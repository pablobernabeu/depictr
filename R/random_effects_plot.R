# Random-effects caterpillar plot --------------------------------------------

#' Caterpillar plot of random effects
#'
#' Displays the conditional modes ("BLUPs") of a mixed model's random effects as
#' a sorted point-and-interval ("caterpillar") plot. It is the usual way to
#' inspect by-group departures from the average, and to identify unusual groups.
#'
#' @param x Either a mixed model fitted with 'lme4' (`merMod`), or a data frame
#'   with one row per group level and columns such as `level`/`group`,
#'   `estimate`, and either `conf.low`/`conf.high` or `std.error`. An optional
#'   `term` column facets the plot.
#' @param conf_level Confidence level when intervals are derived from standard
#'   errors.
#' @param sort Whether to order the levels by their estimate.
#' @param point_colour Colour for the points and intervals.
#' @param title,x_lab Plot title and value-axis label.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # From a data frame of by-group estimates:
#' re <- data.frame(
#'   level = paste0("G", 1:10),
#'   estimate = sort(rnorm(10)),
#'   std.error = runif(10, 0.2, 0.5)
#' )
#' random_effects_plot(re)
#'
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   m <- lme4::lmer(RT ~ condition + (1 | participant), data = lexical_decision)
#'   random_effects_plot(m)
#' }
#' }
random_effects_plot <- function(x, conf_level = 0.95, sort = TRUE,
                                point_colour = "#005b96",
                                title = NULL, x_lab = "Random effect") {
  re <- if (is.data.frame(x)) ranef_from_df(x, conf_level) else
    ranef_from_model(x, conf_level)

  facets <- length(unique(re$facet)) > 1
  if (sort) {
    ord <- order(re$facet, re$estimate)
    re <- re[ord, , drop = FALSE]
  }
  re$level <- factor(re$level, levels = unique(re$level))

  p <- ggplot2::ggplot(re, ggplot2::aes(x = .data$estimate, y = .data$level)) +
    ggplot2::geom_vline(xintercept = 0, linetype = 2, colour = "grey60") +
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      height = 0, linewidth = 0.6, colour = point_colour, na.rm = TRUE
    ) +
    ggplot2::geom_point(size = 1.6, colour = point_colour) +
    ggplot2::labs(x = x_lab, y = NULL, title = title) +
    theme_depictr(grid = "x")

  if (facets) {
    p <- p + ggplot2::facet_wrap(~ facet, scales = "free_y")
  }
  if (nlevels(re$level) > 30) {
    p <- p + ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                            axis.ticks.y = ggplot2::element_blank())
  }
  p
}

# ---- internal helpers ------------------------------------------------------

#' @noRd
ranef_from_df <- function(x, conf_level) {
  level_col <- intersect(c("level", "group", "grp", "id", "term_level"), names(x))
  est_col   <- intersect(c("estimate", "Estimate", "value", "mean"), names(x))
  if (!length(level_col) || !length(est_col)) {
    stop("A data frame needs a level column and an estimate column.",
         call. = FALSE)
  }
  out <- data.frame(
    level = as.character(x[[level_col[1]]]),
    estimate = as.numeric(x[[est_col[1]]]),
    stringsAsFactors = FALSE
  )
  low <- intersect(c("conf.low", "lower", "CI_2.5"), names(x))
  up  <- intersect(c("conf.high", "upper", "CI_97.5"), names(x))
  se  <- intersect(c("std.error", "se", "SE"), names(x))
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  if (length(low) && length(up)) {
    out$conf.low <- as.numeric(x[[low[1]]])
    out$conf.high <- as.numeric(x[[up[1]]])
  } else if (length(se)) {
    s <- as.numeric(x[[se[1]]])
    out$conf.low <- out$estimate - z * s
    out$conf.high <- out$estimate + z * s
  } else {
    out$conf.low <- NA_real_
    out$conf.high <- NA_real_
  }
  out$facet <- if ("term" %in% names(x)) as.character(x[["term"]]) else "Random effect"
  out
}

#' @noRd
ranef_from_model <- function(model, conf_level) {
  ensure_installed("lme4", "to extract random effects from a mixed model")
  re <- lme4::ranef(model, condVar = TRUE)
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  parts <- lapply(names(re), function(g) {
    df <- re[[g]]
    pv <- attr(df, "postVar")
    terms <- colnames(df)
    levs <- rownames(df)
    do.call(rbind, lapply(seq_along(terms), function(ti) {
      se <- sqrt(pv[ti, ti, ])
      est <- df[[ti]]
      data.frame(
        level = levs,
        estimate = est,
        conf.low = est - z * se,
        conf.high = est + z * se,
        facet = if (length(re) > 1 || length(terms) > 1)
          paste0(g, ": ", terms[ti]) else "Random effect",
        stringsAsFactors = FALSE
      )
    }))
  })
  do.call(rbind, parts)
}
