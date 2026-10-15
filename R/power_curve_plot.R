# Power analysis curve -------------------------------------------------------

#' Plot a power analysis curve
#'
#' Draws statistical power against sample size, with a dashed line at a target
#' power (80% by default). The input is usually a power curve produced by
#' `simr::powerCurve()`, though a tidy data frame works equally well, allowing
#' the plot to be redrawn without repeating a power simulation that is often
#' slow to run.
#'
#' A table may hold several curves, one per effect or design, stacked by row.
#' Each is drawn as its own line, told apart by colour and line type. The
#' tables pilotr returns are read as they are: `power_curve_mixed()` gives
#' `n_subject`, `effect`, `power`, `power_lo` and `power_hi`, and
#' `precision_curve()` gives `n_subject`, `param` and the decision
#' probabilities `p_meaningful` and `p_equivalent` with their own `_lo` and
#' `_hi` bounds, which `power` can name. The sample size that pilotr's
#' `target_n()` solves from such a curve, and its interval, can be marked on
#' the plot with `solved`.
#'
#' @param x A `powerCurve` object from 'simr', or a data frame with a sample
#'   size column (`n`, `nlevels`, `x`, `sample_size` or `n_subject`), a power
#'   column (`power`, `mean` or `p`), and optional confidence limits
#'   (`<power>_lo`/`<power>_hi`, `lower`/`upper`, `ci_low`/`ci_high` or
#'   `conf.low`/`conf.high`).
#' @param target Target power, drawn as a horizontal reference line. Use `NA`
#'   to omit it.
#' @param x_lab X-axis label.
#' @param x_breaks Approximate number of x-axis breaks.
#' @param x_expand Optional value(s) to extend the x-axis to.
#' @param ribbon Whether to draw the confidence band as a shaded ribbon
#'   (`TRUE`) or as error bars (`FALSE`).
#' @param title Plot title. If `NULL` and `x` is a 'simr' power curve, the
#'   predictor name stored in the object is used.
#' @param interaction Passed to [format_terms()] when deriving the title from a
#'   'simr' object.
#' @param n,power Columns holding the sample size and the power, as strings or
#'   unquoted names. By default, they are found among the names listed under
#'   `x`. `power` may name any proportion on the 0-1 scale, such as pilotr's
#'   `p_meaningful`.
#' @param group Column that separates several curves, as a string or an
#'   unquoted name. Each level is drawn as its own line, in its own colour and
#'   line type. By default, an `effect`, `param` or `term` column with more than
#'   one level is used, with a message. Rows that share a sample size with no
#'   such column are an error, because joining them would draw a zigzag.
#' @param lower,upper Columns holding the lower and upper confidence limits.
#'   Name both or neither. By default, they are found among the names listed
#'   under `x`.
#' @param y_lab Y-axis label. By default, "Power" when the power column is one
#'   of the names listed under `x`, and the column's name otherwise.
#' @param solved A sample size solved from the curve, with its confidence
#'   interval: a list with numeric `value`, `lo` and `hi`, as pilotr's
#'   `target_n()` and `solve_curve()` return, or a one-row data frame with the
#'   same columns. Other fields are ignored. The solved value is drawn as a
#'   dashed vertical line and its interval as a grey band behind the curve. An
#'   interval that reaches past the swept sizes widens the x-axis to show it.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' pc <- data.frame(
#'   nlevels = c(10, 20, 30, 40, 50, 60),
#'   mean = c(0.18, 0.34, 0.52, 0.66, 0.79, 0.88),
#'   lower = c(0.10, 0.25, 0.42, 0.56, 0.70, 0.81),
#'   upper = c(0.28, 0.44, 0.62, 0.75, 0.86, 0.93)
#' )
#' power_curve_plot(pc, title = "Power for the condition effect")
#'
#' # Two curves in one table, laid out as pilotr's power_curve_mixed() returns
#' # them: one row per sample size and effect.
#' curves <- data.frame(
#'   n_subject = rep(c(20, 40, 60, 80), each = 2),
#'   effect = rep(c("condition", "frequency"), times = 4),
#'   power = c(0.31, 0.12, 0.58, 0.21, 0.78, 0.33, 0.90, 0.45),
#'   power_lo = c(0.23, 0.07, 0.48, 0.14, 0.69, 0.25, 0.83, 0.36),
#'   power_hi = c(0.41, 0.19, 0.67, 0.30, 0.85, 0.43, 0.94, 0.55)
#' )
#' power_curve_plot(curves, group = "effect", x_lab = "Participants")
#'
#' # The sample size at which pc reaches 80% power, with its interval, in the
#' # form pilotr's target_n() returns. The values here are illustrative.
#' power_curve_plot(pc, solved = list(value = 51, lo = 44, hi = 60))
power_curve_plot <- function(x,
                             target = 0.8,
                             x_lab = "Sample size",
                             x_breaks = NULL,
                             x_expand = NULL,
                             ribbon = TRUE,
                             title = NULL,
                             interaction = c("times", "asterisk",
                                             "colon", "space"),
                             n = NULL,
                             power = NULL,
                             group = NULL,
                             lower = NULL,
                             upper = NULL,
                             y_lab = NULL,
                             solved = NULL) {
  interaction <- match.arg(interaction)
  marks <- solved_marks(solved)
  pc <- powercurve_to_df(x, n = rlang::enquo(n), power = rlang::enquo(power),
                         group = rlang::enquo(group),
                         lower = rlang::enquo(lower),
                         upper = rlang::enquo(upper))

  if (is.null(title)) {
    # Only a title recovered from the object is a raw term name in need of
    # tidying; a user-supplied title is finished prose and passes through
    # verbatim.
    title <- attr(pc, "title")
    if (!is.null(title) && interaction != "colon") {
      title <- format_terms(title, interaction = interaction,
                            strip_prefix = FALSE, tidy_intercept = FALSE)
    }
  }
  power_col <- attr(pc, "power_col")
  if (is.null(y_lab)) {
    y_lab <- if (power_col %in% power_candidates) "Power" else power_col
  }
  group_col <- attr(pc, "group_col")
  grouped <- !is.null(group_col)

  has_band <- all(c("lower", "upper") %in% names(pc))

  p <- if (grouped) {
    ggplot2::ggplot(pc, ggplot2::aes(x = .data$n, y = .data$power,
                                     colour = .data$group,
                                     linetype = .data$group,
                                     group = .data$group))
  } else {
    ggplot2::ggplot(pc, ggplot2::aes(x = .data$n, y = .data$power))
  }

  if (!is.null(marks)) {
    # First, so that the interval lies behind the confidence band and the
    # curve. The fill and opacity are those of posterior_plot()'s ROPE band.
    p <- p + ggplot2::annotate(
      "rect", xmin = marks[["lo"]], xmax = marks[["hi"]],
      ymin = -Inf, ymax = Inf, fill = depictr_reference(), alpha = 0.15
    )
  }

  if (has_band) {
    band <- ggplot2::aes(ymin = .data$lower, ymax = .data$upper)
    if (ribbon && grouped) {
      # Translucent, so that overlapping bands stay visible, and without the
      # line type, which belongs to the curve.
      p <- p + ggplot2::geom_ribbon(
        ggplot2::aes(ymin = .data$lower, ymax = .data$upper,
                     fill = .data$group),
        alpha = 0.15, colour = NA, show.legend = FALSE
      ) + scale_fill_depictr(guide = "none")
    } else if (ribbon) {
      p <- p + ggplot2::geom_ribbon(band, fill = "grey88")
    } else if (grouped) {
      p <- p + ggplot2::geom_errorbar(band, width = 0, linetype = 1)
    } else {
      p <- p + ggplot2::geom_errorbar(band, width = 0, colour = "grey50")
    }
  }

  if (!is.na(target)) {
    p <- p + ggplot2::geom_hline(
      yintercept = target, linetype = 2, colour = depictr_reference()
    )
  }
  if (!is.null(marks)) {
    p <- p + ggplot2::geom_vline(
      xintercept = marks[["value"]], linetype = 2, colour = depictr_reference()
    )
  }

  if (grouped) {
    p <- p +
      ggplot2::geom_line(na.rm = TRUE) +
      ggplot2::geom_point(size = 2, na.rm = TRUE) +
      scale_colour_depictr() +
      ggplot2::labs(colour = group_col, linetype = group_col)
  } else {
    p <- p +
      ggplot2::geom_line(colour = depictr_brand(), na.rm = TRUE) +
      ggplot2::geom_point(size = 2, colour = depictr_brand(), na.rm = TRUE)
  }

  p <- p +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, 0.2), labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::scale_x_continuous(n.breaks = x_breaks) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()

  if (!is.null(x_expand)) {
    p <- p + ggplot2::expand_limits(x = x_expand)
  }
  p
}

