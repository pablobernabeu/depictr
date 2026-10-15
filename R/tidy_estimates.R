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
#' Confidence intervals are Wald intervals, estimate +/- multiplier * standard
#' error, with the multiplier the model's own tests use. An `lm` object gets
#' the t interval of [stats::confint()]. A `glm` whose dispersion is estimated
#' (Gaussian, Gamma, inverse Gaussian and quasi families) gets t on the
#' residual degrees of freedom, since [stats::summary.glm()] then tests with
#' t. One whose dispersion is fixed (binomial, Poisson and `MASS::glm.nb()`)
#' gets z. The choice is read from the column the summary reports, "t value"
#' or "z value". At 12 residual degrees of freedom, the t interval is about
#' 11% wider than the z interval, and at 100 about 1% wider. A `merMod` fit
#' gets z, since 'lme4' gives no degrees of freedom. Supply
#' a data frame with your own intervals (for example profiled or posterior
#' intervals) to override this.
#'
#' @param x A fitted model or a data frame of results.
#' @param conf_level Confidence (or credible) level for the interval.
#' @param exponentiate Whether to exponentiate the estimates and interval
#'   limits, which turns log-odds into odds ratios and log rates into rate
#'   ratios. The `std.error` column stays on the link scale, as in
#'   [broom::tidy()]. A data frame is read as estimates on the link scale.
#'   Defaults to `FALSE`.
#' @param ... Passed to methods (and to [broom::tidy()] in the fallback). The
#'   `merMod` method additionally accepts `effects`, which currently only
#'   supports `"fixed"`.
#'
#' @return A data frame with one row per term and the columns `term`,
#'   `estimate`, `std.error`, `conf.low` and `conf.high`.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
#' tidy_estimates(fit)
#'
#' # Odds ratios from a logistic regression:
#' gfit <- glm(accuracy ~ word_frequency + condition,
#'             data = lexical_decision, family = binomial)
#' tidy_estimates(gfit, exponentiate = TRUE)
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
tidy_estimates <- function(x, conf_level = 0.95, exponentiate = FALSE, ...) {
  UseMethod("tidy_estimates")
}

#' @export
tidy_estimates.data.frame <- function(x, conf_level = 0.95,
                                      exponentiate = FALSE, ...) {
  check_exponentiate(exponentiate)
  pick <- function(cands) {
    hit <- intersect(cands, names(x))
    if (length(hit)) hit[1] else NA_character_
  }
  term_col  <- pick(c("term", "parameter", "Parameter", "predictor",
                      "variable", "fixed_effect", "rowname"))
  est_col   <- pick(c("estimate", "Estimate", "frequentist_estimate",
                      "coef", "mean", "value"))
  se_col    <- pick(c("std.error", "Std. Error", "std_error", "SE", "se"))
  low_col   <- pick(interval_low_columns)
  high_col  <- pick(interval_high_columns)

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
  exponentiate_estimates(out, exponentiate)
}

#' @export
tidy_estimates.lm <- function(x, conf_level = 0.95, exponentiate = FALSE, ...) {
  check_exponentiate(exponentiate)
  co <- stats::coef(summary(x))
  ci <- suppressWarnings(stats::confint(x, level = conf_level))
  # In a rank-deficient fit coef(summary()) omits aliased terms while confint()
  # keeps them as NA rows, so the interval matrix must be cut down to the
  # estimated terms before the columns are bound together.
  aliased <- setdiff(rownames(ci), rownames(co))
  if (length(aliased)) {
    message(length(aliased), " aliased term(s) in a rank-deficient fit were ",
            "dropped: ", paste(aliased, collapse = ", "), ".")
    ci <- ci[rownames(co), , drop = FALSE]
  }
  exponentiate_estimates(build_estimates(rownames(co), co[, 1], co[, 2], ci),
                         exponentiate)
}

#' @export
tidy_estimates.glm <- function(x, conf_level = 0.95, exponentiate = FALSE, ...) {
  check_exponentiate(exponentiate)
  co <- stats::coef(summary(x))
  est <- co[, 1]
  se  <- co[, 2]
  mult <- glm_multiplier(x, conf_level, co)
  ci  <- cbind(est - mult * se, est + mult * se)
  exponentiate_estimates(build_estimates(names(est), est, se, ci), exponentiate)
}

