# Outlier plot ---------------------------------------------------------------

#' Box / violin plot highlighting outliers
#'
#' Shows the distribution of a numeric variable (optionally by group) as a box
#' and/or violin plot, with points beyond the 1.5 * IQR fences highlighted so
#' that outliers are easy to spot before modelling.
#'
#' @param data A data frame.
#' @param y The numeric variable (string or unquoted name).
#' @param group Optional grouping variable on the x-axis.
#' @param type One of `"box"`, `"violin"` or `"both"`.
#' @param flag Highlight outliers (points beyond 1.5 * IQR)?
#' @param outlier_colour Colour for highlighted outliers.
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title,y_lab Plot title and value-axis label.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' outlier_plot(crop_yield, yield)
#' outlier_plot(lexical_decision, RT, group = condition, type = "both")
outlier_plot <- function(data, y, group = NULL,
                         type = c("box", "violin", "both"),
                         flag = TRUE, outlier_colour = "#e23b3b",
                         palette = NULL, title = NULL, y_lab = NULL) {
  type <- match.arg(type)
  y <- resolve_var(data, rlang::enquo(y), "y")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[y]])) stop("`y` must be numeric.", call. = FALSE)
  y_lab <- y_lab %||% y

  d <- data[!is.na(data[[y]]), , drop = FALSE]
  d$.x <- if (is.null(group)) factor("") else as.factor(d[[group]])

  # Flag outliers within each group using the 1.5 * IQR rule
  d$.outlier <- FALSE
  if (flag) {
    split_idx <- split(seq_len(nrow(d)), d$.x)
    for (idx in split_idx) {
      v <- d[[y]][idx]
      qs <- stats::quantile(v, c(0.25, 0.75), names = FALSE)
      fence <- 1.5 * (qs[2] - qs[1])
      d$.outlier[idx] <- v < qs[1] - fence | v > qs[2] + fence
    }
  }

  mapping <- ggplot2::aes(x = .data$.x, y = .data[[y]])
  if (!is.null(group)) mapping <- ggplot2::aes(x = .data$.x, y = .data[[y]],
                                               fill = .data$.x)
  p <- ggplot2::ggplot(d, mapping)

  if (type %in% c("violin", "both")) {
    p <- p + ggplot2::geom_violin(alpha = 0.35, colour = NA, na.rm = TRUE)
  }
  if (type %in% c("box", "both")) {
    p <- p + ggplot2::geom_boxplot(
      width = if (type == "both") 0.18 else 0.55,
      outlier.shape = if (flag) NA else 19, alpha = 0.6, na.rm = TRUE
    )
  }
  if (flag && any(d$.outlier)) {
    p <- p + ggplot2::geom_point(
      data = d[d$.outlier, , drop = FALSE],
      colour = outlier_colour, size = 1.8,
      position = ggplot2::position_jitter(width = 0.06, height = 0)
    )
  }

  p <- p + ggplot2::labs(x = group %||% NULL, y = y_lab, title = title) +
    theme_statviz(grid = "y") +
    ggplot2::theme(legend.position = "none")
  if (is.null(group)) {
    p <- p + ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                            axis.ticks.x = ggplot2::element_blank())
  } else {
    pal <- palette %||% statviz_palette(nlevels(d$.x))
    p <- p + ggplot2::scale_fill_manual(values = pal)
  }
  p
}
