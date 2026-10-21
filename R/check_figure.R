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
# particular figure passes: 4.5:1 for text at normal size and 3:1 for
# large-scale text (success criterion 1.4.3), and 3:1 for graphical objects that
# carry meaning (1.4.11). WCAG defines large-scale text as at least 18 point, or
# 14 point in bold. They are fixed rather than arguments because they are
# somebody else's standard.
.wcag_text_contrast <- 4.5
.wcag_large_text_contrast <- 3
.wcag_large_text_pt <- 18
.wcag_large_bold_text_pt <- 14
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
#' passes when the measured value is at least the threshold. The one exception
#' is `text_size_max`, a ceiling added when `max_text_pt` is given, which
#' passes when the measured value is at most its threshold. A check that has
#' nothing to measure, such as colour separability on a figure that encodes
#' nothing by colour, reports `NA` and a verdict of `"not applicable"` instead
#' of a free pass.
#'
#' @section What each check measures:
#' Colours and text are measured as drawn. A translucent colour is composited
#' over the background it is drawn on with the alpha it is drawn with, so it is
#' measured as the paler colour the reader sees. As ggplot2 draws them, bars,
#' tiles, areas, densities, ribbons, polygons, violins, boxplots, crossbars and
#' smooths apply a layer's alpha to their fill and leave the outline opaque.
#' Lines, paths, segments, error bars and reference lines apply it to their
#' colour, and points apply it to both. Any other geom is taken to apply it to
#' both, the cautious assumption. A colour that carries its own alpha keeps it
#' when the layer sets none, as ggplot2 draws it. A colour drawn at several
#' alphas within one layer is measured at the smallest. Where marks overlap
#' one another, the colour that shows depends on what lies beneath it, and
#' that is not measured.
#'
#' `colour_separability` is the smallest colour difference between two of the
#' figure's encoding colours, by the CIEDE2000 formula (Sharma, Wu & Dalal,
#' 2005) unless `metric` asks for CIE76. The three
#' `colour_separability_*` rows repeat that measurement after simulating each
#' dichromacy at full severity with [simulate_cvd()]. Encoding colours are the
#' distinct colour and fill values that tell groups apart. A layer contributes
#' its colours when it maps colour or fill to a discrete scale, even if it
#' draws a single colour, or when it draws two or more. Groups drawn one per
#' layer are therefore audited as they would be in one layer. A colour set as a
#' constant, as in `geom_point(colour = "red")`, is left out, even when another
#' layer sets a different one, and so is a lone colour passed through
#' [ggplot2::scale_colour_identity()]. The audit cannot tell such a colour from
#' decoration, so a colour meant to tell groups apart should be mapped, with
#' [ggplot2::scale_colour_manual()] to fix its values. The outline colours,
#' across every layer, are compared among themselves, and so are the fill
#' colours, and the row reports the closest pair from either set. An outline is
#' therefore never compared with its own fill, nor a group with itself as
#' another layer draws it.
#'
#' A continuous colour or fill scale, such as that of a heatmap, is a smooth
#' ramp rather than a set of codes, and none of the colour rows audits it. When
#' nothing else in the figure encodes by colour, each of them abstains with a
#' `detail` that says so. Whether a ramp reads in order, to a reader with a
#' colour-vision deficiency and in greyscale as well, depends on how evenly its
#' lightness changes, which the audit does not measure. Prefer a perceptually
#' ordered map, such as viridis or depictr's sequential and diverging ramps,
#' over a rainbow (Crameri et al., 2020).
#'
#' `greyscale_separability` is the smallest difference in CIE lightness between
#' those same colours, which is what survives printing in black and white. It
#' is the absolute difference in lightness, whichever `metric` the colour rows
#' use.
#'
#' `text_size` is the smallest point size of the text the theme draws around
#' the panel: axis labels and titles, legends, facet strips, titles and
#' captions. It is scaled by `width_cm / render_width_cm`, so a figure drawn
#' seven inches wide and printed in an 8.9 cm column has every point size
#' halved. Text drawn inside the panel is measured by `annotation_text_size`.
#'
#' `text_contrast` is the WCAG 2.2 contrast ratio of the text that falls
#' furthest short of its own threshold. Each text is measured against the
#' background it is drawn on: a facet strip's fill for strip text, the legend
#' box's fill for legend text, and the plot background for the rest. A
#' translucent fill is measured as the colour it shows over what lies beneath
#' it, and so is text drawn with an alpha. Text that is large at its printed
#' size, 18 pt or 14 pt in bold, is held to 3:1, and other text to 4.5:1, as
#' success criterion 1.4.3 asks. The row's `threshold` is the one that applies
#' to the text it reports, and its `detail` names that text's colour,
#' background, printed size and weight.
#'
#' `geometry_contrast` is the smallest WCAG 2.2 contrast ratio of any encoded
#' group's drawn colour against the panel background, or against the plot
#' background where the panel paints none. Where a layer maps its outline
#' colour to the same groups as its fill, each group counts the better of the
#' two, since WCAG lets a border carry a graphical object's contrast. For a
#' translucent colour, the `detail` names the colour, its alpha and the colour
#' it is drawn as.
#'
#' `redundant_encoding` counts how many of shape and line type also vary
#' across the layers that draw the encoding colours. They are gathered as the
#' colours are. A layer contributes the values it maps to a discrete scale, or
#' the two or more it draws, and a shape or line type set as a constant is left
#' out. Zero means the distinction between groups is carried by colour alone,
#' which is the single most common way an otherwise careful figure becomes
#' unreadable.
#'
#' `annotation_text_size` is the smallest point size of the text drawn inside
#' the panel, scaled as `text_size` is and held to the same `min_text_pt`. That
#' text comes from layers such as [ggplot2::geom_text()] and
#' [ggplot2::geom_label()], from annotations, and from depictr's own cell values
#' and labels. Its contrast is not measured, since it sits on the marks rather
#' than on one background. A label that a layer builds only when the figure is
#' drawn, as ggrepel builds its repelled labels, is not yet in the built plot,
#' so it is not measured either.
#'
#' `text_size_max` is reported only when `max_text_pt` is given, as the last
#' row. It is the largest point size of all the text measured, around the
#' panel and inside it, scaled as `text_size` is. It is the one row that
#' passes at or below its threshold.
#'
#' @section Limitations of the default palette:
#' The eight-colour qualitative palette clears the colour-separability checks
#' comfortably and fails `greyscale_separability`: its orange (`#e69f00`) and
#' sky blue (`#56b4e9`) differ by only 0.79 in lightness, so they print as the
#' same grey. The colourblind-safety guarantee depictr makes is about hue
#' confusion, and it was never a claim about greyscale. A figure that may be
#' printed in black and white should use fewer groups, or a sequential palette,
#' or add a redundant shape or line type; the four leading colours of the
#' palette are also not safe in greyscale, since the bluish green and the
#' vermillion differ by 3.55. The threshold is not lowered to let the package's
#' own defaults through.
#'
#' The palette falls short on contrast as well. Four of its eight colours are
#' below the 3:1 against white that WCAG asks of a graphical object: the orange
#' at 2.25:1, the sky blue at 2.31:1, the grey at 2.85:1 and the yellow at
#' 1.32:1. The orange is the second colour, so a default figure on white whose
#' colour tells two or more groups apart fails `geometry_contrast`, and drawing
#' its marks translucent lowers the ratio further. Opaque marks, the vermillion
#' (`#d55e00`, at 3.87:1) in the orange's place and a redundant shape clear
#' that row and `redundant_encoding`, as the first example below shows. The
#' contrast-first order of [depictr_palette()] puts the vermillion second and
#' the reddish purple third, and [scale_colour_depictr()] takes it as
#' `order = "contrast"`. Up to three groups then pass every colour row, and
#' four keep 3:1 against white.
#'
#' @section Auditing at the printed size:
#' Text is drawn in points, so the size it prints at depends on the two widths.
#' A figure drawn at the size it will be printed, as `save_plot()` draws one
#' given `width = 8.9, units = "cm"`, needs no scaling. Pass the saved width as
#' both `width_cm` and `render_width_cm`, or leave both at their defaults.
#' Given alone, `width_cm` audits the figure as though it had been drawn seven
#' inches wide and then shrunk to fit. [save_plot()] with `check = TRUE` audits
#' a figure at the width it saves it at, given as both.
#'
#' The default `min_text_pt` of 6 is lenient. As their guidelines stood on 30
#' September 2026, PLOS asked for text of 8 to 12 pt and APA Style for 8 to 14
#' pt. Elsevier asked for 7 pt as a rule of thumb, and Nature for 5 to 7 pt,
#' with panel labels at 8 pt. Pass the floor of the journal the figure is for
#' as `min_text_pt`, and its ceiling, where it sets one, as `max_text_pt`.
#' Nature's 7 pt applies to all text but the panel labels. The tags of a
#' composite, where patchwork puts them, are not measured, but a panel label
#' drawn as a panel's title or annotation is measured with the rest. The four
#' pages are listed under References.
#'
#' @section Composites:
#' A composite, such as [arrange_plots()], [residual_diagnostics_plot()] and
#' [model_report()] return, is audited panel by panel. Each panel has its own
#' scales, theme and text, so each is audited as it would be on its own. The
#' reports are stacked under a leading integer column, `panel`, which only the
#' report of a composite has. The widths are those of the whole composite. A
#' panel's text keeps its point size whatever share of the width the panel
#' takes, so the text of every panel scales by the same ratio.
#'
#' Panels are numbered depth-first through any composite nested inside, in the
#' order the composite holds them. That is the order patchwork tags them in,
#' and the reading order of a grid filled row by row. A spacer or a guide area
#' draws no figure of its own and takes no number. A wrapped element, such as
#' a grob or a table, cannot be read, so it keeps its number and is left out
#' of the report with a warning.
#'
#' A panel's legend is measured with the panel, as the panel would draw it on
#' its own, even when `guides = "collect"` gathers it into one legend for the
#' composite. What the composite draws around its panels is not measured: the
#' title, subtitle and caption of [patchwork::plot_annotation()] and the panel
#' tags.
#'
#' @param plot A plot, as returned by any depictr plotting function, including
#'   one extended afterwards with `+`, or a multi-panel composite (see
#'   "Composites").
#' @param width_cm The width, in centimetres, that the figure will occupy in the
#'   finished document. Defaults to 17.78 cm, the seven inches [save_plot()]
#'   draws at, which means no scaling.
#' @param render_width_cm The width, in centimetres, that the figure is drawn
#'   at. Defaults to the same 17.78 cm. The ratio of the two widths is the
#'   factor every point size is multiplied by.
#' @param min_delta_e The smallest acceptable colour difference, on the scale
#'   of `metric`, for the colour separability checks, and the smallest
#'   acceptable difference in lightness for the greyscale check. Defaults to 5,
#'   matching [palette_safety()].
#' @param min_text_pt The smallest acceptable printed text size, in points,
#'   for the text around the panel and the text inside it alike. Defaults to
#'   6, below the floor most journals set (see "Auditing at the printed
#'   size").
#' @param metric The colour difference the colour separability checks measure:
#'   `"ciede2000"`, the default, or `"cie76"`, the Euclidean distance in CIELAB.
#'   `"cie76"` is kept so that results computed with it can be reproduced, and
#'   a later release will remove it.
#' @param max_text_pt The largest acceptable printed text size, in points, or
#'   `NULL`, the default, for no ceiling. When given, a `text_size_max` row is
#'   appended (see "What each check measures").
#'
#' @return A data frame with one row per check and columns `check`, `measured`,
#'   `threshold`, `verdict` (`"pass"`, `"fail"` or `"not applicable"`) and
#'   `detail`, a short note naming what produced the measurement. There are
#'   ten rows, and an eleventh, `text_size_max`, when `max_text_pt` is given.
#'   For a composite, the rows of each panel in turn, after a leading integer
#'   column `panel`.
#' @references
#' APA Style. Figures.
#' <https://apastyle.apa.org/style-grammar-guidelines/tables-figures/figures>
#'
#' \insertRef{crameri2020}{depictr}
#'
#' Elsevier. Artwork sizing.
#' <https://www.elsevier.com/about/policies-and-standards/author/artwork-and-media-instructions/artwork-sizing>
#'
#' \insertRef{machado2009}{depictr}
#'
#' Nature. Guide to preparing final artwork.
#' <https://www.nature.com/documents/nature-final-artwork.pdf>
#'
#' PLOS ONE. Figures. <https://journals.plos.org/plosone/s/figures>
#'
#' \insertRef{sharma2005}{depictr}
#'
#' \insertRef{wcag22}{depictr}
#' @seealso [palette_safety()] for the palette in the abstract, and
#'   [palette_preview()] to look at it.
#' @export
#' @examples
#' library(ggplot2)
#'
#' # A figure that clears every check it can be held to: two well-separated
#' # colours, a redundant shape, and text left at the size it was drawn. It
#' # draws no text inside the panel, so that row is not applicable.
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
#'
#' # Saved at 8.9 cm in the first place, with save_plot(width = 8.9,
#' # units = "cm"), it is drawn at the size it prints, so both widths are 8.9.
#' check_figure(good, width_cm = 8.9, render_width_cm = 8.9)
#'
#' # Nature allowed no text above 7 pt but the panel labels. The axis titles
#' # here are 11 pt, so the ceiling row fails.
#' subset(check_figure(good, max_text_pt = 7), check == "text_size_max")
#'
#' # Each panel of a composite is audited, and a column says which panel each
#' # row describes. At base size 5, the second panel's text is too small.
#' small <- good + theme_depictr(base_size = 5)
#' both <- check_figure(arrange_plots(good, small))
#' both[both$verdict == "fail", c("panel", "check", "measured")]
check_figure <- function(plot, width_cm = 17.78, render_width_cm = 17.78,
                         min_delta_e = 5, min_text_pt = 6,
                         metric = c("ciede2000", "cie76"),
                         max_text_pt = NULL) {
  # A patchwork inherits from ggplot, since it is its last panel with the
  # others attached, so it is told apart before the build sees it.
  composite <- inherits(plot, "patchwork")
  if (!composite && !inherits(plot, "ggplot")) {
    stop("`plot` must be a plot object, as returned by any depictr plotting ",
         "function.", call. = FALSE)
  }
  .positive_scalar(width_cm, "width_cm")
  .positive_scalar(render_width_cm, "render_width_cm")
  .positive_scalar(min_delta_e, "min_delta_e")
  .positive_scalar(min_text_pt, "min_text_pt")
  if (!is.null(max_text_pt)) .positive_scalar(max_text_pt, "max_text_pt")
  metric <- match.arg(metric)

  if (composite) {
    return(.audit_composite(plot, width_cm, render_width_cm, min_delta_e,
                            min_text_pt, metric, max_text_pt))
  }
  .audit_plot(plot, width_cm, render_width_cm, min_delta_e, min_text_pt,
              metric, max_text_pt)
}

