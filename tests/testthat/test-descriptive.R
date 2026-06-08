test_that("distribution_plot() handles strings, names and groups", {
  expect_s3_class(distribution_plot(lexical_decision, RT), "ggplot")
  expect_s3_class(distribution_plot(lexical_decision, "RT"), "ggplot")
  expect_s3_class(
    distribution_plot(lexical_decision, RT, group = condition, type = "both"),
    "ggplot"
  )
  expect_error(distribution_plot(lexical_decision, condition), "numeric")
  expect_error(distribution_plot(lexical_decision, nope), "not found")
})

test_that("scatter_trend_plot() works with and without a group", {
  expect_s3_class(scatter_trend_plot(crop_yield, fertilizer, yield), "ggplot")
  expect_s3_class(
    scatter_trend_plot(crop_yield, fertilizer, yield, group = treatment),
    "ggplot"
  )
  expect_s3_class(
    scatter_trend_plot(crop_yield, fertilizer, yield, method = NULL), "ggplot"
  )
})

test_that("correlation_matrix_plot() needs >= 2 numeric columns", {
  expect_s3_class(correlation_matrix_plot(crop_yield), "ggplot")
  expect_error(
    correlation_matrix_plot(data.frame(a = 1:3, b = letters[1:3])),
    "two numeric"
  )
})

test_that("missingness_plot() returns a ggplot", {
  p <- missingness_plot(wellbeing_survey)
  expect_s3_class(p, "ggplot")
  expect_error(missingness_plot(wellbeing_survey, colours = "red"), "two values")
})