# ---- internal helpers ------------------------------------------------------

# Column names read without being named. Sample size: simr's summary gives
# `nlevels`, and pilotr's sweeps over participants give `n_subject`. Power:
# simr gives `mean`. A power column found here is labelled "Power" on the axis.
n_candidates <- c("n", "nlevels", "x", "sample_size", "n_subject")
power_candidates <- c("power", "mean", "p")
# pilotr names the focal effect `effect` in power curves and `param` in
# precision curves. A tidy coefficient table names it `term`.
group_candidates <- c("effect", "param", "term")

#' @noRd
powercurve_to_df <- function(x, n = rlang::quo(NULL),
                             power = rlang::quo(NULL),
                             group = rlang::quo(NULL),
                             lower = rlang::quo(NULL),
                             upper = rlang::quo(NULL)) {
  if (is.data.frame(x)) {
    df <- x
    title <- attr(x, "title")
  } else if (inherits(x, "powerCurve")) {
    ensure_installed("simr", "to summarise a powerCurve object")
    df <- as.data.frame(summary(x))
    title <- tryCatch(
      clean_predictor_name(x$text),
      error = function(e) NULL
    )
  } else {
    stop("`x` must be a data frame or a 'simr' powerCurve object.",
         call. = FALSE)
  }

  n_col     <- resolve_var(df, n, "n") %||% pick_col(df, n_candidates)
  power_col <- resolve_var(df, power, "power") %||%
    pick_col(df, power_candidates)
  if (is.na(n_col) || is.na(power_col)) {
    stop("Could not find sample-size and power columns in the data. ",
         "Name them with `n` and `power`.", call. = FALSE)
  }
  out <- data.frame(n = as.numeric(df[[n_col]]),
                    power = as.numeric(df[[power_col]]))

  low <- resolve_var(df, lower, "lower")
  up  <- resolve_var(df, upper, "upper")
  if (is.null(low) != is.null(up)) {
    stop("Name both `lower` and `upper`, or neither.", call. = FALSE)
  }
  if (is.null(low)) {
    # The bounds of the chosen power column come first, so that a pilotr
    # precision table banded by p_meaningful_lo is not given another
    # column's bounds.
    low <- pick_col(df, c(paste0(power_col, "_lo"), "lower", "ci_low",
                          "conf.low"))
    up  <- pick_col(df, c(paste0(power_col, "_hi"), "upper", "ci_high",
                          "conf.high"))
  }
  if (!is.na(low) && !is.na(up)) {
    out$lower <- as.numeric(df[[low]])
    out$upper <- as.numeric(df[[up]])
  }

  group_col <- resolve_var(df, group, "group")
  if (is.null(group_col)) {
    # A column with a single level names the one curve the table holds and
    # separates nothing.
    multi <- Filter(function(col) {
      v <- df[[col]]
      length(unique(v[!is.na(v)])) > 1
    }, intersect(group_candidates, names(df)))
    if (length(multi)) {
      group_col <- multi[1]
      message("power_curve_plot(): drawing one curve per level of `",
              group_col, "`, with sample size from `", n_col,
              "` and power from `", power_col,
              "`. Name the column with `group` to silence this message.")
    }
  }

  if (is.null(group_col)) {
    if (anyDuplicated(out$n[!is.na(out$n)])) {
      stop("Several rows share a sample size; name the column that ",
           "separates the curves with `group`.", call. = FALSE)
    }
  } else {
    grp <- df[[group_col]]
    out$group <- if (is.factor(grp)) droplevels(grp) else
      factor(grp, levels = unique(grp))
    keep <- !is.na(out$n)
    if (anyDuplicated(data.frame(out$n, out$group)[keep, , drop = FALSE])) {
      stop("Several rows of one curve share a sample size. Summarise them, ",
           "or name a column that separates them with `group`.",
           call. = FALSE)
    }
  }

  attr(out, "title") <- title
  attr(out, "power_col") <- power_col
  attr(out, "group_col") <- group_col
  out
}

