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
#' @param show_values Whether to annotate each cell with its correlation.
#' @param digits Number of decimal places for the annotations.
#' @param palette Length-3 vector of colours for the lowest, mid (zero) and
#'   highest correlations. Defaults to the endpoints and midpoint of the
#'   colourblind-aware [depictr_palette()] diverging ramp (negative
#'   correlations red, zero neutral, positive correlations brand blue).
#' @param title Plot title.
#'
#' @details Columns with (near-)zero variance cannot be correlated and are
#'   dropped automatically with an informative message, so the raw
#'   `"the standard deviation is zero"` warning from [stats::cor()] is not
#'   surfaced. If, after dropping them, any cells still come out `NA` (e.g. two
#'   variables that never co-occur under `"pairwise.complete.obs"`), those cells
#'   are rendered in grey and labelled `n/a` rather than left blank.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' correlation_heatmap(wellbeing_survey)
#' correlation_heatmap(crop_yield, method = "spearman", show_values = FALSE)
correlation_heatmap <- function(data, cols = NULL, method = "pearson",
                                    use = "pairwise.complete.obs",
                                    show_values = TRUE, digits = 2,
                                    palette = depictr_palette(
                                      5, "diverging")[c(1, 3, 5)],
                                    title = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(cols)) {
    cols <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    check_columns(data, cols)
  }
  if (length(palette) != 3) {
    stop("`palette` must have exactly three colours.", call. = FALSE)
  }

  # Drop (near-)constant columns: cor() cannot define a correlation for them
  # and would otherwise emit a raw "standard deviation is zero" warning and
  # leave a band of unannotated NA cells.
  is_const <- vapply(cols, function(cn) {
    v <- data[[cn]][!is.na(data[[cn]])]
    length(v) < 2 || stats::sd(v) < .Machine$double.eps^0.5
  }, logical(1))
  if (any(is_const)) {
    message("correlation_heatmap(): dropping zero-variance column(s): ",
            paste(cols[is_const], collapse = ", "), ".")
    cols <- cols[!is_const]
  }

  if (length(cols) < 2) {
    stop("Need at least two numeric columns to compute correlations.",
         call. = FALSE)
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
      midpoint = 0, limits = c(-1, 1), name = "Correlation",
      na.value = "grey85"
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    theme_depictr(grid = "none") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.major = ggplot2::element_blank()
    )

  if (show_values) {
    # Label undefined (NA) correlations distinctly rather than leaving blanks.
    long$label <- ifelse(
      is.na(long$corr), "n/a",
      formatC(long$corr, format = "f", digits = digits)
    )
    label_colour <- ifelse(
      is.na(long$corr), "grey40",
      ifelse(abs(long$corr) > 0.6, "white", "grey20")
    )
    p <- p + ggplot2::geom_text(
      data = long,
      ggplot2::aes(label = .data$label),
      size = 3,
      colour = label_colour
    )
  }
  p
}
