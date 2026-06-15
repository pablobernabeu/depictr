# Empirical cumulative distribution plot -------------------------------------

#' Empirical cumulative distribution function (ECDF) plot
#'
#' Draws the empirical CDF of a numeric variable -- the proportion of
#' observations at or below each value -- optionally split by a grouping
#' variable. Unlike a histogram it needs no bin-width choice and makes
#' quantiles, medians and group shifts easy to read directly off the curve.
#'
#' @param data A data frame.
#' @param x The numeric variable (string or unquoted name).
#' @param group Optional grouping variable (string or unquoted name) mapped to
#'   colour, giving one ECDF per group.
#' @param reference_quantiles Optional numeric vector of probabilities in
#'   \[0, 1\] to mark with light horizontal guides (e.g. `c(0.25, 0.5, 0.75)`);
#'   `NULL` (the default) draws none.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Plot title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' ecdf_plot(lexical_decision, RT)
#' ecdf_plot(lexical_decision, RT, group = condition,
#'           reference_quantiles = c(0.25, 0.5, 0.75))
ecdf_plot <- function(data, x, group = NULL, reference_quantiles = NULL,
                      palette = NULL, title = NULL, x_lab = NULL,
                      y_lab = "Cumulative proportion") {
  x <- resolve_var(data, rlang::enquo(x), "x")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[x]])) stop("`x` must be numeric.", call. = FALSE)
  x_lab <- x_lab %||% x

  d <- data[stats::complete.cases(data[, c(x, group), drop = FALSE]), ,
            drop = FALSE]

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[x]]))

  if (!is.null(reference_quantiles)) {
    if (!is.numeric(reference_quantiles) ||
        any(reference_quantiles < 0 | reference_quantiles > 1)) {
      stop("`reference_quantiles` must be probabilities in [0, 1].",
           call. = FALSE)
    }
    p <- p + ggplot2::geom_hline(yintercept = reference_quantiles,
                                 linetype = 3, colour = depictr_reference())
  }

  if (is.null(group)) {
    p <- p + ggplot2::stat_ecdf(geom = "step", linewidth = 0.9,
                                colour = depictr_brand(), pad = FALSE)
  } else {
    p <- p +
      ggplot2::stat_ecdf(ggplot2::aes(colour = .data[[group]]),
                         geom = "step", linewidth = 0.9, pad = FALSE)
    p <- p + if (is.null(palette)) {
      scale_colour_depictr()
    } else {
      ggplot2::scale_colour_manual(values = palette)
    }
  }

  p +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                limits = c(0, 1)) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()
}
