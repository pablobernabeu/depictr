# One-figure model report ----------------------------------------------------

#' A one-figure model report
#'
#' Assembles a compact, consistent overview of a fitted model in a single
#' figure: the coefficient estimates, the predicted effect of a focal predictor,
#' a residuals-against-fitted plot and a normal Q-Q plot, with a subtitle of key
#' fit statistics. It is a convenience wrapper that composes several depictr
#' plots with [arrange_plots()], and serves well for a rapid model review or a
#' report appendix.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param predictor Focal predictor for the effect panel. If `NULL`, the first
#'   numeric predictor (or, failing that, the first predictor) is used.
#' @param standardize Whether the coefficient panel shows standardised
#'   coefficients (each scaled by its predictor's standard deviation). Defaults
#'   to `TRUE`, which keeps the panel readable in this compact overview by
#'   putting predictors on a common scale; set `FALSE` for raw estimates.
#' @param title Overall title.
#' @param subtitle Overall subtitle. If `NULL`, a line of fit statistics
#'   (number of observations, R-squared and AIC) is used.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment,
#'           data = crop_yield)
#' model_report(fit, title = "Crop-yield model")
#'
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' model_report(gfit)
model_report <- function(model, predictor = NULL, standardize = TRUE,
                         title = NULL, subtitle = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  mf <- stats::model.frame(model)
  preds <- names(mf)[-1]
  if (length(preds) == 0) stop("The model has no predictors.", call. = FALSE)
  if (is.null(predictor)) {
    numeric_preds <- preds[vapply(mf[preds], is.numeric, logical(1))]
    predictor <- if (length(numeric_preds)) numeric_preds[1] else preds[1]
  }

  p_coef <- coefficient_plot(
    model, standardize = standardize,
    title = if (standardize) "Coefficients (standardised)" else "Coefficients"
  )
  p_eff <- effects_plot(model, predictor,
                        title = paste("Effect of", predictor))
  p_qq <- qq_plot(model, title = "Normal Q-Q")
  rf <- data.frame(fitted = stats::fitted(model),
                   resid = stats::residuals(model))
  p_rf <- diag_scatter(rf, "fitted", "resid", "Fitted values", "Residuals",
                       "Residuals vs. fitted", 0.6, TRUE, hline = 0)

  if (is.null(subtitle)) {
    n <- tryCatch(stats::nobs(model), error = function(e) NA_integer_)
    r2 <- fit_r2(model)
    aic <- tryCatch(stats::AIC(model), error = function(e) NA_real_)
    r2_lab <- if (inherits(model, "glm")) "pseudo-R\u00b2" else "R\u00b2"
    subtitle <- sprintf("n = %s   |   %s = %.3f   |   AIC = %.1f",
                        n, r2_lab, r2, aic)
  }

  arrange_plots(
    p_coef, p_eff, p_rf, p_qq,
    ncol = 2,
    title = title %||% "Model report",
    subtitle = subtitle,
    tag_levels = "A"
  )
}
