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
  expect_error(binned_residual_plot(gfit, band = "nope"), "should be one of")
})

test_that("the binned-residual band is the standard error the model implies", {
  # The band was twice the residuals' own standard deviation in each bin over
  # the square root of its count, and it collapses where a bin's outcomes are
  # all alike. It is now twice the standard error of the bin's mean residual
  # under the fitted model. There a response residual has variance
  # phi * V(mu_i) / w_i and a Pearson residual variance phi. The expected
  # values come from the accessor functions, apart from the model components
  # the plot reads.
  withr::local_seed(31)
  n <- 240
  d <- data.frame(x = stats::rnorm(n), w = rep(c(1, 4), n / 2),
                  trials = sample(3:12, n, replace = TRUE))
  d$succ <- stats::rbinom(n, d$trials, stats::plogis(-0.5 + 0.8 * d$x))
  d$count <- stats::rnbinom(n, mu = exp(0.3 + 0.5 * d$x), size = 2)
  d$cont <- 1 + 0.5 * d$x + stats::rnorm(n, sd = 1 / sqrt(d$w))
  fits <- list(
    binomial = glm(adverse_event ~ biomarker + age + arm,
                   data = clinical_trial, family = binomial),
    `grouped binomial` = glm(cbind(succ, trials - succ) ~ x, data = d,
                             family = binomial),
    quasipoisson = glm(count ~ x, data = d, family = quasipoisson),
    `weighted gaussian` = glm(cont ~ x, data = d, weights = w),
    `weighted lm` = lm(cont ~ x, data = d, weights = w)
  )
  bins <- 12
  for (nm in names(fits)) {
    fit <- fits[[nm]]
    mu <- stats::fitted(fit)
    w <- stats::weights(fit)
    if (is.null(w)) w <- rep(1, length(mu))
    is_glm <- inherits(fit, "glm")
    v <- if (is_glm) stats::family(fit)$variance(mu) else rep(1, length(mu))
    phi <- if (is_glm) summary(fit)$dispersion else stats::sigma(fit)^2
    grp <- pmin(ceiling(rank(mu, ties.method = "first") / (length(mu) / bins)),
                bins)
    for (type in c("response", "pearson")) {
      r <- stats::residuals(fit, type = type)
      var_r <- if (type == "response") phi * v / w else rep(phi, length(mu))
      nb <- as.numeric(tapply(r, grp, length))
      bd <- attr(binned_residual_plot(fit, bins = bins, type = type), "bins")
      label <- paste(nm, type)
      expect_equal(bd$fitted, as.numeric(tapply(mu, grp, mean)),
                   tolerance = 1e-10, label = label)
      expect_equal(bd$resid, as.numeric(tapply(r, grp, mean)),
                   tolerance = 1e-10, label = label)
      expect_equal(bd$n, as.integer(nb), label = label)
      expect_equal(bd$se2, 2 * sqrt(as.numeric(tapply(var_r, grp, sum))) / nb,
                   tolerance = 1e-10, label = label)
      expect_identical(bd$outside, abs(bd$resid) > bd$se2, label = label)
    }
  }
})

test_that("the documented example, a correct model, stays inside the band", {
  # data-raw/generate_datasets.R simulates the adverse events from this very
  # model. The empirical band flagged 5 of its 17 bins, each of them a bin
  # without events, though at the lowest fitted values the model gives such a
  # bin a probability of 0.78.
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  bd <- attr(binned_residual_plot(gfit), "bins")
  expect_equal(nrow(bd), 17L)
  expect_lte(sum(bd$outside), 1)
})

test_that("band = 'empirical' reproduces the band of depictr 0.3.0", {
  # Twice the standard deviation of the residuals in each bin over the square
  # root of its count, the band arm::binnedplot() draws.
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  bins <- 12
  bd <- attr(binned_residual_plot(gfit, bins = bins, band = "empirical"),
             "bins")

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

  # At the default 17 bins, 0.3.0 drew these bounds and flagged five bins.
  bd <- attr(binned_residual_plot(gfit, band = "empirical"), "bins")
  expect_equal(bd$se2[1:3], c(0.001765791, 0.001317092, 0.001185107),
               tolerance = 1e-6)
  expect_identical(which(bd$outside), c(1L, 2L, 3L, 5L, 14L))
})

