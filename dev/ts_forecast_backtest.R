# Rolling-origin backtest of the prediction intervals of ts_forecast().
#
# Run from the package root:
#   Rscript dev/ts_forecast_backtest.R
#
# The package is loaded from this checkout, so the backtest measures the code
# beside it. Eight classic monthly and quarterly series from base R are cut at
# a run of forecast origins, the first after three full cycles and then one
# every half cycle while 12 observations remain. At each origin the observations
# so far are forecast 12 steps ahead, and each of the next 12 observations is
# checked against the band. Coverage is the share inside the band, averaged
# within each series and then across series, so a long series does not
# outweigh a short one.
#
# The same backtest runs on the construction ts_forecast() used up to depictr
# 0.3.0, reproduced below, and on the log scale (lambda = 0) for the three
# series whose seasonal swing grows with their level. When the forecast package
# is installed, every forecast is also compared with
# forecast::stlf(method = "rwdrift", s.window = "periodic").
#
# Results with R 4.6.1 and forecast 9.0.2 on 2026-10-02. Coverage over all
# eight series, then over the five whose seasonal swing does not grow with
# their level:
#
#   nominal  construction   overall  one step  overall (5)  one step (5)
#   95%      depictr 0.3.0    0.813     0.605        0.933         0.774
#   95%      current          0.907     0.829        0.983         0.922
#   80%      depictr 0.3.0    0.679     0.469        0.817         0.588
#   80%      current          0.800     0.658        0.924         0.761
#
# On those five series, the current construction's nominal 95% band covers
# 0.922 of outcomes one step ahead, 0.937 two steps ahead and 0.994 from three
# to 12 steps ahead. It runs narrow at first and wide further out.
#
# On the log scale, the current construction's nominal 95% band covers 1.000,
# 0.814 and 0.968 of one-step outcomes for AirPassengers, UKgas and
# JohnsonJohnson, against 0.765, 0.674 and 0.581 on the original scale. Every
# forecast agrees with forecast::stlf() to within 6e-13. The run takes about a
# minute.

pkgload::load_all(".", quiet = TRUE)

series <- list(
  AirPassengers = datasets::AirPassengers,
  logAirPassengers = log(datasets::AirPassengers),
  co2 = datasets::co2,
  UKgas = datasets::UKgas,
  nottem = datasets::nottem,
  JohnsonJohnson = datasets::JohnsonJohnson,
  UKDriverDeaths = datasets::UKDriverDeaths,
  sunspot = stats::window(datasets::sunspot.month, start = c(1900, 1),
                          end = c(1959, 12))
)
# The five series with a seasonal swing of stable size, the case the additive
# model is built for, and the three whose swing grows with their level.
additive <- c("logAirPassengers", "co2", "nottem", "UKDriverDeaths", "sunspot")
multiplicative <- c("AirPassengers", "UKgas", "JohnsonJohnson")

# ts_forecast() up to depictr 0.3.0: the STL trend extrapolated from a straight
# line through its last cycle, the last seasonal cycle carried forward, and a
# band of z * sd(STL remainder) * sqrt(h).
legacy_forecast <- function(x, h, level) {
  n <- length(x)
  freq <- stats::frequency(x)
  dec <- stats::stl(x, s.window = "periodic")$time.series
  trend <- as.numeric(dec[, "trend"])
  seasonal <- as.numeric(dec[, "seasonal"])
  last <- seq.int(n - freq + 1L, n)
  line <- stats::lm(y ~ t, data = data.frame(t = last, y = trend[last]))
  trend_fc <- stats::predict(line, newdata = data.frame(t = n + seq_len(h)))
  fit <- as.numeric(trend_fc) +
    seasonal[n - freq + ((seq_len(h) - 1L) %% freq) + 1L]
  half <- stats::qnorm((1 + level) / 2) *
    stats::sd(as.numeric(dec[, "remainder"])) * sqrt(seq_len(h))
  data.frame(fit = fit, lwr = fit - half, upr = fit + half)
}

