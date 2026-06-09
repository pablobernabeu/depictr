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
#' @param intercept Keep the intercept term? Defaults to `FALSE`, as the
#'   intercept is rarely of interest on a forest plot and its scale often
#'   dwarfs the other terms.
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
coefficient_plot <- function(x,
                      conf_level = 0.95,
                      intercept = FALSE,
                      order = c("none", "ascending", "descending"),
                      labels = NULL,
                      interaction = c("times", "asterisk", "colon", "space"),
                      point_colour = "#005b96",
                      reference_colour = "grey60",
                      reference_line = 0,
                      point_size = 2.2,
                      line_size = 0.7,
                      title = NULL,
                      subtitle = NULL,
                      x_lab = "Estimate") {
  order <- match.arg(order)
  interaction <- match.arg(interaction)

  est <- if (inherits(x, "data.frame")) {
    tidy_estimates(x, conf_level = conf_level)
  } else {
    tidy_estimates(x, conf_level = conf_level)
  }

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

  if (!is.na(reference_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line, linetype = 2, colour = reference_colour
    )
  }

  p <- p +
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      height = 0.18, linewidth = line_size, colour = point_colour,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(size = point_size, colour = point_colour) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")

  p
}

# ---- internal helpers ------------------------------------------------------

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