test_that("the model band flags about one bin in twenty under a correct model", {
  skip_on_cran()
  # Outcomes redrawn from the fitted model, which the refitted model then
  # specifies correctly. The empirical band flags most of the bins that hold
  # few events.
  withr::local_seed(2026)
  gfit <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  ct <- clinical_trial
  p <- stats::fitted(gfit)
  flagged <- vapply(seq_len(200), function(i) {
    ct$adverse_event <- stats::rbinom(nrow(ct), 1, p)
    refit <- glm(adverse_event ~ biomarker + age + arm, data = ct,
                 family = binomial)
    c(model = mean(depictr:::binned_residual_data(refit)$outside),
      empirical = mean(depictr:::binned_residual_data(
        refit, band = "empirical")$outside))
  }, numeric(2))
  share <- rowMeans(flagged)
  expect_lt(share[["model"]], 0.06)
  expect_gt(share[["empirical"]], 0.2)
})

test_that("observations with zero prior weight are left out of the bins", {
  # They take no part in the fit, and a variance divided by a zero weight
  # would make the band of their bin infinite. A Gaussian fit's dispersion
  # leaves them out as well, so its band is that of the fit without them.
  withr::local_seed(12)
  n <- 200
  d <- data.frame(x = stats::rnorm(n), w = 1)
  d$y <- stats::rbinom(n, 1, stats::plogis(0.3 + d$x))
  d$z <- 1 + d$x + stats::rnorm(n)
  d$w[c(5, 60, 140)] <- 0
  fits <- list(
    binomial = list(glm(y ~ x, data = d, family = binomial, weights = w),
                    glm(y ~ x, data = d[d$w > 0, ], family = binomial)),
    gaussian = list(glm(z ~ x, data = d, weights = w),
                    glm(z ~ x, data = d[d$w > 0, ]))
  )
  for (nm in names(fits)) {
    for (band in c("model", "empirical")) {
      if (nm == "gaussian" && band == "model") {
        # summary.glm() warns that its dispersion leaves them out.
        expect_warning(p <- binned_residual_plot(fits[[nm]][[1]], band = band),
                       "zero weight")
      } else {
        p <- binned_residual_plot(fits[[nm]][[1]], band = band)
      }
      expect_equal(attr(p, "bins"),
                   attr(binned_residual_plot(fits[[nm]][[2]], band = band),
                        "bins"),
                   tolerance = 1e-8, label = paste(nm, band))
    }
  }
})

test_that("binned residuals of an na.exclude fit are those of its na.omit twin", {
  # The band reads the prior weights, which hold one value per row of the fit,
  # so the fitted values and residuals must too.
  d <- lexical_decision
  d$RT_na <- d$RT
  d$RT_na[seq(1, nrow(d), length.out = 50)] <- NA
  fe <- glm(accuracy ~ word_frequency + RT_na, data = d, family = binomial,
            na.action = na.exclude)
  fo <- glm(accuracy ~ word_frequency + RT_na, data = d, family = binomial,
            na.action = na.omit)
  for (band in c("model", "empirical")) {
    for (type in c("response", "pearson")) {
      expect_identical(
        attr(binned_residual_plot(fe, type = type, band = band), "bins"),
        attr(binned_residual_plot(fo, type = type, band = band), "bins"),
        label = paste(band, type)
      )
    }
  }
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

  # Including in a session that has not drawn a random number yet: there is no
  # state to save, so the restoration is to leave .Random.seed absent rather
  # than let the internal set.seed() leak into the caller's stream.
  saved <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(assign(".Random.seed", saved, envir = .GlobalEnv), add = TRUE)

  rm(".Random.seed", envir = .GlobalEnv)
  invisible(depictr:::quantile_residuals(gfit, seed = 7))
  expect_false(exists(".Random.seed", envir = .GlobalEnv))

  vals <- stats::rnorm(50)
  rm(".Random.seed", envir = .GlobalEnv)
  invisible(depictr:::qq_band(vals, type = "simulate", seed = 3, n_sim = 20))
  expect_false(exists(".Random.seed", envir = .GlobalEnv))
})

