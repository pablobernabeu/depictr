# survminer-parity additions to survival_plot(): number-at-risk table,
# median-survival guides and a log-rank test. The new statistics are checked
# against the survival package on the first-party clinical_trial dataset, and
# the base-R log-rank fallback is checked against survival::survdiff.

render_ok <- function(p) {
  # Render to a throwaway device and assert it draws with no warnings (so the
  # patchwork composition and every geom actually build).
  tmp <- tempfile(fileext = ".pdf")
  grDevices::pdf(tmp)
  on.exit({
    grDevices::dev.off()
    unlink(tmp)
  })
  withCallingHandlers(
    print(p),
    warning = function(w) stop("render warning: ", conditionMessage(w))
  )
  invisible(TRUE)
}

test_that("new args are off by default and keep the plain ggplot output", {
  data(clinical_trial)
  p <- survival_plot(clinical_trial$time, clinical_trial$event,
                     group = clinical_trial$arm)
  expect_s3_class(p, "ggplot")
  expect_false(inherits(p, "patchwork"))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("risk_table returns a patchwork that renders cleanly", {
  data(clinical_trial)
  p <- survival_plot(clinical_trial$time, clinical_trial$event,
                     group = clinical_trial$arm, risk_table = TRUE)
  expect_s3_class(p, "patchwork")
  expect_true(render_ok(p))
})

test_that("full survminer-style figure (table + median + log-rank) renders", {
  data(clinical_trial)
  p <- survival_plot(clinical_trial$time, clinical_trial$event,
                     group = clinical_trial$arm, risk_table = TRUE,
                     median_line = TRUE, logrank = TRUE, x_lab = "Months")
  expect_s3_class(p, "patchwork")
  expect_true(render_ok(p))
})

test_that("number-at-risk counts match survival::summary.survfit", {
  skip_if_not_installed("survival")
  data(clinical_trial)
  breaks <- c(0, 6, 12, 18, 24, 30, 36)

  counts <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                               clinical_trial$arm, 0.95)$counts
  mine <- depictr:::n_at_risk(counts, breaks)

  sf <- survival::survfit(
    survival::Surv(time, event) ~ arm, data = clinical_trial
  )
  ref <- summary(sf, times = breaks)

  for (g in names(counts)) {
    m <- mine$n_risk[mine$group == g]
    r <- ref$n.risk[grepl(g, ref$strata, fixed = TRUE)]
    expect_equal(m, r)
  }
})

test_that("at-risk via the survfit path also matches summary.survfit", {
  skip_if_not_installed("survival")
  data(clinical_trial)
  breaks <- c(0, 6, 12, 18, 24, 30, 36)
  sf <- survival::survfit(
    survival::Surv(time, event) ~ arm, data = clinical_trial
  )
  km_sf <- depictr:::km_from_survfit(sf, 0.95)
  mine <- depictr:::n_at_risk(km_sf$counts, breaks)
  ref <- summary(sf, times = breaks)
  for (g in names(km_sf$counts)) {
    m <- mine$n_risk[mine$group == g]
    r <- ref$n.risk[grepl(g, ref$strata, fixed = TRUE)]
    expect_equal(m, r)
  }
})

test_that("median survival matches survival::quantile.survfit", {
  skip_if_not_installed("survival")
  data(clinical_trial)
  km <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                           clinical_trial$arm, 0.95)
  meds <- depictr:::km_medians(km$curve, unique(km$curve$group))

  sf <- survival::survfit(
    survival::Surv(time, event) ~ arm, data = clinical_trial
  )
  # quantile.survfit() is an S3 method dispatched via the stats generic.
  ref <- stats::quantile(sf, 0.5)$quantile

  expect_equal(
    meds$median[meds$group == "placebo"],
    as.numeric(ref[grepl("placebo", rownames(ref))])
  )
  # The treatment arm never reaches 0.5: median not estimable (NA) in both.
  expect_true(is.na(meds$median[meds$group == "treatment"]))
  expect_true(is.na(as.numeric(ref[grepl("treatment", rownames(ref))])))
})

test_that("median uses the interpolated KM convention (vs quantile.survfit)", {
  skip_if_not_installed("survival")
  med_of <- function(tt, ev) {
    curve <- depictr:::km_input(tt, ev, NULL, NA)$curve
    depictr:::km_medians(curve, unique(curve$group))$median
  }
  ref_of <- function(tt, ev) {
    sf <- survival::survfit(survival::Surv(tt, ev) ~ 1)
    as.numeric(stats::quantile(sf, 0.5)$quantile)
  }
  cases <- list(
    list(c(5, 6, 7, 8),    c(1, 1, 1, 1)),  # exact 0.5 at 6 -> 6.5
    list(c(5, 6, 7, 8, 9), c(1, 1, 1, 1, 1)),  # strictly below at 7 -> 7
    list(c(2, 4, 6),       c(1, 1, 1)),     # below at 4 -> 4
    list(c(5, 6, 7, 20),   c(1, 1, 1, 0)),  # 0.5 at 6, next event 7 -> 6.5
    list(c(10, 20),        c(1, 0))         # flat at 0.5 to censoring -> 15
  )
  for (cs in cases) {
    expect_equal(med_of(cs[[1]], cs[[2]]), ref_of(cs[[1]], cs[[2]]))
  }
})

