# Posterior distributions -----------------------------------------------------

#' Plot posterior distributions
#'
#' Displays posterior (or, more generally, bootstrap or simulation) draws as a
#' *distribution* per parameter, in the style of a half-eye (a density slab with
#' a point-and-interval beneath it), an interval-only forest plot, a gradient
#' interval or a dotplot. The full shape of the posterior is shown, so skew,
#' multimodality and the relative mass on either side of a reference value are
#' all visible -- not just a point and two limits.
#'
#' Draws may be supplied in many shapes: a fitted Bayesian model (`brms` or
#' `rstanarm`), a `posterior` *draws* object, a wide data frame or matrix with
#' one column of draws per parameter, or a long data frame (a parameter column
#' and a value column). For fitted models only the fixed-effect (population)
#' parameters are kept, with the `brms` `b_` prefix stripped.
#'
#' The slab styles use the 'ggdist' package. When 'ggdist' is not installed the
#' function falls back to the point-and-nested-interval display (equivalent to
#' `style = "interval"`) and emits an informative message.
#'
#' @param draws Posterior draws: a fitted model (`brms`/`rstanarm`), a
#'   `posterior` draws object, a matrix, or a long/wide data frame (see
#'   Details).
#' @param style One of `"halfeye"` (density slab + interval, the default),
#'   `"interval"` (point and two nested intervals, no slab), `"gradient"` (a
#'   colour-graded interval) or `"dots"` (a quantile dotplot). Unknown values
#'   and a missing 'ggdist' fall back to `"interval"`.
#' @param point Central summary: `"median"` or `"mean"`.
#' @param widths Two interval widths (inner and outer), as probabilities. The
#'   outer width is used for the caption and the displayed interval mass.
#' @param interaction Passed to [format_terms()] for the parameter labels.
#' @param labels Optional named character vector renaming parameters, e.g.
#'   `c(conditionunrelated = "unrelated")`. Unmatched parameters fall
#'   back to [format_terms()].
#' @param reference_line Position of a vertical reference line, or `NULL`/`NA`
#'   to omit it. There is no universally meaningful reference for every
#'   parameter, so this defaults to `0` (the usual "no effect" line for
#'   differences and slopes) but should be set or cleared deliberately.
#' @param rope Optional length-2 numeric `c(lo, hi)` giving a region of
#'   practical equivalence to shade behind the distributions.
#' @param pd If `TRUE`, annotate each parameter with its probability of
#'   direction relative to `reference_line` -- the posterior probability that
#'   the parameter lies on its majority side of the reference (a value in
#'   \[0.5, 1\]). Requires a finite `reference_line`.
#' @param facet Whether to give each parameter its own panel with a free
#'   x-axis, laid out one per row. This keeps the small parameters legible when
#'   a large one (typically the intercept) would otherwise stretch the shared
#'   axis and squish the rest. Defaults to `FALSE`. A convenience alias for
#'   `scales = "free"`.
#' @param scales Either `"fixed"` (the default, a single shared x-axis) or
#'   `"free"` (one free-scaled panel per parameter). When `facet = TRUE` this is
#'   forced to `"free"`.
#' @param colour,fill Colours for the point/interval and for the density slab.
#'   Default to the depictr brand blue.
#' @param rope_fill,rope_alpha Fill colour and opacity of the ROPE band.
#' @param title,x_lab Plot title and value-axis label.
#' @param caption Plot caption. The default (`NULL`) auto-captions the interval
#'   mass; pass `NA` to omit a caption.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Wide draws: one column per parameter
#' set.seed(1)
#' draws <- data.frame(
#'   intercept = rnorm(400, 5, 0.3),
#'   slope = rnorm(400, 0.8, 0.15),
#'   `slope:group` = rnorm(400, -0.2, 0.2),
#'   check.names = FALSE
#' )
#' posterior_plot(draws)
#'
#' # A region of practical equivalence and a probability-of-direction label
#' posterior_plot(draws, rope = c(-0.1, 0.1), pd = TRUE)
#'
#' # When one parameter dwarfs the others, give each its own free-scaled panel:
#' \donttest{
#' posterior_plot(draws, facet = TRUE)
#' }
posterior_plot <- function(draws,
                           style = c("halfeye", "interval", "gradient",
                                     "dots"),
                           point = c("median", "mean"),
                           widths = c(0.66, 0.95),
                           interaction = c("times", "asterisk", "colon",
                                           "space"),
                           labels = NULL,
                           reference_line = 0,
                           rope = NULL,
                           pd = FALSE,
                           facet = FALSE,
                           scales = c("fixed", "free"),
                           colour = depictr_brand(),
                           fill = depictr_brand(),
                           rope_fill = depictr_reference(),
                           rope_alpha = 0.15,
                           title = NULL, x_lab = "Value",
                           caption = NULL) {
  style <- match.arg(style)
  point <- match.arg(point)
  interaction <- match.arg(interaction)
  scales <- match.arg(scales)
  if (facet) scales <- "free"
  if (length(widths) != 2) stop("`widths` must have two values.", call. = FALSE)
  widths <- sort(widths)

  ref <- if (is.null(reference_line) || all(is.na(reference_line))) {
    NA_real_
  } else {
    reference_line[1]
  }

  # Normalise every supported input to one long draws table. A plain long/wide
  # data frame still flows through the original draws_to_long() so its existing
  # tests and behaviour are preserved exactly.
  long <- normalise_posterior_draws(draws)

  params <- unique(long$term)
  point_fun <- if (point == "median") stats::median else mean

  # Per-parameter summaries (used for the interval style, the slab point, the
  # caption and the probability-of-direction labels).
  summ <- do.call(rbind, lapply(params, function(p) {
    v <- long$.value[long$term == p]
    inner <- stats::quantile(v, c((1 - widths[1]) / 2, 1 - (1 - widths[1]) / 2),
                             names = FALSE, na.rm = TRUE)
    outer <- stats::quantile(v, c((1 - widths[2]) / 2, 1 - (1 - widths[2]) / 2),
                             names = FALSE, na.rm = TRUE)
    pd_val <- if (!is.na(ref)) prob_direction(v, ref) else NA_real_
    data.frame(term = p, centre = point_fun(v, na.rm = TRUE),
               inner_lo = inner[1], inner_hi = inner[2],
               outer_lo = outer[1], outer_hi = outer[2],
               pd = pd_val, stringsAsFactors = FALSE)
  }))

  lab_of <- function(term) make_labels(term, labels, interaction)
  lvls <- rev(lab_of(params))
  label_for <- function(term) factor(lab_of(term), levels = lvls)
  summ$label <- label_for(summ$term)
  long$label <- label_for(long$term)

  use_ggdist <- style != "interval" && requireNamespace("ggdist", quietly = TRUE)
  if (style != "interval" && !use_ggdist) {
    message("Package 'ggdist' is not installed; falling back to ",
            "style = \"interval\". Install it with install.packages('ggdist').")
    style <- "interval"
  }

  p <- ggplot2::ggplot()

  # ROPE band sits behind everything else.
  if (!is.null(rope)) {
    if (length(rope) != 2 || !is.numeric(rope)) {
      stop("`rope` must be a length-2 numeric vector c(lo, hi).", call. = FALSE)
    }
    rope <- sort(rope)
    p <- p + ggplot2::annotate(
      "rect", xmin = rope[1], xmax = rope[2], ymin = -Inf, ymax = Inf,
      fill = rope_fill, alpha = rope_alpha
    )
  }
  # Shared-axis layout draws one full-height reference line; the faceted layout
  # draws it per panel below (only where the interval brackets it), so a
  # large-intercept panel is not stretched back to the reference value.
  if (!is.na(ref) && scales == "fixed") {
    p <- p + ggplot2::geom_vline(xintercept = ref, linetype = 2,
                                 colour = depictr_reference())
  }

  if (use_ggdist) {
    p <- p + posterior_slab_layer(long, style, widths, point, colour, fill)
  } else {
    p <- p + posterior_interval_layers(summ, colour)
  }

  if (isTRUE(pd)) {
    if (is.na(ref)) {
      message("`pd = TRUE` needs a finite `reference_line`; skipping the ",
              "probability-of-direction annotation.")
    } else {
      p <- p + posterior_pd_layer(summ)
    }
  }

  cap <- if (is.null(caption)) {
    sprintf("Point: posterior %s. Intervals: %g%% and %g%% credible.",
            point, widths[1] * 100, widths[2] * 100)
  } else if (length(caption) == 1 && is.na(caption)) {
    NULL
  } else {
    caption
  }

  p <- p +
    ggplot2::labs(x = x_lab, y = NULL, title = title, caption = cap) +
    theme_depictr(grid = "x")

  # Free-scaled, one-parameter-per-row layout: keeps small parameters legible
  # when a large one (typically the intercept) would otherwise stretch the
  # shared axis and squish the rest.
  if (scales == "free") {
    if (!is.na(ref)) {
      brack <- ref >= summ$outer_lo & ref <= summ$outer_hi
      if (any(brack)) {
        refdf <- summ[brack, "label", drop = FALSE]
        refdf$xref <- ref
        p <- p + ggplot2::geom_vline(
          data = refdf, ggplot2::aes(xintercept = .data$xref),
          linetype = 2, colour = depictr_reference(), inherit.aes = FALSE
        )
      }
    }
    p <- p +
      ggplot2::facet_wrap(ggplot2::vars(.data$label), ncol = 1,
                          scales = "free", strip.position = "top",
                          labeller = ggplot2::label_wrap_gen(width = 28)) +
      ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                     axis.ticks.y = ggplot2::element_blank(),
                     panel.spacing.y = ggplot2::unit(2, "pt"))
  }
  p
}

