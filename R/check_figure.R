# Accessibility and honesty audit of a finished figure -----------------------
#
# The audit introspects a built plot rather than re-deriving what it thinks the
# plot ought to contain, which is the same idiom the test suite uses. That way
# it also sees whatever was added after depictr handed the plot back: a
# replacement scale, a different theme, an extra layer. Two passes over the
# build supply everything. The layer data give the colours that encode groups,
# and the rendered gtable gives the text that will actually be drawn, at the
# point size and in the colour it will be drawn in.

# WCAG 2.2 contrast floors, used as published rather than tuned so that any
# particular figure passes: 4.5:1 for text at normal size (success criterion
# 1.4.3) and 3:1 for graphical objects that carry meaning (1.4.11). They are
# fixed rather than arguments because they are somebody else's standard.
.wcag_text_contrast <- 4.5
.wcag_object_contrast <- 3

#' Audit a finished figure for accessibility and honesty
#'
#' Checks a figure as it will be submitted, rather than the palette it was built
#' from. [palette_safety()] can promise that the eight colours depictr ships
#' stay apart under colour-vision deficiency, but it knows nothing about the
#' figure in front of you: how many of those colours it uses, what you replaced
#' them with, how small the text will be once the figure is squeezed into a
#' journal column, or whether the only thing separating two groups is their
#' colour. `check_figure()` reads the built plot and answers those
#' questions with numbers.
#'
#' Every row carries the value it measured next to the threshold it was measured
#' against, so a verdict can be argued with rather than merely accepted. A check
#' passes when the measured value is at least the threshold. A check that has
#' nothing to measure, such as colour separability on a figure that encodes
#' nothing by colour, reports `NA` and a verdict of `"not applicable"` instead
#' of a free pass.
#'
#' @section What each check measures:
#' `colour_separability` is the smallest CIE76 colour difference (Delta-E)
#' between any two of the figure's encoding colours, and the three
#' `colour_separability_*` rows repeat that measurement after simulating each
#' dichromacy at full severity with [simulate_cvd()]. Encoding colours are the
#' distinct colour and fill values a layer uses to tell groups apart; a
#' continuous colour or fill scale is a smooth ramp rather than a set of codes,
#' so it is excluded.
#'
#' `greyscale_separability` is the smallest difference in CIE lightness between
#' those same colours, which is what survives printing in black and white.
#'
#' `text_size` is the smallest point size of any text the figure draws, after
#' scaling by `width_cm / render_width_cm`: a figure drawn seven inches wide and
#' printed in an 8.9 cm column has every point size halved. Text drawn inside
#' the panel, by a layer such as [ggplot2::geom_text()] or by an annotation, is
#' deliberately left out. It sits on the marks rather than on the background, so
#' there is no one background to measure its contrast against, and the two
#' engines size a layer's text in different units, which would leave the check
#' disagreeing with its Python twin on the same figure.
#'
#' `text_contrast` and `geometry_contrast` are the smallest WCAG 2.x contrast
#' ratios of, respectively, any drawn text against the plot background and any
#' encoding colour against the panel background.
#'
#' `redundant_encoding` counts how many of shape and line type also vary in a
#' layer whose colour varies. Zero means the distinction between groups is
#' carried by colour alone, which is the single most common way an otherwise
#' careful figure becomes unreadable.
#'
#' @section A limitation of the default palette:
#' The eight-colour qualitative palette clears the colour-separability checks
#' comfortably and fails `greyscale_separability`: its orange (`#e69f00`) and
#' sky blue (`#56b4e9`) differ by only 0.79 in lightness, so they print as the
#' same grey. The colourblind-safety guarantee depictr makes is about hue
#' confusion, and it was never a claim about greyscale. A figure that may be
#' printed in black and white should use fewer groups, or a sequential palette,
#' or add a redundant shape or line type; the four leading colours of the
#' palette are also not safe in greyscale, since the bluish green and the
#' vermillion differ by 3.55. The threshold has been left where it is rather
#' than moved to let the package's own defaults through.
#'
#' @param plot A plot, as returned by any depictr plotting function, including
#'   one extended afterwards with `+`. A multi-panel composite is refused: its
#'   panels have their own scales, themes and text, and one table of numbers
#'   cannot describe them all. Check each panel on its own.
#' @param width_cm The width, in centimetres, that the figure will occupy in the
#'   finished document. Defaults to 17.78 cm, the seven inches [save_plot()]
#'   draws at, which means no scaling.
#' @param render_width_cm The width, in centimetres, that the figure is drawn
#'   at. Defaults to the same 17.78 cm. The ratio of the two widths is the
#'   factor every point size is multiplied by.
#' @param min_delta_e The smallest acceptable CIE76 colour difference, used for
#'   the colour and greyscale separability checks. Defaults to 5, matching
#'   [palette_safety()].
#' @param min_text_pt The smallest acceptable printed text size, in points.
#'   Defaults to 6, a common publisher floor for figure text.
#'
#' @return A data frame with one row per check and columns `check`, `measured`,
#'   `threshold`, `verdict` (`"pass"`, `"fail"` or `"not applicable"`) and
#'   `detail`, a short note naming what produced the measurement.
#' @references
#' \insertRef{machado2009}{depictr}
#'
#' \insertRef{wcag22}{depictr}
#' @seealso [palette_safety()] for the palette in the abstract, and
#'   [palette_preview()] to look at it.
#' @export
#' @examples
#' library(ggplot2)
#'
#' # A figure that clears every check: two well-separated colours, a redundant
#' # shape, and text left at the size it was drawn.
#' good <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
#'                                shape = treatment)) +
#'   geom_point() +
#'   scale_colour_manual(values = c("#005b96", "#d55e00")) +
#'   theme_depictr()
#' check_figure(good)
#'
#' # The same figure destined for an 8.9 cm journal column, where the text is
#' # half the size it looks on screen.
#' check_figure(good, width_cm = 8.9)
check_figure <- function(plot, width_cm = 17.78, render_width_cm = 17.78,
                         min_delta_e = 5, min_text_pt = 6) {
  # A composite has several panels, each with its own scales, theme and text.
  # One table of numbers cannot describe them all, and the class inherits from
  # ggplot, so it would otherwise reach the build and fail obscurely.
  if (inherits(plot, "patchwork")) {
    stop("`plot` is a multi-panel composite. Check each panel on its own.",
         call. = FALSE)
  }
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a plot object, as returned by any depictr plotting ",
         "function.", call. = FALSE)
  }
  .positive_scalar(width_cm, "width_cm")
  .positive_scalar(render_width_cm, "render_width_cm")
  .positive_scalar(min_delta_e, "min_delta_e")
  .positive_scalar(min_text_pt, "min_text_pt")

  built <- ggplot2::ggplot_build(plot)
  resolved <- .completed_theme(built$plot$theme)
  plot_bg <- .element_background(
    ggplot2::calc_element("plot.background", resolved)) %||% "#ffffff"
  panel_bg <- .element_background(
    ggplot2::calc_element("panel.background", resolved)) %||% plot_bg

  encoding <- .figure_colour_encoding(built)
  text <- .figure_text(ggplot2::ggplot_gtable(built), resolved)

  rows <- c(
    .separability_rows(encoding$colours, min_delta_e),
    list(.text_size_row(text, width_cm, render_width_cm, min_text_pt)),
    list(.text_contrast_row(text, plot_bg)),
    list(.geometry_contrast_row(encoding$colours, panel_bg)),
    list(.redundant_encoding_row(encoding))
  )
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# --- validation -------------------------------------------------------------

