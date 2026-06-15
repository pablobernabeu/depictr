# Precision-recall curve -----------------------------------------------------

#' Precision-recall curve
#'
#' Plots precision against recall for a binary classifier and reports the
#' average precision (the area under the curve). The precision-recall curve is
#' more informative than the ROC curve when the positive class is rare, because
#' it ignores the many true negatives. A horizontal line marks the no-skill
#' baseline (the positive-class prevalence). Pass a *named list* of models /
#' (actual, score) pairs to overlay several colour-coded curves with a legend
#' and per-curve average precision.
#'
#' @param x A binomial `glm`; the vector of observed outcomes (0/1, logical or a
#'   two-level factor with the positive class second); or a *named* list of
#'   models / (actual, score) pairs to overlay.
#' @param score When `x` is an outcome vector, the matching scores or predicted
#'   probabilities (or a list of them for the multi-model case).
#' @param colour Curve colour for the single-model case. Defaults to the depictr
#'   brand blue. Ignored when several models are overlaid.
#' @param f1 Logical; if `TRUE`, mark the maximum-F1 operating point on each
#'   curve (the threshold maximising the harmonic mean of precision and recall).
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The average precision is stored in
#'   `attr(plot, "average_precision")` (a named vector when several models are
#'   supplied).
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' pr_curve_plot(gfit)
#'
#' # Mark the maximum-F1 operating point.
#' pr_curve_plot(gfit, f1 = TRUE)
#'
#' # Compare two models with per-curve average precision in the legend.
#' reduced <- glm(accuracy ~ word_frequency, data = lexical_decision,
#'                family = binomial)
#' pr_curve_plot(list(Full = gfit, Reduced = reduced))
pr_curve_plot <- function(x, score = NULL, colour = depictr_brand(),
                          f1 = FALSE, title = NULL) {
  models <- as_model_list(x, score)
  multi <- attr(models, "multi")

  prs <- lapply(models, function(m) pr_points(m$actual, m$score))
  aps <- vapply(prs, function(pr) sum(diff(c(0, pr$recall)) * pr$precision),
                numeric(1))
  # Baseline = positive prevalence; with several models show each model's own.
  prevs <- vapply(models, function(m) mean(m$actual == 1), numeric(1))

  curve_df <- do.call(rbind, Map(function(pr, nm) { pr$model <- nm; pr },
                                 prs, names(models)))
  curve_df$model <- factor(curve_df$model, levels = names(models))

  p <- ggplot2::ggplot()

  if (multi) {
    base_df <- data.frame(model = factor(names(models), levels = names(models)),
                          prevalence = prevs)
    p <- p +
      ggplot2::geom_hline(data = base_df,
                          ggplot2::aes(yintercept = .data$prevalence,
                                       colour = .data$model),
                          linetype = 2, linewidth = 0.4, alpha = 0.5,
                          show.legend = FALSE) +
      ggplot2::geom_line(data = curve_df,
                         ggplot2::aes(x = .data$recall, y = .data$precision,
                                      colour = .data$model), linewidth = 0.9) +
      scale_colour_depictr(
        name = NULL,
        labels = paste0(names(models), " (AP ",
                        formatC(aps, format = "f", digits = 3), ")")
      )
  } else {
    p <- p +
      ggplot2::geom_hline(yintercept = prevs[[1]], linetype = 2,
                          colour = depictr_reference()) +
      ggplot2::geom_line(data = curve_df,
                         ggplot2::aes(x = .data$recall, y = .data$precision),
                         colour = colour, linewidth = 0.9) +
      ggplot2::annotate("text", x = 0.02, y = 0.04, hjust = 0,
                        label = paste0("AP = ", formatC(aps[[1]], format = "f",
                                                        digits = 3)),
                        colour = depictr_brand(), fontface = "bold")
  }

  if (isTRUE(f1)) {
    fps <- lapply(models, function(m) max_f1_point(m$actual, m$score))
    fp_df <- do.call(rbind, Map(function(fp, nm) {
      data.frame(recall = fp$recall, precision = fp$precision, model = nm)
    }, fps, names(models)))
    fp_df$model <- factor(fp_df$model, levels = names(models))
    if (multi) {
      p <- p + ggplot2::geom_point(
        data = fp_df,
        ggplot2::aes(x = .data$recall, y = .data$precision, colour = .data$model),
        size = 2.6, shape = 21, fill = "white", stroke = 1.1,
        show.legend = FALSE
      )
    } else {
      p <- p +
        ggplot2::geom_point(data = fp_df,
                            ggplot2::aes(x = .data$recall, y = .data$precision),
                            colour = depictr_accent(), size = 2.6) +
        ggplot2::annotate(
          "text", x = fp_df$recall[1], y = fp_df$precision[1] + 0.05,
          hjust = 0.5, vjust = 0, colour = depictr_accent(), fontface = "bold",
          size = 3.2,
          label = paste0("max F1 = ",
                         formatC(fps[[1]]$f1, format = "f", digits = 2),
                         "\n(thr ",
                         formatC(fps[[1]]$threshold, format = "f", digits = 2),
                         ")")
        )
    }
  }

  p <- p +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Recall", y = "Precision", title = title) +
    theme_depictr()

  attr(p, "average_precision") <- if (multi)
    stats::setNames(aps, names(models)) else aps[[1]]
  if (isTRUE(f1)) attr(p, "max_f1") <- if (multi) fps else fps[[1]]
  p
}

# ---- internal helper -------------------------------------------------------

#' @noRd
pr_points <- function(actual, score) {
  P <- sum(actual == 1)
  if (P == 0 || P == length(actual)) {
    stop("Precision-recall needs both positive and negative outcomes.",
         call. = FALSE)
  }
  # Collapse tied scores into a single threshold step so the curve and the
  # average precision do not depend on the input row order.
  cc <- threshold_counts(actual, score)
  data.frame(recall = cc$tp / P, precision = cc$tp / (cc$tp + cc$fp))
}
