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
#' A date or date-time column (`Date`, `POSIXct`) gets a single `Range` row,
#' written as `<earliest> to <latest>` in each column. The cells give the date
#' alone when every time in the column falls at midnight, and the time to the
#' minute, or to the second when any time has seconds. A duration (`difftime`)
#' is summarised as mean (SD) in its own units, which the statistic names, as
#' in `Mean (SD), days`.
#'
#' When `vars` is `NULL`, high-cardinality character/factor columns (those whose
#' number of distinct levels approaches the number of rows, e.g. identifier
#' columns) are skipped automatically, with a message, rather than being
#' expanded into hundreds of one-per-row entries. Pass such a column explicitly
#' via `vars` to override this.
#'
#' @param data A data frame.
#' @param vars Names of the columns to summarise, as a character vector. If
#'   `NULL`, all columns except `group` are used, with high-cardinality
#'   identifier-like columns skipped (see Details).
#' @param group Optional name of the grouping column, given as a string rather
#'   than unquoted. One summary column is produced per level, alongside an
#'   overall column. Records whose group value is missing get a trailing
#'   `Missing` column of their own, so the group sizes still sum to the overall
#'   `N`.
#' @param digits Number of decimal places for numeric summaries.
#' @param missing Whether to add a `Missing, n (%)` row for variables that
#'   contain missing values. Defaults to `TRUE`.
#' @param max_levels When `vars` is `NULL`, character/factor columns whose
#'   distinct-level count is at least `max_levels` *and* exceeds half the number
#'   of rows are treated as identifiers and skipped. Defaults to `20`.
#'
#' @return A data frame with columns `variable`, `statistic`, `Overall`, one
#'   column per group level and, when the grouping variable has missing values,
#'   a trailing `Missing` column. The first row reports `N`.
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

  groups <- if (is.null(group)) list(Overall = data) else {
    parts <- c(list(Overall = data), split(data, data[[group]]))
    # split() drops the rows whose group is missing. Without a column of their
    # own they fall out of every group while Overall still counts them, so the
    # group sizes stop summing to N with nothing on the table to say why.
    if (anyNA(data[[group]])) {
      na_name <- "Missing"
      while (na_name %in% names(parts)) na_name <- paste0(na_name, "_")
      parts[[na_name]] <- data[is.na(data[[group]]), , drop = FALSE]
    }
    parts
  }

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
    if (inherits(col, c("Date", "POSIXt"))) {
      # A date is not a level: expanded as one, it would give a row per day.
      fmt <- date_cell_format(col)
      cells <- vapply(groups, function(g) date_range_cell(g[[v]], fmt),
                      character(1))
      rows[[length(rows) + 1]] <- c(variable = v, statistic = "Range", cells)
    } else if (inherits(col, "difftime")) {
      unit <- units(col)
      cells <- vapply(groups, function(g) {
        num_fmt(as.double(g[[v]], units = unit))
      }, character(1))
      rows[[length(rows) + 1]] <- c(variable = v,
                                    statistic = paste0("Mean (SD), ", unit),
                                    cells)
    } else if (is.numeric(col)) {
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

# The format of the cells of a date or date-time column. It is chosen once for
# the whole column, so that every cell of the row has the same precision: the
# date alone when every time falls at midnight, minutes when no time has
# seconds and seconds otherwise. The Python twin applies the same rule.
date_cell_format <- function(col) {
  if (inherits(col, "Date")) return("%Y-%m-%d")
  # POSIXlt gives the clock time in the column's own time zone, the one the
  # cells are printed in.
  lt <- as.POSIXlt(col[!is.na(col)])
  if (all(lt$hour == 0 & lt$min == 0 & lt$sec == 0)) return("%Y-%m-%d")
  if (all(lt$sec == 0)) return("%Y-%m-%d %H:%M")
  "%Y-%m-%d %H:%M:%S"
}

# One cell of a date row: the earliest and latest values present, or "--" when
# there are none.
date_range_cell <- function(v, fmt) {
  v <- v[!is.na(v)]
  if (!length(v)) return("--")
  paste(format(min(v), format = fmt), "to", format(max(v), format = fmt))
}
