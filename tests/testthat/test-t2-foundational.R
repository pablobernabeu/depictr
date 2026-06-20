# Tier-2 foundational changes ------------------------------------------------

test_that("internal colour accessors are the single source of truth", {
  expect_identical(depictr_brand(), "#005b96")
  expect_identical(depictr_brand(), depictr_palette(1)[1])
  expect_identical(depictr_accent(), "#d55e00")
  expect_identical(depictr_reference(), "grey60")
})

test_that("scale_colour_depictr() builds with no scale_name deprecation warning", {
  p <- ggplot2::ggplot(
    crop_yield,
    ggplot2::aes(rainfall, yield, colour = treatment)
  ) +
    ggplot2::geom_point() +
    scale_colour_depictr()

  expect_no_warning(ggplot2::ggplot_build(p))
  # NA values fall back to the deliberately distinct grey, not palette grey.
  sc <- scale_colour_depictr()
  expect_identical(sc$na.value, "grey80")
  expect_false(identical(sc$na.value, "#999999"))
})

test_that("scale_fill_depictr() builds with no deprecation warning and honours overrides", {
  d <- data.frame(g = factor(letters[1:3]), v = 1:3)
  p <- ggplot2::ggplot(d, ggplot2::aes(g, v, fill = g)) +
    ggplot2::geom_col() +
    scale_fill_depictr()
  expect_no_warning(ggplot2::ggplot_build(p))

  # Palette override is respected.
  reds <- function(n) rep("#ff0000", n)
  p2 <- ggplot2::ggplot(d, ggplot2::aes(g, v, fill = g)) +
    ggplot2::geom_col() +
    scale_fill_depictr(palette = reds)
  built <- ggplot2::ggplot_build(p2)$data[[1]]
  expect_true(all(built$fill == "#ff0000"))
})

test_that("format_terms() keeps NA as NA and strips prefixes per component", {
  out <- format_terms(c("(Intercept)", NA, "b_x:b_y"))
  expect_equal(out[1], "Intercept")
  expect_true(is.na(out[2]))
  expect_false(any(out == "NA", na.rm = TRUE))
  # Both Bayesian prefixes stripped, interaction rendered with the times sign.
  expect_equal(out[3], "x × y")

  # Per-component stripping with the colon (unchanged) renderer.
  expect_equal(
    format_terms("b_a:bs_b:b_c", interaction = "colon"),
    "a:b:c"
  )
  # NA survives the wrap path too.
  wrapped <- format_terms(c(NA, "some long label"), wrap = 4)
  expect_true(is.na(wrapped[1]))
})

test_that("coefficient_plot() renders horizontal error bars without geom_errorbarh warning", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  p <- coefficient_plot(fit)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  # Horizontal bars: xmin/xmax span the interval, the y position is constant
  # within each bar (i.e. bars run along x at a fixed y).
  eb <- b$data[[2]]
  expect_true(all(c("xmin", "xmax", "y") %in% names(eb)))
  expect_true(all(eb$xmin <= eb$xmax, na.rm = TRUE))
})

test_that("compare_models() renders horizontal error bars without geom_errorbarh warning", {
  m1 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  m2 <- lm(yield ~ rainfall + fertiliser,
           data = crop_yield[crop_yield$treatment == "standard", ])
  p <- compare_models(A = m1, B = m2)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  eb <- b$data[[2]]
  expect_true(all(c("xmin", "xmax") %in% names(eb)))
})

test_that("random_effects_plot() renders horizontal error bars without geom_errorbarh warning", {
  re <- data.frame(
    level = paste0("G", 1:8),
    estimate = sort(rnorm(8)),
    std.error = runif(8, 0.2, 0.5)
  )
  p <- random_effects_plot(re)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  eb <- b$data[[2]]
  expect_true(all(c("xmin", "xmax") %in% names(eb)))
})
