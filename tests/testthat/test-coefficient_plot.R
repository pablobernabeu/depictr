test_that("coefficient_plot() returns a ggplot and drops the intercept by default", {
  fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
  p <- coefficient_plot(fit)
  expect_s3_class(p, "ggplot")
  expect_false(any(grepl("Intercept", as.character(p$data$label))))

  p2 <- coefficient_plot(fit, intercept = TRUE)
  expect_true(any(grepl("Intercept", as.character(p2$data$label))))
})

test_that("coefficient_plot() orders terms by estimate", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- coefficient_plot(fit, order = "ascending")
  est <- p$data$estimate
  expect_equal(est, sort(est))
})

test_that("coefficient_plot() accepts custom and named labels", {
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  p <- coefficient_plot(fit, labels = c(rainfall = "Rainfall", fertiliser = "Fert."))
  expect_true(all(c("Rainfall", "Fert.") %in% as.character(p$data$label)))
  expect_error(coefficient_plot(fit, labels = "only-one"), "length")
})

test_that("an unnamed `labels` vector is bound to the terms in model order", {
  # Regression: the vector was attached after order_terms() had reversed or
  # sorted the rows, so soil_ph (estimate 0.99) was labelled "Rainfall" and
  # rainfall (0.004) "Soil pH". In the first fit, the estimates happen to
  # ascend in model order, which hid the fault under "ascending". The second
  # fit lists the same terms out of estimate order, so every order is tested.
  want <- c(`(Intercept)` = "Intercept", rainfall = "Rainfall",
            fertiliser = "Fertiliser", soil_ph = "Soil pH")
  fits <- list(lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield),
               lm(yield ~ soil_ph + rainfall + fertiliser, data = crop_yield))
  for (fit in fits) {
    in_model <- names(stats::coef(fit))
    slopes <- in_model[-1]
    for (ord in c("none", "ascending", "descending")) {
      info <- paste(deparse(stats::formula(fit)), ord)
      p <- coefficient_plot(fit, labels = unname(want[slopes]), order = ord)
      expect_equal(as.character(p$data$label[p$data$term == "soil_ph"]),
                   "Soil pH", info = info)
      expect_equal(as.character(p$data$label), unname(want[p$data$term]),
                   info = info)

      p <- coefficient_plot(fit, labels = unname(want[in_model]), order = ord,
                            intercept = TRUE)
      expect_equal(as.character(p$data$label), unname(want[p$data$term]),
                   info = paste(info, "with the intercept"))
    }
  }
  # Under the default order the labels read in model order from top to bottom.
  p <- coefficient_plot(fits[[1]], labels = c("Rainfall", "Fertiliser",
                                              "Soil pH"))
  expect_equal(levels(p$data$label), c("Soil pH", "Fertiliser", "Rainfall"))
})

test_that("an unnamed `labels` vector of the wrong length names both counts", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  expect_error(
    coefficient_plot(fit, labels = c("Intercept", "R", "F", "S")),
    paste("`labels` has length 4 but the model has 3 terms to label",
          "(in model order, after dropping the intercept)."),
    fixed = TRUE
  )
  expect_error(
    coefficient_plot(fit, labels = c("R", "F", "S"), intercept = TRUE),
    "`labels` has length 3 but the model has 4 terms to label (in model order).",
    fixed = TRUE
  )
})

test_that("`order` puts estimates in increasing order up the axis", {
  # The Python twin pins the same direction. ggplot2 and plotnine both draw
  # the first level of a discrete y axis at the bottom, so "ascending" lists
  # the smallest estimate first and puts the largest at the top.
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  slopes <- stats::coef(fit)[-1]
  p <- coefficient_plot(fit, order = "ascending")
  expect_equal(levels(p$data$label), format_terms(names(sort(slopes))))
  p <- coefficient_plot(fit, order = "descending")
  expect_equal(levels(p$data$label),
               format_terms(names(sort(slopes, decreasing = TRUE))))
  # "none" keeps model order from top to bottom.
  p <- coefficient_plot(fit, order = "none")
  expect_equal(levels(p$data$label), rev(format_terms(names(slopes))))
})

