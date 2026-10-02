test_that("survival_plot() handles all-censored arms (single group)", {
  # Previously crashed: empty censor data frame -> `$group <- g` errored, and
  # the all-censored branch always returned lower/upper, breaking rbind.
  expect_s3_class(survival_plot(c(5, 6, 7, 8), c(0, 0, 0, 0)), "ggplot")
  expect_s3_class(
    survival_plot(c(5, 6, 7, 8), c(0, 0, 0, 0), conf_level = NA),
    "ggplot"
  )
})

test_that("survival_plot() handles a group with zero events", {
  # One arm entirely censored alongside an arm with events.
  tt <- c(5, 6, 7, 8, 5, 6, 7, 8)
  ev <- c(1, 1, 0, 1, 0, 0, 0, 0)
  gg <- c("a", "a", "a", "a", "b", "b", "b", "b")
  expect_s3_class(survival_plot(tt, ev, group = gg), "ggplot")
  expect_s3_class(survival_plot(tt, ev, group = gg, conf_level = NA), "ggplot")
})

test_that("all-censored curve is a flat line to the last follow-up time", {
  km <- depictr:::km_estimate(c(5, 6, 7, 8), c(0, 0, 0, 0), 0.95)
  expect_equal(km$curve$surv, c(1, 1))
  expect_equal(range(km$curve$time), c(0, 8))
  expect_true(all(c("lower", "upper") %in% names(km$curve)))
  # Without CIs the columns must be omitted so groups row-bind cleanly.
  km_noci <- depictr:::km_estimate(c(5, 6, 7, 8), c(0, 0, 0, 0), NA)
  expect_false(any(c("lower", "upper") %in% names(km_noci$curve)))
})

test_that("status accepts the survival::Surv 1/2 coding", {
  # 1 = censored, 2 = event must match 0/1 results exactly.
  km12 <- depictr:::km_estimate(c(5, 6, 7, 8), c(2, 2, 2, 2), 0.95)
  km01 <- depictr:::km_estimate(c(5, 6, 7, 8), c(1, 1, 1, 1), 0.95)
  expect_equal(km12$curve, km01$curve)
  expect_equal(km12$curve$surv, c(1, 0.75, 0.5, 0.25, 0))

  # Mixed 1/2 coding with censoring.
  km_mix <- depictr:::km_estimate(c(5, 6, 7, 8), c(2, 1, 2, 2), 0.95)
  km_ref <- depictr:::km_estimate(c(5, 6, 7, 8), c(1, 0, 1, 1), 0.95)
  expect_equal(km_mix$curve, km_ref$curve)

  expect_s3_class(survival_plot(c(5, 6, 7, 8), c(2, 1, 2, 2)), "ggplot")
})

test_that("a non-finite follow-up time is refused, not silently dropped", {
  # Regression: NA and Inf times were dropped inside km_estimate(), which moves
  # the number at risk (and every step of the curve) with nothing said.
  for (bad in c(NA_real_, Inf, -Inf)) {
    tt <- c(5, 6, 7, 8)
    tt[3] <- bad
    expect_error(
      survival_plot(tt, c(1, 1, 1, 0)),
      "^`time` must be finite; drop or impute missing follow-up times before plotting\\.$"
    )
  }
  # The data-frame path funnels through the same estimator.
  expect_error(
    survival_plot(data.frame(time = c(5, NA, 7), status = c(1, 1, 0))),
    "must be finite"
  )
  # Complete times still plot, and a missing status is dropped with a message.
  expect_message(
    p_na <- survival_plot(c(5, 6, 7, 8), c(1, 1, NA, 0)),
    "1 observation(s) with a missing status were dropped",
    fixed = TRUE
  )
  expect_s3_class(p_na, "ggplot")
})

test_that("logical status is accepted and invalid coding errors", {
  km_lgl <- depictr:::km_estimate(c(5, 6, 7, 8), c(TRUE, TRUE, TRUE, TRUE), 0.95)
  expect_equal(km_lgl$curve$surv, c(1, 0.75, 0.5, 0.25, 0))
  expect_error(depictr:::km_estimate(c(1, 2), c(3, 5), 0.95), "0/1")
})

test_that("a non-integer status code is refused", {
  # Regression: as.integer() truncated towards zero before the coding was
  # checked, so c(0, 0.5, 1) was read as two censorings and an event, and
  # c(1.5, 2) as the 1/2 coding with its first subject censored.
  msg <- "`status` must use the 0/1 (0 = censored) or 1/2 (1 = censored) coding."
  expect_error(depictr:::normalise_status(c(0, 0.5, 1)), msg, fixed = TRUE)
  expect_error(depictr:::normalise_status(c(1.5, 2)), msg, fixed = TRUE)
  expect_error(depictr:::normalise_status(c(0, 1, Inf)), msg, fixed = TRUE)
  expect_error(survival_plot(c(5, 6, 7), c(0, 0.5, 1)), msg, fixed = TRUE)
  # Whole codes stored as doubles read as before, and a missing code is left
  # for km_input() to drop with its message.
  expect_identical(depictr:::normalise_status(c(0, 1, NA)), c(0L, 1L, NA))
  expect_identical(depictr:::normalise_status(c(1, 2, 2)), c(0L, 1L, 1L))
})