test_that("log-rank p-value matches survival::survdiff (survival path)", {
  skip_if_not_installed("survival")
  data(clinical_trial)
  km <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                           clinical_trial$arm, 0.95)
  res <- depictr:::logrank_test(km$counts)

  sd <- survival::survdiff(
    survival::Surv(time, event) ~ arm, data = clinical_trial
  )
  ref_p <- stats::pchisq(sd$chisq, length(sd$n) - 1, lower.tail = FALSE)

  expect_equal(res$method, "survival::survdiff")
  expect_equal(res$chisq, unname(sd$chisq), tolerance = 1e-6)
  expect_equal(res$p, ref_p, tolerance = 1e-6)
})

test_that("base-R log-rank fallback matches survival::survdiff", {
  skip_if_not_installed("survival")
  data(clinical_trial)
  km <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                           clinical_trial$arm, 0.95)
  # base_logrank() is the package-free fallback; it must agree with survdiff.
  res <- depictr:::base_logrank(km$counts)

  sd <- survival::survdiff(
    survival::Surv(time, event) ~ arm, data = clinical_trial
  )
  ref_p <- stats::pchisq(sd$chisq, length(sd$n) - 1, lower.tail = FALSE)

  expect_equal(res$chisq, unname(sd$chisq), tolerance = 1e-6)
  expect_equal(res$p, ref_p, tolerance = 1e-6)
  expect_equal(res$df, 1L)
})

test_that("log-rank fallback handles three groups (vs survdiff)", {
  skip_if_not_installed("survival")
  set.seed(7)
  n <- 240
  g <- sample(c("a", "b", "c"), n, replace = TRUE)
  rate <- c(a = 0.04, b = 0.08, c = 0.12)[g]
  tt <- stats::rexp(n, rate)
  cc <- stats::runif(n, 0, 30)
  obs <- pmin(tt, cc)
  ev <- as.integer(tt <= cc)

  km <- depictr:::km_input(obs, ev, g, 0.95)
  res <- depictr:::base_logrank(km$counts)

  sd <- survival::survdiff(survival::Surv(obs, ev) ~ g)
  ref_p <- stats::pchisq(sd$chisq, length(sd$n) - 1, lower.tail = FALSE)

  expect_equal(res$df, 2L)
  expect_equal(res$chisq, unname(sd$chisq), tolerance = 1e-6)
  expect_equal(res$p, ref_p, tolerance = 1e-6)
})

test_that("log-rank subtitle is a single readable ASCII string", {
  data(clinical_trial)
  km <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                           clinical_trial$arm, 0.95)
  lab <- depictr:::logrank_label(km$counts)
  expect_length(lab, 1L)
  expect_match(lab, "^Log-rank chi-sq\\(1\\)")
  # ASCII only (Windows mbcs PDF devices choke on a Unicode chi).
  expect_false(grepl("[^ -~]", lab))
})

test_that("built curve panel carries the median guide and subtitle", {
  data(clinical_trial)
  p <- survival_plot(clinical_trial$time, clinical_trial$event,
                     group = clinical_trial$arm, median_line = TRUE,
                     logrank = TRUE)
  expect_match(p$labels$subtitle, "Log-rank")
  b <- ggplot2::ggplot_build(p)
  segs <- Filter(
    function(d) all(c("x", "xend", "yend") %in% names(d)) &&
      all(d$yend == 0.5, na.rm = TRUE) && nrow(d) > 0,
    b$data
  )
  xs <- unique(unlist(lapply(segs, function(d) d$x)))
  expect_true(any(abs(xs - 18.2) < 1e-6))  # placebo median
})

test_that("single-group plot supports the new annotations", {
  data(clinical_trial)
  p <- survival_plot(clinical_trial$time, clinical_trial$event,
                     risk_table = TRUE, median_line = TRUE, logrank = TRUE)
  # log-rank needs >= 2 groups, so no subtitle here, but it must not error.
  expect_s3_class(p, "patchwork")
  expect_true(render_ok(p))
})

test_that("custom risk_breaks are honoured", {
  data(clinical_trial)
  brks <- c(0, 12, 24, 36)
  counts <- depictr:::km_input(clinical_trial$time, clinical_trial$event,
                               clinical_trial$arm, 0.95)$counts
  tab <- depictr:::n_at_risk(counts, brks)
  expect_setequal(unique(tab$time), brks)
})
