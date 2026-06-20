# Tier-2 reporting changes ---------------------------------------------------

test_that("arrange_plots() title uses the canonical brand colour", {
  p1 <- explore_distribution(crop_yield, yield)
  p2 <- scatter_trend(crop_yield, fertiliser, yield)
  combined <- arrange_plots(p1, p2, ncol = 2, title = "Crop yield",
                            tag_levels = "A")

  # The patchwork annotation theme carries the title colour; it must be the
  # single-source-of-truth brand blue, not a stray hex literal.
  title_col <- combined$patches$annotation$theme$plot.title$colour
  expect_identical(title_col, depictr_brand())
  expect_identical(title_col, "#005b96")
})

test_that(".relative_luminance() is vectorised and matches WCAG anchors", {
  # Pure black and white anchor the [0, 1] range.
  expect_equal(.relative_luminance("#000000"), 0, tolerance = 1e-8)
  expect_equal(.relative_luminance("#ffffff"), 1, tolerance = 1e-8)

  lum <- .relative_luminance(c("#000000", "#ffffff"))
  expect_length(lum, 2)
  expect_true(lum[1] < lum[2])

  # The palette yellow is light; the brand blue is dark.
  expect_gt(.relative_luminance("#f0e442"), 0.4)
  expect_lt(.relative_luminance(depictr_brand()), 0.4)
})

test_that("palette_preview() labels are legible on every swatch", {
  p <- palette_preview(8)
  b <- ggplot2::ggplot_build(p)

  # geom_text is the last layer; gather its drawn colour + the tile fill.
  text_layer <- b$data[[length(b$data)]]
  expect_true("label" %in% names(text_layer))
  expect_true(all(text_layer$colour %in% c("grey10", "white")))

  # For each label, the chosen colour must be the higher-contrast of the two
  # candidates against its own swatch -- i.e. dark text on light tiles only.
  fills <- text_layer$label
  lum <- .relative_luminance(fills)
  dark_text <- text_layer$colour == "grey10"
  # Every dark-text tile is lighter than every white-text tile.
  if (any(dark_text) && any(!dark_text)) {
    expect_gt(min(lum[dark_text]), max(lum[!dark_text]))
  }
  # The historically unreadable pale yellow now gets dark text.
  yellow_row <- which(fills == "#f0e442")
  if (length(yellow_row)) {
    expect_identical(text_layer$colour[yellow_row], "grey10")
  }
})

test_that("palette_preview() builds for every type without warnings", {
  for (tp in c("qualitative", "sequential", "diverging", "all")) {
    expect_no_warning(ggplot2::ggplot_build(palette_preview(6, type = tp)))
  }
})

test_that("arrange_plots() builds without deprecation warnings", {
  p1 <- explore_distribution(crop_yield, yield)
  p2 <- scatter_trend(crop_yield, fertiliser, yield)
  combined <- arrange_plots(p1, p2, title = "T", subtitle = "S")
  expect_no_warning(print(combined))
})
