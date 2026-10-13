# Tests for the expanded time-series suite: seasonal_plot(), forecast overlay
# on timeseries_plot(), ts_forecast(), and decompose_plot() ribbons / robust STL.

# Helper: a single monthly_sales series as a ts (trend + 12-month seasonality)
ms_ts <- function(which = "indoor") {
  data(monthly_sales, package = "depictr", envir = environment())
  d <- monthly_sales[monthly_sales$series == which, ]
  d <- d[order(d$date), ]
  stats::ts(d$sales, start = c(2018, 1), frequency = 12)
}

test_that("seasonal_plot() builds both styles without warnings", {
  y <- ms_ts()
  p1 <- seasonal_plot(y)
  p2 <- seasonal_plot(y, style = "season")
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
  expect_silent(ggplot2::ggplot_build(p1))
  expect_silent(ggplot2::ggplot_build(p2))
  # also from a numeric vector with frequency
  expect_s3_class(seasonal_plot(as.numeric(y), frequency = 12), "ggplot")
})

test_that("seasonal subseries grouping is exactly per-season, in cycle order", {
  y <- ms_ts()
  df <- depictr:::ts_seasonal_frame(y)

  # 12 seasons, 6 cycles, 12 obs per cycle
  expect_identical(levels(df$season), month.abb)
  expect_equal(max(df$cycle), 6)
  expect_true(all(table(df$cycle) == 12))

  # each subseries panel holds exactly that season's obs, in cycle order
  for (k in 1:12) {
    raw_k <- as.numeric(y)[stats::cycle(y) == k]
    sub_k <- df$value[df$season_idx == k]
    expect_identical(sub_k, raw_k)
    expect_identical(df$cycle[df$season_idx == k], seq_along(raw_k))
  }
})

test_that("per-season mean lines match an independent computation", {
  y <- ms_ts()
  # independent per-month means
  expected <- as.numeric(tapply(as.numeric(y), stats::cycle(y), mean))

  p <- seasonal_plot(y)
  b <- ggplot2::ggplot_build(p)
  hl <- NULL
  for (layer in b$data) if ("yintercept" %in% names(layer)) hl <- layer
  expect_false(is.null(hl))
  expect_equal(sort(unique(hl$yintercept)), sort(expected))
})

test_that("seasonal_plot() validates its inputs", {
  expect_error(seasonal_plot(rnorm(50)), "frequency")
  expect_error(seasonal_plot(stats::ts(rnorm(50), frequency = 1)), "seasonal")
  expect_error(seasonal_plot(AirPassengers, season_labels = c("a", "b")),
               "length")
})

# AirPassengers cut to its first `k` years, one cycle per year.
air_cycles <- function(k) stats::window(AirPassengers, end = c(1948 + k, 12))

test_that("the cycle lines of style = \"season\" clear 3:1 against white", {
  # The lines took depictr_palette(type = "sequential"), which starts at
  # #e6eff5, 1.16:1 against white, so with twelve cycles four of the lines fell
  # below the 3:1 that WCAG 2.2 asks of a graphical object. The ramp now runs
  # from #4a8fc0, at 3.51:1, through the brand blue to #08315a, as in the
  # Python twin.
  b <- ggplot2::ggplot_build(seasonal_plot(AirPassengers, style = "season"))
  lines <- b$data[[1]]
  ramp <- unique(lines$colour[order(lines$group)])
  expect_length(ramp, 12)
  expect_identical(ramp[c(1, 12)], c("#4A8FC0", "#08315A"))
  # Fills keep the sequential palette, pale end and all.
  expect_identical(depictr_palette(3, type = "sequential")[1], "#E6EFF5")
  for (k in c(3, 12)) {
    cf <- check_figure(seasonal_plot(air_cycles(k), style = "season"))
    row <- cf[cf$check == "geometry_contrast", ]
    expect_identical(row$verdict, "pass")
    expect_equal(row$measured, 3.51)
  }
})