#' @noRd
.positive_scalar <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
    stop("`", arg, "` must be a single positive number.", call. = FALSE)
  }
  invisible(TRUE)
}

# --- theme resolution -------------------------------------------------------

#' Fetch an exported ggplot2 object, or NULL where this ggplot2 has none
#'
#' Written this way rather than as a literal `ggplot2::complete_theme` because
#' the literal is a missing export against the declared ggplot2 floor, which
#' `R CMD check` reports as such under "checking dependencies in R code". This
#' reaches exports only, so it is not the `:::` that would also reach internals.
#' @noRd
.ggplot2_export <- function(name) {
  tryCatch(getExportedValue("ggplot2", name), error = function(e) NULL)
}

#' Resolve a plot's theme against the default and fill in what it omits
#'
#' [ggplot2::calc_element()] walks an element up its inheritance chain, so it
#' needs a theme that names every element rather than only the ones the plot
#' happens to set. ggplot2 4.0.0 exports `complete_theme()` for exactly that.
#' The declared floor is ggplot2 3.5.0, so below 4.0.0 the same completion is
#' assembled from the exported API by `.completed_theme_compat()`.
#' @noRd
.completed_theme <- function(theme) {
  complete_theme <- .ggplot2_export("complete_theme")
  if (is.null(complete_theme)) {
    .completed_theme_compat(theme)
  } else {
    complete_theme(theme)
  }
}

