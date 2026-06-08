# Standardise model output into one tidy table ------------------------------

#' Extract a tidy table of estimates
#'
#' `tidy_estimates()` turns the output of a model (or an existing data frame of
#' results) into a single standardised table with the columns `term`,
#' `estimate`, `std.error`, `conf.low` and `conf.high`. It is the common
#' currency used by [coefficient_plot()] and [compare_models()], but is useful
#' on its own.
#'
#' Methods are provided for `lm`, `glm` and `merMod` (mixed models fitted with
#' 'lme4') objects, and for data frames. For any other model class the function
#' falls back to [broom::tidy()] when the 'broom' package is installed.
#'
#' Confidence intervals are computed with the normal approximation
#' (estimate +/- z * standard error) for `glm` and `merMod` objects, which is
#' fast and dependency-free; `lm` objects use the exact t-based interval. Supply
#' a data frame with your own intervals (for example profiled or posterior
#' intervals) to override this.
#'
#' @param x A fitted model or a data frame of results.
#' @param conf_level Confidence (or credible) level for the interval.
#' @param ... Passed to methods (and to [broom::tidy()] in the fallback). The
#'   `merMod` method additionally accepts `effects`, which currently only
#'   supports `"fixed"`.
#'
#' @return A data frame with one row per term and the columns `term`,
#'   `estimate`, `std.error`, `conf.low` and `conf.high`.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
#' tidy_estimates(fit)
#'
#' # A data frame of pre-computed estimates is standardised, not re-fitted:
#' df <- data.frame(
#'   parameter = c("a", "b"),
#'   Estimate = c(0.2, -0.4),
#'   "2.5 %" = c(0.1, -0.6),
#'   "97.5 %" = c(0.3, -0.2),
#'   check.names = FALSE
#' )
#' tidy_estimates(df)
tidy_estimates <- function(x, conf_level = 0.95, ...) {
  UseMethod("tidy_estimates")
}

#' @export
tidy_estimates.data.frame <- function(x, conf_level = 0.95, ...) {
  pick <- function(cands) {
    hit <- intersect(cands, names(x))
    if (length(hit)) hit[1] else NA_character_
  }
  term_col  <- pick(c("term", "parameter", "Parameter", "predictor",
                      "variable", "fixed_effect", "rowname"))
  est_col   <- pick(c("estimate", "Estimate", "frequentist_estimate",
                      "coef", "mean", "value"))
  se_col    <- pick(c("std.error", "Std. Error", "std_error", "SE", "se"))
  low_col   <- pick(c("conf.low", "CI_2.5", "2.5 %", "lower", "ci_low",
                      "Q2.5", "lwr", "l-95% CI"))
  high_col  <- pick(c("conf.high", "CI_97.5", "97.5 %", "upper", "ci_high",
                      "Q97.5", "upr", "u-95% CI"))

  if (is.na(est_col)) {
    stop("Could not find an estimate column in the data frame. Expected one ",
         "of 'estimate', 'Estimate', 'coef', 'mean' or 'value'.", call. = FALSE)
  }
  term <- if (!is.na(term_col)) as.character(x[[term_col]]) else rownames(x)
  if (is.null(term)) term <- as.character(seq_len(nrow(x)))

  out <- data.frame(
    term      = term,
    estimate  = as.numeric(x[[est_col]]),
    std.error = if (!is.na(se_col)) as.numeric(x[[se_col]]) else NA_real_,
    conf.low  = if (!is.na(low_col)) as.numeric(x[[low_col]]) else NA_real_,
    conf.high = if (!is.na(high_col)) as.numeric(x[[high_col]]) else NA_real_,
    stringsAsFactors = FALSE
  )
  out <- fill_ci(out, conf_level)
  out
}

#' @export
tidy_estimates.lm <- function(x, conf_level = 0.95, ...) {
  co <- stats::coef(summary(x))
  ci <- suppressWarnings(stats::confint(x, level = conf_level))
  build_estimates(rownames(co), co[, 1], co[, 2], ci)
}

#' @export
tidy_estimates.glm <- function(x, conf_level = 0.95, ...) {
  co <- stats::coef(summary(x))
  est <- co[, 1]
  se  <- co[, 2]
  ci  <- wald_ci(est, se, conf_level)
  build_estimates(names(est), est, se, ci)
}

#' @export
tidy_estimates.merMod <- function(x, conf_level = 0.95, effects = "fixed", ...) {
  effects <- match.arg(effects, "fixed")
  ensure_installed("lme4", "to tidy mixed-model ('merMod') objects")
  est <- lme4::fixef(x)
  se  <- sqrt(diag(as.matrix(stats::vcov(x))))
  se  <- se[names(est)]
  ci  <- wald_ci(est, se, conf_level)
  build_estimates(names(est), est, se, ci)
}

#' @export
tidy_estimates.default <- function(x, conf_level = 0.95, ...) {
  if (requireNamespace("broom", quietly = TRUE)) {
    td <- broom::tidy(x, conf.int = TRUE, conf.level = conf_level, ...)
    return(tidy_estimates.data.frame(as.data.frame(td), conf_level = conf_level))
  }
  stop("Don't know how to tidy an object of class <",
       paste(class(x), collapse = "/"),
       ">. Install the 'broom' package, or pass a data frame of estimates.",
       call. = FALSE)
}

# ---- internal helpers ------------------------------------------------------

#' @noRd
wald_ci <- function(est, se, conf_level) {
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  cbind(est - z * se, est + z * se)
}

#' @noRd
build_estimates <- function(term, est, se, ci) {
  out <- data.frame(
    term      = as.character(term),
    estimate  = as.numeric(est),
    std.error = as.numeric(se),
    conf.low  = as.numeric(ci[, 1]),
    conf.high = as.numeric(ci[, 2]),
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out
}

#' Fill in missing confidence limits from the standard error
#' @noRd
fill_ci <- function(out, conf_level) {
  need <- is.na(out$conf.low) | is.na(out$conf.high)
  have_se <- !is.na(out$std.error)
  do_fill <- need & have_se
  if (any(do_fill)) {
    ci <- wald_ci(out$estimate[do_fill], out$std.error[do_fill], conf_level)
    out$conf.low[do_fill]  <- ci[, 1]
    out$conf.high[do_fill] <- ci[, 2]
  }
  out
}
