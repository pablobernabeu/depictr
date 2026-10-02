# Reporting helpers: palette preview, composition, saving --------------------

#' Preview the depictr palettes
#'
#' Displays the colours returned by [depictr_palette()] as labelled swatches.
#' It is useful when choosing how many groups to show, selecting a palette type,
#' or documenting a figure. Each swatch's hex label is drawn in near-black or
#' white, whichever is more legible against that tile (chosen by the tile's
#' relative luminance), so labels stay readable on both light and dark colours.
#'
#' Set `cvd` to render the swatches as they would appear under a colour-vision
#' deficiency, using the Machado et al. (2009) simulation. The tiles are
#' recoloured to the simulated appearance while the labels keep the *original*
#' hex code, so you can see whether two groups would still be told apart by a
#' colourblind reader.
#'
#' @param n Number of colours to preview.
#' @param type Palette type to preview: `"qualitative"`, `"sequential"`,
#'   `"diverging"`, or `"all"` to show all three.
#' @param cvd Colour-vision-deficiency simulation for the tiles: `"none"` (the
#'   default, true colours), `"deutan"` (red-green, deuteranopia), `"protan"`
#'   (red-green, protanopia) or `"tritan"` (blue-yellow, tritanopia).
#'
#' @return A [ggplot2::ggplot] object.
#' @references
#' \insertRef{machado2009}{depictr}
#' @export
#' @examples
#' palette_preview()
#' palette_preview(7, type = "sequential")
#' palette_preview(type = "all")
#' palette_preview(cvd = "deutan")
palette_preview <- function(n = 8, type = c("qualitative", "sequential",
                                            "diverging", "all"),
                            cvd = c("none", "deutan", "protan", "tritan")) {
  type <- match.arg(type)
  cvd <- match.arg(cvd)
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
  # The tile is filled with the (possibly CVD-simulated) appearance; the label
  # keeps the true hex so the original colour is always identifiable.
  df$shown <- if (cvd == "none") df$col else simulate_cvd(df$col, cvd)
  # Pick a legible label colour per swatch: near-black on light tiles, white on
  # dark ones. Decide by WCAG relative luminance (sRGB-linearised) of the tile
  # as displayed, which tracks perceived lightness far better than a raw RGB
  # average and so avoids the white-on-pale contrast failure of a fixed colour.
  df$label_col <- ifelse(.relative_luminance(df$shown) > 0.4,
                         "grey10", "white")
  show_labels <- type != "all"

  base_title <- if (type == "all") "depictr palettes" else
    paste0("depictr palette (", type, ")")
  cvd_label <- c(deutan = "deuteranopia", protan = "protanopia",
                 tritan = "tritanopia")
  plot_title <- if (cvd == "none") base_title else
    paste0(base_title, " - ", cvd_label[[cvd]], " simulation")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$i, y = 1,
                                        fill = .data$shown)) +
    ggplot2::geom_tile(width = 0.95, height = 0.95) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(x = NULL, y = NULL, title = plot_title) +
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
    p <- p + ggplot2::geom_text(
      ggplot2::aes(label = .data$col, colour = .data$label_col),
      angle = 90, fontface = "bold", size = 3, show.legend = FALSE
    ) +
      ggplot2::scale_colour_identity()
  }
  p
}

