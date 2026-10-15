# Regression tests for prediction-grid bugs (t1-predictions):
#   (1) effects_plot()/interaction_plot() crashed on lme4 merMod models because
#       model_predict_grid() called predict(model, se.fit = TRUE), unsupported by
#       predict.merMod.
#   (2) lm intervals used a Normal (qnorm) multiplier instead of the t multiplier
#       with residual df, so bands did not match predict.lm()/confint().

test_that("lm prediction bands use a t multiplier and match predict.lm()", {
  fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)

  # numeric focal predictor
  p <- effects_plot(fit, "fertiliser")
  d <- p$data
  nd <- d[, c("rainfall", "fertiliser", "treatment")]
  ref <- predict(fit, newdata = nd, interval = "confidence", level = 0.95)
  expect_equal(d$lwr, unname(ref[, "lwr"]), tolerance = 1e-8)
  expect_equal(d$upr, unname(ref[, "upr"]), tolerance = 1e-8)

  # the t multiplier is strictly wider than the Normal one for finite df
  z <- qnorm(0.975)
  tmult <- qt(0.975, df.residual(fit))
  expect_gt(tmult, z)
  # band half-width should reflect the t multiplier, not z
  half <- (d$upr - d$lwr) / 2
  se <- unname(predict(fit, newdata = nd, se.fit = TRUE)$se.fit)
  expect_equal(half, tmult * se, tolerance = 1e-8)
  expect_false(isTRUE(all.equal(half, z * se)))

  # factor focal predictor also matches predict.lm()
  pf <- effects_plot(fit, "treatment")
  df <- pf$data
  ndf <- df[, c("rainfall", "fertiliser", "treatment")]
  reff <- predict(fit, newdata = ndf, interval = "confidence", level = 0.95)
  expect_equal(df$lwr, unname(reff[, "lwr"]), tolerance = 1e-8)
  expect_equal(df$upr, unname(reff[, "upr"]), tolerance = 1e-8)
})

test_that("glm prediction bands use a Wald (z) interval on the link scale", {
  gfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  p <- effects_plot(gfit, "word_frequency")
  d <- p$data
  nd <- d[, c("word_frequency", "condition")]
  pr <- predict(gfit, newdata = nd, type = "link", se.fit = TRUE)
  inv <- binomial()$linkinv
  z <- qnorm(0.975)
  expect_equal(d$fit, unname(inv(pr$fit)), tolerance = 1e-8)
  expect_equal(d$lwr, unname(inv(pr$fit - z * pr$se.fit)), tolerance = 1e-8)
  expect_equal(d$upr, unname(inv(pr$fit + z * pr$se.fit)), tolerance = 1e-8)
  # predicted probabilities and bands stay within [0, 1]
  expect_true(all(d$fit >= 0 & d$fit <= 1))
  expect_true(all(d$lwr >= 0 & d$upr <= 1))
})

test_that("glm bands take t where the model estimates its dispersion", {
  # Regression: the glm branch used z for every family, so a Gaussian glm drew
  # a band about 10% narrower than lm() on the same model at 12 residual df.
  # summary.glm() tests these families with t, and the band now follows it.
  small <- crop_yield[1:15, ]
  form <- yield ~ rainfall + fertiliser + treatment
  gfit <- glm(form, data = small, family = gaussian)
  lfit <- lm(form, data = small)
  pg <- effects_plot(gfit, "fertiliser")
  pl <- effects_plot(lfit, "fertiliser")
  expect_equal(pg$data$lwr, pl$data$lwr, tolerance = 1e-8)
  expect_equal(pg$data$upr, pl$data$upr, tolerance = 1e-8)
  ref <- predict(lfit, newdata = pg$data[c("rainfall", "fertiliser", "treatment")],
                 interval = "confidence")
  expect_equal(pg$data$upr, unname(ref[, "upr"]), tolerance = 1e-8)

  # A Gamma fit with a log link: t on the link scale, then back-transformed.
  gam <- glm(form, data = small, family = Gamma(link = "log"))
  p <- interaction_plot(gam, "fertiliser", "treatment")
  nd <- p$data[c("rainfall", "fertiliser", "treatment")]
  pr <- predict(gam, newdata = nd, type = "link", se.fit = TRUE)
  tq <- qt(0.975, df.residual(gam))
  expect_equal(p$data$lwr, unname(exp(pr$fit - tq * pr$se.fit)), tolerance = 1e-8)
  expect_equal(p$data$upr, unname(exp(pr$fit + tq * pr$se.fit)), tolerance = 1e-8)
})

