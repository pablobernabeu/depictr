test_that("coefficient_plot() returns a ggplot and drops the intercept by default", {
  fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
  p <- coefficient_plot(fit)
  expect_s3_class(p, "ggplot")
  expect_false(any(grepl("Intercept", as.character(p$data$label))))

  p2 <- coefficient_plot(fit, intercept = TRUE)
  expect_true(any(grepl("Intercept", as.character(p2$data$label))))
})

test_that("coefficient_plot() orders terms by estimate", {
  fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
  p <- coefficient_plot(fit, order = "ascending")
  est <- p$data$estimate
  expect_equal(est, sort(est))
})

test_that("coefficient_plot() accepts custom and named labels", {
  fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
  p <- coefficient_plot(fit, labels = c(rainfall = "Rainfall", fertilizer = "Fert."))
  expect_true(all(c("Rainfall", "Fert.") %in% as.character(p$data$label)))
  expect_error(coefficient_plot(fit, labels = "only-one"), "length")
})

test_that("compare_models() needs at least two sources", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  expect_error(compare_models(fit), "at least two")
})

test_that("compare_models() combines sources", {
  m1 <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertilizer,
           data = crop_yield[crop_yield$treatment == "standard", ])
  p <- compare_models(A = m1, B = m2)
  expect_s3_class(p, "ggplot")
  expect_setequal(levels(p$data$source), c("A", "B"))
})

test_that("frequentist_bayesian_plot() labels the two sources", {
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  bayes <- tidy_estimates(freq)
  p <- frequentist_bayesian_plot(freq, bayes)
  expect_s3_class(p, "ggplot")
  expect_true(any(grepl("Frequentist", levels(p$data$source))))
  expect_true(any(grepl("Bayesian", levels(p$data$source))))
})
