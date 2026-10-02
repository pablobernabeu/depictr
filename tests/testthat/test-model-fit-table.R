# model_fit_table() and the model_report() subtitle: the deviance R-squared for
# every glm, computed from the fit without refitting a null model, and
# maximum-likelihood criteria for mixed models fitted by REML.

test_that("a Gaussian glm reports the R-squared of the identical lm", {
  # McFadden's ratio of log-likelihoods has no meaning once the log-likelihoods
  # are positive, as they are for this small residual variance. It used to
  # report -0.042 here against 0.364 for the same model fitted with lm().
  set.seed(42)
  d <- data.frame(x = runif(60))
  d$y <- 0.002 * d$x + rnorm(60, 0, 0.001)
  m <- glm(y ~ x, data = d)
  expect_equal(model_fit_table(m, digits = 12)$R2,
               summary(lm(y ~ x, data = d))$r.squared)
})

test_that("prior weights carry into the null model", {
  set.seed(7)
  d <- data.frame(x = runif(60), w = runif(60, 0.5, 3))
  d$y <- 1 + 2 * d$x + rnorm(60)
  m <- glm(y ~ x, data = d, weights = w)
  expect_equal(model_fit_table(m, digits = 12)$R2,
               summary(lm(y ~ x, data = d, weights = w))$r.squared)
})

test_that("a glm without an intercept has a null model without one", {
  # glm() leaves the intercept out of the null model when the model has none,
  # as summary.lm() does for its R-squared. update(m, . ~ 1) added one, so its
  # null model was not nested in the model.
  set.seed(8)
  d <- data.frame(x = rnorm(100))
  d$y <- 1 + 2 * d$x + rnorm(100)
  m <- glm(y ~ 0 + x, data = d)
  expect_equal(model_fit_table(m, digits = 12)$R2,
               summary(lm(y ~ 0 + x, data = d))$r.squared)
})

test_that("binary logistic regression keeps McFadden's value", {
  # With a 0/1 response the saturated log-likelihood is zero, so the deviance
  # R-squared and McFadden's ratio are the same number.
  m <- glm(accuracy ~ word_frequency + condition, family = binomial,
           data = lexical_decision)
  m0 <- glm(accuracy ~ 1, family = binomial, data = lexical_decision)
  mcfadden <- 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0))
  expect_equal(model_fit_table(m, digits = 12)$R2, mcfadden)
})

test_that("the null model uses the rows the model was fitted to", {
  # update(m, . ~ 1) refitted the null on every row with a response, 960 here,
  # while the model dropped the 50 with a missing predictor, which inflated the
  # value from 0.021 to 0.096.
  ld <- lexical_decision
  set.seed(3)
  ld$RT_na <- ld$RT
  ld$RT_na[sample(nrow(ld), 50)] <- NA
  m <- glm(accuracy ~ word_frequency + RT_na, family = binomial, data = ld)
  expect_equal(stats::nobs(m), 910)
  m0 <- glm(accuracy ~ 1, family = binomial, data = ld[!is.na(ld$RT_na), ])
  r2 <- model_fit_table(m, digits = 12)$R2
  expect_equal(r2, 1 - deviance(m) / deviance(m0))
  expect_equal(round(r2, 3), 0.021)
})

test_that("an offset in the formula stays in the null model", {
  set.seed(1)
  d <- data.frame(x = rnorm(200), expo = runif(200, 1, 10))
  d$y <- rpois(200, d$expo * exp(0.2 + 0.5 * d$x))
  m <- glm(y ~ x + offset(log(expo)), family = poisson, data = d)
  m0 <- glm(y ~ 1 + offset(log(expo)), family = poisson, data = d)
  expect_equal(model_fit_table(m, digits = 12)$R2,
               1 - deviance(m) / deviance(m0))
})

test_that("a glm fitted inside a function still gets an R-squared", {
  # update() re-evaluated the model call where the function's local data no
  # longer exist, and the R-squared came back NA.
  fit_locally <- function() {
    local_data <- data.frame(y = rbinom(100, 1, 0.5), x = rnorm(100))
    glm(y ~ x, family = binomial, data = local_data)
  }
  set.seed(5)
  m <- fit_locally()
  r2 <- model_fit_table(m, digits = 12)$R2
  expect_false(is.na(r2))
  expect_equal(r2, 1 - m$deviance / m$null.deviance)
})

