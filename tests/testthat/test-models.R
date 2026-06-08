test_that("power_curve_plot() accepts a data frame and reads the title", {
  pc <- data.frame(nlevels = c(10, 20, 30), mean = c(0.3, 0.6, 0.85),
                   lower = c(0.2, 0.5, 0.78), upper = c(0.4, 0.7, 0.92))
  p <- power_curve_plot(pc, title = "Power for cond")
  expect_s3_class(p, "ggplot")
  expect_error(power_curve_plot(data.frame(a = 1)), "sample-size")
})

test_that("optimizer_fixef_plot() works from a data frame", {
  df <- expand.grid(optimizer = c("bobyqa", "Nelder_Mead"),
                    term = c("(Intercept)", "x1"))
  df$value <- c(5, 5.1, 0.2, 0.19)
  p <- optimizer_fixef_plot(df)
  expect_s3_class(p, "ggplot")

  # Dropping the intercept leaves the slope panels
  p2 <- optimizer_fixef_plot(df, intercept = FALSE)
  expect_false(any(grepl("Intercept", as.character(p2$data$panel))))
  expect_error(optimizer_fixef_plot(data.frame(a = 1)), "optimiser")
})

test_that("residual_diagnostics_plot() returns a patchwork", {
  fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
  p <- residual_diagnostics_plot(fit)
  expect_s3_class(p, "patchwork")
  p2 <- residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
  expect_s3_class(p2, "patchwork")
  expect_error(residual_diagnostics_plot("not a model"), "lm")
})
