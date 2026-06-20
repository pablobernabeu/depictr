# Frequentist vs. Bayesian comparison ----------------------------------------

#' Plot frequentist and Bayesian estimates together
#'
#' Presents the estimates from a frequentist model and a Bayesian model on one
#' plot, with the two sources distinguished by the first two colours of the
#' colourblind-safe [depictr_palette()] (brand blue and orange).
#'
#' This is the modernised successor to the original `frequentist_bayesian_plot()`
#' gist, which built on `brms::mcmc_plot()` to show the full Bayesian posterior
#' with the frequentist estimate overlaid. That namesake behaviour is restored
#' here: when `bayesian` carries posterior *draws* (a `brms`/`rstanarm` fit, a
#' `posterior` draws object, a draws matrix, or a long/wide draws data frame),
#' the full posterior **distribution** is drawn per term (a 'ggdist' half-eye)
#' and the frequentist **point and confidence interval** is overlaid at the same
#' position. When `bayesian` is only a tidy table of posterior *summaries*
#' (columns such as `term`, `estimate`, `conf.low`/`conf.high`, or the
#' `Estimate`, `l-95% CI`, `u-95% CI` of `brms::fixef()`), the function shows the
#' familiar two-source forest plot via [compare_models()].
#'
#' Terms are aligned by their canonical display label, so the `brms`-style `b_`
#' prefix is reconciled automatically against the frequentist term names.
#'
#' @param frequentist A frequentist model (e.g. from `lm`, `glm` or
#'   `lmerTest::lmer`) or a tidy data frame of estimates.
#' @param bayesian A Bayesian model, a `posterior` draws object, a draws
#'   matrix/data frame, or a tidy data frame of posterior summaries.
#' @param conf_level Confidence/credible level for models.
#' @param labels,interaction,intercept See [compare_models()].
#'   `intercept` defaults to `TRUE` here, matching the original behaviour.
#' @param facet,scales Layout controls. Because a Bayesian model almost always
#'   carries a large intercept alongside small slopes, the comparison defaults
#'   to a faceted, free-scaled layout (`facet = TRUE`): each term gets its own
#'   panel and free x-axis, so every posterior and its frequentist overlay stay
#'   legible. Pass `facet = FALSE` (or `scales = "fixed"`) for the classic
#'   single shared-axis plot.
#' @param note_frequentist_no_prior If `TRUE`, append "(no prior)" to the
#'   frequentist legend label, which is helpful when the title names the
#'   Bayesian prior.
#' @param vertical_line_at_x Position of the vertical reference line (`NA` to
#'   omit).
#' @param title,subtitle,x_lab Title, subtitle and x-axis label.
#' @param ... Further arguments passed to [compare_models()] on the summary
#'   path (ignored on the distribution path).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Summary path: a tidy "Bayesian" summary as a data frame.
#' freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
#'            data = wellbeing_survey)
#' bayes <- tidy_estimates(freq)
#' bayes$estimate <- bayes$estimate * 0.95
#' frequentist_bayesian_plot(freq, bayes,
#'                           title = "Frequentist vs. Bayesian estimates")
#'
#' # Distribution path: simulated posterior draws (one column per term) drawn as
#' # full posteriors with the frequentist point + CI overlaid.
#' set.seed(1)
#' co <- coef(freq)
#' draws <- as.data.frame(lapply(co, function(m) rnorm(400, m, abs(m) * 0.1 + 0.05)))
#' names(draws) <- names(co)
#' frequentist_bayesian_plot(freq, draws,
#'                           title = "Posterior with frequentist overlay")
frequentist_bayesian_plot <- function(frequentist,
                                      bayesian,
                                      conf_level = 0.95,
                                      labels = NULL,
                                      interaction = c("times", "asterisk",
                                                      "colon", "space"),
                                      intercept = TRUE,
                                      facet = TRUE,
                                      scales = c("free", "fixed"),
                                      note_frequentist_no_prior = FALSE,
                                      vertical_line_at_x = 0,
                                      title = NULL,
                                      subtitle = NULL,
                                      x_lab = "Estimate",
                                      ...) {
  interaction <- match.arg(interaction)
  # `facet` is the primary control; `scales` is honoured only when supplied
  # explicitly, so `facet = FALSE` stays meaningful despite the "free" default.
  scales <- if (missing(scales)) {
    if (facet) "free" else "fixed"
  } else {
    match.arg(scales)
  }
  freq_label <- if (note_frequentist_no_prior) {
    "Frequentist analysis\n(no prior)"
  } else {
    "Frequentist analysis"
  }
  bayes_label <- "Bayesian analysis"

  # Prettify coefficient names to the effect (variable) name by default, from
  # the frequentist model (e.g. "conditionunrelated" -> "condition"); the same
  # map applies to the frequentist estimates and the b_-stripped Bayesian draw
  # names, and any user-supplied `labels` take precedence.
  labels <- merge_pretty_labels(labels, pretty_coef_map(frequentist))

  # The namesake behaviour: when the Bayesian side carries actual draws, render
  # the full posterior distribution and overlay the frequentist point + CI.
  if (has_draws(bayesian)) {
    return(fbp_distribution(
      frequentist = frequentist, bayesian = bayesian,
      conf_level = conf_level, labels = labels, interaction = interaction,
      intercept = intercept, freq_label = freq_label, bayes_label = bayes_label,
      reference_line = vertical_line_at_x, scales = scales,
      title = title, subtitle = subtitle, x_lab = x_lab
    ))
  }

  # Summary path: the familiar two-source forest plot.
  args <- list(frequentist, bayesian)
  names(args) <- c(freq_label, bayes_label)

  do.call(
    compare_models,
    c(args, list(
      conf_level = conf_level,
      intercept = intercept,
      labels = labels,
      interaction = interaction,
      facet = identical(scales, "free"),
      scales = scales,
      reference_line = vertical_line_at_x,
      palette = depictr_palette(2),
      legend_title = NULL,
      title = title,
      subtitle = subtitle,
      x_lab = x_lab,
      ...
    ))
  )
}

