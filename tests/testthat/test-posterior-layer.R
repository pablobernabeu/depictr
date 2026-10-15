# Posterior-distribution layer (ggdist) --------------------------------------
#
# These tests exercise the flagship distribution rendering shared by
# posterior_plot() and frequentist_bayesian_plot(): real density slabs (not
# just lineranges), the ROPE band, the probability-of-direction annotation, the
# interval style, the graceful no-ggdist fallback, and the frequentist point/CI
# overlaid on the Bayesian posterior. Bayesian draws are simulated so the core
# rendering is tested without brms/rstanarm; the fitted-model extraction paths
# are guarded with skip_if_not_installed().

# A simulated posterior with a near-normal, a skewed and a bimodal parameter.
sim_draws <- function(n = 3000, seed = 42) {
  set.seed(seed)
  data.frame(
    normalish = rnorm(n, 0.8, 0.2),
    skewed    = rexp(n, rate = 1) - 1,
    bimodal   = c(rnorm(n / 2, -2, 0.4), rnorm(n / 2, 2, 0.4)),
    check.names = FALSE
  )
}

slab_layer_idx <- function(p) {
  which(vapply(p$layers,
               function(l) inherits(l$geom, "GeomSlabinterval"),
               logical(1)))
}

geom_classes <- function(p) {
  vapply(p$layers, function(l) class(l$geom)[1], character(1))
}

# ---- posterior_plot(): true distribution -----------------------------------

test_that("posterior_plot(style = 'halfeye') renders a real density slab", {
  skip_if_not_installed("ggdist")
  p <- posterior_plot(sim_draws(), style = "halfeye")
  expect_s3_class(p, "ggplot")

  idx <- slab_layer_idx(p)
  expect_length(idx, 1)

  b <- ggplot2::ggplot_build(p)
  sl <- b$data[[idx]]
  # A genuine density: ggdist exposes per-x thickness; many distinct values, not
  # the handful a linerange would produce.
  expect_true("thickness" %in% names(sl))
  expect_gt(length(unique(round(sl$thickness, 4))), 50)
})

test_that("the half-eye captures skew and bimodality, not just a point+interval", {
  skip_if_not_installed("ggdist")
  p <- posterior_plot(sim_draws(), style = "halfeye")
  b <- ggplot2::ggplot_build(p)
  sl <- b$data[[slab_layer_idx(p)]]
  expect_true(all(c("x", "thickness") %in% names(sl)))
  # Each parameter contributes its own slab (grouped by y / fill).
  grp <- if ("y" %in% names(sl)) sl$y else sl$group
  expect_gte(length(unique(grp)), 3)
})

test_that("posterior_plot() default style is the half-eye distribution", {
  skip_if_not_installed("ggdist")
  expect_identical(eval(formals(posterior_plot)$style)[1], "halfeye")
  p <- posterior_plot(sim_draws())
  expect_true(any(vapply(p$layers,
                         function(l) inherits(l$geom, "GeomSlabinterval"),
                         logical(1))))
})

test_that("an unrecognised style is an error, as the help page says", {
  # The page used to say that an unknown style fell back to "interval".
  expect_error(posterior_plot(sim_draws(), style = "foo"), "should be one of")
})

test_that("ROPE band is drawn as a shaded rectangle behind the data", {
  skip_if_not_installed("ggdist")
  p <- posterior_plot(sim_draws(), rope = c(-0.1, 0.1))
  expect_true("GeomRect" %in% geom_classes(p))

  b <- ggplot2::ggplot_build(p)
  rect_idx <- which(geom_classes(p) == "GeomRect")
  rd <- b$data[[rect_idx]]
  expect_equal(rd$xmin, -0.1)
  expect_equal(rd$xmax, 0.1)
})

test_that("invalid ROPE specifications error", {
  expect_error(posterior_plot(sim_draws(), rope = c(1, 2, 3)),
               "length-2 numeric")
  expect_error(posterior_plot(sim_draws(), rope = "a"),
               "length-2 numeric")
})

test_that("pd = TRUE annotates probability of direction per parameter", {
  p <- posterior_plot(sim_draws(), style = "interval", pd = TRUE,
                      reference_line = 0)
  expect_true("GeomText" %in% geom_classes(p))

  b <- ggplot2::ggplot_build(p)
  txt <- b$data[[which(geom_classes(p) == "GeomText")]]
  expect_true(all(grepl("pd = ", txt$label)))
  # The all-positive 'normalish' parameter is ~100% in one direction.
  expect_true(any(grepl("100", txt$label)))
})

