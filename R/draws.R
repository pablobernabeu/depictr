# Normalise Bayesian draws to a tidy long table -----------------------------
#
# Used by frequentist_bayesian_plot() for every Bayesian input that has_draws()
# accepts, and by posterior_plot() for every input but a plain data frame,
# which draws_to_long() in posterior_plot.R reads by the same column rules. It
# coaxes the many shapes a posterior can arrive in (brms / rstanarm fits, a
# posterior 'draws' object, a wide draws matrix/data frame, or an already-long
# table) into one long data frame with the columns
# `term`, `.value` and `.draw`. Only fixed-effect parameters are retained from
# fitted models and from draws objects that hold brms's `b_` parameters, with
# the `b_` prefix stripped so terms line up with the frequentist side. The log
# densities `lp__` and `lprior` are dropped from every source.

#' Column names that mark a table of posterior summaries, not of draws
#'
#' `brms::fixef()` returns Estimate, Est.Error, Q2.5 and Q97.5. The `l-95% CI`
#' pair comes from `summary(fit)$fixed`, and the rest from broom-style tables
#' and `confint()`.
#' @noRd
summary_columns <- c("estimate", "Estimate", "Est.Error", "std.error",
                     "conf.low", "conf.high", "2.5 %", "97.5 %",
                     "l-95% CI", "u-95% CI", "Q2.5", "Q97.5")

#' Variables a sampler or brms records that are never model parameters
#'
#' `lp__` is Stan's log posterior density and `lprior` the log prior density
#' that brms adds.
#' @noRd
log_density_variables <- c("lp__", "lprior")

#' Test whether `x` is a matrix of posterior summaries, as from `brms::fixef()`
#'
#' Melted column by column, such a matrix would be drawn as one 'parameter' per
#' summary statistic, so it is told apart from a draws matrix by its column
#' names.
#' @noRd
is_summary_matrix <- function(x) {
  is.matrix(x) && !inherits(x, "draws") &&
    any(colnames(x) %in% summary_columns)
}

#' Is `x` a recognised source of posterior draws?
#'
#' TRUE for fitted Bayesian models (brms/rstanarm), posterior `draws` objects,
#' and matrices other than summary matrices. Plain data frames are *not*
#' claimed here (a `draws_df` is, by its class), because a tidy data frame of
#' posterior *summaries* (estimate/conf.low/...) must keep flowing down the
#' summary path; `has_draws()` disambiguates those two data-frame cases.
#' @noRd
is_draws_source <- function(x) {
  inherits(x, c("brmsfit", "stanreg", "draws", "draws_df", "draws_matrix",
                "draws_array", "draws_list", "draws_rvars")) ||
    (is.matrix(x) && !is_summary_matrix(x))
}

#' Does this object actually carry per-draw samples (not just summaries)?
#'
#' A data frame counts as draws when it is long (a parameter column plus a
#' value column, and no summary column), when it has a sampler index column
#' (`.chain`, `.iteration` or `.draw`), whatever else it holds, or when it is
#' wide: at least 50 rows, more than a summary table would have, no summary
#' column and at least one numeric column other than the index and
#' book-keeping columns (`.chain`, `.iteration`, `.draw`, `chain`,
#' `iteration`, `draw` and `.row`). A summary table that [tidy_estimates()]
#' reads (estimate + conf.low/high) is therefore treated as summaries unless it
#' carries a sampler index column.
#' @noRd
has_draws <- function(x) {
  if (is_draws_source(x)) return(TRUE)
  if (!is.data.frame(x)) return(FALSE)

  nm <- names(x)
  has_index <- any(c(".chain", ".iteration", ".draw") %in% nm)
  par_col <- intersect(c("parameter", "term", ".variable", "variable"), nm)
  val_col <- intersect(c("value", ".value", "draw"), nm)
  summary_cols <- intersect(summary_columns, nm)

  # Long draws: a parameter column AND a per-draw value column, and crucially no
  # summary columns (otherwise it is a tidy summary table that happens to have a
  # `term` column).
  if (length(par_col) && length(val_col) && length(summary_cols) == 0) {
    return(TRUE)
  }
  # Sampler index columns are a strong signal of raw draws.
  if (has_index) return(TRUE)
  # Wide draws: at least one numeric column, no summary columns, and at least
  # 50 rows, more than a forest plot's worth of terms (draws come in the
  # hundreds or thousands).
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
#'   `.draw` (integer). NA values are dropped, as `draws_to_long()` drops them,
#'   and so are `lp__` and `lprior`: silently from a brms fit, which keeps only
#'   its `b_` parameters, and otherwise with a message.
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
    if (is_summary_matrix(x)) {
      stop("This matrix holds posterior summaries (columns ",
           and_list(intersect(colnames(x), summary_columns)),
           "), not draws. Pass the draws themselves, such as ",
           "posterior::as_draws_df(fit).", call. = FALSE)
    }
    extract_draws_matrix(x)
  } else if (is.data.frame(x)) {
    extract_draws_df(x)
  } else {
    stop("Don't know how to extract posterior draws from an object of class <",
         paste(class(x), collapse = "/"), ">.", call. = FALSE)
  }
  finalise_draws(drop_log_densities(long))
}