current_forecast <- function(x, h, level) ts_forecast(x, h = h, level = level)

log_forecast <- function(x, h, level) {
  ts_forecast(x, h = h, level = level, lambda = 0)
}

# One row per held-out observation: its series, origin, step and whether the
# band covered it.
backtest <- function(forecaster, names, level, h = 12, first_cycles = 3) {
  rows <- lapply(names, function(nm) {
    y <- series[[nm]]
    m <- stats::frequency(y)
    origins <- seq(first_cycles * m, length(y) - h, by = max(1, m %/% 2))
    do.call(rbind, lapply(origins, function(o) {
      train <- stats::ts(as.numeric(y)[seq_len(o)], start = stats::start(y),
                         frequency = m)
      held_out <- as.numeric(y)[o + seq_len(h)]
      fc <- forecaster(train, h, level)
      data.frame(series = nm, origin = o, step = seq_len(h),
                 inside = held_out >= fc$lwr & held_out <= fc$upr)
    }))
  })
  do.call(rbind, rows)
}

# The mean over series of each series' coverage, overall and one step ahead.
coverage <- function(r, names = unique(r$series)) {
  r <- r[r$series %in% names, ]
  one <- r[r$step == 1, ]
  c(overall = mean(tapply(r$inside, r$series, mean)),
    one_step = mean(tapply(one$inside, one$series, mean)))
}

summary_rows <- list()
for (level in c(0.95, 0.80)) {
  for (construction in c("depictr 0.3.0", "current")) {
    f <- if (construction == "current") current_forecast else legacy_forecast
    r <- backtest(f, names(series), level)
    all8 <- coverage(r)
    add5 <- coverage(r, additive)
    summary_rows[[length(summary_rows) + 1]] <- data.frame(
      nominal = paste0(100 * level, "%"), construction = construction,
      overall = all8[["overall"]], one_step = all8[["one_step"]],
      overall_5 = add5[["overall"]], one_step_5 = add5[["one_step"]]
    )
  }
}
cat("Coverage of the prediction intervals (mean over series):\n")
print(do.call(rbind, summary_rows), digits = 3, row.names = FALSE)

cat("\nNominal 95% coverage of the current construction by step ahead,",
    "series whose seasonal swing does not grow with their level:\n")
r5 <- backtest(current_forecast, additive, 0.95)
print(round(colMeans(tapply(r5$inside, list(r5$series, r5$step), mean)), 3))
later <- r5[r5$step >= 3, ]
cat("Steps 3 to 12:", round(mean(tapply(later$inside, later$series, mean)), 3),
    "\n")

cat("\nNominal 95% coverage one step ahead, series whose seasonal swing grows",
    "with their level:\n")
one_step <- function(r) {
  one <- r[r$step == 1, ]
  tapply(one$inside, one$series, mean)[multiplicative]
}
print(round(rbind(
  original_scale = one_step(backtest(current_forecast, multiplicative, 0.95)),
  log_scale = one_step(backtest(log_forecast, multiplicative, 0.95))
), 3))

if (requireNamespace("forecast", quietly = TRUE)) {
  worst <- 0
  for (nm in names(series)) {
    y <- series[[nm]]
    m <- stats::frequency(y)
    for (o in seq(3 * m, length(y) - 12, by = max(1, m %/% 2))) {
      train <- stats::ts(as.numeric(y)[seq_len(o)], start = stats::start(y),
                         frequency = m)
      ours <- ts_forecast(train, h = 12, level = 0.95)
      theirs <- forecast::stlf(train, h = 12, method = "rwdrift",
                               s.window = "periodic", level = 95)
      worst <- max(worst, abs(ours$fit - as.numeric(theirs$mean)),
                   abs(ours$lwr - as.numeric(theirs$lower)),
                   abs(ours$upr - as.numeric(theirs$upper)))
    }
  }
  cat("\nLargest absolute difference from forecast::stlf() over every origin:",
      format(worst, digits = 3), "\n")
}
