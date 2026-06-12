# Reporting helpers: palette preview, composition, saving --------------------

#' Preview the depictr palettes
#'
#' Displays the colours returned by [depictr_palette()] as labelled swatches.
#' It is useful when choosing how many groups to show, selecting a palette type,
#' or documenting a figure.
#'
#' @param n Number of colours to preview.
#' @param type Palette type to preview: `"qualitative"`, `"sequential"`,
#'   `"diverging"`, or `"all"` to show all three.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' palette_preview()
#' palette_preview(7, type = "sequential")
#' palette_preview(type = "all")
palette_preview <- function(n = 8, type = c("qualitative", "sequential",
                                            "diverging", "all")) {
  type <- match.arg(type)
  types <- if (type == "all") {
    c("qualitative", "sequential", "diverging")
  } else {
    type
  }
  df <- do.call(rbind, lapply(types, function(tp) {
    cols <- depictr_palette(n, type = tp)
    data.frame(type = tp, i = seq_along(cols), col = cols,
               stringsAsFactors = FALSE)
  }))
  df$type <- factor(df$type, levels = types)
  show_labels <- type != "all"

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$i, y = 1, fill = .data$col)) +
    ggplot2::geom_tile(width = 0.95, height = 0.95) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(x = NULL, y = NULL,
                  title = if (type == "all") "depictr palettes" else
                    paste0("depictr palette (", type, ")")) +
    theme_depictr(grid = "none") +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
  if (length(types) > 1) {
    p <- p + ggplot2::facet_wrap(~ type, ncol = 1)
  }
  if (show_labels) {
    p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$col), angle = 90,
                                colour = "white", fontface = "bold", size = 3)
  }
  p
}

#' Compose several plots into one figure
#'
#' A thin, friendly wrapper around [patchwork::wrap_plots()] that adds the
#' common finishing touches: collecting duplicate legends into one, an overall
#' title and subtitle, and automatic panel tags (A, B, C, ...).
#'
#' @param ... Plots to combine, or a single list of plots.
#' @param ncol,nrow Layout dimensions (passed to patchwork).
#' @param guides How to treat legends: `"collect"` (merge duplicates) or
#'   `"keep"`.
#' @param title,subtitle Overall title and subtitle.
#' @param tag_levels Panel tag style, e.g. `"A"`, `"1"` or `"i"`; `NULL` for no
#'   tags.
#'
#' @return A 'patchwork' object.
#' @export
#' @examples
#' p1 <- explore_distribution(crop_yield, yield)
#' p2 <- scatter_trend(crop_yield, fertilizer, yield)
#' arrange_plots(p1, p2, ncol = 2, title = "Crop yield", tag_levels = "A")
arrange_plots <- function(..., ncol = NULL, nrow = NULL,
                          guides = c("collect", "keep"),
                          title = NULL, subtitle = NULL, tag_levels = "A") {
  guides <- match.arg(guides)
  dots <- list(...)
  if (length(dots) == 1 && is.list(dots[[1]]) &&
      !inherits(dots[[1]], "ggplot")) {
    dots <- dots[[1]]
  }
  combined <- patchwork::wrap_plots(dots, ncol = ncol, nrow = nrow,
                                    guides = guides)
  if (!is.null(title) || !is.null(subtitle) || !is.null(tag_levels)) {
    combined <- combined + patchwork::plot_annotation(
      title = title, subtitle = subtitle, tag_levels = tag_levels,
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(colour = "#005b96", face = "bold",
                                           hjust = 0.5),
        plot.subtitle = ggplot2::element_text(hjust = 0.5, colour = "grey30")
      )
    )
  }
  combined
}

#' Save a plot with publication-ready defaults
#'
#' A convenience wrapper around [ggplot2::ggsave()] with sensible defaults for
#' figures in papers and reports: a moderate size, 300 dpi, and the output
#' directory created if needed. The device is inferred from the file extension.
#'
#' @param filename Output file path. The extension sets the device (e.g. `.png`,
#'   `.pdf`, `.tiff`).
#' @param plot The plot to save; defaults to the last plot drawn.
#' @param width,height Dimensions.
#' @param units Units for `width` and `height`.
#' @param dpi Resolution for raster devices.
#' @param ... Passed to [ggplot2::ggsave()].
#'
#' @return The `filename`, invisibly.
#' @export
#' @examples
#' p <- scatter_trend(crop_yield, fertilizer, yield)
#' tmp <- file.path(tempdir(), "yield.png")
#' save_plot(tmp, p)
save_plot <- function(filename, plot = ggplot2::last_plot(),
                      width = 7, height = 4.5, units = "in", dpi = 300, ...) {
  dir <- dirname(filename)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  ggplot2::ggsave(filename = filename, plot = plot, width = width,
                  height = height, units = units, dpi = dpi, ...)
  invisible(filename)
}
