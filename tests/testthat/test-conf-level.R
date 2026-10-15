# Every function that takes a `conf_level` refuses one outside (0, 1).
#
# A level given as a percentage, 95, used to give NaN intervals in most of
# these functions, with at most a "NaNs produced" warning, and an unrelated
# error from quantile() in the others. A level of 0 or 1 drew a zero-width or
# an unbounded interval without a word. The Python twin's
# tests/test_argument_validation.py pins the same message.

conf_level_message <- "`conf_level` must be a single number strictly between 0 and 1."
conf_level_message_na <- paste0(
  "`conf_level` must be a single number strictly between 0 and 1, ",
  "or NA to leave the limits out."
)
bad_levels <- list(95, 0, 1, -0.5, Inf, NaN, c(0.9, 0.95), "0.95")

conf_level_calls <- function() {
  fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
  gfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  estimates <- data.frame(term = c("a", "b"), estimate = c(1, 2),
                          std.error = c(0.1, 0.2))
  draws <- data.frame(rainfall = stats::rnorm(50),
                      fertiliser = stats::rnorm(50))
  by_level <- data.frame(level = paste0("G", 1:5), estimate = 1:5,
                         std.error = 0.3)
  list(
    `tidy_estimates() on an lm` = function(cl) {
      tidy_estimates(fit, conf_level = cl)
    },
    `tidy_estimates() on a glm` = function(cl) {
      tidy_estimates(gfit, conf_level = cl)
    },
    `tidy_estimates() on a data frame` = function(cl) {
      tidy_estimates(estimates, conf_level = cl)
    },
    `coefficient_plot()` = function(cl) coefficient_plot(fit, conf_level = cl),
    `compare_models()` = function(cl) {
      compare_models(A = fit, B = fit, conf_level = cl)
    },
    `frequentist_bayesian_plot()` = function(cl) {
      frequentist_bayesian_plot(fit, draws, conf_level = cl)
    },
    `estimation_plot()` = function(cl) {
      estimation_plot(crop_yield, yield, treatment, conf_level = cl,
                      n_boot = 20)
    },
    `effects_plot()` = function(cl) {
      effects_plot(fit, "fertiliser", conf_level = cl)
    },
    `interaction_plot()` = function(cl) {
      interaction_plot(fit, "fertiliser", "treatment", conf_level = cl)
    },
    `group_comparison_plot()` = function(cl) {
      group_comparison_plot(crop_yield, yield, treatment, conf_level = cl)
    },
    `roc_curve_plot()` = function(cl) {
      roc_curve_plot(gfit, ci = 20, conf_level = cl)
    },
    `random_effects_plot()` = function(cl) {
      random_effects_plot(by_level, conf_level = cl)
    },
    `acf_plot()` = function(cl) acf_plot(AirPassengers, conf_level = cl)
  )
}

test_that("a level outside (0, 1) is refused with one message", {
  calls <- conf_level_calls()
  for (fn in names(calls)) {
    for (cl in c(bad_levels, list(NA))) {
      expect_error(calls[[fn]](cl), conf_level_message, fixed = TRUE,
                   info = paste(fn, deparse(cl)))
    }
  }
})

test_that("a level inside (0, 1) is still accepted", {
  calls <- conf_level_calls()
  set.seed(1)
  for (fn in names(calls)) {
    expect_error(suppressMessages(calls[[fn]](0.9)), NA, info = fn)
  }
})

test_that("survival_plot() and calibration_plot() keep NA to leave the limits out", {
  gfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  for (cl in bad_levels) {
    expect_error(
      survival_plot(clinical_trial$time, clinical_trial$event,
                    conf_level = cl),
      conf_level_message_na, fixed = TRUE, info = deparse(cl)
    )
    expect_error(calibration_plot(gfit, conf_level = cl),
                 conf_level_message_na, fixed = TRUE, info = deparse(cl))
  }
  expect_s3_class(calibration_plot(gfit, conf_level = NA), "ggplot")
  expect_s3_class(
    survival_plot(clinical_trial$time, clinical_trial$event, conf_level = NA),
    "ggplot"
  )
})
