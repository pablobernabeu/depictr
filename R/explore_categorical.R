# Categorical bar chart -------------------------------------------------------

#' Bar chart of a categorical variable
#'
#' Counts (or proportions) of the levels of a categorical variable, optionally
#' split by a grouping variable.
#'
#' @param data A data frame.
#' @param x The categorical variable (string or unquoted name).
#' @param group Optional grouping variable mapped to fill.
#' @param proportion Show proportions instead of counts? When `group` is set,
#'   proportions are computed within each group.
#' @param position Bar position when `group` is set: `"dodge"`, `"stack"` or
#'   `"fill"`.
#' @param sort Order the bars from most to least frequent?
#' @param horizontal Draw horizontal bars (helpful with many or long labels)?
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title,x_lab Plot title and category-axis label (defaults to the
#'   variable name).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' explore_categorical(wellbeing_survey, region)
#' explore_categorical(wellbeing_survey, education, group = region,
#'                     proportion = TRUE, position = "dodge")
explore_categorical <- function(data, x, group = NULL, proportion = FALSE,
                                position = c("dodge", "stack", "fill"),
                                sort = TRUE, horizontal = FALSE,
                                palette = NULL, title = NULL, x_lab = NULL) {
  position <- match.arg(position)
  x <- resolve_var(data, rlang::enquo(x), "x")
  group <- resolve_var(data, rlang::enquo(group), "group")
  x_lab <- x_lab %||% x

  d <- data[!is.na(data[[x]]), , drop = FALSE]
  d[[x]] <- as.factor(d[[x]])

  if (is.null(group)) {
    tab <- as.data.frame(table(level = d[[x]]), stringsAsFactors = FALSE)
    tab$value <- if (proportion) tab$Freq / sum(tab$Freq) else tab$Freq
  } else {
    d[[group]] <- as.factor(d[[group]])
    tab <- as.data.frame(table(level = d[[x]], grp = d[[group]]),
                         stringsAsFactors = FALSE)
    if (proportion) {
      denom <- stats::ave(tab$Freq, tab$grp, FUN = sum)
      tab$value <- ifelse(denom > 0, tab$Freq / denom, 0)
    } else {
      tab$value <- tab$Freq
    }
  }

  lev_order <- if (sort) {
    totals <- tapply(tab$Freq, tab$level, sum)
    names(sort(totals, decreasing = !horizontal))
  } else {
    levels(d[[x]])
  }
  tab$level <- factor(tab$level, levels = lev_order)

  y_lab <- if (proportion) "Proportion" else "Count"
  mapping <- if (is.null(group)) {
    ggplot2::aes(x = .data$level, y = .data$value)
  } else {
    ggplot2::aes(x = .data$level, y = .data$value, fill = .data$grp)
  }

  p <- ggplot2::ggplot(tab, mapping)
  if (is.null(group)) {
    p <- p + ggplot2::geom_col(fill = "#005b96", width = 0.75)
  } else {
    p <- p + ggplot2::geom_col(position = position, width = 0.75)
    pal <- palette %||% statviz_palette(nlevels(factor(tab$grp)))
    p <- p + ggplot2::scale_fill_manual(values = pal, name = group)
  }

  p <- p + ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_statviz(grid = if (horizontal) "x" else "y")
  if (horizontal) {
    p <- p + ggplot2::coord_flip()
  } else {
    p <- p + ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    )
  }
  p
}
