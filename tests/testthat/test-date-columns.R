# Dates, date-times, durations and other columns that are not plain numbers.
#
# summary_table() gives a date one row, its range, and a duration its mean (SD)
# in a stated unit; explore_bivariate() draws dates and durations on a
# continuous axis; correlation_heatmap() refuses a column it cannot correlate.
# The Python twin's tests/test_date_columns.py builds the same frame and pins
# the same cells.

# Forty visits three days apart, two arms of twenty, a time stamp every 90
# minutes and a duration that cycles through one to eight days.
date_frame <- function() {
  i <- 0:39
  data.frame(
    id = sprintf("p%02d", i),
    arm = rep(c("a", "b"), each = 20),
    visit = as.Date("2024-01-01") + 3 * i,
    stamp = as.POSIXct("2024-03-01 08:30", tz = "UTC") + 90 * 60 * i,
    dur = as.difftime(i %% 8 + 1, units = "days"),
    score = i / 10,
    stringsAsFactors = FALSE
  )
}

geom_classes <- function(p) {
  unname(vapply(p$layers, function(l) class(l$geom)[1], character(1)))
}

# --- summary_table() ---------------------------------------------------------

test_that("summary_table() gives a date column one row, its range", {
  d <- date_frame()
  tab <- summary_table(d, vars = "visit")
  # One row for N and one for the dates, where there was one per day.
  expect_equal(nrow(tab), 2L)
  expect_identical(tab$statistic, c("", "Range"))
  expect_identical(tab$Overall[2], "2024-01-01 to 2024-04-27")

  grouped <- summary_table(d, vars = "visit", group = "arm")
  expect_identical(unname(unlist(grouped[2, c("Overall", "a", "b")])),
                   c("2024-01-01 to 2024-04-27", "2024-01-01 to 2024-02-27",
                     "2024-03-01 to 2024-04-27"))
})

test_that("summary_table() writes a date-time range to the precision it needs", {
  d <- date_frame()
  grouped <- summary_table(d, vars = "stamp", group = "arm")
  expect_identical(grouped$statistic[2], "Range")
  # No time has seconds, so the cells stop at minutes.
  expect_identical(unname(unlist(grouped[2, c("Overall", "a", "b")])),
                   c("2024-03-01 08:30 to 2024-03-03 19:00",
                     "2024-03-01 08:30 to 2024-03-02 13:00",
                     "2024-03-02 14:30 to 2024-03-03 19:00"))

  # Times that all fall at midnight are written as dates.
  midnight <- data.frame(t = as.POSIXct(c("2024-05-01", "2024-05-09"),
                                        tz = "UTC"))
  expect_identical(summary_table(midnight, vars = "t")$Overall[2],
                   "2024-05-01 to 2024-05-09")
  # A time with seconds keeps them.
  seconds <- data.frame(t = as.POSIXct(c("2024-05-01 10:00:05",
                                         "2024-05-01 10:30:00"), tz = "UTC"))
  expect_identical(summary_table(seconds, vars = "t")$Overall[2],
                   "2024-05-01 10:00:05 to 2024-05-01 10:30:00")
})

test_that("summary_table() summarises a duration as mean (SD) in its unit", {
  d <- date_frame()
  grouped <- summary_table(d, vars = "dur", group = "arm")
  expect_identical(grouped$statistic[2], "Mean (SD), days")
  expect_identical(unname(unlist(grouped[2, c("Overall", "a", "b")])),
                   c("4.5 (2.3)", "4.1 (2.3)", "4.9 (2.3)"))

  hours <- data.frame(h = as.difftime(c(1.5, 2.5, 4), units = "hours"))
  tab <- summary_table(hours, vars = "h")
  expect_identical(tab$statistic[2], "Mean (SD), hours")
  expect_identical(tab$Overall[2], "2.7 (1.3)")
})

test_that("summary_table() keeps dates in one row each when vars is NULL", {
  d <- date_frame()
  expect_message(tab <- summary_table(d, group = "arm"),
                 "skipping high-cardinality column\\(s\\): id\\.")
  # N, then one row each for visit, stamp, dur and score.
  expect_identical(tab$variable, c("N", "visit", "stamp", "dur", "score"))
  expect_identical(tab$statistic,
                   c("", "Range", "Range", "Mean (SD), days", "Mean (SD)"))
})

test_that("summary_table() reports missing dates and an empty group", {
  d <- date_frame()
  d$visit[21:40] <- NA
  tab <- summary_table(d, vars = "visit", group = "arm")
  expect_identical(tab$statistic, c("", "Range", "Missing, n (%)"))
  expect_identical(unname(unlist(tab[2, c("Overall", "a", "b")])),
                   c("2024-01-01 to 2024-02-27", "2024-01-01 to 2024-02-27",
                     "--"))
  expect_identical(tab$b[3], "20 (100%)")
})

# --- explore_bivariate() -----------------------------------------------------

test_that("explore_bivariate() draws a date against a number as a scatter", {
  d <- date_frame()
  p <- explore_bivariate(d, visit, score)
  expect_identical(geom_classes(p), c("GeomPoint", "GeomSmooth"))
  built <- ggplot2::ggplot_build(p)
  expect_s3_class(built$layout$panel_scales_x[[1]], "ScaleContinuousDate")

  p <- explore_bivariate(d, score, stamp)
  expect_identical(geom_classes(p), c("GeomPoint", "GeomSmooth"))
  built <- ggplot2::ggplot_build(p)
  expect_s3_class(built$layout$panel_scales_y[[1]], "ScaleContinuousDatetime")
})

test_that("explore_bivariate() draws a duration in its unit", {
  d <- date_frame()
  p <- explore_bivariate(d, dur, score)
  expect_identical(geom_classes(p), c("GeomPoint", "GeomSmooth"))
  expect_identical(p$labels$x, "dur (days)")
  # Read as a plain number, the duration needs no scale ggplot2 cannot pick.
  expect_no_message(ggplot2::ggplot_build(p))
  expect_identical(explore_bivariate(d, dur, score, x_lab = "Stay")$labels$x,
                   "Stay")
})

test_that("explore_bivariate() draws dates by category as box plots", {
  d <- date_frame()
  expect_no_warning(p <- explore_bivariate(d, arm, visit))
  expect_identical(geom_classes(p), "GeomBoxplot")
  built <- ggplot2::ggplot_build(p)
  # One box per arm, where there was one per day.
  expect_equal(nrow(built$data[[1]]), 2L)
  expect_s3_class(built$layout$panel_scales_y[[1]], "ScaleContinuousDate")
})

# --- correlation_heatmap() ---------------------------------------------------

test_that("correlation_heatmap() refuses columns it cannot correlate", {
  expect_error(
    correlation_heatmap(crop_yield, cols = c("yield", "treatment", "rainfall")),
    "correlation_heatmap() needs numeric columns; these are not: treatment.",
    fixed = TRUE
  )
  d <- date_frame()
  expect_error(
    correlation_heatmap(d, cols = c("score", "visit", "arm")),
    "correlation_heatmap() needs numeric columns; these are not: visit, arm.",
    fixed = TRUE
  )
  # A logical column correlates as 0 and 1, as it did before.
  d$late <- d$score > 2
  expect_s3_class(correlation_heatmap(d, cols = c("score", "late")), "ggplot")
})
