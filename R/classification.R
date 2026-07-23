# Classification plots: ROC, calibration, confusion matrix -------------------

#' ROC curve
#'
#' Plots the receiver operating characteristic (ROC) curve for a binary
#' classifier and reports the area under the curve (AUC). The input can be a
#' fitted binomial `glm`, a pair of vectors (observed binary outcome and a
#' continuous score), or, to compare several models, a *named list* of
#' models or of (actual, score) pairs, which are overlaid as colour-coded curves
#' with a legend and a per-curve AUC. An optional bootstrap confidence band can
#' be drawn for the (single-model) curve and its AUC, and the Youden's J
#' operating point can be marked.
#'
#' @param x A binomial `glm`; the vector of observed outcomes (0/1, logical or a
#'   two-level factor with the positive class second); or a *named* list of
#'   models / (actual, score) pairs to overlay (see Details).
#' @param score When `x` is an outcome vector, the matching vector of scores or
#'   predicted probabilities. When `x` is a named list of outcome vectors, a
#'   matching named/positional list of score vectors.
#' @param colour Curve colour for the single-model case. Defaults to the depictr
#'   brand blue. Ignored when several models are overlaid (the colourblind-aware
#'   [scale_colour_depictr()] palette is used instead).
#' @param ci Bootstrap confidence band for a single ROC curve and its AUC.
#'   `FALSE` (default) draws none; `TRUE` uses 2000 resamples; a positive integer
#'   sets the number of resamples. Ignored when several models are overlaid.
#' @param conf_level Confidence level for the bootstrap band.
#' @param youden Logical; if `TRUE`, mark the Youden's J operating point (the
#'   threshold maximising sensitivity + specificity - 1) on each curve.
#' @param legend_inside When `TRUE` (and several models are overlaid), draw the
#'   legend inside the panel (in the bottom-right corner the curve leaves empty)
#'   over a translucent background, instead of in a right-hand margin.
#'   Defaults to `FALSE`.
#' @param title Plot title.
#'
#' @details
#' A named list overlays one curve per element, e.g.
#' `roc_curve_plot(list("Full" = fit_full, "Reduced" = fit_reduced))`. Each
#' element may be a `glm`, a length-2 list/data frame of `(actual, score)`, or an
#' outcome vector paired with the matching element of a `score` list. Single-model
#' calls are unchanged.
#'
#' @return A [ggplot2::ggplot] object. The AUC(s) are stored in
#'   `attr(plot, "auc")` (a named vector when several models are supplied).
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + condition + RT,
#'             data = lexical_decision, family = binomial)
#' roc_curve_plot(gfit)
#'
#' # Mark the Youden operating point and add a bootstrap band.
#' roc_curve_plot(gfit, youden = TRUE, ci = 200)
#'
#' # Compare two models with a colour-coded legend and per-curve AUC.
#' reduced <- glm(accuracy ~ word_frequency, data = lexical_decision,
#'                family = binomial)
#' roc_curve_plot(list(Full = gfit, Reduced = reduced))
roc_curve_plot <- function(x, score = NULL, colour = depictr_brand(),
                           ci = FALSE, conf_level = 0.95, youden = FALSE,
                           legend_inside = FALSE, title = NULL) {
  models <- as_model_list(x, score)
  multi <- attr(models, "multi")

  # Per-model ROC points and AUC.
  rocs <- lapply(models, function(m) roc_points(m$actual, m$score))
  aucs <- vapply(rocs, roc_auc, numeric(1))

  curve_df <- do.call(rbind, Map(function(r, nm) {
    r$model <- nm; r
  }, rocs, names(models)))
  curve_df$model <- factor(curve_df$model, levels = names(models))

  p <- ggplot2::ggplot() +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = depictr_reference())

  # Optional bootstrap band (single model only).
  do_ci <- !isFALSE(ci) && !multi
  if (do_ci) {
    n_boot <- if (isTRUE(ci)) 2000L else as.integer(ci)
    if (!is.finite(n_boot) || n_boot < 1) {
      stop("`ci` must be TRUE or a positive number of bootstrap resamples.",
           call. = FALSE)
    }
    band <- roc_boot_ci(models[[1]]$actual, models[[1]]$score,
                        n_boot = n_boot, conf_level = conf_level)
    band_df <- data.frame(fpr = band$fpr, lower = band$lower, upper = band$upper)
    p <- p + ggplot2::geom_ribbon(
      data = band_df,
      ggplot2::aes(x = .data$fpr, ymin = .data$lower, ymax = .data$upper),
      fill = colour, alpha = 0.18
    )
  }

  if (multi) {
    p <- p +
      ggplot2::geom_line(
        data = curve_df,
        ggplot2::aes(x = .data$fpr, y = .data$tpr, colour = .data$model),
        linewidth = 0.9
      ) +
      scale_colour_depictr(
        name = NULL,
        labels = paste0(names(models), " (AUC ",
                        formatC(aucs, format = "f", digits = 3), ")")
      )
  } else {
    p <- p +
      ggplot2::geom_line(data = curve_df,
                         ggplot2::aes(x = .data$fpr, y = .data$tpr),
                         colour = colour, linewidth = 0.9) +
      ggplot2::annotate(
        "text", x = 0.98, y = 0.04, hjust = 1,
        label = paste0("AUC = ", formatC(aucs[[1]], format = "f", digits = 3),
                       if (do_ci) paste0(
                         " [", formatC(band$auc_low, format = "f", digits = 3),
                         ", ", formatC(band$auc_high, format = "f", digits = 3),
                         "]") else ""),
        colour = depictr_brand(), fontface = "bold"
      )
  }

  # Youden operating point(s).
  if (isTRUE(youden)) {
    yps <- lapply(models, function(m) youden_point(m$actual, m$score))
    yp_df <- do.call(rbind, Map(function(yp, nm) {
      data.frame(fpr = yp$fpr, tpr = yp$tpr, model = nm)
    }, yps, names(models)))
    yp_df$model <- factor(yp_df$model, levels = names(models))
    if (multi) {
      p <- p + ggplot2::geom_point(
        data = yp_df,
        ggplot2::aes(x = .data$fpr, y = .data$tpr, colour = .data$model),
        size = 2.6, shape = 21, fill = "white", stroke = 1.1,
        show.legend = FALSE
      )
    } else {
      p <- p +
        ggplot2::geom_point(data = yp_df,
                            ggplot2::aes(x = .data$fpr, y = .data$tpr),
                            colour = depictr_accent(), size = 2.6) +
        ggplot2::annotate(
          "text", x = yp_df$fpr[1] + 0.03, y = yp_df$tpr[1] - 0.03, hjust = 0,
          vjust = 1, colour = depictr_accent(), fontface = "bold", size = 3.2,
          label = paste0("Youden J\n(thr ",
                         formatC(yps[[1]]$threshold, format = "f", digits = 2),
                         ")")
        )
    }
  }

  p <- p +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "False positive rate", y = "True positive rate",
                  title = title) +
    theme_depictr()
  # The curve hugs the top-left, so the bottom-right corner is always free: when
  # asked, tuck the multi-model legend there instead of using a right-hand margin.
  if (legend_inside && multi) p <- p + legend_inside_theme(c(0.98, 0.02), c(1, 0))

  attr(p, "auc") <- if (multi) stats::setNames(aucs, names(models)) else aucs[[1]]
  if (isTRUE(youden)) {
    attr(p, "youden") <- if (multi) yps else yps[[1]]
  }
  if (do_ci) attr(p, "auc_ci") <- c(lower = unname(band$auc_low),
                                    upper = unname(band$auc_high))
  p
}

