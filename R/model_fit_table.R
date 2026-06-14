# Goodness-of-fit table ------------------------------------------------------

#' Goodness-of-fit statistics across models
#'
#' Collects the usual model-comparison statistics into one tidy data frame, one
#' row per model. These comprise the number of observations, the degrees of
#' freedom, AIC, BIC, the log-likelihood, an R-squared (ordinary for `lm` and
#' McFadden's pseudo-R-squared for `glm`) and the root-mean-square error.
#'
#' @param ... Two or more fitted models. Name the arguments to label the rows.
#' @param digits Number of decimal places to round to.
#'
#' @return A data frame with one row per model and columns `model`, `n`, `df`,
#'   `AIC`, `BIC`, `logLik`, `R2` and `RMSE`.
#' @references
#' \insertRef{mcfadden1974}{depictr}
#' @export
#' @examples
#' m1 <- lm(yield ~ rainfall, data = crop_yield)
#' m2 <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
#' m3 <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment,
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

  rows <- Map(function(m, nm) {
    ll <- tryCatch(stats::logLik(m), error = function(e) NA)
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
      AIC    = tryCatch(stats::AIC(m), error = function(e) NA_real_),
      BIC    = tryCatch(stats::BIC(m), error = function(e) NA_real_),
      logLik = if (length(ll)) as.numeric(ll) else NA_real_,
      R2     = r2,
      RMSE   = rmse,
      stringsAsFactors = FALSE
    )
  }, models, nms)

  out <- do.call(rbind, rows)
  num <- vapply(out, is.numeric, logical(1))
  out[num] <- lapply(out[num], round, digits = digits)
  rownames(out) <- NULL
  out
}

# ---- internal helper -------------------------------------------------------

#' @noRd
fit_r2 <- function(m) {
  if (inherits(m, "glm")) {
    # McFadden's pseudo-R^2
    ll_full <- tryCatch(as.numeric(stats::logLik(m)), error = function(e) NA)
    null <- tryCatch(stats::update(m, . ~ 1), error = function(e) NULL)
    if (is.null(null) || is.na(ll_full)) return(NA_real_)
    1 - ll_full / as.numeric(stats::logLik(null))
  } else if (inherits(m, "lm")) {
    s <- summary(m)
    if (!is.null(s$r.squared)) s$r.squared else NA_real_
  } else {
    NA_real_
  }
}