# Relative luminance (WCAG 2.x) of one or more colours, in [0, 1].
#
# Linearise each sRGB channel, then take the standard 0.2126/0.7152/0.0722
# weighting. Vectorised over `cols`, returning a numeric vector of the same
# length. Two things call it: the tile and bar labels that need a legible text
# colour against a coloured background, and the contrast ratios `check_figure()`
# reports.
#
# The linearisation is the sRGB transfer function that `.srgb_to_linear()`
# applies everywhere else in the package, with its 0.04045 breakpoint, which is
# the one the WCAG 2.2 definition of relative luminance prints. Before May 2021
# that definition printed 0.03928, and the W3C's note on the change says the
# old value had no practical effect: no 8-bit channel value lies between the
# two, so no ratio differs. The Python twin's `_relative_luminance()` calls its
# own `_srgb_to_linear()` in the same way.
.relative_luminance <- function(cols) {
  lin <- .srgb_to_linear(grDevices::col2rgb(cols) / 255)
  as.numeric(0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ])
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
#' p2 <- scatter_trend(crop_yield, fertiliser, yield)
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
        plot.title = ggplot2::element_text(colour = depictr_brand(),
                                           face = "bold", hjust = 0.5),
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
#' directory created if needed. The device is inferred from the file extension,
#' and PDF, EPS and TIFF files are written to pass the technical checks
#' journals run on submitted figures.
#'
#' @section Formats journals accept:
#' When no `device` is given, three formats are written differently from
#' ggplot2's defaults.
#'
#' A PDF is written with [grDevices::cairo_pdf()], which embeds its fonts.
#' ggplot2's default, [grDevices::pdf()], names the fonts without embedding
#' them.
#'
#' An EPS or PostScript file is written with [grDevices::cairo_ps()], with its
#' fonts embedded too. PostScript has no transparency, and
#' [grDevices::postscript()] leaves every translucent layer out of the file:
#' the points and the confidence band of the plot in the examples below
#' vanish. `cairo_ps()` rasterises those layers, together with whatever they
#' overlap, at `fallback_resolution`, by default `max(dpi, 600)` here. A
#' message says so when a layer of the plot, or of any panel of a patchwork, is
#' translucent. A PDF keeps such layers as vector graphics.
#'
#' A TIFF is compressed with LZW, which is lossless. Uncompressed, a figure of
#' 7 by 4.5 inches at 300 dpi takes 8.1 MiB, and one at the largest size PLOS
#' accepts takes more than the 10 MB PLOS allows. The TIFF is drawn on white
#' unless `bg` is given, so a transparent background, as in
#' [ggplot2::theme_void()], leaves no alpha channel in the file.
#'
#' Without cairo, a PDF is written with `pdf()` and a message says how to embed
#' its fonts with [grDevices::embedFonts()], and an EPS is written with
#' `postscript()` and a warning. A `device`, or a device argument such as
#' `fallback_resolution`, `compression` or `bg`, passed in `...` is used as
#' given, so `device = "pdf"`, `device = "eps"` or `device = "tiff"` restores
#' ggplot2's own behaviour.
#'
#' Which formats three publishers accepted on 2 October 2026:
#'
#' | Format | PLOS | Nature (final artwork) | Elsevier |
#' |:---|:---|:---|:---|
#' | PDF | No | Yes, as vector art | Yes |
#' | EPS | Yes, with fonts embedded | Yes, as vector art | Yes, with fonts embedded |
#' | TIFF | Yes, LZW-compressed RGB or greyscale, no alpha channel, at most 10 MB | No | Yes |
#'
#' Nature also asks for fonts embedded as TrueType 2 or 42, never Type 3, and
#' for line art and text that are not rasterised. A figure with translucent
#' layers therefore goes to Nature as a PDF. Elsevier asks for a graph sent as
#' a TIFF at 1000 dpi, so pass `dpi = 1000` for one.
#'
#' The Python twin takes the plot first, as `save_plot(plot, filename)`.
#'
#' @param filename Output file path. The extension sets the device (e.g. `.png`,
#'   `.pdf`, `.eps`, `.tiff`).
#' @param plot The plot to save; defaults to the last plot drawn.
#' @param width,height Dimensions.
#' @param units Units for `width` and `height`.
#' @param dpi Resolution for raster devices. An EPS rasterises its translucent
#'   layers, and whatever they overlap, at this resolution or at 600 dpi,
#'   whichever is higher.
#' @param ... Passed to [ggplot2::ggsave()], which passes what it does not use
#'   on to the device. A `device` or device argument given here overrides the
#'   defaults described under "Formats journals accept".
#'
#' @return The `filename`, invisibly.
#' @references
#' PLOS ONE. Figures. <https://journals.plos.org/plosone/s/figures>
#'
#' Nature. Guide to preparing final artwork.
#' <https://www.nature.com/documents/nature-final-artwork.pdf>
#'
#' Nature research figure guide. Preparing figures: our specifications.
#' <https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/>
#'
#' Elsevier. Artwork overview.
#' <https://www.elsevier.com/about/policies-and-standards/author/artwork-and-media-instructions/artwork-overview>
#' @export
#' @examples
#' p <- scatter_trend(crop_yield, fertiliser, yield)
#' tmp <- file.path(tempdir(), "yield.png")
#' save_plot(tmp, p)
#'
#' # A TIFF well within the 10 MB that PLOS allows.
#' save_plot(file.path(tempdir(), "yield.tiff"), p)
save_plot <- function(filename, plot = ggplot2::last_plot(),
                      width = 7, height = 4.5, units = "in", dpi = 300, ...) {
  dir <- dirname(filename)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  args <- list(...)
  format <- .file_format(filename)
  # The PDF and EPS devices record here whether cairo opened, so that the note
  # after saving describes the file that was written.
  opened <- new.env(parent = emptyenv())
  if (is.null(args[["device"]])) {
    if (identical(format, "pdf")) {
      args$device <- .journal_device("pdf", opened)
    } else if (format %in% c("eps", "ps")) {
      args$fallback_resolution <- args[["fallback_resolution"]] %||%
        max(.dpi_number(dpi), 600, na.rm = TRUE)
      args$device <- .journal_device("ps", opened)
    } else if (format %in% c("tif", "tiff")) {
      args$compression <- args[["compression"]] %||% "lzw"
      # ragg and the cairo TIFF device store an alpha channel whenever the
      # device background is transparent, as ggsave() makes it for
      # theme_void(), and PLOS refuses one. On white, the plot's own background
      # still covers the page.
      args$bg <- args[["bg"]] %||% "white"
      if (is.null(args[["type"]])) args$type <- .tiff_type()
    }
  }
  # Called through a closure so that the plot travels by name. do.call() would
  # otherwise write the whole plot object into the call it reports on error.
  save <- function(...) {
    ggplot2::ggsave(filename = filename, plot = plot, width = width,
                    height = height, units = units, dpi = dpi, ...)
  }
  do.call(save, args)
  .report_device(format, opened$device, plot, args[["fallback_resolution"]])
  invisible(filename)
}

