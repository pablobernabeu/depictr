cols <- c("rainfall", "fertilizer", "soil_ph", "yield")

test_that("silhouette_plot() returns a ggplot that builds cleanly", {
  set.seed(1)
  cl <- kmeans(scale(crop_yield[cols]), 3)$cluster
  p <- silhouette_plot(crop_yield, cl, cols = cols)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
  # Attributes carry the computed widths
  expect_true(!is.null(attr(p, "silhouette")))
  expect_true(is.numeric(attr(p, "avg_width")))

  # Also works from a dist object and a numeric matrix
  d <- dist(scale(crop_yield[cols]))
  expect_s3_class(silhouette_plot(d, cl), "ggplot")
  expect_s3_class(
    silhouette_plot(as.matrix(crop_yield[cols]), cl, scale = TRUE),
    "ggplot"
  )

  expect_error(silhouette_plot(crop_yield, cols = cols), "clusters")
})

test_that("base_silhouette() matches cluster::silhouette to numerical tolerance", {
  skip_if_not_installed("cluster")
  set.seed(42)
  X <- scale(crop_yield[cols])
  d <- dist(X)
  for (k in 2:5) {
    cl <- kmeans(X, k, nstart = 5)$cluster
    ref <- as.matrix(cluster::silhouette(cl, d))
    mine <- depictr:::base_silhouette(cl, d)
    expect_equal(mine$sil_width, unname(ref[, "sil_width"]), tolerance = 1e-8)
    expect_equal(mine$neighbor, unname(ref[, "neighbor"]))
    expect_equal(mine$cluster, unname(ref[, "cluster"]))
    expect_equal(attr(mine, "avg_width"), mean(ref[, "sil_width"]),
                 tolerance = 1e-8)
  }
})

test_that("base_silhouette() handles singletons and silhouette_widths handles <2 clusters", {
  skip_if_not_installed("cluster")
  set.seed(8)
  X <- scale(crop_yield[cols])
  d <- dist(X)
  cl <- kmeans(X, 3)$cluster
  cl[1] <- 99L  # make the first observation a singleton cluster
  mine <- depictr:::base_silhouette(cl, d)
  ref <- as.matrix(cluster::silhouette(cl, d))
  expect_equal(mine$sil_width[1], 0)           # singleton width defined as 0
  expect_false(any(is.nan(mine$sil_width)))
  expect_equal(mine$sil_width, unname(ref[, "sil_width"]), tolerance = 1e-8)

  # Fewer than two clusters: zero-row result with NA average
  z <- depictr:::silhouette_widths(rep(1L, 10),
                                   dist(matrix(rnorm(20), 10)))
  expect_equal(nrow(z), 0L)
  expect_true(is.na(attr(z, "avg_width")))
})

test_that("k_diagnostic(method = 'wss') recovers withinss and an elbow", {
  set.seed(7)
  kd <- k_diagnostic(crop_yield, k_range = 2:7, method = "wss", cols = cols,
                     nstart = 10)
  # k_diagnostic() returns a ggplot of the diagnostic curve; the numbers are
  # carried as attributes.
  expect_s3_class(kd, "ggplot")
  expect_equal(attr(kd, "method"), "wss")
  tab <- attr(kd, "k_table")
  expect_true(all(c("k", "wss") %in% names(tab)))
  # Within-SS must decrease as k grows
  expect_true(all(diff(tab$wss) < 0))
  expect_true(attr(kd, "suggested") %in% tab$k)
})

test_that("k_diagnostic(method = 'silhouette') picks the argmax average width", {
  skip_if_not_installed("cluster")
  set.seed(11)
  kd <- k_diagnostic(crop_yield, k_range = 2:6, method = "silhouette",
                     cols = cols)
  expect_s3_class(kd, "ggplot")
  ktab <- attr(kd, "k_table")
  expect_equal(attr(kd, "suggested"),
               ktab$k[which.max(ktab$avg_silhouette)])

  # Each tabulated value matches an independent silhouette computation
  set.seed(99)
  cl3 <- kmeans(scale(crop_yield[cols]), 3, nstart = 10)$cluster
  direct <- mean(cluster::silhouette(cl3, dist(scale(crop_yield[cols])))[,
                                     "sil_width"])
  mine <- attr(depictr:::silhouette_widths(cl3,
                 dist(scale(crop_yield[cols]))), "avg_width")
  expect_equal(direct, mine, tolerance = 1e-8)
})

test_that("elbow_k() finds the point of maximum curvature", {
  k <- 2:8
  wss <- c(100, 60, 35, 32, 30, 28, 27)  # sharp elbow at k = 4
  expect_equal(depictr:::elbow_k(k, wss), 4)
})

test_that("gap_statistic() reproduces an independent gap computation", {
  X <- as.matrix(scale(crop_yield[cols]))
  kk <- 1:5
  B <- 20
  set.seed(123)
  mine <- depictr:::gap_statistic(X, kk, nstart = 10, B = B)

  set.seed(123)
  logWk <- function(mat, k) {
    if (k == 1) log(sum(scale(mat, scale = FALSE)^2))
    else log(sum(kmeans(mat, k, nstart = 10)$withinss))
  }
  obs <- vapply(kk, function(k) logWk(X, k), numeric(1))
  mins <- apply(X, 2, min); maxs <- apply(X, 2, max)
  n <- nrow(X); p <- ncol(X)
  refmat <- matrix(0, B, length(kk))
  for (b in seq_len(B)) {
    Xb <- vapply(seq_len(p), function(j) runif(n, mins[j], maxs[j]),
                 numeric(n))
    refmat[b, ] <- vapply(kk, function(k) logWk(Xb, k), numeric(1))
  }
  gap <- colMeans(refmat) - obs
  expect_equal(mine$table$gap, gap, tolerance = 1e-8)
  expect_equal(mine$table$logW, obs, tolerance = 1e-8)
  expect_true(mine$suggested %in% kk)
})

test_that("cluster_plot(suggest_k=) chooses k, stays backward-compatible", {
  # suggest_k overrides k and attaches the diagnostic
  p1 <- cluster_plot(crop_yield, cols = cols, suggest_k = TRUE,
                     k_range = 2:6, seed = 1)
  expect_s3_class(p1, "ggplot")
  expect_silent(ggplot2::ggplot_build(p1))
  kd <- attr(p1, "k_diagnostic")
  expect_false(is.null(kd))
  expect_equal(kd$method, "silhouette")
  expect_true(kd$suggested >= 2)
  # The suggested k matches the argmax of the average-silhouette table
  expect_equal(kd$suggested,
               kd$table$k[which.max(kd$table$avg_silhouette)])

  p2 <- cluster_plot(crop_yield, cols = cols, suggest_k = "wss",
                     k_range = 2:7, seed = 1)
  expect_equal(attr(p2, "k_diagnostic")$method, "wss")

  # Default behaviour unchanged: no diagnostic attached, no subtitle
  p3 <- cluster_plot(crop_yield, cols = cols, k = 3, seed = 1)
  expect_null(attr(p3, "k_diagnostic"))
  expect_null(p3$labels$subtitle)

  # Hierarchical cutree assignments (matching dendrogram_plot) accepted
  hc <- hclust(dist(scale(crop_yield[cols])))
  p4 <- cluster_plot(crop_yield, cols = cols, clusters = cutree(hc, 3))
  expect_s3_class(p4, "ggplot")
  expect_silent(ggplot2::ggplot_build(p4))
})