#' @export
tidy_estimates.merMod <- function(x, conf_level = 0.95, exponentiate = FALSE,
                                  effects = "fixed", ...) {
  check_exponentiate(exponentiate)
  effects <- match.arg(effects, "fixed")
  ensure_installed("lme4", "to tidy mixed-model ('merMod') objects")
  est <- lme4::fixef(x)
  se  <- sqrt(diag(as.matrix(stats::vcov(x))))
  se  <- se[names(est)]
  ci  <- wald_ci(est, se, conf_level)
  exponentiate_estimates(build_estimates(names(est), est, se, ci), exponentiate)
}

#' @export
tidy_estimates.default <- function(x, conf_level = 0.95, exponentiate = FALSE,
                                   ...) {
  check_exponentiate(exponentiate)
  if (requireNamespace("broom", quietly = TRUE)) {
    # broom tidies on the link scale here, and the data-frame method
    # exponentiates, so every class follows the same rule.
    td <- broom::tidy(x, conf.int = TRUE, conf.level = conf_level, ...)
    return(tidy_estimates.data.frame(as.data.frame(td), conf_level = conf_level,
                                     exponentiate = exponentiate))
  }
  stop("Don't know how to tidy an object of class <",
       paste(class(x), collapse = "/"),
       ">. Install the 'broom' package, or pass a data frame of estimates.",
       call. = FALSE)
}

# ---- internal helpers ------------------------------------------------------

# The columns the data-frame method reads as the lower and upper interval
# limits, in order of preference.
interval_low_columns <- c("conf.low", "CI_2.5", "2.5 %", "lower", "ci_low",
                          "Q2.5", "lwr", "l-95% CI")
interval_high_columns <- c("conf.high", "CI_97.5", "97.5 %", "upper",
                           "ci_high", "Q97.5", "upr", "u-95% CI")

#' Does a table of estimates hold interval limits of its own?
#'
#' Such limits are drawn as they stand, at whatever level they were computed.
#' Without them, the data-frame method fills the limits in from the standard
#' errors at `conf_level`, as the model methods compute theirs.
#' @noRd
holds_intervals <- function(x) {
  is.data.frame(x) && any(interval_low_columns %in% names(x)) &&
    any(interval_high_columns %in% names(x))
}

#' @noRd
wald_ci <- function(est, se, conf_level) {
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  cbind(est - z * se, est + z * se)
}

#' The interval multiplier a glm's own tests imply
#'
#' summary.glm() tests with t on the residual degrees of freedom when the
#' dispersion is estimated and with z when it is fixed. The choice is read
#' from the summary's third column, "t value" or "z value", and not from a
#' list of families. MASS::glm.nb() has a negative binomial family whose
#' summary fixes the dispersion at 1 and so reports z, which a family list
#' would miss. Shared by tidy_estimates.glm() and model_predict_grid(), so a
#' coefficient's interval and a prediction band follow one rule.
#' @param co The coefficient table of `summary(x)`, when the caller has it.
#' @noRd
glm_multiplier <- function(x, conf_level, co = stats::coef(summary(x))) {
  p <- 1 - (1 - conf_level) / 2
  df <- stats::df.residual(x)
  if (identical(colnames(co)[3], "t value") && length(df) == 1 &&
      is.finite(df) && df > 0) {
    stats::qt(p, df)
  } else {
    stats::qnorm(p)
  }
}

#' Refuse an `exponentiate` that is not a single TRUE or FALSE
#' @noRd
check_exponentiate <- function(exponentiate) {
  if (!is.logical(exponentiate) || length(exponentiate) != 1 ||
      is.na(exponentiate)) {
    stop("`exponentiate` must be TRUE or FALSE.", call. = FALSE)
  }
  invisible(exponentiate)
}

#' Exponentiate the estimates and interval limits of a tidy table
#'
#' The standard error stays on the link scale, as broom::tidy() leaves it,
#' since the exponentiated interval is not estimate +/- multiplier * SE.
#' @noRd
exponentiate_estimates <- function(est, exponentiate = TRUE) {
  if (!exponentiate) return(est)
  for (col in intersect(c("estimate", "conf.low", "conf.high"), names(est))) {
    est[[col]] <- exp(est[[col]])
  }
  est
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
