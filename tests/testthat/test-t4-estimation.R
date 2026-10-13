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

  # String column names are forwarded too.
  set.seed(1)
  p2 <- group_comparison_plot(crop_yield, "yield", "treatment",
                              differences = TRUE)
  expect_s3_class(p2, "patchwork")
})

# ---- where each difference is drawn ------------------------------------------
# A reader matches a difference to its group by the column it sits in, so each
# group must take the same place across the width of both panels. patchwork
# gives the stacked panels the same width. A column's place is therefore read
# from each built panel as a fraction of its x range, from 0 at the left to 1 at
# the right.

column_positions <- function(panel) {
  x <- ggplot2::ggplot_build(panel)$layout$panel_params[[1]]$x
  stats::setNames(x$break_positions(), x$get_limits())
}

drawn_positions <- function(panel) {
  built <- ggplot2::ggplot_build(panel)
  geoms <- vapply(panel$layers, function(l) class(l$geom)[1], character(1))
  x <- as.numeric(built$data[[which(geoms == "GeomPointrange")]]$x)
  x_range <- built$layout$panel_params[[1]]$x.range
  (x - x_range[1]) / diff(x_range)
}

test_that("each difference is drawn beneath its own group", {
  set.seed(2)
  p <- estimation_plot(wellbeing_survey, life_satisfaction, region,
                       reference = "North", n_boot = 200)
  top <- column_positions(p[[1]])
  expect_named(top, c("North", "East", "South", "West"))
  # Every group keeps its column in the lower panel, the reference included.
  expect_equal(column_positions(p[[2]])[names(top)], top)
  diffs <- attr(p, "differences")
  expect_equal(drawn_positions(p[[2]]), unname(top[as.character(diffs$group)]))
  # The reference's column below is left empty, with no label.
  labels <- ggplot2::ggplot_build(p[[2]])$layout$panel_params[[1]]$x$get_labels()
  expect_equal(labels, c("", "East", "South", "West"))
})

test_that("with two groups the difference sits beneath the second group", {
  set.seed(1)
  p <- estimation_plot(lexical_decision, RT, condition, n_boot = 200)
  top <- column_positions(p[[1]])
  expect_equal(column_positions(p[[2]])[names(top)], top)
  expect_equal(drawn_positions(p[[2]]), unname(top["unrelated"]))
})

test_that("group_comparison_plot(differences = TRUE) keeps the columns too", {
  set.seed(1)
  p <- group_comparison_plot(crop_yield, yield, treatment, differences = TRUE,
                             n_boot = 200)
  top <- column_positions(p[[1]])
  expect_equal(column_positions(p[[2]])[names(top)], top)
  expect_equal(drawn_positions(p[[2]]), unname(top["enhanced"]))
})

test_that("the caption names the bootstrap behind the intervals", {
  # The Python twin pins the same text (tests/test_estimation_tables.py).
  set.seed(1)
  p <- estimation_plot(crop_yield, yield, treatment)
  expect_equal(p[[2]]$labels$caption, "Bootstrap 95% CI (5,000 resamples)")
  # A round number of resamples is written out in full, as in Python. format()
  # alone would give 1e+05. A group of one skips the bootstrap, which keeps the
  # test quick, and its warnings are tested above.
  tiny <- data.frame(y = c(1, 2, 3), g = c("a", "a", "b"))
  p <- suppressWarnings(estimation_plot(tiny, y, g, n_boot = 1e5))
  expect_equal(p[[2]]$labels$caption, "Bootstrap 95% CI (100,000 resamples)")
})

test_that("group_colours() honours a supplied palette", {
  cols <- depictr:::group_colours(c("a", "b", "c"), palette = c("#111111"))
  expect_equal(unname(cols), rep("#111111", 3))
  expect_named(cols, c("a", "b", "c"))
})

# ---- a fresh R session ------------------------------------------------------
# The two panels are composed by patchwork, whose plot operators exist only once
# its namespace is loaded, and depictr imports from patchwork so that
# library(depictr) loads it. Within a test run, patchwork is always loaded
# already: load_all() loads every package in Imports, and under R CMD check the
# earlier test files use it. That is how the failure went unseen, so the second
# test starts a separate R process.

test_that("depictr imports from patchwork, so loading depictr loads it", {
  expect_true("patchwork" %in% names(getNamespaceImports("depictr")))
})

test_that("estimation plots build in a fresh R session", {
  skip_on_cran()
  skip_if_not_installed("callr")
  # The child process loads the installed depictr. Under devtools::test() that
  # copy may predate the source under test, so this runs only under R CMD
  # check, where the installed copy is the one being checked.
  skip_if_not(testthat::is_checking())

  # Each child prints its plot, as the documented example does at the console,
  # so that both panels are built and drawn there.
  fresh <- callr::r(function() {
    grDevices::pdf(NULL)
    library(depictr)
    patchwork_loaded <- "patchwork" %in% loadedNamespaces()
    p <- estimation_plot(lexical_decision, RT, condition, n_boot = 50)
    print(p)
    c(patchwork_loaded = patchwork_loaded,
      is_patchwork = inherits(p, "patchwork"))
  })
  expect_true(fresh[["patchwork_loaded"]])
  expect_true(fresh[["is_patchwork"]])

  # group_comparison_plot(differences = TRUE) forwards to estimation_plot() and
  # failed the same way. It gets a process of its own, so that it is the first
  # call in that session.
  expect_true(callr::r(function() {
    grDevices::pdf(NULL)
    library(depictr)
    p <- group_comparison_plot(crop_yield, yield, treatment,
                               differences = TRUE, n_boot = 50)
    print(p)
    inherits(p, "patchwork")
  }))
})
