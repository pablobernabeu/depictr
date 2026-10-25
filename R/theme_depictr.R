# Shared theme, palette and label helpers ------------------------------------

#' The depictr colour palettes
#'
#' Colourblind-aware palettes shared by every depictr plot. The qualitative
#' palette is based on the Okabe-Ito set (Okabe & Ito, 2008), a widely
#' recommended categorical palette that stays distinguishable under the common
#' forms of colour-vision deficiency. It keeps six of that set's eight colours.
#' The depictr brand blue (`#005b96`) takes the place of its blue (`#0072b2`)
#' and leads the palette, and a grey (`#999999`) takes the place of its black.
#' The sequential and diverging palettes are perceptually ordered single-hue
#' and red-blue ramps.
#'
#' The guarantee belongs to the eight built-in colours themselves, not to any
#' number of colours: past eight the qualitative palette has to interpolate
#' between them, and the interpolated colours sit close enough together to fail
#' the package's own colour-distance check. That case warns rather than handing
#' back colours under a guarantee it cannot keep.
#'
#' @param n Number of colours to return. If `NULL` (the default), the
#'   qualitative palette returns all of its base colours, the eight built-in
#'   colours unless `options(depictr.palette = )` supplies another set, and
#'   the sequential and diverging ramps return seven. For the qualitative
#'   palette an `n` larger than the available base colours is interpolated;
#'   the sequential and diverging palettes are ramps and accept any `n`.
#'   Interpolating the built-in
#'   qualitative palette beyond its eight base colours loses the
#'   colour-vision-deficiency guarantee and warns, so facet the groups or use
#'   the sequential ramp when many groups are needed.
#' @param type Palette type: `"qualitative"` (categorical groups),
#'   `"sequential"` (ordered low-to-high) or `"diverging"` (a midpoint with two
#'   directions).
#' @param order The order of the built-in qualitative palette: `"default"`, or
#'   `"contrast"` for the contrast-first order described below. The ramps have
#'   an order of their own and refuse `"contrast"`.
#'
#' @details The qualitative palette can be overridden globally with
#'   `options(depictr.palette = )` (see [depictr_options()]); when set, that
#'   custom palette replaces the eight built-in colours and is interpolated when
#'   more colours are requested than it provides. The sequential and diverging
#'   ramps are unaffected.
#'
#' @section The contrast-first order:
#' In the default order the second colour is the orange (`#e69f00`), at 2.25:1
#' against white. Any figure on white whose colour tells two or more groups
#' apart therefore fails the `geometry_contrast` row of [check_figure()]. No
#' more than three of the eight colours pass every colour row of that audit
#' together.
#'
#' `order = "contrast"` puts those three first: the brand blue, the vermillion
#' (`#d55e00`) and the reddish purple (`#cc79a7`), then the bluish green
#' (`#009e73`) and the other four in their default order. Up to three groups
#' then pass every colour row, contrast against white included. They stay at
#' least 14.01 apart in CIEDE2000 under every vision type, 6.86 apart in
#' lightness and 3.06:1 against white. Four groups keep 3:1 against white, but
#' the bluish green and the reddish purple are 3.31 apart in lightness, which
#' fails `greyscale_separability`. Asking for more than four colours warns,
#' since the fifth, the orange, falls below 3:1.
#'
#' Under this order, the second group is drawn in the vermillion. That is also
#' the accent ([depictr_options()]) that depictr uses for single highlights,
#' such as the flagged points of [outlier_plot()] and the missing cells of
#' [missingness_map()].
#'
#' The order applies to the built-in palette alone. A palette set with
#' `depictr_options(palette = )` is the user's own, so it is returned in the
#' order it was set, with a warning. That is also how to make the order the
#' default for every later plot:
#' `depictr_options(palette = depictr_palette(order = "contrast"))`. The
#' palette is then the user's own, so asking for more than four colours no
#' longer warns. [scale_colour_depictr()] and [scale_fill_depictr()] take
#' `order` for a single plot.
#'
#' @return A character vector of hex colour codes.
#' @references
#' \insertRef{okabe2008}{depictr}
#'
#' \insertRef{wcag22}{depictr}
#' @export
#' @examples
#' depictr_palette(3)
#' depictr_palette(3, order = "contrast")
#' depictr_palette(7, type = "sequential")
#' scales::show_col(depictr_palette())
depictr_palette <- function(n = NULL, type = c("qualitative", "sequential",
                                               "diverging"),
                            order = c("default", "contrast")) {
  type <- match.arg(type)
  order <- match.arg(order)
  if (!is.null(n) && (!is.numeric(n) || length(n) != 1 || n < 1)) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }
  if (!is.null(n)) n <- as.integer(n)
  if (type != "qualitative" && order != "default") {
    stop("`order` applies to the qualitative palette, not to the ", type,
         " ramp.", call. = FALSE)
  }

  if (type == "sequential") {
    ramp <- grDevices::colorRampPalette(c("#e6eff5", "#4a8fc0", "#005b96",
                                          "#08315a"))
    return(ramp(n %||% 7))
  }
  if (type == "diverging") {
    ramp <- grDevices::colorRampPalette(c("#b2182b", "#ef8a62", "#f7f7f7",
                                          "#67a9cf", "#005b96"))
    return(ramp(n %||% 7))
  }

  # Qualitative: a user-supplied palette (option) overrides the built-in
  # set (based on Okabe-Ito and led by the depictr brand blue); the option falls
  # back to the package default.
  base <- depictr_opt("palette")
  builtin <- is.null(base)
  if (builtin) {
    base <- c(
      blue           = "#005b96",
      orange         = "#e69f00",
      bluish_green   = "#009e73",
      vermillion     = "#d55e00",
      reddish_purple = "#cc79a7",
      sky_blue       = "#56b4e9",
      yellow         = "#f0e442",
      grey           = "#999999"
    )
    if (order == "contrast") {
      # The only three colours of the eight that clear every colour row of
      # check_figure() together lead, then the bluish green, which keeps 3:1
      # against white, then the rest in their default order. The Python twin
      # pins the same order.
      base <- base[c("blue", "vermillion", "reddish_purple", "bluish_green",
                     "orange", "sky_blue", "yellow", "grey")]
    }
  } else if (order != "default") {
    warning("`order` applies to the built-in palette, so the depictr.palette ",
            "option is returned as it was set.", call. = FALSE)
  }
  base <- unname(base)
  if (is.null(n)) return(base)
  if (builtin && order == "contrast" && n > 4L) {
    warning("Past four colours the contrast-first order no longer keeps every ",
            "colour at 3:1 against white.", call. = FALSE)
  }
  if (n <= length(base)) return(base[seq_len(n)])
  # Interpolating past the base set puts the colours close enough together to
  # fail palette_safety(), so say so instead of quietly breaking the package's
  # headline accessibility claim. Only the built-in set carries that claim: a
  # user-supplied palette was never Okabe-Ito to begin with.
  if (builtin) {
    warning(n, " colours interpolated through the ", length(base),
            "-colour Okabe-Ito set: the colour-vision-deficiency guarantee ",
            "holds only up to ", length(base), " categories. Use a sequential ",
            "palette, or facet the groups, if the distinction must survive ",
            "colour-vision deficiency.", call. = FALSE)
  }
  grDevices::colorRampPalette(base)(n)
}

