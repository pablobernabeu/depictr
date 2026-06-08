# Scatter-plot matrix --------------------------------------------------------

#' Scatter-plot matrix
#'
#' A matrix of pairwise plots for a set of numeric variables: scatter plots
#' below the diagonal, densities on the diagonal and correlation coefficients
#' above the diagonal. Optionally colour everything by a grouping variable.
#' Built with 'patchwork', so it shares the package theme and palette.
#'
#' @param data A data frame.
#' @param cols Numeric columns to include. If `NULL`, all numeric columns are
#'   used (up to `max_cols`).
#' @param group Optional grouping variable mapped to colour.
#' @param max_cols Safety cap on the number of variables (a k-by-k matrix grows
#'   quickly).
#' @param point_alpha Point transparency in the scatter panels.
#' @param palette Colours for the groups; defaults to [statviz_palette()].
#' @param title Overall title for the matrix.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @export
#' @examples
#' explore_pairs(crop_yield, cols = c("rainfall", "fertilizer", "yield"))
#' \donttest{
#' explore_pairs(crop_yield, cols = c("rainfall", "fertilizer", "yield"),
#'               group = treatment)
#' }
explore_pairs <- function(data, cols = NULL, group = NULL, max_cols = 8,
                          point_alpha = 0.5, palette = NULL, title = NULL) {
  group <- resolve_var(data, rlang::enquo(group), "group")
  if (is.null(cols)) {
    cols <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    check_columns(data, cols)
    non_num <- cols[!vapply(data[cols], is.numeric, logical(1))]
    if (length(non_num)) {
      stop("explore_pairs() needs numeric columns; these are not: ",
           paste(non_num, collapse = ", "), ".", call. = FALSE)
    }
  }
  if (length(cols) < 2) stop("Need at least two numeric columns.", call. = FALSE)
  if (length(cols) > max_cols) {
    stop("Too many columns (", length(cols), " > max_cols = ", max_cols,
         "). Select fewer with `cols`.", call. = FALSE)
  }

  d <- data
  if (!is.null(group)) d[[group]] <- as.factor(d[[group]])
  pal <- palette %||% (if (!is.null(group)) statviz_palette(nlevels(d[[group]])))

  k <- length(cols)
  panels <- vector("list", k * k)
  pos <- 1L
  for (i in seq_len(k)) {       # row
    for (j in seq_len(k)) {     # column
      panels[[pos]] <- pairs_panel(d, cols[j], cols[i], i, j, group, pal,
                                   point_alpha)
      pos <- pos + 1L
    }
  }

  combined <- patchwork::wrap_plots(panels, nrow = k, ncol = k)
  if (!is.null(group)) {
    combined <- combined +
      patchwork::plot_layout(guides = "collect")
  }
  if (!is.null(title)) {
    combined <- combined + patchwork::plot_annotation(
      title = title,
      theme = ggplot2::theme(plot.title = ggplot2::element_text(
        colour = "#005b96", face = "bold", hjust = 0.5))
    )
  }
  combined
}

# ---- internal helpers ------------------------------------------------------

#' Build one panel of the scatter-plot matrix
#' @noRd
pairs_panel <- function(d, xvar, yvar, i, j, group, pal, point_alpha) {
  base <- theme_statviz(grid = "none") +
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(2, 2, 2, 2)
    )

  if (i == j) {
    # Diagonal: density (with a small label of the variable name)
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[xvar]]))
    if (is.null(group)) {
      p <- p + ggplot2::geom_density(fill = "#005b96", alpha = 0.5,
                                     colour = NA, na.rm = TRUE)
    } else {
      p <- p + ggplot2::geom_density(
        ggplot2::aes(fill = .data[[group]], colour = .data[[group]]),
        alpha = 0.35, na.rm = TRUE) +
        ggplot2::scale_fill_manual(values = pal) +
        ggplot2::scale_colour_manual(values = pal)
    }
    p <- p + ggplot2::annotate("text", x = Inf, y = Inf, label = xvar,
                               hjust = 1.1, vjust = 1.4, fontface = "bold",
                               colour = "#0a3d62", size = 3)
    return(p + base + ggplot2::labs(y = NULL))
  }

  if (i > j) {
    # Lower triangle: scatter
    p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[xvar]], y = .data[[yvar]]))
    if (is.null(group)) {
      p <- p + ggplot2::geom_point(alpha = point_alpha, colour = "#005b96",
                                   size = 0.9, na.rm = TRUE)
    } else {
      p <- p + ggplot2::geom_point(
        ggplot2::aes(colour = .data[[group]]),
        alpha = point_alpha, size = 0.9, na.rm = TRUE) +
        ggplot2::scale_colour_manual(values = pal)
    }
    return(p + base)
  }

  # Upper triangle: correlation coefficient(s)
  if (is.null(group)) {
    r <- stats::cor(d[[xvar]], d[[yvar]], use = "pairwise.complete.obs")
    lab <- data.frame(x = 0.5, y = 0.5,
                      label = paste0("r = ", formatC(r, format = "f", digits = 2)))
    p <- ggplot2::ggplot(lab, ggplot2::aes(x = .data$x, y = .data$y)) +
      ggplot2::geom_text(ggplot2::aes(label = .data$label),
                         size = 3.4, colour = "#0a3d62")
  } else {
    grp <- d[[group]]
    parts <- tapply(seq_len(nrow(d)), grp, function(idx) {
      stats::cor(d[[xvar]][idx], d[[yvar]][idx], use = "pairwise.complete.obs")
    })
    lab <- data.frame(
      x = 0.5,
      y = seq(0.85, 0.15, length.out = length(parts)),
      label = paste0(names(parts), ": ",
                     formatC(unlist(parts), format = "f", digits = 2)),
      grp = factor(names(parts), levels = levels(grp))
    )
    p <- ggplot2::ggplot(lab, ggplot2::aes(x = .data$x, y = .data$y)) +
      ggplot2::geom_text(ggplot2::aes(label = .data$label, colour = .data$grp),
                         size = 3) +
      ggplot2::scale_colour_manual(values = pal, guide = "none")
  }
  p +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    base +
    ggplot2::theme(axis.text = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank())
}
