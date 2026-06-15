# Seasonal-subseries (cycle) plot --------------------------------------------

#' Seasonal-subseries (cycle) plot
#'
#' Draws a seasonal-subseries plot (also called a cycle plot): the series is
#' split into one small panel per season (e.g. one panel per calendar month for
#' monthly data), and within each panel the value is drawn across successive
#' cycles (e.g. across years). A horizontal reference line in every panel marks
#' that season's mean. This makes the seasonal pattern (differences *between*
#' panels) and the within-season trend over time (the slope *inside* each panel)
#' visible at the same time, which a single overlaid line cannot show.
#'
#' Two layouts are offered. With `style = "subseries"` (the default) the panels
#' are faceted side by side, each tracing one season across cycles -- the
#' classic Cleveland cycle plot, matching `feasts::gg_subseries()`. With
#' `style = "season"` every cycle is drawn as its own line over the seasons on a
#' shared axis (the seasonal-plot layout of `forecast::ggseasonplot()`), which is
#' handy for spotting an unusual year.
#'
#' @param x A `ts` object, or a numeric vector (then `frequency` is required).
#' @param frequency Number of observations per period (e.g. 12 for monthly
#'   data); taken from `x` when it is a `ts`.
#' @param style `"subseries"` for the faceted cycle plot (one panel per season)
#'   or `"season"` for one line per cycle across the seasons.
#' @param season_labels Optional character vector of length `frequency` giving
#'   the season (panel/axis) labels, e.g. `month.abb`. When `NULL` (default)
#'   sensible labels are inferred (month abbreviations for frequency 12, quarter
#'   labels for frequency 4, otherwise the season index).
#' @param means Whether to draw the per-season mean reference line
#'   (`style = "subseries"` only).
#' @param point Whether to add points as well as the connecting line.
#' @param palette Colours used for the cycle lines when `style = "season"`;
#'   defaults to a sequential ramp from [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @seealso [decompose_plot()], [timeseries_plot()]
#' @export
#' @examples
#' # Monthly air passengers: rising within-month trend, summer peak
#' seasonal_plot(AirPassengers)
#' seasonal_plot(AirPassengers, style = "season")
seasonal_plot <- function(x, frequency = NULL,
                          style = c("subseries", "season"),
                          season_labels = NULL, means = TRUE, point = TRUE,
                          palette = NULL, title = NULL, x_lab = NULL,
                          y_lab = NULL) {
  style <- match.arg(style)
  df <- ts_seasonal_frame(x, frequency, season_labels)
  freq <- attr(df, "frequency")
  y_lab <- y_lab %||% "Value"

  if (style == "subseries") {
    x_lab <- x_lab %||% "Cycle"
    p <- ggplot2::ggplot(
      df, ggplot2::aes(x = .data$cycle, y = .data$value)
    ) +
      ggplot2::geom_line(colour = depictr_brand(), linewidth = 0.6,
                         na.rm = TRUE)
    if (point) {
      p <- p + ggplot2::geom_point(colour = depictr_brand(), size = 1,
                                   na.rm = TRUE)
    }
    if (means) {
      season_means <- stats::aggregate(value ~ season, data = df,
                                       FUN = mean, na.rm = TRUE)
      p <- p + ggplot2::geom_hline(
        data = season_means,
        ggplot2::aes(yintercept = .data$value),
        colour = depictr_accent(), linewidth = 0.7
      )
    }
    p <- p +
      ggplot2::facet_wrap(~ season, nrow = 1, strip.position = "bottom") +
      ggplot2::scale_x_continuous(breaks = scales_pretty_int) +
      ggplot2::labs(x = x_lab, y = y_lab, title = title) +
      theme_depictr(grid = "y") +
      ggplot2::theme(
        panel.spacing.x = ggplot2::unit(2, "pt"),
        strip.placement = "outside"
      )
    return(p)
  }

  # style == "season": one line per cycle across the seasons
  x_lab <- x_lab %||% "Season"
  cycles <- levels(df$cycle_f)
  pal <- palette %||% depictr_palette(length(cycles), type = "sequential")
  p <- ggplot2::ggplot(
    df, ggplot2::aes(x = .data$season_idx, y = .data$value,
                     colour = .data$cycle_f, group = .data$cycle_f)
  ) +
    ggplot2::geom_line(linewidth = 0.6, na.rm = TRUE)
  if (point) p <- p + ggplot2::geom_point(size = 1, na.rm = TRUE)
  p +
    ggplot2::scale_x_continuous(
      breaks = seq_len(freq), labels = attr(df, "season_labels")
    ) +
    # The cycles use a sequential (light-to-dark) ramp, so reverse the legend:
    # the darkest/most-recent cycle then sits at the top of the key, matching
    # how the later cycles usually sit highest in the plot.
    ggplot2::scale_colour_manual(
      values = pal, name = NULL,
      guide = ggplot2::guide_legend(reverse = TRUE)
    ) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr(grid = "y")
}

# ---- internal helpers ------------------------------------------------------

#' Build a tidy season/cycle data frame from a ts-like input
#'
#' Returns one row per observation with columns `value`, `season` (factor with
#' `frequency` ordered levels), `season_idx` (1..frequency), `cycle` (numeric
#' cycle number, 1-based) and `cycle_f` (cycle as an ordered factor). Attributes
#' `frequency` and `season_labels` are attached.
#' @noRd
ts_seasonal_frame <- function(x, frequency = NULL, season_labels = NULL) {
  if (!stats::is.ts(x)) {
    if (is.null(frequency)) {
      stop("Supply `frequency` when `x` is not a ts object.", call. = FALSE)
    }
    x <- stats::ts(as.numeric(x), frequency = frequency)
  }
  freq <- stats::frequency(x)
  if (freq < 2) {
    stop("A seasonal plot needs a seasonal series (frequency >= 2).",
         call. = FALSE)
  }

  value <- as.numeric(x)
  n <- length(value)
  # cycle() gives the season position (1..freq) for each observation
  season_idx <- as.integer(stats::cycle(x))
  # 1-based cycle number: increments each time we wrap past the season period
  cycle_num <- cumsum(c(1L, as.integer(diff(season_idx) < 0)))

  labs <- season_labels %||% default_season_labels(freq)
  if (length(labs) != freq) {
    stop("`season_labels` must have length equal to the frequency (", freq,
         ").", call. = FALSE)
  }

  df <- data.frame(
    value = value,
    season_idx = season_idx,
    season = factor(labs[season_idx], levels = labs),
    cycle = cycle_num,
    cycle_f = factor(cycle_num, levels = sort(unique(cycle_num)), ordered = TRUE),
    stringsAsFactors = FALSE
  )
  attr(df, "frequency") <- freq
  attr(df, "season_labels") <- labs
  df
}

#' Default season labels for a given frequency
#' @noRd
default_season_labels <- function(freq) {
  if (freq == 12) return(month.abb)
  if (freq == 4) return(paste0("Q", 1:4))
  if (freq == 7) return(c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"))
  as.character(seq_len(freq))
}

#' Pretty integer breaks for a subseries x axis
#' @noRd
scales_pretty_int <- function(limits) {
  br <- pretty(limits)
  br[br == round(br) & br >= 1]
}
