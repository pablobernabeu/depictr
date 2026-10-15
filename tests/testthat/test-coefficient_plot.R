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

# Standardised estimates, keyed by raw term name.
std_by_term <- function(p, col = "estimate") {
  stats::setNames(p$data[[col]], p$data$term)
}

test_that("standardise scales continuous inputs and leaves contrasts alone", {
  # Regression: every model-matrix column was multiplied by its own SD, so the
  # treatment dummy was scaled by 0.500 (the SD of a 0/1 column with 46.5%
  # treated) and rainfall:treatmentenhanced by 264.98, the SD of a product
  # column. Gelman (2008, p. 2867) leaves binary inputs unscaled and scales an
  # interaction through its inputs, so the interaction is the change in the
  # rainfall slope per SD of rainfall.
  fit <- lm(yield ~ rainfall * treatment + fertiliser, data = crop_yield)
  b <- stats::coef(fit)
  ci <- stats::confint(fit)
  sd_rain <- stats::sd(crop_yield$rainfall)
  sd_fert <- stats::sd(crop_yield$fertiliser)
  p <- coefficient_plot(fit, standardise = TRUE)
  got <- std_by_term(p)
  expect_equal(got[["treatmentenhanced"]], b[["treatmentenhanced"]])
  expect_equal(got[["rainfall"]], b[["rainfall"]] * sd_rain)
  expect_equal(got[["fertiliser"]], b[["fertiliser"]] * sd_fert)
  expect_equal(got[["rainfall:treatmentenhanced"]],
               b[["rainfall:treatmentenhanced"]] * sd_rain)
  expect_equal(std_by_term(p, "conf.low")[["rainfall:treatmentenhanced"]],
               ci["rainfall:treatmentenhanced", 1] * sd_rain)
  expect_equal(std_by_term(p, "conf.high")[["treatmentenhanced"]],
               ci["treatmentenhanced", 2])
  expect_equal(p$labels$x, "Estimate per SD of predictor (contrasts unscaled)")

  # Gelman's two-SD convention doubles the continuous multipliers only.
  p2 <- coefficient_plot(fit, standardise = TRUE, sd_multiple = 2)
  got2 <- std_by_term(p2)
  expect_equal(got2[["rainfall"]], b[["rainfall"]] * 2 * sd_rain)
  expect_equal(got2[["rainfall:treatmentenhanced"]],
               b[["rainfall:treatmentenhanced"]] * 2 * sd_rain)
  expect_equal(got2[["treatmentenhanced"]], b[["treatmentenhanced"]])
  expect_equal(p2$labels$x,
               "Estimate per 2 SD of predictor (contrasts unscaled)")
})

test_that("a binary input's standardised estimate does not track group balance", {
  # Simulation from the audit: y = d + x + e. The per-column SD gave d about
  # 0.52, 0.43 and 0.23 at P(d = 1) = 0.5, 0.2 and 0.05 for one true effect.
  # A 0/1 or 1/2 numeric, a logical and a factor input are all left unscaled.
  for (p1 in c(0.5, 0.2, 0.05)) {
    withr::local_seed(11)
    n <- 2000
    sim <- data.frame(d = stats::rbinom(n, 1, p1), x = stats::rnorm(n))
    sim$y <- sim$d + sim$x + stats::rnorm(n)
    sim$d_lgl <- sim$d == 1
    sim$d_fac <- factor(sim$d, labels = c("no", "yes"))
    sim$d_12 <- sim$d + 1
    for (form in list(y ~ d + x, y ~ d_lgl + x, y ~ d_fac + x, y ~ d_12 + x)) {
      fit <- lm(form, data = sim)
      raw <- stats::coef(fit)[2]
      got <- std_by_term(coefficient_plot(fit, standardise = TRUE))
      expect_equal(got[[names(raw)]], unname(raw), info = paste(p1, names(raw)))
      expect_equal(got[["x"]], stats::coef(fit)[["x"]] * stats::sd(sim$x))
    }
  }
})