test_that("tied estimates keep model order under either sort", {
  # R's order() is stable, and the Python twin sorts stably to match it, so
  # both twins stack tied terms alike. tests/test_data_theme_models.py pins the
  # same vectors. There are 24 terms because with only a few, a sort that is
  # not stable can leave the ties in order by chance.
  est <- data.frame(term = sprintf("t%02d", 1:24),
                    estimate = rep(c(0.2, 0.4, 0.1, 0.3, 0), length.out = 24))
  est$conf.low <- est$estimate - 0.05
  est$conf.high <- est$estimate + 0.05
  up <- c(5, 10, 15, 20, 3, 8, 13, 18, 23, 1, 6, 11, 16, 21, 4, 9, 14, 19, 24,
          2, 7, 12, 17, 22)
  down <- c(2, 7, 12, 17, 22, 4, 9, 14, 19, 24, 1, 6, 11, 16, 21, 3, 8, 13,
            18, 23, 5, 10, 15, 20)
  p <- coefficient_plot(est, order = "ascending")
  expect_equal(levels(p$data$label), sprintf("t%02d", up))
  p <- coefficient_plot(est, order = "descending")
  expect_equal(levels(p$data$label), sprintf("t%02d", down))
})

test_that("a `labels` key that matches no term warns", {
  # Regression: a mistyped key was dropped in silence, so the figure came back
  # looking exactly like the unlabelled one.
  est <- data.frame(term = c("stress", "sleep_hours"),
                    estimate = c(-0.4, 0.3),
                    conf.low = c(-0.6, 0.1),
                    conf.high = c(-0.2, 0.5))
  expect_warning(
    coefficient_plot(est, labels = c(strss = "Stress")),
    paste0("^`labels` keys not found among the parameters: strss\\. ",
           "The parameters are stress, sleep_hours\\.$")
  )
  # A key that does match must stay quiet, and must still relabel.
  expect_no_warning(p <- coefficient_plot(est, labels = c(stress = "Stress")))
  expect_true("Stress" %in% as.character(p$data$label))
})

test_that("compare_models() reports an unused `labels` key once", {
  m1 <- lm(yield ~ rainfall + soil_ph, data = crop_yield)
  m2 <- lm(yield ~ rainfall + soil_ph,
           data = crop_yield[crop_yield$treatment == "standard", ])
  # The same terms arrive once per source, so the message must list them once.
  expect_warning(
    compare_models(A = m1, B = m2, labels = c(rainfal = "Rainfall")),
    paste0("^`labels` keys not found among the parameters: rainfal\\. ",
           "The parameters are \\(Intercept\\), rainfall, soil_ph\\.$")
  )
  expect_no_warning(compare_models(A = m1, B = m2,
                                   labels = c(rainfall = "Rainfall")))
})

test_that("the pretty-label merge does not trip the unused-key warning", {
  # merge_pretty_labels() adds b_-prefixed keys that no frequentist fit carries,
  # so the check must see the user's `labels` before that merge.
  fit <- lm(yield ~ rainfall + treatment, data = crop_yield)
  expect_no_warning(coefficient_plot(fit))
  expect_no_warning(coefficient_plot(fit, labels = c(rainfall = "Rainfall")))
})

test_that("compare_models() needs at least two sources", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  expect_error(compare_models(fit), "at least two")
})

test_that("compare_models() combines sources", {
  m1 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertiliser,
           data = crop_yield[crop_yield$treatment == "standard", ])
  p <- compare_models(A = m1, B = m2)
  expect_s3_class(p, "ggplot")
  expect_setequal(levels(p$data$source), c("A", "B"))
})

test_that("compare_models() binds an unnamed `labels` vector to the terms", {
  # Regression: the vector was checked against the stacked table, which has
  # one row per term and source, so one label per term was refused ("length 3
  # but there are 5 terms").
  m1 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  want <- c(rainfall = "Rainfall", fertiliser = "Fertiliser",
            soil_ph = "Soil pH")
  for (ord in c("none", "ascending", "descending")) {
    p <- compare_models(A = m1, B = m2, labels = unname(want), order = ord)
    drawn <- p$data[!is.na(p$data$term), ]
    expect_equal(as.character(drawn$label), unname(want[drawn$term]),
                 info = ord)
  }
  # "none" keeps first-seen order from top to bottom.
  p <- compare_models(A = m1, B = m2, labels = unname(want))
  expect_equal(levels(p$data$label), rev(unname(want)))

  # With the intercept kept, it is the first term each source reports.
  p <- compare_models(A = m1, B = m2, intercept = TRUE,
                      labels = c("Intercept", unname(want)))
  drawn <- p$data[!is.na(p$data$term), ]
  expect_equal(as.character(drawn$label[drawn$term == "(Intercept)"]),
               rep("Intercept", 2))

  expect_error(
    compare_models(A = m1, B = m2, labels = c("R", "F")),
    paste("`labels` has length 2 but the models have 3 terms to label",
          "(in the order they first appear, after dropping the intercept)."),
    fixed = TRUE
  )
})

