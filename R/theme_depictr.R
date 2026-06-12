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
#'   than the eight base colours is interpolated; the sequential and diverging
#'   palettes are ramps and accept any `n`.
#' @param type Palette type: `"qualitative"` (categorical groups),
#'   `"sequential"` (ordered low-to-high) or `"diverging"` (a midpoint with two
#'   directions).
#'
#' @return A character vector of hex colour codes.
#' @references Okabe, M. & Ito, K. (2008). Color Universal Design (CUD): How to
#'   make figures and presentations that are friendly to colorblind people.
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

  # Qualitative: Okabe-Ito, led by the depictr brand blue
  base <- c(
    blue          = "#005b96",
    orange        = "#e69f00",
    bluish_green  = "#009e73",
    vermillion    = "#d55e00",
    reddish_purple = "#cc79a7",
    sky_blue      = "#56b4e9",
    yellow        = "#f0e442",
    grey          = "#999999"
  )
  if (is.null(n)) return(unname(base))
  if (n <= length(base)) return(unname(base[seq_len(n)]))
  grDevices::colorRampPalette(unname(base))(n)
}

#' depictr colour and fill scales
#'
#' Discrete ggplot2 scales using [depictr_palette()].
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 scale that can be added to a plot.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
#'   geom_point() +
#'   scale_colour_depictr() +
#'   theme_depictr()
scale_colour_depictr <- function(...) {
  ggplot2::discrete_scale(
    "colour", "depictr",
    palette = function(n) depictr_palette(n),
    ...
  )
}

#' @rdname scale_colour_depictr
#' @export
scale_color_depictr <- scale_colour_depictr

#' @rdname scale_colour_depictr
#' @export
scale_fill_depictr <- function(...) {
  ggplot2::discrete_scale(
    "fill", "depictr",
    palette = function(n) depictr_palette(n),
    ...
  )
}

#' The depictr ggplot2 theme
#'
#' A clean, minimal theme used by every plotting function in the package. It is
#' a light modification of [ggplot2::theme_minimal()] with subtle gridlines,
#' centred titles and comfortable margins.
#'
#' @param base_size Base font size, in points.
#' @param base_family Base font family.
#' @param grid Which major gridlines to keep: `"xy"`, `"x"`, `"y"` or `"none"`.
#'
#' @return A ggplot2 theme object.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(fertilizer, yield)) +
#'   geom_point() +
#'   theme_depictr()
theme_depictr <- function(base_size = 11, base_family = "", grid = "xy") {
  grid <- match.arg(grid, c("xy", "x", "y", "none"))
  th <- ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        colour = "#005b96", hjust = 0.5, face = "bold",
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
      legend.title = ggplot2::element_text(face = "bold"),
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

#' Tidy raw coefficient names for display
#'
#' Cleans up the term names produced by modelling functions so that they read
#' well on a plot: the intercept is renamed, an optional `b_`/`bs_` Bayesian
#' prefix is stripped, and interaction colons are converted to a chosen symbol.
#'
#' @param x Character vector of term names.
#' @param interaction How to render interaction colons: `"times"` (the default,
#'   a Unicode multiplication sign), `"asterisk"`, `"colon"` (unchanged) or
#'   `"space"`.
#' @param strip_prefix Whether to remove a leading `b_` or `bs_` (as added by 'brms').
#' @param tidy_intercept Whether to replace `(Intercept)` with `"Intercept"`.
#' @param wrap Optional integer width at which to wrap long labels onto new
#'   lines (see [base::strwrap()]). `NULL` (default) leaves labels unwrapped.
#'
#' @return A character vector the same length as `x`.
#' @export
#' @examples
#' format_terms(c("(Intercept)", "b_conditionB", "freq:condition"))
#' format_terms("region:education:age", interaction = "asterisk")
format_terms <- function(x,
                         interaction = c("times", "asterisk", "colon", "space"),
                         strip_prefix = TRUE,
                         tidy_intercept = TRUE,
                         wrap = NULL) {
  interaction <- match.arg(interaction)
  x <- as.character(x)
  if (strip_prefix) {
    x <- stringr::str_replace(x, "^b[s]?_", "")
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
  if (!is.null(wrap)) {
    x <- vapply(
      x,
      function(s) paste(strwrap(s, width = wrap), collapse = "\n"),
      character(1)
    )
    x <- unname(x)
  }
  x
}
