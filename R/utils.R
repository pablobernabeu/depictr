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

#' Arguments that draw a geom_label() without a border
#'
#' ggplot2 4.0.0 replaced geom_label()'s `label.size` with `linewidth`. Before
#' 4.0.0, `linewidth` is an unknown parameter that warns and leaves the default
#' 0.25 mm border drawn. From 4.0.0, `label.size` is soft-deprecated. Splice the
#' result into the call with `rlang::exec(ggplot2::geom_label, ...,
#' !!!label_border_none())`.
#' @param version The ggplot2 version to answer for, the installed one by
#'   default.
#' @return A one-element named list.
#' @noRd
label_border_none <- function(version = utils::packageVersion("ggplot2")) {
  if (package_version(version) < "4.0.0") {
    list(label.size = 0)
  } else {
    list(linewidth = 0)
  }
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

#' Refuse a confidence level outside (0, 1)
#'
#' A level given as a percentage, such as 95, has no normal or t quantile, so
#' the intervals would come out NaN, and a level of 0 or 1 would draw a
#' zero-width or an unbounded interval. Every exported function that takes a
#' `conf_level` calls this, so that each refuses the same values with the same
#' message.
#' @param conf_level The level to check.
#' @param allow_na Whether a single `NA` is accepted, for the functions in
#'   which it leaves the limits out.
#' @noRd
check_conf_level <- function(conf_level, allow_na = FALSE) {
  if (is.numeric(conf_level) && length(conf_level) == 1L &&
      is.finite(conf_level) && conf_level > 0 && conf_level < 1) {
    return(invisible(conf_level))
  }
  # NA, logical or numeric, but not NaN, which is no request to omit anything.
  if (allow_na && (is.logical(conf_level) || is.numeric(conf_level)) &&
      length(conf_level) == 1L && is.na(conf_level) && !is.nan(conf_level)) {
    return(invisible(conf_level))
  }
  stop("`conf_level` must be a single number strictly between 0 and 1",
       if (allow_na) ", or NA to leave the limits out", ".", call. = FALSE)
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
#' Matrix counterpart of `constant_columns()`, for the clustering path where the
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

#' Prepare the grouping variable of a grouped plot
#'
#' Every grouped plot treats its group the same way, so that the same data give
#' the same groups and colours in every function and in the Python twin. The
#' group becomes a factor, so a numeric code is a group like any other. A
#' numeric column with more than 20 distinct values is refused, though, since
#' one group per value of a continuous variable is never what was meant. The
#' threshold and the wording are those explore_categorical() applies to its
#' `x`. Rows whose group is missing belong to no group, and they are dropped
#' with survival_plot()'s message. Levels left without rows are dropped, so
#' they take no place in the legend, on an axis or in the palette. Last, the
#' palette is named by level, unless the user named it already, so that a level
#' takes the same colour in every layer and panel, even one that lacks some
#' levels.
#'
#' Call it after the rows missing a plotted value have been set aside, so that
#' the levels are those of the rows drawn.
#' @param data A data frame.
#' @param group Name of the grouping column, or `NULL`.
#' @param palette The user's palette, or `NULL` for [depictr_palette()].
#' @return A list with elements `data`, `levels` and `palette`. `data` holds
#'   the rows with a group, whose group column is now a factor of the levels in
#'   use, and `palette` gives a colour for each level, named by level. Without
#'   a group, `data` and `palette` come back as given and `levels` is `NULL`.
#' @noRd
prepare_group <- function(data, group, palette = NULL) {
  if (is.null(group)) {
    return(list(data = data, levels = NULL, palette = palette))
  }
  g <- data[[group]]
  if (is.numeric(g)) {
    n_distinct <- length(unique(g[!is.na(g)]))
    if (n_distinct > 20) {
      stop("`group` (", group, ") is numeric with ", n_distinct,
           " distinct values; it looks continuous, not categorical. Bin it, ",
           "or convert it to a factor first.", call. = FALSE)
    }
  }
  no_group <- is.na(g)
  if (length(g) && all(no_group)) {
    stop("`group` is missing for every observation.", call. = FALSE)
  }
  if (any(no_group)) {
    message(sum(no_group), " observation(s) with a missing group were dropped.")
    data <- data[!no_group, , drop = FALSE]
  }
  data[[group]] <- droplevels(as.factor(data[[group]]))
  lv <- levels(data[[group]])
  list(data = data, levels = lv, palette = group_palette(lv, palette))
}

#' Name a palette by the levels it colours
#'
#' A named palette is the user's way to pin a colour to a level across figures,
#' so it is kept as given. An unnamed one is taken in level order, as ggplot2's
#' manual scale takes it, over the levels in use. One with fewer colours than
#' there are levels is left for the manual scale to report.
#' @param levels The levels of the group.
#' @param palette The user's palette, or `NULL` for [depictr_palette()].
#' @noRd
group_palette <- function(levels, palette = NULL) {
  if (!length(levels)) return(palette)
  if (is.null(palette)) {
    return(stats::setNames(depictr_palette(length(levels)), levels))
  }
  if (!is.null(names(palette)) || length(palette) < length(levels)) {
    return(palette)
  }
  stats::setNames(palette[seq_along(levels)], levels)
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
