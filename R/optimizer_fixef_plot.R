# Fixed effects across optimisers --------------------------------------------

#' Plot fixed effects across optimisers
#'
#' Visualises how the fixed-effect estimates of a mixed model vary across the
#' optimisers tried by [lme4::allFit()]. It offers a quick check that a model
#' has settled on a stable solution: tight clusters of points indicate
#' agreement between optimisers, whereas scatter signals a fragile fit.
#'
#' The function refactors the original `plot.fixef.allFit()` gist, using
#' faceting (one panel per fixed effect, each with its own y-axis) in place of
#' the earlier hand-built layout. It also accepts a plain data frame, so it can
#' be used without 'lme4'.
#'
#' @param x Either the object returned by [lme4::allFit()], or a data frame with
#'   one row per optimiser-by-term combination (columns such as `optimizer`,
#'   `term` and `value`/`estimate`).
#' @param intercept Whether to keep the intercept panel. Defaults to `TRUE`.
#' @param select_terms Optional character vector of terms to display (the
#'   intercept is always kept when `intercept = TRUE`).
#' @param interaction Passed to [format_terms()] for the panel titles.
#' @param labels Optional named character vector renaming the term panels, e.g.
#'   `c(conditionunrelated = "Unrelated priming")`. When `x` is a raw
#'   [lme4::allFit()] object, factor levels are prettified automatically (e.g.
#'   `conditionunrelated` to `condition: unrelated`) and these labels override
#'   that default.
#' @param number_optimizers Whether to prefix each optimiser name with a
#'   number, so that the legend doubles as an index.
#' @param free_y Whether to give each panel its own y-axis range. This is
#'   advisable, because the intercept and the slopes usually occupy very
#'   different scales.
#' @param ncol Number of facet columns. If `NULL`, chosen automatically.
#' @param point_size Point size.
#' @param palette Colours for the optimisers; defaults to [depictr_palette()].
#' @param y_lab,title Axis label and plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Without lme4, build the input data frame directly:
#' set.seed(1)
#' df <- expand.grid(
#'   optimizer = c("bobyqa", "Nelder_Mead", "nlminbwrap"),
#'   term = c("(Intercept)", "rainfall", "fertiliser")
#' )
#' df$value <- c(5, 5.01, 4.99, 0.3, 0.31, 0.29, -0.2, -0.18, -0.21)
#' optimizer_fixef_plot(df)
#'
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   m <- lme4::lmer(life_satisfaction ~ stress + (1 | region),
#'                   data = wellbeing_survey)
#'   af <- lme4::allFit(m)
#'   optimizer_fixef_plot(af)
#' }
#' }
optimizer_fixef_plot <- function(x,
                                 intercept = TRUE,
                                 select_terms = NULL,
                                 interaction = c("times", "asterisk",
                                                 "colon", "space"),
                                 labels = NULL,
                                 number_optimizers = TRUE,
                                 free_y = TRUE,
                                 ncol = NULL,
                                 point_size = 2,
                                 palette = NULL,
                                 y_lab = "Fixed effect",
                                 title = NULL) {
  interaction <- match.arg(interaction)
  df <- allfit_to_long(x)

  # When given a raw allFit() object (a list of fitted models), prettify factor
  # coefficient names by default (e.g. "conditionunrelated" -> "condition:
  # unrelated"); user-supplied `labels` take precedence. A summarised allFit or a
  # plain data frame carries no model, so there `labels` is used as given.
  if (inherits(x, "allFit") && length(x)) {
    labels <- merge_pretty_labels(labels, pretty_coef_map(x[[1]]))
  }

  if (!intercept) {
    df <- df[!df$term %in% c("(Intercept)", "Intercept"), , drop = FALSE]
  }
  if (!is.null(select_terms)) {
    keep <- df$term %in% select_terms |
      (intercept & df$term %in% c("(Intercept)", "Intercept"))
    df <- df[keep, , drop = FALSE]
  }
  if (nrow(df) == 0) {
    stop("No terms left to plot.", call. = FALSE)
  }

  if (number_optimizers) {
    lev <- unique(df$optimizer)
    df$optimizer <- factor(df$optimizer, levels = lev)
    df$optimizer <- factor(
      paste0(as.integer(df$optimizer), ". ", df$optimizer),
      levels = paste0(seq_along(lev), ". ", lev)
    )
  } else {
    df$optimizer <- factor(df$optimizer, levels = unique(df$optimizer))
  }

  term_levels <- unique(df$term)
  panel_lab <- function(t) make_labels(t, labels, interaction)
  df$panel <- factor(panel_lab(df$term), levels = panel_lab(term_levels))

  pal <- palette %||% depictr_palette(nlevels(df$optimizer))

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = 0, y = .data$value, colour = .data$optimizer)
  ) +
    ggplot2::geom_point(
      size = point_size,
      position = ggplot2::position_dodge(width = 0.6)
    )

  if (free_y) {
    # With free y-axes, optimisers that AGREE produce a per-panel range of a
    # few floating-point ULPs. The default break algorithm then zooms in and
    # prints the SAME rounded number on every break, exaggerating noise and
    # making a good (stable) fit look broken. Enforce a sensible minimum span
    # per panel so agreement reads as a tight cluster on a readable scale.
    limits <- facet_y_limits(df)
    p <- p +
      ggplot2::geom_blank(
        data = limits,
        ggplot2::aes(x = 0, y = .data$value),
        inherit.aes = FALSE
      ) +
      ggplot2::facet_wrap(
        ~ panel,
        scales = "free",
        ncol = ncol,
        labeller = ggplot2::label_wrap_gen(width = 24)
      ) +
      ggplot2::scale_y_continuous(labels = format_fixef_breaks)
  } else {
    p <- p +
      ggplot2::facet_wrap(
        ~ panel,
        scales = "free_x",
        ncol = ncol,
        labeller = ggplot2::label_wrap_gen(width = 24)
      )
  }

  p +
    ggplot2::scale_colour_manual(values = pal) +
    ggplot2::labs(x = NULL, y = y_lab, colour = "Optimiser", title = title) +
    theme_depictr(grid = "y") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank()
    )
}

