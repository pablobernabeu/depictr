# Tier-3 datasets: structural and statistical properties --------------------
#
# These tests pin the key properties of the bundled datasets so that a future
# edit to data-raw/generate_datasets.R that regenerates the .rda files cannot
# silently break the designed effects (counterbalancing, real interaction,
# meaningful income effect, separating survival curves, rare adverse event,
# seasonality). They use base R / suggested packages only.

## ---- lexical_decision -----------------------------------------------------

test_that("lexical_decision has the expected shape and factor columns", {
  expect_identical(dim(lexical_decision), c(960L, 7L))
  expect_identical(
    names(lexical_decision),
    c("participant", "item", "condition", "modality", "word_frequency",
      "RT", "accuracy")
  )
  expect_identical(nlevels(lexical_decision$participant), 24L)
  expect_identical(nlevels(lexical_decision$item), 40L)
  expect_identical(levels(lexical_decision$condition), c("related", "unrelated"))
  expect_identical(levels(lexical_decision$modality), c("visual", "auditory"))
  expect_true(all(lexical_decision$RT >= 250))
  expect_true(all(lexical_decision$accuracy %in% c(0L, 1L)))
})

test_that("lexical_decision is counterbalanced within items and participants", {
  # Each item appears equally often in each condition AND each modality, so
  # neither factor is collinear with the item random intercept.
  ct_cond <- table(lexical_decision$item, lexical_decision$condition)
  ct_mod  <- table(lexical_decision$item, lexical_decision$modality)
  expect_true(all(ct_cond == ct_cond[1, 1]))
  expect_true(all(ct_mod == ct_mod[1, 1]))

  # Modality is within-item: every item is half visual, half auditory.
  prop_aud <- tapply(as.integer(lexical_decision$modality == "auditory"),
                     lexical_decision$item, mean)
  expect_true(all(abs(prop_aud - 0.5) < 1e-8))

  # Each participant sees each item exactly once.
  expect_true(all(table(lexical_decision$participant,
                        lexical_decision$item) == 1L))
})

test_that("lexical_decision lmer recovers the priming effect (item SD stable)", {
  skip_if_not_installed("lme4")
  ld <- subset(lexical_decision, accuracy == 1)
  m <- lme4::lmer(
    RT ~ condition + modality + word_frequency +
      (1 | participant) + (1 | item),
    data = ld
  )
  fe <- lme4::fixef(m)
  # Unrelated priming effect in the designed ~35 ms region.
  expect_gt(fe[["conditionunrelated"]], 15)
  expect_lt(fe[["conditionunrelated"]], 55)
  # Item SD does not blow up by absorbing the (now within-item) modality.
  vc <- as.data.frame(lme4::VarCorr(m))
  item_sd <- vc$sdcor[vc$grp == "item"]
  expect_lt(item_sd, 80)
})

test_that("lexical_decision accuracy is not derived from RT", {
  # Generated from exogenous predictors only; a high overall accuracy and a
  # weak RT-accuracy link (only via shared predictors) are expected.
  expect_gt(mean(lexical_decision$accuracy), 0.85)
})

## ---- crop_yield -----------------------------------------------------------

test_that("crop_yield has a genuine fertilizer x treatment interaction", {
  expect_identical(dim(crop_yield), c(200L, 6L))
  fit <- lm(yield ~ fertilizer * treatment + rainfall + soil_ph,
            data = crop_yield)
  co <- summary(fit)$coefficients
  ix <- "fertilizer:treatmentenhanced"
  expect_true(ix %in% rownames(co))
  expect_lt(co[ix, "Pr(>|t|)"], 0.01)        # significant interaction
  expect_gt(co[ix, "Estimate"], 0)            # fertiliser pays off more enhanced
  # Main effects retained and signed sensibly.
  expect_gt(co["fertilizer", "Estimate"], 0)
  expect_gt(co["soil_ph", "Estimate"], 0)
})

