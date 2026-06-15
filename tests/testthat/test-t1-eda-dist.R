# Regression tests for distribution/categorical EDA edge cases (t1-eda-dist).

test_that("group_comparison_plot() draws no CI (not NaN) for n = 1 groups", {
  df <- data.frame(y = c(1, 2, 3, 5), g = c("a", "a", "a", "b"))

  expect_warning(
    p <- group_comparison_plot(df, y, g),
    "n < 2"
  )
  expect_s3_class(p, "ggplot")

  # The pointrange layer (layer 2: jitter is layer 1) must not contain NaN
  # bounds for the singleton group; its interval collapses to the mean.
  pr <- ggplot2::layer_data(p, 2)
  expect_false(anyNA(pr$ymin))
  expect_false(anyNA(pr$ymax))
  single <- pr[pr$y == 5, ]
  expect_equal(single$ymin, 5)
  expect_equal(single$ymax, 5)

  # The well-populated group keeps a genuine (non-degenerate) interval.
  multi <- pr[pr$y == 2, ]
  expect_true(multi$ymin < multi$y && multi$ymax > multi$y)
})

test_that("raincloud_plot() skips the half-violin for sparse groups instead of aborting", {
  df <- data.frame(
    y = c(1, 2, 3, 4, 5, 9),
    g = c("a", "a", "a", "a", "a", "b")
  )

  expect_warning(
    p <- raincloud_plot(df, y, group = g),
    "n < 2"
  )
  expect_s3_class(p, "ggplot")
  # It must be drawable end-to-end (this is where stats::density used to blow up).
  expect_no_error(ggplot2::ggplot_build(p))

  # Even when every group is under-populated it degrades gracefully.
  df_all <- data.frame(y = c(1, 9), g = c("a", "b"))
  expect_warning(p2 <- raincloud_plot(df_all, y, group = g), "n < 2")
  expect_no_error(ggplot2::ggplot_build(p2))
})

test_that("explore_categorical() rejects continuous numeric columns", {
  # crop_yield$yield has many distinct values: should error, not draw 150+ bars.
  expect_error(
    explore_categorical(crop_yield, yield),
    "continuous"
  )

  # A low-cardinality numeric (e.g. a 0/1 flag) is still treated as categorical.
  df <- data.frame(flag = c(0, 1, 0, 1, 1, 0, 1, 0))
  expect_s3_class(explore_categorical(df, flag), "ggplot")
})

test_that("explore_distribution() drops NA up front and dodges grouped bars", {
  dd <- lexical_decision
  dd$RT[1:5] <- NA

  # No "Removed N rows" warning should reach the user at draw time.
  p <- explore_distribution(dd, RT)
  expect_no_warning(ggplot2::ggplot_build(p))

  # The under-the-hood data already excludes the NA rows.
  built <- ggplot2::ggplot_build(p)
  expect_equal(sum(built$data[[1]]$count), sum(!is.na(dd$RT)))

  # Grouped histograms default to dodge (readable), not identity (overlapping).
  expect_equal(formals(explore_distribution)$position, NULL)
  gp <- explore_distribution(lexical_decision, RT, group = condition)
  ld <- ggplot2::layer_data(gp, 1)
  # Dodging shrinks each bar and offsets groups, so bar widths are < bin width.
  widths <- ld$xmax - ld$xmin
  full_bin <- diff(range(lexical_decision$RT, na.rm = TRUE)) / 30
  expect_true(all(widths < full_bin))
})
