# The legend_inside argument: every function that offers it gates it on a
# condition (several models overlaid, sort = TRUE, and so on). These tests pin
# the shared behaviour: when the gate is satisfied the plot's theme moves the
# legend inside the panel, and when it is not the theme is left alone.

test_that("legend_inside moves the legend inside when several models overlay", {
  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  reduced <- glm(accuracy ~ word_frequency, data = lexical_decision,
                 family = binomial)
  p <- roc_curve_plot(list(Full = gfit, Reduced = reduced),
                      legend_inside = TRUE)
  expect_identical(p$theme$legend.position, "inside")
  expect_false(is.null(p$theme$legend.position.inside))
})

test_that("legend_inside is ignored when its gate is not satisfied", {
  # Single model: there is no legend to move.
  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  p_single <- roc_curve_plot(gfit, legend_inside = TRUE)
  expect_false(identical(p_single$theme$legend.position, "inside"))

  # missingness_map() gates on sort = TRUE.
  p_unsorted <- missingness_map(wellbeing_survey, sort = FALSE,
                                legend_inside = TRUE)
  expect_false(identical(p_unsorted$theme$legend.position, "inside"))
})
