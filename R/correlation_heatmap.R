# Correlation heatmap --------------------------------------------------------

#' Plot a correlation matrix as a heatmap
#'
#' Computes the pairwise correlations between the numeric columns of a data
#' frame and displays them as a colour-coded heatmap, optionally annotated with
#' the correlation values.
#'
#' @param data A data frame.
#' @param cols Optional character vector of columns to include. If `NULL`, all
#'   numeric columns are used.
#' @param method Correlation method: `"pearson"`, `"spearman"` or `"kendall"`.
#' @param use Missing-value handling passed to [stats::cor()].
#' @param show_values Annotate each cell with its correlation?
#' @param digits Number of decimal places for the annotations.
#' @param palette Length-3 vector of colours for the lowest, mid (zero) and
#'   highest correlations.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' correlation_heatmap(wellbeing_survey)
#' correlation_heatmap(crop_yield, method = "spearman", show_values = FALSE)
correlation_heatmap <- function(data, cols = NULL, method = "pearson",
                                    use = "pairwise.complete.obs",
                                    show_values = TRUE, digits = 2,
                                    palette = c("#b2182b", "white", "#005b96"),
                                    title = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(cols)) {
    cols <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    check_columns(data, cols)
  }
  if (length(cols) < 2) {
    stop("Need at least two numeric columns to compute correlations.",
         call. = FALSE)
  }
  if (length(palette) != 3) {
    stop("`palette` must have exactly three colours.", call. = FALSE)
  }

  cm <- stats::cor(data[cols], use = use, method = method)
  vars <- colnames(cm)
  long <- data.frame(
    var1 = factor(rep(vars, times = length(vars)), levels = vars),
    var2 = factor(rep(vars, each = length(vars)), levels = rev(vars)),
    corr = as.vector(cm),
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(
    long, ggplot2::aes(x = .data$var1, y = .data$var2, fill = .data$corr)
  ) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
    ggplot2::scale_fill_gradient2(
      low = palette[1], mid = palette[2], high = palette[3],
      midpoint = 0, limits = c(-1, 1), name = "Correlation"
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    theme_statviz(grid = "none") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.major = ggplot2::element_blank()
    )

  if (show_values) {
    p <- p + ggplot2::geom_text(
      ggplot2::aes(label = formatC(.data$corr, format = "f", digits = digits)),
      size = 3,
      colour = ifelse(abs(long$corr) > 0.6, "white", "grey20")
    )
  }
  p
}
