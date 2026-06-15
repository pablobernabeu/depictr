# Normalise Bayesian draws to a tidy long table -----------------------------
#
# Shared by posterior_plot() and frequentist_bayesian_plot(): a single place
# that knows how to coax the many shapes a posterior can arrive in (brms /
# rstanarm fits, a posterior 'draws' object, a wide draws matrix/data frame, or
# an already-long table) into one long data frame with the columns
# `term`, `.value` and `.draw`. Only fixed-effect parameters are retained from
# fitted models, with the 'brms' `b_` prefix stripped so terms line up with the
# frequentist side.

#' Is `x` a recognised source of posterior draws?
#'
#' TRUE for fitted Bayesian models (brms/rstanarm), posterior `draws` objects,
#' and matrices. Data frames are *not* claimed here, because a tidy data frame
#' of posterior *summaries* (estimate/conf.low/...) must keep flowing down the
#' summary path; [has_draws()] disambiguates those two data-frame cases.
#' @noRd
is_draws_source <- function(x) {
  inherits(x, c("brmsfit", "stanreg", "draws", "draws_df", "draws_matrix",
                "draws_array", "draws_list", "draws_rvars")) ||
    is.matrix(x)
}

#' Does this object actually carry per-draw samples (not just summaries)?
#'
#' A data frame counts as draws when it is long (a parameter column plus a value
#' column) or wide (several numeric columns and clearly more rows than a summary
#' table would have, or sampler index columns such as `.draw`). Anything that
#' [tidy_estimates()] would read as a summary table (estimate + conf.low/high)
#' is treated as summaries, not draws.
#' @noRd
has_draws <- function(x) {
  if (is_draws_source(x)) return(TRUE)
  if (!is.data.frame(x)) return(FALSE)

  nm <- names(x)
  has_index <- any(c(".chain", ".iteration", ".draw") %in% nm)
  par_col <- intersect(c("parameter", "term", ".variable", "variable"), nm)
  val_col <- intersect(c("value", ".value", "draw"), nm)
  summary_cols <- intersect(
    c("estimate", "Estimate", "conf.low", "conf.high", "std.error",
      "2.5 %", "97.5 %", "l-95% CI", "u-95% CI", "Q2.5", "Q97.5"),
    nm
  )

  # Long draws: a parameter column AND a per-draw value column, and crucially no
  # summary columns (otherwise it is a tidy summary table that happens to have a
  # `term` column).
  if (length(par_col) && length(val_col) && length(summary_cols) == 0) {
    return(TRUE)
  }
  # Sampler index columns are a strong signal of raw draws.
  if (has_index) return(TRUE)
  # Wide draws: many numeric columns, no summary columns, and more rows than a
  # forest plot's worth of terms (draws come in the hundreds/thousands).
  num <- nm[vapply(x, is.numeric, logical(1))]
  num <- setdiff(num, c(".chain", ".iteration", ".draw", "draw", "chain",
                        "iteration", ".row"))
  if (length(summary_cols) == 0 && length(num) >= 1 && nrow(x) >= 50) {
    return(TRUE)
  }
  FALSE
}

#' Extract a tidy long table of draws from any supported source
#'
#' @return A data frame with columns `term` (character), `.value` (numeric) and
#'   `.draw` (integer). NA values are dropped, matching [draws_to_long()].
#' @noRd
extract_draws <- function(x) {
  long <- if (inherits(x, "brmsfit")) {
    extract_draws_brms(x)
  } else if (inherits(x, "stanreg")) {
    extract_draws_rstanarm(x)
  } else if (inherits(x, c("draws", "draws_df", "draws_matrix", "draws_array",
                           "draws_list", "draws_rvars"))) {
    extract_draws_posterior(x)
  } else if (is.matrix(x)) {
    extract_draws_matrix(x)
  } else if (is.data.frame(x)) {
    extract_draws_df(x)
  } else {
    stop("Don't know how to extract posterior draws from an object of class <",
         paste(class(x), collapse = "/"), ">.", call. = FALSE)
  }
  finalise_draws(long)
}

