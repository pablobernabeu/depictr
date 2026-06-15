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

test_that("logical status is accepted and invalid coding errors", {
  km_lgl <- depictr:::km_estimate(c(5, 6, 7, 8), c(TRUE, TRUE, TRUE, TRUE), 0.95)
  expect_equal(km_lgl$curve$surv, c(1, 0.75, 0.5, 0.25, 0))
  expect_error(depictr:::km_estimate(c(1, 2), c(3, 5), 0.95), "0/1")
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