#' depictr colour and fill scales
#'
#' Discrete ggplot2 scales using [depictr_palette()]. These are the canonical
#' colour and fill scales used throughout the package. They honour the global
#' `options(depictr.palette = )` (via [depictr_palette()]) and
#' `options(depictr.na_value = )` settings; see [depictr_options()].
#'
#' @param n Optional number of colours to draw from [depictr_palette()]. By
#'   default ggplot2 requests exactly as many colours as there are groups; pass
#'   `n` only to force a fixed slice of the palette. More than eight groups
#'   means the built-in qualitative palette is interpolated, which loses the
#'   colour-vision-deficiency guarantee and warns at draw time; facet the groups
#'   or use a sequential scale when there are that many.
#' @param palette Optional palette override: a function of one argument (the
#'   number of colours) returning a character vector of colours. Defaults to
#'   [depictr_palette()].
#' @param na.value Colour for `NA` levels. Defaults to the resolved
#'   `depictr.na_value` option (the muted grey `"grey80"` unless changed).
#' @param order `"default"`, or `"contrast"` to draw the groups in the
#'   contrast-first order of [depictr_palette()], with which two or three
#'   groups pass every colour row of [check_figure()]. More than four groups
#'   warn at draw time. It cannot be combined with `palette`.
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 scale that can be added to a plot.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
#'   geom_point() +
#'   scale_colour_depictr() +
#'   theme_depictr()
#'
#' # The vermillion in the orange's place, at 3.87:1 against white
#' ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
#'                        shape = treatment)) +
#'   geom_point() +
#'   scale_colour_depictr(order = "contrast") +
#'   theme_depictr()
scale_colour_depictr <- function(n = NULL, palette = NULL,
                                 na.value = depictr_opt("na_value"),
                                 order = c("default", "contrast"), ...) {
  pal <- depictr_scale_palette(n, palette, order)
  ggplot2::discrete_scale(
    "colour",
    palette = pal,
    na.value = na.value,
    ...
  )
}

