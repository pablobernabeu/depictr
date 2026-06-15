# Descriptive summary table ("Table 1") --------------------------------------

#' A "Table 1" style descriptive summary
#'
#' Builds the kind of descriptive table that opens many empirical papers:
#' numeric variables are summarised as mean (SD), categorical variables as
#' counts and percentages, optionally split into one column per level of a
#' grouping variable. The result is a plain data frame, ready to pass to
#' [knitr::kable()] or a table package.
#'
#' The first row of the table always reports the sample size (`N`) overall and
#' per group. By default each variable is also followed by a `Missing, n (%)`
#' row whenever it contains missing values; set `missing = FALSE` to suppress
#' these.
#'
#' When `vars` is `NULL`, high-cardinality character/factor columns (those whose
#' number of distinct levels approaches the number of rows, e.g. identifier
#' columns) are skipped automatically, with a message, rather than being
#' expanded into hundreds of one-per-row entries. Pass such a column explicitly
#' via `vars` to override this.
#'
#' @param data A data frame.
#' @param vars Columns to summarise. If `NULL`, all columns except `group` are
#'   used, with high-cardinality identifier-like columns skipped (see Details).
#' @param group Optional grouping variable; one summary column is produced per
#'   level, alongside an overall column.
#' @param digits Number of decimal places for numeric summaries.
#' @param missing Whether to add a `Missing, n (%)` row for variables that
#'   contain missing values. Defaults to `TRUE`.
#' @param max_levels When `vars` is `NULL`, character/factor columns whose
#'   distinct-level count is at least `max_levels` *and* exceeds half the number
#'   of rows are treated as identifiers and skipped. Defaults to `20`.
#'
#' @return A data frame with columns `variable`, `statistic`, `Overall` and one
#'   column per group level. The first row reports `N`.
#' @export
#' @examples
#' summary_table(crop_yield, vars = c("yield", "rainfall", "treatment"))
#' summary_table(wellbeing_survey,
#'               vars = c("life_satisfaction", "education"),
#'               group = "region")
summary_table <- function(data, vars = NULL, group = NULL, digits = 1,
                          missing = TRUE, max_levels = 20) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (!is.null(group)) {
    if (!group %in% names(data)) {
      stop("Group column `", group, "` not found.", call. = FALSE)
    }
    data[[group]] <- as.factor(data[[group]])
  }
  if (is.null(vars)) {
    vars <- setdiff(names(data), group)
    # Drop identifier-like columns: character/factor with (nearly) as many
    # distinct levels as rows would explode into hundreds of junk rows.
    n <- nrow(data)
    is_id <- vapply(vars, function(v) {
      col <- data[[v]]
      if (!(is.character(col) || is.factor(col))) return(FALSE)
      n_lev <- length(unique(col[!is.na(col)]))
      n_lev >= max_levels && n_lev > n / 2
    }, logical(1))
    if (any(is_id)) {
      message("summary_table(): skipping high-cardinality column(s): ",
              paste(vars[is_id], collapse = ", "),
              ". Pass them via `vars` to include them.")
      vars <- vars[!is_id]
    }
  }
  check_columns(data, vars)

  groups <- if (is.null(group)) list(Overall = data) else
    c(list(Overall = data), split(data, data[[group]]))

  num_fmt <- function(v) {
    v <- v[!is.na(v)]
    if (!length(v)) return("--")
    if (length(v) == 1) {
      # SD is undefined for a single observation; report the mean alone.
      return(sprintf(paste0("%.", digits, "f (n=1)"), mean(v)))
    }
    sprintf(paste0("%.", digits, "f (%.", digits, "f)"),
            mean(v), stats::sd(v))
  }

  miss_fmt <- function(v) {
    n_miss <- sum(is.na(v))
    tot <- length(v)
    if (tot == 0) return("--")
    sprintf("%d (%.0f%%)", n_miss, 100 * n_miss / tot)
  }

  rows <- list()

  # Always report the sample size first.
  n_cells <- vapply(groups, function(g) as.character(nrow(g)), character(1))
  rows[[length(rows) + 1]] <- c(variable = "N", statistic = "", n_cells)

  for (v in vars) {
    col <- data[[v]]
    if (is.numeric(col)) {
      cells <- vapply(groups, function(g) num_fmt(g[[v]]), character(1))
      rows[[length(rows) + 1]] <- c(variable = v, statistic = "Mean (SD)", cells)
    } else {
      lv <- levels(as.factor(col))
      for (l in lv) {
        cells <- vapply(groups, function(g) {
          x <- as.factor(g[[v]])
          n <- sum(x == l, na.rm = TRUE)
          tot <- sum(!is.na(x))
          if (tot == 0) "--" else sprintf("%d (%.0f%%)", n, 100 * n / tot)
        }, character(1))
        rows[[length(rows) + 1]] <- c(variable = v, statistic = l, cells)
      }
    }
    # Optional missingness line, only when the variable has missing values.
    if (missing && anyNA(col)) {
      cells <- vapply(groups, function(g) miss_fmt(g[[v]]), character(1))
      rows[[length(rows) + 1]] <- c(variable = v, statistic = "Missing, n (%)",
                                    cells)
    }
  }

  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  # Blank the repeated variable name for readability
  dup <- duplicated(out$variable)
  out$variable[dup] <- ""
  out
}
