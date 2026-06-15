# Regression tests for compare_models()/coefficient_plot() fixes (T1) --------

test_that("compare_models() aligns terms that tidy to the same label", {
  # "stress" and the brms-style "b_stress" both tidy to "stress"; previously
  # this produced a duplicated factor level and crashed.
  expect_no_error(
    p <- compare_models(
      A = data.frame(term = "stress", estimate = 1, conf.low = 0, conf.high = 2),
      B = data.frame(term = "b_stress", estimate = 1.1, conf.low = .1,
                     conf.high = 2.1)
    )
  )
  expect_s3_class(p, "ggplot")
  # The two sources collapse onto a single, unique "stress" row.
  expect_equal(levels(p$data$label), "stress")
  expect_setequal(as.character(p$data$source[!is.na(p$data$estimate)]),
                  c("A", "B"))
  expect_equal(sum(!is.na(p$data$estimate)), 2L)
})

test_that("frequentist_bayesian_plot() handles brms b_-prefixed term names", {
  # The canonical frequentist (lm) vs Bayesian (b_-prefixed tidy df) case that
  # used to crash with 'factor level is duplicated'.
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  bayes <- data.frame(
    term      = c("b_Intercept", "b_stress", "b_sleep_hours"),
    estimate  = c(5, -0.3, 0.4),
    conf.low  = c(4, -0.5, 0.2),
    conf.high = c(6, -0.1, 0.6)
  )
  expect_no_error(p <- frequentist_bayesian_plot(freq, bayes))
  expect_s3_class(p, "ggplot")
  # Frequentist "stress"/"sleep_hours" align with Bayesian "b_stress"/etc., so
  # no label is duplicated and each concept appears once per source.
  expect_setequal(levels(p$data$label),
                  c("Intercept", "stress", "sleep_hours"))
  expect_equal(anyDuplicated(levels(p$data$label)), 0L)
  # Both sources are present for the shared "stress" term.
  stress_sources <- p$data$source[p$data$label == "stress" &
                                    !is.na(p$data$estimate)]
  expect_setequal(as.character(stress_sources),
                  c("Frequentist analysis", "Bayesian analysis"))
})

test_that("compare_models() completes the term x source grid for dodging", {
  # Non-overlapping terms: A has x, y; B has y, z. The full grid should have
  # one row per (label, source) so position_dodge centres singleton terms,
  # with the gaps carried as NA estimates (dropped by the geoms).
  A <- data.frame(term = c("x", "y"), estimate = c(1, 2),
                  conf.low = c(0, 1), conf.high = c(2, 3))
  B <- data.frame(term = c("y", "z"), estimate = c(2.5, 3),
                  conf.low = c(1.5, 2), conf.high = c(3.5, 4))
  p <- compare_models(A = A, B = B)
  expect_s3_class(p, "ggplot")

  expect_setequal(levels(p$data$label), c("x", "y", "z"))
  # 3 labels x 2 sources = 6 rows after grid completion.
  expect_equal(nrow(p$data), 6L)
  # Each source x label combination appears exactly once.
  expect_equal(anyDuplicated(p$data[, c("label", "source")]), 0L)
  # The two singleton cells (x in B, z in A) are NA.
  expect_equal(sum(is.na(p$data$estimate)), 2L)
  expect_true(is.na(p$data$estimate[p$data$label == "x" &
                                      p$data$source == "B"]))
  expect_true(is.na(p$data$estimate[p$data$label == "z" &
                                      p$data$source == "A"]))
})

test_that("coefficient_plot() handles data-frame and model input identically", {
  # The if/else branches were byte-identical; both paths must still work.
  fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
  p_model <- coefficient_plot(fit)
  expect_s3_class(p_model, "ggplot")

  df <- data.frame(term = c("a", "b"), estimate = c(0.2, -0.4),
                   conf.low = c(0.1, -0.6), conf.high = c(0.3, -0.2))
  p_df <- coefficient_plot(df)
  expect_s3_class(p_df, "ggplot")
  expect_setequal(as.character(p_df$data$label), c("a", "b"))
})
