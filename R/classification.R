# Classification plots: ROC, calibration, confusion matrix -------------------

#' ROC curve
#'
#' Plots the receiver operating characteristic (ROC) curve for a binary
#' classifier and reports the area under the curve (AUC). The input can be a
#' fitted binomial `glm`, or a pair of vectors: the observed binary outcome and
#' a continuous score (e.g. predicted probabilities).
#'
#' @param x A binomial `glm`, or the vector of observed outcomes (0/1, logical
#'   or a two-level factor with the positive class second).
#' @param score When `x` is an outcome vector, the matching vector of scores or
#'   predicted probabilities.
#' @param colour Curve colour.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The AUC is also stored in
#'   `attr(plot, "auc")`.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + condition + RT,
#'             data = lexical_decision, family = binomial)
#' roc_curve_plot(gfit)
roc_curve_plot <- function(x, score = NULL, colour = "#005b96", title = NULL) {
  io <- binary_inputs(x, score)
  roc <- roc_points(io$actual, io$score)
  auc <- roc_auc(roc)

  p <- ggplot2::ggplot(roc, ggplot2::aes(x = .data$fpr, y = .data$tpr)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = "grey60") +
    ggplot2::geom_line(colour = colour, linewidth = 0.9) +
    ggplot2::annotate("text", x = 0.98, y = 0.04, hjust = 1,
                      label = paste0("AUC = ", formatC(auc, format = "f",
                                                       digits = 3)),
                      colour = "#0a3d62", fontface = "bold") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "False positive rate", y = "True positive rate",
                  title = title) +
    theme_depictr()
  attr(p, "auc") <- auc
  p
}

#' Calibration plot
#'
#' Assesses how well predicted probabilities match observed frequencies. The
#' scores are split into bins; for each bin the mean predicted probability is
#' plotted against the observed event rate, with the diagonal marking perfect
#' calibration.
#'
#' @param x A binomial `glm`, or the vector of observed outcomes.
#' @param score When `x` is an outcome vector, the matching predicted
#'   probabilities.
#' @param bins Number of (equal-count) bins.
#' @param colour Point/line colour.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
#'             family = binomial)
#' calibration_plot(gfit, bins = 8)
calibration_plot <- function(x, score = NULL, bins = 10, colour = "#005b96",
                             title = NULL) {
  io <- binary_inputs(x, score)
  probs <- pmin(pmax(io$score, 0), 1)
  brks <- stats::quantile(probs, probs = seq(0, 1, length.out = bins + 1),
                          na.rm = TRUE)
  brks <- unique(brks)
  if (length(brks) < 3) stop("Too few distinct scores to form bins.",
                             call. = FALSE)
  bin <- cut(probs, breaks = brks, include.lowest = TRUE)
  agg <- data.frame(
    predicted = tapply(probs, bin, mean),
    observed = tapply(io$actual, bin, mean),
    n = tapply(io$actual, bin, length)
  )
  agg <- agg[stats::complete.cases(agg), , drop = FALSE]

  ggplot2::ggplot(agg, ggplot2::aes(x = .data$predicted, y = .data$observed)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = "grey60") +
    ggplot2::geom_line(colour = colour, linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(size = .data$n), colour = colour,
                        alpha = 0.7) +
    ggplot2::scale_size_area(name = "n", max_size = 7) +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Mean predicted probability",
                  y = "Observed frequency", title = title) +
    theme_depictr()
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
#'   positive class.
#' @param normalize One of `"none"`, `"row"` (by actual class) or `"col"` (by
#'   predicted class); controls the fill shading and the cell annotation.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' confusion_matrix_plot(gfit, threshold = 0.5)
confusion_matrix_plot <- function(x, predicted = NULL, threshold = 0.5,
                                  normalize = c("none", "row", "col"),
                                  title = NULL) {
  normalize <- match.arg(normalize)
  if (inherits(x, "glm")) {
    resp <- stats::model.response(stats::model.frame(x))
    actual_bin <- as_binary(resp)
    pred_bin <- as.integer(stats::fitted(x) >= threshold)
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

  if (normalize == "row") {
    denom <- stats::ave(tab$Freq, tab$Actual, FUN = sum)
    tab$shade <- ifelse(denom > 0, tab$Freq / denom, 0)
    tab$label <- sprintf("%d\n(%.0f%%)", tab$Freq, 100 * tab$shade)
  } else if (normalize == "col") {
    denom <- stats::ave(tab$Freq, tab$Predicted, FUN = sum)
    tab$shade <- ifelse(denom > 0, tab$Freq / denom, 0)
    tab$label <- sprintf("%d\n(%.0f%%)", tab$Freq, 100 * tab$shade)
  } else {
    tab$shade <- tab$Freq
    tab$label <- as.character(tab$Freq)
  }

  ggplot2::ggplot(tab, ggplot2::aes(x = .data$Predicted, y = .data$Actual,
                                    fill = .data$shade)) +
    ggplot2::geom_tile(colour = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$label),
                       colour = ifelse(tab$shade > stats::median(tab$shade),
                                       "white", "grey15"), size = 3.5) +
    ggplot2::scale_fill_gradient(low = "#eaf2f8", high = "#005b96",
                                 guide = "none") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Predicted", y = "Actual", title = title) +
    theme_depictr(grid = "none")
}

# ---- internal helpers ------------------------------------------------------

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