# ---- internal helpers ------------------------------------------------------

#' Coerce an allFit object (or data frame) to long format
#' @noRd
allfit_to_long <- function(x) {
  if (is.data.frame(x)) {
    opt  <- intersect(c("optimizer", "Optimizer", "optimiser"), names(x))
    term <- intersect(c("term", "fixed_effect", "parameter", "Var2"), names(x))
    val  <- intersect(c("value", "estimate", "Estimate"), names(x))
    if (!length(opt) || !length(term) || !length(val)) {
      stop("A data frame input needs optimiser, term and value columns.",
           call. = FALSE)
    }
    out <- data.frame(
      optimizer = as.character(x[[opt[1]]]),
      term = as.character(x[[term[1]]]),
      value = as.numeric(x[[val[1]]]),
      stringsAsFactors = FALSE
    )
    return(out)
  }
  # `x` may already be a summarised allFit (e.g. the shipped inst/extdata
  # object), in which case `summary(x)` returns an atomic vector and
  # `summary(x)$fixef` errors with "$ operator is invalid for atomic vectors".
  if (inherits(x, "summary.allFit")) {
    fx <- x$fixef
  } else {
    ensure_installed("lme4", "to summarise an allFit() object")
    fx <- summary(x)$fixef
  }
  if (is.null(fx)) {
    stop("Could not extract fixed effects from the allFit object.",
         call. = FALSE)
  }
  fx <- as.matrix(fx)
  data.frame(
    optimizer = rep(rownames(fx), times = ncol(fx)),
    term = rep(colnames(fx), each = nrow(fx)),
    value = as.vector(fx),
    stringsAsFactors = FALSE
  )
}

#' Per-panel y-limits that enforce a sensible minimum range
#'
#' Returns two rows per panel (a low and a high limit) suitable for feeding to
#' [ggplot2::geom_blank()], so that each free y-axis spans at least a readable
#' window. When optimisers agree to several decimals the natural spread is a
#' handful of floating-point ULPs; without a floor on the range, the axis zooms
#' in until every break carries the same rounded label. The window is centred
#' on the panel's values and sized to the larger of the observed spread and a
#' small fraction of the magnitude (falling back to an absolute floor near
#' zero).
#' @noRd
facet_y_limits <- function(df) {
  panels <- split(df$value, df$panel)
  panels <- panels[!vapply(panels, function(v) all(is.na(v)), logical(1))]
  rows <- lapply(names(panels), function(nm) {
    v   <- panels[[nm]]
    v   <- v[is.finite(v)]
    mid <- mean(range(v))
    obs <- diff(range(v))
    # Minimum half-window: a small fraction of the magnitude, but never below
    # an absolute floor (keeps near-zero effects readable too).
    floor_abs  <- 1e-6
    floor_frac <- 0.001 * max(abs(v))
    half <- max(obs / 2, floor_frac, floor_abs)
    # Pad a little beyond the data so points are not flush against the border.
    half <- half * 1.1
    data.frame(
      panel = factor(nm, levels = levels(df$panel)),
      value = c(mid - half, mid + half),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Format fixed-effect axis breaks so repeated labels stay distinct
#'
#' Chooses the number of significant digits from the spread of the breaks, so a
#' tight cluster of nearly-equal values still gets distinguishable tick labels
#' instead of the same rounded number repeated down the axis.
#' @noRd
format_fixef_breaks <- function(breaks) {
  b <- breaks[is.finite(breaks)]
  if (!length(b)) return(format(breaks))
  span <- diff(range(b))
  if (span <= 0) {
    return(formatC(breaks, format = "g", digits = 4))
  }
  # Digits after the decimal needed to separate adjacent breaks, with a small
  # safety margin and a sane cap.
  decimals <- max(0, ceiling(-log10(span)) + 2)
  decimals <- min(decimals, 8)
  out <- formatC(breaks, format = "f", digits = decimals)
  trimws(out)
}