# The lower-case extension of a file name, or "" when it has none.
.file_format <- function(filename) {
  base <- basename(filename)
  if (!grepl(".", base, fixed = TRUE)) return("")
  tolower(sub("^.*\\.", "", base))
}

# ggsave() also accepts a resolution by name. Anything else it cannot read
# becomes NA here, and ggsave() then reports the problem in its own words.
.dpi_number <- function(dpi) {
  if (is.numeric(dpi)) return(dpi)
  if (!is.character(dpi) || length(dpi) != 1) return(NA_real_)
  switch(dpi, retina = 320, print = 300, screen = 72, NA_real_)
}

# Kept apart so that the tests can take cairo away on a machine that has it.
.cairo_available <- function() isTRUE(capabilities("cairo"))

# A device function for ggsave() that opens cairo and, when cairo cannot open,
# the device ggplot2 would have used. Only a failure to open the device falls
# back, so an error in drawing the plot is still reported as the plot's own.
.journal_device <- function(format, opened) {
  force(format)
  function(filename, ...) {
    args <- list(...)
    if (.cairo_available()) {
      started <- tryCatch({
        .open_cairo(format, filename, args)
        TRUE
      }, error = function(e) FALSE)
      if (started) {
        opened$device <- "cairo"
        return(invisible(NULL))
      }
    }
    opened$device <- "fallback"
    .open_fallback(format, filename, args)
  }
}

.open_cairo <- function(format, filename, args) {
  if (identical(format, "pdf")) {
    do.call(grDevices::cairo_pdf, c(list(filename = filename), args))
  } else {
    # One page in Encapsulated PostScript, as ggplot2 asks of postscript().
    args$onefile <- args[["onefile"]] %||% FALSE
    do.call(grDevices::cairo_ps, c(list(filename = filename), args))
  }
}

