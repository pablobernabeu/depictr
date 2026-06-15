# Forest / coefficient plot --------------------------------------------------

#' Forest (coefficient) plot
#'
#' Draws a horizontal point-and-interval ("forest") plot of model estimates.
#' The input can be a fitted model (anything [tidy_estimates()] understands) or
#' a data frame of pre-computed estimates.
#'
#' @param x A fitted model or a tidy data frame of estimates.
#' @param conf_level Confidence/credible level, passed to [tidy_estimates()]
#'   when `x` is a model.
#' @param intercept Whether to keep the intercept term. Defaults to `FALSE`,
#'   since the intercept is seldom of interest on a forest plot and its scale
#'   often overwhelms the other terms.
#' @param order Order the terms by estimate: `"none"` (keep input order),
#'   `"ascending"` or `"descending"`.
#' @param labels Optional display labels for the terms. Either a character
#'   vector the same length as the number of terms (in plotting order) or a
#'   named vector mapping raw term names to labels. If `NULL`, names are tidied
#'   with [format_terms()].
#' @param interaction Passed to [format_terms()] to control how interaction
#'   terms are rendered (ignored when `labels` is supplied).
#' @param point_colour,reference_colour Colours for the estimates and the
#'   reference line.
#' @param reference_line Position of a vertical reference line (e.g. `0` for
#'   differences, `1` for odds/risk ratios). Use `NA` to omit it.
#' @param point_size,line_size Size of the points and interval lines.
#' @param facet Whether to give each term its own panel with a free x-axis,
#'   laid out one per row. This removes the squish that occurs when terms live
#'   on very different scales (for example a large intercept alongside small
#'   slopes). Defaults to `FALSE`, preserving the shared-axis layout. A
#'   convenience alias for `scales = "free"`.
#' @param scales Either `"fixed"` (the default, a single shared x-axis) or
#'   `"free"` (one free-scaled panel per term). When `facet = TRUE` this is
#'   forced to `"free"`.
#' @param title,subtitle,x_lab Plot title, subtitle and x-axis label.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment,
#'           data = crop_yield)
#' coefficient_plot(fit)
#'
#' # Order terms and add a title
#' coefficient_plot(fit, order = "descending", title = "Drivers of crop yield")
#'
#' # When an intercept or large term squishes the rest, give each term its own
#' # free-scaled panel:
#' coefficient_plot(fit, intercept = TRUE, facet = TRUE)
coefficient_plot <- function(x,
                      conf_level = 0.95,
                      intercept = FALSE,
                      order = c("none", "ascending", "descending"),
                      labels = NULL,
                      interaction = c("times", "asterisk", "colon", "space"),
                      point_colour = depictr_brand(),
                      reference_colour = depictr_reference(),
                      reference_line = 0,
                      point_size = 2.2,
                      line_size = 0.7,
                      facet = FALSE,
                      scales = c("fixed", "free"),
                      title = NULL,
                      subtitle = NULL,
                      x_lab = "Estimate") {
  order <- match.arg(order)
  interaction <- match.arg(interaction)
  scales <- match.arg(scales)
  if (facet) scales <- "free"

  est <- tidy_estimates(x, conf_level = conf_level)

  if (!intercept) {
    est <- est[!est$term %in% c("(Intercept)", "Intercept", "b_Intercept"), ,
                drop = FALSE]
  }
  if (nrow(est) == 0) {
    stop("No terms left to plot (did you drop the only term?).", call. = FALSE)
  }

  est <- order_terms(est, order)

  est$label <- make_labels(est$term, labels, interaction)
  est$label <- factor(est$label, levels = est$label)

  p <- ggplot2::ggplot(
    est,
    ggplot2::aes(x = .data$estimate, y = .data$label)
  )

  # In the shared-axis layout the reference line spans the whole plot; in the
  # faceted layout it is drawn per panel (see add_term_facets()), so that a
  # large-intercept panel is not stretched back to the reference value.
  if (!is.na(reference_line) && scales == "fixed") {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line, linetype = 2, colour = reference_colour
    )
  }

  p <- p +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      orientation = "y", width = 0.18, linewidth = line_size,
      colour = point_colour, na.rm = TRUE
    ) +
    ggplot2::geom_point(size = point_size, colour = point_colour) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")

  if (scales == "free") {
    p <- add_term_facets(p, reference_line = reference_line,
                         reference_colour = reference_colour)
  }

  p
}

