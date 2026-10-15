# Frequentist vs. Bayesian comparison ----------------------------------------

#' Plot frequentist and Bayesian estimates together
#'
#' Presents the estimates from a frequentist model and a Bayesian model on one
#' plot, in the first two colours of the colourblind-safe [depictr_palette()]:
#' brand blue for the frequentist estimates and orange for the Bayesian ones,
#' whether the Bayesian side is drawn from draws or from summaries.
#'
#' When `bayesian` carries posterior *draws* (a `brms`/`rstanarm` fit, a
#' `posterior` draws object, a draws matrix, or a long/wide draws data frame),
#' the full posterior *distribution* is drawn per term (a 'ggdist' half-eye)
#' and the frequentist point and confidence interval is overlaid at the same
#' position. When `bayesian` is only a table of posterior *summaries*, the
#' function shows the familiar two-source forest plot via [compare_models()].
#' It reads tidy columns (`term`, `estimate`, `conf.low`, `conf.high`), the
#' `Estimate`, `Q2.5` and `Q97.5` of the matrix `brms::fixef()` returns, and the
#' `l-95% CI` and `u-95% CI` of `summary(fit)$fixed`.
#'
#' Terms are aligned by their canonical display label, so the `brms`-style `b_`
#' prefix is reconciled automatically against the frequentist term names. Draws
#' are read as in [posterior_plot()], so a draws object holding `b_` parameters
#' keeps only those, and two terms that would share a label are an error. With
#' draws, only the terms both sides share are drawn, and a message names any
#' dropped, such as a `sigma` in the posterior. The forest plot of summaries
#' draws every term of either input.
#'
#' `conf_level` is the level of every interval the function computes. For a
#' frequentist model, that is its confidence interval. For posterior draws, it
#' is the outer of the equal-tailed credible intervals drawn beneath each
#' half-eye, so the two sources are compared at one level. The inner interval
#' is 66%, drawn only when `conf_level` exceeds 0.66 so that it stays the
#' narrower of the two. A table of estimates keeps the interval limits it
#' holds, at whatever level they were computed. By default, a caption names the
#' level of each source's intervals or says that they are as supplied.
#'
#' @param frequentist A frequentist model (e.g. from `lm`, `glm` or
#'   `lmerTest::lmer`) or a tidy data frame of estimates.
#' @param bayesian A Bayesian model, a `posterior` draws object, a draws
#'   matrix/data frame, a tidy data frame of posterior summaries or a summary
#'   matrix such as `brms::fixef()` returns.
#' @param conf_level Level of the intervals the function computes: the
#'   confidence intervals of a frequentist model and, when `bayesian` holds
#'   draws, the outer credible interval of each posterior (see Details). A
#'   single number strictly between 0 and 1.
#' @param labels,interaction,intercept See [compare_models()]. On both paths,
#'   an unnamed `labels` vector takes the frequentist terms first, then any
#'   that only the Bayesian input holds. `intercept` defaults to `TRUE` here.
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
#' @param caption Plot caption. The default (`NULL`) names the level of each
#'   source's intervals. Pass `NA` to omit the caption.
#' @param ... Further arguments passed to [compare_models()] on the summary
#'   path (ignored on the distribution path).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Summary path: a tidy "Bayesian" summary as a data frame. The summary here
#' # stands in for a regularised posterior, so a weakly informative prior pulls
#' # each estimate toward zero and narrows its interval; a real posterior would
#' # come from the model fit rather than from arithmetic on the frequentist one.
#' freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
#'            data = wellbeing_survey)
#' bayes <- tidy_estimates(freq)
#' bayes$estimate <- bayes$estimate * 0.9
#' half <- (bayes$conf.high - bayes$conf.low) / 2 * 0.8
#' bayes$conf.low <- bayes$estimate - half
#' bayes$conf.high <- bayes$estimate + half
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
                                      caption = NULL,
                                      ...) {
  check_conf_level(conf_level)
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

  # The namesake behaviour: when the Bayesian side carries actual draws, render
  # the full posterior distribution and overlay the frequentist point + CI.
  if (has_draws(bayesian)) {
    # The default labels name each factor level, read from the frequentist
    # model (e.g. "conditionunrelated" -> "condition: unrelated"). The same map
    # applies to the frequentist estimates and the b_-stripped Bayesian draw
    # names, and any user-supplied `labels` take precedence. The summary path
    # leaves this to compare_models(), which builds the same map itself and
    # must see the user's own `labels` to judge which keys match nothing.
    labels <- merge_pretty_labels(labels,
                                  pretty_coef_map(frequentist, interaction))
    return(fbp_distribution(
      frequentist = frequentist, bayesian = bayesian,
      conf_level = conf_level, labels = labels, interaction = interaction,
      intercept = intercept, freq_label = freq_label, bayes_label = bayes_label,
      reference_line = vertical_line_at_x, scales = scales,
      title = title, subtitle = subtitle, x_lab = x_lab, caption = caption
    ))
  }

  # Summary path: the familiar two-source forest plot. A summary matrix, as
  # brms::fixef() returns, keeps its terms in the row names, which
  # tidy_estimates() reads from a data frame.
  if (is.matrix(bayesian)) bayesian <- as.data.frame(bayesian)
  args <- list(frequentist, bayesian)
  names(args) <- c(freq_label, bayes_label)

  p <- do.call(
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
  # compare_models() takes no caption, so it is added here. A table of
  # posterior summaries keeps its own intervals, whose level it does not
  # record.
  caption <- fbp_caption(
    caption,
    fbp_level_text("Frequentist", frequentist, conf_level,
                   "confidence interval"),
    fbp_level_text("Bayesian", bayesian, conf_level, "interval")
  )
  if (!is.null(caption)) p <- p + ggplot2::labs(caption = caption)
  p
}

# ---- distribution path ------------------------------------------------------

#' Posterior distributions with the frequentist point + CI overlaid
#'
#' Draws a 'ggdist' half-eye per term from the Bayesian draws and overlays the
#' frequentist estimate and confidence interval at the same y position, the
#' half-eyes in orange and the overlay in brand blue. Terms are matched by
#' canonical label so `b_`-prefixed Bayesian names line up with the frequentist
#' ones, and only the matched terms are drawn. Falls back to point + interval
#' slabs when 'ggdist' is unavailable.
#' @noRd
fbp_distribution <- function(frequentist, bayesian, conf_level, labels,
                             interaction, intercept, freq_label, bayes_label,
                             reference_line, scales = "fixed",
                             title, subtitle, x_lab, caption = NULL) {
  # On the summary path, compare_models() colours the sources in order,
  # frequentist first, and the same mapping here keeps each source's colour on
  # either path.
  pal <- depictr_palette(2)
  freq_colour  <- pal[1]
  bayes_colour <- pal[2]
  # The posterior's outer interval is drawn at the level of the frequentist
  # one. The 66% inner interval is kept only while it is the narrower.
  widths <- if (conf_level > 0.66) c(0.66, conf_level) else conf_level
  tails <- c((1 - conf_level) / 2, 1 - (1 - conf_level) / 2)

  # Bayesian draws -> long, labelled by canonical display label.
  draws <- extract_draws(bayesian)
  # Frequentist summaries -> the same canonical label space.
  freq <- tidy_estimates(frequentist, conf_level = conf_level)

  # An unnamed `labels` vector is read as compare_models() reads it on the
  # summary path: one label per term drawn, the frequentist terms first, after
  # the intercept rule. The draws hold one row per sample, so the vector is
  # keyed by term name before either side is labelled.
  if (!is.null(labels) && is.null(names(labels))) {
    term_names <- unique(c(freq$term, draws$term))
    is_intercept <- term_names %in% c("(Intercept)", "Intercept", "b_Intercept")
    if (!intercept) term_names <- term_names[!is_intercept]
    labels <- key_labels_by_term(labels, term_names,
                                 pretty_coef_map(frequentist, interaction),
                                 interaction,
                                 !intercept && any(is_intercept))
  }
  # Each Bayesian term is labelled once and its draws take the label by
  # match(), since labelling every draw took seconds.
  b_params <- unique(draws$term)
  draws$label <- make_labels(b_params, labels, interaction)[
    match(draws$term, b_params)
  ]
  freq$label <- make_labels(freq$term, labels, interaction)

  if (!intercept) {
    drop <- c("(Intercept)", "Intercept", "b_Intercept")
    draws <- draws[!draws$term %in% drop, , drop = FALSE]
    freq  <- freq[!freq$term %in% drop, , drop = FALSE]
  }
  if (nrow(draws) == 0) {
    stop("No Bayesian terms left to plot.", call. = FALSE)
  }

  # Within each side, two terms under one label would share a row, and on the
  # Bayesian side their draws would pool into one slab.
  check_label_clash(draws$term, draws$label)
  check_label_clash(freq$term, freq$label)

  # Only the terms both sides share are drawn. A slab with no frequentist
  # overlay (a posterior's sigma, say), or an overlay with no slab, compares
  # nothing.
  b_terms <- draws[!duplicated(draws$term), c("term", "label")]
  f_terms <- freq[!duplicated(freq$term), c("term", "label")]
  shared <- intersect(b_terms$label, f_terms$label)
  if (!length(shared)) {
    stop("The frequentist and Bayesian inputs share no terms. Frequentist: ",
         and_list(f_terms$term), ". Bayesian: ", and_list(b_terms$term), ".",
         call. = FALSE)
  }
  b_only <- b_terms$term[!b_terms$label %in% shared]
  f_only <- f_terms$term[!f_terms$label %in% shared]
  if (length(b_only) || length(f_only)) {
    message("Dropped the terms the two inputs do not share.",
            if (length(b_only)) {
              paste0(" Bayesian only: ", and_list(b_only), ".")
            },
            if (length(f_only)) {
              paste0(" Frequentist only: ", and_list(f_only), ".")
            })
    draws <- draws[draws$label %in% shared, , drop = FALSE]
    freq  <- freq[freq$label %in% shared, , drop = FALSE]
  }

  # Shared, reversed factor levels (top-to-bottom reading order), in the order
  # of the Bayesian terms.
  lvls <- rev(unique(draws$label))
  draws$label <- factor(draws$label, levels = lvls)
  freq$label  <- factor(freq$label,  levels = lvls)

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
      .width = widths, point_interval = "median_qi",
      slab_alpha = 0.6, na.rm = TRUE
    )
  } else {
    # The fallback summarises the draws to their median and the conf_level
    # interval alone, and the caption says so.
    widths <- conf_level
    bsumm <- do.call(rbind, lapply(split(draws$.value, draws$label), function(v) {
      q <- stats::quantile(v, c(tails[1], 0.5, tails[2]), names = FALSE,
                           na.rm = TRUE)
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

  caption <- fbp_caption(
    caption,
    fbp_level_text("Frequentist", frequentist, conf_level,
                   "confidence interval"),
    sprintf("Bayesian: posterior median with %s equal-tailed credible %s.",
            and_list(sprintf("%g%%", 100 * widths)),
            if (length(widths) > 1) "intervals" else "interval")
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
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle,
                  caption = caption) +
    theme_depictr(grid = "x")

  # Free-scaled, one-term-per-row layout (the flagship default): a large
  # intercept no longer squishes the slopes. The reference line is drawn only in
  # panels whose span (the posterior's conf_level interval unioned with the
  # frequentist CI) brackets it, so a far-from-zero panel is not stretched back
  # to the line.
  if (scales == "free") {
    if (!is.na(ref)) {
      labs_all <- levels(draws$label)
      dq <- tapply(draws$.value, draws$label, function(v)
        stats::quantile(v, tails, names = FALSE, na.rm = TRUE))
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
        # geom_vline() never inherits the plot's aesthetics. Passing
        # inherit.aes = FALSE as well warns on ggplot2 3.5.x.
        p <- p + ggplot2::geom_vline(
          data = refdf, ggplot2::aes(xintercept = .data$xref),
          linetype = 2, colour = depictr_reference()
        )
      }
    }
    p <- p +
      ggplot2::facet_wrap(ggplot2::vars(.data$label), ncol = 1,
                          scales = "free", strip.position = "top",
                          labeller = ggplot2::label_wrap_gen(width = 28)) +
      # Each panel holds a single row whose half-eye slab rises upward from the
      # baseline and whose frequentist overlay sits just below it, so the default
      # discrete expansion (add = 0.6 each side) leaves a wide empty band down to
      # the x-axis. Tighten the lower expansion (and trim the upper) so the geoms
      # sit snugly above the axis.
      ggplot2::scale_y_discrete(
        expand = ggplot2::expansion(add = c(0.18, 0.45))
      ) +
      ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                     axis.ticks.y = ggplot2::element_blank(),
                     panel.spacing.y = ggplot2::unit(2, "pt"))
  }
  p
}

# ---- caption ----------------------------------------------------------------

#' The caption of either path
#'
#' `NULL` asks for the automatic caption, one sentence per source, and `NA`
#' omits it. Anything else is used as given. Each sentence takes a line of its
#' own: ggplot2 does not wrap a caption, and on one line the posterior's
#' sentence ran past the left edge of a figure seven inches wide.
#' @noRd
fbp_caption <- function(caption, frequentist_text, bayesian_text) {
  if (is.null(caption)) {
    return(paste(frequentist_text, bayesian_text, sep = "\n"))
  }
  if (length(caption) == 1 && is.na(caption)) return(NULL)
  caption
}

#' The caption's sentence on one source's intervals
#'
#' A table that holds interval limits of its own is drawn with them, at a level
#' the table does not record. Any other limits are computed at `conf_level`,
#' from a fitted model or from a table's standard errors.
#' @noRd
fbp_level_text <- function(source, x, conf_level, interval) {
  if (holds_intervals(x)) {
    return(sprintf("%s: intervals as supplied.", source))
  }
  sprintf("%s: %g%% %s.", source, 100 * conf_level, interval)
}
