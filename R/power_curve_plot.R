# Power analysis curve -------------------------------------------------------

#' Plot a power analysis curve
#'
#' Draws statistical power against sample size, with a dashed line at a target
#' power (80% by default). The input is usually a power curve produced by
#' `simr::powerCurve()`, though a tidy data frame works equally well, allowing
#' the plot to be redrawn without repeating a power simulation that is often
#' slow to run.
#'
#' The function refactors the original `powercurvePlot()` gist.
#'
#' @param x A `powerCurve` object from 'simr', or a data frame with a sample
#'   size column (`nlevels`, `n` or `x`), a power column (`mean` or `power`),
#'   and optional `lower`/`upper` confidence limits.
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
power_curve_plot <- function(x,
                             target = 0.8,
                             x_lab = "Sample size",
                             x_breaks = NULL,
                             x_expand = NULL,
                             ribbon = TRUE,
                             title = NULL,
                             interaction = c("times", "asterisk",
                                             "colon", "space")) {
  interaction <- match.arg(interaction)
  pc <- powercurve_to_df(x)

  if (is.null(title)) title <- attr(pc, "title")
  if (!is.null(title) && interaction != "colon") {
    title <- format_terms(title, interaction = interaction,
                          strip_prefix = FALSE, tidy_intercept = FALSE)
  }

  has_band <- all(c("lower", "upper") %in% names(pc))

  p <- ggplot2::ggplot(pc, ggplot2::aes(x = .data$n, y = .data$power))

  if (has_band) {
    if (ribbon) {
      p <- p + ggplot2::geom_ribbon(
        ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
        fill = "grey88"
      )
    } else {
      p <- p + ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
        width = 0, colour = "grey50"
      )
    }
  }

  if (!is.na(target)) {
    p <- p + ggplot2::geom_hline(
      yintercept = target, linetype = 2, colour = depictr_reference()
    )
  }

  p <- p +
    ggplot2::geom_line(colour = depictr_brand(), na.rm = TRUE) +
    ggplot2::geom_point(size = 2, colour = depictr_brand(), na.rm = TRUE) +
    ggplot2::scale_y_continuous(
      name = "Power", limits = c(0, 1),
      breaks = seq(0, 1, 0.2), labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::scale_x_continuous(n.breaks = x_breaks) +
    ggplot2::labs(x = x_lab, title = title) +
    theme_depictr()

  if (!is.null(x_expand)) {
    p <- p + ggplot2::expand_limits(x = x_expand)
  }
  p
}

# ---- internal helpers ------------------------------------------------------

#' @noRd
powercurve_to_df <- function(x) {
  if (is.data.frame(x)) {
    df <- x
    title <- attr(x, "title")
  } else if (inherits(x, "powerCurve")) {
    ensure_installed("simr", "to summarise a powerCurve object")
    df <- as.data.frame(summary(x))
    title <- tryCatch(
      stringr::str_remove(stringr::str_remove_all(x$text, "Power for predictor |^'|'$"), "$^"),
      error = function(e) NULL
    )
  } else {
    stop("`x` must be a data frame or a 'simr' powerCurve object.",
         call. = FALSE)
  }

  n_col     <- pick_col(df, c("n", "nlevels", "x", "sample_size"))
  power_col <- pick_col(df, c("power", "mean", "p"))
  if (is.na(n_col) || is.na(power_col)) {
    stop("Could not find sample-size and power columns in the data.",
         call. = FALSE)
  }
  out <- data.frame(n = as.numeric(df[[n_col]]),
                    power = as.numeric(df[[power_col]]))
  low <- pick_col(df, c("lower", "ci_low", "conf.low"))
  up  <- pick_col(df, c("upper", "ci_high", "conf.high"))
  if (!is.na(low) && !is.na(up)) {
    out$lower <- as.numeric(df[[low]])
    out$upper <- as.numeric(df[[up]])
  }
  attr(out, "title") <- title
  out
}

#' @noRd
pick_col <- function(df, cands) {
  hit <- intersect(cands, names(df))
  if (length(hit)) hit[1] else NA_character_
}