test_that("a factor or character status is refused", {
  # Regression: as.integer() turned a factor into its level codes, which then
  # passed as the 1/2 coding with the alphabetically first level taken as
  # censored, and a character vector into NA, giving a flat curve at 1.
  tt <- c(1, 2, 3, 4, 5, 6)
  ev <- c(1, 0, 1, 1, 0, 1)
  msg <- "must be numeric (0/1 or 1/2) or logical"
  expect_error(survival_plot(tt, factor(ifelse(ev == 1, "event", "no event"))),
               msg, fixed = TRUE)
  expect_error(survival_plot(tt, ifelse(ev == 1, "event", "censored")),
               msg, fixed = TRUE)
  expect_error(
    survival_plot(data.frame(time = tt, status = factor(ev))), msg, fixed = TRUE
  )
  # The numeric and logical codings are unchanged.
  ref <- depictr:::km_input(tt, ev, NULL, 0.95)
  expect_equal(depictr:::km_input(tt, ev == 1, NULL, 0.95)$curve, ref$curve)
  expect_equal(depictr:::km_input(tt, ev + 1, NULL, 0.95)$curve, ref$curve)
})

test_that("the status coding is read once over all observations", {
  # Regression: normalise_status() ran once per arm. In 1/2-coded data, an arm
  # with censorings only (all 1) also fits the 0/1 coding, so it was read as
  # all events and its curve fell to zero. Codes mixing the two codings across
  # arms were accepted too.
  tt <- c(1, 2, 3, 4, 5, 6, 7, 8)
  gg <- rep(c("a", "b"), each = 4)
  st12 <- c(2, 1, 2, 2, 1, 1, 1, 1)
  km12 <- depictr:::km_input(tt, st12, gg, 0.95)
  km01 <- depictr:::km_input(tt, st12 - 1, gg, 0.95)
  expect_equal(km12$curve, km01$curve)
  expect_equal(km12$counts, km01$counts)
  expect_equal(unique(km12$curve$surv[km12$curve$group == "b"]), 1)
  expect_error(
    survival_plot(tt, c(0, 1, 0, 1, 1, 2, 1, 2), group = gg),
    "`status` must use the 0/1 (0 = censored) or 1/2 (1 = censored) coding.",
    fixed = TRUE
  )
})

test_that("KM curve extends past the last event to the final follow-up", {
  # Last event at 7, last follow-up (censored) at 20.
  km <- depictr:::km_estimate(c(5, 6, 7, 20), c(1, 1, 1, 0), 0.95)
  expect_equal(max(km$curve$time), 20)
  n <- nrow(km$curve)
  # The tail row is a flat step: survival unchanged from the last event.
  expect_equal(km$curve$surv[n], km$curve$surv[n - 1])
  expect_equal(km$curve$time[n], 20)
})

test_that("survfit input is consistent with the vector path", {
  skip_if_not_installed("survival")
  tt <- c(5, 6, 7, 8, 9, 10)
  ev <- c(1, 0, 1, 1, 0, 1)
  sf <- survival::survfit(survival::Surv(tt, ev) ~ 1)

  km_sf  <- depictr:::km_from_survfit(sf, 0.95)
  km_vec <- depictr:::km_estimate(tt, ev, 0.95)

  # Origin row present in both.
  expect_true(any(km_sf$curve$time == 0))
  expect_equal(km_sf$curve$surv[km_sf$curve$time == 0], 1)

  # Censoring marks recovered (lost before the fix).
  expect_equal(sort(km_sf$censor$time), c(6, 9))
  expect_equal(sort(km_sf$censor$time), sort(km_vec$censor$time))
  expect_true(all(c("time", "surv", "group") %in% names(km_sf$censor)))

  # Survival agrees at every time the two paths share.
  common <- intersect(km_sf$curve$time, km_vec$curve$time)
  s_sf  <- km_sf$curve$surv[match(common, km_sf$curve$time)]
  s_vec <- km_vec$curve$surv[match(common, km_vec$curve$time)]
  expect_equal(s_sf, s_vec)

  expect_s3_class(survival_plot(sf), "ggplot")
})

test_that("grouped survfit input produces per-group curves and marks", {
  skip_if_not_installed("survival")
  set.seed(3)
  n <- 50
  g <- sample(c("a", "b"), n, replace = TRUE)
  tt <- rexp(n, ifelse(g == "b", 0.05, 0.1))
  cc <- runif(n, 0, 30)
  obs <- pmin(tt, cc)
  ev <- as.integer(tt <= cc)
  sf <- survival::survfit(survival::Surv(obs, ev) ~ g)

  km <- depictr:::km_from_survfit(sf, 0.95)
  expect_length(unique(km$curve$group), 2)
  expect_true(nrow(km$censor) > 0)
  expect_setequal(unique(km$censor$group), unique(km$curve$group))
  expect_s3_class(survival_plot(sf), "ggplot")
  expect_s3_class(survival_plot(sf, conf_level = NA), "ggplot")
})
