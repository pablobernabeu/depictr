# Descriptive summary table ("Table 1") --------------------------------------

#' A "Table 1" style descriptive summary
#'
#' Builds the kind of descriptive table that opens many empirical papers:
#' numeric variables are summarised as mean (SD), categorical variables as
#' counts and percentages, optionally split into one column per level of a
#' grouping variable. The result is a plain data frame, ready to pass to
#' [knitr::kable()] or a table package.
#'
#' @param data A data frame.
#' @param vars Columns to summarise. If `NULL`, all columns except `group` are
#'   used.
#' @param group Optional grouping variable; one summary column is produced per
#'   level, alongside an overall column.
#' @param digits Number of decimal places for numeric summaries.
#'
#' @return A data frame with columns `variable`, `statistic`, `Overall` and one
#'   column per group level.
#' @export
#' @examples
#' summary_table(crop_yield, vars = c("yield", "rainfall", "treatment"))
#' summary_table(wellbeing_survey,
#'               vars = c("life_satisfaction", "education"),
#'               group = "region")
summary_table <- function(data, vars = NULL, group = NULL, digits = 1) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (!is.null(group)) {
    if (!group %in% names(data)) {
      stop("Group column `", group, "` not found.", call. = FALSE)
    }
    data[[group]] <- as.factor(data[[group]])
  }
  if (is.null(vars)) vars <- setdiff(names(data), group)
  check_columns(data, vars)

  groups <- if (is.null(group)) list(Overall = data) else
    c(list(Overall = data), split(data, data[[group]]))

  num_fmt <- function(v) {
    v <- v[!is.na(v)]
    if (!length(v)) return("--")
    sprintf(paste0("%.", digits, "f (%.", digits, "f)"),
            mean(v), stats::sd(v))
  }

  rows <- list()
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
  }

  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  # Blank the repeated variable name for readability
  dup <- duplicated(out$variable)
  out$variable[dup] <- ""
  out
}
