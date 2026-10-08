# ggplot2 renamed geom_label()'s border argument in 4.0.0 (label.size became
# linewidth). Each name is unknown to the other side of that release, where it
# warns and leaves the default border in place, so the label layers ask
# label_border_none() for the name this ggplot2 understands.

test_that("label_border_none() names the border argument of each ggplot2", {
  expect_identical(label_border_none("3.5.2"), list(label.size = 0))
  expect_identical(label_border_none("3.5.9"), list(label.size = 0))
  expect_identical(label_border_none("4.0.0"), list(linewidth = 0))
  expect_identical(label_border_none("4.0.3"), list(linewidth = 0))
  expect_identical(label_border_none(package_version("10.0.0")),
                   list(linewidth = 0))
  expect_identical(label_border_none(),
                   label_border_none(utils::packageVersion("ggplot2")))
})

# The border is zero whichever argument carries it: an aesthetic from 4.0.0,
# a geom parameter before.
label_layers_borderless <- function(p) {
  labels <- Filter(function(l) inherits(l$geom, "GeomLabel"), p$layers)
  expect_gt(length(labels), 0)
  for (l in labels) {
    border <- l$aes_params$linewidth %||% l$geom_params$label.size
    expect_identical(border, 0)
  }
}

test_that("pca_plot() draws borderless loading labels without a warning", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_warning(
    p <- pca_plot(crop_yield,
                  cols = c("rainfall", "fertiliser", "soil_ph", "yield"),
                  group = "treatment")
  )
  label_layers_borderless(p)
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("silhouette_plot() draws borderless labels without a warning", {
  skip_if_not_installed("cluster")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  cl <- withr::with_seed(1, stats::kmeans(scale(crop_yield[cols]), 3)$cluster)
  expect_no_warning(p <- silhouette_plot(crop_yield, cl, cols = cols))
  label_layers_borderless(p)
  expect_no_warning(ggplot2::ggplot_build(p))
})
