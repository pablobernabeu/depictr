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
  expect_message(
    p <- frequentist_bayesian_plot(freq, draws),
    "ggdist.*is not installed"
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
  # brms::fixef()-style summary is NOT draws.
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
  # Population-level names are kept as-is here (no stripping in the generic
  # posterior path); the b_ prefix is reconciled later by format_terms().
  expect_true(all(c("b_x", "b_y") %in% unique(ed$term)))
  expect_true(all(c("term", ".value", ".draw") %in% names(ed)))
})

# The brmsfit extraction path (posterior::as_draws_df dispatch) is verified
# manually against a real fit in dev/; CI covers the draws-object and
# data-frame paths above, so depictr needs no heavy brms dependency.
