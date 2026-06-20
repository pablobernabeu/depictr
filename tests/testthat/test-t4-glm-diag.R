# GLM-appropriate diagnostics: binned residuals, quantile residuals, QQ band ---

test_that("binned_residual_plot() returns a ggplot and per-bin summary", {
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  p <- binned_residual_plot(gfit, bins = 12)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))

  bd <- attr(p, "bins")
  expect_s3_class(bd, "data.frame")
  expect_equal(nrow(bd), 12L)
  expect_true(all(c("fitted", "resid", "n", "se2", "outside") %in% names(bd)))

  expect_error(binned_residual_plot("nope"), "lm")
  expect_error(binned_residual_plot(gfit, bins = 1), "bins")
})

test_that("binned bounds equal 2*sd/sqrt(n) per bin (independent recompute)", {
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  bins <- 12
  bd <- attr(binned_residual_plot(gfit, bins = bins), "bins")

  fitted <- as.numeric(stats::fitted(gfit))
  resid  <- as.numeric(stats::residuals(gfit, type = "response"))
  n <- length(fitted)
  rk  <- rank(fitted, ties.method = "first")
  grp <- pmin(ceiling(rk / (n / bins)), bins)
  agg <- do.call(rbind, lapply(split(seq_len(n), grp), function(ix) {
    rb <- resid[ix]; nb <- length(ix)
    data.frame(fitted = mean(fitted[ix]), resid = mean(rb),
               se2 = 2 * stats::sd(rb) / sqrt(nb))
  }))
  agg <- agg[order(agg$fitted), , drop = FALSE]

  expect_equal(bd$resid, agg$resid, tolerance = 1e-10)
  expect_equal(bd$se2,   agg$se2,   tolerance = 1e-10)
  # The outside flag is exactly |mean resid| > 2 sd / sqrt(n)
  expect_equal(bd$outside, abs(bd$resid) > bd$se2)
})

test_that("quantile residuals are ~uniform for a well-specified GLM", {
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  qr <- depictr:::quantile_residuals(gfit, seed = 99)
  expect_true(isTRUE(attr(qr, "quantile")))
  expect_length(qr, nrow(clinical_trial))

  # u = Phi(r) should be Uniform(0, 1) under correct specification.
  u <- stats::pnorm(as.numeric(qr))
  expect_gt(stats::ks.test(u, "punif")$p.value, 0.05)
  # ... and the residuals themselves ~ N(0, 1).
  expect_gt(stats::ks.test(as.numeric(qr), "pnorm")$p.value, 0.05)
})

test_that("quantile residuals detect distributional misspecification", {
  skip_on_cran()
  set.seed(11)
  nn <- 1200
  xx <- rnorm(nn)
  mu <- exp(0.5 + 0.7 * xx)

  # Overdispersed (negative-binomial) counts fitted with a plain Poisson.
  y_over <- stats::rnbinom(nn, mu = mu, size = 1.2)
  bad <- glm(y_over ~ xx, family = poisson)
  pb <- stats::ks.test(stats::pnorm(depictr:::quantile_residuals(bad, seed = 1)),
                       "punif")$p.value
  expect_lt(pb, 0.01)

  # Correctly-specified Poisson on Poisson data is not rejected.
  y_pois <- stats::rpois(nn, mu)
  good <- glm(y_pois ~ xx, family = poisson)
  pg <- stats::ks.test(stats::pnorm(depictr:::quantile_residuals(good, seed = 1)),
                       "punif")$p.value
  expect_gt(pg, 0.05)
})

test_that("quantile residuals are reproducible with a seed", {
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  a <- depictr:::quantile_residuals(gfit, seed = 7)
  b <- depictr:::quantile_residuals(gfit, seed = 7)
  expect_identical(as.numeric(a), as.numeric(b))
  # Seeding must not disturb the caller's RNG stream.
  set.seed(1); s1 <- runif(1)
  set.seed(1); invisible(depictr:::quantile_residuals(gfit, seed = 7)); s2 <- runif(1)
  expect_identical(s1, s2)
})

test_that("residual_diagnostics_plot() is glm-aware but lm is unchanged", {
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  pg <- residual_diagnostics_plot(gfit, seed = 1)
  expect_s3_class(pg, "patchwork")
  expect_silent(ggplot2::ggplot_build(patchwork::wrap_plots(pg)))
  # The resid-vs-fitted panel is the binned-residual plot for a glm.
  expect_equal(pg[[1]]$labels$x, "Mean fitted value (binned)")
  # The Q-Q panel uses quantile residuals.
  expect_equal(pg[[2]]$labels$y, "Quantile residuals")

  # glm_panels = FALSE forces the classic lm-style panels.
  pgc <- residual_diagnostics_plot(gfit, glm_panels = FALSE)
  expect_equal(pgc[[1]]$labels$x, "Fitted values")
  expect_equal(pgc[[2]]$labels$y, "Standardised residuals")

  # lm behaviour: classic panels, builds cleanly.
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  pl <- residual_diagnostics_plot(fit)
  expect_s3_class(pl, "patchwork")
  expect_equal(pl[[1]]$labels$x, "Fitted values")
  expect_equal(pl[[2]]$labels$y, "Standardised residuals")
  expect_silent(ggplot2::ggplot_build(patchwork::wrap_plots(pl)))
})

test_that("qq_plot() draws a band and keeps working without one", {
  set.seed(1)
  p1 <- qq_plot(rnorm(100))
  expect_s3_class(p1, "ggplot")
  expect_silent(ggplot2::ggplot_build(p1))

  p2 <- qq_plot(stats::rt(100, df = 3), band_type = "simulate", seed = 1)
  expect_silent(ggplot2::ggplot_build(p2))

  # band = FALSE removes the ribbon layer; band = TRUE adds one.
  has_ribbon <- function(p) {
    any(vapply(ggplot2::ggplot_build(p)$plot$layers,
               function(l) inherits(l$geom, "GeomRibbon"), logical(1)))
  }
  expect_true(has_ribbon(qq_plot(rnorm(80))))
  expect_false(has_ribbon(qq_plot(rnorm(80), band = FALSE)))

  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  expect_silent(ggplot2::ggplot_build(qq_plot(fit)))
  expect_error(qq_plot(letters), "numeric")
})

test_that("qq band has ~nominal pointwise coverage and detects heavy tails", {
  skip_on_cran()
  set.seed(123)
  reps <- 200; n <- 200; level <- 0.95
  inside <- numeric(reps)
  for (r in seq_len(reps)) {
    v  <- rnorm(n)
    bd <- depictr:::qq_band(v, type = "pointwise", level = level)
    sorted <- sort(v)
    inside[r] <- mean(sorted >= bd$lower & sorted <= bd$upper)
  }
  # Pointwise band: average per-point coverage close to nominal.
  expect_equal(mean(inside), level, tolerance = 0.04)

  # Heavy-tailed sample exits the band far more often than a normal one.
  set.seed(9)
  out_t <- mean(replicate(150, {
    v <- stats::rt(150, df = 2)
    bd <- depictr:::qq_band(v, type = "pointwise", level = 0.95)
    sum(sort(v) < bd$lower | sort(v) > bd$upper)
  }))
  set.seed(9)
  out_n <- mean(replicate(150, {
    v <- rnorm(150)
    bd <- depictr:::qq_band(v, type = "pointwise", level = 0.95)
    sum(sort(v) < bd$lower | sort(v) > bd$upper)
  }))
  expect_gt(out_t, 3 * out_n)
})
