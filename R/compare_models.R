# Compare estimates from several sources -------------------------------------

#' Compare estimates from several models or sources
#'
#' Overlays the estimates from two or more models (or tidy estimate tables) on a
#' single forest plot, with one colour per source. It is the general engine
#' behind [frequentist_bayesian_plot()] (frequentist against Bayesian), and
#' serves equally well for comparing nested models, several optimisers, or
#' estimates before and after a transformation.
#'
#' @param ... Two or more fitted models and/or tidy data frames of estimates.
#'   Name the arguments to label the sources (e.g.
#'   `compare_models(Frequentist = m1, Bayesian = m2)`).
#' @param names Optional character vector of source labels, overriding the
#'   names of `...`.
#' @param conf_level Confidence/credible level for models, a single number
#'   strictly between 0 and 1.
#' @param intercept Whether to keep the intercept term. Defaults to `FALSE`.
#' @param order Order of the terms, by their average estimate across sources.
#'   `"ascending"` puts the smallest estimate at the bottom and the largest at
#'   the top, so estimates increase up the axis. `"descending"` does the
#'   reverse, and `"none"` keeps the terms in the order they first appear, from
#'   top to bottom. The faceted layout (`facet = TRUE`) stacks its panels the
#'   other way up.
#' @param labels Optional display labels. An unnamed vector gives one label per
#'   term, whatever `order` is. The terms are taken in the order they first
#'   appear across the sources, each source in the order [tidy_estimates()]
#'   returns, after the intercept is dropped unless `intercept = TRUE`. Terms
#'   drawn on one row, such as `stress` and brms's `b_stress`, take one label.
#'   A named vector mapping raw term names to labels, such as
#'   `c(soil_ph = "Soil pH")`, is safer. If `NULL`, the terms are labelled as
#'   in [coefficient_plot()], each factor level with its variable and level
#'   (`treatment: enhanced`), from every fitted model among the sources.
#' @param interaction Passed to [format_terms()].
#' @param dodge_width Vertical spacing between sources sharing a term.
#' @param reference_line Position of a vertical reference line. Defaults to 0,
#'   or to 1 when `exponentiate = TRUE`. Use `NA` to omit it.
#' @param palette Colours for the sources; defaults to [depictr_palette()].
#' @param point_size,line_size Point and interval-line sizes.
#' @param facet Whether to give each term its own panel with a free x-axis,
#'   laid out one per row, so that terms on very different scales (for example a
#'   large intercept alongside small slopes) stay legible. The source overlay
#'   and its single legend are preserved within the faceted layout. Defaults to
#'   `FALSE`. A convenience alias for `scales = "free"`.
#' @param scales Either `"fixed"` (the default, a single shared x-axis) or
#'   `"free"` (one free-scaled panel per term). When `facet = TRUE` this is
#'   forced to `"free"`.
#' @param exponentiate Whether to draw every source's exponentiated estimates
#'   and intervals on a log10 axis, as odds or rate ratios. Each model is
#'   exponentiated by [tidy_estimates()], and a data frame among the sources
#'   must hold estimates on the link scale, since it is exponentiated too.
#'   Defaults to `FALSE`.
#' @param legend_title,legend_ncol Legend title and number of columns.
#' @param title,subtitle,x_lab Title, subtitle and x-axis label. `x_lab`
#'   defaults to "Estimate". With `exponentiate = TRUE` it defaults to the name
#'   of the ratio, as in [coefficient_plot()], when the fitted models agree on
#'   it, and to "exp(Estimate)" when they do not.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' m1 <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
#' m2 <- lm(yield ~ rainfall + fertiliser + soil_ph,
#'          data = crop_yield[crop_yield$treatment == "standard", ])
#' compare_models(`All fields` = m1, `Standard only` = m2,
#'                        title = "Estimates by subset")
#'
#' # Keep the intercept legible alongside the slopes:
#' compare_models(`All fields` = m1, `Standard only` = m2,
#'                intercept = TRUE, facet = TRUE)
#'
#' # Odds ratios from two logistic regressions:
#' g1 <- glm(accuracy ~ word_frequency + condition,
#'           data = lexical_decision, family = binomial)
#' g2 <- glm(accuracy ~ word_frequency + condition + modality,
#'           data = lexical_decision, family = binomial)
#' compare_models(Reduced = g1, Full = g2, exponentiate = TRUE)
compare_models <- function(...,
                                    names = NULL,
                                    conf_level = 0.95,
                                    intercept = FALSE,
                                    order = c("none", "ascending", "descending"),
                                    labels = NULL,
                                    interaction = c("times", "asterisk",
                                                    "colon", "space"),
                                    dodge_width = 0.6,
                                    reference_line = if (exponentiate) 1 else 0,
                                    palette = NULL,
                                    point_size = 2.2,
                                    line_size = 0.7,
                                    facet = FALSE,
                                    scales = c("fixed", "free"),
                                    exponentiate = FALSE,
                                    legend_title = "Source",
                                    legend_ncol = 1,
                                    title = NULL,
                                    subtitle = NULL,
                                    x_lab = NULL) {
  check_conf_level(conf_level)
  order <- match.arg(order)
  interaction <- match.arg(interaction)
  scales <- match.arg(scales)
  if (facet) scales <- "free"
  check_exponentiate(exponentiate)

  sources <- list(...)
  if (length(sources) < 2) {
    stop("Supply at least two models or data frames to compare.", call. = FALSE)
  }
  # `names` is also an argument here, so call base::names() explicitly to make
  # the function call unambiguous to readers (R already resolves it correctly).
  src_names <- names %||% base::names(sources)
  if (is.null(src_names) || any(!nzchar(src_names))) {
    auto <- paste("Source", seq_along(sources))
    if (is.null(src_names)) src_names <- auto
    else src_names[!nzchar(src_names)] <- auto[!nzchar(src_names)]
  }

  tidied <- Map(function(s, nm) {
    e <- tidy_estimates(s, conf_level = conf_level, exponentiate = exponentiate)
    e$source <- nm
    e
  }, sources, src_names)
  est <- do.call(rbind, tidied)
  rownames(est) <- NULL

  # The ratio is named after the fitted models. Data frames carry no family,
  # and models of different families share only the neutral name.
  x_lab <- x_lab %||% if (exponentiate) {
    named <- unique(vapply(Filter(Negate(is.data.frame), sources), ratio_label,
                           character(1)))
    if (length(named) == 1) named else "exp(Estimate)"
  } else {
    "Estimate"
  }

  # Align the intercept across sources: frequentist models report "(Intercept)"
  # while Bayesian summaries often use "Intercept" or "b_Intercept". Collapsing
  # the aliases to a single canonical name lets the overlay (and faceting) match
  # the term, instead of producing two near-identical rows/panels.
  est$term[est$term %in% c("Intercept", "b_Intercept")] <- "(Intercept)"

  # Judged before the intercept is dropped, so labelling a term that is merely
  # not plotted is not reported as a typo.
  warn_unused_labels(est$term, labels)

  intercept_dropped <- FALSE
  if (!intercept) {
    is_intercept <- est$term %in% c("(Intercept)", "Intercept", "b_Intercept")
    intercept_dropped <- any(is_intercept)
    est <- est[!is_intercept, , drop = FALSE]
  }
  if (nrow(est) == 0) {
    stop("No terms left to plot.", call. = FALSE)
  }

  # Align rows from different sources by a CANONICAL display label rather than
  # the raw term name, so concepts that tidy to the same label (e.g. "stress"
  # and the brms-style "b_stress") share a single row instead of producing
  # duplicated factor levels. All ordering and grid-completion below therefore
  # works on `label`, not `term`.
  #
  # The default labels name each factor level, and they come from every fitted
  # model among the sources, so a factor term that only a later model holds is
  # labelled too. User-supplied `labels` take precedence over them.
  auto <- pretty_coef_maps(sources, interaction)
  # An unnamed `labels` vector gives one label per term drawn, in the order the
  # terms first appear across the sources. The stacked table holds each term
  # once per source, so the vector is keyed by raw term name for the lookup
  # below. Terms that share a row, such as stress and brms's b_stress, share a
  # label.
  if (!is.null(labels) && is.null(base::names(labels))) {
    labels <- key_labels_by_term(labels, est$term, auto, interaction,
                                 intercept_dropped)
  }
  labels <- merge_pretty_labels(labels, auto)
  est$label <- make_labels(est$term, labels, interaction)

  label_levels <- unique(est$label)
  if (order != "none") {
    # Ratios are averaged on the log scale they are drawn on, which orders
    # them by their geometric mean.
    on_axis <- if (exponentiate) log(est$estimate) else est$estimate
    avg <- tapply(on_axis, est$label, mean, na.rm = TRUE)
    label_levels <- base::names(sort(avg, decreasing = (order == "descending")))
  } else {
    label_levels <- rev(label_levels)
  }

  est$source <- factor(est$source, levels = src_names)

  # Complete the label x source grid so every source has a row for every term.
  # The added rows carry NA estimates (dropped by the geoms via `na.rm`), which
  # keeps position_dodge from mis-centring terms that appear in only one source.
  grid <- expand.grid(
    label  = label_levels,
    source = src_names,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  est <- merge(grid, est, by = c("label", "source"), all.x = TRUE,
               sort = FALSE)

  est$label <- factor(est$label, levels = label_levels)
  est$source <- factor(est$source, levels = src_names)

  pal <- palette %||% depictr_palette(length(src_names))
  dodge <- ggplot2::position_dodge(width = dodge_width)

  p <- ggplot2::ggplot(
    est,
    ggplot2::aes(x = .data$estimate, y = .data$label, colour = .data$source)
  )

  # Shared-axis layout: one full-height reference line. Faceted layout: drawn
  # per panel in add_term_facets(), so a large-intercept panel is not stretched.
  if (!is.na(reference_line) && scales == "fixed") {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line, linetype = 2, colour = depictr_reference()
    )
  }

  p <- p +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      orientation = "y", width = 0.18, linewidth = line_size,
      position = dodge, na.rm = TRUE
    ) +
    ggplot2::geom_point(size = point_size, position = dodge, na.rm = TRUE) +
    ggplot2::scale_colour_manual(
      values = pal,
      guide = ggplot2::guide_legend(title = legend_title, ncol = legend_ncol,
                                    reverse = FALSE)
    ) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")
  if (exponentiate) p <- p + ggplot2::scale_x_log10()

  if (scales == "free") {
    # One free-scaled panel per term keeps the source overlay and its single
    # legend, but lets each term occupy its own x-range.
    p <- add_term_facets(p, reference_line = reference_line,
                         reference_colour = depictr_reference())
  }

  p
}
