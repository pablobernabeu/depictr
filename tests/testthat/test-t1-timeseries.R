# Regression tests for time-series bug fixes (T1 / timeseries) ---------------

test_that("moving average follows time order, not row order", {
  # A clean signal that is easy to reason about: roll = centred mean of window 3.
  ordered <- data.frame(t = 1:9, v = c(0, 3, 6, 9, 12, 15, 18, 21, 24))
  shuffled <- ordered[c(5, 1, 9, 3, 7, 2, 8, 4, 6), ]

  expected <- depictr:::moving_average(ordered$v, 3)

  build_roll <- function(df) {
    p <- timeseries_plot(df, t, v, rolling = 3)
    d <- p$layers[[2]]$data        # the moving-average layer
    d <- d[order(d$time), ]
    d$roll
  }

  roll_ordered <- build_roll(ordered)
  roll_shuffled <- build_roll(shuffled)

  # The roll computed from shuffled input, once re-ordered by time, must match
  # the roll from already-sorted input (and the true centred MA).
  expect_equal(roll_ordered, expected)
  expect_equal(roll_shuffled, expected)
  # Centre points are the local mean: (0 + 3 + 6)/3 = 3, etc.
  expect_equal(roll_ordered[2:8], c(3, 6, 9, 12, 15, 18, 21))
})

test_that("non-integer rolling window is rejected (would bias the MA)", {
  v <- as.numeric(1:20)
  expect_error(depictr:::moving_average(v, 2.5), "whole number")
  expect_error(depictr:::validate_window(2.5), "whole number")
  df <- data.frame(t = 1:20, v = v)
  expect_error(timeseries_plot(df, t, v, rolling = 3.5), "whole number")

  # Integer-valued doubles are accepted and coerced.
  expect_identical(depictr:::validate_window(4), 4L)
  expect_identical(depictr:::validate_window(4.0), 4L)

  # A non-integer window summing to < 1 would shrink the MA toward zero; the
  # validated path returns an unbiased centred mean instead.
  ma <- depictr:::moving_average(rep(10, 10), 3)
  expect_equal(ma[5], 10)
})

test_that("non-positive / malformed windows are rejected", {
  expect_error(depictr:::validate_window(0), "positive integer")
  expect_error(depictr:::validate_window(-3), "positive integer")
  expect_error(depictr:::validate_window(c(2, 3)), "single positive integer")
  expect_error(depictr:::validate_window(NA_real_), "single positive integer")
})

test_that("oversized rolling window gives a friendly error, not a cryptic one", {
  df <- data.frame(t = 1:5, v = rnorm(5))
  expect_error(timeseries_plot(df, t, v, rolling = 10),
               "larger than the shortest series")

  # Per-group: window must be <= the SHORTEST group.
  dfg <- data.frame(
    t = c(1:8, 1:3),
    v = rnorm(11),
    g = c(rep("a", 8), rep("b", 3))
  )
  expect_error(timeseries_plot(dfg, t, v, group = g, rolling = 5),
               "shortest series")
  # A window that fits both groups works.
  expect_s3_class(timeseries_plot(dfg, t, v, group = g, rolling = 3), "ggplot")
})

test_that("multi-group MA overlay uses a distinct (dashed) linetype", {
  dfg <- data.frame(
    t = rep(1:20, 2),
    v = rnorm(40),
    g = rep(c("a", "b"), each = 20)
  )
  p <- timeseries_plot(dfg, t, v, group = g, rolling = 4)
  built <- ggplot2::ggplot_build(p)
  # A linetype scale must be present for the MA legend.
  has_linetype <- any(vapply(built$plot$scales$scales,
                             function(s) "linetype" %in% s$aesthetics,
                             logical(1)))
  expect_true(has_linetype)
})

test_that("acf_plot keeps interior NAs (na.pass) and warns", {
  set.seed(1)
  x <- as.numeric(arima.sim(list(ar = 0.6), 200))
  x_gap <- x
  x_gap[c(50, 90, 130)] <- NA  # interior gaps

  # Should warn about interior missing values rather than silently dropping.
  expect_warning(acf_plot(x_gap), "interior missing")
  p <- suppressWarnings(acf_plot(x_gap))
  expect_s3_class(p, "ggplot")

  # The buggy behaviour concatenated across gaps (dropping interior NAs, which
  # changes n.used and the lag-1 estimate). Compare against the na.pass acf.
  ref <- stats::acf(x_gap, plot = FALSE, na.action = stats::na.pass)
  got_lag1 <- p$data$acf[p$data$lag == 1]
  expect_equal(got_lag1, as.numeric(ref$acf)[2])

  # Dropping interior NAs (the old behaviour) gives a different lag-1 value,
  # confirming the fix is observable.
  dropped <- stats::acf(x_gap[is.finite(x_gap)], plot = FALSE)
  expect_false(isTRUE(all.equal(as.numeric(ref$acf)[2],
                                as.numeric(dropped$acf)[2])))
})

test_that("acf_plot does not warn for a clean series", {
  x <- as.numeric(AirPassengers)
  expect_silent(acf_plot(x))
})

test_that("conf_level is validated to (0, 1)", {
  x <- as.numeric(AirPassengers)
  expect_error(acf_plot(x, conf_level = 0), "between 0 and 1")
  expect_error(acf_plot(x, conf_level = 1), "between 0 and 1")
  expect_error(acf_plot(x, conf_level = 1.5), "between 0 and 1")
  expect_error(acf_plot(x, conf_level = -0.2), "between 0 and 1")
  expect_error(acf_plot(x, conf_level = c(0.9, 0.95)), "single number")
  expect_s3_class(acf_plot(x, conf_level = 0.99), "ggplot")
})
