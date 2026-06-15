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
#' @param conf_level Confidence/credible level for models.
#' @param intercept Whether to keep the intercept term. Defaults to `FALSE`.
#' @param order Order terms by their average estimate across sources:
#'   `"none"`, `"ascending"` or `"descending"`.
#' @param labels Optional display labels (see [coefficient_plot()]).
#' @param interaction Passed to [format_terms()].
#' @param dodge_width Vertical spacing between sources sharing a term.
#' @param reference_line Position of a vertical reference line (`NA` to omit).
#' @param palette Colours for the sources; defaults to [depictr_palette()].
#' @param point_size,line_size Point and interval-line sizes.
#' @param legend_title,legend_ncol Legend title and number of columns.
#' @param title,subtitle,x_lab Title, subtitle and x-axis label.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' m1 <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
#' m2 <- lm(yield ~ rainfall + fertilizer + soil_ph,
#'          data = crop_yield[crop_yield$treatment == "standard", ])
#' compare_models(`All fields` = m1, `Standard only` = m2,
#'                        title = "Estimates by subset")
compare_models <- function(...,
                                    names = NULL,
                                    conf_level = 0.95,
                                    intercept = FALSE,
                                    order = c("none", "ascending", "descending"),
                                    labels = NULL,
                                    interaction = c("times", "asterisk",
                                                    "colon", "space"),
                                    dodge_width = 0.6,
                                    reference_line = 0,
                                    palette = NULL,
                                    point_size = 2.2,
                                    line_size = 0.7,
                                    legend_title = "Source",
                                    legend_ncol = 1,
                                    title = NULL,
                                    subtitle = NULL,
                                    x_lab = "Estimate") {
  order <- match.arg(order)
  interaction <- match.arg(interaction)

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
    e <- tidy_estimates(s, conf_level = conf_level)
    e$source <- nm
    e
  }, sources, src_names)
  est <- do.call(rbind, tidied)
  rownames(est) <- NULL

  if (!intercept) {
    est <- est[!est$term %in% c("(Intercept)", "Intercept", "b_Intercept"), ,
                drop = FALSE]
  }
  if (nrow(est) == 0) {
    stop("No terms left to plot.", call. = FALSE)
  }

  # Align rows from different sources by a CANONICAL display label rather than
  # the raw term name, so concepts that tidy to the same label (e.g. "stress"
  # and the brms-style "b_stress") share a single row instead of producing
  # duplicated factor levels. All ordering and grid-completion below therefore
  # works on `label`, not `term`.
  est$label <- make_labels(est$term, labels, interaction)

  label_levels <- unique(est$label)
  if (order != "none") {
    avg <- tapply(est$estimate, est$label, mean, na.rm = TRUE)
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

  if (!is.na(reference_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line, linetype = 2, colour = "grey60"
    )
  }

  p +
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      height = 0.18, linewidth = line_size, position = dodge, na.rm = TRUE
    ) +
    ggplot2::geom_point(size = point_size, position = dodge, na.rm = TRUE) +
    ggplot2::scale_colour_manual(
      values = pal,
      guide = ggplot2::guide_legend(title = legend_title, ncol = legend_ncol,
                                    reverse = FALSE)
    ) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")
}
