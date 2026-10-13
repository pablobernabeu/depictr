# The confidence limits survival_plot() draws: the log-log default, the log and
# plain transforms, and the requested level, on the vector and survfit routes.
# Each is checked against survival::survfit() at the same level and transform.

limit_types <- c("log-log", "log", "plain")
lung_times <- c(60, 180, 365, 540, 730, 900)

# The limits in force at `times` on a drawn step curve: those of the last row
# at or before each time.
limits_at <- function(curve, times, group = NULL) {
  if (!is.null(group)) curve <- curve[curve$group == group, , drop = FALSE]
  curve <- curve[order(curve$time), , drop = FALSE]
  i <- findInterval(times, curve$time)
  cbind(lower = curve$lower[i], upper = curve$upper[i])
}

# survfit's own limits at `times`, for one stratum when `stratum` names one.
survfit_limits <- function(fit, times, stratum = NULL) {
  s <- summary(fit, times = times)
  keep <- if (is.null(stratum)) TRUE else s$strata == stratum
  cbind(lower = s$lower[keep], upper = s$upper[keep])
}

test_that("vector input draws survfit's limits for each transform and level", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  for (type in limit_types) {
    for (level in c(0.95, 0.9, 0.5)) {
      p <- survival_plot(lung$time, lung$status, conf_level = level,
                         conf_type = type)
      ref <- survfit_limits(
        survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                          conf.type = type, conf.int = level),
        lung_times
      )
      expect_equal(limits_at(p$data, lung_times), ref, tolerance = 1e-10,
                   label = paste(type, level))
    }
  }
})

test_that("a survfit object's limits are recomputed at the requested level", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  # survfit's defaults, a 95% log interval, are what the object stores.
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung)
  for (type in limit_types) {
    for (level in c(0.95, 0.9, 0.5)) {
      p <- survival_plot(sf, conf_level = level, conf_type = type)
      ref <- survfit_limits(
        survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                          conf.type = type, conf.int = level),
        lung_times
      )
      expect_equal(limits_at(p$data, lung_times), ref, tolerance = 1e-10,
                   label = paste(type, level))
    }
  }
  # The level used to be ignored, so 90% and 50% drew the stored 95% band.
  expect_false(isTRUE(all.equal(survival_plot(sf, conf_level = 0.9)$data$lower,
                                survival_plot(sf, conf_level = 0.5)$data$lower)))
})

test_that("both routes default to log-log limits at 95%", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  ref <- survfit_limits(
    survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                      conf.type = "log-log"),
    lung_times
  )
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung)
  expect_equal(limits_at(survival_plot(lung$time, lung$status)$data, lung_times),
               ref, tolerance = 1e-10)
  expect_equal(limits_at(survival_plot(sf)$data, lung_times), ref,
               tolerance = 1e-10)
})

test_that("each group's limits match its stratum on both routes", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  times <- c(60, 180, 365, 540, 730)
  fit <- survival::survfit(survival::Surv(time, status) ~ sex, data = lung,
                           conf.type = "log-log", conf.int = 0.9)
  p_vec <- survival_plot(lung$time, lung$status, group = lung$sex,
                         conf_level = 0.9)
  p_sf <- survival_plot(
    survival::survfit(survival::Surv(time, status) ~ sex, data = lung),
    conf_level = 0.9
  )
  for (sex in c("1", "2")) {
    ref <- survfit_limits(fit, times, stratum = paste0("sex=", sex))
    expect_equal(limits_at(p_vec$data, times, group = sex), ref,
                 tolerance = 1e-10)
    expect_equal(limits_at(p_sf$data, times, group = paste0("sex=", sex)), ref,
                 tolerance = 1e-10)
  }
})

test_that("curves from a Cox model and from clustered data are recomputed", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  times <- c(60, 180, 365, 540, 730)
  # survfit.coxph stores the standard error of the cumulative hazard, as
  # survfit does for a Kaplan-Meier curve.
  cox <- survival::coxph(survival::Surv(time, status) ~ age, data = lung)
  p <- survival_plot(survival::survfit(cox), conf_level = 0.9)
  ref <- survfit_limits(
    survival::survfit(cox, conf.type = "log-log", conf.int = 0.9), times
  )
  expect_equal(limits_at(p$data, times), ref, tolerance = 1e-10)
  # A robust variance over clusters is stored on the survival scale
  # (logse = FALSE), and survfit divides it by the estimate for its own limits.
  sr <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                          cluster = inst, robust = TRUE)
  p <- survival_plot(sr, conf_level = 0.9)
  ref <- survfit_limits(
    survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                      cluster = inst, robust = TRUE, conf.type = "log-log",
                      conf.int = 0.9),
    times
  )
  expect_equal(limits_at(p$data, times), ref, tolerance = 1e-10)
  # The same standard errors give the same limits on either scale.
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung)
  on_surv_scale <- sf
  on_surv_scale$std.err <- sf$std.err * sf$surv
  on_surv_scale$logse <- FALSE
  expect_equal(survival_plot(on_surv_scale, conf_level = 0.9)$data,
               survival_plot(sf, conf_level = 0.9)$data, tolerance = 1e-12)
})