#' Theme completion for a ggplot2 that predates `complete_theme()`
#'
#' ggplot2's own documented completion, the `plot_theme()` that
#' `complete_theme()` is a wrapper around. A complete theme replaces the active
#' default outright and only has its gaps filled from it, an incomplete one is
#' added to that default, and either way whatever is still unnamed comes from
#' `theme_grey()`, the fallback ggplot2 registers at load and restores in
#' `reset_theme_settings()`.
#'
#' An extension that has called `register_theme_elements()` adds its own
#' elements to that fallback, which this cannot see. Those elements are the
#' extension's own, and the audit asks only for `plot.background`,
#' `panel.background` and `text`.
#' @noRd
.completed_theme_compat <- function(theme) {
  default <- ggplot2::theme_get()
  theme <- theme %||% ggplot2::theme()
  if (isTRUE(attr(theme, "complete", exact = TRUE))) {
    # Merging element by element would let the default's settings show through a
    # theme that deliberately dropped them, so a complete theme is only topped
    # up with the elements it does not name at all.
    absent <- setdiff(names(default), names(theme))
    theme[absent] <- default[absent]
  } else {
    theme <- default + theme
  }
  fallback <- ggplot2::theme_grey()
  absent <- setdiff(names(fallback), names(theme))
  theme[absent] <- fallback[absent]
  attr(theme, "complete") <- TRUE
  # The result is assembled from themes already validated on their way in, and
  # ggplot2 exports no element validator, so revalidation is neither possible
  # nor wanted here. `complete_theme()` clears the flag for the same reason.
  attr(theme, "validate") <- FALSE
  theme
}

# --- colour bookkeeping -----------------------------------------------------

#' Normalise colours to lower-case six-digit hex, dropping what cannot be seen
#'
#' Anything missing, unparseable or fully transparent is removed rather than
#' carried through as a colour, since it encodes nothing. The result is the same
#' canonical form the Python twin produces, so the two can be compared directly.
#' @noRd
.as_hex <- function(cols) {
  cols <- as.character(cols)
  cols <- cols[!is.na(cols) & nzchar(cols) & cols != "NA"]
  if (!length(cols)) return(character(0))
  parsed <- lapply(cols, function(x) {
    tryCatch(grDevices::col2rgb(x, alpha = TRUE), error = function(e) NULL)
  })
  parsed <- parsed[!vapply(parsed, is.null, logical(1))]
  if (!length(parsed)) return(character(0))
  rgba <- do.call(cbind, parsed)
  rgba <- rgba[, rgba[4, ] > 0, drop = FALSE]
  if (!ncol(rgba)) return(character(0))
  tolower(grDevices::rgb(rgba[1, ], rgba[2, ], rgba[3, ], maxColorValue = 255))
}

#' The fill of a background element, or NULL when nothing is painted
#' @noRd
.element_background <- function(element) {
  if (is.null(element) || inherits(element, "element_blank")) return(NULL)
  hex <- .as_hex(element$fill)
  if (!length(hex)) NULL else hex[[1]]
}

#' WCAG 2.x contrast ratio between two colours
#'
#' `(L1 + 0.05) / (L2 + 0.05)`, with the lighter of the two relative luminances
#' on top, so the ratio runs from 1 (identical) to 21 (black on white).
#' @noRd
.contrast_ratio <- function(a, b) {
  la <- .relative_luminance(a)
  lb <- .relative_luminance(b)
  (pmax(la, lb) + 0.05) / (pmin(la, lb) + 0.05)
}

