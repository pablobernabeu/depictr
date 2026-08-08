# Internal helpers -----------------------------------------------------------

#' Null-coalescing operator
#'
#' Returns `x` unless it is `NULL`, in which case `y` is returned.
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Check whether a suggested package is available
#'
#' Thin wrapper around [requireNamespace()] used to keep heavy dependencies in
#' `Suggests`. Errors with an informative message when the package is needed
#' but not installed.
#' @param pkg Package name.
#' @param what Short description of what the package is needed for.
#' @noRd
ensure_installed <- function(pkg, what = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- sprintf("Package '%s' is required", pkg)
    if (!is.null(what)) msg <- paste0(msg, " ", what)
    msg <- paste0(msg, ". Install it with install.packages('", pkg, "').")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate that `data` is a data frame containing `cols`
#' @noRd
check_columns <- function(data, cols, arg = "data") {
  if (!is.data.frame(data)) {
    stop("`", arg, "` must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    stop("`", arg, "` is missing column(s): ",
         paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' Test which of `cols` are (near-)constant
#'
#' A column with no variance has no correlation and cannot be scaled to unit
#' variance: [stats::cor()] warns and returns `NA`, and [scale()] divides by
#' zero and returns `NaN`, which [stats::kmeans()] then rejects outright. The
#' tolerance is the usual `sqrt(.Machine$double.eps)`, so a column that is
#' constant only up to floating-point noise counts as constant too.
#' @param data A data frame.
#' @param cols Column names to test.
#' @return A named logical vector, one element per column of `cols`.
#' @noRd
constant_columns <- function(data, cols) {
  vapply(cols, function(cn) {
    v <- data[[cn]][!is.na(data[[cn]])]
    length(v) < 2 || stats::sd(v) < .Machine$double.eps^0.5
  }, logical(1))
}

#' Drop (near-)constant columns of a numeric matrix before scaling it
#'
#' Matrix counterpart of [constant_columns()], for the clustering path where the
#' data has already been coerced to a matrix of complete cases. [scale()] turns
#' a constant column into `NaN`, which [stats::kmeans()] rejects with the raw
#' "NA/NaN/Inf in foreign function call" error; dropping the column with a
#' message keeps the diagnostic in the package's own voice, as
#' [correlation_heatmap()] already does for the same input.
#' @param mat A numeric matrix.
#' @param what Name of the calling function, used in the message.
#' @return `mat` without its constant columns.
#' @noRd
drop_constant_matrix_columns <- function(mat, what) {
  is_const <- vapply(seq_len(ncol(mat)), function(j) {
    v <- mat[, j]
    v <- v[!is.na(v)]
    length(v) < 2 || stats::sd(v) < .Machine$double.eps^0.5
  }, logical(1))
  if (any(is_const)) {
    nm <- colnames(mat)
    nm <- if (is.null(nm)) which(is_const) else nm[is_const]
    message(what, "(): dropping zero-variance column(s): ",
            paste(nm, collapse = ", "), ".")
    mat <- mat[, !is_const, drop = FALSE]
  }
  mat
}

#' Resolve a column argument that may be a string or an unquoted name
#'
#' Accepts either `"col"` or `col` and returns the column name as a string,
#' checking that it exists in `data`.
#' @noRd
resolve_var <- function(data, quo, arg) {
  if (rlang::quo_is_null(quo)) return(NULL)
  expr <- rlang::quo_get_expr(quo)
  if (is.character(expr)) {
    name <- expr
  } else {
    name <- rlang::as_name(quo)
    # If the symbol is not a column, it may be a variable holding a column name
    if (!name %in% names(data)) {
      val <- tryCatch(rlang::eval_tidy(quo), error = function(e) NULL)
      if (is.character(val) && length(val) == 1 && val %in% names(data)) {
        name <- val
      }
    }
  }
  if (!name %in% names(data)) {
    stop("Column `", name, "` (argument `", arg, "`) not found in the data.",
         call. = FALSE)
  }
  name
}