test_that("effects_plot() works for lmer (merMod) numeric and factor predictors", {
  skip_if_not_installed("lme4")
  m <- lme4::lmer(RT ~ word_frequency + condition + (1 | participant),
                  data = lexical_decision)

  # numeric focal predictor: previously crashed (se.fit unsupported)
  p <- expect_silent(effects_plot(m, "word_frequency"))
  expect_s3_class(p, "ggplot")
  d <- p$data
  expect_true(all(is.finite(d$fit)))
  expect_true(all(d$lwr < d$fit & d$fit < d$upr))

  # point estimates equal the fixed-effects-only prediction (re.form = NA),
  # which needs no grouping variable in the grid
  nd <- d[, c("word_frequency", "condition")]
  ref <- predict(m, newdata = nd, re.form = NA)
  expect_equal(d$fit, unname(ref), tolerance = 1e-6)

  # SE matches the fixed-effect design matrix / vcov computation
  Terms <- delete.response(terms(m, fixed.only = TRUE))
  contr <- attr(model.matrix(m), "contrasts")
  X <- model.matrix(Terms, data = nd, contrasts.arg = contr)
  V <- as.matrix(vcov(m))
  X <- X[, colnames(V), drop = FALSE]
  se <- sqrt(diag(X %*% V %*% t(X)))
  expect_equal((d$upr - d$lwr) / 2, unname(qnorm(0.975) * se), tolerance = 1e-6)

  # factor focal predictor
  pf <- effects_plot(m, "condition")
  expect_s3_class(pf, "ggplot")
  expect_true(all(pf$data$lwr < pf$data$upr))
})

test_that("interaction_plot() works for lmer (merMod)", {
  skip_if_not_installed("lme4")
  m <- lme4::lmer(RT ~ word_frequency * condition + (1 | participant),
                  data = lexical_decision)
  p <- expect_silent(interaction_plot(m, "word_frequency", "condition"))
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$lwr < p$data$upr))
})

test_that("effects_plot() back-transforms glmer (merMod) to probabilities", {
  skip_if_not_installed("lme4")
  gm <- suppressMessages(suppressWarnings(
    lme4::glmer(accuracy ~ word_frequency + condition + (1 | participant),
                data = lexical_decision, family = binomial)
  ))
  p <- effects_plot(gm, "word_frequency")
  expect_s3_class(p, "ggplot")
  d <- p$data
  # binomial back-transform: fit and bands within [0, 1]
  expect_true(all(d$fit >= 0 & d$fit <= 1))
  expect_true(all(d$lwr >= 0 & d$upr <= 1))
  expect_identical(p$labels$y, "Predicted probability")
})

# Regression tests for transformed terms and offsets. The grid was built from
# model-frame columns such as `log(rainfall)`, while predict() rebuilds every
# term from the raw variable. Any model with a transformed term or an offset
# failed with "object not found", and where a transformed term sat beside its
# raw variable the plots silently drew a flat line or coincident lines.