# ---- rendering helpers (ggdist) --------------------------------------------

#' Build the ggdist slab/interval layer for a given style
#' @noRd
posterior_slab_layer <- function(long, style, widths, point, colour, fill) {
  point_interval <- if (point == "median") "median_qi" else "mean_qi"
  common <- list(
    ggplot2::aes(x = .data$.value, y = .data$label),
    data = long,
    .width = widths,
    point_interval = point_interval,
    colour = colour,
    na.rm = TRUE
  )
  switch(style,
    halfeye = do.call(ggdist::stat_halfeye,
                      c(common, list(fill = fill, slab_alpha = 0.6))),
    gradient = do.call(ggdist::stat_gradientinterval,
                       c(common, list(fill = fill))),
    dots = do.call(ggdist::stat_dotsinterval,
                   c(common, list(fill = fill, slab_colour = NA)))
  )
}

#' Point + two nested intervals (the interval style and the no-ggdist fallback)
#' @noRd
posterior_interval_layers <- function(summ, colour) {
  list(
    ggplot2::geom_linerange(
      data = summ,
      ggplot2::aes(y = .data$label, xmin = .data$outer_lo,
                   xmax = .data$outer_hi),
      linewidth = 0.6, colour = colour
    ),
    ggplot2::geom_linerange(
      data = summ,
      ggplot2::aes(y = .data$label, xmin = .data$inner_lo,
                   xmax = .data$inner_hi),
      linewidth = 1.8, colour = colour
    ),
    ggplot2::geom_point(
      data = summ, ggplot2::aes(x = .data$centre, y = .data$label),
      size = 2.2, colour = "white"
    ),
    ggplot2::geom_point(
      data = summ, ggplot2::aes(x = .data$centre, y = .data$label),
      size = 1.4, colour = colour
    )
  )
}

