# Frequentist vs. Bayesian comparison ----------------------------------------

#' Plot frequentist and Bayesian estimates together
#'
#' Presents the estimates from a frequentist model and a Bayesian model side by
#' side on one forest plot, in the familiar red (frequentist) and blue
#' (Bayesian) styling. The function is a convenience wrapper around
#' [compare_models()].
#'
#' It is a modernised, self-contained successor to the original
#' `frequentist_bayesian_plot()` gist. The Bayesian estimates may be supplied
#' as a fitted model or, more commonly, as a tidy data frame of posterior
#' summaries (with columns such as `term`, `estimate` and
#' `conf.low`/`conf.high`, or the `Estimate`, `l-95% CI` and `u-95% CI`
#' produced by `brms::fixef()`). Terms are aligned by name, so any small
#' differences in naming between the two sources need only be reconciled in the
#' term labels.
#'
#' @param frequentist A frequentist model (e.g. from `lm`, `glm` or
#'   `lmerTest::lmer`) or a tidy data frame of estimates.
#' @param bayesian A Bayesian model or a tidy data frame of posterior summaries.
#' @param conf_level Confidence/credible level for models.
#' @param labels,interaction,intercept See [compare_models()].
#'   `intercept` defaults to `TRUE` here, matching the original behaviour.
#' @param note_frequentist_no_prior If `TRUE`, append "(no prior)" to the
#'   frequentist legend label, which is helpful when the title names the
#'   Bayesian prior.
#' @param vertical_line_at_x Position of the vertical reference line.
#' @param title,subtitle,x_lab Title, subtitle and x-axis label.
#' @param ... Further arguments passed to [compare_models()].
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Same model fitted two ways here purely so the example is self-contained;
#' # in practice `bayesian` would come from brms, rstanarm, etc.
#' freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
#'            data = wellbeing_survey)
#' # A stand-in "Bayesian" summary as a tidy data frame:
#' bayes <- tidy_estimates(freq)
#' bayes$estimate <- bayes$estimate * 0.95
#' frequentist_bayesian_plot(freq, bayes,
#'                           title = "Frequentist vs. Bayesian estimates")
frequentist_bayesian_plot <- function(frequentist,
                                      bayesian,
                                      conf_level = 0.95,
                                      labels = NULL,
                                      interaction = c("times", "asterisk",
                                                      "colon", "space"),
                                      intercept = TRUE,
                                      note_frequentist_no_prior = FALSE,
                                      vertical_line_at_x = 0,
                                      title = NULL,
                                      subtitle = NULL,
                                      x_lab = "Estimate",
                                      ...) {
  interaction <- match.arg(interaction)
  freq_label <- if (note_frequentist_no_prior) {
    "Frequentist analysis\n(no prior)"
  } else {
    "Frequentist analysis"
  }
  bayes_label <- "Bayesian analysis"

  args <- list(frequentist, bayesian)
  names(args) <- c(freq_label, bayes_label)

  do.call(
    compare_models,
    c(args, list(
      conf_level = conf_level,
      intercept = intercept,
      labels = labels,
      interaction = interaction,
      reference_line = vertical_line_at_x,
      palette = c("#e23b3b", "#005b96"),
      legend_title = NULL,
      title = title,
      subtitle = subtitle,
      x_lab = x_lab,
      ...
    ))
  )
}
