# Estimation / effect-size plots ---------------------------------------------

#' Gardner-Altman / Cumming estimation plot
#'
#' An estimation plot puts the *effect size* and its uncertainty at the centre
#' of the comparison, rather than a p-value. The upper panel shows each group's
#' raw data (jittered) with its mean and confidence interval; the lower panel
#' shows the pairwise mean difference(s) against a reference group, each with
#' a bootstrap confidence interval. The two panels share an aligned outcome axis
#' and are stacked with 'patchwork', so a difference of zero in the lower panel
#' lines up with the reference group's mean above it.
#'
#' With exactly two groups this is the classic *Gardner-Altman* two-group plot
#' (Gardner & Altman, 1986; Ho et al., 2019): a single mean difference is shown
#' with its bootstrap interval, annotated with a standardised effect size
#' (Cohen's *d* or, by default, the small-sample corrected Hedges' *g*; Hedges,
#' 1981). With more than two groups it becomes a *Cumming* estimation plot
#' (Cumming, 2012): every other group is compared with the reference group, each
#' difference carrying its own bootstrap interval.
#'
#' The lower-panel interval is a non-parametric *bootstrap* of the mean
#' difference: the two groups are resampled with replacement `n_boot` times and
#' the requested percentile interval is read off the resampled differences. This
#' makes no normality assumption about the sampling distribution of the
#' difference. The bootstrap uses base R only; set a seed beforehand for
#' reproducibility.
#'
#' A group with fewer than two observations has no estimable spread, so its
#' confidence interval is omitted (the mean is still drawn) and a difference
#' involving it is shown as a point without a bootstrap interval; a warning is
#' issued in both cases.
#'
#' @param data A data frame.
#' @param y The numeric outcome (string or unquoted name).
#' @param group The grouping variable (string or unquoted name).
#' @param reference The reference (control) group that the others are compared
#'   with; defaults to the first level of `group`. The reference is drawn first
#'   in the upper panel and sits at a difference of zero in the lower panel.
#' @param conf_level Confidence level for both the group intervals (t-based) and
#'   the bootstrap difference intervals.
#' @param n_boot Number of bootstrap resamples for the difference intervals.
#' @param effsize Standardised effect size annotated beside each difference:
#'   `"hedges_g"` (the default, small-sample corrected), `"cohens_d"`, or
#'   `"none"` to omit it. Every contrast against the reference is labelled, so
#'   the standardised effect is shown for both the two-group and multi-group
#'   cases.
#' @param show_points Whether to draw the raw data behind the group means.
#' @param point_alpha Transparency of the raw points.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title,y_lab Title and outcome-axis label.
#' @param heights Relative heights of the upper (raw data) and lower
#'   (difference) panels, passed to [patchwork::plot_layout()].
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]). The
#'   computed differences and their bootstrap intervals are attached as the
#'   `"differences"` attribute (a data frame).
#' @references
#' Cumming, G. (2012). *Understanding the new statistics: Effect sizes,
#' confidence intervals, and meta-analysis*. Routledge.
#'
#' Gardner, M. J., & Altman, D. G. (1986). Confidence intervals rather than P
#' values: Estimation rather than hypothesis testing. *BMJ*, 292(6522), 746-750.
#' \doi{10.1136/bmj.292.6522.746}
#'
#' Hedges, L. V. (1981). Distribution theory for Glass's estimator of effect
#' size and related estimators. *Journal of Educational Statistics*, 6(2),
#' 107-128. \doi{10.3102/10769986006002107}
#'
#' Ho, J., Tumkaya, T., Aryal, S., Choi, H., & Claridge-Chang, A. (2019). Moving
#' beyond P values: Data analysis with estimation graphics. *Nature Methods*,
#' 16(7), 565-566. \doi{10.1038/s41592-019-0470-3}
#' @export
#' @examples
#' set.seed(1)
#' # n_boot is kept small here for speed; use the default for real work.
#' estimation_plot(lexical_decision, RT, condition, n_boot = 1000)
#' \donttest{
#' estimation_plot(crop_yield, yield, treatment)
#' # More than two groups: differences vs a chosen reference
#' estimation_plot(wellbeing_survey, life_satisfaction, region,
#'                 reference = "North")
#' }
estimation_plot <- function(data, y, group, reference = NULL,
                            conf_level = 0.95, n_boot = 5000,
                            effsize = c("hedges_g", "cohens_d", "none"),
                            show_points = TRUE, point_alpha = 0.25,
                            palette = NULL, title = NULL, y_lab = NULL,
                            heights = c(2, 1.4)) {
  y <- resolve_var(data, rlang::enquo(y), "y")
  group <- resolve_var(data, rlang::enquo(group), "group")
  effsize <- match.arg(effsize)
  if (!is.numeric(data[[y]])) stop("`y` must be numeric.", call. = FALSE)
  if (!is.numeric(n_boot) || length(n_boot) != 1 || n_boot < 1) {
    stop("`n_boot` must be a single positive number.", call. = FALSE)
  }
  y_lab <- y_lab %||% y

  d <- data[!is.na(data[[y]]) & !is.na(data[[group]]), , drop = FALSE]
  d[[group]] <- as.factor(d[[group]])
  groups <- levels(droplevels(d[[group]]))
  if (length(groups) < 2) {
    stop("`group` must have at least two non-empty levels.", call. = FALSE)
  }

  # Order the levels so the reference comes first (its mean aligns with the
  # zero-difference line below).
  ref <- reference %||% groups[1]
  if (!ref %in% groups) {
    stop("`reference` (\"", ref, "\") is not a level of `group`.",
         call. = FALSE)
  }
  groups <- c(ref, setdiff(groups, ref))
  d[[group]] <- factor(d[[group]], levels = groups)

  vals <- stats::setNames(lapply(groups, function(g) d[[y]][d[[group]] == g]),
                          groups)

  # ---- group means and t-based intervals (upper panel) ---------------------
  # Each element carries its summary row and, for a sparse group, its name --
  # read back below rather than accumulated with `<<-`.
  summ_res <- lapply(groups, function(g) {
    v <- vals[[g]]
    nv <- length(v)
    m <- mean(v)
    if (nv < 2) {
      return(list(row = data.frame(group = g, mean = m, lower = m, upper = m,
                                   stringsAsFactors = FALSE),
                 sparse = g))
    }
    se <- stats::sd(v) / sqrt(nv)
    tc <- stats::qt(1 - (1 - conf_level) / 2, df = nv - 1)
    list(row = data.frame(group = g, mean = m, lower = m - tc * se,
                          upper = m + tc * se, stringsAsFactors = FALSE),
        sparse = NULL)
  })
  summ <- do.call(rbind, lapply(summ_res, `[[`, "row"))
  sparse <- unlist(lapply(summ_res, `[[`, "sparse"))
  if (length(sparse)) {
    warning("No confidence interval drawn for group(s) with n < 2: ",
            paste(sparse, collapse = ", "), "; showing the mean only.",
            call. = FALSE)
  }
  summ$group <- factor(summ$group, levels = groups)
  ref_mean <- summ$mean[summ$group == ref]

  # ---- pairwise differences vs reference with bootstrap CIs (lower panel) --
  others <- setdiff(groups, ref)
  ref_vals <- vals[[ref]]
  # Each element carries its difference row and, when the bootstrap interval
  # is NA, the group name -- read back below rather than accumulated with
  # `<<-`.
  diffs_res <- lapply(others, function(g) {
    gv <- vals[[g]]
    md <- mean(gv) - mean(ref_vals)
    ci <- boot_diff_ci(gv, ref_vals, conf_level, n_boot)
    es <- effsize_diff(gv, ref_vals)
    list(row = data.frame(group = g, reference = ref, diff = md,
                          lower = ci[1], upper = ci[2],
                          cohens_d = es[["cohens_d"]], hedges_g = es[["hedges_g"]],
                          stringsAsFactors = FALSE),
        sparse = if (is.na(ci[1])) g else NULL)
  })
  diffs <- do.call(rbind, lapply(diffs_res, `[[`, "row"))
  boot_sparse <- unlist(lapply(diffs_res, `[[`, "sparse"))
  if (length(boot_sparse)) {
    warning("No bootstrap interval for difference(s) involving group(s) ",
            "with n < 2: ", paste(boot_sparse, collapse = ", "),
            "; showing the difference only.", call. = FALSE)
  }
  diffs$group <- factor(diffs$group, levels = others)

  # Colours: keep each group's hue consistent across the two panels.
  cols <- group_colours(groups, palette)

  # ---- upper panel: raw data + means with CIs ------------------------------
  top <- ggplot2::ggplot(summ, ggplot2::aes(x = .data$group,
                                            colour = .data$group))
  if (show_points) {
    top <- top + ggplot2::geom_jitter(
      data = d,
      ggplot2::aes(x = .data[[group]], y = .data[[y]], colour = .data[[group]]),
      width = 0.12, alpha = point_alpha, size = 0.9, inherit.aes = FALSE
    )
  }
  top <- top +
    ggplot2::geom_hline(yintercept = ref_mean, linetype = 2,
                        colour = depictr_reference(), linewidth = 0.4) +
    ggplot2::geom_pointrange(
      ggplot2::aes(y = .data$mean, ymin = .data$lower, ymax = .data$upper),
      linewidth = 0.8, size = 0.6
    ) +
    ggplot2::scale_colour_manual(values = cols) +
    ggplot2::labs(x = NULL, y = y_lab, title = title) +
    theme_depictr(grid = "y") +
    ggplot2::theme(legend.position = "none",
                   axis.text.x = ggplot2::element_text(face = "bold"))

  # ---- lower panel: differences vs reference -------------------------------
  diff_cols <- cols[as.character(diffs$group)]
  bottom <- ggplot2::ggplot(diffs, ggplot2::aes(x = .data$group,
                                                colour = .data$group)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2,
                        colour = depictr_reference(), linewidth = 0.4) +
    ggplot2::geom_pointrange(
      ggplot2::aes(y = .data$diff, ymin = .data$lower, ymax = .data$upper),
      linewidth = 0.8, size = 0.6, na.rm = TRUE
    ) +
    ggplot2::scale_colour_manual(values = diff_cols) +
    ggplot2::labs(
      x = NULL,
      y = sprintf("Mean difference\n(vs. %s)", ref),
      caption = sprintf("Bootstrap %g%% CI (%s resamples)",
                        100 * conf_level, format(n_boot, big.mark = ","))
    ) +
    theme_depictr(grid = "y") +
    ggplot2::theme(legend.position = "none")

  # Match the lower-panel x ordering and labels to the upper panel: pad with
  # an (invisible) slot for the reference so the columns line up.
  bottom <- bottom +
    ggplot2::scale_x_discrete(limits = others, drop = FALSE) +
    ggplot2::expand_limits(x = groups)

  # Surface the standardised effect size for EVERY contrast, not only the
  # two-group case. Showing Hedges' g / Cohen's d beside each bootstrap interval
  # is what makes this an estimation plot rather than a plain mean-difference
  # plot, and keeps it distinct from group_comparison_plot().
  if (effsize != "none") {
    es_prefix <- switch(effsize, hedges_g = "Hedges' ", cohens_d = "Cohen's ")
    es_letter <- switch(effsize, hedges_g = "g", cohens_d = "d")
    # Build the label data on a copy so the public "differences" attribute keeps
    # its documented columns (no extra helper columns leak out).
    lab_df <- diffs[is.finite(diffs[[effsize]]), , drop = FALSE]
    if (nrow(lab_df)) {
      # plotmath label (parse = TRUE) so the effect-size letter is italic.
      lab_df$es_label <- sprintf('"%s"*italic(%s)*" = %s"', es_prefix,
                                 es_letter,
                                 formatC(lab_df[[effsize]], format = "f",
                                         digits = 2))
      lab_df$lab_y <- ifelse(is.finite(lab_df$upper), lab_df$upper, lab_df$diff)
      bottom <- bottom +
        ggplot2::geom_text(
          data = lab_df,
          ggplot2::aes(x = .data$group, y = .data$lab_y,
                       label = .data$es_label),
          parse = TRUE,
          inherit.aes = FALSE, vjust = -0.9, colour = "grey25", size = 3
        ) +
        # The label is drawn above the interval cap, so reserve enough headroom
        # at the top that it is never clipped by the (often short) lower panel.
        ggplot2::scale_y_continuous(
          expand = ggplot2::expansion(mult = c(0.08, 0.32))
        )
    }
  }

  combined <- top / bottom +
    patchwork::plot_layout(heights = heights)
  attr(combined, "differences") <- diffs
  combined
}