test_that("the cycle colours pass every colour check up to five cycles", {
  # Past about six cycles, a single-hue ramp shows the order of the cycles
  # more than which is which. Measured with CIEDE2000, six cycles pass every
  # row but deuteranopia, whose closest pair is 4.93 apart. The Python twin
  # rounds its interpolated ramp one hex unit away and measures 5.24 there.
  # Every colour row fails from seven cycles and greyscale separability from
  # eight, so none is asserted there. redundant_encoding stays at zero, since
  # colour alone tells the cycles apart.
  rows <- c("colour_separability", "colour_separability_protan",
            "colour_separability_deutan", "colour_separability_tritan",
            "greyscale_separability", "geometry_contrast")
  for (k in 2:5) {
    cf <- check_figure(seasonal_plot(air_cycles(k), style = "season"))
    expect_identical(cf$verdict[match(rows, cf$check)], rep("pass", 6),
                     label = paste(k, "cycles"))
  }
  cf <- check_figure(seasonal_plot(air_cycles(6), style = "season"))
  expect_identical(cf$verdict[match(rows, cf$check)],
                   c("pass", "pass", "fail", "pass", "pass", "pass"))
  expect_equal(cf$measured[cf$check == "colour_separability_deutan"], 4.93)
})

test_that("a non-integer frequency is rounded down to whole seasons", {
  # Such a series was refused with "`season_labels` must have length equal to
  # the frequency (52.1785714285714)", which no labels could satisfy.
  # decompose_plot() accepted it, since stl() uses the whole part of the
  # frequency. The Python twin truncated such a period without a word.
  set.seed(1)
  y <- stats::ts(stats::rnorm(130), frequency = 365.25 / 7)
  msg <- paste("Frequency 52.17857 is not a whole number; using 52 seasons",
               "per cycle, as stl() does.")
  expect_message(p <- seasonal_plot(y, style = "season"), msg, fixed = TRUE)
  expect_identical(p$data$season_idx, c(rep(1:52, 2), 1:26))
  expect_identical(p$data$cycle, rep(1:3, c(52, 52, 26)))
  expect_silent(ggplot2::ggplot_build(p))
  # The default style and a numeric `x` take the same route, and labels are
  # given for the whole seasons.
  expect_message(seasonal_plot(as.numeric(y), frequency = 365.25 / 7), msg,
                 fixed = TRUE)
  weeks <- sprintf("W%02d", 1:52)
  expect_message(p <- seasonal_plot(y, season_labels = weeks), msg,
                 fixed = TRUE)
  expect_identical(levels(p$data$season), weeks)
})

test_that("a frequency a rounding error from a whole number is that number", {
  # ts() takes a frequency within ts.eps of a whole number for that number,
  # but a ts whose tsp is set directly keeps 12.0000001. Such a series was
  # rounded down with a message calling 12 not a whole number, and its seasons
  # were counted from the first observation, so April became season 1. The
  # Python twin reads a period the same way.
  y <- stats::ts(1:24, start = c(2016, 4), frequency = 12)
  tsp(y) <- c(tsp(y)[1:2], 12 + 1e-7)
  expect_silent(df <- depictr:::ts_seasonal_frame(y))
  expect_identical(attr(df, "frequency"), 12)
  expect_identical(df$season_idx, c(4:12, 1:12, 1:3))
  expect_identical(df$cycle, rep(1:3, c(9L, 12L, 3L)))
})

test_that("the seasons follow the calendar the ts carries", {
  # The Python twin counted its seasons from the first observation, so a
  # series from April drew April as season 1. It now reads the calendar from
  # the index, as stats::cycle() reads it here, and both suites pin the same
  # series: one from March 2016 that peaks every July.
  months <- as.numeric(stats::cycle(
    stats::ts(numeric(36), start = c(2016, 3), frequency = 12)
  ))
  y <- stats::ts(ifelse(months == 7, 10, 1), start = c(2016, 3),
                 frequency = 12)
  df <- depictr:::ts_seasonal_frame(y)
  expect_identical(as.character(unique(df$season[df$value == 10])), "Jul")
  expect_identical(df$cycle, rep(1:4, c(10L, 12L, 12L, 2L)))
  april <- stats::ts(1:24, start = c(2016, 4), frequency = 12)
  expect_identical(depictr:::ts_seasonal_frame(april)$season_idx,
                   c(4:12, 1:12, 1:3))
})