test_that("pd is the max-side probability relative to the reference", {
  v <- rnorm(10000, 1, 0.5)              # almost all > 0
  expect_gt(depictr:::prob_direction(v, 0), 0.95)
  expect_equal(depictr:::prob_direction(c(-1, -1, 1, 1), 0), 0.5)
  # Reference shifts the direction.
  expect_gt(depictr:::prob_direction(v, 2), 0.95)
})

test_that("pd = TRUE without a reference line is skipped with a message", {
  expect_message(
    p <- posterior_plot(sim_draws(), style = "interval", pd = TRUE,
                        reference_line = NA),
    "needs a finite"
  )
  expect_false("GeomText" %in% geom_classes(p))
})

test_that("reference_line is configurable and can be omitted", {
  p_none <- posterior_plot(sim_draws(), style = "interval",
                           reference_line = NULL)
  expect_false("GeomVline" %in% geom_classes(p_none))

  p_at2 <- posterior_plot(sim_draws(), style = "interval", reference_line = 2)
  b <- ggplot2::ggplot_build(p_at2)
  vl <- b$data[[which(geom_classes(p_at2) == "GeomVline")]]
  expect_equal(unique(vl$xintercept), 2)
})

test_that("style = 'interval' draws the point + nested intervals only", {
  p <- posterior_plot(sim_draws(), style = "interval")
  gc <- geom_classes(p)
  expect_false("GeomSlabinterval" %in% gc)
  expect_true(sum(gc == "GeomLinerange") == 2)
  expect_true(sum(gc == "GeomPoint") == 2)
})

test_that("the intervals are central (equal-tailed) quantile intervals", {
  # The help page now names the interval it draws. Each leaves the same share
  # of the draws in either tail, which on the skewed parameter is not the
  # narrowest interval of that mass.
  d <- sim_draws()
  p <- posterior_plot(d, style = "interval")
  summ <- p$layers[[which(geom_classes(p) == "GeomLinerange")[1]]]$data
  got <- unlist(summ[summ$term == "skewed",
                     c("outer_lo", "inner_lo", "inner_hi", "outer_hi")])
  expect_equal(unname(got),
               stats::quantile(d$skewed, c(0.025, 0.17, 0.83, 0.975),
                               names = FALSE))
})

test_that("the caption auto-reports the interval mass", {
  p <- posterior_plot(sim_draws(), style = "interval", widths = c(0.5, 0.9))
  expect_match(p$labels$caption, "50%")
  expect_match(p$labels$caption, "90%")
  # NA suppresses the caption.
  p2 <- posterior_plot(sim_draws(), style = "interval", caption = NA)
  expect_null(p2$labels$caption)
})

test_that("gradient and dots styles produce ggdist slab-interval geoms", {
  skip_if_not_installed("ggdist")
  pg <- posterior_plot(sim_draws(), style = "gradient")
  expect_true("GeomSlabinterval" %in% geom_classes(pg))
  pd <- posterior_plot(sim_draws(), style = "dots")
  expect_true(any(grepl("Dots", geom_classes(pd))))
})

test_that("a missing ggdist falls back to the interval style with a message", {
  # Force requireNamespace('ggdist') to report FALSE for the duration.
  orig <- base::requireNamespace
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (identical(package, "ggdist")) FALSE else orig(package, ...)
    },
    .package = "base"
  )
  expect_message(
    p <- posterior_plot(sim_draws(), style = "halfeye"),
    "ggdist.*is not installed"
  )
  gc <- geom_classes(p)
  expect_false("GeomSlabinterval" %in% gc)
  expect_true(sum(gc == "GeomLinerange") == 2)
})

# ---- frequentist_bayesian_plot(): posterior + frequentist overlay ----------

test_that("fbp with Bayesian DRAWS renders posteriors + frequentist point/CI", {
  skip_if_not_installed("ggdist")
  freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
             data = wellbeing_survey)
  co <- coef(freq)
  set.seed(11)
  draws <- as.data.frame(lapply(co, function(m)
    rnorm(2000, m * 0.95, abs(m) * 0.12 + 0.05)))
  nm <- names(co); nm[nm == "(Intercept)"] <- "Intercept"
  names(draws) <- paste0("b_", nm)

  p <- frequentist_bayesian_plot(freq, draws)
  expect_s3_class(p, "ggplot")

  # The Bayesian side is a real posterior density slab.
  expect_true("GeomSlabinterval" %in% geom_classes(p))
  # The frequentist side is overlaid as a point + interval.
  expect_true("GeomPoint" %in% geom_classes(p))
  expect_true("GeomErrorbar" %in% geom_classes(p))

  # Two distinct, colourblind-safe palette colours encode the two sources.
  b <- ggplot2::ggplot_build(p)
  cols <- unlist(lapply(b$data, function(d)
    if ("colour" %in% names(d)) unique(stats::na.omit(d$colour))))
  expect_true(all(depictr_palette(2) %in% cols))
  expect_false("#e23b3b" %in% cols)
})