test_that("quantile residuals handle a cbind(successes, failures) response", {
  # Regression: as.numeric() flattened the n x 2 response matrix and the raw
  # success counts were multiplied by the trial totals again, so the residuals
  # centred far from zero instead of on it.
  set.seed(21)
  n <- 400
  xx <- rnorm(n)
  trials <- sample(5:20, n, replace = TRUE)
  succ <- rbinom(n, trials, plogis(-0.4 + 0.8 * xx))
  fit <- glm(cbind(succ, trials - succ) ~ xx, family = binomial)

  qr <- depictr:::quantile_residuals(fit, seed = 1)
  expect_true(isTRUE(attr(qr, "quantile")))
  expect_length(qr, n)
  # Approximately standard normal under correct specification.
  expect_lt(abs(mean(qr)), 0.15)
  expect_gt(stats::ks.test(as.numeric(qr), "pnorm")$p.value, 0.05)
})

test_that("quantile residuals of an na.exclude fit are the na.omit ones, padded", {
  # Under na.exclude, fitted() and residuals() are padded with NA to the data's
  # length while the model frame is not. The residuals paired the padded fitted
  # values with the unpadded response, recycling one against the other, and
  # took the Gaussian scale from padded residuals, so every value came out NA.
  d <- lexical_decision
  d$RT_na <- d$RT
  d$RT_na[seq(1, nrow(d), length.out = 50)] <- NA
  fit_with <- list(
    binomial = function(na) {
      glm(accuracy ~ word_frequency + RT_na, data = d, family = binomial,
          na.action = na)
    },
    gaussian = function(na) {
      glm(RT_na ~ word_frequency + condition, data = d, na.action = na)
    },
    lm = function(na) lm(RT_na ~ word_frequency + condition, data = d,
                         na.action = na)
  )
  for (nm in names(fit_with)) {
    fe <- fit_with[[nm]](na.exclude)
    fo <- fit_with[[nm]](na.omit)
    expect_silent(qe <- depictr:::quantile_residuals(fe, seed = 3))
    qo <- depictr:::quantile_residuals(fo, seed = 3)
    expect_true(isTRUE(attr(qe, "quantile")))
    # One value per row of the data, NA exactly where the fit left a row out.
    expect_length(qe, nrow(d))
    expect_identical(unname(which(is.na(qe))), as.integer(fe$na.action),
                     label = paste(nm, "NA positions"))
    expect_equal(as.numeric(qe[!is.na(qe)]), as.numeric(qo),
                 label = paste(nm, "residuals"))
  }
})

test_that("quantile residuals honour prior weights in the Gaussian and Gamma scales", {
  # Under prior weights w, the variance of observation i is phi * V(mu_i) / w_i.
  # One scale served every observation, so with weights 1 and 16 the second
  # group's residuals had an SD of 0.25 under a correctly specified model.
  withr::local_seed(2026)
  n <- 2000
  x <- stats::rnorm(n)
  w <- rep(c(1, 16), each = n / 2)

  y <- 1 + 0.5 * x + stats::rnorm(n, sd = 2 / sqrt(w))
  fits <- list(glm = glm(y ~ x, weights = w), lm = lm(y ~ x, weights = w))
  for (nm in names(fits)) {
    qr <- as.numeric(depictr:::quantile_residuals(fits[[nm]]))
    sds <- tapply(qr, w, stats::sd)
    expect_gt(min(sds), 0.9, label = paste(nm, "smallest group SD"))
    expect_lt(max(sds), 1.1, label = paste(nm, "largest group SD"))
    # For a Gaussian model, the quantile residual is the weighted residual
    # divided by sigma.
    expect_equal(qr, unname(sqrt(w) * stats::residuals(fits[[nm]], "response") /
                              stats::sigma(fits[[nm]])),
                 tolerance = 1e-8)
  }

  mu <- exp(0.5 + 0.3 * x)
  yg <- stats::rgamma(n, shape = 4 * w, rate = 4 * w / mu)
  gfit <- glm(yg ~ x, weights = w, family = Gamma(link = "log"))
  qr <- as.numeric(depictr:::quantile_residuals(gfit))
  sds <- tapply(qr, w, stats::sd)
  expect_gt(min(sds), 0.9, label = "Gamma smallest group SD")
  expect_lt(max(sds), 1.1, label = "Gamma largest group SD")
})