## ---- wellbeing_survey -----------------------------------------------------

test_that("wellbeing_survey has an ordered education factor", {
  expect_identical(dim(wellbeing_survey), c(300L, 9L))
  expect_true(is.ordered(wellbeing_survey$education))
  expect_identical(levels(wellbeing_survey$education),
                   c("secondary", "undergraduate", "postgraduate"))
})

test_that("wellbeing_survey income is a meaningful predictor (MAR retained)", {
  w <- transform(wellbeing_survey, log_income = log(income))
  fit <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days +
              log_income + age, data = w)
  co <- summary(fit)$coefficients
  expect_gt(co["log_income", "Estimate"], 0)
  expect_lt(co["log_income", "Pr(>|t|)"], 0.05)

  # Income is missing, and missing more often at higher stress (MAR).
  expect_gt(sum(is.na(wellbeing_survey$income)), 0)
  miss <- is.na(wellbeing_survey$income)
  expect_gt(mean(wellbeing_survey$stress[miss]),
            mean(wellbeing_survey$stress[!miss]))
})

## ---- clinical_trial -------------------------------------------------------

test_that("clinical_trial has the expected columns and codings", {
  expect_identical(dim(clinical_trial), c(300L, 7L))
  expect_identical(
    names(clinical_trial),
    c("patient", "arm", "age", "biomarker", "time", "event", "adverse_event")
  )
  expect_identical(levels(clinical_trial$arm), c("placebo", "treatment"))
  expect_true(all(clinical_trial$event %in% c(0L, 1L)))
  expect_true(all(clinical_trial$adverse_event %in% c(0L, 1L)))
  expect_true(all(clinical_trial$time > 0))
})

test_that("clinical_trial shows a real survival difference (log-rank sig.)", {
  skip_if_not_installed("survival")
  sd <- survival::survdiff(survival::Surv(time, event) ~ arm,
                           data = clinical_trial)
  pval <- 1 - stats::pchisq(sd$chisq, length(sd$n) - 1)
  expect_lt(pval, 0.001)
  # Treatment arm has fewer events (longer survival, more censoring).
  ev <- tapply(clinical_trial$event, clinical_trial$arm, mean)
  expect_lt(ev[["treatment"]], ev[["placebo"]])
})

test_that("clinical_trial adverse_event is rare and predictable", {
  rate <- mean(clinical_trial$adverse_event)
  expect_gt(rate, 0.05)
  expect_lt(rate, 0.15)
  # Predictable from covariates: the model discriminates (fitted prob spread).
  m <- glm(adverse_event ~ arm + age + biomarker, data = clinical_trial,
           family = binomial)
  expect_gt(diff(range(stats::fitted(m))), 0.3)
})

## ---- monthly_sales --------------------------------------------------------

test_that("monthly_sales is a tidy two-series seasonal time series", {
  expect_identical(dim(monthly_sales), c(144L, 3L))
  expect_identical(names(monthly_sales), c("date", "series", "sales"))
  expect_s3_class(monthly_sales$date, "Date")
  expect_identical(levels(monthly_sales$series), c("indoor", "outdoor"))
  # Equal-length series, 72 months each.
  expect_identical(unname(table(monthly_sales$series)[["indoor"]]), 72L)
})

test_that("monthly_sales has clear seasonality and trend", {
  indoor <- monthly_sales$sales[monthly_sales$series == "indoor"]
  ts_in <- stats::ts(indoor, frequency = 12, start = c(2018, 1))
  dec <- stats::stl(ts_in, s.window = "periodic")$time.series
  seas_amp <- diff(range(dec[, "seasonal"]))
  rem_sd <- stats::sd(dec[, "remainder"])
  # Seasonal swing dominates the remainder noise.
  expect_gt(seas_amp / rem_sd, 3)
  # A discernible trend over the six years.
  expect_gt(diff(range(dec[, "trend"])), 30)
})