test_that("fbp distribution path aligns b_-prefixed terms with frequentist", {
  skip_if_not_installed("ggdist")
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  co <- coef(freq)
  set.seed(12)
  draws <- as.data.frame(lapply(co, function(m) rnorm(1500, m, 0.1)))
  nm <- names(co); nm[nm == "(Intercept)"] <- "Intercept"
  names(draws) <- paste0("b_", nm)

  p <- frequentist_bayesian_plot(freq, draws)
  # Bayesian b_stress and frequentist stress collapse onto one labelled row.
  slab <- ggplot2::ggplot_build(p)$data[[slab_layer_idx(p)]]
  # Frequentist data carries the same canonical labels.
  freq_layer <- p$layers[[which(geom_classes(p) == "GeomPoint")[1]]]
  flabs <- as.character(freq_layer$data$label)
  expect_true(all(c("stress", "sleep hours") %in% flabs))
  expect_equal(anyDuplicated(flabs), 0L)
})

test_that("fbp summary-only path keeps the two-source forest overlay", {
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  bayes <- data.frame(
    term      = c("b_Intercept", "b_stress", "b_sleep_hours"),
    estimate  = c(5, -0.3, 0.4),
    conf.low  = c(4, -0.5, 0.2),
    conf.high = c(6, -0.1, 0.6)
  )
  p <- frequentist_bayesian_plot(freq, bayes)
  expect_s3_class(p, "ggplot")
  # No posterior slab on the summary path.
  expect_false("GeomSlabinterval" %in% geom_classes(p))
  expect_setequal(levels(p$data$label),
                  c("Intercept", "stress", "sleep hours"))
  b <- ggplot2::ggplot_build(p)
  expect_setequal(sort(unique(b$data[[2]]$colour)), sort(depictr_palette(2)))
})

test_that("fbp distribution path falls back to point+interval without ggdist", {
  orig <- base::requireNamespace
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (identical(package, "ggdist")) FALSE else orig(package, ...)
    },
    .package = "base"
  )
  freq <- lm(life_satisfaction ~ stress, data = wellbeing_survey)
  set.seed(13)
  draws <- data.frame(b_stress = rnorm(1000, -0.3, 0.1))
  # The draws hold no intercept, so the frequentist one is dropped, with a
  # message of its own.
  expect_message(
    expect_message(
      p <- frequentist_bayesian_plot(freq, draws),
      "ggdist.*is not installed"
    ),
    "Frequentist only: \\(Intercept\\)\\."
  )
  gc <- geom_classes(p)
  expect_false("GeomSlabinterval" %in% gc)
  expect_true("GeomLinerange" %in% gc)
  # Both sources still get distinct palette colours.
  b <- ggplot2::ggplot_build(p)
  cols <- unlist(lapply(b$data, function(d)
    if ("colour" %in% names(d)) unique(stats::na.omit(d$colour))))
  expect_true(all(depictr_palette(2) %in% cols))
})

# ---- frequentist_bayesian_plot(): one stated level, stable colours ---------

# Draws spaced evenly over a normal posterior for each coefficient, so the
# intervals a plot computes from them are known without a seed.
quantile_draws <- function(fit, n = 400) {
  co <- stats::coef(fit)
  draws <- as.data.frame(lapply(co, function(m) {
    stats::qnorm(stats::ppoints(n), m, abs(m) * 0.1 + 0.05)
  }))
  names(draws) <- names(co)
  draws
}

# The point-and-interval rows of a built half-eye, one per term and width.
halfeye_intervals <- function(p) {
  d <- ggplot2::ggplot_build(p)$data[[slab_layer_idx(p)]]
  d[!is.na(d$xmin), c(".width", "xmin", "xmax")]
}

# Brand blue for the frequentist source and orange for the Bayesian one.
fbp_colours <- function() {
  pal <- depictr_palette(2)
  c(`Frequentist analysis` = pal[[1]], `Bayesian analysis` = pal[[2]])
}

# The colour each source takes in the built legend.
legend_colours <- function(p) {
  guide <- ggplot2::get_guide_data(p, "colour")
  stats::setNames(guide$colour, guide$.label)[names(fbp_colours())]
}

