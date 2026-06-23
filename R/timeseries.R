# Time-series plots ----------------------------------------------------------

#' Time-series plot
#'
#' Plots one or more series over time, with an optional moving-average overlay.
#' The input can be a `ts` object, a numeric vector, or a data frame with a time
#' column, a value column and an optional grouping column.
#'
#' @param x A `ts` object, a numeric vector, or a data frame.
#' @param time When `x` is a data frame, the time column (string or unquoted
#'   name); when `x` is a numeric vector, an optional vector of times.
#' @param value When `x` is a data frame, the value column.
#' @param group When `x` is a data frame, an optional grouping column mapped to
#'   colour.
#' @param rolling Optional integer window for a centred moving-average overlay.
#'   The data are ordered by time (within each group) before the moving average
#'   is computed, so unsorted input is handled correctly.
#' @param forecast Optional forecast overlay for a single (non-grouped) series.
#'   Either an integer horizon (number of future steps) to forecast with the
#'   built-in STL + seasonal-naive-with-drift method (see [ts_forecast()]), or a
#'   pre-computed forecast supplied as a data frame with columns `time`, `fit`
#'   and (optionally) `lwr`/`upr` -- for instance from a fitted
#'   `forecast::forecast()` object. The point forecast continues the line and a
#'   shaded prediction-interval ribbon, which widens with the horizon, is drawn
#'   behind it.
#' @param frequency Number of observations per period, used only to coerce a
#'   numeric `x` to a `ts` when an integer `forecast` horizon is requested.
#' @param level Prediction-interval coverage for the built-in forecast (a single
#'   number strictly between 0 and 1, e.g. `0.95`).
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param point Whether to add points as well as the line.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @seealso [ts_forecast()], [decompose_plot()], [seasonal_plot()]
#' @export
#' @examples
#' timeseries_plot(AirPassengers, rolling = 12,
#'                 title = "Air passengers", y_lab = "Passengers")
#' # 24-month forecast with a 90% prediction interval
#' timeseries_plot(AirPassengers, forecast = 24, level = 0.9)
timeseries_plot <- function(x, time = NULL, value = NULL, group = NULL,
                            rolling = NULL, forecast = NULL, frequency = NULL,
                            level = 0.95, palette = NULL, point = FALSE,
                            title = NULL, x_lab = NULL, y_lab = NULL) {
  if (is.data.frame(x)) {
    tcol <- resolve_var(x, rlang::enquo(time), "time")
    vcol <- resolve_var(x, rlang::enquo(value), "value")
    gcol <- resolve_var(x, rlang::enquo(group), "group")
    if (is.null(tcol) || is.null(vcol)) {
      stop("For a data frame, supply `time` and `value` columns.",
           call. = FALSE)
    }
    df <- data.frame(time = x[[tcol]], value = x[[vcol]])
    df$series <- if (is.null(gcol)) "series" else as.character(x[[gcol]])
    x_lab <- x_lab %||% tcol
    y_lab <- y_lab %||% vcol
  } else if (stats::is.ts(x)) {
    df <- data.frame(time = as.numeric(stats::time(x)),
                     value = as.numeric(x), series = "series")
    x_lab <- x_lab %||% "Time"
  } else {
    if (!is.numeric(x)) stop("`x` must be a ts, numeric vector or data frame.",
                             call. = FALSE)
    tv <- if (!is.null(time)) time else seq_along(x)
    df <- data.frame(time = tv, value = as.numeric(x), series = "series")
    x_lab <- x_lab %||% "Time"
  }
  y_lab <- y_lab %||% "Value"
  df$series <- factor(df$series, levels = unique(df$series))
  # Order by series then time so the moving average (and the drawn lines) follow
  # time order even when the input data frame is unsorted.
  df <- df[order(df$series, df$time), , drop = FALSE]
  multi <- nlevels(df$series) > 1
  pal <- palette %||% depictr_palette(nlevels(df$series))
  caption <- NULL

  mapping <- if (multi) {
    ggplot2::aes(x = .data$time, y = .data$value, colour = .data$series)
  } else {
    ggplot2::aes(x = .data$time, y = .data$value)
  }
  p <- ggplot2::ggplot(df, mapping)
  if (multi) {
    p <- p + ggplot2::geom_line(linewidth = 0.6, na.rm = TRUE)
    if (point) p <- p + ggplot2::geom_point(size = 0.9, na.rm = TRUE)
  } else {
    p <- p + ggplot2::geom_line(linewidth = 0.6, colour = depictr_brand(),
                                na.rm = TRUE)
    if (point) p <- p + ggplot2::geom_point(size = 0.9, colour = depictr_brand(),
                                            na.rm = TRUE)
  }

  if (!is.null(rolling)) {
    rolling <- validate_window(rolling)
    min_len <- min(tabulate(df$series))
    if (rolling > min_len) {
      stop("`rolling` (", rolling, ") is larger than the shortest series (",
           min_len, " observation", if (min_len == 1) "" else "s",
           "); choose a smaller window.", call. = FALSE)
    }
    df$roll <- stats::ave(df$value, df$series,
                          FUN = function(v) moving_average(v, rolling))
    if (multi) {
      # Draw the moving average as a dashed line in each series' colour so it
      # shares the single colour legend. `show.legend = FALSE` keeps it out of
      # the legend key glyphs, and a caption (added below) explains the dashes,
      # so the plot keeps exactly one legend box instead of adding a second one.
      p <- p + ggplot2::geom_line(
        data = df, ggplot2::aes(x = .data$time, y = .data$roll,
                                colour = .data$series),
        linewidth = 1, linetype = "dashed", na.rm = TRUE, show.legend = FALSE
      )
      caption <- paste0("Dashed line: ", rolling,
                        "-point centred moving average")
    } else {
      p <- p + ggplot2::geom_line(
        data = df, ggplot2::aes(x = .data$time, y = .data$roll),
        colour = depictr_accent(), linewidth = 0.9, na.rm = TRUE,
        inherit.aes = FALSE
      )
    }
  }

  if (!is.null(forecast)) {
    if (multi) {
      stop("A forecast overlay is only supported for a single series.",
           call. = FALSE)
    }
    fc <- resolve_forecast(forecast, x, df, frequency = frequency,
                           level = level)
    if (!is.null(fc$lwr) && !is.null(fc$upr)) {
      p <- p + ggplot2::geom_ribbon(
        data = fc, ggplot2::aes(x = .data$time, ymin = .data$lwr,
                                ymax = .data$upr),
        fill = depictr_brand(), alpha = 0.15, inherit.aes = FALSE
      )
    }
    p <- p + ggplot2::geom_line(
      data = fc, ggplot2::aes(x = .data$time, y = .data$fit),
      colour = depictr_accent(), linewidth = 0.8, linetype = "longdash",
      na.rm = TRUE, inherit.aes = FALSE
    )
  }

  if (multi) p <- p + ggplot2::scale_colour_manual(values = pal, name = NULL)
  p + ggplot2::labs(x = x_lab, y = y_lab, title = title, caption = caption) +
    theme_depictr()
}

