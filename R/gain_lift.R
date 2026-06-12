# Cumulative gains and lift charts -------------------------------------------

#' Cumulative gains chart
#'
#' Shows how many of the positive cases are captured as a growing share of the
#' population is targeted in order of predicted score. It is the customary chart
#' for judging a classifier's value for ranking and targeting, as in marketing,
#' triage and fraud detection. The diagonal marks the no-model baseline and the
#' upper envelope a perfect model.
#'
#' @param x A binomial `glm`, or the vector of observed outcomes (0/1, logical
#'   or a two-level factor with the positive class second).
#' @param score When `x` is an outcome vector, the matching scores or predicted
#'   probabilities.
#' @param colour Curve colour.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' gain_plot(gfit)
gain_plot <- function(x, score = NULL, colour = "#005b96", title = NULL) {
  io <- binary_inputs(x, score)
  g <- gain_table(io$actual, io$score)
  prevalence <- mean(io$actual == 1)
  perfect <- data.frame(
    population = c(0, prevalence, 1),
    captured = c(0, 1, 1)
  )

  ggplot2::ggplot(g, ggplot2::aes(x = .data$population, y = .data$captured)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = "grey60") +
    ggplot2::geom_line(data = perfect, colour = "grey75", linewidth = 0.5) +
    ggplot2::geom_line(colour = colour, linewidth = 0.9) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Population targeted", y = "Positive cases captured",
                  title = title) +
    theme_depictr()
}

#' Cumulative lift chart
#'
#' Shows how many times more positive cases a classifier captures, at each depth
#' of the score-ordered population, than random targeting would. A lift of 3 at
#' the top 10% means that decile contains three times the baseline rate of
#' positives. The horizontal line at 1 is the no-model baseline.
#'
#' @inheritParams gain_plot
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' gfit <- glm(accuracy ~ word_frequency + RT + condition,
#'             data = lexical_decision, family = binomial)
#' lift_plot(gfit)
lift_plot <- function(x, score = NULL, colour = "#005b96", title = NULL) {
  io <- binary_inputs(x, score)
  g <- gain_table(io$actual, io$score)
  g <- g[g$population > 0, , drop = FALSE]
  g$lift <- g$captured / g$population

  ggplot2::ggplot(g, ggplot2::aes(x = .data$population, y = .data$lift)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 2, colour = "grey60") +
    ggplot2::geom_line(colour = colour, linewidth = 0.9) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::expand_limits(y = 1) +
    ggplot2::labs(x = "Population targeted", y = "Cumulative lift",
                  title = title) +
    theme_depictr()
}

# ---- internal helper -------------------------------------------------------

#' Cumulative share of population vs share of positives captured
#' @noRd
gain_table <- function(actual, score) {
  P <- sum(actual == 1)
  if (P == 0 || P == length(actual)) {
    stop("Gains/lift need both positive and negative outcomes.", call. = FALSE)
  }
  o <- order(score, decreasing = TRUE)
  y <- actual[o]
  data.frame(
    population = c(0, seq_along(y) / length(y)),
    captured = c(0, cumsum(y == 1) / P)
  )
}