test_that("stored limits are drawn, with a warning, when no standard errors", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung)
  sf$std.err <- NULL
  expect_warning(
    p <- survival_plot(sf, conf_level = 0.9),
    "stores no standard errors"
  )
  # The limits drawn are the 95% log limits the object holds.
  expect_equal(
    limits_at(p$data, lung_times),
    survfit_limits(survival::survfit(survival::Surv(time, status) ~ 1,
                                     data = lung), lung_times),
    tolerance = 1e-10
  )
  # Asking for what the object holds draws it without a warning.
  expect_no_warning(survival_plot(sf, conf_level = 0.95, conf_type = "log"))
  # Standard errors whose scale the object does not record are not used.
  unscaled <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung)
  unscaled$logse <- NULL
  expect_warning(survival_plot(unscaled, conf_level = 0.9),
                 "does not record the scale of its standard errors")
})

test_that("peto and modified lower limits are kept, with a warning", {
  # survfit's conf.lower widens the lower limit by rules of its own, which the
  # usual formulas would silently replace.
  skip_if_not_installed("survival")
  lung <- survival::lung
  for (rule in c("peto", "modified")) {
    sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                            conf.lower = rule)
    expect_warning(p <- survival_plot(sf), "conf.lower", label = rule)
    # Every row draws the 95% log limits the object holds.
    expect_equal(limits_at(p$data, sf$time),
                 cbind(lower = sf$lower, upper = sf$upper),
                 tolerance = 1e-12, label = rule)
    expect_no_warning(survival_plot(sf, conf_level = 0.95, conf_type = "log"))
  }
})

test_that("an object made without limits gets them from its standard errors", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                          conf.type = "none")
  p <- survival_plot(sf, conf_level = 0.9, conf_type = "log")
  ref <- survfit_limits(
    survival::survfit(survival::Surv(time, status) ~ 1, data = lung,
                      conf.int = 0.9),
    lung_times
  )
  expect_equal(limits_at(p$data, lung_times), ref, tolerance = 1e-10)
  expect_false("lower" %in% names(survival_plot(sf, conf_level = NA)$data))
})

test_that("conf_level is a single level strictly between 0 and 1, or NA", {
  # A level such as 95, meant as a percentage, has no normal quantile, and the
  # band would be drawn at 1 throughout.
  levels <- list(95, 1.5, 1, 0, -0.2, Inf, "0.95", c(0.9, 0.95), NULL)
  for (level in levels) {
    expect_error(survival_plot(c(1, 2, 3), c(1, 0, 1), conf_level = level),
                 "strictly between 0 and 1", label = deparse(level))
  }
  skip_if_not_installed("survival")
  sf <- survival::survfit(survival::Surv(c(1, 2, 3), c(1, 0, 1)) ~ 1)
  expect_error(survival_plot(sf, conf_level = 95), "strictly between 0 and 1")
})

test_that("limits are 1 at survival 1 and hold the last step at survival 0", {
  # Censoring before the first event, and a last event that leaves nobody at
  # risk. The plain limits used to be NaN where the curve reached zero, so the
  # band stopped one step early, and the log-log formula is 0/0 at survival 1.
  tt <- c(1, 2, 3, 4, 5)
  st <- c(0, 1, 0, 1, 1)
  for (type in limit_types) {
    curve <- depictr:::km_estimate(tt, st, 0.95, type)$curve
    expect_false(anyNA(curve$lower), label = type)
    expect_false(anyNA(curve$upper), label = type)
    expect_equal(curve$surv[nrow(curve)], 0)
    expect_equal(curve$lower[nrow(curve)], curve$lower[nrow(curve) - 1])
    expect_equal(curve$upper[nrow(curve)], curve$upper[nrow(curve) - 1])
    expect_equal(unlist(curve[1, c("lower", "upper")], use.names = FALSE),
                 c(1, 1))
  }
  skip_if_not_installed("survival")
  for (type in limit_types) {
    curve <- survival_plot(survival::survfit(survival::Surv(tt, st) ~ 1),
                           conf_type = type)$data
    expect_false(anyNA(curve$lower), label = type)
    expect_false(anyNA(curve$upper), label = type)
    # The censoring at time 1 comes before any event, where survival is 1.
    expect_equal(unlist(curve[curve$time == 1, c("lower", "upper")],
                        use.names = FALSE), c(1, 1))
    expect_equal(curve$lower[nrow(curve)], curve$lower[nrow(curve) - 1])
    # The two routes draw the same limits.
    vec <- survival_plot(tt, st, conf_type = type)$data
    expect_equal(limits_at(curve, 0:5), limits_at(vec, 0:5))
  }
})

test_that("conf_type is one of the three transforms", {
  expect_error(survival_plot(c(1, 2, 3), c(1, 0, 1), conf_type = "logit"),
               "should be one of")
  # conf_level = NA still leaves the limits out on both routes.
  expect_false("lower" %in% names(
    survival_plot(c(1, 2, 3), c(1, 0, 1), conf_level = NA)$data
  ))
  skip_if_not_installed("survival")
  sf <- survival::survfit(survival::Surv(c(1, 2, 3), c(1, 0, 1)) ~ 1)
  expect_false("lower" %in% names(survival_plot(sf, conf_level = NA)$data))
})