test_that("standardise scales a transformed input by the SD of what was fitted", {
  fit <- lm(yield ~ log(rainfall) + treatment, data = crop_yield)
  got <- std_by_term(coefficient_plot(fit, standardise = TRUE))
  expect_equal(got[["log(rainfall)"]],
               stats::coef(fit)[["log(rainfall)"]] *
                 stats::sd(log(crop_yield$rainfall)))
})

test_that("matrix-valued terms are left unscaled with a message", {
  fit <- lm(yield ~ poly(rainfall, 2) + fertiliser, data = crop_yield)
  expect_message(p <- coefficient_plot(fit, standardise = TRUE),
                 "poly(rainfall, 2)", fixed = TRUE)
  got <- std_by_term(p)
  b <- stats::coef(fit)
  expect_equal(got[["poly(rainfall, 2)1"]], b[["poly(rainfall, 2)1"]])
  expect_equal(got[["poly(rainfall, 2)2"]], b[["poly(rainfall, 2)2"]])
  expect_equal(got[["fertiliser"]],
               b[["fertiliser"]] * stats::sd(crop_yield$fertiliser))
  # No contrast is drawn, so the label does not mention one.
  expect_equal(p$labels$x, "Estimate per SD of predictor")
})

test_that("a continuous-by-continuous interaction warns unless centred", {
  fit <- lm(yield ~ rainfall * fertiliser, data = crop_yield)
  expect_warning(p <- coefficient_plot(fit, standardise = TRUE),
                 "rainfall:fertiliser")
  b <- stats::coef(fit)
  expect_equal(std_by_term(p)[["rainfall:fertiliser"]],
               b[["rainfall:fertiliser"]] * stats::sd(crop_yield$rainfall) *
                 stats::sd(crop_yield$fertiliser))
  # Gelman's remedy: centred inputs make each main effect the slope at the
  # other's mean, so there is nothing to warn about.
  centred <- transform(crop_yield, rain_c = rainfall - mean(rainfall),
                       fert_c = fertiliser - mean(fertiliser))
  fit_c <- lm(yield ~ rain_c * fert_c, data = centred)
  expect_no_warning(coefficient_plot(fit_c, standardise = TRUE))
  # Centring one input is not enough: its main effect is still the slope
  # where the other, uncentred input is zero.
  expect_warning(
    coefficient_plot(lm(yield ~ rain_c * fertiliser, data = centred),
                     standardise = TRUE),
    "rain_c:fertiliser is an interaction", fixed = TRUE
  )
  # Without standardise the figure is in raw units and says nothing.
  expect_no_warning(coefficient_plot(fit))
})

test_that("standardise maps inputs for glm and lmer fits", {
  gfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  got <- std_by_term(coefficient_plot(gfit, standardise = TRUE))
  b <- stats::coef(gfit)
  expect_equal(got[["conditionunrelated"]], b[["conditionunrelated"]])
  expect_equal(got[["word_frequency"]],
               b[["word_frequency"]] * stats::sd(lexical_decision$word_frequency))

  skip_if_not_installed("lme4")
  mfit <- lme4::lmer(RT ~ condition + modality + word_frequency +
                       (1 | participant) + (1 | item), data = lexical_decision)
  got <- std_by_term(coefficient_plot(mfit, standardise = TRUE))
  fe <- lme4::fixef(mfit)
  expect_equal(got[["conditionunrelated"]], fe[["conditionunrelated"]])
  expect_equal(got[["modalityauditory"]], fe[["modalityauditory"]])
  expect_equal(got[["word_frequency"]],
               fe[["word_frequency"]] * stats::sd(lexical_decision$word_frequency))
})

test_that("sd_multiple must be a single positive number", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  for (bad in list(0, -1, c(1, 2), NA_real_, "2")) {
    expect_error(coefficient_plot(fit, standardise = TRUE, sd_multiple = bad),
                 "`sd_multiple` must be a single positive number", fixed = TRUE)
  }
})

