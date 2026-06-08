test_that("posterior_plot() accepts wide and long draws", {
  set.seed(1)
  wide <- data.frame(a = rnorm(400, 5, 0.3), b = rnorm(400, 0.8, 0.15))
  expect_s3_class(posterior_plot(wide), "ggplot")

  long <- data.frame(parameter = rep(c("a", "b"), each = 400),
                     value = c(rnorm(400), rnorm(400, 2)))
  expect_s3_class(posterior_plot(long), "ggplot")
  expect_error(posterior_plot(data.frame(x = letters)), "draws")
})

test_that("palette_preview() and arrange_plots() return objects", {
  expect_s3_class(palette_preview(4), "ggplot")
  p1 <- scatter_trend(crop_yield, fertilizer, yield)
  p2 <- explore_distribution(crop_yield, yield)
  expect_s3_class(arrange_plots(p1, p2, ncol = 2, title = "t"), "patchwork")
  expect_s3_class(arrange_plots(list(p1, p2)), "patchwork")
})

test_that("save_plot() writes a file", {
  p <- scatter_trend(crop_yield, fertilizer, yield)
  f <- file.path(tempdir(), "statviz-test.png")
  if (file.exists(f)) unlink(f)
  save_plot(f, p, width = 4, height = 3)
  expect_true(file.exists(f))
  unlink(f)
})