test_that("ts_forecast() reproduces STL plus a random walk with drift", {
  # Values from forecast 9.0.2 under R 4.6.1, the $mean, $lower and $upper of
  #   forecast::stlf(AirPassengers, h = 12, method = "rwdrift",
  #                  s.window = "periodic", level = 95)
  # pinned here because forecast is not a dependency of depictr.
  fc <- ts_forecast(AirPassengers, h = 12, level = 0.95)
  expect_equal(fc$fit, c(
    440.5242153238, 433.0824170240, 467.5572919758, 464.5671339643,
    469.4103174983, 509.7656586032, 549.9543241725, 550.0412935250,
    501.7116049968, 465.4912655880, 431.3542647697, 459.3770179437
  ), tolerance = 1e-8)
  expect_equal(fc$lwr, c(
    407.2233476641, 385.8246385491, 409.4793312810, 397.2752067877,
    393.9201892667, 426.7914607445, 460.0317040329, 453.5900635286,
    399.0714375404, 356.9437173166, 317.1371970933, 339.6944840716
  ), tolerance = 1e-8)
  expect_equal(fc$upr, c(
    473.8250829836, 480.3401954989, 525.6352526706, 531.8590611409,
    544.9004457299, 592.7398564618, 639.8769443120, 646.4925235214,
    604.3517724532, 574.0388138594, 545.5713324460, 579.0595518157
  ), tolerance = 1e-8)
  expect_equal(fc$time, 1961 + (0:11) / 12, tolerance = 1e-12)

  # The half-width is z * sd(diff(sa)) * sqrt(h * (1 + h / (T - 1))), where sa
  # is the seasonally adjusted series and T its length. That is the drift
  # method's standard deviation in Hyndman and Athanasopoulos (2021, Table
  # 5.2). Version 0.3.0 used z * sd(STL remainder) * sqrt(h).
  seas <- stats::stl(AirPassengers, s.window = "periodic")$time.series
  sigma <- stats::sd(diff(as.numeric(AirPassengers) -
                            as.numeric(seas[, "seasonal"])))
  h <- 1:12
  expect_equal(fc$upr - fc$fit,
               stats::qnorm(0.975) * sigma * sqrt(h * (1 + h / 143)),
               tolerance = 1e-10)
})

test_that("ts_forecast(lambda = 0) forecasts on the log scale", {
  # Values from forecast 9.0.2 under R 4.6.1, the $mean, $lower and $upper of
  #   forecast::stlf(AirPassengers, h = 12, method = "rwdrift",
  #                  s.window = "periodic", level = 95, lambda = 0,
  #                  biasadj = FALSE)
  fc <- ts_forecast(AirPassengers, h = 12, level = 0.95, lambda = 0)
  expect_equal(fc$fit, c(
    440.0658477097, 434.4320147467, 499.4145710292, 489.3343843321,
    493.5142965444, 564.4598891513, 633.9581438069, 635.6774900183,
    556.7186494482, 489.7245198438, 428.4039687478, 484.1820858670
  ), tolerance = 1e-8)
  expect_equal(fc$lwr, c(
    409.0406619907, 391.6185234311, 439.6286194274, 422.1291027632,
    418.1408604200, 470.4572488222, 520.3823908799, 514.3681210831,
    444.3979549196, 385.8830079091, 333.3892623292, 372.3022952827
  ), tolerance = 1e-8)
  expect_equal(fc$upr, c(
    473.4442521630, 481.9260687247, 567.3309305503, 567.2391174223,
    582.4744337328, 677.2453124240, 772.3223059480, 785.5966471350,
    697.4281749326, 621.5098888022, 550.4975149970, 629.6826402762
  ), tolerance = 1e-8)
  # The back-transformed point forecast is the median, so on the log scale it
  # sits midway between the limits.
  expect_equal(log(fc$fit), (log(fc$lwr) + log(fc$upr)) / 2,
               tolerance = 1e-12)
})