test_that("fbp draws the posterior's outer interval at conf_level", {
  # Regression: conf_level moved the frequentist bars but not the half-eyes,
  # which stayed at 66% and 95%, so conf_level = 0.8 set 80% confidence
  # intervals beside 95% credible ones.
  skip_if_not_installed("ggdist")
  fit <- lm(life_satisfaction ~ stress, data = wellbeing_survey)
  draws <- quantile_draws(fit)
  p <- frequentist_bayesian_plot(fit, draws, conf_level = 0.8,
                                 intercept = FALSE)
  iv <- halfeye_intervals(p)
  expect_equal(sort(iv$.width), c(0.66, 0.8))
  expect_equal(unlist(iv[iv$.width == 0.8, c("xmin", "xmax")],
                      use.names = FALSE),
               stats::quantile(draws$stress, c(0.1, 0.9), names = FALSE))
  # The frequentist bars are drawn at the same level.
  bars <- p$layers[[which(geom_classes(p) == "GeomErrorbar")]]$data
  expect_equal(c(bars$conf.low, bars$conf.high),
               unname(stats::confint(fit, level = 0.8)["stress", ]))
  # The default keeps the 66% and 95% pair.
  p95 <- frequentist_bayesian_plot(fit, draws, intercept = FALSE)
  expect_equal(sort(halfeye_intervals(p95)$.width), c(0.66, 0.95))
  # At or below 66%, an inner interval would be the wider of the two, so a
  # single interval is drawn.
  for (level in c(0.5, 0.66)) {
    p_low <- frequentist_bayesian_plot(fit, draws, conf_level = level,
                                       intercept = FALSE)
    expect_equal(halfeye_intervals(p_low)$.width, level)
  }
})

test_that("fbp's fallback without ggdist draws the conf_level interval", {
  orig <- base::requireNamespace
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (identical(package, "ggdist")) FALSE else orig(package, ...)
    },
    .package = "base"
  )
  fit <- lm(life_satisfaction ~ stress, data = wellbeing_survey)
  draws <- quantile_draws(fit)
  p <- suppressMessages(frequentist_bayesian_plot(
    fit, draws, conf_level = 0.8, intercept = FALSE
  ))
  ranges <- p$layers[[which(geom_classes(p) == "GeomLinerange")]]$data
  expect_equal(c(ranges$lo, ranges$hi),
               stats::quantile(draws$stress, c(0.1, 0.9), names = FALSE))
  # The fallback draws one posterior interval, and its caption says so.
  expect_identical(p$labels$caption, paste0(
    "Frequentist: 80% confidence interval.\n",
    "Bayesian: posterior median with 80% equal-tailed credible interval."
  ))
  expect_identical(legend_colours(p), fbp_colours())
})

test_that("fbp places reference lines by the conf_level interval", {
  # The faceted layout draws the zero line only in panels whose span reaches
  # it, and the span took the 95% posterior interval whatever conf_level said.
  freq <- data.frame(term = c("a", "b"), estimate = c(0.35, 2),
                     conf.low = c(0.3, 1.9), conf.high = c(0.4, 2.1))
  n <- 400
  # The 95% posterior interval of `a` reaches below zero, and its 80%
  # interval stays above it.
  draws <- data.frame(a = stats::qnorm(stats::ppoints(n), 0.15, 0.1),
                      b = stats::qnorm(stats::ppoints(n), 2, 0.05))
  zero_panels <- function(p) {
    lines <- Filter(function(l) inherits(l$geom, "GeomVline"), p$layers)
    unlist(lapply(lines, function(l) as.character(l$data$label)),
           use.names = FALSE)
  }
  p95 <- suppressMessages(frequentist_bayesian_plot(freq, draws))
  expect_identical(zero_panels(p95), "a")
  p80 <- suppressMessages(
    frequentist_bayesian_plot(freq, draws, conf_level = 0.8)
  )
  expect_null(zero_panels(p80))
})

test_that("fbp captions the level of each source's intervals", {
  # Regression: nothing on the figure named either level. Each source's
  # sentence takes a line, since ggplot2 does not wrap a caption.
  fit <- lm(life_satisfaction ~ stress, data = wellbeing_survey)
  summ <- tidy_estimates(fit)
  # On the summary path, the Bayesian table keeps its own intervals, at a
  # level depictr cannot read, and so does a frequentist table.
  expect_identical(
    frequentist_bayesian_plot(fit, summ, conf_level = 0.9)$labels$caption,
    "Frequentist: 90% confidence interval.\nBayesian: intervals as supplied."
  )
  expect_identical(
    frequentist_bayesian_plot(summ, summ)$labels$caption,
    "Frequentist: intervals as supplied.\nBayesian: intervals as supplied."
  )
  expect_null(
    frequentist_bayesian_plot(fit, summ, caption = NA)$labels$caption
  )
  own <- frequentist_bayesian_plot(fit, summ, caption = "Own words.")
  expect_identical(own$labels$caption, "Own words.")

  skip_if_not_installed("ggdist")
  draws <- quantile_draws(fit)
  expect_identical(
    frequentist_bayesian_plot(fit, draws, conf_level = 0.9)$labels$caption,
    paste0("Frequentist: 90% confidence interval.\n",
           "Bayesian: posterior median with 66% and 90% equal-tailed ",
           "credible intervals.")
  )
  expect_identical(
    frequentist_bayesian_plot(fit, draws, conf_level = 0.5)$labels$caption,
    paste0("Frequentist: 50% confidence interval.\n",
           "Bayesian: posterior median with 50% equal-tailed credible ",
           "interval.")
  )
  expect_identical(
    frequentist_bayesian_plot(summ, draws)$labels$caption,
    paste0("Frequentist: intervals as supplied.\n",
           "Bayesian: posterior median with 66% and 95% equal-tailed ",
           "credible intervals.")
  )
  expect_null(
    frequentist_bayesian_plot(fit, draws, caption = NA)$labels$caption
  )
})

