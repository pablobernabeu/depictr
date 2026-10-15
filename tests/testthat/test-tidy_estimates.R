test_that("tidy_estimates() works on lm and glm", {
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  te <- tidy_estimates(fit)
  expect_s3_class(te, "data.frame")
  expect_named(te, c("term", "estimate", "std.error", "conf.low", "conf.high"))
  expect_equal(nrow(te), 3L)
  expect_true(all(te$conf.low <= te$estimate & te$estimate <= te$conf.high))

  gfit <- glm(accuracy ~ word_frequency, data = lexical_decision,
              family = binomial)
  tg <- tidy_estimates(gfit)
  expect_equal(nrow(tg), 2L)
  expect_false(any(is.na(tg$conf.low)))
})

test_that("tidy_estimates() standardises a data frame and back-fills CIs", {
  df <- data.frame(
    parameter = c("a", "b"),
    Estimate = c(0.2, -0.4),
    `2.5 %` = c(0.1, -0.6),
    `97.5 %` = c(0.3, -0.2),
    check.names = FALSE
  )
  te <- tidy_estimates(df)
  expect_equal(te$term, c("a", "b"))
  expect_equal(te$conf.low, c(0.1, -0.6))

  # No CI columns but an SE -> Wald interval is computed
  df2 <- data.frame(term = "a", estimate = 1, std.error = 0.5)
  te2 <- tidy_estimates(df2, conf_level = 0.95)
  expect_equal(round(te2$conf.low, 3), round(1 - qnorm(0.975) * 0.5, 3))
})

test_that("tidy_estimates() errors helpfully without an estimate column", {
  expect_error(tidy_estimates(data.frame(x = 1)), "estimate column")
})

test_that("a glm with an estimated dispersion gets the t intervals its tests use", {
  # Regression: every glm took z limits, while summary.glm() tests with t on
  # the residual degrees of freedom whenever the dispersion is estimated. On
  # 15 rows (12 residual df) the Gaussian intervals were 10% too narrow and
  # disagreed with lm() on the same model.
  small <- crop_yield[1:15, ]
  form <- yield ~ rainfall + fertiliser
  te_glm <- tidy_estimates(glm(form, data = small, family = gaussian))
  te_lm <- tidy_estimates(lm(form, data = small))
  ci_lm <- confint(lm(form, data = small))
  expect_equal(te_glm$conf.low, unname(ci_lm[, 1]))
  expect_equal(te_glm$conf.high, unname(ci_lm[, 2]))
  expect_equal(te_glm, te_lm)

  # Gamma and quasi-Poisson fits estimate the dispersion too.
  t_limits <- function(fit) {
    co <- coef(summary(fit))
    tq <- qt(0.975, df.residual(fit))
    cbind(co[, 1] - tq * co[, 2], co[, 1] + tq * co[, 2])
  }
  gfit <- glm(form, data = small, family = Gamma(link = "log"))
  expect_equal(as.matrix(tidy_estimates(gfit)[, c("conf.low", "conf.high")]),
               unname(t_limits(gfit)), ignore_attr = TRUE)
  set.seed(5)
  counts <- data.frame(x = rnorm(20))
  counts$y <- rpois(20, exp(1 + 0.4 * counts$x))
  qfit <- glm(y ~ x, data = counts, family = quasipoisson)
  expect_equal(as.matrix(tidy_estimates(qfit)[, c("conf.low", "conf.high")]),
               unname(t_limits(qfit)), ignore_attr = TRUE)
  # The level is honoured on the t scale as well.
  te90 <- tidy_estimates(glm(form, data = small), conf_level = 0.9)
  expect_equal(te90$conf.low,
               unname(confint(lm(form, data = small), level = 0.9)[, 1]))
})