#' Calibration plot
#'
#' Assesses how well predicted probabilities match observed frequencies. The
#' scores are split into bins; for each bin the mean predicted probability is
#' plotted against the observed event rate, with the diagonal marking perfect
#' calibration. A Wilson binomial confidence interval is drawn on each bin's
#' observed proportion so that bins backed by few observations are not
#' over-interpreted. Pass a *named list* of models / (actual, score) pairs to
#' overlay several colour-coded calibration curves with a legend.
#'
#' @param x A binomial `glm`, the vector of observed outcomes, or a *named* list
#'   of models / (actual, score) pairs to overlay.
#' @param score When `x` is an outcome vector, the matching predicted
#'   probabilities (or a list of them for the multi-model case).
#' @param bins Number of (equal-count) bins.
#' @param colour Point/line colour for the single-model case. Defaults to the
#'   depictr brand blue. Ignored when several models are overlaid.
#' @param conf_level Confidence level for the per-bin Wilson interval on the
#'   observed proportion. Use `NA` to omit the intervals. Intervals are only
#'   drawn in the single-model case to keep the overlay legible.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Calibration is judged against the base rate, so the example uses the rare
#' # clinical-trial adverse event (about 10% positive).
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' calibration_plot(gfit, bins = 6)
calibration_plot <- function(x, score = NULL, bins = 10,
                             colour = depictr_brand(), conf_level = 0.95,
                             title = NULL) {
  models <- as_model_list(x, score)
  multi <- attr(models, "multi")

  agg_one <- function(io) calibration_bins(io$actual, io$score, bins)
  aggs <- lapply(models, agg_one)

  if (multi) {
    agg <- do.call(rbind, Map(function(a, nm) { a$model <- nm; a },
                              aggs, names(models)))
    agg$model <- factor(agg$model, levels = names(models))
    return(
      ggplot2::ggplot(agg, ggplot2::aes(x = .data$predicted, y = .data$observed,
                                        colour = .data$model)) +
        ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                             colour = depictr_reference()) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::geom_point(ggplot2::aes(size = .data$n), alpha = 0.7) +
        scale_colour_depictr(name = NULL) +
        ggplot2::scale_size_area(name = "n", max_size = 7) +
        ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
        ggplot2::labs(x = "Mean predicted probability",
                      y = "Observed frequency", title = title) +
        theme_depictr()
    )
  }

  agg <- aggs[[1]]
  draw_ci <- !is.na(conf_level)
  if (draw_ci) {
    ci <- wilson_interval(agg$successes, agg$n, conf_level)
    agg$conf.low <- ci$lower
    agg$conf.high <- ci$upper
  }

  p <- ggplot2::ggplot(agg,
                       ggplot2::aes(x = .data$predicted, y = .data$observed)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = depictr_reference())
  if (draw_ci) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
      width = 0.02, linewidth = 0.5, colour = colour, alpha = 0.7
    )
  }
  p +
    ggplot2::geom_line(colour = colour, linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(size = .data$n), colour = colour,
                        alpha = 0.7) +
    ggplot2::scale_size_area(name = "n", max_size = 7) +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Mean predicted probability",
                  y = "Observed frequency", title = title) +
    theme_depictr()
}

