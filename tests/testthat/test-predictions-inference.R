test_that("effects_plot() works for numeric and factor predictors and glm", {
  fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
  expect_s3_class(effects_plot(fit, "fertilizer"), "ggplot")
  expect_s3_class(effects_plot(fit, "treatment"), "ggplot")
  expect_error(effects_plot(fit, "not_a_var"), "predictor")

  gfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  p <- effects_plot(gfit, "word_frequency")
  expect_s3_class(p, "ggplot")
  # Predicted probabilities stay within [0, 1]
  yr <- p$data$fit
  expect_true(all(yr >= 0 & yr <= 1))
})

test_that("interaction_plot() handles factor and numeric moderators", {
  fit <- lm(yield ~ fertilizer * treatment + rainfall, data = crop_yield)
  expect_s3_class(interaction_plot(fit, "fertilizer", "treatment"), "ggplot")
  fit2 <- lm(yield ~ fertilizer * rainfall, data = crop_yield)
  expect_s3_class(interaction_plot(fit2, "fertilizer", "rainfall"), "ggplot")
  expect_error(interaction_plot(fit, "fertilizer", "nope"), "predictor")
})

test_that("random_effects_plot() works from a data frame", {
  re <- data.frame(level = paste0("G", 1:8), estimate = sort(rnorm(8)),
                   std.error = runif(8, 0.2, 0.5))
  p <- random_effects_plot(re)
  expect_s3_class(p, "ggplot")
  expect_error(random_effects_plot(data.frame(a = 1)), "estimate")
})

test_that("model_fit_table() summarises several models", {
  m1 <- lm(yield ~ rainfall, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
  tab <- model_fit_table(simple = m1, bigger = m2)
  expect_s3_class(tab, "data.frame")
  expect_equal(tab$model, c("simple", "bigger"))
  expect_true(all(c("AIC", "BIC", "R2", "RMSE") %in% names(tab)))
  # More predictors -> higher R2 here
  expect_gt(tab$R2[2], tab$R2[1])
})
