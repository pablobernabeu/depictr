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

test_that("ts_forecast() point forecast matches STL + lin-trend + seasonal-naive", {
  y <- ms_ts()
  fc <- ts_forecast(y, h = 24, level = 0.95)

  dec <- stats::stl(y, s.window = "periodic")$time.series
  trend <- as.numeric(dec[, "trend"])
  seas <- as.numeric(dec[, "seasonal"])
  rem <- as.numeric(dec[, "remainder"])
  n <- length(y); f <- 12
  last_idx <- (n - f + 1):n
  fit_lm <- stats::lm(v ~ t, data = data.frame(t = last_idx,
                                               v = trend[last_idx]))
  fut <- (n + 1):(n + 24)
  trend_fc <- as.numeric(stats::predict(fit_lm,
                                        newdata = data.frame(t = fut)))
  cyc <- as.integer(stats::cycle(y)); last_pos <- cyc[n]
  sv <- stats::setNames(seas[last_idx], cyc[last_idx])
  spos <- ((last_pos - 1 + 1:24) %% f) + 1
  exp_fit <- trend_fc + as.numeric(sv[as.character(spos)])

  expect_equal(fc$fit, exp_fit, tolerance = 1e-8)

  # interval half-width is z * sigma * sqrt(h)
  z <- stats::qnorm(0.975); sig <- stats::sd(rem)
  expect_equal(fc$upr - fc$fit, z * sig * sqrt(1:24), tolerance = 1e-8)
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
