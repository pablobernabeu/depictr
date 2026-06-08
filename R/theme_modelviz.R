# Shared theme, palette and label helpers ------------------------------------

#' The modelviz colour palette
#'
#' A qualitative palette built around the blue/red pairing used for
#' Bayesian/frequentist comparisons, extended with complementary hues so that
#' it also works for several groups.
#'
#' @param n Number of colours to return. If `NULL` (the default) the full
#'   palette is returned. When `n` is larger than the palette,
#'   [grDevices::colorRampPalette()] is used to interpolate.
#'
#' @return A character vector of hex colour codes.
#' @export
#' @examples
#' modelviz_palette(2)
#' scales::show_col(modelviz_palette())
modelviz_palette <- function(n = NULL) {
  base <- c(
    blue   = "#005b96",
    red    = "#e23b3b",
    green  = "#2e8b57",
    orange = "#e08a1e",
    purple = "#7b539e",
    teal   = "#1c9aa8",
    pink   = "#cc5b8e",
    grey   = "#5a5a5a"
  )
  if (is.null(n)) return(unname(base))
  if (!is.numeric(n) || length(n) != 1 || n < 1) {
    stop("`n` must be a single positive number.", call. = FALSE)
  }
  n <- as.integer(n)
  if (n <= length(base)) return(unname(base[seq_len(n)]))
  grDevices::colorRampPalette(unname(base))(n)
}

#' modelviz colour and fill scales
#'
#' Discrete ggplot2 scales using [modelviz_palette()].
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 scale that can be added to a plot.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
#'   geom_point() +
#'   scale_colour_modelviz() +
#'   theme_modelviz()
scale_colour_modelviz <- function(...) {
  ggplot2::discrete_scale(
    "colour", "modelviz",
    palette = function(n) modelviz_palette(n),
    ...
  )
}

#' @rdname scale_colour_modelviz
#' @export
scale_color_modelviz <- scale_colour_modelviz

#' @rdname scale_colour_modelviz
#' @export
scale_fill_modelviz <- function(...) {
  ggplot2::discrete_scale(
    "fill", "modelviz",
    palette = function(n) modelviz_palette(n),
    ...
  )
}

#' The modelviz ggplot2 theme
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
#'   theme_modelviz()
theme_modelviz <- function(base_size = 11, base_family = "", grid = "xy") {
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
#' @param strip_prefix Remove a leading `b_` or `bs_` (as added by 'brms')?
#' @param tidy_intercept Replace `(Intercept)` with `"Intercept"`?
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
