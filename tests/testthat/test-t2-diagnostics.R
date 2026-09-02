# Tier-2 diagnostics colour / scale / quality refactor -----------------------

test_that("residual_diagnostics_plot() builds with no warnings and on-palette colours", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- residual_diagnostics_plot(fit)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  # Gather every colour drawn across the patchwork panels.
  cols <- unlist(lapply(b$data, function(d) {
    out <- character(0)
    if (!is.null(d$colour)) out <- c(out, d$colour)
    out
  }))
  cols <- unique(cols[!is.na(cols)])

  # The off-palette red must be gone; brand blue and the grey reference remain.
  expect_false(any(cols == "#e23b3b"))
  expect_true(depictr_brand() %in% cols)
  expect_true(depictr_reference() %in% cols)
})

test_that("residual_diagnostics_plot() loess smoother and QQ line use the reference grey", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  # Scale-location panel carries a loess smoother; QQ panel carries the QQ line.
  p <- residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  smoother_cols <- unlist(lapply(b$data, function(d) {
    if (!is.null(d$colour) && !is.null(d$flipped_aes)) d$colour else NULL
  }))
  # The reference grey should appear (loess / hline / qq line); the old red not.
  all_cols <- unique(unlist(lapply(b$data, function(d) d$colour)))
  expect_true(depictr_reference() %in% all_cols)
  expect_false("#e23b3b" %in% all_cols)
})

test_that("influence_plot() uses brand bubbles, grey references and accent labels", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- influence_plot(fit)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  all_cols <- unique(unlist(lapply(b$data, function(d) d$colour)))
  all_cols <- all_cols[!is.na(all_cols)]
  expect_true(depictr_brand() %in% all_cols)      # bubbles
  expect_true(depictr_reference() %in% all_cols)  # h/v reference lines
  expect_true(depictr_accent() %in% all_cols)     # influence labels
  expect_false("#e23b3b" %in% all_cols)
})

test_that("qq_plot() builds for vectors and models without the off-palette red", {
  expect_no_warning(b1 <- ggplot2::ggplot_build(qq_plot(rnorm(100))))
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  expect_no_warning(b2 <- ggplot2::ggplot_build(qq_plot(fit)))
  cols <- unique(c(
    unlist(lapply(b1$data, function(d) d$colour)),
    unlist(lapply(b2$data, function(d) d$colour))
  ))
  expect_true(depictr_brand() %in% cols)
  expect_true(depictr_reference() %in% cols)
  expect_false("#e23b3b" %in% cols)
})

test_that("vif_plot() builds and uses the colourblind-safe palette pair", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- vif_plot(fit)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  fills <- unique(b$data[[1]]$fill)
  expect_true(all(fills %in% depictr_palette(2)))
  # No ad-hoc red/blue pair survives.
  expect_false("#e23b3b" %in% fills)

  # These VIFs are ~1, well below the threshold, so the line is off-axis and is
  # reported in the caption rather than stranded in a wide empty band.
  expect_match(p$labels$caption, "off the axis")
})

test_that("vif_plot() draws a neutral-grey threshold line under collinearity", {
  set.seed(1)
  d <- crop_yield
  d$rain2 <- d$rainfall + stats::rnorm(nrow(d), 0, 5)
  p <- vif_plot(lm(yield ~ rainfall + rain2 + fertiliser, data = d))
  b <- ggplot2::ggplot_build(p)
  line_cols <- unique(unlist(lapply(b$data[-1], function(dd) dd$colour)))
  expect_true("grey40" %in% line_cols)
})

test_that("gvif_terms() reduces to ordinary VIF for single-df terms", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)

  # Independent base-R VIF computation for comparison.
  X <- stats::model.matrix(fit)
  X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  ref_vif <- vapply(seq_len(ncol(X)), function(j) {
    r2 <- summary(stats::lm(X[, j] ~ X[, -j, drop = FALSE]))$r.squared
    1 / (1 - r2)
  }, numeric(1))
  names(ref_vif) <- colnames(X)

  res <- gvif_terms(fit)
  # One row per term, every term has df = 1 here.
  expect_setequal(res$term, c("rainfall", "fertiliser", "soil_ph"))
  expect_true(all(res$df == 1))

  # GVIF == ordinary VIF for single-df terms, and the adjusted value is sqrt().
  expect_equal(res$gvif[match(names(ref_vif), res$term)], unname(ref_vif),
               tolerance = 1e-8)
  expect_equal(res$gvif_adj, sqrt(res$gvif), tolerance = 1e-12)
})

