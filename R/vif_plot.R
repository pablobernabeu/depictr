# Multicollinearity (VIF) plot -----------------------------------------------

#' Variance inflation factor plot
#'
#' Computes a variance inflation factor for each *term* in a model and shows
#' them as a bar chart, with reference lines at the usual rules of thumb
#' (`threshold` and `threshold / 2`). High bars flag predictors whose
#' coefficients are unstable because they are collinear with the others. Values
#' are computed from base R (no 'car' dependency).
#'
#' For single-degree-of-freedom terms this is the ordinary VIF, \eqn{1/(1-R^2)}.
#' For terms that span several design-matrix columns (multi-level factors, or
#' spline/polynomial bases) the function reports the generalised VIF of Fox and
#' Monette (1992): with \eqn{R} the correlation matrix of the (centred)
#' predictor columns, \eqn{R_{11}} the block for the term and \eqn{R_{22}} the
#' block for the remaining columns,
#' \deqn{\mathrm{GVIF} = \frac{\det(R_{11})\,\det(R_{22})}{\det(R)}.}
#' Because a GVIF for a term with \eqn{\mathrm{df}} columns is on the scale of a
#' squared inflation raised to \eqn{\mathrm{df}}, the plot shows the comparable
#' quantity \eqn{\mathrm{GVIF}^{1/(2\,\mathrm{df})}} so that every bar is on the
#' same (single-df VIF-like) scale; the reference lines are squared
#' accordingly. For single-df terms \eqn{\mathrm{GVIF}^{1/(2\,\mathrm{df})}}
#' equals \eqn{\sqrt{\mathrm{VIF}}}.
#'
#' @param model A fitted `lm` or `glm` model with at least two predictors.
#' @param threshold Reference value for the ordinary VIF, drawn as a solid line
#'   (a second, dashed line is drawn at `threshold / 2`). On the
#'   \eqn{\mathrm{GVIF}^{1/(2\,\mathrm{df})}} scale used by the bars these become
#'   \eqn{\sqrt{\mathrm{threshold}}} and \eqn{\sqrt{\mathrm{threshold}/2}}.
#' @param palette Length-2 colours encoding terms below and above the threshold.
#'   Defaults to the colourblind-safe [depictr_palette()] pair (blue / orange).
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @references
#' Fox, J. and Monette, G. (1992) Generalized collinearity diagnostics.
#' \emph{Journal of the American Statistical Association}, 87, 178-183.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
#' vif_plot(fit)
#'
#' # Multi-level factors get a single generalised VIF per term
#' fit2 <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
#' vif_plot(fit2)
vif_plot <- function(model, threshold = 5,
                     palette = depictr_palette(2), title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }

  res <- gvif_terms(model)

  # The bars are on the GVIF^(1/(2*df)) scale; map the VIF-scale `threshold`
  # (and its half) onto that scale by taking square roots.
  thr <- sqrt(threshold)
  thr_half <- sqrt(threshold / 2)

  df <- data.frame(term = res$term, vif = res$gvif_adj,
                   stringsAsFactors = FALSE)
  df <- df[order(df$vif), , drop = FALSE]
  df$term <- factor(df$term, levels = df$term)
  df$flag <- factor(ifelse(df$vif >= thr, "above", "below"),
                    levels = c("below", "above"))

  # Adapt the x-range to the data and the reference lines, so the bars are not
  # squeezed to the left with a wide empty band on the right.
  upper <- max(c(df$vif, thr)) * 1.12

  x_lab <- if (any(res$df > 1)) {
    expression(GVIF^{1 / (2 * df)})
  } else {
    "Variance inflation factor"
  }

  ggplot2::ggplot(df, ggplot2::aes(x = .data$vif, y = .data$term,
                                   fill = .data$flag)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_vline(xintercept = thr_half, linetype = 2,
                        colour = depictr_reference()) +
    ggplot2::geom_vline(xintercept = thr, linetype = 1,
                        colour = "grey40") +
    # Label the threshold guides in place, staggered so they never collide when
    # the two lines sit close together at a large-VIF range.
    ggplot2::annotate("text", x = thr, y = Inf, vjust = 1.3, hjust = -0.1,
                      label = paste0("VIF = ", format(threshold)),
                      colour = "grey40", size = 3, fontface = "italic") +
    ggplot2::annotate("text", x = thr_half, y = Inf, vjust = 3.0, hjust = -0.1,
                      label = paste0("VIF = ", format(threshold / 2)),
                      colour = depictr_reference(), size = 3,
                      fontface = "italic") +
    ggplot2::scale_fill_manual(
      name = NULL,
      values = c(below = palette[1], above = palette[2]),
      breaks = c("below", "above"),
      labels = c(paste0("VIF < ", format(threshold)),
                 paste0("VIF >= ", format(threshold))),
      drop = FALSE
    ) +
    ggplot2::scale_x_continuous(limits = c(0, upper),
                                expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = x_lab, y = NULL, title = title) +
    theme_depictr(grid = "x") +
    ggplot2::theme(legend.position = "top", legend.justification = "right")
}

# ---- internal helpers ------------------------------------------------------

#' Generalised variance inflation factors, one per model term
#'
#' Groups the design-matrix columns belonging to each model term and returns the
#' Fox-Monette generalised VIF together with the adjusted value
#' `GVIF^(1/(2*df))` that puts every term on a common scale. Single-df terms
#' reduce to the ordinary VIF.
#' @return A data frame with columns `term`, `df`, `gvif` and `gvif_adj`.
#' @noRd
gvif_terms <- function(model) {
  X <- stats::model.matrix(model)
  assign <- attr(X, "assign")
  term_labels <- attr(stats::terms(model), "term.labels")

  # Drop the intercept column (assign == 0); it is not a predictor.
  keep <- assign != 0
  X <- X[, keep, drop = FALSE]
  assign <- assign[keep]
  if (ncol(X) < 2) {
    stop("VIF needs at least two predictor columns.", call. = FALSE)
  }

  R <- stats::cor(X)
  detR <- det(R)
  terms_present <- sort(unique(assign))

  rows <- lapply(terms_present, function(t) {
    cols <- which(assign == t)
    others <- which(assign != t)
    dfi <- length(cols)
    # GVIF = det(R[term]) * det(R[others]) / det(R). For a single column
    # det(R[term]) = 1, so this is the usual 1/(1-R^2_j).
    gvif <- det(R[cols, cols, drop = FALSE]) *
      det(R[others, others, drop = FALSE]) / detR
    data.frame(
      term = term_labels[t],
      df = dfi,
      gvif = gvif,
      gvif_adj = gvif^(1 / (2 * dfi)),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
