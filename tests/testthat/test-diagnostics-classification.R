test_that("influence_plot() and qq_plot() return ggplots", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  expect_s3_class(influence_plot(fit), "ggplot")
  expect_s3_class(qq_plot(fit), "ggplot")
  expect_s3_class(qq_plot(rnorm(50)), "ggplot")
  expect_error(influence_plot("nope"), "lm")
  expect_error(qq_plot(letters), "numeric")
})

test_that("roc_curve_plot() computes a sensible AUC", {
  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  p <- roc_curve_plot(gfit)
  expect_s3_class(p, "ggplot")
  auc <- attr(p, "auc")
  expect_true(auc >= 0.5 && auc <= 1)

  # Vector interface, perfect separation -> AUC 1
  actual <- c(0, 0, 1, 1)
  score  <- c(0.1, 0.2, 0.8, 0.9)
  expect_equal(attr(roc_curve_plot(actual, score), "auc"), 1)
})

test_that("calibration_plot() and confusion_matrix_plot() work", {
  gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
              family = binomial)
  expect_s3_class(calibration_plot(gfit, bins = 6), "ggplot")
  expect_s3_class(confusion_matrix_plot(gfit, threshold = 0.5), "ggplot")
  expect_s3_class(
    confusion_matrix_plot(c("a", "b", "a"), predicted = c("a", "a", "b")),
    "ggplot"
  )
  expect_error(confusion_matrix_plot(c(0, 1, 0)), "predicted")
})
