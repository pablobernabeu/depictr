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

test_that("multi-group MA overlay is dashed and adds no second legend", {
  dfg <- data.frame(
    t = rep(1:20, 2),
    v = rnorm(40),
    g = rep(c("a", "b"), each = 20)
  )
  p <- timeseries_plot(dfg, t, v, group = g, rolling = 4)
  built <- ggplot2::ggplot_build(p)
  # The moving average adds a second line layer (raw series + MA overlay)...
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_gte(sum(geoms == "GeomLine"), 2L)
  # ...drawn dashed somewhere in the built layers...
  linetypes <- unlist(lapply(built$data, function(d)
    if ("linetype" %in% names(d)) as.character(d$linetype) else NULL))
  expect_true(any(linetypes %in% c("2", "dashed")))
  # ...but it must NOT introduce a second (linetype) legend: one colour legend.
  has_linetype <- any(vapply(built$plot$scales$scales,
                             function(s) "linetype" %in% s$aesthetics,
                             logical(1)))
  expect_false(has_linetype)
})

test_that("an even window is the centred 2 x m moving average", {
  # filter(sides = 2) with an even number of equal weights put the mean of
  # observations 1 to 4 at observation 2, half a step before its centre. The
  # Python twin put it half a step after. A centred moving average of even
  # order averages two adjacent windows, which gives the observations at
  # either end half weight (Hyndman & Athanasopoulos, 2021, Section 3.3). The
  # Python twin's tests pin the same values.
  expect_equal(depictr:::moving_average(1:10, 4),
               c(NA, NA, 3, 4, 5, 6, 7, 8, NA, NA))
  roll <- timeseries_plot(1:10, rolling = 4)$layers[[2]]$data$roll
  expect_equal(roll, c(NA, NA, 3, 4, 5, 6, 7, 8, NA, NA))
  # The 2 x 12 average is the trend of R's classical decomposition.
  expect_equal(depictr:::moving_average(AirPassengers, 12),
               as.numeric(stats::decompose(AirPassengers)$trend))
  # An odd window was already centred on its observation and is unchanged.
  expect_equal(depictr:::moving_average(1:10, 3), c(NA, 2:9, NA))
})

test_that("an even window needs one observation more than its length", {
  # The 2 x 4 average spans five observations. Without a guard, filter() would
  # stop on four with "'filter' is longer than time series".
  df4 <- data.frame(t = 1:4, v = c(2, 4, 3, 5))
  expect_error(timeseries_plot(df4, t, v, rolling = 4), "needs 5 observations")
  df5 <- rbind(df4, data.frame(t = 5, v = 4))
  roll <- timeseries_plot(df5, t, v, rolling = 4)$layers[[2]]$data$roll
  expect_equal(roll, c(NA, NA, (2 / 2 + 4 + 3 + 5 + 4 / 2) / 4, NA, NA))
  # An odd window needs as many observations as its length.
  expect_s3_class(timeseries_plot(df4[1:3, ], t, v, rolling = 3), "ggplot")
})

test_that("the caption of a grouped overlay names a 2 x m average", {
  dfg <- data.frame(t = rep(1:30, 2), v = sin(1:60),
                    g = rep(c("a", "b"), each = 30))
  expect_identical(
    timeseries_plot(dfg, t, v, group = g, rolling = 12)$labels$caption,
    "Dashed line: 2×12 centred moving average"
  )
  expect_identical(
    timeseries_plot(dfg, t, v, group = g, rolling = 5)$labels$caption,
    "Dashed line: 5-point centred moving average"
  )
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

test_that("the PACF is R's pacf(), as the Python twin pins it", {
  # The Python twin's tests pin these values, which its
  # dev/goldens/timeseries.R prints from this function. Its default estimator
  # once differed from them by up to 0.18.
  pinned <- c(
    0.948047340752492, -0.229421874117177, 0.038147780503991,
    0.093785438151741, 0.073606697894160, 0.007727602590501,
    0.125597130176117, 0.089951343164267, 0.232488542208562,
    0.166051259804356, 0.171274419743056, -0.135431102278015,
    -0.539691241907120, -0.026610140069523, 0.090764981938823,
    0.024955559165498, 0.032515570006784, 0.073432640501125,
    0.048442114810552, -0.045541680123359, 0.045752935204032
  )
  p <- acf_plot(AirPassengers, type = "partial")
  expect_equal(p$data$lag, 1:21)
  expect_equal(p$data$acf, pinned, tolerance = 1e-10)
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

test_that("a factor group keeps its level order", {
  # The group was turned into character and reordered by first appearance, so
  # the legend and the colours ignored the order the factor declares.
  dfg <- data.frame(
    t = rep(1:5, 2),
    v = rnorm(10),
    g = factor(rep(c("b", "a"), each = 5), levels = c("a", "b"))
  )
  p <- timeseries_plot(dfg, t, v, group = g)
  expect_equal(levels(p$data$series), c("a", "b"))
  b <- ggplot2::ggplot_build(p)$data[[1]]
  expect_identical(unique(b$colour[b$group == 1]), depictr_palette(2)[1])

  # An unused level is dropped, so it takes no colour.
  dfg$g <- factor(as.character(dfg$g), levels = c("a", "b", "c"))
  expect_equal(levels(timeseries_plot(dfg, t, v, group = g)$data$series),
               c("a", "b"))

  # A character group still orders by first appearance.
  dfg$g <- rep(c("b", "a"), each = 5)
  expect_equal(levels(timeseries_plot(dfg, t, v, group = g)$data$series),
               c("b", "a"))
})
