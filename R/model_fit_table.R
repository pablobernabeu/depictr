# Goodness-of-fit table ------------------------------------------------------

#' Goodness-of-fit statistics across models
#'
#' Collects the usual model-comparison statistics into one tidy data frame, one
#' row per model. These comprise the number of observations, the number of
#' estimated parameters (`df`, as [stats::logLik()] counts them for AIC and
#' BIC), AIC, BIC, the log-likelihood, an R-squared and the root-mean-square of
#' the residuals (response residuals for a `glm`, deviance residuals otherwise,
#' which for an unweighted linear or linear mixed model are the ordinary
#' residuals).
#'
#' @details
#' The R-squared depends on the kind of model. An `lm` reports the ordinary
#' coefficient of determination. Every `glm`, including quasi-likelihood
#' families and negative binomial fits from `MASS::glm.nb()`, reports the
#' deviance R-squared, \eqn{1 - D/D_0}. Here \eqn{D} is the residual deviance
#' of the model and \eqn{D_0} the deviance of the null model, which
#' [stats::glm()] fits to the same rows with the same prior weights and
#' offset. The null model has an intercept only if the model has one. Both
#' deviances are stored with the fit, so nothing is refitted. The value is the
#' share of the null deviance that the predictors explain, the
#' Kullback-Leibler R-squared of Cameron and Windmeijer (1997). It equals the
#' ordinary R-squared for a Gaussian model with the identity link and
#' McFadden's (1974) pseudo-R-squared for binary logistic regression. For
#' Poisson, grouped binomial, Gamma and other models, the two measures differ.
#' Mixed models (`merMod`) report an R-squared of `NA`, since no single
#' definition is standard for them.
#'
#' A linear mixed model fitted with [lme4::lmer()] by restricted maximum
#' likelihood (REML, its default) is refitted by maximum likelihood with
#' [lme4::refitML()]. Its AIC, BIC and log-likelihood come from the refit, and
#' a message says so. A REML likelihood is the likelihood of the residuals left
#' once the fixed effects are removed. Two models with different fixed effects
#' therefore have REML likelihoods of different data, and their criteria cannot
#' be compared. The `anova()` method for lme4 fits refits them by maximum
#' likelihood for the same reason. If a refit fails, a warning says so, and
#' that model's `df`, `AIC`, `BIC` and `logLik` are `NA`. The other columns
#' describe the model as supplied.
#'
#' @param ... One or more fitted models. Name the arguments to label the rows.
#' @param digits Number of decimal places to round to.
#'
#' @return A data frame with one row per model and columns `model`, `n`, `df`,
#'   `AIC`, `BIC`, `logLik`, `R2` and `RMSE`.
#' @references
#' \insertRef{cameron1997}{depictr}
#'
#' \insertRef{mcfadden1974}{depictr}
#' @export
#' @examples
#' m1 <- lm(yield ~ rainfall, data = crop_yield)
#' m2 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
#' m3 <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
#'          data = crop_yield)
#' model_fit_table(simple = m1, medium = m2, full = m3)
model_fit_table <- function(..., digits = 3) {
  models <- list(...)
  if (length(models) < 1) stop("Supply at least one model.", call. = FALSE)
  nms <- names(models)
  if (is.null(nms) || any(!nzchar(nms))) {
    auto <- paste0("model", seq_along(models))
    if (is.null(nms)) nms <- auto else nms[!nzchar(nms)] <- auto[!nzchar(nms)]
  }

  # Information criteria are read from each model as supplied, or from its
  # maximum-likelihood refit when it was fitted by REML (see Details). A refit
  # that failed leaves NULL, and its criteria then come out NA.
  criteria_fits <- models
  reml <- vapply(models, is_reml_fit, logical(1))
  criteria_fits[reml] <- Map(refit_ml, models[reml], nms[reml])
  if (any(reml & !vapply(criteria_fits, is.null, logical(1)))) {
    message("model_fit_table(): REML fits were refitted by maximum likelihood ",
            "for AIC, BIC and logLik, so models that differ in their fixed ",
            "effects can be compared.")
  }

  rows <- Map(function(m, cf, nm) {
    ll <- tryCatch(stats::logLik(cf), error = function(e) NA)
    r2 <- fit_r2(m)
    rmse <- tryCatch({
      r <- stats::residuals(m, type = if (inherits(m, "glm")) "response" else
        "deviance")
      sqrt(mean(r^2, na.rm = TRUE))
    }, error = function(e) NA_real_)
    data.frame(
      model  = nm,
      n      = tryCatch(stats::nobs(m), error = function(e) NA_integer_),
      df     = if (length(ll) && !is.na(ll[1])) attr(ll, "df") else NA_integer_,
      AIC    = tryCatch(stats::AIC(cf), error = function(e) NA_real_),
      BIC    = tryCatch(stats::BIC(cf), error = function(e) NA_real_),
      logLik = if (length(ll)) as.numeric(ll) else NA_real_,
      R2     = r2,
      RMSE   = rmse,
      stringsAsFactors = FALSE
    )
  }, models, criteria_fits, nms)

  out <- do.call(rbind, rows)
  num <- vapply(out, is.numeric, logical(1))
  out[num] <- lapply(out[num], round, digits = digits)
  rownames(out) <- NULL
  out
}

# ---- internal helpers ------------------------------------------------------

#' R-squared for the fit table and the model_report() subtitle
#'
#' The deviance R-squared of a `glm` is read from the two deviances the fit
#' already holds. glm() computes the null deviance on the rows, prior weights
#' and offset of the model itself. Refitting the null with update() would
#' re-evaluate the call and read the data afresh, bringing back rows the model
#' dropped for a missing predictor and failing on data local to a function.
#' Its `. ~ 1` formula would also discard an offset written in the formula and
#' add an intercept to a model fitted without one.
#' @param m A fitted model.
#' @return A number, or `NA` when no R-squared applies or the null deviance is
#'   zero (a response with no variation).
#' @noRd
fit_r2 <- function(m) {
  if (inherits(m, "glm")) {
    dev <- m$deviance
    dev0 <- m$null.deviance
    if (length(dev) != 1L || length(dev0) != 1L || !is.finite(dev) ||
        !is.finite(dev0) || dev0 <= 0) {
      return(NA_real_)
    }
    1 - dev / dev0
  } else if (inherits(m, "lm")) {
    s <- summary(m)
    if (!is.null(s$r.squared)) s$r.squared else NA_real_
  } else {
    NA_real_
  }
}

#' Whether a model is an lme4 fit by restricted maximum likelihood
#'
#' A generalised linear mixed model is never fitted by REML, so only linear
#' mixed models qualify. Without lme4 installed, the object's methods are
#' unavailable and its criteria come out NA.
#' @param m A fitted model.
#' @noRd
is_reml_fit <- function(m) {
  inherits(m, "merMod") && requireNamespace("lme4", quietly = TRUE) &&
    isTRUE(lme4::isREML(m))
}

#' Refit an lme4 REML fit by maximum likelihood for its information criteria
#'
#' @param m A linear mixed model fitted by REML.
#' @param nm The row label, named in the warning.
#' @return The refitted model, or `NULL` with a warning when the refit fails.
#'   The table then shows `NA` for that model's criteria, since its REML
#'   values would look comparable with the other rows.
#' @noRd
refit_ml <- function(m, nm) {
  tryCatch(lme4::refitML(m), error = function(e) {
    warning("model_fit_table(): could not refit `", nm, "` by maximum ",
            "likelihood (", conditionMessage(e), "), so its df, AIC, BIC and ",
            "logLik are NA.", call. = FALSE)
    NULL
  })
}
