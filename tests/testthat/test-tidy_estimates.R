test_that("tidy_estimates() works on lm and glm", {
  fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
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