test_that("fbp gives each source the same colour on both paths", {
  # Regression: with draws, the Bayesian side was brand blue and the
  # frequentist side orange, the reverse of the summary path and of the Python
  # twin.
  fit <- lm(life_satisfaction ~ stress, data = wellbeing_survey)
  expect_identical(
    legend_colours(frequentist_bayesian_plot(fit, tidy_estimates(fit))),
    fbp_colours()
  )
  skip_if_not_installed("ggdist")
  p <- frequentist_bayesian_plot(fit, quantile_draws(fit))
  expect_identical(legend_colours(p), fbp_colours())
  # The layers draw what the legend says.
  b <- ggplot2::ggplot_build(p)
  slab <- b$data[[slab_layer_idx(p)]]
  expect_identical(unique(c(slab$colour, slab$fill)),
                   fbp_colours()[["Bayesian analysis"]])
  bars <- b$data[[which(geom_classes(p) == "GeomErrorbar")]]
  expect_identical(unique(bars$colour),
                   fbp_colours()[["Frequentist analysis"]])
})

# ---- draws extraction helpers ----------------------------------------------

test_that("extract_draws() handles wide, long and matrix inputs", {
  set.seed(1)
  wide <- data.frame(a = rnorm(100), b = rnorm(100))
  ed <- depictr:::extract_draws(wide)
  expect_setequal(unique(ed$term), c("a", "b"))
  expect_true(all(c("term", ".value", ".draw") %in% names(ed)))

  long <- data.frame(parameter = rep(c("a", "b"), each = 50),
                     value = rnorm(100))
  edl <- depictr:::extract_draws(long)
  expect_setequal(unique(edl$term), c("a", "b"))

  m <- matrix(rnorm(200), ncol = 2, dimnames = list(NULL, c("x", "y")))
  edm <- depictr:::extract_draws(m)
  expect_setequal(unique(edm$term), c("x", "y"))
})

test_that("extract_draws() drops sampler index columns and NA values", {
  set.seed(2)
  draws <- data.frame(.chain = 1L, .iteration = 1:100, .draw = 1:100,
                      a = rnorm(100), b = rnorm(100))
  draws$a[5] <- NA
  ed <- depictr:::extract_draws(draws)
  expect_setequal(unique(ed$term), c("a", "b"))
  expect_false(any(is.na(ed$.value)))
})

test_that("has_draws() distinguishes draws from summary tables", {
  # Tidy summary tables are NOT draws.
  summ <- data.frame(term = "x", estimate = 1, conf.low = 0, conf.high = 2)
  expect_false(depictr:::has_draws(summ))
  # A summary(brmsfit)$fixed-style summary is NOT draws.
  fx <- data.frame(Estimate = 1, `l-95% CI` = 0, `u-95% CI` = 2,
                   check.names = FALSE)
  expect_false(depictr:::has_draws(fx))
  # Long draws (parameter + value, no summaries) ARE draws.
  long <- data.frame(parameter = rep("a", 100), value = rnorm(100))
  expect_true(depictr:::has_draws(long))
  # Wide draws with many rows ARE draws.
  expect_true(depictr:::has_draws(data.frame(a = rnorm(200), b = rnorm(200))))
  # A draws matrix is draws.
  expect_true(depictr:::has_draws(matrix(rnorm(20), ncol = 2)))
})

test_that("extract_draws() reads a posterior draws object", {
  skip_if_not_installed("posterior")
  set.seed(3)
  dd <- posterior::as_draws_df(
    posterior::draws_matrix(b_x = rnorm(200), b_y = rnorm(200))
  )
  ed <- depictr:::extract_draws(dd)
  # Population-level parameters lose their b_ prefix, as they do when the
  # brmsfit itself is passed, so one `labels` key reaches the frequentist term
  # and its posterior alike.
  expect_setequal(unique(ed$term), c("x", "y"))
  expect_true(all(c("term", ".value", ".draw") %in% names(ed)))
})