test_that("a quasi-likelihood family reports the deviance R-squared", {
  # A quasi family has no log-likelihood, so McFadden's ratio was NA. Its
  # deviance is the Poisson deviance, so the two fits agree.
  set.seed(1)
  d <- data.frame(x = rnorm(200), expo = runif(200, 1, 10))
  d$y <- rpois(200, d$expo * exp(0.2 + 0.5 * d$x))
  mq <- glm(y ~ x + offset(log(expo)), family = quasipoisson, data = d)
  mp <- glm(y ~ x + offset(log(expo)), family = poisson, data = d)
  tab <- model_fit_table(quasi = mq, poisson = mp, digits = 12)
  expect_false(anyNA(tab$R2))
  expect_equal(tab$R2[1], tab$R2[2])
})

test_that("a response with no variation gives an R-squared of NA", {
  d <- data.frame(x = seq_len(20), y = 2)
  m <- glm(y ~ x, data = d)
  expect_identical(model_fit_table(m)$R2, NA_real_)
})

test_that("REML fits are compared on maximum-likelihood criteria", {
  skip_if_not_installed("lme4")
  correct <- subset(lexical_decision, accuracy == 1)
  full <- lme4::lmer(RT ~ condition + modality + word_frequency +
                       (1 | participant) + (1 | item), data = correct)
  reduced <- lme4::lmer(RT ~ condition + word_frequency +
                          (1 | participant) + (1 | item), data = correct)
  msgs <- capture_messages(
    tab <- model_fit_table(Reduced = reduced, Full = full, digits = 12)
  )
  # One message for the call, however many fits were refitted.
  expect_length(msgs, 1)
  expect_match(msgs, "refitted by maximum likelihood", fixed = TRUE)

  ml_full <- lme4::refitML(full)
  ml_reduced <- lme4::refitML(reduced)
  expect_equal(tab$AIC, c(stats::AIC(ml_reduced), stats::AIC(ml_full)))
  expect_equal(tab$BIC, c(stats::BIC(ml_reduced), stats::BIC(ml_full)))
  expect_equal(tab$logLik, c(as.numeric(stats::logLik(ml_reduced)),
                             as.numeric(stats::logLik(ml_full))))
  # The models themselves are described as supplied, and a mixed model has no
  # R-squared in the table.
  expect_equal(tab$n, c(stats::nobs(reduced), stats::nobs(full)))
  expect_true(all(is.na(tab$R2)))

  # A fit by maximum likelihood is reported as it is, without a message.
  full_ml <- lme4::lmer(RT ~ condition + modality + word_frequency +
                          (1 | participant) + (1 | item), data = correct,
                        REML = FALSE)
  expect_no_message(tab_ml <- model_fit_table(full_ml, digits = 12))
  expect_equal(tab_ml$AIC, stats::AIC(full_ml))
})

test_that("a failed maximum-likelihood refit warns and leaves the criteria NA", {
  skip_if_not_installed("lme4")
  correct <- subset(lexical_decision, accuracy == 1)
  m <- lme4::lmer(RT ~ condition + (1 | participant), data = correct)
  local_mocked_bindings(
    refitML = function(x, ...) stop("no convergence"),
    .package = "lme4"
  )
  expect_warning(
    tab <- model_fit_table(reml_fit = m),
    "reml_fit.*no convergence"
  )
  expect_true(all(is.na(tab[c("df", "AIC", "BIC", "logLik")])))
  expect_equal(tab$n, stats::nobs(m))
})

test_that("model_report() names the deviance R-squared for a glm", {
  m <- glm(accuracy ~ word_frequency + RT + condition, family = binomial,
           data = lexical_decision)
  subtitle <- model_report(m)$patches$annotation$subtitle
  text <- paste(deparse(subtitle), collapse = " ")
  expect_match(text, "deviance", fixed = TRUE)
  expect_no_match(text, "pseudo", fixed = TRUE)
  expect_match(text, formatC(1 - m$deviance / m$null.deviance, digits = 3,
                             format = "f"), fixed = TRUE)
})
