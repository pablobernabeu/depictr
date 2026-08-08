test_that("coefficient_plot() returns a ggplot and drops the intercept by default", {
  fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
  p <- coefficient_plot(fit)
  expect_s3_class(p, "ggplot")
  expect_false(any(grepl("Intercept", as.character(p$data$label))))

  p2 <- coefficient_plot(fit, intercept = TRUE)
  expect_true(any(grepl("Intercept", as.character(p2$data$label))))
})

test_that("coefficient_plot() orders terms by estimate", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- coefficient_plot(fit, order = "ascending")
  est <- p$data$estimate
  expect_equal(est, sort(est))
})

test_that("coefficient_plot() accepts custom and named labels", {
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  p <- coefficient_plot(fit, labels = c(rainfall = "Rainfall", fertiliser = "Fert."))
  expect_true(all(c("Rainfall", "Fert.") %in% as.character(p$data$label)))
  expect_error(coefficient_plot(fit, labels = "only-one"), "length")
})

test_that("a `labels` key that matches no term warns", {
  # Regression: a mistyped key was dropped in silence, so the figure came back
  # looking exactly like the unlabelled one.
  est <- data.frame(term = c("stress", "sleep_hours"),
                    estimate = c(-0.4, 0.3),
                    conf.low = c(-0.6, 0.1),
                    conf.high = c(-0.2, 0.5))
  expect_warning(
    coefficient_plot(est, labels = c(strss = "Stress")),
    paste0("^`labels` keys not found among the parameters: strss\\. ",
           "The parameters are stress, sleep_hours\\.$")
  )
  # A key that does match must stay quiet, and must still relabel.
  expect_no_warning(p <- coefficient_plot(est, labels = c(stress = "Stress")))
  expect_true("Stress" %in% as.character(p$data$label))
})

test_that("compare_models() reports an unused `labels` key once", {
  m1 <- lm(yield ~ rainfall + soil_ph, data = crop_yield)
  m2 <- lm(yield ~ rainfall + soil_ph,
           data = crop_yield[crop_yield$treatment == "standard", ])
  # The same terms arrive once per source, so the message must list them once.
  expect_warning(
    compare_models(A = m1, B = m2, labels = c(rainfal = "Rainfall")),
    paste0("^`labels` keys not found among the parameters: rainfal\\. ",
           "The parameters are \\(Intercept\\), rainfall, soil_ph\\.$")
  )
  expect_no_warning(compare_models(A = m1, B = m2,
                                   labels = c(rainfall = "Rainfall")))
})

test_that("the pretty-label merge does not trip the unused-key warning", {
  # merge_pretty_labels() adds b_-prefixed keys that no frequentist fit carries,
  # so the check must see the user's `labels` before that merge.
  fit <- lm(yield ~ rainfall + treatment, data = crop_yield)
  expect_no_warning(coefficient_plot(fit))
  expect_no_warning(coefficient_plot(fit, labels = c(rainfall = "Rainfall")))
})

test_that("compare_models() needs at least two sources", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  expect_error(compare_models(fit), "at least two")
})

test_that("compare_models() combines sources", {
  m1 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertiliser,
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

test_that("the standardise label names the x-only convention", {
  # standardise_estimates() rescales the predictors but not the outcome, so the
  # figure must not say "standardised estimate", which conventionally means a
  # fully standardised beta. The figure travels without its help page.
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  expect_equal(coefficient_plot(fit, standardise = TRUE)$labels$x,
               "Estimate per SD of predictor")
  expect_equal(coefficient_plot(fit)$labels$x, "Estimate")
  # An explicit x_lab still wins.
  expect_equal(coefficient_plot(fit, standardise = TRUE, x_lab = "beta")$labels$x,
               "beta")
})
