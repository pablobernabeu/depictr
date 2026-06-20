test_that("explore_categorical() handles counts, proportions and groups", {
  expect_s3_class(explore_categorical(wellbeing_survey, region), "ggplot")
  expect_s3_class(
    explore_categorical(wellbeing_survey, education, group = region,
                        proportion = TRUE), "ggplot"
  )
  expect_s3_class(
    explore_categorical(wellbeing_survey, region, horizontal = TRUE), "ggplot"
  )
})

test_that("explore_bivariate() dispatches on variable types", {
  expect_s3_class(explore_bivariate(crop_yield, fertiliser, yield), "ggplot")
  expect_s3_class(explore_bivariate(lexical_decision, condition, RT), "ggplot")
  expect_s3_class(explore_bivariate(wellbeing_survey, region, education),
                  "ggplot")
})

test_that("explore_pairs() needs numeric columns and respects max_cols", {
  expect_s3_class(
    explore_pairs(crop_yield, cols = c("rainfall", "fertiliser", "yield")),
    "patchwork"
  )
  expect_error(explore_pairs(crop_yield, cols = c("yield", "treatment")),
               "numeric")
  expect_error(
    explore_pairs(crop_yield, cols = c("rainfall", "fertiliser", "yield"),
                  max_cols = 2),
    "Too many"
  )
})

test_that("outlier_plot() flags outliers and validates input", {
  expect_s3_class(outlier_plot(crop_yield, yield), "ggplot")
  expect_s3_class(outlier_plot(lexical_decision, RT, group = condition,
                               type = "both"), "ggplot")
  expect_error(outlier_plot(crop_yield, treatment), "numeric")
})

test_that("summary_table() returns a tidy descriptive table", {
  tab <- summary_table(crop_yield, vars = c("yield", "treatment"))
  expect_s3_class(tab, "data.frame")
  expect_true(all(c("variable", "statistic", "Overall") %in% names(tab)))
  # Numeric -> one Mean (SD) row; factor -> one row per level
  expect_true(any(tab$statistic == "Mean (SD)"))

  grouped <- summary_table(wellbeing_survey, vars = "education",
                           group = "region")
  expect_true(all(levels(wellbeing_survey$region) %in% names(grouped)))
})