test_that("gvif_terms() reports one generalised VIF per multi-level factor term", {
  fit <- lm(life_satisfaction ~ age + income + region + education,
            data = wellbeing_survey)
  res <- gvif_terms(fit)

  # One row per *term*, not per dummy column.
  expect_setequal(res$term, c("age", "income", "region", "education"))
  expect_equal(res$df[res$term == "region"], 3L)      # 4 levels -> 3 df
  expect_equal(res$df[res$term == "education"], 2L)    # 3 levels -> 2 df

  # Validate the Fox-Monette formula directly for the 'region' term.
  X <- stats::model.matrix(fit)
  assign <- attr(X, "assign")
  keep <- assign != 0
  X <- X[, keep, drop = FALSE]
  assign <- assign[keep]
  R <- stats::cor(X)
  detR <- det(R)
  region_idx <- which(attr(stats::terms(fit), "term.labels") == "region")
  cols <- which(assign == region_idx)
  others <- which(assign != region_idx)
  expected_gvif <- det(R[cols, cols, drop = FALSE]) *
    det(R[others, others, drop = FALSE]) / detR
  expect_equal(res$gvif[res$term == "region"], expected_gvif, tolerance = 1e-8)
  expect_equal(res$gvif_adj[res$term == "region"],
               expected_gvif^(1 / (2 * 3)), tolerance = 1e-10)

  # All adjusted values are finite and positive.
  expect_true(all(is.finite(res$gvif_adj)))
  expect_true(all(res$gvif_adj > 0))
})

test_that("vif_plot() shows one bar per term for a model with a multi-level factor", {
  fit <- lm(life_satisfaction ~ age + income + region + education,
            data = wellbeing_survey)
  p <- vif_plot(fit)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  # Four terms -> four bars (not one per dummy column).
  expect_equal(nrow(b$data[[1]]), 4L)
})

test_that("vif_plot() still errors with fewer than two predictor columns", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  expect_error(vif_plot(fit), "at least two predictor")
})

test_that("gvif_terms() uses the coefficient covariance for weighted fits", {
  # The design-matrix correlation and the coefficient covariance agree only for
  # an unweighted lm; for a glm or a weighted fit the fitting weights matter,
  # and the Fox-Monette definition (what car::vif() reports) uses the latter.
  ref_gvif <- function(model) {
    V <- stats::vcov(model)
    assign <- attr(stats::model.matrix(model), "assign")
    keep <- assign != 0
    R <- stats::cov2cor(V[keep, keep, drop = FALSE])
    assign <- assign[keep]
    detR <- det(R)
    vapply(sort(unique(assign)), function(t) {
      cols <- which(assign == t)
      others <- which(assign != t)
      det(R[cols, cols, drop = FALSE]) *
        det(R[others, others, drop = FALSE]) / detR
    }, numeric(1))
  }

  set.seed(11)
  n <- 200
  x1 <- rnorm(n)
  x2 <- 0.9 * x1 + rnorm(n, sd = 0.4)
  x3 <- rnorm(n)
  counts <- rpois(n, exp(0.2 + 0.3 * x1 - 0.2 * x2 + 0.1 * x3))

  pois <- glm(counts ~ x1 + x2 + x3, family = poisson)
  expect_equal(gvif_terms(pois)$gvif, ref_gvif(pois), tolerance = 1e-10)

  wfit <- lm(counts ~ x1 + x2 + x3, weights = runif(n, 0.2, 3))
  expect_equal(gvif_terms(wfit)$gvif, ref_gvif(wfit), tolerance = 1e-10)

  # The weights genuinely move the answer, so the test would fail against a
  # design-matrix computation.
  X <- stats::model.matrix(wfit)[, -1, drop = FALSE]
  design_gvif <- diag(solve(stats::cor(X)))
  expect_false(isTRUE(all.equal(gvif_terms(wfit)$gvif, unname(design_gvif),
                                tolerance = 1e-4)))
})

test_that("gvif_terms() refuses a model with aliased coefficients", {
  set.seed(12)
  n <- 30
  d <- data.frame(x1 = rnorm(n), x3 = rnorm(n))
  d$x2 <- 2 * d$x1
  d$y <- rnorm(n)
  expect_error(vif_plot(lm(y ~ x1 + x2 + x3, data = d)), "aliased")
})

test_that("gvif_terms() warns when the model has no intercept", {
  # Without an intercept the columns are uncentred, so the figures are not the
  # centred VIFs a reader expects; the warning is what car::vif() gives too.
  set.seed(13)
  n <- 100
  x1 <- rnorm(n, mean = 5)
  x2 <- 0.8 * x1 + rnorm(n, sd = 0.5)
  y <- x1 - x2 + rnorm(n)
  fit <- lm(y ~ 0 + x1 + x2)
  expect_warning(gvif_terms(fit), "no intercept")
  expect_warning(vif_plot(fit), "no intercept")

  # An intercept is the ordinary case and stays quiet.
  expect_silent(gvif_terms(lm(y ~ x1 + x2)))
})