#' Autocorrelation plot
#'
#' Plots the autocorrelation (or partial autocorrelation) function of a series,
#' with the approximate significance bounds, as a clean lollipop chart.
#'
#' @param x A numeric vector or `ts` object.
#' @param lag_max Maximum lag (passed to [stats::acf()] / [stats::pacf()]).
#' @param type `"correlation"` for the ACF or `"partial"` for the PACF.
#' @param conf_level Confidence level for the significance bounds; a single
#'   number strictly between 0 and 1.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' acf_plot(AirPassengers)
#' acf_plot(AirPassengers, type = "partial")
acf_plot <- function(x, lag_max = NULL, type = c("correlation", "partial"),
                     conf_level = 0.95, title = NULL, x_lab = "Lag",
                     y_lab = NULL) {
  type <- match.arg(type)
  if (!is.numeric(conf_level) || length(conf_level) != 1 ||
      !is.finite(conf_level) || conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  }
  v <- as.numeric(x)
  # Keep the series in place (do not drop interior NAs, which would concatenate
  # across gaps and bias the autocorrelation); na.pass preserves the time
  # structure and acf()/pacf() handle the missingness pairwise.
  obs <- which(!is.na(v))
  if (length(obs) > 1 &&
      anyNA(v[seq.int(obs[1], obs[length(obs)])])) {
    warning("Series has interior missing values; the ", type,
            " is computed pairwise (na.action = na.pass).", call. = FALSE)
  }
  if (type == "partial") {
    a <- stats::pacf(v, lag.max = lag_max, plot = FALSE,
                     na.action = stats::na.pass)
    y_lab <- y_lab %||% "Partial ACF"
  } else {
    a <- stats::acf(v, lag.max = lag_max, plot = FALSE,
                    na.action = stats::na.pass)
    y_lab <- y_lab %||% "ACF"
  }
  df <- data.frame(lag = as.numeric(a$lag), acf = as.numeric(a$acf))
  if (type == "correlation") df <- df[df$lag > 0, , drop = FALSE]
  bound <- stats::qnorm((1 + conf_level) / 2) / sqrt(a$n.used)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$lag, y = .data$acf)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey40") +
    ggplot2::geom_hline(yintercept = c(-bound, bound), linetype = 2,
                        colour = depictr_reference()) +
    ggplot2::geom_segment(ggplot2::aes(xend = .data$lag, yend = 0),
                          colour = depictr_brand(), linewidth = 0.6) +
    ggplot2::geom_point(colour = depictr_brand(), size = 1.6) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()
}