#' The colours a figure uses to tell groups apart, and what else varies with them
#'
#' A colour or fill counts as encoding when a single layer draws more than one
#' of them and the scale behind it is discrete. A continuous scale is a smooth
#' ramp, where neighbouring colours are meant to be close, so measuring the
#' distance between them would only ever say that a gradient is a gradient.
#'
#' @return A list with `colours` (canonical hex, sorted so that a tie between
#'   two equally close pairs resolves the same way in both engines) and
#'   `redundant`, the names of the non-colour channels that vary alongside them.
#' @noRd
.figure_colour_encoding <- function(built) {
  continuous <- character(0)
  for (scale in built$plot$scales$scales) {
    if (!isTRUE(scale$is_discrete())) {
      continuous <- union(continuous, scale$aesthetics)
    }
  }
  varies <- function(layer_data, aesthetic) {
    if (!aesthetic %in% names(layer_data)) return(FALSE)
    values <- layer_data[[aesthetic]]
    length(unique(values[!is.na(values)])) >= 2
  }

  colours <- character(0)
  redundant <- character(0)
  for (index in seq_along(built$data)) {
    layer_data <- built$data[[index]]
    # A text layer's colour is chosen for legibility against whatever it sits
    # on, not to code a group, so counting it would report the distance between
    # black and white labels as though it were the distance between categories.
    if (.is_text_layer(built$plot$layers[[index]])) next
    encodes <- FALSE
    for (aesthetic in c("colour", "fill")) {
      if (aesthetic %in% continuous || !varies(layer_data, aesthetic)) next
      # Distinct after normalisation: two spellings of one colour are one
      # colour, and a layer that draws only that encodes nothing.
      hex <- unique(.as_hex(unique(layer_data[[aesthetic]])))
      if (length(hex) < 2) next
      colours <- union(colours, hex)
      encodes <- TRUE
    }
    if (!encodes) next
    also <- c("shape", "linetype")[
      vapply(c("shape", "linetype"), function(a) varies(layer_data, a),
             logical(1))
    ]
    if (length(also) > length(redundant)) redundant <- also
  }
  # Radix order is byte order, which is what Python's sorted() gives, so the two
  # engines pick the same pair when two are equally close.
  list(colours = sort(unique(colours), method = "radix"), redundant = redundant)
}

# --- text bookkeeping -------------------------------------------------------

#' Is this layer one that draws text?
#' @noRd
.is_text_layer <- function(layer) {
  inherits(layer$geom, "GeomText") || inherits(layer$geom, "GeomLabel")
}

