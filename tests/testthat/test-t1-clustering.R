# Regression tests for clustering bug fixes (t1-clustering) -------------------

has_hline <- function(p) {
  any(vapply(p$layers, function(l) inherits(l$geom, "GeomHline"),
             logical(1)))
}

test_that("dendrogram_plot() handles dist input with k (positional mapping)", {
  # Bug 1: dist input has no leaf labels, so matching cutree() by name yielded
  # an empty-level factor and depictr_palette(0) crashed.
  set.seed(1)
  m <- matrix(rnorm(24), ncol = 3)
  expect_s3_class(dendrogram_plot(dist(m), k = 2), "ggplot")
  expect_s3_class(dendrogram_plot(dist(m), k = 3), "ggplot")
})

test_that("dendrogram_plot() handles unnamed hclust input with k", {
  set.seed(1)
  m <- matrix(rnorm(24), ncol = 3)
  hc <- hclust(dist(m))
  expect_null(hc$labels)
  p <- dendrogram_plot(hc, k = 2)
  expect_s3_class(p, "ggplot")
})

test_that("dendrogram_plot() assigns one cluster level per requested k", {
  # The positional mapping must produce exactly k non-empty cluster levels.
  set.seed(1)
  m <- matrix(rnorm(30), ncol = 3)
  hc <- hclust(dist(m))
  p <- dendrogram_plot(hc, k = 4)
  leaf_layer <- p$layers[[length(p$layers)]]
  dat <- leaf_layer$data
  expect_equal(nlevels(dat$cluster), 4L)
  expect_true(all(table(dat$cluster) > 0))
  # Clusters must match cutree() taken in leaf (observation) order.
  expect_equal(as.integer(as.character(dat$cluster)),
               unname(cutree(hc, k = 4)))
})

test_that("dendrogram_plot() draws the cut line only for 2 <= k < n", {
  # Bug 2: cut line was meaningless at k = 1 and NA at k = n.
  set.seed(1)
  m <- matrix(rnorm(24), ncol = 3)
  hc <- hclust(dist(m))
  n <- length(hc$order)

  expect_false(has_hline(dendrogram_plot(hc, k = 1)))
  expect_true(has_hline(dendrogram_plot(hc, k = 2)))
  expect_true(has_hline(dendrogram_plot(hc, k = n - 1)))
  expect_false(has_hline(dendrogram_plot(hc, k = n)))

  # Edge values must not crash and must not produce NA cut heights.
  expect_s3_class(dendrogram_plot(hc, k = 1), "ggplot")
  expect_s3_class(dendrogram_plot(hc, k = n), "ggplot")
})

test_that("dendrogram_plot() rejects out-of-range k", {
  set.seed(1)
  m <- matrix(rnorm(24), ncol = 3)
  hc <- hclust(dist(m))
  expect_error(dendrogram_plot(hc, k = length(hc$order) + 1), "between 1")
  expect_error(dendrogram_plot(hc, k = 0), "between 1")
})

test_that("cluster_plot() validates clusters length against nrow(data)", {
  # Bug 3: with NA rows, a `clusters` vector sized to the complete rows
  # silently over-indexed and misaligned instead of erroring.
  set.seed(1)
  df <- data.frame(a = rnorm(10), b = rnorm(10), c = rnorm(10))
  df$a[3] <- NA  # one incomplete row -> 9 complete rows

  # Length matching the complete rows (9), not nrow (10), must error.
  expect_error(cluster_plot(df, clusters = rep(1:2, length.out = 9)),
               "one entry per row")
  # Correct length (per row of data) works.
  expect_s3_class(cluster_plot(df, clusters = rep(1:2, length.out = 10)),
                  "ggplot")
})

test_that("cluster_plot() aligns supplied clusters to complete rows", {
  # The supplied per-row clusters must be subset by complete.cases so the
  # plotted assignments line up with the surviving rows.
  set.seed(1)
  df <- data.frame(a = rnorm(6), b = rnorm(6))
  df$a[2] <- NA  # drop row 2
  clusters <- c(1, 9, 1, 2, 2, 1)  # per row; row 2's value (9) must be dropped

  p <- cluster_plot(df, clusters = clusters, hulls = FALSE,
                    label_centers = FALSE)
  # The plot-level data carries the per-point cluster factor.
  drawn <- sort(unique(as.character(p$data$cluster)))
  # The spurious "9" assignment belonged to the dropped row and must not appear.
  expect_false("9" %in% drawn)
  expect_setequal(drawn, c("1", "2"))
  # Five complete rows survive, in original order minus the dropped row 2.
  expect_equal(as.integer(as.character(p$data$cluster)),
               clusters[-2])
})

test_that("cluster_plot() is reproducible with a seed", {
  # Bug 4: k-means had no seed, so colour-by-cluster assignments were
  # non-deterministic across runs.
  set.seed(1)
  df <- data.frame(a = rnorm(40), b = rnorm(40), c = rnorm(40))

  set.seed(123)
  p1 <- cluster_plot(df, k = 3, seed = 42)
  set.seed(456)
  p2 <- cluster_plot(df, k = 3, seed = 42)

  d1 <- ggplot2::layer_data(p1, length(p1$layers))
  d2 <- ggplot2::layer_data(p2, length(p2$layers))
  expect_identical(d1$colour, d2$colour)

  expect_error(cluster_plot(df, k = 3, seed = c(1, 2)),
               "single number")
})