# ---- internal helpers ------------------------------------------------------

#' Bootstrap percentile CI for the difference in means (treat - ref)
#'
#' Resamples each group with replacement `n_boot` times and returns the
#' `conf_level` percentile interval of the resampled mean differences. Returns
#' `c(NA, NA)` when either group has fewer than two observations (no spread to
#' resample meaningfully).
#' @noRd
boot_diff_ci <- function(treat, ref, conf_level = 0.95, n_boot = 5000) {
  if (length(treat) < 2 || length(ref) < 2) return(c(NA_real_, NA_real_))
  nt <- length(treat)
  nr <- length(ref)
  reps <- vapply(seq_len(n_boot), function(i) {
    mean(treat[sample.int(nt, nt, replace = TRUE)]) -
      mean(ref[sample.int(nr, nr, replace = TRUE)])
  }, numeric(1))
  alpha <- 1 - conf_level
  unname(stats::quantile(reps, c(alpha / 2, 1 - alpha / 2), names = FALSE,
                         type = 7))
}

#' Cohen's d and Hedges' g for the difference (treat - ref)
#'
#' Uses the pooled standard deviation (the classic two-sample Cohen's d). Hedges'
#' g multiplies d by the small-sample correction factor
#' \eqn{J = 1 - 3 / (4 (n_1 + n_2) - 9)}. Returns `NA` for either when the
#' pooled SD is undefined (fewer than two observations in either group, or zero
#' pooled variance).
#' @noRd
effsize_diff <- function(treat, ref) {
  n1 <- length(treat)
  n2 <- length(ref)
  if (n1 < 2 || n2 < 2) {
    return(c(cohens_d = NA_real_, hedges_g = NA_real_))
  }
  s1 <- stats::var(treat)
  s2 <- stats::var(ref)
  sp <- sqrt(((n1 - 1) * s1 + (n2 - 1) * s2) / (n1 + n2 - 2))
  if (!is.finite(sp) || sp == 0) {
    return(c(cohens_d = NA_real_, hedges_g = NA_real_))
  }
  d <- (mean(treat) - mean(ref)) / sp
  j <- 1 - 3 / (4 * (n1 + n2) - 9)
  c(cohens_d = d, hedges_g = j * d)
}

#' Named colour vector for groups, from a palette or [depictr_palette()]
#' @noRd
group_colours <- function(groups, palette = NULL) {
  if (is.null(palette)) {
    cols <- depictr_palette(length(groups))
  } else {
    cols <- rep_len(palette, length(groups))
  }
  stats::setNames(cols, groups)
}