test_that("binomial, Poisson and negative binomial fits keep z intervals", {
  # Their summaries test with z, since the dispersion is fixed. MASS::glm.nb
  # fixes it at 1 in summary(), which is why the rule reads the summary and
  # not a list of families.
  z_limits <- function(fit) {
    co <- coef(summary(fit))
    z <- qnorm(0.975)
    cbind(co[, 1] - z * co[, 2], co[, 1] + z * co[, 2])
  }
  bfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  expect_equal(as.matrix(tidy_estimates(bfit)[, c("conf.low", "conf.high")]),
               unname(z_limits(bfit)), ignore_attr = TRUE)
  set.seed(5)
  counts <- data.frame(x = rnorm(40))
  counts$y <- rpois(40, exp(1 + 0.4 * counts$x))
  pfit <- glm(y ~ x, data = counts, family = poisson)
  expect_equal(as.matrix(tidy_estimates(pfit)[, c("conf.low", "conf.high")]),
               unname(z_limits(pfit)), ignore_attr = TRUE)

  skip_if_not_installed("MASS")
  counts$y <- MASS::rnegbin(40, exp(1 + 0.4 * counts$x), theta = 2)
  nbfit <- MASS::glm.nb(y ~ x, data = counts)
  expect_identical(colnames(coef(summary(nbfit)))[3], "z value")
  expect_equal(as.matrix(tidy_estimates(nbfit)[, c("conf.low", "conf.high")]),
               unname(z_limits(nbfit)), ignore_attr = TRUE)
})

test_that("exponentiate gives ratios with the standard error left on the link scale", {
  # Regression: tidy_estimates(glm, exponentiate = TRUE) swallowed the argument
  # in `...` and returned log-odds, where broom::tidy() returns odds ratios.
  bfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  link <- tidy_estimates(bfit)
  te <- tidy_estimates(bfit, exponentiate = TRUE)
  expect_equal(te$term, link$term)
  expect_equal(te$estimate, unname(exp(coef(bfit))))
  expect_equal(te$conf.low, exp(link$conf.low))
  expect_equal(te$conf.high, exp(link$conf.high))
  expect_equal(te$std.error, link$std.error)
  expect_equal(tidy_estimates(bfit, exponentiate = FALSE), link)

  # A data frame is read as link-scale estimates. Limits filled in from the
  # standard error are filled in on that scale, then exponentiated.
  df <- data.frame(term = c("a", "b"), estimate = c(0.2, -0.4),
                   std.error = c(0.1, 0.2))
  te_df <- tidy_estimates(df, exponentiate = TRUE)
  z <- qnorm(0.975)
  expect_equal(te_df$estimate, exp(c(0.2, -0.4)))
  expect_equal(te_df$conf.low, exp(c(0.2, -0.4) - z * c(0.1, 0.2)))
  expect_equal(te_df$std.error, c(0.1, 0.2))

  # exp() of an lm(log(y) ~ x) slope is a ratio of geometric means.
  lfit <- lm(log(yield) ~ rainfall, data = crop_yield)
  expect_equal(tidy_estimates(lfit, exponentiate = TRUE)$estimate,
               unname(exp(coef(lfit))))

  expect_error(tidy_estimates(bfit, exponentiate = NA),
               "`exponentiate` must be TRUE or FALSE", fixed = TRUE)
})

test_that("exponentiate is honoured for glmer fits", {
  skip_if_not_installed("lme4")
  gm <- suppressMessages(suppressWarnings(
    lme4::glmer(accuracy ~ word_frequency + condition + (1 | participant),
                data = lexical_decision, family = binomial)
  ))
  link <- tidy_estimates(gm)
  te <- tidy_estimates(gm, exponentiate = TRUE)
  expect_equal(te$estimate, unname(exp(lme4::fixef(gm))))
  expect_equal(te$conf.high, exp(link$conf.high))
  expect_equal(te$std.error, link$std.error)
})

test_that("a rank-deficient lm drops aliased terms with a message", {
  # Regression: coef(summary()) omits aliased rows while confint() keeps them
  # as NA rows, so binding the columns failed with a raw "differing number of
  # rows" error.
  set.seed(3)
  d <- data.frame(y = rnorm(20), x1 = rnorm(20))
  d$x2 <- 2 * d$x1  # perfectly collinear
  fit <- lm(y ~ x1 + x2, data = d)

  expect_message(te <- tidy_estimates(fit), "aliased term(s)", fixed = TRUE)
  expect_message(tidy_estimates(fit), "x2", fixed = TRUE)
  expect_equal(te$term, c("(Intercept)", "x1"))
  expect_false(anyNA(te$conf.low))
  expect_false(anyNA(te$conf.high))

  # A full-rank fit stays silent.
  expect_silent(tidy_estimates(lm(y ~ x1, data = d)))
})