#' @rdname scale_colour_depictr
#' @export
scale_color_depictr <- scale_colour_depictr

#' @rdname scale_colour_depictr
#' @export
scale_fill_depictr <- function(n = NULL, palette = NULL,
                               na.value = depictr_opt("na_value"),
                               order = c("default", "contrast"), ...) {
  pal <- depictr_scale_palette(n, palette, order)
  ggplot2::discrete_scale(
    "fill",
    palette = pal,
    na.value = na.value,
    ...
  )
}

#' The palette function behind the depictr discrete scales
#'
#' `order` is matched when the scale is made, so a misspelt order fails at
#' once. The palette is asked for `k` colours at draw time, which is when the
#' warnings past four or eight groups come.
#' @noRd
depictr_scale_palette <- function(n, palette, order) {
  order <- match.arg(order, c("default", "contrast"))
  if (!is.null(palette)) {
    if (order != "default") {
      stop("Give `palette` or `order = \"contrast\"`, not both.", call. = FALSE)
    }
    return(palette)
  }
  function(k) depictr_palette(n %||% k, order = order)
}

#' The depictr ggplot2 theme
#'
#' The minimal theme used by every plotting function in the package. It is
#' a light modification of [ggplot2::theme_minimal()] with subtle gridlines,
#' centred titles and comfortable margins.
#'
#' The default `base_size` and `base_family` come from the global options
#' `depictr.base_size` and `depictr.base_family` (see [depictr_options()]), so
#' the package-wide font size can be set once; passing the arguments explicitly
#' overrides them. The title is drawn in the brand colour, the one
#' `options(depictr.brand = )` sets and the other functions' `depictr_brand()`
#' defaults stand for.
#'
#' @param base_size Base font size, in points. Defaults to the
#'   `depictr.base_size` option.
#' @param base_family Base font family. Defaults to the `depictr.base_family`
#'   option.
#' @param grid Which major gridlines to keep: `"xy"`, `"x"`, `"y"` or `"none"`.
#'
#' @return A ggplot2 theme object.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(fertiliser, yield)) +
#'   geom_point() +
#'   theme_depictr()
theme_depictr <- function(base_size = depictr_opt("base_size"),
                          base_family = depictr_opt("base_family"),
                          grid = "xy") {
  grid <- match.arg(grid, c("xy", "x", "y", "none"))
  th <- ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        colour = depictr_brand(), hjust = 0.5, face = "bold",
        size = ggplot2::rel(1.15),
        margin = ggplot2::margin(b = base_size * 0.6)
      ),
      plot.subtitle = ggplot2::element_text(
        hjust = 0.5, colour = "grey30",
        margin = ggplot2::margin(b = base_size * 0.5)
      ),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = base_size * 0.6)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = base_size * 0.6)),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey90"),
      legend.background = ggplot2::element_rect(colour = "grey85", fill = "white"),
      # Centre the (bold) legend title over its keys; tidier than ggplot2's
      # default left alignment, especially for an inside or top/bottom legend.
      legend.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      strip.background = ggplot2::element_rect(fill = "grey96", colour = NA),
      strip.text = ggplot2::element_text(
        margin = ggplot2::margin(t = 4, b = 4)
      ),
      plot.margin = ggplot2::margin(10, 12, 10, 12)
    )
  if (grid %in% c("x", "none")) {
    th <- th + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  }
  if (grid %in% c("y", "none")) {
    th <- th + ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
  }
  th
}