test_that("ts_forecast() validates lambda, which needs positive data", {
  expect_error(ts_forecast(AirPassengers, lambda = "log"),
               "single finite number")
  expect_error(ts_forecast(AirPassengers, lambda = c(0, 1)),
               "single finite number")
  expect_error(ts_forecast(AirPassengers, lambda = NA_real_),
               "single finite number")
  y <- AirPassengers
  y[5] <- 0
  expect_error(ts_forecast(y, lambda = 0), "positive")
  expect_error(ts_forecast(y, lambda = 0.5), "positive")
  # Without lambda, a zero is just a value.
  expect_s3_class(ts_forecast(y, h = 3), "data.frame")
  # lambda = 1 shifts the series down by one, and the back-transformation
  # shifts the forecast up again.
  expect_equal(ts_forecast(AirPassengers, lambda = 1),
               ts_forecast(AirPassengers), tolerance = 1e-10)
})

test_that("forecasting and STL decomposition need more than two cycles", {
  set.seed(12)
  y24 <- stats::ts(100 + stats::rnorm(24), frequency = 12)
  y25 <- stats::ts(100 + stats::rnorm(25), frequency = 12)
  msg <- "more than two full cycles \\(at least 25 observations\\)"
  # Exactly two cycles used to reach stats::stl() and its raw error, "series is
  # not periodic or has less than two periods".
  expect_error(ts_forecast(y24), msg)
  expect_error(decompose_plot(y24), msg)
  expect_s3_class(ts_forecast(y25, h = 3), "data.frame")
  expect_s3_class(decompose_plot(y25), "patchwork")
  # Classical decomposition works with exactly two cycles and is not refused.
  expect_s3_class(decompose_plot(y24, method = "classical"), "patchwork")
  # The count follows the frequency.
  expect_error(ts_forecast(stats::ts(1:8 + stats::rnorm(8), frequency = 4)),
               "at least 9 observations")
})

test_that("ts_forecast() intervals widen monotonically with the horizon", {
  y <- ms_ts("outdoor")
  fc <- ts_forecast(y, h = 24)
  w <- fc$upr - fc$lwr
  expect_true(all(w > 0))
  expect_true(all(diff(w) > 0))
  # higher coverage gives wider intervals at every horizon
  f80 <- ts_forecast(y, h = 24, level = 0.80)
  expect_true(all((fc$upr - fc$lwr) > (f80$upr - f80$lwr)))
  # forecast times advance by one period
  expect_equal(diff(fc$time), rep(1 / 12, 23), tolerance = 1e-8)
})

test_that("ts_forecast() validates its inputs", {
  expect_error(ts_forecast(rnorm(50)), "frequency")
  expect_error(ts_forecast(stats::ts(rnorm(50), frequency = 1)), "seasonal")
  expect_error(ts_forecast(stats::ts(rnorm(12), frequency = 12)),
               "two full cycles")
  expect_error(ts_forecast(AirPassengers, h = -1), "positive integer")
  expect_error(ts_forecast(AirPassengers, level = 1.5), "between 0 and 1")
})

test_that("timeseries_plot() forecast overlay builds and is anchored", {
  y <- ms_ts()
  p <- timeseries_plot(y, forecast = 24, level = 0.9)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))

  # the resolved forecast frame is anchored at the last observed point
  dfh <- data.frame(time = as.numeric(stats::time(y)),
                    value = as.numeric(y), series = "series")
  fcdf <- depictr:::resolve_forecast(24, y, dfh, level = 0.9)
  expect_equal(fcdf$fit[1], as.numeric(y)[length(y)])
  expect_equal(nrow(fcdf), 25L) # anchor + 24

  # a user-supplied forecast data frame is accepted
  userfc <- data.frame(time = 100:111, fit = 200:211)
  expect_silent(ggplot2::ggplot_build(timeseries_plot(y, forecast = userfc)))
})

