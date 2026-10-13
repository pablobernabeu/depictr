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
#'   colour/fill. A numeric code counts as a group, but a numeric column with
#'   more than 20 distinct values is refused as continuous. Rows with a missing
#'   group are dropped with a message, and levels without rows are left out of
#'   the plot and its palette.
#' @param type One of `"histogram"`, `"density"` or `"both"`.
#' @param bins Number of histogram bins.
#' @param alpha Fill transparency (useful when groups overlap).
#' @param position Histogram position adjustment, e.g. `"identity"`,
#'   `"stack"` or `"dodge"`. The default (`NULL`) chooses `"dodge"` when
#'   `group` is set (so overlapping bars stay readable) and `"identity"`
#'   otherwise.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param facet When a `group` is given, draw one panel per group instead of
#'   overlaying them. This is much clearer than an overlay once there are more
#'   than two or three groups (overlaid histograms in particular become hard to
#'   read). Defaults to `FALSE`. Ignored when there is no `group`.
#' @param legend_inside When `TRUE` (and a `group` is given without `facet`),
#'   draw the colour legend inside the panel (in the top-right corner a
#'   unimodal histogram/density leaves empty) over a translucent background,
#'   instead of in a right-hand margin. Defaults to `FALSE`.
#' @param title,x_lab Plot title and x-axis label (defaults to the variable
#'   name).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' explore_distribution(lexical_decision, RT)
#' explore_distribution(lexical_decision, RT, group = condition, type = "density")
#' # One panel per group keeps many groups legible:
#' explore_distribution(wellbeing_survey, life_satisfaction, group = region,
#'                      type = "both", facet = TRUE)
explore_distribution <- function(data, x, group = NULL,
                              type = c("histogram", "density", "both"),
                              bins = 30, alpha = 0.6, position = NULL,
                              palette = NULL, facet = FALSE,
                              legend_inside = FALSE,
                              title = NULL, x_lab = NULL) {
  type <- match.arg(type)
  x <- resolve_var(data, rlang::enquo(x), "x")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[x]])) {
    stop("`x` must be a numeric variable.", call. = FALSE)
  }
  x_lab <- x_lab %||% x

  # Default position: dodge keeps grouped bars readable; identity for ungrouped.
  position <- position %||% (if (is.null(group)) "identity" else "dodge")

  # Drop rows with a missing x so ggplot2 does not emit a "Removed N rows"
  # warning at draw time. Rows with a missing group go next, with a message.
  data <- data[!is.na(data[[x]]), , drop = FALSE]
  prep <- prepare_group(data, group, palette)
  data <- prep$data
  palette <- prep$palette

  aes_main <- if (is.null(group)) {
    ggplot2::aes(x = .data[[x]])
  } else {
    ggplot2::aes(x = .data[[x]], fill = .data[[group]], colour = .data[[group]])
  }
  p <- ggplot2::ggplot(data, aes_main)

  if (type %in% c("histogram", "both")) {
    p <- p + ggplot2::geom_histogram(
      ggplot2::aes(y = if (type == "both") ggplot2::after_stat(density) else
        ggplot2::after_stat(count)),
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
    theme_depictr()

  if (!is.null(group)) {
    p <- p + ggplot2::scale_fill_manual(values = palette)
    # Grouped histogram bars have no outline, so only a density draws in the
    # colour scale. Without one, a scale named by level would find no level
    # to colour and warn.
    if (type != "histogram") {
      p <- p + ggplot2::scale_colour_manual(values = palette)
    }
    # One panel per group declutters the overlay; the strips name the groups, so
    # the now-redundant colour legend is dropped.
    if (facet) {
      p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[group]])) +
        ggplot2::theme(legend.position = "none")
    } else if (legend_inside) {
      # Overlaid groups: a unimodal histogram/density peaks in the interior and
      # tapers to the axes, leaving the upper corners empty, so (when asked) tuck
      # the colour legend into the top-right rather than a right-hand margin.
      p <- p + legend_inside_theme(c(0.98, 0.98), c(1, 1))
    }
  }
  p
}