#' Per-bin calibration aggregation (equal-count quantile bins)
#' @noRd
calibration_bins <- function(actual, score, bins) {
  probs <- pmin(pmax(score, 0), 1)
  brks <- stats::quantile(probs, probs = seq(0, 1, length.out = bins + 1),
                          na.rm = TRUE)
  brks <- unique(brks)
  if (length(brks) < 3) stop("Too few distinct scores to form bins.",
                             call. = FALSE)
  bin <- cut(probs, breaks = brks, include.lowest = TRUE)
  agg <- data.frame(
    predicted = tapply(probs, bin, mean),
    observed = tapply(actual, bin, mean),
    successes = tapply(actual, bin, sum),
    n = tapply(actual, bin, length)
  )
  agg[stats::complete.cases(agg), , drop = FALSE]
}

#' Confusion matrix heatmap
#'
#' Cross-tabulates predicted against actual classes and displays the counts as a
#' heatmap. The input can be a fitted binomial `glm` (with a probability
#' threshold) or a pair of vectors of actual and predicted classes.
#'
#' @param x A binomial `glm`, or the vector of actual classes.
#' @param predicted When `x` is an actual-class vector, the matching predicted
#'   classes.
#' @param threshold When `x` is a `glm`, the probability threshold for the
#'   positive class. As well as a number in `[0, 1]`, you may pass the string
#'   `"youden"` to reuse the Youden's J optimal threshold (the same operating
#'   point [roc_curve_plot()] marks), so the confusion matrix and the ROC curve
#'   agree on the cut-off.
#' @param normalise One of `"none"`, `"row"` (by actual class) or `"col"` (by
#'   predicted class); controls the fill shading and the cell annotation.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The threshold actually used is stored in
#'   `attr(plot, "threshold")`.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' confusion_matrix_plot(gfit, threshold = 0.5)
#'
#' # Reuse the Youden-optimal operating point.
#' confusion_matrix_plot(gfit, threshold = "youden")
confusion_matrix_plot <- function(x, predicted = NULL, threshold = 0.5,
                                  normalise = c("none", "row", "col"),
                                  title = NULL) {
  normalise <- match.arg(normalise)
  used_threshold <- NA_real_
  if (inherits(x, "glm")) {
    resp <- stats::model.response(stats::model.frame(x))
    actual_bin <- as_binary(resp)
    fit <- as.numeric(stats::fitted(x))
    if (is.character(threshold)) {
      threshold <- match.arg(threshold, "youden")
      io <- drop_incomplete(actual_bin, fit)
      threshold <- youden_point(io$actual, io$score)$threshold
    }
    if (!is.numeric(threshold) || length(threshold) != 1L) {
      stop("`threshold` must be a single number in [0, 1] or \"youden\".",
           call. = FALSE)
    }
    used_threshold <- threshold
    pred_bin <- as.integer(fit >= threshold)
    # Recover the model's own class names so the matrix is labelled with the
    # real outcome levels (e.g. "no"/"yes") rather than a hardcoded 0/1.
    if (is.factor(resp)) {
      lvls <- levels(resp)
    } else if (is.logical(resp)) {
      lvls <- c("FALSE", "TRUE")
    } else {
      lvls <- c("0", "1")
    }
    actual <- factor(lvls[actual_bin + 1L], levels = lvls)
    pred <- factor(lvls[pred_bin + 1L], levels = lvls)
  } else {
    if (is.null(predicted)) {
      stop("Supply `predicted` when `x` is not a model.", call. = FALSE)
    }
    lvls <- union(levels(as.factor(x)), levels(as.factor(predicted)))
    actual <- factor(as.character(x), levels = lvls)
    pred <- factor(as.character(predicted), levels = lvls)
  }

  tab <- as.data.frame(table(Actual = actual, Predicted = pred),
                       stringsAsFactors = FALSE)
  tab$Actual <- factor(tab$Actual, levels = rev(lvls))
  tab$Predicted <- factor(tab$Predicted, levels = lvls)

  if (normalise == "row") {
    denom <- stats::ave(tab$Freq, tab$Actual, FUN = sum)
    tab$shade <- ifelse(denom > 0, tab$Freq / denom, 0)
    tab$label <- sprintf("%d\n(%.0f%%)", tab$Freq, 100 * tab$shade)
  } else if (normalise == "col") {
    denom <- stats::ave(tab$Freq, tab$Predicted, FUN = sum)
    tab$shade <- ifelse(denom > 0, tab$Freq / denom, 0)
    tab$label <- sprintf("%d\n(%.0f%%)", tab$Freq, 100 * tab$shade)
  } else {
    tab$shade <- tab$Freq
    tab$label <- as.character(tab$Freq)
  }

  # Source the tile fill from the canonical sequential palette (a single-hue
  # ramp from a pale tint up to the brand-blue dark end). Choose each label's
  # colour from the TILE's own luminance, so counts stay legible on both pale
  # low-count and dark high-count cells. A global shade-vs-median rule fails
  # when one cell dominates the range (it leaves white text on a pale cell).
  fill_ramp <- depictr_palette(type = "sequential")
  rng <- range(tab$shade)
  frac <- if (diff(rng) > 0) (tab$shade - rng[1]) / diff(rng) else rep(0, nrow(tab))
  tile_hex <- grDevices::rgb(grDevices::colorRamp(fill_ramp)(frac),
                             maxColorValue = 255)
  tab$text_col <- ifelse(.relative_luminance(tile_hex) > 0.4, "grey15", "white")
  p <- ggplot2::ggplot(tab, ggplot2::aes(x = .data$Predicted, y = .data$Actual,
                                         fill = .data$shade)) +
    ggplot2::geom_tile(colour = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$label),
                       colour = tab$text_col, size = 3.5) +
    ggplot2::scale_fill_gradientn(colours = fill_ramp, guide = "none") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Predicted", y = "Actual", title = title) +
    theme_depictr(grid = "none")
  attr(p, "threshold") <- used_threshold
  p
}

