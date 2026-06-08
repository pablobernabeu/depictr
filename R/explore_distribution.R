# Distribution plot ----------------------------------------------------------

#' Plot the distribution of a variable
#'
#' Draws a histogram, a density curve, or both, optionally split by a grouping
#' variable. A quick first look at a continuous variable.
#'
#' @param data A data frame.
#' @param x The continuous variable to display. Either a string or an unquoted
#'   column name.
#' @param group Optional grouping variable (string or unquoted name) mapped to
#'   colour/fill.
#' @param type One of `"histogram"`, `"density"` or `"both"`.
#' @param bins Number of histogram bins.
#' @param alpha Fill transparency (useful when groups overlap).
#' @param position Histogram position adjustment, e.g. `"identity"`,
#'   `"stack"` or `"dodge"`.
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title,x_lab Plot title and x-axis label (defaults to the variable
#'   name).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' explore_distribution(lexical_decision, RT)
#' explore_distribution(lexical_decision, RT, group = condition, type = "density")
explore_distribution <- function(data, x, group = NULL,
                              type = c("histogram", "density", "both"),
                              bins = 30, alpha = 0.6, position = "identity",
                              palette = NULL, title = NULL, x_lab = NULL) {
  type <- match.arg(type)
  x <- resolve_var(data, rlang::enquo(x), "x")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[x]])) {
    stop("`x` must be a numeric variable.", call. = FALSE)
  }
  x_lab <- x_lab %||% x

  aes_main <- if (is.null(group)) {
    ggplot2::aes(x = .data[[x]])
  } else {
    ggplot2::aes(x = .data[[x]], fill = .data[[group]], colour = .data[[group]])
  }
  p <- ggplot2::ggplot(data, aes_main)

  if (type %in% c("histogram", "both")) {
    p <- p + ggplot2::geom_histogram(
      ggplot2::aes(y = if (type == "both") ggplot2::after_stat(.data$density) else
        ggplot2::after_stat(.data$count)),
      bins = bins, alpha = alpha, position = position,
      colour = if (is.null(group)) "white" else NA
    )
  }
  if (type %in% c("density", "both")) {
    dens_alpha <- if (type == "both") 0 else alpha
    p <- p + ggplot2::geom_density(alpha = dens_alpha, linewidth = 0.8)
  }

  y_lab <- if (type == "histogram") "Count" else "Density"
  p <- p + ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_statviz()

  if (!is.null(group)) {
    pal <- palette %||% statviz_palette(length(unique(data[[group]])))
    p <- p +
      ggplot2::scale_fill_manual(values = pal) +
      ggplot2::scale_colour_manual(values = pal)
  }
  p
}