# The brmsfit extraction path (posterior::as_draws_df dispatch) is verified
# manually against a real fit in dev/; CI covers the draws-object and
# data-frame paths above, so depictr needs no heavy brms dependency.

# ---- brms draws objects, fixef() matrices and label clashes -----------------

# Mimics the variables posterior::as_draws_df() returns for a brms fit of
# y ~ x, in brms's order. Beside the population-level b_ parameters there are
# the residual SD, the intercept of the centred predictors (which brms reports
# alongside b_Intercept) and the two log densities.
brms_shaped_draws <- function(n = 400, seed = 21) {
  set.seed(seed)
  posterior::as_draws_df(data.frame(
    b_Intercept = rnorm(n, 2, 0.1),
    b_x         = rnorm(n, 0.5, 0.05),
    sigma       = abs(rnorm(n, 1, 0.05)),
    Intercept   = rnorm(n, 2.3, 0.1),
    lprior      = rnorm(n, -6),
    lp__        = rnorm(n, -90)
  ))
}

kept_b_message <- paste0(
  "^Kept the 2 population-level \\(b_\\) parameters and dropped 4 others: ",
  "sigma, Intercept, lprior, lp__\\."
)

# The distinct y labels across a plot's layers.
drawn_labels <- function(p) {
  unique(unlist(lapply(p$layers, function(l) {
    if (is.data.frame(l$data) && "label" %in% names(l$data)) {
      as.character(unique(l$data$label))
    }
  })))
}

test_that("posterior_plot() keeps the b_ parameters of a brms draws object", {
  # Regression: a draws_df is a data frame, so it took the wide path that keeps
  # every variable, and b_Intercept and the centred Intercept then clashed as
  # factor levels ("factor level [6] is duplicated"). A draws_matrix failed the
  # same way through extract_draws().
  skip_if_not_installed("posterior")
  dd <- brms_shaped_draws()
  for (d in list(dd, posterior::as_draws_matrix(dd))) {
    expect_no_warning(expect_message(
      p <- posterior_plot(d, style = "interval"), kept_b_message
    ))
    expect_setequal(drawn_labels(p), c("Intercept", "x"))
    # The Intercept row summarises b_Intercept alone.
    summ <- p$layers[[which(geom_classes(p) == "GeomLinerange")[1]]]$data
    expect_equal(summ$centre[summ$label == "Intercept"],
                 stats::median(dd$b_Intercept))
  }
})

