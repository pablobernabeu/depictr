# Shared theme, palette and label helpers ------------------------------------

#' The depictr colour palettes
#'
#' Colourblind-aware palettes shared by every depictr plot. The qualitative
#' palette is based on the Okabe-Ito set (Okabe & Ito, 2008), a widely
#' recommended categorical palette that stays distinguishable under the common
#' forms of colour-vision deficiency, with the depictr brand blue leading. The
#' sequential and diverging palettes are perceptually ordered single-hue and
#' red-blue ramps.
#'
#' @param n Number of colours to return. If `NULL` (the default) the full
#'   qualitative palette is returned. For the qualitative palette an `n` larger
#'   than the available base colours is interpolated; the sequential and
#'   diverging palettes are ramps and accept any `n`. Interpolated colours
#'   beyond the base set are not guaranteed to remain distinguishable under
#'   colour-vision deficiency, so prefer faceting or a custom palette when many
#'   groups are needed.
#' @param type Palette type: `"qualitative"` (categorical groups),
#'   `"sequential"` (ordered low-to-high) or `"diverging"` (a midpoint with two
#'   directions).
#'
#' @details The qualitative palette can be overridden globally with
#'   `options(depictr.palette = )` (see [depictr_options()]); when set, that
#'   custom palette replaces the built-in Okabe-Ito set and is interpolated when
#'   more colours are requested than it provides. The sequential and diverging
#'   ramps are unaffected.
#'
#' @return A character vector of hex colour codes.
#' @references
#' \insertRef{okabe2008}{depictr}
#' @export
#' @examples
#' depictr_palette(3)
#' depictr_palette(7, type = "sequential")
#' scales::show_col(depictr_palette())
depictr_palette <- function(n = NULL, type = c("qualitative", "sequential",
                                               "diverging")) {
  type <- match.arg(type)
  if (!is.null(n) && (!is.numeric(n) || length(n) != 1 || n < 1)) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }
  if (!is.null(n)) n <- as.integer(n)

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
  # Okabe-Ito set (led by the depictr brand blue); the option falls back to the
  # package default.
  base <- depictr_opt("palette")
  if (is.null(base)) {
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
  }
  base <- unname(base)
  if (is.null(n)) return(base)
  if (n <= length(base)) return(base[seq_len(n)])
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
#'   `n` only to force a fixed slice of the palette.
#' @param palette Optional palette override: a function of one argument (the
#'   number of colours) returning a character vector of colours. Defaults to
#'   [depictr_palette()].
#' @param na.value Colour for `NA` levels. Defaults to the resolved
#'   `depictr.na_value` option (the muted grey `"grey80"` unless changed).
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 scale that can be added to a plot.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
#'   geom_point() +
#'   scale_colour_depictr() +
#'   theme_depictr()
scale_colour_depictr <- function(n = NULL, palette = NULL,
                                 na.value = depictr_opt("na_value"), ...) {
  pal <- palette %||% function(k) depictr_palette(n %||% k)
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
                               na.value = depictr_opt("na_value"), ...) {
  pal <- palette %||% function(k) depictr_palette(n %||% k)
  ggplot2::discrete_scale(
    "fill",
    palette = pal,
    na.value = na.value,
    ...
  )
}

#' The depictr ggplot2 theme
#'
#' A clean, minimal theme used by every plotting function in the package. It is
#' a light modification of [ggplot2::theme_minimal()] with subtle gridlines,
#' centred titles and comfortable margins.
#'
#' The default `base_size` and `base_family` come from the global options
#' `depictr.base_size` and `depictr.base_family` (see [depictr_options()]), so
#' the package-wide font size can be set once; passing the arguments explicitly
#' overrides them. The title colour is the resolved `depictr_brand()`, which in
#' turn honours `options(depictr.brand = )`.
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
#' background, so the figure needs no right-hand margin. `position` and
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
  na <- is.na(x)
  if (strip_prefix) {
    # Strip the b_/bs_ Bayesian prefix from each interaction component, not just
    # the leading token: split on the interaction separator, strip each piece,
    # then rejoin. `stringr` propagates NA, so missing values stay missing.
    x <- vapply(
      strsplit(x, ":", fixed = TRUE),
      function(parts) paste(stringr::str_replace(parts, "^b[s]?_", ""),
                            collapse = ":"),
      character(1)
    )
    x[na] <- NA_character_
  }
  if (tidy_intercept) {
    x <- stringr::str_replace(x, "^\\(Intercept\\)$", "Intercept")
  }
  sep <- switch(interaction,
    times = " \u00d7 ",
    asterisk = " * ",
    colon = ":",
    space = " "
  )
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