# ---- distribution path ------------------------------------------------------

#' Posterior distributions with the frequentist point + CI overlaid
#'
#' Draws a 'ggdist' half-eye per term from the Bayesian draws and overlays the
#' frequentist estimate and confidence interval at the same y position, in the
#' two leading colours of [depictr_palette()]. Terms are matched by canonical
#' label so `b_`-prefixed Bayesian names line up with the frequentist ones.
#' Falls back to point + interval slabs when 'ggdist' is unavailable.
#' @noRd
fbp_distribution <- function(frequentist, bayesian, conf_level, labels,
                             interaction, intercept, freq_label, bayes_label,
                             reference_line, scales = "fixed",
                             title, subtitle, x_lab) {
  pal <- depictr_palette(2)
  bayes_colour <- pal[1]
  freq_colour  <- pal[2]

  # Bayesian draws -> long, labelled by canonical display label.
  draws <- extract_draws(bayesian)
  draws$label <- make_labels(draws$term, labels, interaction)

  # Frequentist summaries -> the same canonical label space.
  freq <- tidy_estimates(frequentist, conf_level = conf_level)
  freq$label <- make_labels(freq$term, labels, interaction)

  if (!intercept) {
    drop <- c("(Intercept)", "Intercept", "b_Intercept")
    draws <- draws[!draws$term %in% drop, , drop = FALSE]
    freq  <- freq[!freq$term %in% drop, , drop = FALSE]
  }
  if (nrow(draws) == 0) {
    stop("No Bayesian terms left to plot.", call. = FALSE)
  }

  # Shared, reversed factor levels (top-to-bottom reading order), driven by the
  # Bayesian terms with any frequentist-only terms appended.
  lvls <- unique(c(draws$label, freq$label))
  lvls <- rev(lvls)
  draws$label <- factor(draws$label, levels = lvls)
  freq$label  <- factor(freq$label,  levels = lvls)
  # Keep only frequentist rows that match a plotted (Bayesian) term, plus carry
  # any extras for completeness of the legend.
  freq <- freq[!is.na(freq$label), , drop = FALSE]

  ref <- if (is.null(reference_line) || all(is.na(reference_line))) {
    NA_real_
  } else {
    reference_line[1]
  }

  use_ggdist <- requireNamespace("ggdist", quietly = TRUE)
  if (!use_ggdist) {
    message("Package 'ggdist' is not installed; drawing the Bayesian side as ",
            "point + interval instead of a posterior density. Install it with ",
            "install.packages('ggdist').")
  }

  p <- ggplot2::ggplot()
  if (!is.na(ref) && scales == "fixed") {
    p <- p + ggplot2::geom_vline(xintercept = ref, linetype = 2,
                                 colour = depictr_reference())
  }

  if (use_ggdist) {
    p <- p + ggdist::stat_halfeye(
      data = draws,
      ggplot2::aes(x = .data$.value, y = .data$label,
                   colour = bayes_label, fill = bayes_label),
      .width = c(0.66, 0.95), point_interval = "median_qi",
      slab_alpha = 0.6, na.rm = TRUE
    )
  } else {
    # Summarise the draws to a point + 95% interval for the fallback.
    bsumm <- do.call(rbind, lapply(split(draws$.value, draws$label), function(v) {
      q <- stats::quantile(v, c(0.025, 0.5, 0.975), names = FALSE, na.rm = TRUE)
      data.frame(centre = q[2], lo = q[1], hi = q[3])
    }))
    bsumm$label <- factor(rownames(bsumm), levels = lvls)
    p <- p +
      ggplot2::geom_linerange(
        data = bsumm,
        ggplot2::aes(y = .data$label, xmin = .data$lo, xmax = .data$hi,
                     colour = bayes_label),
        linewidth = 0.9
      ) +
      ggplot2::geom_point(
        data = bsumm,
        ggplot2::aes(x = .data$centre, y = .data$label, colour = bayes_label),
        size = 2
      )
  }

  # Frequentist point + CI overlay, nudged just below the slab baseline so it
  # reads as a separate series rather than colliding with the posterior point.
  nudge <- ggplot2::position_nudge(y = -0.12)
  p <- p +
    ggplot2::geom_errorbar(
      data = freq,
      ggplot2::aes(y = .data$label, xmin = .data$conf.low,
                   xmax = .data$conf.high, colour = freq_label),
      orientation = "y", width = 0.12, linewidth = 0.8, position = nudge,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      data = freq,
      ggplot2::aes(x = .data$estimate, y = .data$label, colour = freq_label),
      size = 2.4, position = nudge, na.rm = TRUE
    )

  p <- p +
    ggplot2::scale_colour_manual(
      values = stats::setNames(c(bayes_colour, freq_colour),
                               c(bayes_label, freq_label)),
      breaks = c(bayes_label, freq_label), name = NULL
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(bayes_colour, bayes_label), guide = "none"
    ) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")

  # Free-scaled, one-term-per-row layout (the flagship default): a large
  # intercept no longer squishes the slopes. The reference line is drawn only in
  # panels whose span (Bayesian 95% interval unioned with the frequentist CI)
  # brackets it, so a far-from-zero panel is not stretched back to the line.
  if (scales == "free") {
    if (!is.na(ref)) {
      labs_all <- levels(draws$label)
      dq <- tapply(draws$.value, draws$label, function(v)
        stats::quantile(v, c(0.025, 0.975), names = FALSE, na.rm = TRUE))
      lo <- vapply(labs_all, function(l)
        min(c(dq[[l]][1], freq$conf.low[freq$label == l]), na.rm = TRUE),
        numeric(1))
      hi <- vapply(labs_all, function(l)
        max(c(dq[[l]][2], freq$conf.high[freq$label == l]), na.rm = TRUE),
        numeric(1))
      keep <- is.finite(lo) & is.finite(hi) & ref >= lo & ref <= hi
      if (any(keep)) {
        refdf <- data.frame(
          label = factor(labs_all[keep], levels = levels(draws$label)),
          xref = ref, stringsAsFactors = FALSE
        )
        p <- p + ggplot2::geom_vline(
          data = refdf, ggplot2::aes(xintercept = .data$xref),
          linetype = 2, colour = depictr_reference(), inherit.aes = FALSE
        )
      }
    }
    p <- p +
      ggplot2::facet_wrap(ggplot2::vars(.data$label), ncol = 1,
                          scales = "free", strip.position = "top",
                          labeller = ggplot2::label_wrap_gen(width = 28)) +
      ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                     axis.ticks.y = ggplot2::element_blank(),
                     panel.spacing.y = ggplot2::unit(2, "pt"))
  }
  p
}