# ---- internal helpers ------------------------------------------------------

#' Wilson score interval for a binomial proportion
#'
#' Vectorised over `successes`/`n`. The Wilson interval is preferred to the
#' Wald (normal-approximation) interval because it stays inside `[0, 1]` and
#' behaves sensibly for small `n` and proportions near 0 or 1 - exactly the
#' situation in the sparsely populated tail bins of a calibration plot.
#'
#' @param successes Integer count of positives in each bin.
#' @param n Integer bin size.
#' @param conf_level Confidence level (e.g. 0.95).
#' @return A list with numeric vectors `lower` and `upper`.
#' @noRd
wilson_interval <- function(successes, n, conf_level = 0.95) {
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  phat <- successes / n
  denom <- 1 + z^2 / n
  centre <- (phat + z^2 / (2 * n)) / denom
  half <- (z * sqrt(phat * (1 - phat) / n + z^2 / (4 * n^2))) / denom
  list(lower = pmax(0, centre - half), upper = pmin(1, centre + half))
}

#' Coerce an outcome vector to 0/1
#'
#' NA values are preserved (not coerced or rejected); complete-case filtering is
#' handled by the callers so that `actual` and `score` are dropped pairwise.
#'
#' @param y A logical, two-level factor, or 0/1 numeric vector.
#' @param positive For a factor, the level treated as the positive (1) class.
#'   Defaults to the second (last) level, matching the package convention.
#' @noRd
as_binary <- function(y, positive = NULL) {
  if (is.logical(y)) return(as.integer(y))
  if (is.factor(y)) {
    lv <- levels(y)
    if (length(lv) > 2L) {
      stop("The outcome factor has ", length(lv),
           " levels; a binary outcome must have exactly two. Levels: ",
           paste(lv, collapse = ", "), ".", call. = FALSE)
    }
    if (is.null(positive)) {
      positive <- lv[length(lv)]
    } else if (!positive %in% lv) {
      stop("`positive` (\"", positive,
           "\") is not a level of the outcome factor. Levels: ",
           paste(lv, collapse = ", "), ".", call. = FALSE)
    }
    return(as.integer(as.character(y) == positive))
  }
  yn <- suppressWarnings(as.numeric(y))
  ok <- is.na(y) | yn %in% c(0, 1)
  if (!all(ok)) {
    stop("The outcome must be binary (0/1, logical or a two-level factor).",
         call. = FALSE)
  }
  as.integer(yn)
}