test_that("the built-in forecast overlay names its interval and method", {
  y <- ms_ts()
  p <- timeseries_plot(y, forecast = 12)
  expect_identical(
    p$labels$caption,
    "Shaded: 95% prediction interval (STL + random walk with drift)."
  )
  expect_match(timeseries_plot(y, forecast = 12, level = 0.9)$labels$caption,
               "^Shaded: 90% prediction interval")
  expect_match(
    timeseries_plot(AirPassengers, forecast = 12, lambda = 0)$labels$caption,
    "on the log scale"
  )
  expect_match(
    timeseries_plot(AirPassengers, forecast = 12, lambda = 0.5)$labels$caption,
    "Box-Cox lambda = 0.5"
  )
  # A forecast the caller computed is theirs to describe.
  userfc <- data.frame(time = 2024 + (1:12) / 12, fit = 1:12,
                       lwr = 0:11, upr = 2:13)
  expect_null(timeseries_plot(y, forecast = userfc)$labels$caption)
})

test_that("timeseries_plot() passes lambda to the built-in forecast", {
  y <- AirPassengers
  dfh <- data.frame(time = as.numeric(stats::time(y)),
                    value = as.numeric(y), series = "series")
  fcdf <- depictr:::resolve_forecast(12, y, dfh, level = 0.9, lambda = 0)
  expect_equal(fcdf[-1, c("fit", "lwr", "upr")],
               ts_forecast(y, h = 12, level = 0.9, lambda = 0)[
                 , c("fit", "lwr", "upr")],
               ignore_attr = TRUE)
})

test_that("an integer forecast horizon continues a numeric `x` on its own axis", {
  # Regression: a numeric `x` was wrapped in a ts starting at time 1, so the
  # forecast times came back in cycle units, from 1 + n / frequency onwards.
  # The overlay jumped from the last observation back to about
  # x = n / frequency, and on a Date axis it landed in the year 4.
  set.seed(1)
  vals <- 100 + 10 * sin(2 * pi * seq_len(36) / 12) + stats::rnorm(36)
  fc_times <- function(p) p$layers[[length(p$layers)]]$data$time
  # The default axis is the observation index.
  p <- timeseries_plot(vals, forecast = 6, frequency = 12)
  expect_equal(fc_times(p), c(36, 37:42))
  # A numeric `time`.
  p <- timeseries_plot(vals, time = 2000:2035, forecast = 6, frequency = 12)
  expect_equal(fc_times(p), c(2035, 2036:2041))
  # Irregular spacing continues at the typical step.
  p <- timeseries_plot(vals, time = c(seq(2, 70, by = 2), 100),
                       forecast = 3, frequency = 12)
  expect_equal(fc_times(p), c(100, 102, 104, 106))
  # A Date axis steps by the median gap in days.
  months <- seq(as.Date("2020-01-01"), by = "month", length.out = 36)
  p <- timeseries_plot(vals, time = months, forecast = 6, frequency = 12)
  ft <- fc_times(p)
  expect_s3_class(ft, "Date")
  expect_equal(ft[1], as.Date("2022-12-01"))
  expect_equal(as.numeric(diff(ft)), rep(31, 6))
  # A ts keeps its decimal-year axis.
  y <- ms_ts()
  p <- timeseries_plot(y, forecast = 6)
  expect_equal(fc_times(p)[-1], as.numeric(stats::time(y))[length(y)] +
                 seq_len(6) / stats::frequency(y))
})

test_that("an integer forecast horizon forecasts a numeric `x` in time order", {
  # Regression: the history is drawn in time order, but the forecast was made
  # from `x` in the order given, so with an unsorted `time` the overlay
  # extended a series other than the one drawn.
  set.seed(1)
  vals <- 100 + 10 * sin(2 * pi * seq_len(36) / 12) + seq_len(36) / 2 +
    stats::rnorm(36)
  shuffle <- sample(36)
  fc_layer <- function(p) p$layers[[length(p$layers)]]$data
  sorted <- fc_layer(timeseries_plot(vals, time = 1:36, forecast = 6,
                                     frequency = 12))
  shuffled <- fc_layer(timeseries_plot(vals[shuffle], time = shuffle,
                                       forecast = 6, frequency = 12))
  expect_equal(shuffled, sorted)
  expect_equal(sorted$fit[-1], ts_forecast(vals, h = 6, frequency = 12)$fit)
})

