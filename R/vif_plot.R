# Multicollinearity (VIF) plot -----------------------------------------------

#' Variance inflation factor plot
#'
#' Computes a variance inflation factor (VIF) for each column of a model's
#' design matrix and shows them as a bar chart, with reference lines at the
#' usual rules of thumb (VIF = 5 and VIF = 10). High bars flag predictors whose
#' coefficients are unstable because they are collinear with the others. VIFs
#' are computed from base R (no 'car' dependency).
#'
#' For models with multi-level factors, each dummy column is shown separately;
#' interpret those with care (a generalised VIF is more appropriate for factors
#' with several levels).
#'
#' @param model A fitted `lm` or `glm` model with at least two predictors.
#' @param threshold Reference value drawn as a solid line (a second, dashed line
#'   is drawn at `threshold / 2`).
#' @param palette Length-2 colours for VIFs below and above `threshold`.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
#' vif_plot(fit)
vif_plot <- function(model, threshold = 5,
                     palette = c("#005b96", "#e23b3b"), title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  X <- stats::model.matrix(model)
  int <- colnames(X) == "(Intercept)"
  X <- X[, !int, drop = FALSE]
  if (ncol(X) < 2) {
    stop("VIF needs at least two predictor columns.", call. = FALSE)
  }

  vifs <- vapply(seq_len(ncol(X)), function(j) {
    r2 <- summary(stats::lm(X[, j] ~ X[, -j, drop = FALSE]))$r.squared
    1 / (1 - r2)
  }, numeric(1))

  df <- data.frame(term = colnames(X), vif = vifs, stringsAsFactors = FALSE)
  df <- df[order(df$vif), , drop = FALSE]
  df$term <- factor(df$term, levels = df$term)
  df$flag <- df$vif >= threshold

  ggplot2::ggplot(df, ggplot2::aes(x = .data$vif, y = .data$term,
                                   fill = .data$flag)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_vline(xintercept = threshold / 2, linetype = 2,
                        colour = "grey55") +
    ggplot2::geom_vline(xintercept = threshold, linetype = 1,
                        colour = "grey40") +
    ggplot2::scale_fill_manual(
      values = c(`FALSE` = palette[1], `TRUE` = palette[2]), guide = "none"
    ) +
    ggplot2::labs(x = "Variance inflation factor", y = NULL, title = title) +
    theme_statviz(grid = "x")
}