#' @noRd
extract_draws_brms <- function(x) {
  # A 'brmsfit' is created by brms, whose posterior::as_draws_df() method is
  # therefore already loaded in the user's session; routing through posterior
  # means depictr needs no hard brms dependency of its own.
  ensure_installed("posterior", "to extract draws from a 'brmsfit' object")
  draws <- posterior::as_draws_df(x)
  df <- as.data.frame(draws)
  # Keep only population-level (fixed) effects: the `b_` parameters. Drop the
  # rest, such as the centred `Intercept`, `sigma`, the group-level (`r_`,
  # `sd_`, `cor_`) terms and the log densities, without a message.
  # extract_draws_posterior() names what it drops from a draws object.
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
  m <- m[, rstanarm_fixed_columns(colnames(m)), drop = FALSE]
  extract_draws_matrix(m)
}

#' The regression-coefficient columns of an rstanarm draws matrix
#'
#' rstanarm's as.matrix() carries the auxiliary parameters (sigma, etc.) and,
#' for a mixed model, every group-level coefficient `b[...]` and covariance
#' element `Sigma[...]`. The regression coefficients are everything else.
#' @noRd
rstanarm_fixed_columns <- function(nm) {
  aux <- c("sigma", "(phi)", "reciprocal_dispersion", "mean_PPD",
           "log-posterior", "shape", "nu", "tau", "alpha", "lambda")
  nm[!nm %in% aux & !grepl("^(b|Sigma)\\[", nm)]
}

#' Draws from a posterior `draws` object
#'
#' brms names its population-level parameters `b_...`. A draws object made from
#' a brms fit also holds the intercept of the centred predictors (`Intercept`,
#' beside `b_Intercept`), the residual SD, every group-level effect and the log
#' densities. When any `b_` variable is present only those are kept, named
#' without the prefix as for a brms fit itself, and one message summarises the
#' rest. Without `b_` variables only the log densities go, in `extract_draws()`.
#' @noRd
extract_draws_posterior <- function(x) {
  ensure_installed("posterior", "to handle a posterior 'draws' object")
  df <- as.data.frame(posterior::as_draws_df(x))
  vars <- setdiff(names(df), c(".chain", ".iteration", ".draw"))
  b_vars <- grep("^b_", vars, value = TRUE)
  if (!length(b_vars)) return(wide_to_long_draws(df))
  dropped <- setdiff(vars, b_vars)
  if (length(dropped)) {
    message(sprintf(
      "Kept the %d population-level (b_) %s and dropped %d %s: %s.",
      length(b_vars), if (length(b_vars) == 1) "parameter" else "parameters",
      length(dropped), if (length(dropped) == 1) "other" else "others",
      summarise_variables(dropped)
    ))
  }
  out <- df[b_vars]
  names(out) <- sub("^b_", "", b_vars)
  wide_to_long_draws(out)
}

#' Name a set of draws variables compactly, grouped by prefix
#'
#' Indexed variables are grouped by the name before the bracket (`r_item[...]`
#' becomes `r_item`) and brms's group-level variables by their leading prefix
#' (`sd_item__Intercept` becomes `sd_`). A group carries its size in brackets,
#' in order of first appearance, so a model with hundreds of random effects
#' still yields a one-line message.
#' @noRd
summarise_variables <- function(vars) {
  indexed <- grepl("[", vars, fixed = TRUE)
  prefixed <- !indexed & grepl("^[[:alnum:]]+_.*__", vars)
  key <- vars
  key[indexed] <- sub("\\[.*$", "", vars[indexed])
  key[prefixed] <- sub("^([[:alnum:]]+_).*$", "\\1", vars[prefixed])
  keys <- unique(key)
  n <- tabulate(match(key, keys), nbins = length(keys))
  grouped <- keys %in% key[indexed | prefixed] | n > 1
  paste(ifelse(grouped, sprintf("%s (%d)", keys, n), keys), collapse = ", ")
}

#' Drop the log densities from a long draws table, with a message
#' @param long A long draws table.
#' @param col The column holding the parameter names.
#' @noRd
drop_log_densities <- function(long, col = "term") {
  hit <- long[[col]] %in% log_density_variables
  if (!any(hit)) return(long)
  found <- unique(long[[col]][hit])
  message(if (length(found) == 1) {
    sprintf("Dropped %s, which is a log density, not a model parameter.",
            found)
  } else {
    sprintf("Dropped %s, which are log densities, not model parameters.",
            and_list(found))
  })
  long[!hit, , drop = FALSE]
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
#' Uses the same column selection as the wide path of `draws_to_long()`, but
#' emits the `term` / `.value` / `.draw` schema used throughout the
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

#' Refuse two parameters that would be drawn under one label
#'
#' Two terms with one display label would share a row, so posterior_plot()
#' would fail on a duplicated factor level and frequentist_bayesian_plot() would
#' pool their draws into one slab. brms's `b_Intercept` and `Intercept` are the
#' usual pair, since both format to "Intercept".
#' @param terms,labels Parallel vectors of raw terms and their display labels.
#' @noRd
check_label_clash <- function(terms, labels) {
  keep <- !duplicated(terms)
  terms <- terms[keep]
  labels <- labels[keep]
  shared <- unique(labels[duplicated(labels)])
  if (!length(shared)) return(invisible(NULL))
  clauses <- vapply(shared, function(l) {
    sprintf("%s share the label '%s'", and_list(terms[labels == l]), l)
  }, character(1))
  pair <- length(shared) == 1 && sum(labels == shared) == 2
  stop("Parameters ", paste(clauses, collapse = ", and "), "; ",
       if (pair) "rename one" else "give each its own label",
       " with `labels`.", call. = FALSE)
}

#' Join names as "a, b and c"
#' @noRd
and_list <- function(x) {
  x <- as.character(x)
  n <- length(x)
  if (n < 2) return(paste(x, collapse = ""))
  paste(paste(x[-n], collapse = ", "), "and", x[n])
}