test_that("model_report() leaves the treatment contrast unscaled by default", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
            data = crop_yield)
  coef_panel <- model_report(fit)[[1]]
  got <- std_by_term(coef_panel)
  expect_equal(got[["treatmentenhanced"]], stats::coef(fit)[["treatmentenhanced"]])
  expect_equal(got[["soil_ph"]],
               stats::coef(fit)[["soil_ph"]] * stats::sd(crop_yield$soil_ph))
  expect_equal(coef_panel$labels$title,
               "Coefficients (per SD of continuous predictors)")
})

# Odds, rate and risk ratios --------------------------------------------------

# The x position of each vertical reference line a plot draws.
vline_positions <- function(p) {
  vl <- Filter(function(l) inherits(l$geom, "GeomVline"), p$layers)
  unname(unlist(lapply(vl, function(l) {
    if (is.null(l$aes_params$xintercept)) l$data$xintercept
    else l$aes_params$xintercept
  })))
}

# The name of the x scale's transformation, "identity" when none is set.
x_transformation <- function(p) {
  sc <- p$scales$get_scales("x")
  if (is.null(sc)) return("identity")
  tr <- if (is.function(sc$get_transformation)) sc$get_transformation() else sc$trans
  tr$name
}

test_that("coefficient_plot(exponentiate = TRUE) draws odds ratios on a log axis", {
  bfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  p <- coefficient_plot(bfit, exponentiate = TRUE)
  b <- stats::coef(bfit)[-1]
  link <- tidy_estimates(bfit)[-1, ]
  got <- std_by_term(p)
  expect_equal(got[names(b)], exp(b))
  expect_equal(std_by_term(p, "conf.low")[link$term], exp(link$conf.low),
               ignore_attr = TRUE)
  expect_equal(vline_positions(p), 1)
  expect_equal(p$labels$x, "Odds ratio")
  expect_equal(x_transformation(p), "log-10")
  expect_no_warning(ggplot2::ggplot_build(p))

  # Without it, nothing changes: link scale, line at 0, linear axis.
  p0 <- coefficient_plot(bfit)
  expect_equal(vline_positions(p0), 0)
  expect_equal(p0$labels$x, "Estimate")
  expect_equal(x_transformation(p0), "identity")

  # An explicit reference line and axis label still win, and NA omits the line.
  expect_equal(vline_positions(coefficient_plot(bfit, exponentiate = TRUE,
                                                reference_line = 2)), 2)
  expect_null(vline_positions(coefficient_plot(bfit, exponentiate = TRUE,
                                               reference_line = NA)))
  expect_equal(coefficient_plot(bfit, exponentiate = TRUE,
                                x_lab = "OR")$labels$x, "OR")

  # The faceted layout draws the line at 1 in the panels whose interval
  # brackets it.
  pf <- coefficient_plot(bfit, exponentiate = TRUE, facet = TRUE)
  expect_true(all(vline_positions(pf) == 1))
  expect_equal(x_transformation(pf), "log-10")
})

test_that("the ratio is named by the family and link", {
  set.seed(9)
  d <- data.frame(x = rnorm(200), arm = factor(rep(c("a", "b"), 100)))
  d$count <- rpois(200, exp(0.5 + 0.3 * d$x))
  d$event <- rbinom(200, 1, 0.2 * exp(0.2 * d$x) / max(exp(0.2 * d$x)))
  label_of <- function(fit) coefficient_plot(fit, exponentiate = TRUE)$labels$x
  expect_equal(label_of(glm(count ~ x + arm, data = d, family = poisson)),
               "Rate ratio")
  expect_equal(label_of(glm(count ~ x + arm, data = d, family = quasipoisson)),
               "Rate ratio")
  expect_equal(label_of(glm(event ~ x + arm, data = d,
                            family = quasibinomial)), "Odds ratio")
  rr <- suppressWarnings(glm(event ~ x, data = d, family = binomial(link = "log"),
                             start = c(log(0.1), 0)))
  expect_equal(label_of(rr), "Risk ratio")
  expect_equal(label_of(glm(event ~ x, data = d,
                            family = binomial(link = "probit"))),
               "exp(Estimate)")
  # exp() of an lm(log(y) ~ x) slope is a ratio of geometric means, so an
  # identity link is not refused.
  expect_equal(label_of(lm(log(yield) ~ rainfall, data = crop_yield)),
               "exp(Estimate)")
  df <- data.frame(term = c("a", "b"), estimate = c(0.2, -0.4),
                   conf.low = c(0.1, -0.6), conf.high = c(0.3, -0.2))
  pd <- coefficient_plot(df, exponentiate = TRUE)
  expect_equal(pd$labels$x, "exp(Estimate)")
  expect_equal(pd$data$estimate[match(c("a", "b"), pd$data$term)],
               exp(c(0.2, -0.4)))

  skip_if_not_installed("MASS")
  d$nb <- MASS::rnegbin(200, exp(0.5 + 0.3 * d$x), theta = 2)
  expect_equal(label_of(MASS::glm.nb(nb ~ x, data = d)), "Rate ratio")
})