#' Time-series decomposition plot
#'
#' Decomposes a seasonal time series into trend, seasonal and remainder
#' components and shows them, with the original series, as stacked panels.
#'
#' @param x A `ts` object, or a numeric vector (then `frequency` is required).
#' @param frequency Number of observations per period (e.g. 12 for monthly
#'   data); taken from `x` when it is a `ts`.
#' @param method `"stl"` (loess-based) or `"classical"`
#'   ([stats::decompose()]).
#' @param robust For `method = "stl"`, whether to fit a robust STL
#'   ([stats::stl()] with `robust = TRUE`), which down-weights outliers in the
#'   loess fits so that an unusual point bleeds less into the trend and seasonal
#'   components. Ignored for the classical method.
#' @param confidence Whether to draw a confidence ribbon around the trend
#'   component. The band is a normal-approximation interval based on the
#'   remainder's standard deviation (see Details). `FALSE` reproduces the
#'   previous behaviour exactly.
#' @param level Coverage of the trend confidence ribbon (a single number
#'   strictly between 0 and 1).
#' @param title Plot title.
#'
#' @details
#' The trend confidence ribbon is a pragmatic normal-approximation band:
#' `trend +/- z * sd(remainder)`, where `z = qnorm((1 + level) / 2)` and the
#' remainder standard deviation is computed on the non-missing remainder values.
#' It conveys the scale of the unexplained variation around the smoothed trend
#' rather than a formal sampling-distribution interval.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @seealso [ts_forecast()], [seasonal_plot()]
#' @export
#' @examples
#' decompose_plot(AirPassengers)
#' decompose_plot(AirPassengers, method = "classical")
#' # Robust STL with a confidence ribbon on the trend
#' decompose_plot(AirPassengers, robust = TRUE, confidence = TRUE)
decompose_plot <- function(x, frequency = NULL,
                           method = c("stl", "classical"), robust = FALSE,
                           confidence = FALSE, level = 0.95, title = NULL) {
  method <- match.arg(method)
  if (!stats::is.ts(x)) {
    if (is.null(frequency)) {
      stop("Supply `frequency` when `x` is not a ts object.", call. = FALSE)
    }
    x <- stats::ts(as.numeric(x), frequency = frequency)
  }
  if (stats::frequency(x) < 2) {
    stop("Decomposition needs a seasonal series (frequency >= 2).",
         call. = FALSE)
  }
  if (confidence &&
      (!is.numeric(level) || length(level) != 1 || !is.finite(level) ||
       level <= 0 || level >= 1)) {
    stop("`level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  }
  tt <- as.numeric(stats::time(x))

  if (method == "stl") {
    dec <- stats::stl(x, s.window = "periodic", robust = robust)$time.series
    comps <- data.frame(
      trend = as.numeric(dec[, "trend"]),
      seasonal = as.numeric(dec[, "seasonal"]),
      remainder = as.numeric(dec[, "remainder"])
    )
  } else {
    dec <- stats::decompose(x)
    comps <- data.frame(
      trend = as.numeric(dec$trend),
      seasonal = as.numeric(dec$seasonal),
      remainder = as.numeric(dec$random)
    )
  }
  observed <- as.numeric(x)

  panel <- function(y, lab, colour, ribbon = NULL) {
    pd <- data.frame(t = tt, y = y)
    g <- ggplot2::ggplot(pd, ggplot2::aes(x = .data$t, y = .data$y))
    if (!is.null(ribbon)) {
      pd$lwr <- ribbon$lwr
      pd$upr <- ribbon$upr
      g <- g + ggplot2::geom_ribbon(
        data = pd, ggplot2::aes(x = .data$t, ymin = .data$lwr,
                                ymax = .data$upr),
        fill = colour, alpha = 0.15, inherit.aes = FALSE
      )
    }
    g +
      ggplot2::geom_line(colour = colour, linewidth = 0.6, na.rm = TRUE) +
      ggplot2::labs(x = NULL, y = lab) +
      theme_depictr(grid = "y") +
      ggplot2::theme(plot.margin = ggplot2::margin(2, 6, 2, 6))
  }

  trend_ribbon <- NULL
  if (confidence) {
    z <- stats::qnorm((1 + level) / 2)
    s <- stats::sd(comps$remainder, na.rm = TRUE)
    trend_ribbon <- data.frame(lwr = comps$trend - z * s,
                               upr = comps$trend + z * s)
  }

  # One colour per component (observed/trend/seasonal/remainder) drawn from the
  # canonical qualitative palette, so the four panels stay colourblind-safe and
  # mutually distinct without ad-hoc hex literals.
  comp_cols <- depictr_palette(4)
  p <- patchwork::wrap_plots(
    panel(observed, "observed", comp_cols[1]),
    panel(comps$trend, "trend", comp_cols[2], ribbon = trend_ribbon),
    panel(comps$seasonal, "seasonal", comp_cols[3]),
    panel(comps$remainder, "remainder", comp_cols[4]),
    ncol = 1
  )
  if (!is.null(title)) {
    p <- p + patchwork::plot_annotation(
      title = title,
      theme = ggplot2::theme(plot.title = ggplot2::element_text(
        colour = depictr_brand(), face = "bold", hjust = 0.5))
    )
  }
  p
}

#' Forecast a seasonal series with STL plus seasonal-naive drift
#'
#' A lightweight, dependency-free forecaster for a single seasonal series. The
#' series is decomposed with [stats::stl()] into trend, seasonal and remainder.
#' The trend is extrapolated linearly from its last `frequency` fitted values
#' (the recent local slope), the seasonal pattern is carried forward by repeating
#' the last full cycle of the seasonal component (a seasonal-naive forecast), and
#' the point forecast is their sum.
#'
#' Prediction intervals are a random-walk-style normal band: the one-step
#' standard deviation is estimated from the STL remainder and the interval at
#' horizon `h` is `fit +/- z * sigma * sqrt(h)`, so the band necessarily widens
#' with the horizon. This mirrors how seasonal-naive forecast variance
#' accumulates over time and gives an honest, monotonically growing uncertainty
#' band without pulling in a heavy modelling dependency. For a fully specified
#' statistical model use, for example, `forecast::forecast()` and pass the
#' resulting fit/interval columns to [timeseries_plot()] directly.
#'
#' @param x A `ts` object, or a numeric vector (then `frequency` is required).
#' @param h Forecast horizon: the number of future steps (a positive integer).
#' @param frequency Number of observations per period; taken from `x` when it is
#'   a `ts`.
#' @param level Prediction-interval coverage (a single number strictly between 0
#'   and 1).
#'
#' @return A data frame with one row per forecast step and columns `time` (the
#'   future times, on the same scale as [stats::time()]), `fit`, `lwr` and
#'   `upr`.
#' @seealso [timeseries_plot()]
#' @export
#' @examples
#' fc <- ts_forecast(AirPassengers, h = 12)
#' head(fc)
#' # Interval width grows with the horizon
#' diff(fc$upr - fc$lwr) >= 0
ts_forecast <- function(x, h = 12, frequency = NULL, level = 0.95) {
  if (!stats::is.ts(x)) {
    if (is.null(frequency)) {
      stop("Supply `frequency` when `x` is not a ts object.", call. = FALSE)
    }
    x <- stats::ts(as.numeric(x), frequency = frequency)
  }
  if (!is.numeric(h) || length(h) != 1 || !is.finite(h) || h < 1 ||
      abs(h - round(h)) > .Machine$double.eps^0.5) {
    stop("`h` must be a single positive integer.", call. = FALSE)
  }
  h <- as.integer(round(h))
  if (!is.numeric(level) || length(level) != 1 || !is.finite(level) ||
      level <= 0 || level >= 1) {
    stop("`level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  }
  freq <- stats::frequency(x)
  if (freq < 2) {
    stop("`ts_forecast()` needs a seasonal series (frequency >= 2).",
         call. = FALSE)
  }
  n <- length(x)
  if (n < 2 * freq) {
    stop("Need at least two full cycles (", 2 * freq,
         " observations) to forecast.", call. = FALSE)
  }

  dec <- stats::stl(x, s.window = "periodic")$time.series
  trend <- as.numeric(dec[, "trend"])
  seasonal <- as.numeric(dec[, "seasonal"])
  remainder <- as.numeric(dec[, "remainder"])

  # Local linear extrapolation of the trend from its last full cycle.
  last_idx <- seq.int(n - freq + 1L, n)
  tr_fit <- stats::lm(y ~ t, data = data.frame(t = last_idx,
                                               y = trend[last_idx]))
  future_idx <- seq.int(n + 1L, n + h)
  trend_fc <- stats::predict(tr_fit,
                             newdata = data.frame(t = future_idx))

  # Seasonal-naive: repeat the seasonal component of the last full cycle. Index
  # by the season position (1..freq) so the right month/quarter is carried
  # forward regardless of where the ts starts within its cycle.
  cyc <- as.integer(stats::cycle(x))
  last_cycle_idx <- seq.int(n - freq + 1L, n)
  # Seasonal value keyed by season position.
  season_value <- stats::setNames(seasonal[last_cycle_idx],
                                  cyc[last_cycle_idx])
  last_pos <- cyc[n]
  season_pos <- ((last_pos - 1L + seq_len(h)) %% freq) + 1L
  seasonal_fc <- as.numeric(season_value[as.character(season_pos)])

  fit <- as.numeric(trend_fc) + seasonal_fc

  sigma <- stats::sd(remainder, na.rm = TRUE)
  z <- stats::qnorm((1 + level) / 2)
  half <- z * sigma * sqrt(seq_len(h))

  delta <- stats::deltat(x)
  last_time <- as.numeric(stats::time(x))[n]
  future_time <- last_time + delta * seq_len(h)

  data.frame(time = future_time, fit = fit, lwr = fit - half,
             upr = fit + half)
}

# ---- internal helpers ------------------------------------------------------

#' Resolve the `forecast` argument of `timeseries_plot()` to a tidy data frame
#'
#' Accepts either an integer horizon (dispatching to [ts_forecast()] on the
#' original `ts`/numeric input) or a pre-computed data frame with at least
#' `time` and `fit` columns. The data frame is prepended with the last observed
#' point so the overlaid forecast line joins the history without a gap.
#' @noRd
resolve_forecast <- function(forecast, x, df, frequency = NULL, level = 0.95) {
  if (is.data.frame(forecast)) {
    if (!all(c("time", "fit") %in% names(forecast))) {
      stop("A forecast data frame must have `time` and `fit` columns.",
           call. = FALSE)
    }
    fc <- forecast
    if (is.null(fc$lwr)) fc$lwr <- NA_real_
    if (is.null(fc$upr)) fc$upr <- NA_real_
    fc <- fc[, c("time", "fit", "lwr", "upr")]
  } else {
    if (is.data.frame(x)) {
      stop("An integer `forecast` horizon needs a ts or numeric `x`; ",
           "for a data frame supply a pre-computed forecast data frame.",
           call. = FALSE)
    }
    fc <- ts_forecast(x, h = forecast, frequency = frequency, level = level)
  }
  # Reconcile the forecast times with the historical axis. ts_forecast() (and a
  # forecast::forecast object) return decimal-year `time` values, but the
  # history may be plotted from a Date/POSIXct column. Plotting raw decimal
  # years on a Date axis would interpret them as days since the epoch, dropping
  # the forecast around 1976; convert them so the forecast continues from the
  # end of the history on one shared scale.
  fc$time <- reconcile_forecast_time(fc$time, df$time)
  # Anchor the forecast line at the last observed point for a continuous join.
  last_obs <- df[which.max(df$time), , drop = FALSE]
  anchor <- data.frame(time = last_obs$time, fit = last_obs$value,
                       lwr = last_obs$value, upr = last_obs$value)
  rbind(anchor, fc)
}

#' Reconcile forecast times with the class of the historical time axis
#'
#' The built-in forecaster returns decimal-year numbers (e.g. 2024.083). When
#' the history is plotted from a `Date` or `POSIXct` column, those numbers must
#' be coerced to the same class so the overlay lands on the historical axis
#' rather than being read as days/seconds since the epoch. Times that are
#' already on the right class (or where the history is plain numeric) are
#' returned unchanged.
#' @noRd
reconcile_forecast_time <- function(fc_time, hist_time) {
  if (inherits(hist_time, "Date") && !inherits(fc_time, "Date")) {
    return(decimal_year_to_date(as.numeric(fc_time)))
  }
  if (inherits(hist_time, "POSIXct") && !inherits(fc_time, "POSIXct")) {
    d <- decimal_year_to_date(as.numeric(fc_time))
    return(as.POSIXct(d, tz = attr(hist_time, "tzone") %||% ""))
  }
  fc_time
}

#' Convert decimal years (e.g. 2024.5) to calendar `Date`s
#'
#' Maps each value to a day within its year using the fractional part, handling
#' leap years by interpolating between successive 1 January boundaries.
#' @noRd
decimal_year_to_date <- function(t) {
  yr <- floor(t)
  frac <- t - yr
  start <- as.Date(paste0(yr, "-01-01"))
  end <- as.Date(paste0(yr + 1L, "-01-01"))
  start + round(frac * as.numeric(end - start))
}

#' Validate and coerce a rolling-window argument to a positive integer
#'
#' A non-integer window would make `rep(1 / window, window)` sum to less than
#' one and silently bias the moving average, so we require a whole number.
#' @noRd
validate_window <- function(window) {
  if (!is.numeric(window) || length(window) != 1 || !is.finite(window)) {
    stop("`rolling` must be a single positive integer.", call. = FALSE)
  }
  if (window < 1) stop("`rolling` must be a positive integer.", call. = FALSE)
  if (abs(window - round(window)) > .Machine$double.eps^0.5) {
    stop("`rolling` must be a whole number (got ", window, ").", call. = FALSE)
  }
  as.integer(round(window))
}

#' Centred moving average
#' @noRd
moving_average <- function(v, window) {
  window <- validate_window(window)
  as.numeric(stats::filter(v, rep(1 / window, window), sides = 2))
}
