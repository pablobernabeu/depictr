# Tier-2 colour / scale / quality refactor for the EDA plotting functions.
#
# These tests pin down the canonical colours (brand blue, colourblind-safe
# accent) introduced by the foundational pass, confirm that off-palette red was
# removed, and check the new `method` argument of explore_pairs().

test_that("scatter_trend uses brand points and the accent smoother", {
  b <- ggplot2::ggplot_build(scatter_trend(crop_yield, fertilizer, yield))
  point_layer <- b$data[[1]]
  smooth_layer <- b$data[[2]]
  expect_identical(unique(point_layer$colour), depictr_brand())
  expect_identical(unique(smooth_layer$colour), depictr_accent())
  # The off-palette red must be gone.
  expect_false(any(b$data[[2]]$colour == "#e23b3b"))
})

test_that("scatter_trend grouped palette routes through depictr scales", {
  p <- scatter_trend(crop_yield, fertilizer, yield, group = treatment,
                     method = "lm")
  b <- ggplot2::ggplot_build(p)
  cols <- unique(b$data[[1]]$colour)
  expect_setequal(cols, depictr_palette(length(cols)))
})

test_that("outlier_plot defaults to the colourblind-safe accent", {
  expect_identical(eval(formals(outlier_plot)$outlier_colour), depictr_accent())
  d <- data.frame(g = rep(c("a", "b"), each = 20),
                  y = c(rnorm(20), c(rnorm(19), 100)))
  b <- ggplot2::ggplot_build(outlier_plot(d, y, group = g))
  # The highlighted-outlier point layer should carry the accent colour.
  has_accent <- any(vapply(b$data, function(layer) {
    !is.null(layer$colour) && any(layer$colour == depictr_accent())
  }, logical(1)))
  expect_true(has_accent)
})

test_that("explore_categorical single-series fill is brand blue", {
  b <- ggplot2::ggplot_build(explore_categorical(wellbeing_survey, region))
  expect_identical(unique(b$data[[1]]$fill), depictr_brand())
})

test_that("explore_distribution and explore_categorical grouped fills use the palette", {
  bd <- ggplot2::ggplot_build(
    explore_distribution(lexical_decision, RT, group = condition,
                         type = "density")
  )
  fills <- unique(bd$data[[1]]$fill)
  expect_setequal(fills, depictr_palette(length(fills)))

  bc <- ggplot2::ggplot_build(
    explore_categorical(wellbeing_survey, education, group = region)
  )
  cfills <- unique(bc$data[[1]]$fill)
  expect_setequal(cfills, depictr_palette(length(cfills)))
})

test_that("missingness_map highlights missing cells with the accent colour", {
  expect_identical(eval(formals(missingness_map)$colours)[2], depictr_accent())
  b <- ggplot2::ggplot_build(missingness_map(wellbeing_survey))
  expect_true(any(b$data[[1]]$fill == depictr_accent()))
})

test_that("correlation_heatmap default palette is single-sourced and ends in brand", {
  pal <- eval(formals(correlation_heatmap)$palette)
  expect_length(pal, 3)
  expect_identical(toupper(pal[3]), toupper(depictr_brand()))
  expect_identical(pal, depictr_palette(5, "diverging")[c(1, 3, 5)])
  # Builds without error.
  expect_s3_class(correlation_heatmap(wellbeing_survey), "ggplot")
})

test_that("raincloud and group_comparison grouped colours use the palette", {
  b <- ggplot2::ggplot_build(
    raincloud_plot(lexical_decision, RT, group = condition)
  )
  fills <- stats::na.omit(unique(unlist(lapply(b$data, function(l) l$fill))))
  fills <- fills[grepl("^#", fills)]
  expect_true(all(fills %in% depictr_palette(length(unique(lexical_decision$condition)))))

  bg <- ggplot2::ggplot_build(
    group_comparison_plot(lexical_decision, RT, condition)
  )
  gcols <- stats::na.omit(unique(unlist(lapply(bg$data, function(l) l$colour))))
  gcols <- gcols[grepl("^#", gcols)]
  expect_true(all(gcols %in% depictr_palette(nlevels(factor(lexical_decision$condition)))))
})

test_that("explore_pairs gains a method argument passed to cor()", {
  expect_true("method" %in% names(formals(explore_pairs)))
  # The upper-triangle label changes with the method.
  lab <- function(m) {
    pn <- pairs_panel(crop_yield, "rainfall", "yield", 1L, 2L, 3L,
                      NULL, NULL, 0.5, m)
    pn$data$label
  }
  expect_match(lab("pearson"), "^r = ")
  expect_false(identical(lab("pearson"), lab("kendall")))
  # The panel labels match a direct cor() call.
  rp <- stats::cor(crop_yield$rainfall, crop_yield$yield,
                   use = "pairwise.complete.obs", method = "spearman")
  expect_identical(lab("spearman"),
                   paste0("r = ", formatC(rp, format = "f", digits = 2)))
  # An unknown method is rejected by match.arg().
  expect_error(explore_pairs(crop_yield, cols = c("rainfall", "yield"),
                             method = "nope"))
})

test_that("explore_pairs panel text and density use brand blue", {
  pn <- pairs_panel(crop_yield, "rainfall", "yield", 1L, 2L, 3L,
                    NULL, NULL, 0.5, "pearson")
  expect_identical(pn$layers[[1]]$aes_params$colour, depictr_brand())
})

test_that("no off-palette hex literals remain in the refactored EDA sources", {
  files <- c("explore_pairs.R", "scatter_trend.R", "outlier_plot.R",
             "explore_categorical.R", "correlation_heatmap.R",
             "missingness_map.R", "distributions_extra.R",
             "explore_distribution.R")
  paths <- file.path("..", "..", "R", files)
  paths <- paths[file.exists(paths)]
  skip_if(length(paths) == 0, "package R sources not reachable from test dir")
  banned <- c("#e23b3b", "#0a3d62")
  for (p in paths) {
    txt <- readLines(p, warn = FALSE)
    for (b in banned) {
      expect_false(any(grepl(b, txt, fixed = TRUE)),
                   info = paste0(basename(p), " still contains ", b))
    }
  }
})