test_that("exponentiate applies after standardise", {
  bfit <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
              family = binomial)
  p <- coefficient_plot(bfit, standardise = TRUE, exponentiate = TRUE)
  b <- stats::coef(bfit)
  got <- std_by_term(p)
  expect_equal(got[["word_frequency"]],
               exp(b[["word_frequency"]] *
                     stats::sd(lexical_decision$word_frequency)))
  expect_equal(got[["conditionunrelated"]], exp(b[["conditionunrelated"]]))
  expect_equal(p$labels$x,
               "Odds ratio per SD of predictor (contrasts unscaled)")
})

test_that("exponentiate must be TRUE or FALSE", {
  fit <- lm(yield ~ rainfall, data = crop_yield)
  for (bad in list(NA, c(TRUE, FALSE), "yes", 1)) {
    expect_error(coefficient_plot(fit, exponentiate = bad),
                 "`exponentiate` must be TRUE or FALSE", fixed = TRUE)
    expect_error(compare_models(fit, fit, exponentiate = bad),
                 "`exponentiate` must be TRUE or FALSE", fixed = TRUE)
  }
})

test_that("compare_models(exponentiate = TRUE) exponentiates every source", {
  m1 <- glm(accuracy ~ word_frequency + condition, data = lexical_decision,
            family = binomial)
  m2 <- glm(accuracy ~ word_frequency + condition + modality,
            data = lexical_decision, family = binomial)
  # A data-frame source is read on the link scale, as the models are.
  m3 <- data.frame(term = "word_frequency", estimate = 0.3, conf.low = 0.1,
                   conf.high = 0.5)
  p <- compare_models(A = m1, B = m2, C = m3, exponentiate = TRUE)
  got <- p$data[!is.na(p$data$estimate), ]
  a_wf <- got$estimate[got$source == "A" & got$term == "word_frequency"]
  expect_equal(a_wf, exp(stats::coef(m1)[["word_frequency"]]))
  b_mod <- got$conf.high[got$source == "B" & got$term == "modalityauditory"]
  expect_equal(b_mod, exp(tidy_estimates(m2)$conf.high[4]))
  expect_equal(got$estimate[got$source == "C"], exp(0.3))
  expect_equal(vline_positions(p), 1)
  expect_equal(p$labels$x, "Odds ratio")
  expect_equal(x_transformation(p), "log-10")
  expect_no_warning(ggplot2::ggplot_build(p))

  # Defaults unchanged without it.
  p0 <- compare_models(A = m1, B = m2)
  expect_equal(vline_positions(p0), 0)
  expect_equal(p0$labels$x, "Estimate")

  # Sources of different families fall back to the neutral label.
  set.seed(9)
  d <- data.frame(x = rnorm(100))
  d$count <- rpois(100, exp(0.5 + 0.3 * d$x))
  d$event <- rbinom(100, 1, 0.4)
  mixed <- compare_models(Count = glm(count ~ x, data = d, family = poisson),
                          Event = glm(event ~ x, data = d, family = binomial),
                          exponentiate = TRUE)
  expect_equal(mixed$labels$x, "exp(Estimate)")
})
