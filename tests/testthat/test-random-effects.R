# random_effects_plot() on fitted lme4 models. The plot used to index lme4's
# postVar attribute as a three-dimensional array, which it is only when every
# term of a grouping factor shares one correlated block. With
# (1 + x || g), split terms such as (1 | g) + (0 + x | g), or their glmer
# equivalents, postVar is a list and the plot failed with "incorrect number of
# dimensions".

fit_quietly <- function(expr) suppressWarnings(suppressMessages(expr))

facets_of <- function(p) sort(unique(p$data$facet))

test_that("random_effects_plot() draws an uncorrelated (1 + x || g) model", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::lmer(
    RT ~ word_frequency + (1 + word_frequency || participant),
    data = lexical_decision
  ))
  p <- random_effects_plot(m)
  expect_s3_class(p, "ggplot")
  expect_identical(facets_of(p),
                   c("participant: (Intercept)", "participant: word_frequency"))
  expect_identical(nrow(p$data), 2L * 24L)
  # The by-participant slope variance is estimated at zero in these data, so
  # only the intercept intervals are required to have positive width.
  expect_true(all(p$data$conf.low <= p$data$estimate))
  expect_true(all(p$data$conf.high >= p$data$estimate))
  intercepts <- p$data[p$data$facet == "participant: (Intercept)", ]
  expect_true(all(intercepts$conf.high - intercepts$conf.low > 0))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("random_effects_plot() draws split terms for one grouping factor", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::lmer(
    RT ~ word_frequency + (1 | participant) + (0 + word_frequency | participant),
    data = lexical_decision
  ))
  p <- random_effects_plot(m)
  expect_s3_class(p, "ggplot")
  expect_identical(facets_of(p),
                   c("participant: (Intercept)", "participant: word_frequency"))
  expect_false(anyNA(p$data$conf.low))
})

test_that("random_effects_plot() draws a glmer (1 + x || g) model", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::glmer(
    accuracy ~ word_frequency + (1 + word_frequency || participant),
    data = lexical_decision, family = binomial
  ))
  p <- random_effects_plot(m)
  expect_s3_class(p, "ggplot")
  expect_identical(facets_of(p),
                   c("participant: (Intercept)", "participant: word_frequency"))
  expect_false(anyNA(p$data$conf.high))
})

test_that("random_effects_plot() labels two grouping factors by factor and term", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::lmer(RT ~ condition + (1 | participant) + (1 | item),
                              data = lexical_decision))
  p <- random_effects_plot(m)
  expect_identical(facets_of(p),
                   c("item: (Intercept)", "participant: (Intercept)"))
  expect_identical(nrow(p$data), 24L + 40L)
})

test_that("a single random-effect term keeps the 'Random effect' facet", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::lmer(RT ~ condition + (1 | participant),
                              data = lexical_decision))
  p <- random_effects_plot(m)
  expect_identical(facets_of(p), "Random effect")
  expect_true(inherits(p$facet, "FacetNull"))
})

test_that("correlated-model intervals still come from the postVar diagonal", {
  skip_if_not_installed("lme4")
  m <- fit_quietly(lme4::lmer(
    RT ~ word_frequency + (1 + word_frequency | participant),
    data = lexical_decision
  ))
  re <- lme4::ranef(m, condVar = TRUE)$participant
  pv <- attr(re, "postVar")
  z <- stats::qnorm(0.975)
  expected <- do.call(rbind, lapply(seq_along(re), function(ti) {
    se <- sqrt(pv[ti, ti, ])
    data.frame(facet = paste0("participant: ", names(re)[ti]),
               level = rownames(re), estimate = re[[ti]],
               conf.low = re[[ti]] - z * se, conf.high = re[[ti]] + z * se,
               stringsAsFactors = FALSE)
  }))

  got <- random_effects_plot(m, sort = FALSE)$data
  got$level <- sub("\r.*$", "", as.character(got$level))
  key_got <- paste(got$facet, got$level)
  key_exp <- paste(expected$facet, expected$level)
  expect_setequal(key_got, key_exp)
  got <- got[match(key_exp, key_got), ]
  expect_equal(got$estimate, expected$estimate, tolerance = 1e-12)
  expect_equal(got$conf.low, expected$conf.low, tolerance = 1e-12)
  expect_equal(got$conf.high, expected$conf.high, tolerance = 1e-12)
})
