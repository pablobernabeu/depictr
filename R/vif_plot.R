# Multicollinearity (VIF) plot -----------------------------------------------

#' Variance inflation factor plot
#'
#' Computes a variance inflation factor for each *term* in a model and shows
#' them as a bar chart, with a reference line at the usual rule of thumb
#' (`threshold`). High bars flag predictors whose coefficients are unstable
#' because they are collinear with the others. Values are computed from base R
#' (no 'car' dependency).
#'
#' For single-degree-of-freedom terms this is the ordinary VIF, \eqn{1/(1-R^2)}.
#' For terms that span several design-matrix columns (multi-level factors, or
#' spline/polynomial bases) the function reports the generalised VIF of Fox and
#' Monette (1992): with \eqn{R} the correlation matrix of the (centred)
#' predictor columns, \eqn{R_{11}} the block for the term and \eqn{R_{22}} the
#' block for the remaining columns,
#' \deqn{\mathrm{GVIF} = \frac{\det(R_{11})\,\det(R_{22})}{\det(R)}.}
#' When every term has a single degree of freedom the bars are the ordinary
#' VIFs, on a plain "Variance inflation factor" axis with the reference line at
#' `threshold`. If any term spans several columns the bars switch to the
#' comparable \eqn{\mathrm{GVIF}^{1/(2\,\mathrm{df})}} (which for a single-df
#' term equals \eqn{\sqrt{\mathrm{VIF}}}) and the reference line moves to
#' \eqn{\sqrt{\mathrm{threshold}}} accordingly. The x-axis is kept tight to the
#' data: when every bar is comfortably below the threshold the line is reported
#' in the caption rather than drawn into a wide empty band.
#'
#' @param model A fitted `lm` or `glm` model with at least two predictors.
#' @param threshold Reference value for the ordinary VIF, drawn as a line. For
#'   models with multi-column terms it is shown on the
#'   \eqn{\mathrm{GVIF}^{1/(2\,\mathrm{df})}} scale as
#'   \eqn{\sqrt{\mathrm{threshold}}}.
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
#' fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
#' vif_plot(fit)
#'
#' # Multi-level factors get a single generalised VIF per term
#' fit2 <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
#' vif_plot(fit2)
vif_plot <- function(model, threshold = 5,
                     palette = depictr_palette(2), title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }

  res <- gvif_terms(model)
  multi <- any(res$df > 1)

  # Single-degree-of-freedom terms are shown as the ordinary VIF on a plain
  # "Variance inflation factor" axis, with the reference lines at the actual
  # `threshold` and its half -- so a bar at 1 against a line at 5 reads
  # honestly. Multi-df terms have no scalar VIF, so the comparable
  # GVIF^(1/(2*df)) is plotted and the lines sit at the square roots of the VIF
  # thresholds (Fox & Monette).
  if (multi) {
    value <- res$gvif_adj
    line_main <- sqrt(threshold)
    x_lab <- expression(GVIF^{1 / (2 * df)})
  } else {
    value <- res$gvif
    line_main <- threshold
    x_lab <- "Variance inflation factor"
  }

  df <- data.frame(term = res$term, vif = value, stringsAsFactors = FALSE)
  df <- df[order(df$vif), , drop = FALSE]
  df$term <- factor(df$term, levels = df$term)
  df$flag <- factor(ifelse(df$vif >= line_main, "above", "below"),
                    levels = c("below", "above"))

  # Scale the axis to the data so the bars stay prominent. Draw the single
  # threshold line when it falls within that range; when every value is
  # comfortably below it, note it in the caption rather than stranding a line in
  # a wide empty band (which is both wasteful and hard to read).
  upper <- max(df$vif) * 1.5
  lab_main <- paste0("VIF = ", format(threshold))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$vif, y = .data$term,
                                        fill = .data$flag)) +
    ggplot2::geom_col(width = 0.7)
  caption <- NULL
  if (line_main <= upper) {
    p <- p +
      ggplot2::geom_vline(xintercept = line_main, linetype = 1,
                          colour = "grey40") +
      ggplot2::annotate("text", x = line_main, y = Inf, vjust = 1.3,
                        hjust = -0.08, label = lab_main, colour = "grey40",
                        size = 3, fontface = "italic")
  } else {
    caption <- paste0("Threshold ", lab_main,
                      " is off the axis (every value is well below it).")
  }

  p +
    ggplot2::scale_fill_manual(
      name = NULL,
      values = c(below = palette[1], above = palette[2]),
      breaks = c("below", "above"),
      labels = c(paste0("VIF < ", format(threshold)),
                 paste0("VIF >= ", format(threshold))),
      drop = FALSE
    ) +
    ggplot2::scale_x_continuous(limits = c(0, upper),
                                expand = ggplot2::expansion(mult = c(0, 0.02))) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, caption = caption) +
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