# ---- internal helpers ------------------------------------------------------

#' Lay a forest plot out one term per row, each panel free-scaled
#'
#' Adds a one-column `facet_wrap()` over the term `label`, with a free x-axis so
#' every estimate is legible regardless of scale, and blanks the now-redundant
#' y-axis text (the term name moves to the strip). Shared by [coefficient_plot()],
#' [compare_models()] and (through it) [frequentist_bayesian_plot()].
#'
#' A reference line is drawn per panel, but only in the panels whose data range
#' actually brackets it. Drawing it everywhere would force a free-scaled panel
#' (for example a large intercept) to stretch back to the reference value,
#' re-introducing the very squish that faceting is meant to remove.
#'
#' @param p A ggplot whose data has a `label` column (term label) mapped to `y`
#'   and `conf.low`/`conf.high` (or `outer_lo`/`outer_hi`) interval columns.
#' @param reference_line Position of the per-panel reference line (`NA` to omit).
#' @param reference_colour Colour of the reference line.
#' @noRd
add_term_facets <- function(p, reference_line = NA,
                            reference_colour = "grey60") {
  out <- p +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$label),
      ncol = 1, scales = "free", strip.position = "top",
      labeller = ggplot2::label_wrap_gen(width = 28)
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.spacing.y = ggplot2::unit(2, "pt")
    )

  if (!is.na(reference_line)) {
    ref <- reference_line_panels(p$data, reference_line)
    if (nrow(ref)) {
      out <- out + ggplot2::geom_vline(
        data = ref,
        ggplot2::aes(xintercept = .data$xintercept),
        linetype = 2, colour = reference_colour, inherit.aes = FALSE
      )
    }
  }
  out
}

#' Per-panel reference-line data: one row per term whose interval brackets it
#' @noRd
reference_line_panels <- function(df, reference_line) {
  lo_col <- if ("conf.low" %in% names(df)) "conf.low" else "outer_lo"
  hi_col <- if ("conf.high" %in% names(df)) "conf.high" else "outer_hi"
  lo <- tapply(df[[lo_col]], df$label, min, na.rm = TRUE)
  hi <- tapply(df[[hi_col]], df$label, max, na.rm = TRUE)
  keep <- is.finite(lo) & is.finite(hi) &
    reference_line >= lo & reference_line <= hi
  keep[is.na(keep)] <- FALSE
  if (!any(keep)) {
    return(data.frame(label = factor(character(0), levels = levels(df$label)),
                      xintercept = numeric(0)))
  }
  data.frame(
    label = factor(base::names(lo)[keep], levels = levels(df$label)),
    xintercept = reference_line,
    stringsAsFactors = FALSE
  )
}

#' @noRd
order_terms <- function(est, order) {
  if (order == "none") {
    est <- est[rev(seq_len(nrow(est))), , drop = FALSE]
  } else if (order == "ascending") {
    est <- est[order(est$estimate), , drop = FALSE]
  } else if (order == "descending") {
    est <- est[order(est$estimate, decreasing = TRUE), , drop = FALSE]
  }
  est
}

#' Build display labels for a set of terms
#' @noRd
make_labels <- function(terms, labels, interaction) {
  if (is.null(labels)) {
    return(format_terms(terms, interaction = interaction))
  }
  if (!is.null(names(labels))) {
    out <- labels[terms]
    out[is.na(out)] <- format_terms(terms[is.na(out)], interaction = interaction)
    return(unname(out))
  }
  if (length(labels) != length(terms)) {
    stop("`labels` has length ", length(labels), " but there are ",
         length(terms), " terms to label.", call. = FALSE)
  }
  labels
}
