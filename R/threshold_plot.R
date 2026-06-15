# Threshold sweep: metrics vs decision threshold ----------------------------

#' Classification metrics versus decision threshold
#'
#' Sweeps the decision threshold across the full range of scores and plots the
#' chosen classification metrics - any of sensitivity (= recall), specificity,
#' precision and F1 - as colour-coded curves. This is the natural companion to
#' the ROC and precision-recall curves for *choosing* an operating point: it
#' shows directly how each metric trades off as the cut-off moves, and (by
#' default) marks the Youden's J and maximum-F1 optimal thresholds.
#'
#' At threshold \eqn{t} a case is predicted positive when its score is \eqn{\ge
#' t}. The metrics are evaluated at every distinct score (the points at which the
#' confusion matrix can change), so the curves are exact step functions rather
#' than a coarse grid.
#'
#' @param x A binomial `glm`, or the vector of observed outcomes (0/1, logical
#'   or a two-level factor with the positive class second).
#' @param score When `x` is an outcome vector, the matching scores or predicted
#'   probabilities.
#' @param metrics Which metrics to draw: any subset of `"sensitivity"`,
#'   `"specificity"`, `"precision"` and `"f1"`. (`"recall"` is accepted as an
#'   alias for `"sensitivity"`.)
#' @param mark Which optimal operating points to mark with a dashed vertical
#'   line: any subset of `"youden"` (max sensitivity + specificity - 1) and
#'   `"f1"` (max F1). Use `character(0)` or `NULL` to mark none.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The Youden and max-F1 thresholds are
#'   stored in `attr(plot, "thresholds")`.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' threshold_plot(gfit)
#'
#' # Sensitivity / specificity trade-off only, no markers.
#' threshold_plot(gfit, metrics = c("sensitivity", "specificity"),
#'                mark = NULL)
threshold_plot <- function(x, score = NULL,
                           metrics = c("sensitivity", "specificity",
                                       "precision", "f1"),
                           mark = c("youden", "f1"), title = NULL) {
  valid <- c("sensitivity", "recall", "specificity", "precision", "f1")
  metrics <- match.arg(metrics, valid, several.ok = TRUE)
  metrics[metrics == "recall"] <- "sensitivity"
  metrics <- unique(metrics)

  mark <- if (is.null(mark)) character(0) else
    match.arg(mark, c("youden", "f1"), several.ok = TRUE)

  io <- binary_inputs(x, score)
  actual <- io$actual
  sc <- io$score
  P <- sum(actual == 1)
  N <- sum(actual == 0)
  if (P == 0 || N == 0) {
    stop("A threshold sweep needs both positive and negative outcomes.",
         call. = FALSE)
  }

  cc <- threshold_counts(actual, sc)
  thr <- distinct_thresholds(sc)
  tp <- cc$tp
  fp <- cc$fp
  fn <- P - tp
  tn <- N - fp

  sensitivity <- tp / P
  specificity <- tn / N
  precision <- ifelse(tp + fp > 0, tp / (tp + fp), NA_real_)
  recall <- sensitivity
  f1 <- ifelse(precision + recall > 0,
               2 * precision * recall / (precision + recall), 0)

  metric_lookup <- list(
    sensitivity = sensitivity,
    specificity = specificity,
    precision = precision,
    f1 = f1
  )
  pretty <- c(sensitivity = "Sensitivity (recall)",
              specificity = "Specificity",
              precision = "Precision", f1 = "F1")

  long <- do.call(rbind, lapply(metrics, function(m) {
    data.frame(threshold = thr, value = metric_lookup[[m]],
               metric = pretty[[m]], stringsAsFactors = FALSE)
  }))
  long$metric <- factor(long$metric, levels = unname(pretty[metrics]))

  yp <- youden_point(actual, sc)
  fpt <- max_f1_point(actual, sc)

  p <- ggplot2::ggplot(
    long, ggplot2::aes(x = .data$threshold, y = .data$value,
                       colour = .data$metric)
  )

  if ("youden" %in% mark) {
    p <- p + ggplot2::geom_vline(xintercept = yp$threshold, linetype = 2,
                                 colour = depictr_reference())
  }
  if ("f1" %in% mark) {
    p <- p + ggplot2::geom_vline(xintercept = fpt$threshold, linetype = 3,
                                 colour = depictr_reference())
  }

  p <- p +
    ggplot2::geom_line(linewidth = 0.9, na.rm = TRUE) +
    scale_colour_depictr(name = NULL) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(x = "Decision threshold", y = "Metric value", title = title) +
    theme_depictr()

  attr(p, "thresholds") <- c(youden = yp$threshold, f1 = fpt$threshold)
  p
}
