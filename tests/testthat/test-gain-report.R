test_that("gain_plot() and lift_plot() work from glm and vectors", {
  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  expect_s3_class(gain_plot(gfit), "ggplot")
  expect_s3_class(lift_plot(gfit), "ggplot")
  expect_s3_class(gain_plot(c(0, 0, 1, 1), c(0.1, 0.2, 0.8, 0.9)), "ggplot")
  expect_error(gain_plot(c(1, 1, 1), c(0.1, 0.2, 0.3)),
               "both positive and negative")
})

test_that("gain_plot() drops the perfect-model line when models are overlaid", {
  # The envelope bends at the prevalence of the outcome, so it describes one
  # model's data. Overlaid models need not share a prevalence, so the reference
  # help page promises the line only for the single-model case.
  full <- glm(adverse_event ~ biomarker + age + arm,
              data = clinical_trial, family = binomial)
  reduced <- glm(adverse_event ~ biomarker, data = clinical_trial,
                 family = binomial)

  reference_layers <- function(p) {
    built <- ggplot2::ggplot_build(p)
    sum(vapply(built$data, function(d) {
      !is.null(d$colour) && all(d$colour == depictr_reference())
    }, logical(1)))
  }

  # One model: the no-model diagonal and the perfect-model envelope.
  expect_identical(reference_layers(gain_plot(full)), 2L)
  # Several: the diagonal alone.
  expect_identical(
    reference_layers(gain_plot(list(Full = full, Reduced = reduced))), 1L)
})

test_that("gain_table() captures all positives at full depth", {
  g <- depictr:::gain_table(c(0, 1, 0, 1), c(0.1, 0.9, 0.2, 0.8))
  expect_equal(g$population[1], 0)
  expect_equal(g$captured[1], 0)
  expect_equal(g$population[nrow(g)], 1)
  expect_equal(g$captured[nrow(g)], 1)   # all positives captured at 100%
})

test_that("model_report() returns a patchwork for lm and glm", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
            data = crop_yield)
  expect_s3_class(model_report(fit), "patchwork")
  expect_s3_class(model_report(fit, predictor = "rainfall"), "patchwork")

  gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
              family = binomial)
  expect_s3_class(model_report(gfit), "patchwork")
  expect_error(model_report("not a model"), "lm")
})