# A newdata grid built by hand from the raw variables: each held at its mean or
# most frequent level over `data`, with `focal` swept over `values`.
raw_grid <- function(data, vars, focal, values) {
  held <- lapply(data[vars], function(x) {
    if (is.numeric(x)) return(mean(x))
    f <- as.factor(x)
    factor(names(which.max(table(f))), levels = levels(f))
  })
  held[[focal]] <- values
  expand.grid(held, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
}

test_that("effects_plot() predicts transformed terms from the raw variables", {
  forms <- list(
    log    = yield ~ log(rainfall) + fertiliser + treatment,
    poly   = yield ~ poly(fertiliser, 2) + rainfall + treatment,
    ns     = yield ~ splines::ns(rainfall, 3) + fertiliser + treatment,
    scale  = yield ~ scale(rainfall) + fertiliser + treatment,
    factor = yield ~ factor(treatment) + rainfall + fertiliser,
    I      = yield ~ I(rainfall^2) + fertiliser + treatment
  )
  vars <- c("rainfall", "fertiliser", "treatment")
  for (nm in names(forms)) {
    fit <- lm(forms[[nm]], data = crop_yield)
    for (focal in vars) {
      p <- effects_plot(fit, focal)
      expect_no_error(ggplot2::ggplot_build(p))
      d <- p$data
      values <- if (focal == "treatment") levels(crop_yield$treatment) else d[[focal]]
      nd <- raw_grid(crop_yield, vars, focal, values)
      expect_equal(d$fit, unname(predict(fit, newdata = nd)), tolerance = 1e-8,
                   label = paste0(nm, ", fit across ", focal))
      if (focal != "treatment") {
        expect_equal(range(d[[focal]]), range(crop_yield[[focal]]))
      }
    }
  }
})

test_that("a model-frame name such as log(rainfall) maps to its raw variable", {
  fit <- lm(yield ~ log(rainfall) + fertiliser + treatment, data = crop_yield)
  p <- effects_plot(fit, "log(rainfall)")
  expect_equal(p$data, effects_plot(fit, "rainfall")$data)
  expect_identical(p$labels$x, "rainfall")

  ffit <- lm(yield ~ factor(treatment) + rainfall, data = crop_yield)
  pf <- effects_plot(ffit, "factor(treatment)")
  expect_identical(levels(pf$data$treatment), levels(crop_yield$treatment))

  # A term built from two variables does not name one of them.
  fit2 <- lm(yield ~ I(rainfall * fertiliser) + treatment, data = crop_yield)
  expect_error(effects_plot(fit2, "I(rainfall * fertiliser)"),
               "rainfall, fertiliser")
  expect_error(effects_plot(fit, "not_a_var"),
               "must be one of the model's predictors")
})

test_that("a squared term beside its raw variable draws the whole curve", {
  # predict() ignored the grid column `I(rainfall^2)` and rebuilt the term from
  # rainfall held at its mean, so the line was flat.
  fit <- lm(yield ~ rainfall + I(rainfall^2) + fertiliser, data = crop_yield)
  p <- effects_plot(fit, "I(rainfall^2)")
  expect_gt(sd(p$data$fit), 0)
  nd <- raw_grid(crop_yield, c("rainfall", "fertiliser"), "rainfall",
                 p$data$rainfall)
  expect_equal(p$data$fit, unname(predict(fit, newdata = nd)), tolerance = 1e-8)
})

test_that("interaction_plot() draws distinct lines for a transformed moderator", {
  # The moderator column `log(rainfall)` was ignored in the same way, so the
  # three lines coincided.
  fit <- lm(yield ~ fertiliser * log(rainfall) + rainfall, data = crop_yield)
  p <- interaction_plot(fit, "fertiliser", "log(rainfall)")
  d <- p$data
  expect_equal(sort(unique(d$rainfall)),
               unname(quantile(crop_yield$rainfall, c(0.1, 0.5, 0.9))))
  at_max <- d$fit[d$fertiliser == max(d$fertiliser)]
  expect_length(unique(round(at_max, 6)), 3)
  expect_equal(d$fit, unname(predict(fit, newdata = d[c("fertiliser", "rainfall")])),
               tolerance = 1e-8)
  expect_identical(p$scales$get_scales("colour")$name, "rainfall")

  # A raw variable that appears only inside I() is still a variable to hold.
  fit2 <- lm(yield ~ I(rainfall^2) + fertiliser * treatment, data = crop_yield)
  p2 <- interaction_plot(fit2, "fertiliser", "treatment")
  expect_equal(unique(p2$data$rainfall), mean(crop_yield$rainfall))
  nd2 <- p2$data[c("fertiliser", "treatment", "rainfall")]
  expect_equal(p2$data$fit, unname(predict(fit2, newdata = nd2)), tolerance = 1e-8)

  expect_error(interaction_plot(fit, "rainfall", "log(rainfall)"),
               "same variable")
})

test_that("offset models are predicted at the mean offset, in both forms", {
  set.seed(1)
  d <- data.frame(x = rnorm(200), expo = runif(200, 1, 10),
                  arm = factor(rep(c("a", "b"), 100)))
  d$y <- rpois(200, d$expo * exp(0.2 + 0.5 * d$x))
  mean_off <- mean(log(d$expo))
  z <- qnorm(0.975)
  fits <- list(
    formula  = glm(y ~ x + offset(log(expo)), family = poisson, data = d),
    argument = glm(y ~ x, offset = log(expo), family = poisson, data = d)
  )
  for (nm in names(fits)) {
    fit <- fits[[nm]]
    p <- effects_plot(fit, "x")
    b <- unname(coef(fit))
    eta <- b[1] + b[2] * p$data$x + mean_off
    expect_equal(p$data$fit, exp(eta), tolerance = 1e-8, label = nm)
    se <- predict(fit, newdata = data.frame(x = p$data$x, expo = 1),
                  type = "link", se.fit = TRUE)$se.fit
    expect_equal(p$data$upr, exp(eta + z * unname(se)), tolerance = 1e-8)
    expect_identical(p$labels$y, "Predicted y at the mean offset")
  }
  # An offset is held fixed, so it is no predictor to vary.
  expect_error(effects_plot(fits$formula, "expo"), "offset")

  # The identity link of lm follows the same convention.
  lfit <- lm(y ~ x + offset(log(expo)), data = d)
  pl <- effects_plot(lfit, "x")
  expect_equal(pl$data$fit,
               unname(coef(lfit)[1] + coef(lfit)[2] * pl$data$x + mean_off),
               tolerance = 1e-8)

  ifit <- glm(y ~ x * arm + offset(log(expo)), family = poisson, data = d)
  pint <- interaction_plot(ifit, "x", "arm")
  bi <- coef(ifit)
  in_b <- pint$data$arm == "b"
  eta_b <- bi[["(Intercept)"]] + bi[["armb"]] +
    (bi[["x"]] + bi[["x:armb"]]) * pint$data$x[in_b] + mean_off
  expect_equal(pint$data$fit[in_b], unname(exp(eta_b)), tolerance = 1e-8)
  expect_identical(pint$labels$y, "Predicted y at the mean offset")
})

test_that("effects_plot() handles a transformed term in lmer", {
  skip_if_not_installed("lme4")
  m <- lme4::lmer(RT ~ log(word_frequency) + condition + (1 | participant),
                  data = lexical_decision)
  for (focal in c("condition", "word_frequency", "log(word_frequency)")) {
    p <- effects_plot(m, focal)
    expect_no_error(ggplot2::ggplot_build(p))
    d <- p$data
    ref <- predict(m, newdata = d[c("word_frequency", "condition")], re.form = NA)
    expect_equal(d$fit, unname(ref), tolerance = 1e-6, label = focal)
  }
  expect_equal(unique(effects_plot(m, "condition")$data$word_frequency),
               mean(lexical_decision$word_frequency))
})

test_that("glmer offsets are held at their mean, in both forms", {
  skip_if_not_installed("lme4")
  # predict.merMod adds only a formula offset to new data and drops an
  # `offset =` argument, so the fixed-effect predictor is formed directly.
  set.seed(4)
  d <- data.frame(x = rnorm(300), expo = runif(300, 1, 10),
                  g = factor(rep(1:15, each = 20)))
  d$y <- rpois(300, d$expo * exp(0.2 + 0.5 * d$x + rnorm(15, 0, 0.3)[d$g]))
  fits <- list(
    formula  = lme4::glmer(y ~ x + offset(log(expo)) + (1 | g),
                           family = poisson, data = d),
    argument = lme4::glmer(y ~ x + (1 | g), offset = log(expo),
                           family = poisson, data = d)
  )
  for (nm in names(fits)) {
    p <- effects_plot(fits[[nm]], "x")
    b <- unname(lme4::fixef(fits[[nm]]))
    expect_equal(p$data$fit, exp(b[1] + b[2] * p$data$x + mean(log(d$expo))),
                 tolerance = 1e-6, label = nm)
    expect_identical(p$labels$y, "Predicted y at the mean offset")
  }
})

test_that("a transformed model fitted to workspace vectors is refused", {
  # predict() found xv in the workspace, so the plot showed the fitted values,
  # in data order, against the grid without a word.
  set.seed(2)
  xv <- runif(100, 1, 50)
  yv <- 2 + 3 * log(xv) + rnorm(100)
  f <- lm(yv ~ log(xv))
  expect_error(effects_plot(f, "log(xv)"), "Cannot recover the data")
  expect_error(model_report(f), "Cannot recover the data")

  # Untransformed, the model frame holds the raw variable, which is enough.
  f2 <- lm(yv ~ xv)
  p <- effects_plot(f2, "xv")
  expect_equal(p$data$fit, unname(predict(f2, newdata = p$data["xv"])),
               tolerance = 1e-8)
})

test_that("data changed or removed since the fit are refused", {
  # Recovered data are checked against the model frame the fit stored, so a
  # stale data frame cannot supply typical values the model never saw.
  cy <- crop_yield
  fit <- lm(yield ~ log(rainfall) + fertiliser, data = cy)
  expect_s3_class(effects_plot(fit, "fertiliser"), "ggplot")
  cy$rainfall <- cy$rainfall * 2
  expect_error(effects_plot(fit, "fertiliser"),
               "`cy` is missing or has changed since the fit")
  rm(cy)
  expect_error(effects_plot(fit, "fertiliser"),
               "`cy` is missing or has changed since the fit")
})

test_that("held values and ranges come from the rows the model was fitted to", {
  cy <- crop_yield
  cy$yield[order(cy$rainfall, decreasing = TRUE)[1:60]] <- NA
  fit <- lm(yield ~ log(rainfall) + fertiliser + treatment, data = cy)
  est <- cy[!is.na(cy$yield), ]
  p <- effects_plot(fit, "fertiliser")
  expect_equal(unique(p$data$rainfall), mean(est$rainfall))
  expect_equal(range(p$data$fertiliser), range(est$fertiliser))
  pr <- effects_plot(fit, "rainfall")
  expect_equal(range(pr$data$rainfall), range(est$rainfall))
  # The rug shows the same rows.
  expect_equal(nrow(ggplot2::layer_data(pr, 3)), nrow(est))
})

test_that("a numeric variable that enters through factor() is held at its mode", {
  set.seed(3)
  d <- data.frame(dose = sample(c(1, 2, 4), 120, replace = TRUE,
                                prob = c(0.2, 0.5, 0.3)),
                  x = rnorm(120))
  d$y <- d$dose + d$x + rnorm(120)
  fit <- lm(y ~ factor(dose) + x, data = d)
  mode_dose <- as.numeric(names(which.max(table(d$dose))))
  expect_equal(unique(effects_plot(fit, "x")$data$dose), mode_dose)
  pf <- effects_plot(fit, "factor(dose)")
  expect_identical(levels(pf$data$dose), c("1", "2", "4"))
  nd <- data.frame(dose = c(1, 2, 4), x = mean(d$x))
  expect_equal(pf$data$fit, unname(predict(fit, newdata = nd)), tolerance = 1e-8)
})

test_that("a term computed from statistics of its rows is refused", {
  # predict() rebuilds I(rainfall - mean(rainfall)) from the grid's rows, so
  # the centring moved with the grid and the line shifted without a word.
  fit <- lm(yield ~ I(rainfall - mean(rainfall)) + fertiliser, data = crop_yield)
  expect_error(effects_plot(fit, "rainfall"),
               "`I\\(rainfall - mean\\(rainfall\\)\\)` depends on statistics")
  expect_error(effects_plot(fit, "fertiliser"), "depends on statistics")
  expect_error(model_report(fit), "depends on statistics")
  # Where the raw variable also enters untransformed, the model frame holds
  # it, and the plot used to draw a wrong line from there.
  fit2 <- lm(yield ~ rainfall + I(rainfall / max(rainfall)) + fertiliser,
             data = crop_yield)
  expect_error(effects_plot(fit2, "fertiliser"), "depends on statistics")
  fit3 <- lm(yield ~ fertiliser * treatment + I(rainfall > median(rainfall)),
             data = crop_yield)
  expect_error(interaction_plot(fit3, "fertiliser", "treatment"),
               "depends on statistics")
  # An offset is replaced by its mean, so one that takes statistics is fine.
  set.seed(1)
  d <- data.frame(x = rnorm(200), expo = runif(200, 1, 10))
  d$y <- rpois(200, d$expo * exp(0.2 + 0.5 * d$x))
  gfit <- glm(y ~ x + offset(log(expo / mean(expo))), family = poisson, data = d)
  p <- effects_plot(gfit, "x")
  b <- unname(coef(gfit))
  expect_equal(p$data$fit,
               exp(b[1] + b[2] * p$data$x + mean(log(d$expo / mean(d$expo)))),
               tolerance = 1e-8)
})

test_that("a formula or offset that reads a data frame with $ is refused", {
  # predict() took d$expo from d, whatever the grid held.
  set.seed(1)
  d <- data.frame(x = rnorm(200), expo = runif(200, 1, 10))
  d$y <- rpois(200, d$expo * exp(0.2 + 0.5 * d$x))
  fit <- glm(y ~ x, offset = log(d$expo), family = poisson, data = d)
  expect_error(effects_plot(fit, "x"), "reads columns of `d` with `\\$`")
  fit2 <- glm(y ~ x + offset(log(d[["expo"]])), family = poisson, data = d)
  expect_error(effects_plot(fit2, "x"), "reads columns of `d`")
  expect_error(effects_plot(lm(d$y ~ d$x), "x"), "reads columns of `d`")
})

test_that("a constant of a term stays out of the grid", {
  k <- 3
  kn <- unname(quantile(crop_yield$rainfall, c(0.33, 0.66)))
  for (fit in list(
    lm(yield ~ splines::ns(rainfall, df = k) + fertiliser, data = crop_yield),
    lm(yield ~ splines::ns(rainfall, knots = kn) + fertiliser, data = crop_yield)
  )) {
    p <- effects_plot(fit, "rainfall")
    expect_named(p$data, c("rainfall", "fertiliser", "fit", "lwr", "upr"),
                 ignore.order = TRUE)
    nd <- data.frame(rainfall = p$data$rainfall,
                     fertiliser = mean(crop_yield$fertiliser))
    expect_equal(p$data$fit, unname(predict(fit, newdata = nd)), tolerance = 1e-8)
  }
})

test_that("model_report() builds on a model with a transformed term", {
  fit <- lm(yield ~ log(rainfall) + fertiliser + treatment, data = crop_yield)
  r <- model_report(fit)
  expect_s3_class(r, "patchwork")
  # The default predictor is the raw numeric variable behind log(rainfall).
  expect_identical(r[[2]]$labels$title, "Effect of rainfall")
  withr::local_pdf(NULL)
  expect_no_error(print(r))
})