test_that("an observation with zero prior weight has no quantile residual", {
  # It takes no part in the fit, so nobs() leaves it out. Dividing its variance
  # by a zero weight would otherwise give it a residual of 0 (Gaussian) or
  # -8.1, the clamped tail (Gamma).
  withr::local_seed(17)
  n <- 200
  x <- stats::rnorm(n)
  w <- rep(1, n)
  w[c(3, 50)] <- 0
  y <- 1 + x + stats::rnorm(n)
  yg <- stats::rgamma(n, shape = 5, rate = 5 / exp(0.2 * x))
  fits <- list(
    gaussian = list(glm(y ~ x, weights = w),
                    glm(y ~ x, subset = w > 0)),
    Gamma = list(glm(yg ~ x, weights = w, family = Gamma(link = "log")),
                 glm(yg ~ x, subset = w > 0, family = Gamma(link = "log")))
  )
  for (nm in names(fits)) {
    # summary.glm() warns that its dispersion estimate leaves them out.
    expect_warning(qr <- depictr:::quantile_residuals(fits[[nm]][[1]]),
                   "zero weight")
    expect_identical(unname(which(is.na(qr))), c(3L, 50L),
                     label = paste(nm, "NA positions"))
    # The others are those of the same model fitted without the two rows.
    expect_equal(as.numeric(qr[-c(3, 50)]),
                 as.numeric(depictr:::quantile_residuals(fits[[nm]][[2]])),
                 label = paste(nm, "residuals"))
  }
})

