# Tests for arguments added in the plot-quality pass --------------------------

test_that("explore_distribution(facet = TRUE) facets by group", {
  p <- explore_distribution(wellbeing_survey, life_satisfaction,
                            group = region, type = "both", facet = TRUE)
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$facet, "FacetWrap")
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("explore_distribution(facet) is a no-op without a group", {
  p <- explore_distribution(lexical_decision, RT, facet = TRUE)
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$facet, "FacetNull")
})

test_that("correlation_heatmap(reorder = TRUE) reorders by clustering", {
  num <- c("age", "income", "stress", "sleep_hours", "exercise_days",
           "life_satisfaction")
  cm <- stats::cor(wellbeing_survey[num], use = "pairwise.complete.obs")
  ord <- stats::hclust(stats::as.dist(1 - cm))$order

  p <- correlation_heatmap(wellbeing_survey, cols = num, reorder = TRUE)
  expect_equal(levels(p$data$var1), colnames(cm)[ord])

  p0 <- correlation_heatmap(wellbeing_survey, cols = num, reorder = FALSE)
  expect_equal(levels(p0$data$var1), num)
})