test_that("timeseries_plot() rejects unsupported forecast combinations", {
  df <- data.frame(t = rep(1:30, 2), v = rnorm(60),
                   g = rep(c("a", "b"), each = 30))
  expect_error(timeseries_plot(df, t, v, group = g, forecast = 5),
               "single series")
  expect_error(
    timeseries_plot(data.frame(t = 1:24, v = rnorm(24)), t, v, forecast = 5),
    "ts or numeric"
  )
})

test_that("decompose_plot() ribbon equals trend +/- z * sd(remainder)", {
  y <- ms_ts()
  pd <- decompose_plot(y, confidence = TRUE, level = 0.95)
  expect_s3_class(pd, "patchwork")

  dec <- stats::stl(y, s.window = "periodic")$time.series
  rem <- as.numeric(dec[, "remainder"])
  z <- stats::qnorm(0.975); s <- stats::sd(rem, na.rm = TRUE)

  tb <- ggplot2::ggplot_build(pd[[2]]) # trend panel is the 2nd plot
  rib <- NULL
  for (layer in tb$data) {
    if (all(c("ymin", "ymax") %in% names(layer))) rib <- layer
  }
  expect_false(is.null(rib))
  expect_equal(unique(round(rib$ymax - rib$ymin, 6)), round(2 * z * s, 6))
})

test_that("decompose_plot() robust STL and backward compatibility", {
  y <- ms_ts()
  expect_s3_class(decompose_plot(y, robust = TRUE), "patchwork")
  expect_s3_class(decompose_plot(y, robust = TRUE, confidence = TRUE),
                  "patchwork")
  # unchanged default behaviour
  expect_s3_class(decompose_plot(AirPassengers), "patchwork")
  expect_s3_class(decompose_plot(AirPassengers, method = "classical"),
                  "patchwork")
  expect_error(decompose_plot(y, confidence = TRUE, level = 2),
               "between 0 and 1")
})

test_that("decompose_plot() exposes the STL seasonal window", {
  seasonal_panel <- function(p) p[[3]]$data$y
  cyc <- stats::cycle(AirPassengers)
  within_month <- function(s) tapply(s, cyc, function(v) diff(range(v)))
  # The default stays periodic: each month has one seasonal value throughout.
  s_per <- seasonal_panel(decompose_plot(AirPassengers))
  expect_true(all(within_month(s_per) < 1e-8))
  # A numeric window lets the seasonal component change from year to year,
  # which AirPassengers needs: its seasonal swing grows with its level.
  s13 <- seasonal_panel(decompose_plot(AirPassengers, s_window = 13))
  expect_gt(max(within_month(s13)), 10)
  expect_equal(s13, as.numeric(stats::stl(AirPassengers, s.window = 13)$
                                 time.series[, "seasonal"]))
  expect_s3_class(decompose_plot(AirPassengers, s_window = 7, robust = TRUE),
                  "patchwork")
  # stl() accepts an abbreviation of "periodic", and so does decompose_plot().
  expect_equal(seasonal_panel(decompose_plot(AirPassengers, s_window = "per")),
               s_per)
  # stl() would round a fractional window, raise an even one to the next odd
  # number and accept one below 7 without a word, so all of them are refused.
  for (bad in list(4, 12, 7.5, c(7, 9), NA_real_, "weekly", "", TRUE)) {
    expect_error(decompose_plot(AirPassengers, s_window = bad),
                 "`s_window` must be \"periodic\" or an odd whole number")
  }
})

test_that("a frequency-7 series is labelled by season index, not weekday", {
  # Regression: a plain ts(x, frequency = 7) carries no weekday information --
  # season 1 is simply the first observation -- yet the panels were labelled
  # Mon..Sun, contradicting @param season_labels.
  set.seed(3)
  y <- stats::ts(rnorm(70), frequency = 7)
  expect_equal(depictr:::default_season_labels(7), as.character(1:7))
  p <- seasonal_plot(y)
  expect_setequal(unique(as.character(p$data$season)), as.character(1:7))
  expect_false(any(c("Mon", "Sun") %in% as.character(p$data$season)))

  # Frequencies the ts start really does pin down keep their names.
  expect_equal(depictr:::default_season_labels(12), month.abb)
  expect_equal(depictr:::default_season_labels(4), paste0("Q", 1:4))
  # A caller who does know the alignment can still supply the weekdays.
  wd <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  pw <- seasonal_plot(y, season_labels = wd)
  expect_setequal(unique(as.character(pw$data$season)), wd)
})

