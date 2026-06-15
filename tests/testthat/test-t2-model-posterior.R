# Tier-2 colour/scale refactor: model & posterior plots ----------------------
#
# These tests pin the colour single-source-of-truth for the four files in this
# group (frequentist_bayesian_plot, posterior_plot, power_curve_plot,
# predictions) and guard against the off-palette red "#e23b3b" / ad-hoc
# red+blue pairs reappearing.

test_that("frequentist_bayesian_plot() uses the colourblind-safe two-colour palette", {
  freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
             data = wellbeing_survey)
  bayes <- tidy_estimates(freq)
  bayes$estimate <- bayes$estimate * 0.95

  p <- frequentist_bayesian_plot(freq, bayes)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  # The two sources are encoded by depictr_palette(2) (brand blue + orange),
  # never the old off-palette red/blue pair.
  pt <- b$data[[2]]
  used <- sort(unique(pt$colour))
  expect_setequal(used, sort(depictr_palette(2)))
  expect_false("#e23b3b" %in% used)
  # Brand blue leads the palette; orange is the colourblind-safe partner.
  expect_identical(sort(depictr_palette(2)), sort(c(depictr_brand(), "#e69f00")))
})

test_that("posterior_plot() draws points/intervals in brand blue and a neutral reference line", {
  set.seed(1)
  draws <- data.frame(
    intercept = rnorm(2000, 5, 0.3),
    slope = rnorm(2000, 0.8, 0.15),
    `slope:group` = rnorm(2000, -0.2, 0.2),
    check.names = FALSE
  )
  p <- posterior_plot(draws)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  # Layer 1 is the reference vline; remaining linerange/point layers are brand.
  vline <- b$data[[1]]
  expect_identical(unique(vline$colour), depictr_reference())

  ranges <- b$data[[2]]
  expect_identical(unique(ranges$colour), depictr_brand())

  # The default colour formal resolves through the accessor, not a hex literal.
  expect_identical(eval(formals(posterior_plot)$colour), depictr_brand())
})

test_that("power_curve_plot() uses brand blue for the curve and a neutral target line", {
  pc <- data.frame(
    nlevels = c(10, 20, 30, 40, 50, 60),
    mean = c(0.18, 0.34, 0.52, 0.66, 0.79, 0.88),
    lower = c(0.10, 0.25, 0.42, 0.56, 0.70, 0.81),
    upper = c(0.28, 0.44, 0.62, 0.75, 0.86, 0.93)
  )
  p <- power_curve_plot(pc, title = "Power")
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  # Collect colours across layers: the target hline is the neutral reference
  # grey; the line and points are brand blue.
  line_cols <- unlist(lapply(b$data, function(d) {
    if ("colour" %in% names(d)) unique(d$colour) else NULL
  }))
  expect_true(depictr_reference() %in% line_cols)
  expect_true(depictr_brand() %in% line_cols)
  expect_false("#e23b3b" %in% line_cols)
})

test_that("effects_plot() defaults to brand blue for both factor and numeric predictors", {
  expect_identical(eval(formals(effects_plot)$colour), depictr_brand())

  fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)

  pn <- effects_plot(fit, "fertilizer")        # numeric -> ribbon + line
  expect_no_warning(bn <- ggplot2::ggplot_build(pn))
  line_n <- bn$data[[2]]
  expect_identical(unique(line_n$colour), depictr_brand())

  pf <- effects_plot(fit, "treatment")         # factor -> pointrange
  expect_no_warning(bf <- ggplot2::ggplot_build(pf))
  expect_identical(unique(bf$data[[1]]$colour), depictr_brand())
})

test_that("interaction_plot() encodes the moderator via the canonical depictr palette", {
  fit <- lm(yield ~ fertilizer * treatment + rainfall, data = crop_yield)
  p <- interaction_plot(fit, "fertilizer", "treatment")
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  # Two moderator levels -> first two palette colours, drawn from depictr_palette.
  line_cols <- sort(unique(b$data[[2]]$colour))
  expect_setequal(line_cols, sort(depictr_palette(2)))
  expect_false("#e23b3b" %in% line_cols)

  # An explicit palette override is still honoured (the canonical scale slices
  # the supplied vector rather than ignoring it).
  greens <- c("#111111", "#222222")
  p2 <- interaction_plot(fit, "fertilizer", "treatment", palette = greens)
  b2 <- ggplot2::ggplot_build(p2)
  expect_setequal(sort(unique(b2$data[[2]]$colour)), sort(greens))
})

test_that("the four refactored files contain no off-palette hex literals", {
  files <- c("frequentist_bayesian_plot.R", "posterior_plot.R",
             "power_curve_plot.R", "predictions.R")
  roots <- c("R", file.path("..", "..", "R"))
  root <- roots[dir.exists(roots)][1]
  skip_if(is.na(root), "package R/ source not available from test wd")

  for (f in files) {
    path <- file.path(root, f)
    skip_if_not(file.exists(path), paste("missing", path))
    src <- readLines(path, warn = FALSE)
    hits <- grep("#[0-9a-fA-F]{6}\\b", src, value = TRUE)
    expect_identical(hits, character(0),
                     info = paste0(f, " still contains a hex literal: ",
                                   paste(hits, collapse = " | ")))
  }
})
