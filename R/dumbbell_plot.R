# Dumbbell (connected dot) plot ----------------------------------------------

#' Dumbbell plot
#'
#' Compares a numeric value between exactly two groups across a set of
#' categories: for each category the two group values are drawn as points joined
#' by a connecting segment, so the size and direction of the gap is read at a
#' glance. It is a clearer alternative to paired or grouped bars for
#' before/after, two-condition or two-period comparisons.
#'
#' When a category has several rows per group the values are averaged. Rows with
#' a missing category, value or group are dropped.
#'
#' @param data A data frame.
#' @param category The categorical axis (string or unquoted name); one row of
#'   the plot per level.
#' @param value The numeric value to compare (string or unquoted name).
#' @param group The two-level grouping variable whose levels are the two ends of
#'   each dumbbell (string or unquoted name).
#' @param sort How to order the categories up the axis: `"gap"` (by the signed
#'   difference between the two groups, the default), `"value"` (by the second
#'   group's value), or `"none"` (the data's own order).
#' @param point_size Size of the end points.
#' @param palette Length-2 colours for the two groups; defaults to
#'   [depictr_palette()].
#' @param legend_inside When `TRUE`, draw the two-group legend inside the panel
#'   (in the top-right corner, which the default gap sort with the shortest
#'   dumbbell on top usually leaves clear) over a translucent background,
#'   instead of in a right-hand margin. Defaults to `FALSE`.
#' @param title,x_lab,y_lab Plot title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' wb <- wellbeing_survey
#' wb$age_group <- ifelse(wb$age < median(wb$age), "younger", "older")
#' dumbbell_plot(wb, region, life_satisfaction, age_group)
dumbbell_plot <- function(data, category, value, group,
                          sort = c("gap", "value", "none"),
                          point_size = 3, palette = NULL, legend_inside = FALSE,
                          title = NULL, x_lab = NULL, y_lab = NULL) {
  sort <- match.arg(sort)
  category <- resolve_var(data, rlang::enquo(category), "category")
  value <- resolve_var(data, rlang::enquo(value), "value")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[value]])) stop("`value` must be numeric.", call. = FALSE)

  d <- data[stats::complete.cases(data[, c(category, value, group)]), ,
            drop = FALSE]
  glv <- levels(droplevels(as.factor(d[[group]])))
  if (length(glv) != 2) {
    stop("`group` must have exactly two levels.", call. = FALSE)
  }

  # Average within each category x group cell, then widen to one row per
  # category carrying both group values.
  agg <- stats::aggregate(d[[value]],
                          by = list(category = as.character(d[[category]]),
                                    group = as.character(d[[group]])),
                          FUN = mean)
  names(agg)[3] <- "value"
  v1 <- stats::setNames(agg$value[agg$group == glv[1]],
                        agg$category[agg$group == glv[1]])
  v2 <- stats::setNames(agg$value[agg$group == glv[2]],
                        agg$category[agg$group == glv[2]])
  cats <- intersect(names(v1), names(v2))
  if (!length(cats)) {
    stop("No category has a value in both groups.", call. = FALSE)
  }
  seg <- data.frame(category = cats, x1 = v1[cats], x2 = v2[cats],
                    stringsAsFactors = FALSE)

  ord <- switch(sort,
    gap = order(seg$x2 - seg$x1),
    value = order(seg$x2),
    none = seq_len(nrow(seg))
  )
  seg$category <- factor(seg$category, levels = seg$category[ord])

  pts <- rbind(
    data.frame(category = seg$category, value = seg$x1, group = glv[1]),
    data.frame(category = seg$category, value = seg$x2, group = glv[2])
  )
  pts$group <- factor(pts$group, levels = glv)

  pal <- palette %||% depictr_palette(2)

  p <- ggplot2::ggplot(seg, ggplot2::aes(y = .data$category)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$x1, xend = .data$x2,
                   yend = .data$category),
      colour = depictr_reference(), linewidth = 1
    ) +
    ggplot2::geom_point(
      data = pts,
      ggplot2::aes(x = .data$value, colour = .data$group),
      size = point_size
    ) +
    ggplot2::scale_colour_manual(values = pal, name = NULL) +
    ggplot2::labs(x = x_lab %||% value, y = y_lab %||% category,
                  title = title) +
    theme_depictr(grid = "x")
  # With the default gap sort the shortest dumbbell sits at the top, so the
  # top-right corner is usually clear: when asked, place the two-group legend
  # there over a semi-transparent background instead of in a right-hand margin.
  if (legend_inside) p <- p + legend_inside_theme(c(0.98, 0.98), c(1, 1))
  p
}