#' Probability-of-direction text, placed at the right edge of each row
#' @noRd
posterior_pd_layer <- function(summ) {
  summ$pd_label <- ifelse(is.na(summ$pd), NA_character_,
                          paste0("pd = ", format(round(summ$pd * 100, 1),
                                                 nsmall = 1), "%"))
  ggplot2::geom_text(
    data = summ,
    ggplot2::aes(x = .data$outer_hi, y = .data$label, label = .data$pd_label),
    hjust = -0.1, vjust = 0.5, size = 3, colour = depictr_reference(),
    na.rm = TRUE
  )
}

# ---- internal helpers -------------------------------------------------------

#' Probability of direction relative to a reference
#'
#' The posterior probability that the parameter lies on its majority side of
#' `ref`: `max(P(value > ref), P(value < ref))`, a value in \[0.5, 1\].
#' @noRd
prob_direction <- function(v, ref = 0) {
  v <- v[!is.na(v)]
  if (!length(v)) return(NA_real_)
  above <- mean(v > ref)
  max(above, 1 - above)
}

#' Normalise the `draws` argument of posterior_plot() to a long table
#'
#' A plain long/wide data frame uses the original `draws_to_long()` path so its
#' established behaviour and tests are untouched; richer Bayesian inputs (fits,
#' draws objects, matrices) route through `extract_draws()`.
#' @noRd
normalise_posterior_draws <- function(draws) {
  if (is.data.frame(draws)) {
    long <- draws_to_long(draws)
    return(data.frame(term = long$parameter, .value = long$value,
                      stringsAsFactors = FALSE))
  }
  ed <- extract_draws(draws)
  data.frame(term = ed$term, .value = ed$.value, stringsAsFactors = FALSE)
}

#' @noRd
draws_to_long <- function(draws) {
  if (!is.data.frame(draws)) stop("`draws` must be a data frame.", call. = FALSE)
  par_col <- intersect(c("parameter", "term", ".variable", "variable"),
                       names(draws))
  val_col <- intersect(c("value", ".value", "draw", "estimate"), names(draws))
  if (length(par_col) && length(val_col)) {
    long <- data.frame(parameter = as.character(draws[[par_col[1]]]),
                       value = as.numeric(draws[[val_col[1]]]),
                       stringsAsFactors = FALSE)
    return(long[!is.na(long$value), , drop = FALSE])
  }
  # Wide form: each remaining numeric column is one parameter. Known sampler
  # index/book-keeping columns are not parameters and must be dropped first.
  index_cols <- c(".chain", ".iteration", ".draw", "draw", "chain",
                  "iteration", ".row")
  num <- names(draws)[vapply(draws, is.numeric, logical(1))]
  num <- setdiff(num, index_cols)
  if (length(num) < 1) {
    stop("Could not find draws: supply long (parameter + value) or wide ",
         "(numeric columns) data.", call. = FALSE)
  }
  long <- data.frame(
    parameter = rep(num, each = nrow(draws)),
    value = unlist(draws[num], use.names = FALSE),
    stringsAsFactors = FALSE
  )
  long[!is.na(long$value), , drop = FALSE]
}