test_that("timeseries_plot() draws a multivariate ts as one series per column", {
  # Regression: as.numeric() flattened cbind(mdeaths, fdeaths) into 144 rows of
  # one series on 72 recycled times, so the line zigzagged between the two
  # columns at every time.
  y <- cbind(mdeaths, fdeaths)
  p <- timeseries_plot(y)
  expect_identical(levels(p$data$series), c("mdeaths", "fdeaths"))
  for (s in colnames(y)) {
    d <- p$data[p$data$series == s, ]
    expect_equal(d$time, as.numeric(stats::time(y)))
    expect_equal(d$value, as.numeric(y[, s]))
  }
  expect_silent(b <- ggplot2::ggplot_build(p))
  expect_setequal(unique(b$data[[1]]$colour), depictr_palette(2))
  # The moving average is taken within each series.
  roll <- timeseries_plot(y, rolling = 12)$layers[[2]]$data
  expect_equal(roll$roll[roll$series == "fdeaths"],
               depictr:::moving_average(as.numeric(fdeaths), 12))
  # A forecast is made for a single series.
  expect_error(timeseries_plot(y, forecast = 12), "single series")
})

test_that("timeseries_plot() draws a numeric matrix as one series per column", {
  m <- cbind(a = 1:10, b = 11:20)
  p <- timeseries_plot(m)
  expect_identical(levels(p$data$series), c("a", "b"))
  expect_equal(p$data$time[p$data$series == "b"], 1:10)
  expect_equal(p$data$value[p$data$series == "b"], 11:20)
  # `time` gives one time per row, as it gives one per value of a vector.
  p <- timeseries_plot(m, time = 2001:2010)
  expect_equal(p$data$time[p$data$series == "a"], 2001:2010)
  expect_error(timeseries_plot(m, time = 1:5), "one entry per row")
  # Columns without names are named as stats::ts() names them.
  expect_identical(levels(timeseries_plot(unname(m))$data$series),
                   c("Series 1", "Series 2"))
  # A single column is a single series.
  expect_identical(
    nlevels(timeseries_plot(m[, "a", drop = FALSE])$data$series), 1L
  )
})

test_that("the single-series functions refuse several columns", {
  # acf_plot() returned the autocorrelation of the columns laid end to end,
  # seasonal_plot() and the classical decompose_plot() drew them over each
  # other, and ts_forecast() forecast the concatenation at missing times.
  y <- cbind(mdeaths, fdeaths)
  two <- "`x` has 2 columns; pass one series at a time."
  expect_error(acf_plot(y), two, fixed = TRUE)
  expect_error(acf_plot(y, type = "partial"), two, fixed = TRUE)
  expect_error(seasonal_plot(y), two, fixed = TRUE)
  expect_error(decompose_plot(y), two, fixed = TRUE)
  expect_error(decompose_plot(y, method = "classical"), two, fixed = TRUE)
  expect_error(ts_forecast(y), two, fixed = TRUE)
  # A plain matrix with a frequency is refused before it becomes a ts.
  m <- cbind(as.numeric(mdeaths), as.numeric(fdeaths), as.numeric(ldeaths))
  three <- "`x` has 3 columns; pass one series at a time."
  expect_error(acf_plot(m), three, fixed = TRUE)
  expect_error(seasonal_plot(m, frequency = 12), three, fixed = TRUE)
  expect_error(decompose_plot(m, frequency = 12), three, fixed = TRUE)
  expect_error(ts_forecast(m, frequency = 12), three, fixed = TRUE)
  # One column of a multivariate ts is a series like any other.
  expect_s3_class(acf_plot(y[, "mdeaths"]), "ggplot")
  expect_s3_class(seasonal_plot(y[, "fdeaths"]), "ggplot")
})

