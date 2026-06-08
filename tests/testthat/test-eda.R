test_that("explore_distribution() handles strings, names and groups", {
  expect_s3_class(explore_distribution(lexical_decision, RT), "ggplot")
  expect_s3_class(explore_distribution(lexical_decision, "RT"), "ggplot")
  expect_s3_class(
    explore_distribution(lexical_decision, RT, group = condition, type = "both"),
    "ggplot"
  )
  expect_error(explore_distribution(lexical_decision, condition), "numeric")
  expect_error(explore_distribution(lexical_decision, nope), "not found")
})

test_that("scatter_trend() works with and without a group", {
  expect_s3_class(scatter_trend(crop_yield, fertilizer, yield), "ggplot")
  expect_s3_class(
    scatter_trend(crop_yield, fertilizer, yield, group = treatment),
    "ggplot"
  )
  expect_s3_class(
    scatter_trend(crop_yield, fertilizer, yield, method = NULL), "ggplot"
  )
})

test_that("correlation_heatmap() needs >= 2 numeric columns", {
  expect_s3_class(correlation_heatmap(crop_yield), "ggplot")
  expect_error(
    correlation_heatmap(data.frame(a = 1:3, b = letters[1:3])),
    "two numeric"
  )
})

test_that("missingness_map() returns a ggplot", {
  p <- missingness_map(wellbeing_survey)
  expect_s3_class(p, "ggplot")
  expect_error(missingness_map(wellbeing_survey, colours = "red"), "two values")
})
