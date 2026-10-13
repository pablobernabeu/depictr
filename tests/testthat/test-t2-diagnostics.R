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

test_that("vif_plot() refuses a model with aliased coefficients, naming the terms", {
  # rain2 is twice rainfall, so lm() leaves its coefficient NA and no VIF
  # exists. The plot stopped on "missing value where TRUE/FALSE needed". The
  # Python twin refuses the same model with the same sentence.
  d <- crop_yield
  d$rain2 <- 2 * d$rainfall
  expect_error(
    vif_plot(lm(yield ~ rainfall + rain2 + fertiliser, data = d)),
    paste("VIF is undefined when coefficients are aliased: rain2.",
          "Drop the redundant term(s) and refit."),
    fixed = TRUE
  )
  # A copy of a factor is aliased as a whole term, and a glm is refused alike.
  d$treatment2 <- d$treatment
  expect_error(vif_plot(lm(yield ~ rainfall + treatment + treatment2, data = d)),
               "aliased: treatment2. ", fixed = TRUE)
  ct <- clinical_trial
  ct$age_months <- 12 * ct$age
  expect_error(
    vif_plot(glm(adverse_event ~ biomarker + age + age_months,
                 family = binomial, data = ct)),
    "aliased: age_months. ", fixed = TRUE
  )
})

test_that("gvif_terms() weights a weighted lm and a glm as their fits do", {
  # The generalised VIF describes the estimated coefficients, whose covariance
  # carries the weights of the fit. The correlations of the unweighted design
  # matrix gave other values for both models. car::vif() (car 3.1.5) gives
  # the values pinned here, and the Python twin's tests pin them too
  # (depictr-py dev/goldens/vif.R).
  ws <- wellbeing_survey
  ws$w <- rep_len(1:3, nrow(ws))
  wfit <- lm(life_satisfaction ~ stress + region + education, data = ws,
             weights = w)
  res <- gvif_terms(wfit)
  expect_equal(res$term, c("stress", "region", "education"))
  expect_equal(res$gvif, c(1.22771766362, 1.22763102351, 1.02413689177),
               tolerance = 1e-9)
  # Converged tightly, to the estimate statsmodels reaches.
  gfit <- glm(adverse_event ~ biomarker + age + arm, family = binomial,
              data = clinical_trial,
              control = glm.control(epsilon = 1e-14, maxit = 100))
  expect_equal(gvif_terms(gfit)$gvif,
               c(1.00264843600, 1.00461360059, 1.00348848503), tolerance = 1e-9)
})

test_that("gvif_terms() keeps the values of an unweighted lm, exact fits included", {
  # With an intercept and no weights, the coefficient correlations and the
  # correlations of the predictor columns give the same GVIF. The Python twin
  # pins these values (depictr-py dev/goldens/vif.R).
  fit <- lm(life_satisfaction ~ stress + region + education,
            data = wellbeing_survey)
  res <- gvif_terms(fit)
  expect_equal(res$df, c(1L, 3L, 2L))
  expect_equal(res$gvif, c(1.21638178777, 1.22488550981, 1.01798089228),
               tolerance = 1e-9)
  # A model that fits its data exactly has a zero residual variance, which
  # vcov() would warn about. Its design is as collinear as any other.
  d <- data.frame(x1 = c(1, 2, 3, 4, 5, 6, 7, 8), x2 = c(2, 1, 4, 3, 6, 8, 5, 7))
  d$y <- 1 + 2 * d$x1 - d$x2
  exact <- lm(y ~ x1 + x2, data = d)
  expect_no_warning(res <- gvif_terms(exact))
  expect_equal(res$gvif, rep(1 / (1 - stats::cor(d$x1, d$x2)^2), 2),
               tolerance = 1e-10)
})

test_that("gvif_terms() warns that a model without an intercept is uncentred", {
  # Without an intercept, the coefficients' covariance comes from uncentred
  # columns, so a predictor far from zero looks collinear with the others.
  # car::vif() warns here too, and so does the Python twin.
  set.seed(13)
  d <- data.frame(x1 = rnorm(100, mean = 5))
  d$x2 <- 0.8 * d$x1 + rnorm(100, sd = 0.5)
  d$y <- d$x1 - d$x2 + rnorm(100)
  fit <- lm(y ~ 0 + x1 + x2, data = d)
  expect_warning(res <- gvif_terms(fit), "no intercept")
  gram <- crossprod(stats::model.matrix(fit))
  expect_equal(res$gvif, unname(diag(gram) * diag(solve(gram))),
               tolerance = 1e-9)
  expect_warning(vif_plot(fit), "no intercept")
  expect_no_warning(gvif_terms(lm(y ~ x1 + x2, data = d)))
})