test_that("a ts with one column is read as that series", {
  # ts() of a one-column data frame makes a ts with one column, which stl()
  # refused with "only univariate series are allowed".
  y1 <- stats::ts(data.frame(passengers = as.numeric(AirPassengers)),
                  start = 1949, frequency = 12)
  expect_identical(dim(y1), c(144L, 1L))
  for (method in c("stl", "classical")) {
    pw1 <- decompose_plot(y1, method = method)
    pw <- decompose_plot(AirPassengers, method = method)
    for (i in 1:4) expect_equal(pw1[[i]]$data, pw[[i]]$data)
  }
  expect_equal(ts_forecast(y1, h = 6), ts_forecast(AirPassengers, h = 6))
  expect_equal(acf_plot(y1)$data, acf_plot(AirPassengers)$data)
  expect_equal(seasonal_plot(y1)$data, seasonal_plot(AirPassengers)$data)
  # The column keeps its times when missing values at the ends are trimmed.
  y1[c(1, 144)] <- NA
  expect_equal(ts_forecast(y1, h = 3)$time, 1960 + (11:13) / 12)
})

test_that("decompose_plot() and ts_forecast() trim missing values at the ends", {
  # Both stopped with stl()'s "missing values in object" when a value at either
  # end was missing. The Python twin trims such values.
  y <- AirPassengers
  y[c(1, 2, 143, 144)] <- NA
  observed <- stats::window(AirPassengers, start = c(1949, 3),
                            end = c(1960, 10))
  expect_equal(ts_forecast(y, h = 6), ts_forecast(observed, h = 6))
  # The forecast starts in the month after the last observation.
  expect_equal(ts_forecast(y, h = 6)$time[1], 1960 + 10 / 12)
  expect_equal(ts_forecast(as.numeric(y), h = 6, frequency = 12)$fit,
               ts_forecast(observed, h = 6)$fit)
  for (method in c("stl", "classical")) {
    pw <- decompose_plot(y, method = method)
    expect_equal(pw[[1]]$data$t, as.numeric(stats::time(observed)))
    expect_equal(pw[[1]]$data$y, as.numeric(observed))
  }
})

test_that("an interior missing value is refused by name", {
  # stl() stopped with "missing values in object" and decompose() with "time
  # series contains internal NAs", naming neither the argument nor a remedy.
  y <- AirPassengers
  y[60] <- NA
  msg <- paste("`x` must not contain internal missing values; drop or impute",
               "them before")
  expect_error(decompose_plot(y), paste(msg, "plotting."), fixed = TRUE)
  expect_error(decompose_plot(y, method = "classical"),
               paste(msg, "plotting."), fixed = TRUE)
  expect_error(ts_forecast(y), paste(msg, "forecasting."), fixed = TRUE)
  expect_error(ts_forecast(as.numeric(y), frequency = 12), msg, fixed = TRUE)
  expect_error(timeseries_plot(y, forecast = 6), paste(msg, "forecasting."),
               fixed = TRUE)
  # The series alone is still drawn, with its gap.
  expect_s3_class(timeseries_plot(y), "ggplot")
  # A series with no observation has nothing to trim to.
  expect_error(ts_forecast(stats::ts(rep(NA_real_, 36), frequency = 12)),
               "no non-missing values")
})

test_that("timeseries_plot() forecasts from the last observation", {
  # With missing values at the end, the forecast continues from the last value
  # observed, and the overlay is anchored there.
  y <- AirPassengers
  y[c(143, 144)] <- NA
  observed <- stats::window(AirPassengers, end = c(1960, 10))
  p <- timeseries_plot(y, forecast = 6)
  fc <- p$layers[[length(p$layers)]]$data
  expect_equal(fc$time[1], 1960 + 9 / 12)
  expect_equal(fc$fit[1], as.numeric(observed)[length(observed)])
  expect_equal(fc$fit[-1], ts_forecast(observed, h = 6)$fit)
  expect_silent(ggplot2::ggplot_build(p))
  # A numeric `x` steps on from its last observed position.
  q <- timeseries_plot(as.numeric(y), forecast = 3, frequency = 12)
  expect_equal(q$layers[[length(q$layers)]]$data$time, c(142, 143:145))
})
