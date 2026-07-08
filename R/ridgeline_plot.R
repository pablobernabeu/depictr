# Ridgeline (joyplot) distribution plot --------------------------------------

#' Ridgeline plot
#'
#' Shows the distribution of a numeric variable across the levels of a grouping
#' variable as a column of partially overlapping density curves, one ridge per
#' group, stacked up the y-axis. It compares many distributions in a compact
#' space, making shifts in location and shape easy to follow, and is a clearer
#' choice than many overlaid densities once there are several groups.
#'
#' Densities are computed with [stats::density()] and scaled to a common height;
#' the `overlap` argument controls how far each ridge reaches into the one above.
#' Groups with fewer than two non-missing values are dropped with a warning. The
#' implementation is base R + ggplot2, with no extra package dependency.
#'
#' @param data A data frame.
#' @param x The numeric variable whose distribution is shown (string or unquoted
#'   name).
#' @param group The grouping variable (string or unquoted name); one ridge per
#'   level.
#' @param overlap How far each ridge extends into the next, as a multiple of the
#'   row spacing. `1` makes the tallest ridge just touch the next baseline;
#'   larger values overlap more. Defaults to `1.4`.
#' @param alpha Fill transparency of the ridges.
#' @param scale_height Whether to scale every ridge to the same peak height
#'   (`TRUE`, the default) or keep the true relative densities (`FALSE`).
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Plot title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' ridgeline_plot(wellbeing_survey, life_satisfaction, region)
#' ridgeline_plot(lexical_decision, RT, condition)
ridgeline_plot <- function(data, x, group, overlap = 1.4, alpha = 0.85,
                           scale_height = TRUE, palette = NULL,
                           title = NULL, x_lab = NULL, y_lab = NULL) {
  x <- resolve_var(data, rlang::enquo(x), "x")
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (!is.numeric(data[[x]])) stop("`x` must be numeric.", call. = FALSE)
  if (!is.numeric(overlap) || length(overlap) != 1 || overlap <= 0) {
    stop("`overlap` must be a single positive number.", call. = FALSE)
  }
  x_lab <- x_lab %||% x
  y_lab <- y_lab %||% group

  d <- data[stats::complete.cases(data[, c(x, group), drop = FALSE]), ,
            drop = FALSE]
  g <- droplevels(as.factor(d[[group]]))
  groups <- levels(g)
  pos <- stats::setNames(seq_along(groups), groups)

  # Each element carries its density row (NULL if too sparse to estimate) and,
  # for a sparse group, its name -- read back below rather than accumulated
  # with `<<-`.
  res <- lapply(groups, function(gg) {
    v <- d[[x]][as.character(g) == gg]
    if (length(v) < 2) return(list(row = NULL, sparse = gg))
    de <- stats::density(v)
    list(row = data.frame(group = gg, x = de$x, h = de$y,
                          stringsAsFactors = FALSE),
        sparse = NULL)
  })
  dens <- do.call(rbind, lapply(res, `[[`, "row"))
  sparse <- unlist(lapply(res, `[[`, "sparse"))
  if (length(sparse)) {
    warning("No ridge drawn for group(s) with n < 2: ",
            paste(sparse, collapse = ", "), ".", call. = FALSE)
  }
  if (is.null(dens) || !nrow(dens)) {
    stop("Need at least one group with two or more values.", call. = FALSE)
  }

  # Scale ridge heights: each to its own peak (comparable shapes) or all by a
  # single factor (true relative densities). `overlap` sets how far the tallest
  # ridge reaches above its baseline, in row-spacing units.
  if (scale_height) {
    dens$h <- stats::ave(dens$h, dens$group,
                         FUN = function(z) z / max(z))
  } else {
    dens$h <- dens$h / max(dens$h)
  }
  dens$base <- pos[dens$group]
  dens$y <- dens$base + dens$h * overlap
  dens$group <- factor(dens$group, levels = groups)

  # Draw from the top ridge down so each lower ridge sits in front of the tail
  # of the one above (the conventional ridgeline overlap).
  dens <- dens[order(-dens$base, dens$x), , drop = FALSE]

  pal_fun <- if (is.null(palette)) NULL else function(k) palette

  ggplot2::ggplot(dens, ggplot2::aes(x = .data$x, group = .data$group,
                                     fill = .data$group)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$base, ymax = .data$y),
      colour = "white", linewidth = 0.3, alpha = alpha
    ) +
    scale_fill_depictr(palette = pal_fun) +
    ggplot2::scale_y_continuous(breaks = pos, labels = groups,
                                expand = ggplot2::expansion(mult = c(0, 0.08))) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr(grid = "x") +
    ggplot2::theme(legend.position = "none")
}