#' The solved value and its bounds, as a named numeric vector
#'
#' pilotr's `target_n()` and `solve_curve()` return a list with the solved
#' value in `value` and its confidence bounds in `lo` and `hi`, among other
#' fields. A one-row data frame holding the three is read alike, and anything
#' else is refused, a named vector included.
#' @noRd
solved_marks <- function(solved) {
  if (is.null(solved)) return(NULL)
  fields <- c("value", "lo", "hi")
  ok <- is.list(solved) && (!is.data.frame(solved) || nrow(solved) == 1L)
  if (ok) {
    marks <- lapply(fields, function(nm) solved[[nm]])
    ok <- all(vapply(marks, function(v) {
      is.numeric(v) && length(v) == 1L && is.finite(v)
    }, logical(1)))
  }
  if (!ok) {
    stop("`solved` needs numeric `value`, `lo` and `hi`, as pilotr's ",
         "target_n() returns.", call. = FALSE)
  }
  stats::setNames(as.numeric(unlist(marks)), fields)
}

#' @noRd
pick_col <- function(df, cands) {
  hit <- intersect(cands, names(df))
  if (length(hit)) hit[1] else NA_character_
}

#' Extract a clean predictor name from a powerCurve `$text` string
#'
#' 'simr' stores the title as e.g. `"Power for predictor 'word_frequency'"`,
#' where the predictor name is wrapped in single quotes (or back-ticks when it
#' is a non-syntactic name). The previous regex left the leading quote behind,
#' so the title rendered as `'word_frequency`. This strips the boilerplate and
#' any surrounding quoting on both sides.
#' @noRd
clean_predictor_name <- function(text) {
  if (is.null(text) || !length(text)) return(NULL)
  out <- sub("^Power for predictor[: ]*", "", text[1])
  out <- trimws(out)
  # Drop matching leading/trailing quotes or back-ticks left by deparse/quote.
  out <- sub("^['\"`]+", "", out)
  out <- sub("['\"`]+$", "", out)
  out <- trimws(out)
  if (!nzchar(out)) NULL else out
}