#' @noRd
binary_inputs <- function(x, score) {
  if (inherits(x, "glm")) {
    actual <- as_binary(stats::model.response(stats::model.frame(x)))
    sc <- as.numeric(stats::fitted(x))
    return(drop_incomplete(actual, sc))
  }
  if (is.null(score)) {
    stop("Supply `score` when `x` is not a model.", call. = FALSE)
  }
  drop_incomplete(as_binary(x), as.numeric(score))
}

#' Normalise the curve inputs into a named list of (actual, score) pairs
#'
#' This is the single entry point that lets every classification curve accept
#' either a single model/vector (the original, backward-compatible behaviour) or
#' a *named list* of models or (actual, score) pairs to overlay. It always
#' returns a list of `list(actual = , score = )` entries with `names()` set, plus
#' an attribute `"multi"` recording whether more than one model was supplied (so
#' the callers know whether to draw a legend).
#'
#' Recognised shapes for `x`:
#' \itemize{
#'   \item a binomial `glm` (with `score = NULL`);
#'   \item an outcome vector with a matching `score` vector;
#'   \item a *named* list whose elements are each a `glm`, a length-2 list or
#'     data frame of `(actual, score)` (named or positional), or an `actual`
#'     vector - in which case the matching element of a parallel `score` list is
#'     used.
#' }
#' @noRd
as_model_list <- function(x, score = NULL) {
  is_pair_list <- is.list(x) && !is.data.frame(x) && !inherits(x, "glm")

  if (!is_pair_list) {
    out <- list(binary_inputs(x, score))
    names(out) <- "model"
    attr(out, "multi") <- FALSE
    return(out)
  }

  if (length(x) == 0L) {
    stop("The list of models is empty.", call. = FALSE)
  }
  nms <- names(x)
  if (is.null(nms) || any(!nzchar(nms))) {
    stop("When supplying several models, use a *named* list, e.g. ",
         "list(`Model A` = fitA, `Model B` = fitB).", call. = FALSE)
  }
  if (anyDuplicated(nms)) {
    stop("Model names must be unique; duplicated: ",
         paste(unique(nms[duplicated(nms)]), collapse = ", "), ".",
         call. = FALSE)
  }

  out <- Map(function(el, sc) extract_pair(el, sc), x, score %||% vector("list", length(x)))
  names(out) <- nms
  attr(out, "multi") <- length(out) > 1L
  out
}