# The devices ggplot2 uses for these extensions, opened as ggplot2 opens them.
.open_fallback <- function(format, filename, args) {
  cairo_only <- c("antialias", "fallback_resolution", "symbolfamily")
  args <- args[setdiff(names(args), cairo_only)]
  if (identical(format, "pdf")) {
    do.call(grDevices::pdf, c(list(file = filename), args))
  } else {
    eps <- list(onefile = FALSE, horizontal = FALSE, paper = "special")
    do.call(grDevices::postscript,
            c(list(file = filename), utils::modifyList(eps, args)))
  }
}

# A note on what the file holds, when that differs from what was asked for.
.report_device <- function(format, device, plot, resolution) {
  if (is.null(device)) return(invisible(NULL))
  if (identical(format, "pdf")) {
    if (identical(device, "fallback")) {
      message("The PDF was written with pdf(), so its fonts are not ",
              "embedded. Embed them before submission with ",
              "grDevices::embedFonts(), which needs Ghostscript.")
    }
    return(invisible(NULL))
  }
  kind <- if (identical(format, "eps")) "EPS" else "PostScript"
  if (identical(device, "fallback")) {
    warning("cairo_ps() could not be used, so the ", kind, " file was ",
            "written with postscript(), which leaves out translucent layers ",
            "and does not embed fonts. Save as PDF or TIFF to keep them.",
            call. = FALSE)
  } else if (.has_translucency(plot)) {
    # cairo rasterises the whole area a translucent layer covers, including
    # the lines and text drawn over it there.
    message(kind, " has no transparency, so the translucent layers, and ",
            "whatever they overlap, were rasterised at ", resolution, " dpi. ",
            "Journals that forbid rasterised line art, Nature among them, ",
            "take PDF.")
  }
  invisible(NULL)
}

# Whether any layer of a plot, or of any panel of a composite, draws with alpha
# below 1. A patchwork is itself its last panel, and keeps the others in
# `patches$plots`. The build repeats work ggsave() has done, so its messages
# and warnings, already shown once, are muffled.
.has_translucency <- function(plot) {
  if (inherits(plot, "patchwork") &&
      any(vapply(plot$patches$plots, .has_translucency, logical(1)))) {
    return(TRUE)
  }
  if (!inherits(plot, "ggplot")) return(FALSE)
  built <- tryCatch(
    suppressMessages(suppressWarnings(ggplot2::ggplot_build(plot))),
    error = function(e) NULL
  )
  if (is.null(built)) return(FALSE)
  any(vapply(seq_along(built$data), function(i) {
    .layer_translucent(built$plot$layers[[i]], built$data[[i]])
  }, logical(1)))
}

# A smoothing layer applies its alpha only to the confidence band, so without
# the band, as under `se = FALSE`, its alpha column describes nothing drawn.
.layer_translucent <- function(layer, data) {
  alpha <- data[["alpha"]]
  if (inherits(layer$geom, "GeomSmooth") && !.smooth_band(layer, data)) {
    alpha <- NULL
  }
  if (any(alpha > 0 & alpha < 1, na.rm = TRUE)) return(TRUE)
  for (aesthetic in c("colour", "fill")) {
    if (is.null(data[[aesthetic]])) next
    rgba <- tryCatch(grDevices::col2rgb(data[[aesthetic]], alpha = TRUE),
                     error = function(e) NULL)
    if (!is.null(rgba) && any(rgba[4, ] > 0 & rgba[4, ] < 255)) return(TRUE)
  }
  FALSE
}

.smooth_band <- function(layer, data) {
  se <- layer$computed_geom_params$se %||% layer$geom_params$se
  !isFALSE(se) && (all(c("ymin", "ymax") %in% names(data)) ||
                     all(c("xmin", "xmax") %in% names(data)))
}

# grDevices::tiff() ignores compression, with a warning, for the quartz type
# that macOS uses by default. ggsave() hands a TIFF to ragg when ragg is
# installed, and ragg compresses, so the cairo type is asked for only when
# grDevices::tiff() would otherwise draw with quartz.
.tiff_type <- function(ragg = requireNamespace("ragg", quietly = TRUE),
                       bitmap_type = getOption("bitmapType"),
                       cairo = .cairo_available()) {
  if (!ragg && identical(bitmap_type, "quartz") && cairo) "cairo" else NULL
}
