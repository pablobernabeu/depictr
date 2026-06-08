# Precision-recall curve -----------------------------------------------------

#' Precision-recall curve
#'
#' Plots precision against recall for a binary classifier and reports the
#' average precision (the area under the curve). The precision-recall curve is
#' more informative than the ROC curve when the positive class is rare, because
#' it ignores the many true negatives. A horizontal line marks the no-skill
#' baseline (the positive-class prevalence).
#'
#' @param x A binomial `glm`, or the vector of observed outcomes (0/1, logical
#'   or a two-level factor with the positive class second).
#' @param score When `x` is an outcome vector, the matching scores or predicted
#'   probabilities.
#' @param colour Curve colour.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The average precision is stored in
#'   `attr(plot, "average_precision")`.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' pr_curve_plot(gfit)
pr_curve_plot <- function(x, score = NULL, colour = "#005b96", title = NULL) {
  io <- binary_inputs(x, score)
  pr <- pr_points(io$actual, io$score)
  ap <- sum(diff(c(0, pr$recall)) * pr$precision)
  prevalence <- mean(io$actual == 1)

  p <- ggplot2::ggplot(pr, ggplot2::aes(x = .data$recall, y = .data$precision)) +
    ggplot2::geom_hline(yintercept = prevalence, linetype = 2,
                        colour = "grey60") +
    ggplot2::geom_line(colour = colour, linewidth = 0.9) +
    ggplot2::annotate("text", x = 0.02, y = 0.04, hjust = 0,
                      label = paste0("AP = ", formatC(ap, format = "f",
                                                      digits = 3)),
                      colour = "#0a3d62", fontface = "bold") +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Recall", y = "Precision", title = title) +
    theme_statviz()
  attr(p, "average_precision") <- ap
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
  o <- order(score, decreasing = TRUE)
  y <- actual[o]
  tp <- cumsum(y == 1)
  fp <- cumsum(y == 0)
  data.frame(recall = tp / P, precision = tp / (tp + fp))
}