#' Turn one element of a model list into an (actual, score) pair
#' @noRd
extract_pair <- function(el, sc = NULL) {
  if (inherits(el, "glm")) return(binary_inputs(el, NULL))
  if (is.data.frame(el) || (is.list(el) && length(el) == 2L)) {
    actual <- if (!is.null(el[["actual"]])) el[["actual"]] else el[[1L]]
    s      <- if (!is.null(el[["score"]]))  el[["score"]]  else el[[2L]]
    return(binary_inputs(actual, s))
  }
  # Otherwise `el` is an outcome vector and `sc` the parallel score vector.
  if (is.null(sc)) {
    stop("Each model must be a glm, an (actual, score) pair, or an outcome ",
         "vector with a matching `score` list element.", call. = FALSE)
  }
  binary_inputs(el, sc)
}

#' Youden's J operating point: the threshold maximising sensitivity + specificity
#' - 1, i.e. the ROC point furthest above the chance diagonal (tpr - fpr).
#'
#' Returns the chosen score threshold and the (fpr, tpr) coordinates of that
#' point on the ROC curve, computed on the collapsed distinct-threshold steps so
#' that the result is order- and tie-independent.
#' @noRd
youden_point <- function(actual, score) {
  P <- sum(actual == 1)
  N <- sum(actual == 0)
  cc <- threshold_counts(actual, score)
  tpr <- cc$tp / P
  fpr <- cc$fp / N
  j <- tpr - fpr
  i <- which.max(j)
  thr <- distinct_thresholds(score)[i]
  list(threshold = thr, fpr = fpr[i], tpr = tpr[i], j = j[i],
       sensitivity = tpr[i], specificity = 1 - fpr[i])
}

#' Max-F1 operating point on the precision-recall curve.
#'
#' F1 = 2 * precision * recall / (precision + recall), maximised over the
#' distinct-threshold steps.
#' @noRd
max_f1_point <- function(actual, score) {
  P <- sum(actual == 1)
  cc <- threshold_counts(actual, score)
  recall <- cc$tp / P
  precision <- cc$tp / (cc$tp + cc$fp)
  f1 <- ifelse(precision + recall > 0,
               2 * precision * recall / (precision + recall), 0)
  i <- which.max(f1)
  thr <- distinct_thresholds(score)[i]
  list(threshold = thr, recall = recall[i], precision = precision[i],
       f1 = f1[i])
}