#' A theme fragment placing the legend inside the panel
#'
#' Returns the theme that the plots exposing a `legend_inside` argument add when
#' it is set to `TRUE`: it tucks the legend into a corner the plot's geometry
#' usually leaves empty, be it a ROC curve (hugs the top-left), a cumulative
#' gains chart (concave, above the diagonal), a lift chart (decays to the
#' baseline on the right), an ECDF (saturates before the right edge), a survival
#' curve (monotone-decreasing) or a unimodal density, over a semi-transparent
#' background, so the figure needs no right-hand margin. A missingness map
#' sorted most- to least-missing adds it in the top-right corner, over its most
#' complete columns, and so does dumbbell_plot(), whose rows do not always
#' leave that corner empty. `position` and
#' `justification` are the ggplot2 `legend.position.inside` and
#' `legend.justification` coordinates of the anchored corner (npc, 0-1).
#' @noRd
legend_inside_theme <- function(position = c(0.98, 0.02),
                                justification = c(1, 0)) {
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = position,
    legend.justification = justification,
    legend.background = ggplot2::element_rect(
      fill = grDevices::adjustcolor("white", alpha.f = 0.7),
      colour = "grey85"
    ),
    legend.key = ggplot2::element_rect(fill = NA, colour = NA)
  )
}

#' Tidy raw coefficient names for display
#'
#' Cleans up the term names produced by modelling functions so that they read
#' well on a plot: the intercept is renamed, an optional `b_`/`bs_` Bayesian
#' prefix is stripped, interaction colons are converted to a chosen symbol, and
#' underscores are shown as spaces (e.g. `word_frequency` becomes
#' `"word frequency"`). The `b_`/`bs_` prefix is stripped from *each* component
#' of an interaction (e.g. `b_x:b_y`), not just the leading term. Missing values
#' (`NA`) are kept as `NA` rather than being rendered as the literal text
#' `"NA"`.
#'
#' @param x Character vector of term names.
#' @param interaction How to render interaction colons: `"times"` (the default,
#'   a Unicode multiplication sign), `"asterisk"`, `"colon"` (unchanged) or
#'   `"space"`.
#' @param strip_prefix Whether to remove a leading `b_` or `bs_` (as added by
#'   'brms') from each interaction component.
#' @param tidy_intercept Whether to replace `(Intercept)` with `"Intercept"`.
#' @param wrap Optional integer width at which to wrap long labels onto new
#'   lines (see [base::strwrap()]). `NULL` (default) leaves labels unwrapped.
#'
#' @return A character vector the same length as `x`, with `NA` preserved.
#' @export
#' @examples
#' format_terms(c("(Intercept)", "b_conditionB", "freq:condition"))
#' format_terms("region:education:age", interaction = "asterisk")
#' format_terms(c("word_frequency", "b_sleep_hours"))
#' format_terms(c("b_x:b_y", NA))
format_terms <- function(x,
                         interaction = c("times", "asterisk", "colon", "space"),
                         strip_prefix = TRUE,
                         tidy_intercept = TRUE,
                         wrap = NULL) {
  interaction <- match.arg(interaction)
  x <- as.character(x)
  if (strip_prefix) {
    # Strip the b_/bs_ Bayesian prefix from each interaction component, not just
    # the leading token: a prefix counts at the start of the term or straight
    # after a colon. One regular expression over the whole vector does this for
    # every term at once, which matters for the per-draw tables of a posterior,
    # and gsub() leaves NA as NA.
    x <- gsub("(^|:)bs?_", "\\1", x)
  }
  if (tidy_intercept) {
    x <- stringr::str_replace(x, "^\\(Intercept\\)$", "Intercept")
  }
  sep <- interaction_separator(interaction)
  if (interaction != "colon") {
    x <- stringr::str_replace_all(x, ":", sep)
  }
  # Show underscores as spaces for readability (e.g. word_frequency ->
  # "word frequency"); gsub leaves NA untouched.
  x <- gsub("_", " ", x, fixed = TRUE)
  if (!is.null(wrap)) {
    x <- vapply(
      x,
      function(s) if (is.na(s)) NA_character_ else
        paste(strwrap(s, width = wrap), collapse = "\n"),
      character(1)
    )
    x <- unname(x)
  }
  x
}

#' The text that joins the components of an interaction label
#'
#' Shared by [format_terms()] and the factor-level labels of
#' `pretty_coef_map()`, so both write an interaction the same way.
#' @noRd
interaction_separator <- function(interaction) {
  switch(interaction,
    times = " \u00d7 ",
    asterisk = " * ",
    colon = ":",
    space = " "
  )
}
