# Tier-2 colour refactor: multivariate, time-series and clustering ----------
#
# These tests pin the canonical palette to the geoms it should reach, so a
# future stray hex literal (or a palette change made in the wrong place) is
# caught. Colours are read back out of the built plot data rather than the
# source, so a change that is not actually rendered fails the test.

# Collect every distinct `colour`/`fill` value across all layers of a built
# plot (NA values dropped).
built_aes <- function(p, aes = "colour") {
  b <- ggplot2::ggplot_build(p)
  vals <- unlist(lapply(b$data, function(d) if (aes %in% names(d)) d[[aes]]))
  sort(unique(stats::na.omit(vals)))
}

## ---- multivariate ---------------------------------------------------------

test_that("scree_plot uses brand bars and the accent for the cumulative overlay", {
  cols <- c("age", "income", "stress", "sleep_hours",
            "exercise_days", "life_satisfaction")
  p <- scree_plot(wellbeing_survey, cols = cols)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  expect_identical(unique(b$data[[1]]$fill), depictr_brand())   # bars
  expect_identical(unique(b$data[[2]]$colour), depictr_accent()) # cumulative line
  expect_identical(unique(b$data[[3]]$colour), depictr_accent()) # cumulative points

  # The off-palette red it replaced must be gone everywhere.
  expect_false("#e23b3b" %in% built_aes(p, "colour"))
})

test_that("pca_plot draws brand points and accent loadings (single-group)", {
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  p <- pca_plot(crop_yield, cols = cols)
  expect_no_warning(b <- ggplot2::ggplot_build(p))

  expect_identical(unique(b$data[[1]]$colour), depictr_brand())  # observations
  # Loading arrows and labels share the single accent (was #e23b3b / #b1262d).
  load_cols <- built_aes(p, "colour")
  expect_true(depictr_accent() %in% load_cols)
  expect_false(any(c("#e23b3b", "#b1262d") %in% load_cols))
})

test_that("pca_plot grouped colours come from the qualitative palette", {
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  p <- pca_plot(crop_yield, cols = cols, group = "treatment")
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  n <- nlevels(as.factor(crop_yield$treatment))
  expect_true(all(unique(b$data[[1]]$colour) %in% depictr_palette(n)))
})

## ---- time series ----------------------------------------------------------

test_that("timeseries_plot single series is brand; moving average is the accent", {
  p <- timeseries_plot(AirPassengers, rolling = 12)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  cols <- built_aes(p, "colour")
  expect_true(depictr_brand() %in% cols)   # the series line
  expect_true(depictr_accent() %in% cols)  # the moving-average overlay
  expect_false("#e23b3b" %in% cols)
})

test_that("acf_plot uses brand lollipops and grey reference bounds", {
  p <- acf_plot(AirPassengers)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  cols <- built_aes(p, "colour")
  expect_true(depictr_brand() %in% cols)      # segments + points
  expect_true(depictr_reference() %in% cols)  # significance bounds
  expect_false("#e23b3b" %in% cols)
})

test_that("decompose_plot panels are exactly the four-colour palette", {
  pw <- decompose_plot(AirPassengers)
  panel_cols <- vapply(
    seq_len(4),
    function(i) unique(ggplot2::ggplot_build(pw[[i]])$data[[1]]$colour),
    character(1)
  )
  expect_identical(unname(panel_cols), depictr_palette(4))
})

## ---- clustering -----------------------------------------------------------

test_that("cluster_plot routes colour and fill through the depictr palette", {
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  p <- cluster_plot(crop_yield, cols = cols, k = 3, seed = 1)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  pal <- depictr_palette(3)
  expect_true(all(built_aes(p, "fill") %in% pal))
  # Point/hull cluster colours are palette members (centroid labels are grey15).
  expect_true(all(setdiff(built_aes(p, "colour"), "grey15") %in% pal))
})

test_that("cluster_plot honours a supplied palette through the canonical scale", {
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  custom <- c("#111111", "#222222", "#333333")
  p <- cluster_plot(crop_yield, cols = cols, k = 3, seed = 1, palette = custom)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  expect_true(all(custom %in% built_aes(p, "colour")))
  expect_true(all(custom %in% built_aes(p, "fill")))
})

test_that("dendrogram_plot leaf clusters use the palette and honour overrides", {
  d <- aggregate(cbind(stress, sleep_hours, life_satisfaction) ~ region,
                 data = wellbeing_survey, FUN = mean)
  rownames(d) <- d$region

  p <- dendrogram_plot(d[-1], k = 2)
  expect_no_warning(b <- ggplot2::ggplot_build(p))
  # Leaf-label colours include the two-colour palette (grey segments aside).
  expect_true(all(depictr_palette(2) %in% built_aes(p, "colour")))

  custom <- c("#444444", "#555555")
  p2 <- dendrogram_plot(d[-1], k = 2, palette = custom)
  expect_no_warning(ggplot2::ggplot_build(p2))
  expect_true(all(custom %in% built_aes(p2, "colour")))
})