test_that("diagnostic plots draw an na.exclude fit as its na.omit twin", {
  # A Gaussian glm under na.exclude drew an empty Q-Q panel, and every frame
  # built from padded values carried the excluded rows. ggplot2 warned that it
  # removed them, and influence_plot() counted them in the 2p/n leverage line.
  d <- lexical_decision
  d$RT_na <- d$RT
  d$RT_na[seq(1, nrow(d), length.out = 50)] <- NA
  fit_with <- list(
    gaussian = function(na) {
      glm(RT_na ~ word_frequency + condition, data = d, na.action = na)
    },
    binomial = function(na) {
      glm(accuracy ~ word_frequency + RT_na, data = d, family = binomial,
          na.action = na)
    },
    lm = function(na) lm(RT_na ~ word_frequency + condition, data = d,
                         na.action = na)
  )
  # Builds each panel under na.exclude and na.omit, checks that the first
  # builds without warnings and that both draw the same layer data.
  same_panels <- function(nm, draw, panels = 1L) {
    pe <- draw(fit_with[[nm]](na.exclude))
    po <- draw(fit_with[[nm]](na.omit))
    if (!inherits(pe, "patchwork")) {
      pe <- list(pe)
      po <- list(po)
    }
    lapply(seq_len(panels), function(k) {
      expect_no_warning(be <- ggplot2::ggplot_build(pe[[k]]))
      expect_identical(be$data, ggplot2::ggplot_build(po[[k]])$data,
                       label = paste(nm, "panel", k, "layer data"))
      be
    })
  }
  n_fit <- nrow(d) - 50

  # The GLM panels: binned residuals, quantile-residual Q-Q, scale-location
  # and residuals against leverage.
  built <- same_panels("gaussian", residual_diagnostics_plot, panels = 4)
  expect_equal(nrow(built[[2]]$data[[1]]), n_fit, label = "Gaussian Q-Q points")
  built <- same_panels("binomial", function(m) {
    residual_diagnostics_plot(m, which = "qq", seed = 1)
  })
  expect_equal(nrow(built[[1]]$data[[1]]), n_fit, label = "binomial Q-Q points")
  # The classic panels, as an lm gets them.
  same_panels("lm", function(m) {
    residual_diagnostics_plot(m, which = c("resid_fitted", "qq"))
  }, panels = 2)
  same_panels("gaussian", influence_plot)
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

test_that("model_report() draws the GLM panels for a glm", {
  # It drew a residuals-against-fitted scatter and a Q-Q plot of standardised
  # deviance residuals for every glm. Those residuals are not expected to look
  # normal for a binary or count response, even under a correct model.
  withr::local_seed(5)
  withr::local_pdf(NULL)
  n <- 300
  d <- data.frame(x = stats::rnorm(n))
  d$y_binary <- stats::rbinom(n, 1, stats::plogis(-0.2 + 0.9 * d$x))
  d$y_count <- stats::rpois(n, exp(0.4 + 0.5 * d$x))
  d$y_cont <- 1 + 0.5 * d$x + stats::rnorm(n)
  fits <- list(
    binomial = glm(y_binary ~ x, family = binomial, data = d),
    poisson = glm(y_count ~ x, family = poisson, data = d),
    gaussian = glm(y_cont ~ x, data = d)
  )
  for (nm in names(fits)) {
    # The default arguments, so the old code runs this call and fails on the
    # panels themselves.
    r <- model_report(fits[[nm]])
    titles <- vapply(seq_along(r), function(k) r[[k]]$labels$title,
                     character(1))
    expect_identical(titles[3:4], c("Binned residuals", "Normal Q-Q"),
                     label = paste(nm, "panel titles"))
    expect_identical(r[[4]]$labels$y, "Quantile residuals",
                     label = paste(nm, "Q-Q axis"))
    expect_no_warning(print(r))
  }
})

test_that("a correct logistic model stays inside the model_report() Q-Q band", {
  # About a third of the standardised deviance residuals of a correctly
  # specified logistic model fell outside the band, the picture of a broken
  # model. Quantile residuals are standard normal under the model.
  withr::local_seed(2026)
  n <- 400
  d <- data.frame(x1 = stats::rnorm(n), x2 = stats::rnorm(n))
  d$y <- stats::rbinom(n, 1, stats::plogis(-0.3 + 1.2 * d$x1 - 0.8 * d$x2))
  fit <- glm(y ~ x1 + x2, family = binomial, data = d)
  outside <- function(report) {
    band <- ggplot2::layer_data(report[[4]], 1)
    points <- ggplot2::layer_data(report[[4]], 2)
    expect_equal(points$x, band$x)
    mean(points$y < band$ymin | points$y > band$ymax)
  }
  r <- model_report(fit, seed = 1)
  expect_lt(outside(r), 0.10)
  # The seed makes the randomised residuals reproducible.
  expect_identical(ggplot2::layer_data(r[[4]], 2)$y,
                   ggplot2::layer_data(model_report(fit, seed = 1)[[4]], 2)$y)
  # The classic panels, still available, flag the same correct model.
  expect_gt(outside(model_report(fit, glm_panels = FALSE)), 0.20)
})

test_that("model_report() keeps the classic panels for an lm or on request", {
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  r <- model_report(fit)
  expect_identical(r[[3]]$labels$title, "Residuals vs. fitted")
  expect_identical(r[[4]]$labels$y, "Standardised residuals")

  gfit <- glm(adverse_event ~ biomarker + age + arm, data = clinical_trial,
              family = binomial)
  rc <- model_report(gfit, glm_panels = FALSE)
  expect_identical(rc[[3]]$labels$title, "Residuals vs. fitted")
  expect_identical(rc[[4]]$labels$y, "Standardised residuals")
})

test_that("model_report() names deviance residuals for an unsupported family", {
  # quantile_residuals() has no distribution for a quasi-likelihood family and
  # falls back to the deviance residuals, which the axis must not call
  # quantile residuals.
  withr::local_seed(8)
  d <- data.frame(x = stats::rnorm(200))
  d$y <- stats::rnbinom(200, mu = exp(0.5 + 0.4 * d$x), size = 2)
  fit <- glm(y ~ x, family = quasipoisson, data = d)
  r <- model_report(fit)
  expect_identical(r[[3]]$labels$title, "Binned residuals")
  expect_identical(r[[4]]$labels$y, "Deviance residuals")
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
