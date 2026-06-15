# Tests for the estimation / effect-size plot and the differences = TRUE option
# of group_comparison_plot(). The statistics (bootstrap percentile CI and the
# standardised effect sizes) are checked against independent computations.

build_ok <- function(p) {
  # A patchwork stores its panels as indexable elements; build each so any
  # geometry-stage error surfaces. (Index, don't `for ... in`: a patchwork is
  # an S7 object and is not directly iterable.)
  for (i in seq_len(length(p))) invisible(ggplot2::ggplot_build(p[[i]]))
  invisible(TRUE)
}

test_that("estimation_plot() returns a patchwork that builds (two groups)", {
  set.seed(1)
  p <- estimation_plot(lexical_decision, RT, condition)
  expect_s3_class(p, "patchwork")
  expect_silent(build_ok(p))
  diffs <- attr(p, "differences")
  expect_s3_class(diffs, "data.frame")
  expect_equal(nrow(diffs), 1L)
  expect_setequal(c("group", "reference", "diff", "lower", "upper",
                    "cohens_d", "hedges_g"), names(diffs))
})

test_that("estimation_plot() compares >2 groups against the reference", {
  set.seed(2)
  p <- estimation_plot(wellbeing_survey, life_satisfaction, region,
                       reference = "North")
  expect_s3_class(p, "patchwork")
  expect_silent(build_ok(p))
  diffs <- attr(p, "differences")
  # One row per non-reference group, all referenced to North.
  expect_equal(nrow(diffs), 3L)
  expect_true(all(diffs$reference == "North"))
  expect_false("North" %in% as.character(diffs$group))
})

test_that("the reported mean difference equals the raw difference of means", {
  set.seed(3)
  p <- estimation_plot(crop_yield, yield, treatment, reference = "standard")
  diffs <- attr(p, "differences")
  d <- crop_yield[!is.na(crop_yield$yield), ]
  md <- mean(d$yield[d$treatment == "enhanced"]) -
    mean(d$yield[d$treatment == "standard"])
  expect_equal(diffs$diff[diffs$group == "enhanced"], md)
})

test_that("bootstrap CI matches the boot package (percentile method)", {
  skip_if_not_installed("boot")
  set.seed(42)
  treat <- rnorm(40, 10, 3)
  ref <- rnorm(35, 8, 2.5)

  set.seed(123)
  dep <- depictr:::boot_diff_ci(treat, ref, conf_level = 0.95, n_boot = 20000)

  df <- data.frame(val = c(treat, ref),
                   grp = c(rep("t", length(treat)), rep("r", length(ref))))
  stat <- function(d, idx) {
    dd <- d[idx, ]
    mean(dd$val[dd$grp == "t"]) - mean(dd$val[dd$grp == "r"])
  }
  set.seed(99)
  bb <- boot::boot(df, stat, R = 20000, strata = factor(df$grp))
  ci <- boot::boot.ci(bb, type = "perc", conf = 0.95)$percent[4:5]

  # Two independent 20k-resample bootstraps: bounds agree to Monte-Carlo noise.
  # The interval is ~2.7 wide, so 0.1 absolute is < 4% of its width.
  expect_lt(abs(unname(dep[1]) - unname(ci[1])), 0.1)
  expect_lt(abs(unname(dep[2]) - unname(ci[2])), 0.1)
})

test_that("bootstrap percentile CI has nominal coverage", {
  set.seed(7)
  truth <- 2
  nsim <- 500
  cover <- 0
  for (i in seq_len(nsim)) {
    treat <- rnorm(30, 10, 3)
    ref <- rnorm(30, 8, 3)
    ci <- depictr:::boot_diff_ci(treat, ref, 0.95, 1500)
    if (ci[1] <= truth && truth <= ci[2]) cover <- cover + 1
  }
  expect_equal(cover / nsim, 0.95, tolerance = 0.04)
})

test_that("bootstrap CI is reproducible under a fixed seed", {
  set.seed(5)
  a <- depictr:::boot_diff_ci(rnorm(20), rnorm(20), 0.95, 3000)
  set.seed(5)
  b <- depictr:::boot_diff_ci(rnorm(20), rnorm(20), 0.95, 3000)
  expect_identical(a, b)
})

test_that("Cohen's d and Hedges' g equal their formulae", {
  set.seed(11)
  treat <- rnorm(40, 10, 3)
  ref <- rnorm(35, 8, 2.5)
  es <- depictr:::effsize_diff(treat, ref)

  n1 <- length(treat)
  n2 <- length(ref)
  sp <- sqrt(((n1 - 1) * var(treat) + (n2 - 1) * var(ref)) / (n1 + n2 - 2))
  d_formula <- (mean(treat) - mean(ref)) / sp
  j <- 1 - 3 / (4 * (n1 + n2) - 9)

  expect_equal(es[["cohens_d"]], d_formula)
  expect_equal(es[["hedges_g"]], j * d_formula)
  # The small-sample correction shrinks |g| relative to |d|.
  expect_lt(abs(es[["hedges_g"]]), abs(es[["cohens_d"]]))
})

test_that("effect-size sign follows (treatment - reference)", {
  # Reference has the larger mean -> a negative effect size.
  es <- depictr:::effsize_diff(c(1, 2, 3, 4), c(10, 11, 12, 13))
  expect_lt(es[["cohens_d"]], 0)
})

test_that("invalid arguments error early", {
  expect_error(estimation_plot(crop_yield, treatment, treatment), "numeric")
  expect_error(estimation_plot(crop_yield, yield, treatment,
                               reference = "nope"), "reference")
  expect_error(
    estimation_plot(crop_yield, yield, treatment, n_boot = -1), "n_boot"
  )
  expect_error(
    estimation_plot(subset(crop_yield, treatment == "standard"),
                    yield, treatment),
    "at least two"
  )
})

test_that("a group with n < 2 warns but still yields a buildable plot", {
  small <- data.frame(y = c(1, 2, 3, 5, 9), g = c("a", "a", "a", "a", "b"))
  # The singleton group "b" trips two warnings: no t-interval (upper panel) and
  # no bootstrap interval (lower panel).
  expect_warning(
    expect_warning(estimation_plot(small, y, g), "confidence interval"),
    "bootstrap interval"
  )
  p <- suppressWarnings(estimation_plot(small, y, g))
  expect_s3_class(p, "patchwork")
  expect_silent(build_ok(p))
  diffs <- attr(p, "differences")
  # No bootstrap interval for the singleton group's difference.
  expect_true(is.na(diffs$lower) && is.na(diffs$upper))
})

test_that("group_comparison_plot() is unchanged by default", {
  p <- group_comparison_plot(crop_yield, yield, treatment)
  expect_s3_class(p, "ggplot")
  expect_false(inherits(p, "patchwork"))
})

test_that("group_comparison_plot(differences = TRUE) yields an estimation plot", {
  set.seed(1)
  p <- group_comparison_plot(crop_yield, yield, treatment, differences = TRUE)
  expect_s3_class(p, "patchwork")
  expect_silent(build_ok(p))
  expect_s3_class(attr(p, "differences"), "data.frame")

  # Forwarding string column names through {{ }} works too.
  set.seed(1)
  p2 <- group_comparison_plot(crop_yield, "yield", "treatment",
                              differences = TRUE)
  expect_s3_class(p2, "patchwork")
})

test_that("group_colours() honours a supplied palette", {
  cols <- depictr:::group_colours(c("a", "b", "c"), palette = c("#111111"))
  expect_equal(unname(cols), rep("#111111", 3))
  expect_named(cols, c("a", "b", "c"))
})
