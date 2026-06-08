# Internal helpers -----------------------------------------------------------

#' Null-coalescing operator
#'
#' Returns `x` unless it is `NULL`, in which case `y` is returned.
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Is a suggested package available?
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

#' Resolve a column argument that may be a string or an unquoted name
#'
#' Accepts either `"col"` or `col` and returns the column name as a string,
#' checking that it exists in `data`.
#' @noRd
resolve_var <- function(data, quo, arg) {
  if (rlang::quo_is_null(quo)) return(NULL)
  expr <- rlang::quo_get_expr(quo)
  name <- if (is.character(expr)) expr else rlang::as_name(quo)
  if (!name %in% names(data)) {
    stop("Column `", name, "` (argument `", arg, "`) not found in the data.",
         call. = FALSE)
  }
  name
}