#' Every piece of text the figure will actually draw
#'
#' Walks the rendered gtable for text grobs, which is the only place the
#' resolved point size and colour of a label exist: the theme states some of
#' them relatively, and a grob that is never drawn never appears here at all, so
#' an unused element cannot drag the measurement down.
#'
#' The panel cells are skipped, which is what leaves layer and annotation text
#' out of the measurement. An inside legend sits in a cell of its own rather
#' than in the panel, so it is still counted.
#'
#' @return A data frame of `size` (points) and `colour` (hex), or `NULL` when the
#'   figure draws no text.
#' @noRd
.figure_text <- function(gt, resolved) {
  base <- ggplot2::calc_element("text", resolved)
  found <- list()
  walk <- function(grob) {
    if (is.null(grob)) return(invisible(NULL))
    if (inherits(grob, "gtable")) {
      cells <- grob$layout$name %||% rep_len("", length(grob$grobs))
      for (index in seq_along(grob$grobs)) {
        if (startsWith(cells[[index]], "panel")) next
        walk(grob$grobs[[index]])
      }
    } else if (inherits(grob, "gTree")) {
      for (child in grob$children) walk(child)
    }
    if (!inherits(grob, "text")) return(invisible(NULL))
    labels <- as.character(grob$label)
    if (!length(labels) || !any(nzchar(trimws(labels)))) {
      return(invisible(NULL))
    }
    # A single grob can carry a vector of sizes or colours, one per label, so
    # both are recycled to the same length rather than reduced to their first
    # element and quietly losing the smallest or the palest.
    sizes <- as.numeric(grob$gp$fontsize %||% base$size) *
      as.numeric(grob$gp$cex %||% 1)
    colours <- .as_hex(grob$gp$col %||% base$colour %||% "black")
    sizes <- sizes[is.finite(sizes)]
    if (!length(sizes) || !length(colours)) return(invisible(NULL))
    n <- max(length(sizes), length(colours))
    found[[length(found) + 1L]] <<- data.frame(
      size = rep_len(sizes, n), colour = rep_len(colours, n),
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
  walk(gt)
  if (!length(found)) return(NULL)
  do.call(rbind, found)
}

# --- rows -------------------------------------------------------------------

#' @noRd
.verdict <- function(measured, threshold) {
  if (is.na(measured)) return("not applicable")
  if (measured >= threshold) "pass" else "fail"
}

#' @noRd
.check_row <- function(check, measured, threshold, detail) {
  data.frame(
    check = check,
    measured = if (is.na(measured)) NA_real_ else round(measured, 2),
    threshold = threshold,
    verdict = .verdict(measured, threshold),
    detail = detail,
    stringsAsFactors = FALSE
  )
}

# What every colour-dependent check says when the figure encodes nothing by
# colour. Shared so the two halves of the sentence cannot drift apart.
.no_colour_detail <- "No two encoding colours: nothing is distinguished by colour."

# Fixed two decimals, so a number embedded in a detail string reads the same
# here as in the Python twin's f-string.
#' @noRd
.fmt <- function(x) formatC(x, format = "f", digits = 2)

#' The four colour rows plus the greyscale row
#' @noRd
.separability_rows <- function(colours, min_delta_e) {
  check_names <- c("colour_separability", "colour_separability_protan",
                   "colour_separability_deutan", "colour_separability_tritan")
  conditions <- c("normal", names(.cvd_matrices))
  if (length(colours) < 2) {
    rows <- lapply(check_names, function(nm) {
      .check_row(nm, NA_real_, min_delta_e, .no_colour_detail)
    })
    rows[[length(rows) + 1L]] <- .check_row(
      "greyscale_separability", NA_real_, min_delta_e, .no_colour_detail)
    return(rows)
  }
  rows <- Map(function(nm, condition) {
    seen <- if (condition == "normal") colours else {
      simulate_cvd(colours, condition)
    }
    closest <- .min_pairwise_delta_e(seen)
    pair <- colours[closest$pair]
    .check_row(nm, closest$distance, min_delta_e, sprintf(
      "Closest pair %s and %s of %d encoding colours.",
      pair[[1]], pair[[2]], length(colours)))
  }, check_names, conditions)
  # Lightness is what a black-and-white printer keeps, and CIE L* is a function
  # of luminance alone, so the greyscale difference between two colours is the
  # CIE76 distance between their lightnesses.
  lightness <- .srgb_to_lab(colours)[, "L"]
  grey <- .min_pairwise_delta_e_1d(lightness)
  pair <- colours[grey$pair]
  rows[[length(rows) + 1L]] <- .check_row(
    "greyscale_separability", grey$distance, min_delta_e, sprintf(
      "Closest pair %s and %s in CIE lightness.", pair[[1]], pair[[2]]))
  unname(rows)
}

#' Smallest pairwise gap in a single dimension, walked in the twin's order
#' @noRd
.min_pairwise_delta_e_1d <- function(values) {
  n <- length(values)
  best <- Inf
  pair <- c(1L, 1L)
  for (i in seq_len(n - 1)) {
    for (j in seq(i + 1, n)) {
      d <- abs(values[[i]] - values[[j]])
      if (d < best) {
        best <- d
        pair <- c(i, j)
      }
    }
  }
  list(distance = best, pair = pair)
}

#' @noRd
.text_size_row <- function(text, width_cm, render_width_cm, min_text_pt) {
  if (is.null(text)) {
    return(.check_row("text_size", NA_real_, min_text_pt,
                      "The figure draws no text."))
  }
  nominal <- min(text$size)
  .check_row("text_size", nominal * width_cm / render_width_cm, min_text_pt,
             sprintf("Smallest text %s pt, drawn at %s cm and printed at %s cm.",
                     .fmt(nominal), .fmt(render_width_cm), .fmt(width_cm)))
}

#' @noRd
.text_contrast_row <- function(text, background) {
  if (is.null(text)) {
    return(.check_row("text_contrast", NA_real_, .wcag_text_contrast,
                      "The figure draws no text."))
  }
  ratios <- .contrast_ratio(text$colour, background)
  worst <- which.min(ratios)
  .check_row("text_contrast", ratios[[worst]], .wcag_text_contrast,
             sprintf("Lowest-contrast text %s on %s.",
                     text$colour[[worst]], background))
}

#' @noRd
.geometry_contrast_row <- function(colours, background) {
  if (!length(colours)) {
    return(.check_row("geometry_contrast", NA_real_, .wcag_object_contrast,
                      .no_colour_detail))
  }
  ratios <- .contrast_ratio(colours, background)
  worst <- which.min(ratios)
  .check_row("geometry_contrast", ratios[[worst]], .wcag_object_contrast,
             sprintf("Lowest-contrast colour %s on %s.",
                     colours[[worst]], background))
}

#' @noRd
.redundant_encoding_row <- function(encoding) {
  if (length(encoding$colours) < 2) {
    return(.check_row("redundant_encoding", NA_real_, 1, .no_colour_detail))
  }
  channels <- encoding$redundant
  detail <- if (length(channels)) {
    sprintf("Colour is joined by %s.", paste(channels, collapse = " and "))
  } else {
    "Colour alone distinguishes the groups."
  }
  .check_row("redundant_encoding", length(channels), 1, detail)
}
