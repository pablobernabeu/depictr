# Cumulative gains and lift charts -------------------------------------------

#' Cumulative gains chart
#'
#' Shows how many of the positive cases are captured as a growing share of the
#' population is targeted in order of predicted score. It is the customary chart
#' for judging a classifier's value for ranking and targeting, as in marketing,
#' triage and fraud detection. The diagonal marks the no-model baseline and the
#' upper envelope a perfect model. Pass a *named list* of models / (actual,
#' score) pairs to overlay several colour-coded gains curves with a legend.
#'
#' @param x A binomial `glm`; the vector of observed outcomes (0/1, logical or a
#'   two-level factor with the positive class second); or a *named* list of
#'   models / (actual, score) pairs to overlay.
#' @param score When `x` is an outcome vector, the matching scores or predicted
#'   probabilities (or a list of them for the multi-model case).
#' @param colour Curve colour for the single-model case. Defaults to the depictr
#'   brand blue. Ignored when several models are overlaid.
#' @param legend_inside When `TRUE` (and several models are overlaid), draw the
#'   legend inside the panel (in the bottom-right triangle the concave curve
#'   leaves empty) over a translucent background, instead of in a right-hand
#'   margin. Defaults to `FALSE`.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Targeting only pays off when the positive class is scarce, so the example
#' # uses the rare clinical-trial adverse event (about 10% positive).
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' gain_plot(gfit)
#'
#' # Compare two models.
#' reduced <- glm(adverse_event ~ biomarker, data = clinical_trial,
#'                family = binomial)
#' gain_plot(list(Full = gfit, Reduced = reduced))
gain_plot <- function(x, score = NULL, colour = depictr_brand(),
                      legend_inside = FALSE, title = NULL) {
  models <- as_model_list(x, score)
  multi <- attr(models, "multi")

  gs <- lapply(models, function(m) gain_table(m$actual, m$score))
  # The perfect-model envelope depends on prevalence; with one model it is drawn,
  # with several (possibly differing prevalence) we omit it to keep things clean.
  prevalence <- mean(models[[1]]$actual == 1)

  p <- ggplot2::ggplot() +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = depictr_reference())

  if (multi) {
    g <- do.call(rbind, Map(function(d, nm) { d$model <- nm; d },
                            gs, names(models)))
    g$model <- factor(g$model, levels = names(models))
    p <- p +
      ggplot2::geom_line(data = g,
                         ggplot2::aes(x = .data$population, y = .data$captured,
                                      colour = .data$model), linewidth = 0.9) +
      scale_colour_depictr(name = NULL)
  } else {
    perfect <- data.frame(population = c(0, prevalence, 1),
                          captured = c(0, 1, 1))
    p <- p +
      ggplot2::geom_line(data = perfect,
                         ggplot2::aes(x = .data$population, y = .data$captured),
                         colour = depictr_reference(), linewidth = 0.5) +
      ggplot2::geom_line(data = gs[[1]],
                         ggplot2::aes(x = .data$population, y = .data$captured),
                         colour = colour, linewidth = 0.9) +
      # Label the reference lines in place rather than adding a second legend.
      ggplot2::annotate("text", x = min(prevalence + 0.04, 0.85), y = 0.99,
                        hjust = 0, vjust = 1, label = "Perfect model",
                        colour = "grey40", size = 3, fontface = "italic") +
      ggplot2::annotate("text", x = 0.97, y = 0.9, hjust = 1, vjust = 1,
                        angle = 45, label = "Random baseline",
                        colour = "grey40", size = 3, fontface = "italic")
  }

  p <- p +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Population targeted", y = "Positive cases captured",
                  title = title) +
    theme_depictr()
  # A gains curve is concave (above the diagonal), so the bottom-right triangle
  # is always empty: when asked, place the multi-model legend there.
  if (legend_inside && multi) p <- p + legend_inside_theme(c(0.98, 0.02), c(1, 0))
  p
}

#' Cumulative lift chart
#'
#' Shows how many times more positive cases a classifier captures, at each depth
#' of the score-ordered population, than random targeting would. A lift of 3 at
#' the top 10% means that decile contains three times the baseline rate of
#' positives. The horizontal line at 1 is the no-model baseline. Pass a *named
#' list* of models / (actual, score) pairs to overlay several colour-coded lift
#' curves with a legend.
#'
#' @inheritParams gain_plot
#' @param legend_inside When `TRUE` (and several models are overlaid), draw the
#'   legend inside the panel (in the top-right corner, which the decaying lift
#'   curve leaves empty) over a translucent background, instead of in a
#'   right-hand margin. Defaults to `FALSE`.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Lift is measured against the base rate, so the example uses the rare
#' # clinical-trial adverse event (about 10% positive).
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' lift_plot(gfit)
#'
#' # Compare two models.
#' reduced <- glm(adverse_event ~ biomarker, data = clinical_trial,
#'                family = binomial)
#' lift_plot(list(Full = gfit, Reduced = reduced))
lift_plot <- function(x, score = NULL, colour = depictr_brand(),
                      legend_inside = FALSE, title = NULL) {
  models <- as_model_list(x, score)
  multi <- attr(models, "multi")

  lift_one <- function(m) {
    g <- gain_table(m$actual, m$score)
    g <- g[g$population > 0, , drop = FALSE]
    g$lift <- g$captured / g$population
    g
  }
  gs <- lapply(models, lift_one)

  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 1, linetype = 2,
                        colour = depictr_reference())

  if (multi) {
    g <- do.call(rbind, Map(function(d, nm) { d$model <- nm; d },
                            gs, names(models)))
    g$model <- factor(g$model, levels = names(models))
    p <- p +
      ggplot2::geom_line(data = g,
                         ggplot2::aes(x = .data$population, y = .data$lift,
                                      colour = .data$model), linewidth = 0.9) +
      scale_colour_depictr(name = NULL)
  } else {
    p <- p +
      ggplot2::geom_line(data = gs[[1]],
                         ggplot2::aes(x = .data$population, y = .data$lift),
                         colour = colour, linewidth = 0.9)
  }

  if (!multi) {
    # Identify the baseline directly, matching gain_plot's style.
    p <- p +
      ggplot2::annotate("text", x = 0.99, y = 1, hjust = 1, vjust = -0.4,
                        label = "Random baseline", colour = "grey40",
                        size = 3, fontface = "italic")
  }

  p <- p +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::expand_limits(y = 1) +
    ggplot2::labs(x = "Population targeted", y = "Cumulative lift",
                  title = title) +
    theme_depictr()
  # Lift decays towards the baseline (1) as the targeted share grows, so the
  # top-right corner stays empty regardless of model strength: when asked, anchor
  # the multi-model legend there.
  if (legend_inside && multi) p <- p + legend_inside_theme(c(0.98, 0.98), c(1, 1))
  p
}

# ---- internal helper -------------------------------------------------------

#' Cumulative share of population vs share of positives captured
#' @noRd
gain_table <- function(actual, score) {
  n <- length(actual)
  P <- sum(actual == 1)
  if (P == 0 || P == n) {
    stop("Gains/lift need both positive and negative outcomes.", call. = FALSE)
  }
  # Collapse tied scores: each distinct threshold targets all observations with
  # that score at once, so the curve is independent of the input row order.
  cc <- threshold_counts(actual, score)
  data.frame(
    population = c(0, (cc$tp + cc$fp) / n),
    captured = c(0, cc$tp / P)
  )
}