test_that("compare_models() gives aligned aliases one positional label", {
  # "stress" and brms's "b_stress" are drawn as one term, so a positional
  # vector carries one label for them, as the figure shows one row.
  a <- data.frame(term = c("stress", "sleep_hours"), estimate = c(-0.4, 0.3),
                  conf.low = c(-0.6, 0.1), conf.high = c(-0.2, 0.5))
  b <- data.frame(term = c("b_stress", "b_sleep_hours"),
                  estimate = c(-0.35, 0.25),
                  conf.low = c(-0.5, 0.1), conf.high = c(-0.2, 0.4))
  p <- compare_models(A = a, B = b, labels = c("Stress", "Sleep (hours)"))
  expect_equal(levels(p$data$label), c("Sleep (hours)", "Stress"))
  drawn <- p$data[!is.na(p$data$term), ]
  expect_equal(as.character(drawn$label[drawn$term %in% c("stress", "b_stress")]),
               rep("Stress", 2))
})

test_that("frequentist_bayesian_plot() labels the two sources", {
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  bayes <- tidy_estimates(freq)
  p <- frequentist_bayesian_plot(freq, bayes)
  expect_s3_class(p, "ggplot")
  expect_true(any(grepl("Frequentist", levels(p$data$source))))
  expect_true(any(grepl("Bayesian", levels(p$data$source))))
})

test_that("frequentist_bayesian_plot() binds an unnamed `labels` vector on both paths", {
  # Regression: the summary path handed the vector to compare_models(), which
  # refused it, and the distribution path checked it against one row per
  # posterior draw ("length 3 but there are 600 terms"). Both paths now read
  # it as compare_models() does, with the frequentist terms first. A
  # b_-prefixed Bayesian term takes the label of the frequentist term it is
  # drawn with.
  freq <- lm(life_satisfaction ~ stress + sleep_hours, data = wellbeing_survey)
  want <- c("Intercept", "Stress", "Sleep (hours)")
  key <- c(`(Intercept)` = "Intercept", b_Intercept = "Intercept",
           stress = "Stress", b_stress = "Stress",
           sleep_hours = "Sleep (hours)", b_sleep_hours = "Sleep (hours)")

  summ <- tidy_estimates(freq)
  summ$term <- c("b_Intercept", "b_stress", "b_sleep_hours")
  p <- frequentist_bayesian_plot(freq, summ, labels = want)
  drawn <- p$data[!is.na(p$data$term), ]
  expect_equal(as.character(drawn$label), unname(key[drawn$term]))

  # The distribution path keeps the draws and the frequentist overlay in
  # separate layers, so the term-label pairs are collected from every layer.
  layer_labels <- function(p) {
    do.call(rbind, lapply(p$layers, function(l) {
      d <- l$data
      if (is.data.frame(d) && all(c("term", "label") %in% names(d))) {
        d[, c("term", "label")]
      }
    }))
  }
  set.seed(1)
  draws <- as.data.frame(lapply(stats::coef(freq),
                                function(m) stats::rnorm(200, m, 0.05)))
  names(draws) <- c("b_Intercept", "b_stress", "b_sleep_hours")
  got <- layer_labels(frequentist_bayesian_plot(freq, draws, labels = want))
  expect_setequal(unique(got$term), names(key))
  expect_equal(as.character(got$label), unname(key[got$term]))

  got <- layer_labels(frequentist_bayesian_plot(freq, draws, labels = want[-1],
                                                intercept = FALSE))
  expect_setequal(unique(got$term), names(key)[-(1:2)])
  expect_equal(as.character(got$label), unname(key[got$term]))
  expect_error(
    frequentist_bayesian_plot(freq, draws, labels = want[-1]),
    "`labels` has length 2 but the models have 3 terms to label (in the order they first appear).",
    fixed = TRUE
  )
})

test_that("the standardise label names the x-only convention", {
  # standardise_estimates() rescales the predictors but not the outcome, so the
  # figure must not say "standardised estimate", which conventionally means a
  # fully standardised beta. The figure travels without its help page.
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  expect_equal(coefficient_plot(fit, standardise = TRUE)$labels$x,
               "Estimate per SD of predictor")
  expect_equal(coefficient_plot(fit)$labels$x, "Estimate")
  # An explicit x_lab still wins.
  expect_equal(coefficient_plot(fit, standardise = TRUE, x_lab = "beta")$labels$x,
               "beta")
})
