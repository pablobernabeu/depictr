# Scatter plot with fitted trend ---------------------------------------------

#' Scatter plot with a fitted trend
#'
#' Plots `y` against `x` with an optional fitted trend line and confidence
#' band, optionally split by a grouping variable.
#'
#' @param data A data frame.
#' @param x,y The variables for the horizontal and vertical axes (string or
#'   unquoted column name).
#' @param group Optional grouping variable mapped to colour.
#' @param method Smoothing method passed to [ggplot2::geom_smooth()], e.g.
#'   `"lm"`, `"loess"`, or `NULL` for no trend line.
#' @param se Whether to draw the confidence band around the trend.
#' @param point_alpha Point transparency.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels (default to variable names).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' scatter_trend(crop_yield, fertilizer, yield)
#' scatter_trend(crop_yield, fertilizer, yield, group = treatment,
#'                    method = "lm")
scatter_trend <- function(data, x, y, group = NULL, method = "lm",
                               se = TRUE, point_alpha = 0.6, palette = NULL,
                               title = NULL, x_lab = NULL, y_lab = NULL) {
  x <- resolve_var(data, rlang::enquo(x), "x")
  y <- resolve_var(data, rlang::enquo(y), "y")
  group <- resolve_var(data, rlang::enquo(group), "group")
  x_lab <- x_lab %||% x
  y_lab <- y_lab %||% y

  mapping <- if (is.null(group)) {
    ggplot2::aes(x = .data[[x]], y = .data[[y]])
  } else {
    ggplot2::aes(x = .data[[x]], y = .data[[y]],
                 colour = .data[[group]], fill = .data[[group]])
  }

  p <- ggplot2::ggplot(data, mapping)
  if (is.null(group)) {
    p <- p + ggplot2::geom_point(alpha = point_alpha, na.rm = TRUE,
                                 colour = depictr_brand())
  } else {
    p <- p + ggplot2::geom_point(alpha = point_alpha, na.rm = TRUE)
  }

  if (!is.null(method)) {
    if (is.null(group)) {
      p <- p + ggplot2::geom_smooth(
        method = method, se = se, formula = y ~ x, na.rm = TRUE,
        colour = depictr_accent(), alpha = 0.18
      )
    } else {
      p <- p + ggplot2::geom_smooth(
        method = method, se = se, formula = y ~ x, na.rm = TRUE, alpha = 0.18
      )
    }
  }

  p <- p + ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()

  if (!is.null(group)) {
    if (is.null(palette)) {
      p <- p +
        scale_colour_depictr() +
        scale_fill_depictr()
    } else {
      p <- p +
        ggplot2::scale_colour_manual(values = palette) +
        ggplot2::scale_fill_manual(values = palette)
    }
  }
  p
}
