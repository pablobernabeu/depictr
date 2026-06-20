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

  # point estimates equal the fixed-effects-only prediction (re.form = NA)
  nd <- d[, c("word_frequency", "condition", "participant")]
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
