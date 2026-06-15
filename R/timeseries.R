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
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param point Whether to add points as well as the line.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' timeseries_plot(AirPassengers, rolling = 12,
#'                 title = "Air passengers", y_lab = "Passengers")
timeseries_plot <- function(x, time = NULL, value = NULL, group = NULL,
                            rolling = NULL, palette = NULL, point = FALSE,
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
      p <- p + ggplot2::geom_line(
        data = df, ggplot2::aes(x = .data$time, y = .data$roll,
                                colour = .data$series,
                                linetype = "Moving average"),
        linewidth = 1, na.rm = TRUE
      ) +
        ggplot2::scale_linetype_manual(values = c("Moving average" = "dashed"),
                                       name = NULL)
    } else {
      p <- p + ggplot2::geom_line(
        data = df, ggplot2::aes(x = .data$time, y = .data$roll),
        colour = depictr_accent(), linewidth = 0.9, na.rm = TRUE,
        inherit.aes = FALSE
      )
    }
  }

  if (multi) p <- p + ggplot2::scale_colour_manual(values = pal, name = NULL)
  p + ggplot2::labs(x = x_lab, y = y_lab, title = title) + theme_depictr()
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
#' @param title Plot title.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @export
#' @examples
#' decompose_plot(AirPassengers)
#' decompose_plot(AirPassengers, method = "classical")
decompose_plot <- function(x, frequency = NULL,
                           method = c("stl", "classical"), title = NULL) {
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
  tt <- as.numeric(stats::time(x))

  if (method == "stl") {
    dec <- stats::stl(x, s.window = "periodic")$time.series
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

  panel <- function(y, lab, colour) {
    ggplot2::ggplot(data.frame(t = tt, y = y),
                    ggplot2::aes(x = .data$t, y = .data$y)) +
      ggplot2::geom_line(colour = colour, linewidth = 0.6, na.rm = TRUE) +
      ggplot2::labs(x = NULL, y = lab) +
      theme_depictr(grid = "y") +
      ggplot2::theme(plot.margin = ggplot2::margin(2, 6, 2, 6))
  }

  # One colour per component (observed/trend/seasonal/remainder) drawn from the
  # canonical qualitative palette, so the four panels stay colourblind-safe and
  # mutually distinct without ad-hoc hex literals.
  comp_cols <- depictr_palette(4)
  p <- patchwork::wrap_plots(
    panel(observed, "observed", comp_cols[1]),
    panel(comps$trend, "trend", comp_cols[2]),
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

# ---- internal helpers ------------------------------------------------------

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