#' The distinct score thresholds, in decreasing order, matching the rows that
#' `threshold_counts()` returns (one per run of tied scores).
#' @noRd
distinct_thresholds <- function(score) {
  s <- sort(unique(score), decreasing = TRUE)
  s
}

#' Bootstrap percentile confidence band for an ROC curve and its AUC.
#'
#' Resamples observations with replacement `n_boot` times; for each resample the
#' ROC is interpolated onto a common fixed FPR grid so the bands can be summarised
#' pointwise. Returns the per-grid-point lower/upper TPR quantiles and the AUC
#' quantiles. Resamples that happen to contain only one class are skipped.
#' @noRd
roc_boot_ci <- function(actual, score, n_boot = 2000, conf_level = 0.95,
                        grid = seq(0, 1, length.out = 101)) {
  n <- length(actual)
  alpha <- 1 - conf_level
  tpr_mat <- matrix(NA_real_, nrow = n_boot, ncol = length(grid))
  aucs <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    idx <- sample.int(n, n, replace = TRUE)
    ab <- actual[idx]
    sb <- score[idx]
    if (sum(ab == 1) == 0 || sum(ab == 0) == 0) {
      aucs[b] <- NA_real_
      next
    }
    rb <- roc_points(ab, sb)
    # Step-interpolate TPR at each grid FPR (ROC is a step/right-continuous
    # function; approx with a monotone rule gives a conservative reading).
    tpr_mat[b, ] <- stats::approx(rb$fpr, rb$tpr, xout = grid, ties = "ordered",
                                  rule = 2)$y
    aucs[b] <- roc_auc(rb)
  }
  qs <- apply(tpr_mat, 2, stats::quantile, probs = c(alpha / 2, 1 - alpha / 2),
              na.rm = TRUE)
  auc_q <- stats::quantile(aucs, probs = c(alpha / 2, 1 - alpha / 2),
                           na.rm = TRUE)
  list(fpr = grid, lower = qs[1, ], upper = qs[2, ],
       auc_low = auc_q[1], auc_high = auc_q[2])
}

#' Drop observations with a missing outcome or score, pairwise
#' @noRd
drop_incomplete <- function(actual, score) {
  keep <- !is.na(actual) & !is.na(score)
  if (!all(keep)) {
    message(sum(!keep), " observation(s) with a missing outcome or score ",
            "were dropped.")
  }
  list(actual = actual[keep], score = score[keep])
}

#' Accumulate TP/FP counts at each distinct score threshold
#'
#' Collapsing tied scores into a single step makes ROC/PR/gain summaries
#' independent of the input row order: the AUC then equals the Mann-Whitney
#' statistic with ties counted as 0.5.
#' @noRd
threshold_counts <- function(actual, score) {
  # Distinct thresholds in decreasing score order; ties share one step.
  o <- order(score, decreasing = TRUE)
  y <- actual[o]
  s <- score[o]
  tp <- cumsum(y == 1)
  fp <- cumsum(y == 0)
  # Keep the last row of each run of equal scores (the cumulative totals once
  # every observation at that threshold has been included).
  last <- !duplicated(s, fromLast = TRUE)
  list(tp = tp[last], fp = fp[last])
}

#' @noRd
roc_points <- function(actual, score) {
  P <- sum(actual == 1)
  N <- sum(actual == 0)
  if (P == 0 || N == 0) {
    stop("ROC needs both positive and negative outcomes.", call. = FALSE)
  }
  cc <- threshold_counts(actual, score)
  data.frame(fpr = c(0, cc$fp / N), tpr = c(0, cc$tp / P))
}

#' @noRd
roc_auc <- function(roc) {
  sum(diff(roc$fpr) * (utils::head(roc$tpr, -1) + utils::tail(roc$tpr, -1)) / 2)
}
