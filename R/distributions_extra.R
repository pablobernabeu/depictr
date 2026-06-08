# Raincloud and group-comparison plots ---------------------------------------

#' Raincloud plot
#'
#' A "raincloud" combines three views of a distribution: a half-violin density
#' (the cloud), a narrow boxplot, and the raw jittered points (the rain). It
#' shows the shape, the summary and the individual data at once, and is a
#' popular, transparent alternative to the bare boxplot. Implemented with base
#' graphics primitives, so it needs no extra packages.
#'
#' @param data A data frame.
#' @param y The numeric variable (string or unquoted name).
#' @param group Optional grouping variable on the x-axis.
#' @param width Maximum width of the half-violin.
#' @param point_alpha Transparency of the rain points.
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' raincloud_plot(lexical_decision, RT, group = condition)
#' raincloud_plot(crop_yield, yield, group = treatment)
raincloud_plot <- function(data, y, group = NULL, width = 0.4,
                           point_alpha = 0.4, palette = NULL, title = NULL,
                           x_lab = NULL, y_lab = NULL) {
  y <- resolve_var(data, rlang::enquo(y), "y")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[y]])) stop("`y` must be numeric.", call. = FALSE)
  y_lab <- y_lab %||% y

  d <- data[!is.na(data[[y]]), , drop = FALSE]
  d$.g <- if (is.null(group)) factor("all") else as.factor(d[[group]])
  groups <- levels(d$.g)
  pos <- stats::setNames(seq_along(groups), groups)

  dens <- do.call(rbind, lapply(groups, function(g) {
    v <- d[[y]][d$.g == g]
    de <- stats::density(v)
    w <- de$y / max(de$y) * width
    data.frame(g = g,
               x = c(pos[[g]] + w, rep(pos[[g]], length(w))),
               yy = c(de$x, rev(de$x)),
               stringsAsFactors = FALSE)
  }))
  box <- do.call(rbind, lapply(groups, function(g) {
    bs <- grDevices::boxplot.stats(d[[y]][d$.g == g])$stats
    data.frame(g = g, x = pos[[g]], ymin = bs[1], lower = bs[2],
               middle = bs[3], upper = bs[4], ymax = bs[5],
               stringsAsFactors = FALSE)
  }))
  d$.x <- pos[as.character(d$.g)] - 0.22 +
    stats::runif(nrow(d), -0.06, 0.06)

  pal <- palette %||% statviz_palette(length(groups))

  p <- ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data = dens,
      ggplot2::aes(x = .data$x, y = .data$yy, fill = .data$g, group = .data$g),
      alpha = 0.5, colour = NA
    ) +
    ggplot2::geom_point(
      data = d,
      ggplot2::aes(x = .data$.x, y = .data[[y]], colour = .data$.g),
      alpha = point_alpha, size = 0.9
    ) +
    ggplot2::geom_boxplot(
      data = box,
      ggplot2::aes(x = .data$x, ymin = .data$ymin, lower = .data$lower,
                   middle = .data$middle, upper = .data$upper,
                   ymax = .data$ymax, group = .data$g),
      stat = "identity", width = 0.09, fill = "white", colour = "grey30"
    ) +
    ggplot2::scale_fill_manual(values = pal) +
    ggplot2::scale_colour_manual(values = pal) +
    ggplot2::scale_x_continuous(breaks = pos, labels = groups) +
    ggplot2::labs(x = x_lab %||% (group %||% NULL), y = y_lab, title = title) +
    theme_statviz(grid = "y") +
    ggplot2::theme(legend.position = "none")

  if (is.null(group)) {
    p <- p + ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                            axis.ticks.x = ggplot2::element_blank())
  }
  p
}

#' Compare group means with confidence intervals
#'
#' An estimation-style plot of a numeric outcome across the levels of a grouping
#' variable: each group's mean with a confidence interval, over a backdrop of
#' the raw (jittered) data. A clearer answer to "do these groups differ?" than a
#' bar chart, because it shows both the estimate and its uncertainty.
#'
#' @param data A data frame.
#' @param y The numeric outcome (string or unquoted name).
#' @param group The grouping variable (string or unquoted name).
#' @param conf_level Confidence level for the intervals (t-based).
#' @param show_points Draw the raw data behind the means?
#' @param point_alpha Transparency of the raw points.
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' group_comparison_plot(lexical_decision, RT, condition)
#' group_comparison_plot(crop_yield, yield, treatment)
group_comparison_plot <- function(data, y, group, conf_level = 0.95,
                                  show_points = TRUE, point_alpha = 0.25,
                                  palette = NULL, title = NULL, x_lab = NULL,
                                  y_lab = NULL) {
  y <- resolve_var(data, rlang::enquo(y), "y")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[y]])) stop("`y` must be numeric.", call. = FALSE)
  x_lab <- x_lab %||% group
  y_lab <- y_lab %||% y

  d <- data[!is.na(data[[y]]) & !is.na(data[[group]]), , drop = FALSE]
  d[[group]] <- as.factor(d[[group]])
  groups <- levels(d[[group]])

  summ <- do.call(rbind, lapply(groups, function(g) {
    v <- d[[y]][d[[group]] == g]
    nv <- length(v)
    se <- stats::sd(v) / sqrt(nv)
    tc <- stats::qt(1 - (1 - conf_level) / 2, df = nv - 1)
    data.frame(group = g, mean = mean(v), lower = mean(v) - tc * se,
               upper = mean(v) + tc * se, stringsAsFactors = FALSE)
  }))
  summ$group <- factor(summ$group, levels = groups)
  pal <- palette %||% statviz_palette(length(groups))

  p <- ggplot2::ggplot(summ, ggplot2::aes(x = .data$group, colour = .data$group))
  if (show_points) {
    p <- p + ggplot2::geom_jitter(
      data = d,
      ggplot2::aes(x = .data[[group]], y = .data[[y]], colour = .data[[group]]),
      width = 0.12, alpha = point_alpha, size = 0.9, inherit.aes = FALSE
    )
  }
  p +
    ggplot2::geom_pointrange(
      ggplot2::aes(y = .data$mean, ymin = .data$lower, ymax = .data$upper),
      linewidth = 0.8, size = 0.6
    ) +
    ggplot2::scale_colour_manual(values = pal) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_statviz(grid = "y") +
    ggplot2::theme(legend.position = "none")
}