#' @noRd
extract_draws_brms <- function(x) {
  ensure_installed("brms", "to extract draws from a 'brmsfit' object")
  # posterior::as_draws_df() is the modern path; fall back to brms's own method.
  draws <- if (requireNamespace("posterior", quietly = TRUE)) {
    posterior::as_draws_df(x)
  } else {
    brms::as_draws_df(x)
  }
  df <- as.data.frame(draws)
  # Keep only population-level (fixed) effects: the `b_` parameters. Drop the
  # intercept-less book-keeping and group-level (`r_`, `sd_`, `cor_`) terms.
  b_cols <- grep("^b_", names(df), value = TRUE)
  if (!length(b_cols)) {
    stop("No fixed-effect (b_*) parameters found in the brms fit.",
         call. = FALSE)
  }
  out <- df[, b_cols, drop = FALSE]
  names(out) <- sub("^b_", "", b_cols)
  wide_to_long_draws(out)
}

#' @noRd
extract_draws_rstanarm <- function(x) {
  ensure_installed("rstanarm", "to extract draws from a 'stanreg' object")
  m <- as.matrix(x)
  # rstanarm's as.matrix() carries auxiliary parameters (sigma, etc.); keep the
  # regression coefficients, which is everything bar the known auxiliaries.
  aux <- c("sigma", "(phi)", "reciprocal_dispersion", "mean_PPD",
           "log-posterior", "shape", "nu", "tau", "alpha", "lambda")
  keep <- setdiff(colnames(m), aux)
  m <- m[, keep, drop = FALSE]
  extract_draws_matrix(m)
}

#' @noRd
extract_draws_posterior <- function(x) {
  ensure_installed("posterior", "to handle a posterior 'draws' object")
  df <- as.data.frame(posterior::as_draws_df(x))
  wide_to_long_draws(df)
}

#' @noRd
extract_draws_matrix <- function(x) {
  if (is.null(colnames(x))) {
    colnames(x) <- paste0("V", seq_len(ncol(x)))
  }
  wide_to_long_draws(as.data.frame(x, check.names = FALSE))
}

#' @noRd
extract_draws_df <- function(x) {
  par_col <- intersect(c("parameter", "term", ".variable", "variable"),
                       names(x))
  val_col <- intersect(c("value", ".value", "draw", "estimate"), names(x))
  if (length(par_col) && length(val_col)) {
    n <- nrow(x)
    return(data.frame(
      term  = as.character(x[[par_col[1]]]),
      .value = as.numeric(x[[val_col[1]]]),
      .draw = stats::ave(seq_len(n), x[[par_col[1]]], FUN = seq_along),
      stringsAsFactors = FALSE
    ))
  }
  wide_to_long_draws(x)
}

#' Long-melt a wide draws data frame, dropping sampler index columns
#'
#' Mirrors the column-selection logic in [draws_to_long()] (the existing wide
#' path), but emits the `term` / `.value` / `.draw` schema used throughout the
#' distribution layer.
#' @noRd
wide_to_long_draws <- function(df) {
  index_cols <- c(".chain", ".iteration", ".draw", "draw", "chain",
                  "iteration", ".row")
  num <- names(df)[vapply(df, is.numeric, logical(1))]
  num <- setdiff(num, index_cols)
  if (length(num) < 1) {
    stop("Could not find draws: supply long (parameter + value) or wide ",
         "(numeric columns) data.", call. = FALSE)
  }
  n <- nrow(df)
  data.frame(
    term  = rep(num, each = n),
    .value = unlist(df[num], use.names = FALSE),
    .draw = rep(seq_len(n), times = length(num)),
    stringsAsFactors = FALSE
  )
}

#' Drop NA values and guarantee the canonical column order / types
#' @noRd
finalise_draws <- function(long) {
  long <- long[!is.na(long$.value), c("term", ".value", ".draw"), drop = FALSE]
  long$term <- as.character(long$term)
  long$.value <- as.numeric(long$.value)
  long$.draw <- as.integer(long$.draw)
  rownames(long) <- NULL
  long
}