# --- composites -------------------------------------------------------------

#' The panels of a composite, depth-first in the order it holds them
#'
#' Reached through patchwork's exported `length()` and `[[` methods alone, so
#' the walk does not depend on how a patchwork stores its plots. `[[` hands
#' back a nested composite whole, and the walk descends into it where it
#' stands, which is the order patchwork tags the panels in. A spacer and a
#' guide area draw no figure of their own, and patchwork tags neither, so
#' neither is a panel.
#' @return A list of the panels.
#' @noRd
.composite_panels <- function(plot) {
  panels <- list()
  for (index in seq_len(length(plot))) {
    panel <- plot[[index]]
    if (inherits(panel, "patchwork")) {
      panels <- c(panels, .composite_panels(panel))
    } else if (!inherits(panel, c("spacer", "guide_area"))) {
      panels[[length(panels) + 1L]] <- panel
    }
  }
  panels
}

#' Each panel of a composite audited on its own, under a panel column
#'
#' The composite's title, subtitle and tags belong to no panel, so they are
#' not measured. The Python twin numbers the panels of a plotnine composition
#' by the same rule.
#' @noRd
.audit_composite <- function(plot, width_cm, render_width_cm, min_delta_e,
                             min_text_pt, metric, max_text_pt = NULL) {
  panels <- .composite_panels(plot)
  reports <- list()
  for (number in seq_along(panels)) {
    panel <- panels[[number]]
    # A wrapped grob, table or base R plot is carried by an empty plot of
    # patchwork's own, a "patch", and drawn from grobs that the build of that
    # plot never sees. Audited as the plot, it would read as a panel with no
    # text and no colours.
    if (inherits(panel, "patch")) {
      warning("Panel ", number, " is a wrapped element, such as a grob or a ",
              "table, which check_figure() cannot read, so the report leaves ",
              "it out.", call. = FALSE)
      next
    }
    report <- .audit_plot(panel, width_cm, render_width_cm, min_delta_e,
                          min_text_pt, metric, max_text_pt)
    reports[[length(reports) + 1L]] <- cbind(panel = number, report)
  }
  if (!length(reports)) {
    return(data.frame(panel = integer(0), check = character(0),
                      measured = numeric(0), threshold = numeric(0),
                      verdict = character(0), detail = character(0),
                      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, reports)
  rownames(out) <- NULL
  out
}

# --- one plot ---------------------------------------------------------------

#' The audit of a single plot, its settings already validated
#'
#' The ceiling row is appended only when `max_text_pt` is given, so the report
#' asked for without one keeps its ten rows.
#' @noRd
.audit_plot <- function(plot, width_cm, render_width_cm, min_delta_e,
                        min_text_pt, metric, max_text_pt = NULL) {
  built <- ggplot2::ggplot_build(plot)
  resolved <- .completed_theme(built$plot$theme)
  # White stands in for the paper under a plot background that paints nothing.
  plot_bg <- .element_background(
    ggplot2::calc_element("plot.background", resolved), "#ffffff") %||%
    "#ffffff"
  panel_bg <- .element_background(
    ggplot2::calc_element("panel.background", resolved), plot_bg) %||% plot_bg

  # Marks are drawn on the panel, so a translucent one shows the panel through.
  encoding <- .figure_colour_encoding(built, panel_bg)
  gt <- ggplot2::ggplot_gtable(built)
  text <- .figure_text(gt, resolved, plot_bg)
  panel_text <- .figure_text(gt, resolved, panel_bg, panel = TRUE)
  # A figure whose only text is inside the panel does draw text, just none that
  # the two rows for the theme's text measure.
  no_text <- if (is.null(panel_text)) {
    "The figure draws no text."
  } else {
    "The figure draws no text outside the panel."
  }

  rows <- c(
    .separability_rows(encoding$sets, min_delta_e, metric, encoding$abstain),
    list(.smallest_text_row("text_size", text, width_cm, render_width_cm,
                            min_text_pt, "text", no_text)),
    list(.text_contrast_row(text, width_cm, render_width_cm, no_text)),
    list(.geometry_contrast_row(encoding$marks, panel_bg, encoding$abstain)),
    list(.redundant_encoding_row(encoding)),
    list(.smallest_text_row("annotation_text_size", panel_text, width_cm,
                            render_width_cm, min_text_pt, "in-panel text",
                            "The figure draws no text inside the panel."))
  )
  if (!is.null(max_text_pt)) {
    rows <- c(rows, list(.largest_text_row(c(text$size, panel_text$size),
                                           width_cm, render_width_cm,
                                           max_text_pt)))
  }
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
#' The declared floor is ggplot2 3.5.2, so below 4.0.0 the same completion is
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

#' Parse colours into canonical hex and their own alpha
#'
#' Anything missing or unparseable is dropped, since it draws nothing. The hex
#' is lower-case and six-digit, the canonical form the Python twin produces, so
#' the two can be compared directly. The colour's own alpha is kept beside it,
#' in `[0, 1]`, for the caller to decide how it is drawn.
#' @return A data frame of `value` (the colour as given), `hex` and `alpha`,
#'   one row per colour that parsed, or `NULL` when none did.
#' @noRd
.parse_colours <- function(cols) {
  cols <- as.character(cols)
  cols <- cols[!is.na(cols) & nzchar(cols) & cols != "NA"]
  if (!length(cols)) return(NULL)
  parsed <- lapply(cols, function(x) {
    tryCatch(grDevices::col2rgb(x, alpha = TRUE), error = function(e) NULL)
  })
  ok <- !vapply(parsed, is.null, logical(1))
  if (!any(ok)) return(NULL)
  rgba <- do.call(cbind, parsed[ok])
  data.frame(
    value = cols[ok],
    hex = tolower(grDevices::rgb(rgba[1, ], rgba[2, ], rgba[3, ],
                                 maxColorValue = 255)),
    alpha = rgba[4, ] / 255,
    stringsAsFactors = FALSE
  )
}

#' A colour as drawn over a background, given its alpha
#'
#' Each channel, scaled to run from 0 to 1, is
#' `alpha * colour + (1 - alpha) * background`,
#' then scaled to 8 bits with `floor(255 * drawn + 0.5)`. The Python twin does
#' the same arithmetic in the same order, so the two agree to the last bit. A
#' library that rounds half to even would disagree with it at some alphas.
#' `alpha` multiplies the colour's own alpha, as grid's `gpar(alpha)` does.
#' @return Lower-case six-digit hex, one per colour.
#' @noRd
.composite <- function(colour, background, alpha = 1) {
  fg <- grDevices::col2rgb(colour, alpha = TRUE) / 255
  a <- fg[4, ] * alpha
  bg <- as.numeric(grDevices::col2rgb(background)) / 255
  drawn <- sweep(fg[1:3, , drop = FALSE], 2, a, `*`) + outer(bg, 1 - a)
  channels <- floor(255 * drawn + 0.5)
  tolower(grDevices::rgb(channels[1, ], channels[2, ], channels[3, ],
                         maxColorValue = 255))
}

#' The colour a fill paints over its parent background, or NULL if it paints
#' nothing
#'
#' A translucent fill is composited over the background it is drawn on, so a
#' half-transparent black strip on white is measured as the grey it shows.
#' @noRd
.painted <- function(fill, parent, alpha = NULL) {
  fill <- as.character(fill)
  if (!length(fill) || is.na(fill[[1]]) || !nzchar(fill[[1]])) return(NULL)
  rgba <- tryCatch(grDevices::col2rgb(fill[[1]], alpha = TRUE),
                   error = function(e) NULL)
  alpha <- alpha %||% 1
  if (is.null(rgba) || rgba[4, 1] * alpha[[1]] == 0) return(NULL)
  .composite(fill[[1]], parent, alpha[[1]])
}

#' The colour a background element paints over its parent, or NULL when
#' nothing is painted
#' @noRd
.element_background <- function(element, parent) {
  if (is.null(element) || inherits(element, "element_blank")) return(NULL)
  .painted(element$fill, parent)
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

#' Which of a layer's colour and fill take its alpha, as ggplot2 draws the geom
#'
#' Read from the geoms' drawing code. Rectangles (bars, columns, tiles),
#' ribbons (areas, densities), polygons, violins, boxplots, crossbars and
#' smooths pass the layer's alpha to the fill alone and draw the outline, the
#' whiskers and the median or fitted line opaque. Paths (lines, steps),
#' segments, error bars, line ranges and the reference lines pass it to the
#' colour. Points and point ranges pass it to both, and so does any geom not
#' named here, the cautious assumption for a geom whose drawing has not been
#' read. The Python twin keeps the same table for plotnine's geoms.
#' @return `"fill"`, `"colour"` or both.
#' @noRd
.alpha_targets <- function(geom) {
  if (inherits(geom, c("GeomRect", "GeomRibbon", "GeomPolygon", "GeomViolin",
                       "GeomBoxplot", "GeomCrossbar", "GeomSmooth"))) {
    return("fill")
  }
  if (inherits(geom, c("GeomPath", "GeomSegment", "GeomErrorbar",
                       "GeomLinerange", "GeomHline", "GeomVline",
                       "GeomAbline"))) {
    return("colour")
  }
  c("colour", "fill")
}

#' The aesthetics a layer maps
#'
#' ggplot2 resolves a layer's own mapping, and whatever it inherits from the
#' plot, into `computed_mapping` as it builds the plot. An aesthetic also set
#' to a constant, in `aes_params`, is drawn as the constant, so it does not
#' count as mapped.
#' @noRd
.layer_mapped <- function(layer) {
  setdiff(names(layer$computed_mapping), names(layer$aes_params))
}

#' The colour one aesthetic of a layer draws on each row, and its alpha
#'
#' ggplot2 draws a colour through `scales::alpha()`, which replaces the
#' colour's own alpha with the layer's when the layer sets one and keeps it
#' otherwise. Where the geom does not pass its alpha to this aesthetic, the
#' colour's own alpha is all there is. A row drawn fully transparent is
#' dropped, since it shows nothing.
#' @param applies Whether the layer's alpha reaches this aesthetic.
#' @return A data frame of `row` (the row of the layer data), `declared`
#'   (canonical hex) and `alpha`, or `NULL` when nothing is drawn.
#' @noRd
.layer_ink <- function(layer_data, aesthetic, applies) {
  values <- as.character(layer_data[[aesthetic]])
  parsed <- .parse_colours(unique(values))
  if (is.null(parsed)) return(NULL)
  at <- match(values, parsed$value)
  rows <- which(!is.na(at))
  own <- parsed$alpha[at[rows]]
  layer_alpha <- rep_len(as.numeric(layer_data[["alpha"]] %||% NA_real_),
                         length(values))[rows]
  alpha <- if (applies) ifelse(is.na(layer_alpha), own, layer_alpha) else own
  keep <- alpha > 0
  if (!any(keep)) return(NULL)
  data.frame(row = rows[keep], declared = parsed$hex[at[rows]][keep],
             alpha = alpha[keep], stringsAsFactors = FALSE)
}

#' Each declared colour of a layer as drawn, at the smallest alpha it takes
#' @return A data frame of `declared`, `alpha` and `drawn`, one row per
#'   declared colour.
#' @noRd
.drawn_by_value <- function(ink, background) {
  alpha <- tapply(ink$alpha, ink$declared, min)
  declared <- names(alpha)
  alpha <- as.numeric(alpha)
  data.frame(declared = declared, alpha = alpha,
             drawn = .composite(declared, background, alpha),
             stringsAsFactors = FALSE)
}

#' The groups a layer's colour and fill share, when they mark the same ones
#'
#' The two mark the same groups when each colour goes with exactly one fill on
#' the rows that draw both, and the other way round, and every colour and fill
#' the layer draws is among those pairs.
#' @return A data frame of `colour` and `fill` (declared hex), one row per
#'   group, or `NULL` when the two mark different groups.
#' @noRd
.shared_groups <- function(colour, fill) {
  rows <- intersect(colour$row, fill$row)
  pairs <- unique(data.frame(
    colour = colour$declared[match(rows, colour$row)],
    fill = fill$declared[match(rows, fill$row)],
    stringsAsFactors = FALSE
  ))
  one_to_one <- !anyDuplicated(pairs$colour) && !anyDuplicated(pairs$fill)
  covers <- setequal(pairs$colour, colour$declared) &&
    setequal(pairs$fill, fill$declared)
  if (nrow(pairs) && one_to_one && covers) pairs else NULL
}

#' One drawn colour per group of a layer, for the geometry check
#'
#' A group whose outline colour and fill are both mapped to it counts the one
#' of the two that contrasts better with the background. WCAG's Understanding
#' document for success criterion 1.4.11 lets a border supply a graphical
#' object's contrast, and an area geom draws its outline opaque however pale
#' its fill. Otherwise, each encoding colour stands for its own group.
#' @noRd
.layer_marks <- function(ink, drawn, background) {
  if (all(c("colour", "fill") %in% names(ink))) {
    groups <- .shared_groups(ink$colour, ink$fill)
    if (!is.null(groups)) {
      fill <- drawn$fill[match(groups$fill, drawn$fill$declared), ,
                         drop = FALSE]
      outline <- drawn$colour[match(groups$colour, drawn$colour$declared), ,
                              drop = FALSE]
      better <- .contrast_ratio(outline$drawn, background) >
        .contrast_ratio(fill$drawn, background)
      fill[better, ] <- outline[better, ]
      return(fill)
    }
  }
  do.call(rbind, unname(drawn))
}

#' The colours a figure uses to tell groups apart, and what else varies with them
#'
#' A layer carries colour or fill when it maps the aesthetic to a discrete
#' scale that is not an identity scale, even if every row draws the same
#' colour. It also carries one in which it draws two or more distinct colours.
#' The figure encodes by the aesthetic when the layers that carry it draw two
#' or more distinct colours between them, so groups drawn one per layer count
#' as they would in a single layer. A constant set on a layer is not a mapping,
#' and a colour passed through an identity scale is drawn as given. A layer
#' that draws one such colour alone carries nothing, since the audit cannot
#' tell it from decoration. A continuous scale is a smooth ramp, where
#' neighbouring colours are meant to be close, so measuring the distance
#' between them would only ever say that a gradient is a gradient.
#'
#' Shape and line type are gathered by the same rule from the layers that draw
#' the encoding colours. Either counts as varying alongside them when those
#' layers draw two or more distinct values of it between them.
#'
#' Every colour is taken as drawn over `background`, the panel, at the alpha
#' its geom applies to it.
#'
#' When nothing encodes by colour, the colour rows abstain, and their detail
#' says why. It tells a figure that draws its colour or fill from a continuous
#' scale apart from one that draws no colour code at all. A continuous scale
#' counts when the build trained it on data. A fill that a stat computes, such
#' as the counts of `geom_bin_2d()`, therefore counts, and a scale added to a
#' plot that maps nothing to it does not. The Python twin applies the same rule
#' through plotnine's own `is_empty()`.
#'
#' @return A list with `sets`, the drawn colours of the colour and of the fill
#'   aesthetic across all layers (each a data frame of `drawn` and `declared`,
#'   sorted so that a tie between two equally close pairs resolves the same way
#'   in both engines, and absent when nothing encodes by it), `marks`, one
#'   drawn colour per encoded group for the geometry check, `redundant`, the
#'   names of the non-colour channels that vary alongside them, and `abstain`,
#'   the detail the colour rows give when nothing encodes.
#' @noRd
.figure_colour_encoding <- function(built, background) {
  continuous <- character(0)
  coded <- character(0)
  graded <- FALSE
  for (scale in built$plot$scales$scales) {
    if (!isTRUE(scale$is_discrete())) {
      continuous <- union(continuous, scale$aesthetics)
      if (any(c("colour", "fill") %in% scale$aesthetics) &&
          !isTRUE(scale$is_empty())) {
        graded <- TRUE
      }
    } else if (!inherits(scale, "ScaleDiscreteIdentity")) {
      # An identity scale draws each value as given, so a value mapped through
      # it is chosen by hand, as a constant set on a layer is.
      coded <- union(coded, scale$aesthetics)
    }
  }

  # What each layer carries in colour and fill, gathered before it is known
  # whether the figure as a whole encodes by either.
  carriers <- list()
  for (index in seq_along(built$data)) {
    layer_data <- built$data[[index]]
    layer <- built$plot$layers[[index]]
    # A text layer's colour is chosen for legibility against whatever it sits
    # on, not to code a group, so counting it would report the distance between
    # black and white labels as though it were the distance between categories.
    if (.is_text_layer(layer)) next
    mapped <- intersect(.layer_mapped(layer), coded)
    targets <- .alpha_targets(layer$geom)
    ink <- list()
    for (aesthetic in c("colour", "fill")) {
      if (aesthetic %in% continuous) next
      rows <- .layer_ink(layer_data, aesthetic, aesthetic %in% targets)
      if (is.null(rows)) next
      # Distinct after normalisation: two spellings of one colour are one
      # colour, and an unmapped layer that draws only that carries nothing.
      if (aesthetic %in% mapped || length(unique(rows$declared)) >= 2) {
        ink[[aesthetic]] <- rows
      }
    }
    if (length(ink)) {
      carriers[[length(carriers) + 1L]] <- list(ink = ink, data = layer_data,
                                                mapped = mapped)
    }
  }
  encodes <- Filter(function(aesthetic) {
    declared <- unlist(lapply(carriers, function(carrier) {
      carrier$ink[[aesthetic]]$declared
    }))
    length(unique(declared)) >= 2
  }, c("colour", "fill"))

  sets <- list(colour = NULL, fill = NULL)
  marks <- list()
  others <- list(shape = character(0), linetype = character(0))
  for (carrier in carriers) {
    ink <- carrier$ink[intersect(names(carrier$ink), encodes)]
    if (!length(ink)) next
    drawn <- lapply(ink, .drawn_by_value, background = background)
    for (aesthetic in names(drawn)) {
      sets[[aesthetic]] <- rbind(sets[[aesthetic]],
                                 drawn[[aesthetic]][, c("drawn", "declared")])
    }
    marks[[length(marks) + 1L]] <- .layer_marks(ink, drawn, background)
    for (aesthetic in names(others)) {
      values <- carrier$data[[aesthetic]]
      values <- unique(as.character(values[!is.na(values)]))
      if (aesthetic %in% carrier$mapped || length(values) >= 2) {
        others[[aesthetic]] <- union(others[[aesthetic]], values)
      }
    }
  }
  # Radix order is byte order, which is what Python's sorted() gives, so the two
  # engines pick the same pair when two are equally close.
  sets <- lapply(sets, function(set) {
    if (is.null(set)) return(NULL)
    set <- unique(set)
    set[order(set$drawn, set$declared, method = "radix"), , drop = FALSE]
  })
  list(sets = Filter(Negate(is.null), sets),
       marks = if (length(marks)) do.call(rbind, marks),
       redundant = names(others)[lengths(others) >= 2],
       abstain = if (graded) .continuous_colour_detail else .no_colour_detail)
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
#' The outermost table holds the panels, and the walk takes one side of them.
#' By default, it skips the panel cells and leaves layer and annotation text to
#' the other walk. An inside legend sits in a cell of its own, so it is still
#' counted. With `panel = TRUE`, it walks the panel cells alone and takes every
#' text beneath them, an inset plot's included. Text that a grob builds only
#' when it is drawn, as ggrepel builds its repelled labels in `makeContent()`,
#' is not in the table yet, so neither walk sees it.
#'
#' A blank label draws nothing. Where a grob's sizes or colours run one per
#' label, as a text layer's do, a blank label's are left out. The Python twin
#' sees the same, since matplotlib draws no text for a blank label.
#'
#' Each text is paired with the background it is drawn on, which WCAG measures
#' contrast against. The walk carries a background down the tree: a nested
#' gtable with a cell named "background" or "legend.box.background" (a legend
#' box, or the box around all the legends) and a gTree with a
#' child rect named `strip.background*` (a facet strip) set it for everything
#' beneath them, and the plot background holds elsewhere. Legend keys are never
#' taken for a background, since text is not drawn on them.
#'
#' A text drawn with an alpha is composited over its background, as a mark is
#' over the panel. grid multiplies a gpar alpha into the colour's own and
#' carries it down the tree, so the walk carries it too.
#'
#' @param background The background the walk starts from: the plot background,
#'   which the outermost gtable's own "background" cell paints and which
#'   therefore is not read a second time, or the panel's for `panel = TRUE`.
#' @param panel Whether to walk only the panel cells, for the text drawn
#'   inside the panel.
#' @return A data frame of `size` (points), `colour` (the hex drawn),
#'   `declared` (the hex before compositing), `alpha`, `bold` (logical) and
#'   `background` (hex), or `NULL` when the walk finds no text.
#' @noRd
.figure_text <- function(gt, resolved, background, panel = FALSE) {
  base <- ggplot2::calc_element("text", resolved)
  found <- list()
  walk <- function(grob, bg, face = NULL, alpha = 1, root = FALSE) {
    if (is.null(grob)) return(invisible(NULL))
    # grid stores a gpar fontface as `font`, and a titleGrob can hold it for the
    # text inside, so the face is inherited down the tree like the background.
    face <- grob$gp$font %||% grob$gp$fontface %||% face
    alpha <- alpha * as.numeric(grob$gp$alpha %||% 1)[[1]]
    if (inherits(grob, "gtable")) {
      cells <- grob$layout$name %||% rep_len("", length(grob$grobs))
      if (!root) bg <- .cell_background(grob, cells, bg)
      for (index in seq_along(grob$grobs)) {
        in_panel <- startsWith(cells[[index]], "panel")
        skip <- if (panel) root && !in_panel else in_panel
        if (skip) next
        walk(grob$grobs[[index]], bg, face, alpha)
      }
    } else if (inherits(grob, "gTree")) {
      bg <- .strip_background(grob$children, bg)
      for (child in grob$children) walk(child, bg, face, alpha)
    }
    if (!inherits(grob, "text")) return(invisible(NULL))
    labels <- as.character(grob$label)
    drawn <- nzchar(trimws(labels))
    if (!any(drawn)) return(invisible(NULL))
    # A single grob can carry a vector of sizes or colours, one per label, so
    # both are recycled to the same length rather than reduced to their first
    # element and quietly losing the smallest or the palest.
    sizes <- as.numeric(grob$gp$fontsize %||% base$size) *
      as.numeric(grob$gp$cex %||% 1)
    colours <- grob$gp$col %||% base$colour %||% "black"
    if (length(sizes) == length(labels)) sizes <- sizes[drawn]
    if (length(colours) == length(labels)) colours <- colours[drawn]
    ink <- .parse_colours(colours)
    if (!is.null(ink)) {
      ink$alpha <- ink$alpha * alpha
      ink <- ink[ink$alpha > 0, , drop = FALSE]
    }
    sizes <- sizes[is.finite(sizes)]
    if (!length(sizes) || is.null(ink) || !nrow(ink)) return(invisible(NULL))
    bold <- (face %||% 1) %in% c(2, 4, "bold", "bold.italic")
    n <- max(length(sizes), nrow(ink), length(bold))
    found[[length(found) + 1L]] <<- data.frame(
      size = rep_len(sizes, n),
      colour = rep_len(.composite(ink$hex, bg, ink$alpha), n),
      declared = rep_len(ink$hex, n), alpha = rep_len(ink$alpha, n),
      bold = rep_len(bold, n), background = bg,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
  walk(gt, background, root = TRUE)
  if (!length(found)) return(NULL)
  do.call(rbind, found)
}

#' The background a gtable's "background" cell paints, else the parent's
#'
#' A legend's guide table holds its box (`legend.background`) in a cell named
#' "background", listed after the keys and labels it sits behind, so the cell
#' is looked up before the walk descends. The guide box around all the legends
#' holds `legend.box.background` in a cell of that name, which works the same
#' way one level up.
#' @noRd
.cell_background <- function(gt, cells, parent) {
  index <- which(cells %in% c("background", "legend.box.background"))
  if (!length(index)) return(parent)
  grob <- gt$grobs[[index[[1]]]]
  if (!inherits(grob, "rect")) return(parent)
  .painted(grob$gp$fill, parent, grob$gp$alpha) %||% parent
}

#' The fill of a facet strip among a gTree's children, else the parent's
#' @noRd
.strip_background <- function(children, parent) {
  for (child in children) {
    if (inherits(child, "rect") &&
        startsWith(child$name %||% "", "strip.background")) {
      return(.painted(child$gp$fill, parent, child$gp$alpha) %||% parent)
    }
  }
  parent
}

# --- rows -------------------------------------------------------------------

#' A row's verdict: a floor passes at or above its threshold, and a ceiling at
#' or below it
#' @noRd
.verdict <- function(measured, threshold, ceiling = FALSE) {
  if (is.na(measured)) return("not applicable")
  passes <- if (ceiling) measured <= threshold else measured >= threshold
  if (passes) "pass" else "fail"
}

#' @noRd
.check_row <- function(check, measured, threshold, detail, ceiling = FALSE) {
  data.frame(
    check = check,
    measured = if (is.na(measured)) NA_real_ else round(measured, 2),
    threshold = threshold,
    verdict = .verdict(measured, threshold, ceiling),
    detail = detail,
    stringsAsFactors = FALSE
  )
}

# What every colour-dependent check says when the figure encodes nothing by
# colour. Shared so the two halves of the sentence cannot drift apart.
.no_colour_detail <- "No two encoding colours: nothing is distinguished by colour."

# What they say instead when the figure draws its colour or fill from a
# continuous scale, which they do not audit. A heatmap distinguishes its cells
# by colour, so the sentence above would be false of it. The Python twin
# carries the same sentence.
.continuous_colour_detail <-
  "Colour is a continuous scale, which these checks do not audit."

# Fixed two decimals, so a number embedded in a detail string reads the same
# here as in the Python twin's f-string.
#' @noRd
.fmt <- function(x) formatC(x, format = "f", digits = 2)

# How a detail names the colours of each aesthetic's set.
.set_nouns <- c(colour = "colours", fill = "fill colours")

#' The four colour rows plus the greyscale row
#'
#' Each set holds the drawn colours of one aesthetic, and only colours declared
#' differently are paired, so a group is never compared with itself. The rows
#' report the closest pair over the sets, the first set winning a tie.
#' @param metric The colour difference of the four colour rows, `"ciede2000"`
#'   or `"cie76"`. The greyscale row is a lightness gap either way.
#' @param abstain The detail every row gives when no set encodes.
#' @noRd
.separability_rows <- function(sets, min_delta_e, metric = "ciede2000",
                               abstain = .no_colour_detail) {
  check_names <- c("colour_separability", "colour_separability_protan",
                   "colour_separability_deutan", "colour_separability_tritan")
  conditions <- c("normal", names(.cvd_matrices))
  if (!length(sets)) {
    rows <- lapply(check_names, function(nm) {
      .check_row(nm, NA_real_, min_delta_e, abstain)
    })
    rows[[length(rows) + 1L]] <- .check_row(
      "greyscale_separability", NA_real_, min_delta_e, abstain)
    return(rows)
  }
  closest_over_sets <- function(measure) {
    best <- NULL
    for (aesthetic in names(sets)) {
      set <- sets[[aesthetic]]
      found <- measure(set)
      if (is.null(best) || found$distance < best$distance) {
        best <- found
        best$colours <- set$drawn[found$pair]
        best$size <- nrow(set)
        best$noun <- .set_nouns[[aesthetic]]
      }
    }
    best
  }
  rows <- Map(function(nm, condition) {
    closest <- closest_over_sets(function(set) {
      seen <- if (condition == "normal") set$drawn else {
        simulate_cvd(set$drawn, condition)
      }
      .min_pairwise_delta_e(seen, set$declared, metric)
    })
    .check_row(nm, closest$distance, min_delta_e, sprintf(
      "Closest pair %s and %s of %d encoding %s.", closest$colours[[1]],
      closest$colours[[2]], closest$size, closest$noun))
  }, check_names, conditions)
  # Lightness is what a black-and-white printer keeps, and CIE L* is a function
  # of luminance alone, so the greyscale difference between two colours is the
  # gap between their lightnesses, whichever metric the colour rows use.
  grey <- closest_over_sets(function(set) {
    .min_pairwise_delta_e_1d(.srgb_to_lab(set$drawn)[, "L"], set$declared)
  })
  rows[[length(rows) + 1L]] <- .check_row(
    "greyscale_separability", grey$distance, min_delta_e, sprintf(
      "Closest pair %s and %s in CIE lightness.", grey$colours[[1]],
      grey$colours[[2]]))
  unname(rows)
}

#' Smallest pairwise gap in a single dimension, walked in the twin's order
#'
#' A pair whose `groups` are equal is skipped, as in `.min_pairwise_delta_e()`.
#' @noRd
.min_pairwise_delta_e_1d <- function(values, groups = NULL) {
  n <- length(values)
  best <- Inf
  pair <- c(1L, 1L)
  for (i in seq_len(n - 1)) {
    for (j in seq(i + 1, n)) {
      if (!is.null(groups) && groups[[i]] == groups[[j]]) next
      d <- abs(values[[i]] - values[[j]])
      if (d < best) {
        best <- d
        pair <- c(i, j)
      }
    }
  }
  list(distance = best, pair = pair)
}

#' The smallest of some text at its printed size, against the floor
#'
#' Serves `text_size`, for the theme's text, and `annotation_text_size`, for
#' the text drawn inside the panel.
#' @param noun How the detail names the text measured.
#' @param absent The detail when there is no such text.
#' @noRd
.smallest_text_row <- function(check, text, width_cm, render_width_cm,
                               min_text_pt, noun, absent) {
  if (is.null(text)) {
    return(.check_row(check, NA_real_, min_text_pt, absent))
  }
  nominal <- min(text$size)
  .check_row(check, nominal * width_cm / render_width_cm, min_text_pt,
             sprintf("Smallest %s %s pt, drawn at %s cm and printed at %s cm.",
                     noun, .fmt(nominal), .fmt(render_width_cm),
                     .fmt(width_cm)))
}

#' The largest text at its printed size, against a ceiling
#'
#' Serves `text_size_max`, over the text around the panel and inside it
#' together, since a ceiling such as Nature's applies to all of it. It is the
#' one row that passes at or below its threshold.
#' @param sizes The point sizes of every text the figure draws, as drawn.
#' @noRd
.largest_text_row <- function(sizes, width_cm, render_width_cm, max_text_pt) {
  if (!length(sizes)) {
    return(.check_row("text_size_max", NA_real_, max_text_pt,
                      "The figure draws no text.", ceiling = TRUE))
  }
  nominal <- max(sizes)
  .check_row("text_size_max", nominal * width_cm / render_width_cm,
             max_text_pt,
             sprintf("Largest text %s pt, drawn at %s cm and printed at %s cm.",
                     .fmt(nominal), .fmt(render_width_cm), .fmt(width_cm)),
             ceiling = TRUE)
}

#' The text that falls furthest short of its own WCAG threshold
#'
#' Each text is measured against its own background and held to 3:1 when it is
#' large at its printed size (18 pt, or 14 pt in bold) and to 4.5:1 otherwise.
#' The row reports the text with the smallest ratio relative to its threshold.
#' Ties go to the smaller printed size, then to the colour and background in
#' byte order, which is the order the Python twin breaks them in.
#' @param absent The detail when the figure draws no such text.
#' @noRd
.text_contrast_row <- function(text, width_cm, render_width_cm,
                               absent = "The figure draws no text.") {
  if (is.null(text)) {
    return(.check_row("text_contrast", NA_real_, .wcag_text_contrast, absent))
  }
  printed <- text$size * width_cm / render_width_cm
  large <- printed >= .wcag_large_text_pt |
    (text$bold & printed >= .wcag_large_bold_text_pt)
  threshold <- ifelse(large, .wcag_large_text_contrast, .wcag_text_contrast)
  ratios <- .contrast_ratio(text$colour, text$background)
  worst <- order(ratios / threshold, printed, text$colour, text$background,
                 method = "radix")[[1]]
  .check_row("text_contrast", ratios[[worst]], threshold[[worst]],
             sprintf("Lowest-contrast text %s on %s at %s pt%s.",
                     .ink_as_drawn(text$declared[[worst]], text$alpha[[worst]],
                                   text$colour[[worst]]),
                     text$background[[worst]], .fmt(printed[[worst]]),
                     if (text$bold[[worst]]) " bold" else ""))
}

#' How a detail names a colour: as declared when it is opaque, and with its
#' alpha and the colour it is drawn as when it is not
#' @noRd
.ink_as_drawn <- function(declared, alpha, drawn) {
  if (alpha >= 1) return(drawn)
  sprintf("%s at alpha %s, drawn as %s,", declared, .fmt(alpha), drawn)
}

#' The encoded group whose drawn colour contrasts least with the background
#'
#' Ties go to the drawn colour, then the declared one, in byte order, which is
#' the order the Python twin breaks them in.
#' @param abstain The detail when no group is encoded.
#' @noRd
.geometry_contrast_row <- function(marks, background,
                                   abstain = .no_colour_detail) {
  if (is.null(marks) || !nrow(marks)) {
    return(.check_row("geometry_contrast", NA_real_, .wcag_object_contrast,
                      abstain))
  }
  ratios <- .contrast_ratio(marks$drawn, background)
  worst <- order(ratios, marks$drawn, marks$declared, method = "radix")[[1]]
  .check_row("geometry_contrast", ratios[[worst]], .wcag_object_contrast,
             sprintf("Lowest-contrast colour %s on %s.",
                     .ink_as_drawn(marks$declared[[worst]],
                                   marks$alpha[[worst]], marks$drawn[[worst]]),
                     background))
}

#' @noRd
.redundant_encoding_row <- function(encoding) {
  if (!length(encoding$sets)) {
    return(.check_row("redundant_encoding", NA_real_, 1,
                      encoding$abstain %||% .no_colour_detail))
  }
  channels <- encoding$redundant
  detail <- if (length(channels)) {
    sprintf("Colour is joined by %s.", paste(channels, collapse = " and "))
  } else {
    "Colour alone distinguishes the groups."
  }
  .check_row("redundant_encoding", length(channels), 1, detail)
}
