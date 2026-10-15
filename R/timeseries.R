# Time-series plots ----------------------------------------------------------

#' Time-series plot
#'
#' Plots one or more series over time, with an optional moving-average overlay.
#' The input can be a `ts` object, a numeric vector or matrix, or a data frame
#' with a time column, a value column and an optional grouping column. A
#' multivariate `ts`, such as `cbind(mdeaths, fdeaths)`, or a matrix with
#' several columns gives one series per column, named after its column.
#'
#' @param x A `ts` object, a numeric vector or matrix, or a data frame.
#' @param time When `x` is a data frame, the time column (string or unquoted
#'   name). When `x` is a numeric vector or matrix, an optional vector of times,
#'   one per value or per row.
#' @param value When `x` is a data frame, the value column.
#' @param group When `x` is a data frame, an optional grouping column mapped to
#'   colour. A factor keeps the order of its levels in the legend and the
#'   palette, and levels no row uses are left out. Other columns are ordered by
#'   first appearance.
#' @param rolling Optional integer window for a centred moving-average overlay.
#'   The data are ordered by time (within each group) before the moving average
#'   is computed, so unsorted input is handled correctly. An odd window averages
#'   each observation with the same number of neighbours on either side. An
#'   even window, such as 12 for monthly data, gives the 2×12 moving average, a
#'   12-point average followed by a 2-point one (Hyndman & Athanasopoulos,
#'   2021, Section 3.3). The two observations at the ends of the 13 it spans
#'   count half, which centres the average on its observation, as equal weights
#'   over an even window cannot. It needs a series one observation longer than
#'   the window.
#' @param forecast Optional forecast overlay for a single (non-grouped) series.
#'   Either an integer horizon (number of future steps) to forecast with the
#'   built-in STL plus random walk with drift (see [ts_forecast()]), or a
#'   pre-computed forecast supplied as a data frame with columns `time`, `fit`
#'   and (optionally) `lwr`/`upr`, for instance from a fitted
#'   `forecast::forecast()` object. The point forecast continues the line and a
#'   shaded prediction-interval ribbon is drawn behind it. The built-in
#'   forecast is captioned with its coverage and method, and its band widens
#'   with the horizon on the scale it is made on (see `lambda`). For a numeric
#'   `x`, it is made from the values in time order and continues the history's
#'   own time axis, one typical step at a time. Missing values at either end of
#'   the series are trimmed before forecasting, so the forecast starts from the
#'   last observation, and a missing value inside the series is an error.
#' @param frequency Number of observations per period, used only to coerce a
#'   numeric `x` to a `ts` when an integer `forecast` horizon is requested.
#' @param level Prediction-interval coverage for the built-in forecast (a single
#'   number strictly between 0 and 1, e.g. `0.95`).
#' @param lambda Optional Box-Cox transformation for the built-in forecast,
#'   passed to [ts_forecast()]. `0` forecasts on the log scale, which suits a
#'   series whose seasonal swing grows with its level.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param point Whether to add points as well as the line.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @references
#' \insertRef{hyndman2021}{depictr}
#' @seealso [ts_forecast()], [decompose_plot()], [seasonal_plot()]
#' @export
#' @examples
#' timeseries_plot(AirPassengers, rolling = 12,
#'                 title = "Air passengers", y_lab = "Passengers")
#' # One line per column of a multivariate ts
#' timeseries_plot(cbind(mdeaths, fdeaths), y_lab = "Deaths")
#' # 24-month forecast with a 90% prediction interval, made on the log scale
#' # because the seasonal swing grows with the number of passengers
#' timeseries_plot(AirPassengers, forecast = 24, level = 0.9, lambda = 0)
timeseries_plot <- function(x, time = NULL, value = NULL, group = NULL,
                            rolling = NULL, forecast = NULL, frequency = NULL,
                            level = 0.95, lambda = NULL, palette = NULL,
                            point = FALSE, title = NULL, x_lab = NULL,
                            y_lab = NULL) {
  if (is.data.frame(x)) {
    tcol <- resolve_var(x, rlang::enquo(time), "time")
    vcol <- resolve_var(x, rlang::enquo(value), "value")
    gcol <- resolve_var(x, rlang::enquo(group), "group")
    if (is.null(tcol) || is.null(vcol)) {
      stop("For a data frame, supply `time` and `value` columns.",
           call. = FALSE)
    }
    df <- data.frame(time = x[[tcol]], value = x[[vcol]])
    df$series <- if (is.null(gcol)) "series" else x[[gcol]]
    x_lab <- x_lab %||% tcol
    y_lab <- y_lab %||% vcol
  } else if (NCOL(x) > 1) {
    # One series per column. as.numeric() would lay the columns end to end and
    # draw them as one series.
    df <- series_by_column(x, time)
    x_lab <- x_lab %||% "Time"
  } else if (stats::is.ts(x)) {
    df <- data.frame(time = as.numeric(stats::time(x)),
                     value = as.numeric(x), series = "series")
    x_lab <- x_lab %||% "Time"
  } else {
    if (!is.numeric(x)) {
      stop("`x` must be a ts, a numeric vector or matrix, or a data frame.",
           call. = FALSE)
    }
    tv <- if (!is.null(time)) time else seq_along(x)
    df <- data.frame(time = tv, value = as.numeric(x), series = "series")
    x_lab <- x_lab %||% "Time"
  }
  y_lab <- y_lab %||% "Value"
  # A factor keeps the order of its levels, which sets the legend and the
  # colours, without the levels no row uses. Anything else is ordered by first
  # appearance.
  sv <- df$series
  lev <- if (is.factor(sv)) {
    levels(droplevels(sv))
  } else {
    unique(as.character(sv))
  }
  df$series <- factor(as.character(sv), levels = lev)
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
    # An even window is the 2 x m average, which spans one observation more
    # than the window (see moving_average()).
    if (rolling %% 2 == 0 && rolling + 1 > min_len) {
      stop("An even `rolling` window spans one observation more than its ",
           "length, so `rolling` (", rolling, ") needs ", rolling + 1,
           " observations, and the shortest series has ", min_len,
           "; choose a smaller window.", call. = FALSE)
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
      # An even window is named as the 2 x m average it draws, the name
      # Hyndman and Athanasopoulos (2021, Section 3.3) give it.
      window_name <- if (rolling %% 2 == 0) {
        paste0("2\u00d7", rolling)
      } else {
        paste0(rolling, "-point")
      }
      caption <- paste0("Dashed line: ", window_name,
                        " centred moving average")
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
                           level = level, lambda = lambda)
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
    # A reader cannot tell from the ribbon alone what it covers or how it was
    # made. A forecast the caller computed is theirs to describe.
    if (!is.data.frame(forecast)) caption <- forecast_caption(level, lambda)
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
#' @param x A numeric vector or `ts` object holding one series. A multivariate
#'   `ts` or a matrix with several columns is refused.
#' @param lag_max Maximum lag (passed to [stats::acf()] / [stats::pacf()]).
#' @param type `"correlation"` for the ACF or `"partial"` for the PACF.
#' @param conf_level Confidence level for the significance bounds; a single
#'   number strictly between 0 and 1.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @details
#' A missing value inside the series is kept in its place, and the
#' correlations are computed from the pairs of observations that are both
#' present (`na.action = na.pass`), with a warning. Dropping it would join the
#' observations on either side of the gap as if they were neighbours. The
#' Python package refuses such a series and asks for the gap to be dropped or
#' imputed first.
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
  check_conf_level(conf_level)
  x <- as_one_series(x)
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
#' @param x A `ts` object, or a numeric vector (then `frequency` is required),
#'   holding one series. A multivariate `ts` or a matrix with several columns
#'   is refused. Missing values at either end are trimmed, and a missing value
#'   inside the series is an error.
#' @param frequency Number of observations per period (e.g. 12 for monthly
#'   data); taken from `x` when it is a `ts`.
#' @param method `"stl"` (loess-based, Cleveland et al., 1990) or
#'   `"classical"` ([stats::decompose()]). STL needs more than two full cycles
#'   of data, and classical decomposition at least two.
#' @param robust For `method = "stl"`, whether to fit a robust STL
#'   ([stats::stl()] with `robust = TRUE`), which down-weights outliers in the
#'   loess fits so that an unusual point bleeds less into the trend and seasonal
#'   components. Ignored for the classical method.
#' @param s_window For `method = "stl"`, the seasonal window, passed to
#'   [stats::stl()] as `s.window`. The default, `"periodic"`, estimates one
#'   seasonal value per position in the cycle and repeats it in every cycle, as
#'   classical decomposition does. An odd whole number of at least 7 lets the
#'   seasonal component change from cycle to cycle. It is the number of
#'   consecutive cycles that go into each seasonal value, so a smaller window
#'   lets the pattern change faster. Ignored for the classical method.
#' @param confidence Whether to draw a confidence ribbon around the trend
#'   component. The band is a normal-approximation interval based on the
#'   remainder's standard deviation (see Details).
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
#' @references
#' \insertRef{cleveland1990}{depictr}
#' @seealso [ts_forecast()], [seasonal_plot()]
#' @export
#' @examples
#' decompose_plot(AirPassengers)
#' \donttest{
#' decompose_plot(AirPassengers, method = "classical")
#' # Robust STL with a confidence ribbon on the trend
#' decompose_plot(AirPassengers, robust = TRUE, confidence = TRUE)
#' # A seasonal component free to grow with the level of the series
#' decompose_plot(AirPassengers, s_window = 13)
#' }
decompose_plot <- function(x, frequency = NULL,
                           method = c("stl", "classical"), robust = FALSE,
                           s_window = "periodic", confidence = FALSE,
                           level = 0.95, title = NULL) {
  method <- match.arg(method)
  s_window <- validate_s_window(s_window)
  x <- as_one_series(x)
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
  x <- trim_missing_ends(x, "plotting")
  tt <- as.numeric(stats::time(x))

  if (method == "stl") {
    check_stl_length(length(x), stats::frequency(x),
                     "for an STL decomposition")
    dec <- stats::stl(x, s.window = s_window, robust = robust)$time.series
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

#' Forecast a seasonal series with STL and a random walk with drift
#'
#' A dependency-free forecaster for a single seasonal series, which forecasts
#' by decomposition (Hyndman & Athanasopoulos, 2021, Section 5.7).
#' [stats::stl()] with `s.window = "periodic"` estimates a seasonal component
#' that repeats unchanged in every cycle (Cleveland et al., 1990). The
#' seasonally adjusted series, the data minus that component, is forecast with a
#' random walk with drift, and the last cycle of the seasonal component is added
#' back. The result reproduces
#' `forecast::stlf(x, method = "rwdrift", s.window = "periodic")`.
#'
#' The prediction interval at horizon `h` is `fit +/- z * sigma_h`, with
#' `z = qnorm((1 + level) / 2)`. The forecast standard deviation is that of a
#' random walk with drift, `sigma_h = sigma * sqrt(h * (1 + h / (T - 1)))`
#' (Hyndman & Athanasopoulos, 2021, Section 5.5), where `sigma` is the standard
#' deviation of the steps of the seasonally adjusted series and `T` the length
#' of the series. The band widens with the horizon, and the second term carries
#' the uncertainty in the estimated drift.
#'
#' The model assumes a seasonal pattern that adds to the level of the series
#' and stays the same from cycle to cycle. When the seasonal swing grows with
#' the level, as in `AirPassengers`, forecast on the log scale with
#' `lambda = 0`. The band treats the seasonal component as known, so it leaves
#' out the uncertainty in estimating it. In a rolling-origin backtest on five
#' classic series whose seasonal swing does not grow with their level, the
#' nominal 95% band covered 92% of one-step-ahead outcomes
#' (`dev/ts_forecast_backtest.R` in the source repository). From three to 12
#' steps ahead, it covered 99%. The band therefore runs somewhat narrow at the
#' shortest horizons and wide further out, where the uncertainty of a random
#' walk keeps growing while these series stay close to their trend. For a
#' different model, fit it with, for example, `forecast::forecast()` and pass
#' its columns to [timeseries_plot()] as a data frame.
#'
#' @param x A `ts` object, or a numeric vector (then `frequency` is required),
#'   holding one series. It needs more than two full cycles of observations.
#'   Missing values at either end are trimmed, so the forecast starts after the
#'   last observation, and a missing value inside the series is an error. A
#'   multivariate `ts` or a matrix with several columns is refused.
#' @param h Forecast horizon: the number of future steps (a positive integer).
#' @param frequency Number of observations per period; taken from `x` when it is
#'   a `ts`.
#' @param level Prediction-interval coverage (a single number strictly between 0
#'   and 1).
#' @param lambda Optional Box-Cox transformation parameter. `NULL`, the default,
#'   forecasts the series as it is. `0` forecasts its logarithm, and any other
#'   number forecasts `(x^lambda - 1) / lambda`. Every observation must then be
#'   positive. The forecasts and limits are transformed back to the original
#'   scale, where the point forecast is the median of the forecast
#'   distribution, without the bias adjustment that would make it the mean
#'   (Hyndman & Athanasopoulos, 2021, Section 5.6). A forecast or limit beyond
#'   the range the transformation can reach comes back as `0` (for a positive
#'   `lambda`) or `Inf` (for a negative one).
#'
#' @return A data frame with one row per forecast step and columns `time` (the
#'   future times, on the same scale as [stats::time()]), `fit`, `lwr` and
#'   `upr`.
#' @references
#' \insertRef{cleveland1990}{depictr}
#'
#' \insertRef{hyndman2021}{depictr}
#' @seealso [timeseries_plot()], [decompose_plot()]
#' @export
#' @examples
#' # The seasonal swing of AirPassengers grows with the number of passengers,
#' # so it is forecast on the log scale.
#' fc <- ts_forecast(AirPassengers, h = 12, lambda = 0)
#' head(fc)
#' # On that scale, the band widens with the horizon
#' diff(log(fc$upr) - log(fc$lwr)) > 0
ts_forecast <- function(x, h = 12, frequency = NULL, level = 0.95,
                        lambda = NULL) {
  x <- as_one_series(x)
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
  if (!is.null(lambda) &&
      (!is.numeric(lambda) || length(lambda) != 1 || !is.finite(lambda))) {
    stop("`lambda` must be NULL or a single finite number.", call. = FALSE)
  }
  freq <- stats::frequency(x)
  if (freq < 2) {
    stop("`ts_forecast()` needs a seasonal series (frequency >= 2).",
         call. = FALSE)
  }
  # The trimmed series keeps its times, so the forecast starts after the last
  # observation.
  x <- trim_missing_ends(x, "forecasting")
  n <- length(x)
  check_stl_length(n, freq, "to forecast")

  y <- as.numeric(x)
  if (!is.null(lambda)) {
    if (any(y <= 0, na.rm = TRUE)) {
      stop("A Box-Cox `lambda` needs every observation to be positive.",
           call. = FALSE)
    }
    y <- box_cox(y, lambda)
  }
  # The transformed values keep the series' place in the cycle, which the
  # periodic STL uses to pool each season's values.
  y_ts <- stats::ts(y, start = stats::start(x), frequency = freq)
  seasonal <- as.numeric(
    stats::stl(y_ts, s.window = "periodic")$time.series[, "seasonal"]
  )
  sa <- y - seasonal

  # Random walk with drift on the seasonally adjusted series. The drift is the
  # mean step and sigma the standard deviation of the steps, which equals the
  # residual standard error of the drift model.
  steps <- diff(sa)
  drift <- mean(steps)
  sigma <- stats::sd(steps)
  hh <- seq_len(h)
  # The periodic seasonal component repeats every cycle, so its last cycle
  # holds one value per season, carried forward in step with the forecast.
  seasonal_fc <- seasonal[n - freq + ((hh - 1L) %% freq) + 1L]
  fit <- sa[n] + hh * drift + seasonal_fc
  # The h-step variance h * sigma^2 of the walk, plus h^2 times the variance
  # sigma^2 / (n - 1) of the estimated drift.
  se <- sigma * sqrt(hh * (1 + hh / (n - 1)))
  z <- stats::qnorm((1 + level) / 2)
  lwr <- fit - z * se
  upr <- fit + z * se
  if (!is.null(lambda)) {
    fit <- inv_box_cox(fit, lambda)
    lwr <- inv_box_cox(lwr, lambda)
    upr <- inv_box_cox(upr, lambda)
  }

  delta <- stats::deltat(x)
  last_time <- as.numeric(stats::time(x))[n]
  data.frame(time = last_time + delta * hh, fit = fit, lwr = lwr, upr = upr)
}

# ---- internal helpers ------------------------------------------------------

#' Resolve the `forecast` argument of `timeseries_plot()` to a tidy data frame
#'
#' Accepts either an integer horizon (dispatching to [ts_forecast()] on the
#' `ts`, or on a numeric input's values in time order) or a pre-computed data
#' frame with at least `time` and `fit` columns. The data frame is prepended
#' with the last observed point so the overlaid forecast line joins the history
#' without a gap. Missing values at the end of the history are passed over, as
#' ts_forecast() trims them.
#' @noRd
resolve_forecast <- function(forecast, x, df, frequency = NULL, level = 0.95,
                             lambda = NULL) {
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
    # A numeric `x` is forecast from `df$value`, its values in time order, so
    # that an unsorted `time` extends the series as drawn.
    y <- if (stats::is.ts(x)) x else df$value
    fc <- ts_forecast(y, h = forecast, frequency = frequency, level = level,
                      lambda = lambda)
    if (!stats::is.ts(x)) {
      # A numeric `x` is wrapped in a ts that starts at time 1, so
      # ts_forecast() returns times in cycle units the history knows nothing
      # about. The history sits at seq_along(x) or at the caller's `time`, so
      # the forecast continues that axis, one typical spacing per step, from
      # the last observation.
      fc$time <- forecast_steps(df$time[!is.na(df$value)], nrow(fc))
    }
  }
  # Reconcile the forecast times with the historical axis. ts_forecast() (and a
  # forecast::forecast object) return decimal-year `time` values, but the
  # history may be plotted from a Date/POSIXct column. Plotting raw decimal
  # years on a Date axis would interpret them as days since the epoch, dropping
  # the forecast around 1976; convert them so the forecast continues from the
  # end of the history on one shared scale.
  fc$time <- reconcile_forecast_time(fc$time, df$time)
  # Anchor the forecast line at the last observed point for a continuous join.
  # An anchor at a missing value would break the forecast line instead.
  observed <- df[!is.na(df$value), , drop = FALSE]
  last_obs <- observed[which.max(observed$time), , drop = FALSE]
  anchor <- data.frame(time = last_obs$time, fit = last_obs$value,
                       lwr = last_obs$value, upr = last_obs$value)
  rbind(anchor, fc)
}

#' The next `h` times on the history's own axis
#'
#' Steps on from the last observed time by the median spacing of the history,
#' or by one unit for a single observation. The result keeps the class of
#' `hist_time`, so a `Date` axis gains days and a `POSIXct` one seconds.
#' @noRd
forecast_steps <- function(hist_time, h) {
  hist_time <- sort(hist_time)
  n <- length(hist_time)
  step <- if (n > 1) stats::median(diff(as.numeric(hist_time))) else 1
  hist_time[n] + step * seq_len(h)
}

#' Caption naming the coverage and method of the built-in forecast's ribbon
#' @noRd
forecast_caption <- function(level, lambda = NULL) {
  method <- "STL + random walk with drift"
  if (!is.null(lambda)) {
    method <- if (lambda == 0) {
      paste(method, "on the log scale")
    } else {
      sprintf("%s, Box-Cox lambda = %g", method, lambda)
    }
  }
  sprintf("Shaded: %g%% prediction interval (%s).", 100 * level, method)
}

#' Refuse a series too short for stats::stl()
#'
#' stl() stops on `n <= 2 * frequency` with "series is not periodic or has less
#' than two periods", which reads as a complaint about the frequency.
#' @noRd
check_stl_length <- function(n, freq, purpose) {
  if (n <= 2 * freq) {
    stop("Need more than two full cycles (at least ", floor(2 * freq) + 1,
         " observations) ", purpose, ".", call. = FALSE)
  }
  invisible(n)
}

#' Refuse a series with several columns, and read one column as the series
#'
#' A multivariate ts or a matrix holds one series per column. as.numeric()
#' would lay the columns end to end, so a single-series function would read
#' them as one series, or recycle the times and seasons of one column over
#' all of them. The Python twin refuses a frame or 2-D array with several
#' columns in the same words. A ts with one column, as ts() makes from a
#' one-column data frame, is returned as that column, since stl() refuses
#' anything with columns as multivariate. The Python twin reads a single
#' column the same way.
#' @noRd
as_one_series <- function(x) {
  k <- NCOL(x)
  if (k > 1) {
    stop("`x` has ", k, " columns; pass one series at a time.", call. = FALSE)
  }
  # The column of a ts keeps its times.
  if (k == 1 && is.matrix(x)) x <- x[, 1]
  x
}

#' Trim missing values from the ends of a ts and refuse interior ones
#'
#' Missing values at either end only shorten the series, so they are trimmed
#' with stats::window(), which keeps the times and the place in the cycle. A
#' missing value inside the series would stop stl() or decompose() with an
#' error of its own. Dropping it would move every later observation to the
#' wrong place in the cycle, so it is refused, in the Python twin's words.
#' @noRd
trim_missing_ends <- function(x, purpose) {
  obs <- which(!is.na(x))
  if (length(obs) == 0) {
    stop("`x` has no non-missing values.", call. = FALSE)
  }
  first <- obs[1]
  last <- obs[length(obs)]
  if (first > 1 || last < length(x)) {
    tt <- stats::time(x)
    x <- stats::window(x, start = if (first > 1) tt[first],
                       end = if (last < length(x)) tt[last])
  }
  if (anyNA(x)) {
    stop("`x` must not contain internal missing values; drop or impute ",
         "them before ", purpose, ".", call. = FALSE)
  }
  x
}

#' One series per column of a multivariate ts or a numeric matrix, in long form
#'
#' Each column is named after its column name, and an unnamed one
#' "Series <i>", as stats::ts() names it. A ts carries its own times. A matrix
#' takes `time`, one entry per row, or else the row number.
#' @noRd
series_by_column <- function(x, time = NULL) {
  if (!is.numeric(x)) {
    stop("`x` must be a ts, a numeric vector or matrix, or a data frame.",
         call. = FALSE)
  }
  n <- NROW(x)
  k <- NCOL(x)
  nm <- colnames(x) %||% rep("", k)
  unnamed <- is.na(nm) | nm == ""
  nm[unnamed] <- paste("Series", which(unnamed))
  nm <- make.unique(nm)
  tv <- if (stats::is.ts(x)) {
    as.numeric(stats::time(x))
  } else if (!is.null(time)) {
    if (length(time) != n) {
      stop("`time` must have one entry per row of `x` (", n, ").",
           call. = FALSE)
    }
    time
  } else {
    seq_len(n)
  }
  data.frame(time = rep(tv, k), value = as.numeric(x),
             series = factor(rep(nm, each = n), levels = nm))
}

#' Validate the STL seasonal window
#'
#' stl() rounds the window to a whole number and raises an even one to the next
#' odd number, and its documentation, following Cleveland et al. (1990), asks
#' for at least 7. Such windows are refused here, since stl() would change them
#' without a word. An abbreviation of "periodic" is accepted, as stl() accepts
#' it.
#' @noRd
validate_s_window <- function(s_window) {
  if (is.character(s_window) && length(s_window) == 1 &&
      !is.na(pmatch(s_window, "periodic"))) {
    return("periodic")
  }
  if (!is.numeric(s_window) || length(s_window) != 1 ||
      !is.finite(s_window) || s_window < 7 || s_window %% 2 != 1) {
    stop("`s_window` must be \"periodic\" or an odd whole number of at ",
         "least 7.", call. = FALSE)
  }
  s_window
}

#' Box-Cox transformation of positive values, and its inverse
#'
#' The inverse maps a value beyond the range the transformation can reach to
#' the edge of the positive half-line it stands for. That edge is 0 for a
#' positive `lambda`, whose transformation nears `-1 / lambda` as values fall
#' towards 0, and `Inf` for a negative one, whose transformation nears it as
#' values grow.
#' @noRd
box_cox <- function(y, lambda) {
  if (lambda == 0) log(y) else (y^lambda - 1) / lambda
}

# The inverse of box_cox(), described above.
inv_box_cox <- function(z, lambda) {
  if (lambda == 0) return(exp(z))
  base <- lambda * z + 1
  out <- base^(1 / lambda)
  out[which(base <= 0)] <- if (lambda > 0) 0 else Inf
  out
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
#'
#' Equal weights over an odd window centre the average on an observation.
#' Over an even window they centre it between two observations:
#' stats::filter(sides = 2) with four equal weights puts the mean of
#' observations 1 to 4 at observation 2. An even window m therefore gives the
#' 2 x m average, an m-point average followed by a 2-point one (Hyndman &
#' Athanasopoulos, 2021, Section 3.3). Its weights,
#' c(0.5, rep(1, m - 1), 0.5) / m, span m + 1 observations. It is the trend
#' that stats::decompose() estimates for a frequency of m, and the Python twin
#' computes the same weights. A window that runs off either end of the series,
#' or reaches a missing value, gives NA.
#' @noRd
moving_average <- function(v, window) {
  window <- validate_window(window)
  weights <- if (window %% 2 == 0) {
    c(0.5, rep(1, window - 1), 0.5) / window
  } else {
    rep(1 / window, window)
  }
  as.numeric(stats::filter(v, weights, sides = 2))
}
