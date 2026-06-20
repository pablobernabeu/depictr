# Tier-2 colour/scale/quality changes for the classification plots -----------
# Covers: every reference/baseline line drawn at depictr_reference(); every
# single-series curve and annotation drawn at depictr_brand(); the confusion
# matrix fill sourced from the canonical sequential palette (no ad-hoc hex);
# and the new per-bin Wilson confidence intervals on calibration_plot().

# A small, well-separated binary problem reused across the plot tests.
make_glm <- function(n = 200, seed = 1) {
  withr::local_seed(seed)
  x <- rnorm(n)
  y <- factor(ifelse(plogis(1.2 * x) > runif(n), "yes", "no"))
  glm(y ~ x, data = data.frame(x = x, y = y), family = binomial)
}

test_that("reference and baseline lines use depictr_reference(), not ad-hoc grey", {
  g <- make_glm()

  layer_colours <- function(p) lapply(ggplot2::ggplot_build(p)$data,
                                      function(d) unique(d$colour))

  # ROC: diagonal reference line (first layer) is the neutral reference grey.
  roc <- layer_colours(roc_curve_plot(g))
  expect_identical(roc[[1]], depictr_reference())

  # PR: no-skill baseline hline.
  pr <- layer_colours(pr_curve_plot(g))
  expect_identical(pr[[1]], depictr_reference())

  # Gain: both the no-model diagonal and the perfect-model envelope.
  gain <- layer_colours(gain_plot(g))
  expect_identical(gain[[1]], depictr_reference())
  expect_identical(gain[[2]], depictr_reference())

  # Lift: the no-model baseline at 1.
  lift <- layer_colours(lift_plot(g))
  expect_identical(lift[[1]], depictr_reference())

  # Calibration: the diagonal (perfect-calibration) line.
  calib <- layer_colours(calibration_plot(g, bins = 6))
  expect_identical(calib[[1]], depictr_reference())
})

test_that("single-series curves and annotations use depictr_brand()", {
  g <- make_glm()

  # The curve in each plot is drawn in brand blue by default.
  curve_colour <- function(p, layer) {
    unique(ggplot2::ggplot_build(p)$data[[layer]]$colour)
  }
  expect_identical(curve_colour(roc_curve_plot(g), 2), depictr_brand())
  expect_identical(curve_colour(pr_curve_plot(g), 2), depictr_brand())
  expect_identical(curve_colour(gain_plot(g), 3), depictr_brand())
  expect_identical(curve_colour(lift_plot(g), 2), depictr_brand())

  # The AUC / AP annotation text is the brand blue, not the old off-palette
  # "#0a3d62" dark blue.
  roc_p <- roc_curve_plot(g)
  ann <- roc_p$layers[[length(roc_p$layers)]]
  expect_identical(ann$aes_params$colour, depictr_brand())
  expect_false(identical(ann$aes_params$colour, "#0a3d62"))

  pr_p <- pr_curve_plot(g)
  ann2 <- pr_p$layers[[length(pr_p$layers)]]
  expect_identical(ann2$aes_params$colour, depictr_brand())
})

test_that("confusion_matrix_plot() fills come from the sequential palette", {
  g <- make_glm()
  b <- ggplot2::ggplot_build(confusion_matrix_plot(g, threshold = 0.5))

  seq_pal <- depictr_palette(type = "sequential")
  tile <- b$data[[1]]
  fills <- toupper(tile$fill)

  # The fills are exactly what the canonical sequential ramp produces for the
  # rescaled shade values, confirming the scale is sourced from the palette and
  # not from ad-hoc hex literals.
  expected <- toupper(scales::gradient_n_pal(seq_pal)(
    scales::rescale(b$plot$data$shade)
  ))
  expect_setequal(fills, expected)

  # The fill range spans the canonical sequential endpoints (pale low to dark
  # high), and the old hand-picked endpoint #eaf2f8 is gone.
  expect_true(toupper(seq_pal[1]) %in% fills)
  expect_true(toupper(seq_pal[length(seq_pal)]) %in% fills)
  expect_false("#EAF2F8" %in% fills)

  # Contrast-text logic is preserved: white on the darker (above-median) cells,
  # dark grey on the lighter ones.
  txt <- unique(b$data[[2]]$colour)
  expect_setequal(txt, c("white", "grey15"))
})

test_that("calibration_plot() adds per-bin Wilson confidence intervals", {
  g <- make_glm(n = 300, seed = 7)
  p <- calibration_plot(g, bins = 8)
  b <- ggplot2::ggplot_build(p)

  # An error-bar layer is present (abline, errorbar, line, point => 4 layers).
  expect_length(b$data, 4L)
  eb <- b$data[[2]]
  expect_true(all(c("ymin", "ymax") %in% names(eb)))
  expect_identical(unique(eb$colour), depictr_brand())

  # The interval brackets the observed proportion and stays inside [0, 1].
  obs <- p$data$observed
  expect_true(all(eb$ymin <= obs + 1e-9))
  expect_true(all(obs <= eb$ymax + 1e-9))
  expect_true(all(eb$ymin >= 0) && all(eb$ymax <= 1))

  # conf_level = NA omits the intervals (one fewer layer).
  p0 <- calibration_plot(g, bins = 8, conf_level = NA)
  expect_length(ggplot2::ggplot_build(p0)$data, 3L)
})

test_that("wilson_interval() matches the prop.test Wilson interval", {
  # prop.test(correct = FALSE) is the Wilson score interval; use it as an
  # independent oracle across ordinary and boundary counts.
  for (kn in list(c(5, 20), c(0, 10), c(10, 10), c(1, 100), c(37, 64))) {
    k <- kn[1]; n <- kn[2]
    ci <- wilson_interval(k, n, 0.95)
    ref <- suppressWarnings(stats::prop.test(k, n, correct = FALSE)$conf.int)
    expect_equal(c(ci$lower, ci$upper), as.numeric(ref), tolerance = 1e-6)
  }

  # Vectorised over bins, and clamped to [0, 1] at the boundaries.
  v <- wilson_interval(c(0, 5, 10), c(10, 20, 10), 0.95)
  expect_length(v$lower, 3L)
  expect_equal(v$lower[1], 0)
  expect_equal(v$upper[3], 1)
})

test_that("affected classification plots build without warnings", {
  g <- make_glm()
  for (p in list(roc_curve_plot(g), calibration_plot(g, bins = 6),
                 confusion_matrix_plot(g, threshold = 0.5),
                 confusion_matrix_plot(g, normalise = "row"),
                 pr_curve_plot(g), gain_plot(g), lift_plot(g))) {
    expect_no_warning(ggplot2::ggplot_build(p))
  }
})
