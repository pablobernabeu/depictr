# Missing-data map -----------------------------------------------------------

#' Map the missing values in a data frame
#'
#' Draws a tile map of the data frame with one column per variable and one row
#' per observation, shading the cells that are missing. The variables are
#' ordered by their proportion of missing values, and that proportion is shown
#' in the axis labels, making it easy to spot variables and patterns that need
#' attention before modelling.
#'
#' @param data A data frame.
#' @param cols Optional character vector of columns to include (default: all).
#' @param sort Whether to order variables by their proportion of missing values.
#' @param show_pct Whether to append the percentage missing to each variable label.
#' @param colours Length-2 vector: colours for present and missing cells.
#'   Defaults to a muted grey for present cells and the colourblind-safe
#'   [depictr_palette()] accent for missing cells.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' missingness_map(wellbeing_survey)
missingness_map <- function(data, cols = NULL, sort = TRUE, show_pct = TRUE,
                             colours = c("grey85", depictr_accent()),
                             title = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(cols)) cols <- names(data) else check_columns(data, cols)
  if (length(colours) != 2) {
    stop("`colours` must have exactly two values.", call. = FALSE)
  }

  miss <- is.na(data[cols])
  pct <- colMeans(miss)
  ord <- if (sort) names(sort(pct, decreasing = TRUE)) else cols

  labels <- ord
  if (show_pct) {
    labels <- sprintf("%s (%.0f%%)", ord, 100 * pct[ord])
  }

  long <- data.frame(
    row = rep(seq_len(nrow(data)), times = length(ord)),
    variable = factor(rep(ord, each = nrow(data)), levels = ord, labels = labels),
    missing = as.vector(miss[, ord, drop = FALSE]),
    stringsAsFactors = FALSE
  )

  overall <- mean(miss)
  subtitle <- sprintf("%.1f%% of all values are missing", 100 * overall)

  p <- ggplot2::ggplot(
    long, ggplot2::aes(x = .data$variable, y = .data$row, fill = .data$missing)
  ) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_manual(
      values = c(`FALSE` = colours[1], `TRUE` = colours[2]),
      labels = c(`FALSE` = "Present", `TRUE` = "Missing"),
      name = NULL
    ) +
    ggplot2::scale_y_reverse(expand = c(0, 0)) +
    ggplot2::labs(x = NULL, y = "Observation", title = title,
                  subtitle = subtitle) +
    theme_depictr(grid = "none") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.major = ggplot2::element_blank()
    )
  # Variables are ordered most- to least-missing left-to-right, so the rightmost
  # columns are the most complete (solid "Present"): a two-item legend tucked
  # into the top-right covers only those uninformative cells, never a "Missing"
  # mark. Keep it in the right margin when the columns are left unsorted.
  if (sort) {
    p <- p + legend_inside(c(0.99, 0.99), c(1, 1))
  }
  p
}
