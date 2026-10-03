# One-figure model report ----------------------------------------------------

#' A one-figure model report
#'
#' Assembles a compact, consistent overview of a fitted model in a single
#' figure: the coefficient estimates, the predicted effect of a focal predictor,
#' a residual panel and a normal Q-Q plot, with a subtitle of key fit
#' statistics. It is a convenience wrapper that composes several depictr
#' plots with [arrange_plots()], and serves well for a rapid model review or a
#' report appendix.
#'
#' For an `lm`, the residual panel plots the residuals against the fitted
#' values, and the Q-Q panel is [qq_plot()] of the standardised residuals. A
#' `glm` gets the panels [residual_diagnostics_plot()] draws for it
#' (`glm_panels = TRUE`). The residual panel is a [binned_residual_plot()]
#' (Gelman & Hill, 2007). The Q-Q panel plots randomised quantile residuals
#' (Dunn & Smyth, 1996), which are standard normal under a correctly specified
#' model whatever the response family, so the band of [qq_plot()] applies to
#' them. The standardised deviance residuals of a binary or count model are
#' not expected to be normal, so even a correctly specified model can put many
#' of them outside that band (about a third, in a simulated logistic model with
#' 400 observations). The quantile residuals of a binomial or Poisson model are
#' randomised, and even under a correct model a run of them occasionally
#' leaves the pointwise band. A departure worth acting on persists when the
#' panel is drawn again with another `seed`. For a family with no quantile
#' residual here, such as a quasi-likelihood family, the Q-Q panel plots the
#' deviance residuals and its axis says so.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param predictor Focal predictor for the effect panel, given as in
#'   [effects_plot()]. If `NULL`, the first numeric variable in the formula (or,
#'   failing that, the first variable) is used, so a model with
#'   `log(rainfall)` shows the effect of `rainfall`.
#' @param standardise Whether the coefficient panel shows standardised
#'   coefficients (each scaled by its predictor's standard deviation). Defaults
#'   to `TRUE`, which keeps the panel readable in this compact overview by
#'   putting predictors on a common scale; set `FALSE` for raw estimates.
#' @param title Overall title.
#' @param subtitle Overall subtitle. If `NULL`, a line of fit statistics
#'   (number of observations, R-squared and AIC) is used. For a `glm`, the
#'   R-squared is the deviance R-squared described in [model_fit_table()].
#' @param glm_panels For a `glm`, whether to draw the binned-residual and
#'   quantile-residual panels (the default) instead of the classic `lm`
#'   panels. Ignored for an `lm`.
#' @param seed Optional integer seed for the randomisation of discrete
#'   quantile residuals, for a reproducible Q-Q panel of a binomial or Poisson
#'   `glm`. The caller's random number stream is left as it was.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @references
#' \insertRef{gelman2007}{depictr}
#'
#' \insertRef{dunn1996}{depictr}
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
#'           data = crop_yield)
#' model_report(fit, title = "Crop-yield model")
#'
#' # A logistic model gets binned and quantile-residual panels, and a seed
#' # fixes the randomisation of its quantile residuals:
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' model_report(gfit, seed = 1)
model_report <- function(model, predictor = NULL, standardise = TRUE,
                         title = NULL, subtitle = NULL, glm_panels = TRUE,
                         seed = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  raw <- model_raw_data(model)
  preds <- raw$predictors
  if (length(preds) == 0) stop("The model has no predictors.", call. = FALSE)
  if (is.null(predictor)) {
    numeric_preds <- setdiff(preds[vapply(raw$data[preds], is.numeric,
                                          logical(1))], raw$categorical)
    predictor <- if (length(numeric_preds)) numeric_preds[1] else preds[1]
  } else {
    predictor <- resolve_predictor(predictor, raw, "predictor")
  }

  p_coef <- coefficient_plot(
    model, standardise = standardise,
    title = if (standardise) "Coefficients (per predictor SD)" else "Coefficients"
  )
  p_eff <- effects_plot(model, predictor,
                        title = paste("Effect of", predictor))
  # The same rule as residual_diagnostics_plot(), so the two figures agree.
  if (isTRUE(glm_panels) && inherits(model, "glm")) {
    p_rf <- binned_residual_plot(model)
    qq <- glm_qq_sample(model, seed = seed)
    p_qq <- qq_plot(qq$sample, y_lab = qq$label, title = "Normal Q-Q")
  } else {
    rf <- data.frame(fitted = stats::fitted(model),
                     resid = stats::residuals(model))
    p_rf <- diag_scatter(rf, "fitted", "resid", "Fitted values", "Residuals",
                         "Residuals vs. fitted", 0.6, TRUE, hline = 0)
    p_qq <- qq_plot(model, title = "Normal Q-Q")
  }

  if (is.null(subtitle)) {
    n <- tryCatch(stats::nobs(model), error = function(e) NA_integer_)
    r2 <- fit_r2(model)
    aic <- tryCatch(stats::AIC(model), error = function(e) NA_real_)
    nc <- as.character(n)
    r2f <- formatC(r2, digits = 3, format = "f")
    aicf <- formatC(aic, digits = 1, format = "f")
    # A plotmath subtitle so the statistical letters n and R are italic.
    subtitle <- if (inherits(model, "glm")) {
      bquote(italic(n) * " = " * .(nc) * "    |    deviance " * italic(R)^2 *
               " = " * .(r2f) * "    |    AIC = " * .(aicf))
    } else {
      bquote(italic(n) * " = " * .(nc) * "    |    " * italic(R)^2 *
               " = " * .(r2f) * "    |    AIC = " * .(aicf))
    }
  }

  # Free each panel's left axis title from cross-panel alignment so it sits next
  # to its own axis, rather than being pushed out to match a neighbour with
  # wider axis text (which leaves a gap between the title and the plot area).
  # `type` and `side` arrived in patchwork 1.3.0, which is why DESCRIPTION
  # floors patchwork there.
  freel <- function(p) patchwork::free(p, type = "label", side = "l")
  arrange_plots(
    freel(p_coef), freel(p_eff), freel(p_rf), freel(p_qq),
    ncol = 2,
    title = title %||% "Model report",
    subtitle = subtitle,
    tag_levels = "A"
  )
}
