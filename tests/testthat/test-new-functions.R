# Tests for the new plotting functions ---------------------------------------

test_that("dumbbell_plot connects two groups per category", {
  wb <- wellbeing_survey
  wb$age_group <- ifelse(wb$age < median(wb$age), "younger", "older")
  p <- dumbbell_plot(wb, region, life_satisfaction, age_group)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
  # One segment per region (4) and two points per region (8 points).
  expect_equal(nlevels(p$data$category), 4L)
})

test_that("dumbbell_plot(sort = 'none') keeps level order, else first appearance", {
  # aggregate() sorted the categories, so "the data's own order" came out
  # alphabetical: levels West, South, North, East gave East, North, South,
  # West.
  d <- data.frame(
    region = rep(c("South", "West", "North", "East"), each = 2),
    value = c(1, 2, 3, 5, 2, 2.5, 4, 4.5),
    period = rep(c("before", "after"), 4)
  )
  d$region_f <- factor(d$region,
                       levels = c("West", "Central", "South", "North", "East"))
  p <- dumbbell_plot(d, region_f, value, period, sort = "none")
  # A level no row uses has no dumbbell to draw.
  expect_identical(levels(p$data$category), c("West", "South", "North", "East"))
  p <- dumbbell_plot(d, region, value, period, sort = "none")
  expect_identical(levels(p$data$category), c("South", "West", "North", "East"))
  # Each category keeps its own two values.
  seg <- p$data[match(c("South", "West", "North", "East"), p$data$category), ]
  expect_identical(seg$x1, c(2, 5, 2.5, 4.5))
  expect_identical(seg$x2, c(1, 3, 2, 4))
})

test_that("dumbbell_plot requires exactly two groups", {
  expect_error(
    dumbbell_plot(wellbeing_survey, region, life_satisfaction, education),
    "exactly two"
  )
})

test_that("ecdf_plot builds, grouped and ungrouped", {
  expect_s3_class(ecdf_plot(lexical_decision, RT), "ggplot")
  p <- ecdf_plot(lexical_decision, RT, group = condition)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("ecdf_plot validates reference_quantiles", {
  expect_error(
    ecdf_plot(lexical_decision, RT, reference_quantiles = c(0.5, 2)),
    "probabilities"
  )
})

test_that("ridgeline_plot builds one ridge per group", {
  p <- ridgeline_plot(wellbeing_survey, life_satisfaction, region)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
  expect_equal(nlevels(p$data$group), 4L)
})

test_that("ridgeline_plot rejects non-positive overlap", {
  expect_error(
    ridgeline_plot(wellbeing_survey, life_satisfaction, region, overlap = 0),
    "positive"
  )
})

test_that("ridgeline_plot draws the top ridge first, colours unchanged", {
  # Regression: the data-row sort meant to draw from the top down was a no-op,
  # because ggplot2 draws ribbon groups in factor-level order; upper ridges
  # overpainted the lower ones, the opposite of the conventional overlap.
  p <- ridgeline_plot(wellbeing_survey, life_satisfaction, region)
  d <- ggplot2::ggplot_build(p)$data[[1]]

  # Group ids are the draw order; the baseline (ymin) must descend with them,
  # so the top ridge is painted first and each lower ridge lands in front.
  base_by_group <- tapply(d$ymin, d$group, unique)
  bases <- as.numeric(base_by_group[order(as.integer(names(base_by_group)))])
  expect_true(all(diff(bases) < 0))

  # The fill still follows the original level order: bottom ridge (base 1)
  # takes the first palette colour, and so on up.
  pal <- depictr_palette(length(bases))
  fill_by_base <- vapply(seq_along(pal), function(b) {
    unique(d$fill[d$ymin == b])
  }, character(1))
  expect_identical(fill_by_base, pal)
})
