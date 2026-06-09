test_that("gain_plot() and lift_plot() work from glm and vectors", {
  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  expect_s3_class(gain_plot(gfit), "ggplot")
  expect_s3_class(lift_plot(gfit), "ggplot")
  expect_s3_class(gain_plot(c(0, 0, 1, 1), c(0.1, 0.2, 0.8, 0.9)), "ggplot")
  expect_error(gain_plot(c(1, 1, 1), c(0.1, 0.2, 0.3)),
               "both positive and negative")
})

test_that("gain_table() captures all positives at full depth", {
  g <- depictr:::gain_table(c(0, 1, 0, 1), c(0.1, 0.9, 0.2, 0.8))
  expect_equal(g$population[1], 0)
  expect_equal(g$captured[1], 0)
  expect_equal(g$population[nrow(g)], 1)
  expect_equal(g$captured[nrow(g)], 1)   # all positives captured at 100%
})

test_that("model_report() returns a patchwork for lm and glm", {
  fit <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment,
            data = crop_yield)
  expect_s3_class(model_report(fit), "patchwork")
  expect_s3_class(model_report(fit, predictor = "rainfall"), "patchwork")

  gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
              family = binomial)
  expect_s3_class(model_report(gfit), "patchwork")
  expect_error(model_report("not a model"), "lm")
})