test_that("the variables a draws object loses are summarised by prefix", {
  skip_if_not_installed("posterior")
  set.seed(22)
  vars <- c("b_Intercept", "b_conditionunrelated", "sd_item__Intercept",
            "sd_participant__Intercept", "sigma", "Intercept",
            sprintf("r_item[w%d,Intercept]", 1:3),
            sprintf("r_participant[p%d,Intercept]", 1:2), "lprior", "lp__")
  m <- matrix(rnorm(100 * length(vars)), ncol = length(vars),
              dimnames = list(NULL, vars))
  dd <- posterior::as_draws_df(posterior::as_draws_matrix(m))
  msgs <- character(0)
  ed <- withCallingHandlers(
    depictr:::extract_draws(dd),
    message = function(cond) {
      msgs <<- c(msgs, conditionMessage(cond))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(msgs, 1)
  expect_match(
    msgs,
    paste0("Kept the 2 population-level (b_) parameters and dropped 11 ",
           "others: sd_ (2), sigma, Intercept, r_item (3), r_participant (2), ",
           "lprior, lp__."),
    fixed = TRUE
  )
  expect_setequal(unique(ed$term), c("Intercept", "conditionunrelated"))
})

test_that("frequentist_bayesian_plot() reads a brms draws object unpooled", {
  # Regression: the two intercepts were pooled into one 'Intercept' slab of
  # twice the draws, beside slabs for lp__, lprior and sigma.
  skip_if_not_installed("posterior")
  skip_if_not_installed("ggdist")
  set.seed(23)
  d <- data.frame(x = rnorm(60))
  d$y <- 2 + 0.5 * d$x + rnorm(60)
  fit <- lm(y ~ x, data = d)
  dd <- brms_shaped_draws(n = 400)
  for (b in list(dd, posterior::as_draws_matrix(dd))) {
    expect_message(
      p <- frequentist_bayesian_plot(fit, b, facet = FALSE), kept_b_message
    )
    slab <- p$layers[[slab_layer_idx(p)]]$data
    expect_setequal(as.character(unique(slab$label)), c("Intercept", "x"))
    expect_equal(sum(slab$label == "Intercept"), 400L)
    expect_equal(sort(slab$.value[slab$label == "Intercept"]),
                 sort(dd$b_Intercept))
  }
})

test_that("a brms::fixef() matrix takes the summary path", {
  # Regression: every matrix counted as draws, so the fixef() summary was
  # melted column-wise into half-eyes named Estimate, Est.Error, Q2.5 and
  # Q97.5.
  fx <- readRDS(system.file("extdata", "brms_fixef_lexdec.rds",
                            package = "depictr"))
  expect_true(is.matrix(fx))
  expect_false(depictr:::has_draws(fx))
  # A matrix of draws with parameter columns is still draws.
  expect_true(depictr:::has_draws(matrix(rnorm(20), ncol = 2,
                                         dimnames = list(NULL, c("a", "b")))))

  fit <- lm(RT ~ condition + modality + word_frequency,
            data = lexical_decision)
  expect_no_warning(p <- frequentist_bayesian_plot(fit, fx))
  expect_false("GeomSlabinterval" %in% geom_classes(p))
  expect_setequal(unique(as.character(p$data$label)),
                  c("Intercept", "condition: unrelated", "modality: auditory",
                    "word frequency"))
  # The Bayesian rows carry the fixef() estimates and quantiles.
  bayes <- p$data[p$data$source == "Bayesian analysis", ]
  wf <- bayes[bayes$label == "word frequency", ]
  expect_equal(wf$estimate, fx["word_frequency", "Estimate"])
  expect_equal(c(wf$conf.low, wf$conf.high),
               unname(fx["word_frequency", c("Q2.5", "Q97.5")]))
})

test_that("posterior_plot() refuses a matrix of posterior summaries", {
  fx <- readRDS(system.file("extdata", "brms_fixef_lexdec.rds",
                            package = "depictr"))
  expect_error(posterior_plot(fx), "holds posterior summaries .*not draws")
})

test_that("the summary path warns only about label keys the user supplied", {
  # Regression: the automatic b_-prefixed factor-level keys were merged into
  # `labels` before compare_models() judged them, so it warned about
  # b_treatmentenhanced, a key nobody had written.
  fit <- lm(yield ~ treatment + rainfall, data = crop_yield)
  expect_no_warning(frequentist_bayesian_plot(fit, tidy_estimates(fit)))
  # A key the user mistyped still warns, and names only that key.
  expect_warning(
    frequentist_bayesian_plot(fit, tidy_estimates(fit),
                              labels = c(rainfal = "Rainfall")),
    "^`labels` keys not found among the parameters: rainfal\\. "
  )
})

test_that("two parameters that would share a label are an error naming both", {
  # A plain table keeps every column, so brms's two intercepts would be drawn
  # as one: posterior_plot() failed on a duplicated factor level and
  # frequentist_bayesian_plot() pooled their draws into one slab.
  set.seed(24)
  n <- 400
  draws <- data.frame(b_Intercept = rnorm(n, 2, 0.1),
                      Intercept   = rnorm(n, 2.3, 0.1),
                      b_x         = rnorm(n, 0.5, 0.05))
  clash <- paste0("^Parameters b_Intercept and Intercept share the label ",
                  "'Intercept'; rename one with `labels`\\.$")
  expect_error(posterior_plot(draws), clash)
  d <- data.frame(x = rnorm(60))
  d$y <- 2 + 0.5 * d$x + rnorm(60)
  expect_error(frequentist_bayesian_plot(lm(y ~ x, data = d), draws), clash)
  expect_error(
    posterior_plot(data.frame(b_x = rnorm(n), x = rnorm(n))),
    "^Parameters b_x and x share the label 'x'"
  )
  # A label for one of them resolves the clash.
  p <- posterior_plot(draws, style = "interval",
                      labels = c(Intercept = "Intercept (centred)"))
  expect_setequal(drawn_labels(p), c("Intercept", "Intercept (centred)", "x"))
})

test_that("frequentist_bayesian_plot() draws only the terms both inputs share", {
  # Regression: a posterior's sigma was drawn as a slab with no frequentist
  # counterpart, and a frequentist term with no posterior stood alone too.
  set.seed(25)
  d <- data.frame(x = rnorm(80), z = rnorm(80))
  d$y <- 1 + 0.5 * d$x + rnorm(80)
  fit <- lm(y ~ x + z, data = d)
  n <- 400
  draws <- data.frame(b_Intercept = rnorm(n, 1, 0.1),
                      b_x         = rnorm(n, 0.5, 0.05),
                      sigma       = abs(rnorm(n, 1, 0.05)))
  expect_message(
    p <- frequentist_bayesian_plot(fit, draws, facet = FALSE),
    paste0("^Dropped the terms the two inputs do not share\\. ",
           "Bayesian only: sigma\\. Frequentist only: z\\.")
  )
  expect_setequal(drawn_labels(p), c("Intercept", "x"))
  # Inputs with no term in common are refused.
  expect_error(
    frequentist_bayesian_plot(fit, data.frame(a = rnorm(n), b = rnorm(n))),
    "^The frequentist and Bayesian inputs share no terms\\."
  )
})

test_that("lp__ and lprior are never drawn as parameters", {
  set.seed(26)
  n <- 400
  draws <- data.frame(a = rnorm(n), lprior = rnorm(n, -5),
                      lp__ = rnorm(n, -90))
  dropped <- paste0("^Dropped lprior and lp__, which are log densities, ",
                    "not model parameters\\.")
  expect_message(p <- posterior_plot(draws, style = "interval"), dropped)
  expect_setequal(drawn_labels(p), "a")
  expect_message(ed <- depictr:::extract_draws(draws), dropped)
  expect_setequal(unique(ed$term), "a")
})

test_that("draws holding only log densities are refused plainly", {
  # Dropping lp__ and lprior can leave no parameter at all, and the empty table
  # then failed inside ggplot2 with an error about `data`.
  set.seed(27)
  only_lp <- data.frame(lp__ = rnorm(100, -50), lprior = rnorm(100, -5))
  for (d in list(only_lp, as.matrix(only_lp))) {
    expect_error(suppressMessages(posterior_plot(d)),
                 "^No parameters left to plot\\.$")
  }
})

# ---- labels formatted once per parameter -------------------------------------

# Replaces format_terms() for the rest of the calling test with a copy that
# records the longest vector it is asked to format, and returns a function that
# reads the record. Counting what is formatted keeps the test free of the clock.
record_format_terms <- function(env = parent.frame()) {
  longest <- 0L
  real <- format_terms
  testthat::local_mocked_bindings(
    format_terms = function(x, ...) {
      longest <<- max(longest, length(x))
      real(x, ...)
    },
    .env = env
  )
  function() longest
}

test_that("posterior_plot() formats each parameter's label once", {
  # Regression: a label was formatted for every draw, so ten parameters of
  # 4,000 draws took seconds and a brms draws object minutes.
  draws <- sim_draws(n = 600)
  longest <- record_format_terms()
  p <- posterior_plot(draws, style = "interval")
  expect_gt(longest(), 0)
  expect_lte(longest(), ncol(draws))
  expect_setequal(drawn_labels(p), names(draws))
  # A named `labels` vector leaves the other parameters to format_terms().
  p <- posterior_plot(draws, style = "interval",
                      labels = c(normalish = "near normal"))
  expect_lte(longest(), ncol(draws))
  expect_setequal(drawn_labels(p), c("near normal", "skewed", "bimodal"))
})

test_that("posterior_plot() takes an unnamed label per parameter", {
  # Labelling every draw made an unnamed vector fail with a count of draws:
  # "`labels` has length 3 but there are 1800 terms to label."
  draws <- sim_draws(n = 600)
  p <- posterior_plot(draws, style = "interval", labels = c("A", "B", "C"))
  summ <- p$layers[[which(geom_classes(p) == "GeomLinerange")[1]]]$data
  expect_identical(as.character(summ$label), c("A", "B", "C"))
  expect_identical(summ$term, names(draws))
  expect_error(posterior_plot(draws, labels = c("A", "B")),
               "^`labels` has length 2 but there are 3 terms to label\\.$")
})

test_that("frequentist_bayesian_plot() formats each term's label once", {
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  draws <- quantile_draws(freq, n = 600)
  longest <- record_format_terms()
  p <- suppressMessages(frequentist_bayesian_plot(freq, draws))
  expect_gt(longest(), 0)
  expect_lte(longest(), ncol(draws))
  expect_setequal(drawn_labels(p), c("Intercept", "stress", "sleep hours"))
  # Every draw keeps its term's label. Without ggdist, the draws are summarised
  # before they are drawn.
  skip_if_not_installed("ggdist")
  bayes <- Filter(function(l) nrow(l$data) == nrow(draws) * ncol(draws),
                  p$layers)
  expect_length(bayes, 1)
  expect_equal(as.vector(table(as.character(bayes[[1]]$data$label))),
               rep(nrow(draws), ncol(draws)))
})

test_that("an rstanarm fit keeps only its regression coefficients", {
  # rstanarm's as.matrix() also carries every group-level coefficient b[...]
  # and covariance element Sigma[...], which are not fixed effects. rstanarm
  # is not a dependency, so the column filter is tested on its own.
  cols <- c("(Intercept)", "x", "b[(Intercept) participant:p1]",
            "b[(Intercept) participant:p2]",
            "Sigma[participant:(Intercept),(Intercept)]", "sigma",
            "mean_PPD", "log-posterior")
  expect_identical(depictr:::rstanarm_fixed_columns(cols),
                   c("(Intercept)", "x"))
})
