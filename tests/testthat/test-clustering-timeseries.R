test_that("cluster_plot() runs k-means and accepts supplied clusters", {
  cols <- c("rainfall", "fertiliser", "soil_ph", "yield")
  expect_s3_class(cluster_plot(crop_yield, cols = cols, k = 3), "ggplot")
  expect_s3_class(
    cluster_plot(crop_yield, cols = c("fertiliser", "yield"), k = 2,
                 hulls = FALSE),
    "ggplot"
  )
  km <- kmeans(scale(crop_yield[cols]), 3)
  expect_s3_class(cluster_plot(crop_yield, cols = cols, clusters = km$cluster),
                  "ggplot")
  expect_error(cluster_plot(crop_yield, cols = "yield"), "at least two")
})

test_that("dendrogram_plot() works from data frames, dist and hclust", {
  d <- aggregate(cbind(stress, sleep_hours, life_satisfaction) ~ region,
                 data = wellbeing_survey, FUN = mean)
  rownames(d) <- d$region
  expect_s3_class(dendrogram_plot(d[-1], k = 2), "ggplot")
  expect_s3_class(dendrogram_plot(d[-1], horizontal = TRUE), "ggplot")

  hc <- hclust(dist(scale(crop_yield[1:12, c("rainfall", "yield")])))
  expect_s3_class(dendrogram_plot(hc), "ggplot")
  expect_s3_class(dendrogram_plot(dist(scale(crop_yield[1:12, c("rainfall",
                                                                "yield")]))),
                  "ggplot")
})

test_that("dendro_segments() produces the right number of segments", {
  hc <- hclust(dist(scale(crop_yield[1:10, c("rainfall", "yield")])))
  segs <- depictr:::dendro_segments(hc)
  # Three segments per internal node (n - 1 nodes)
  expect_equal(nrow(segs), 3 * (10 - 1))
})

test_that("timeseries_plot() accepts ts, vectors and data frames", {
  expect_s3_class(timeseries_plot(AirPassengers, rolling = 12), "ggplot")
  expect_s3_class(timeseries_plot(as.numeric(AirPassengers)), "ggplot")
  df <- data.frame(t = rep(1:30, 2), v = rnorm(60),
                   g = rep(c("a", "b"), each = 30))
  expect_s3_class(timeseries_plot(df, t, v, group = g, rolling = 4), "ggplot")
  expect_error(timeseries_plot(df), "time")
})

test_that("acf_plot() works for ACF and PACF", {
  expect_s3_class(acf_plot(AirPassengers), "ggplot")
  expect_s3_class(acf_plot(AirPassengers, type = "partial"), "ggplot")
})

test_that("decompose_plot() decomposes seasonal series", {
  expect_s3_class(decompose_plot(AirPassengers), "patchwork")
  expect_s3_class(decompose_plot(AirPassengers, method = "classical"),
                  "patchwork")
  expect_error(decompose_plot(rnorm(50)), "frequency")
  expect_error(decompose_plot(ts(rnorm(50), frequency = 1)), "seasonal")
})
