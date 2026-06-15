# Silhouette plot and cluster-quality diagnostics ----------------------------

#' Silhouette plot
#'
#' Draws a silhouette plot for a clustering: one horizontal bar per observation,
#' grouped and sorted within cluster, with the average silhouette width shown
#' per cluster and overall. The silhouette width \eqn{s(i)} compares how close an
#' observation is to its own cluster against the nearest other cluster, and lies
#' in \eqn{[-1, 1]} (higher is better; negative suggests the point may belong to
#' another cluster). It is a standard internal measure of cluster quality.
#'
#' The widths are computed with [cluster::silhouette()] when the 'cluster'
#' package is installed, and otherwise with an equivalent base-R implementation,
#' so the function works with no extra dependency.
#'
#' @param data A data frame, a numeric matrix, or a [stats::dist] object.
#' @param clusters A vector of cluster assignments, one per observation (per row
#'   of `data`, or matching the objects in a `dist`). Required.
#' @param cols When `data` is a data frame, the numeric columns to use
#'   (default: all numeric columns).
#' @param scale Whether to scale variables to unit variance before computing the
#'   distances (ignored when `data` is a `dist`).
#' @param distance Distance measure passed to [stats::dist()] (ignored when
#'   `data` is already a `dist`).
#' @param palette Colours for the clusters; defaults to [depictr_palette()].
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object. The per-observation silhouette table is
#'   attached as the attribute `"silhouette"` and the average width as
#'   `"avg_width"`.
#' @references
#' Rousseeuw, P. J. (1987). Silhouettes: A graphical aid to the interpretation
#' and validation of cluster analysis. *Journal of Computational and Applied
#' Mathematics*, 20, 53-65. \doi{10.1016/0377-0427(87)90125-7}
#' @export
#' @examples
#' cl <- kmeans(scale(crop_yield[c("rainfall", "fertilizer", "soil_ph",
#'                                 "yield")]), 3)$cluster
#' silhouette_plot(crop_yield, cl,
#'                 cols = c("rainfall", "fertilizer", "soil_ph", "yield"))
silhouette_plot <- function(data, clusters, cols = NULL, scale = TRUE,
                            distance = "euclidean", palette = NULL,
                            title = NULL) {
  if (missing(clusters) || is.null(clusters)) {
    stop("`clusters` must be supplied (one assignment per observation).",
         call. = FALSE)
  }
  prep <- sil_prepare(data, clusters, cols, scale, distance)
  sil <- silhouette_widths(prep$clusters, prep$dist)

  if (nrow(sil) == 0L) {
    stop("Silhouette widths need at least two clusters.", call. = FALSE)
  }

  # Order: by cluster, then by descending width within cluster, and assign a
  # plotting index so bars stack neatly within each cluster block.
  sil <- sil[order(sil$cluster, -sil$sil_width), , drop = FALSE]
  sil$cluster <- factor(sil$cluster)
  sil$index <- seq_len(nrow(sil))

  avg_by_cluster <- tapply(sil$sil_width, sil$cluster, mean)
  avg_width <- mean(sil$sil_width)
  pal <- palette %||% depictr_palette(nlevels(sil$cluster))

  # Cluster annotation: place label at the middle of each cluster block.
  ann <- do.call(rbind, lapply(levels(sil$cluster), function(g) {
    rows <- sil[sil$cluster == g, , drop = FALSE]
    data.frame(
      cluster = g,
      index = mean(rows$index),
      label = sprintf("%s  (n=%d, avg=%.2f)", g, nrow(rows),
                      avg_by_cluster[[g]]),
      stringsAsFactors = FALSE
    )
  }))

  p <- ggplot2::ggplot(
    sil,
    ggplot2::aes(x = .data$index, y = .data$sil_width, fill = .data$cluster)
  ) +
    ggplot2::geom_col(width = 1) +
    ggplot2::geom_hline(yintercept = avg_width, linetype = 2,
                        colour = "grey30") +
    ggplot2::geom_text(
      data = ann,
      ggplot2::aes(x = .data$index, y = -0.02, label = .data$label),
      inherit.aes = FALSE, hjust = 1, size = 3, colour = "grey20"
    ) +
    ggplot2::annotate(
      "text", x = max(sil$index), y = avg_width,
      label = sprintf("overall avg = %.2f", avg_width),
      hjust = 1, vjust = -0.6, size = 3, colour = "grey30"
    ) +
    ggplot2::scale_fill_manual(values = pal, name = "Cluster") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      x = NULL, y = "Silhouette width",
      title = title %||% "Silhouette plot"
    ) +
    theme_depictr(grid = "x") +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank())

  attr(p, "silhouette") <- sil[c("cluster", "neighbor", "sil_width")]
  attr(p, "avg_width") <- avg_width
  p
}

#' Suggest a number of clusters
#'
#' Computes a cluster-quality diagnostic across a range of `k` and returns a
#' tidy data frame plus a suggested `k`. Three criteria are available: the
#' average silhouette width (maximised), the total within-cluster sum of squares
#' "elbow" (the point of maximum curvature), and the gap statistic
#' (the smallest `k` whose gap is within one standard error of the next, using
#' the Tibshirani et al. heuristic).
#'
#' @param data A data frame or numeric matrix.
#' @param k_range Integer vector of candidate cluster counts to evaluate.
#' @param method Diagnostic: `"silhouette"`, `"wss"` (within sum of squares
#'   elbow) or `"gap"`.
#' @param cols When `data` is a data frame, the numeric columns to use.
#' @param scale Whether to scale variables to unit variance first.
#' @param nstart Number of random starts for [stats::kmeans()].
#' @param B Number of reference bootstrap samples for the gap statistic.
#'
#' @return A list with elements `table` (a data frame with one row per `k`),
#'   `suggested` (the chosen `k`) and `method`.
#' @references
#' Rousseeuw, P. J. (1987). Silhouettes: A graphical aid to the interpretation
#' and validation of cluster analysis. *Journal of Computational and Applied
#' Mathematics*, 20, 53-65. \doi{10.1016/0377-0427(87)90125-7}
#'
#' Tibshirani, R., Walther, G., & Hastie, T. (2001). Estimating the number of
#' clusters in a data set via the gap statistic. *Journal of the Royal
#' Statistical Society: Series B*, 63(2), 411-423.
#' \doi{10.1111/1467-9868.00293}
#' @export
#' @examples
#' kd <- k_diagnostic(crop_yield, k_range = 2:6,
#'                    cols = c("rainfall", "fertilizer", "soil_ph", "yield"))
#' kd$suggested
k_diagnostic <- function(data, k_range = 2:8,
                         method = c("silhouette", "wss", "gap"),
                         cols = NULL, scale = TRUE, nstart = 10, B = 50) {
  method <- match.arg(method)
  X <- numeric_matrix(data, cols, scale)
  k_range <- sort(unique(as.integer(k_range)))
  k_range <- k_range[k_range >= 1 & k_range < nrow(X)]
  if (length(k_range) < 2) {
    stop("`k_range` must contain at least two feasible values of k.",
         call. = FALSE)
  }

  if (method == "wss") {
    k_range <- k_range[k_range >= 1]
    wss <- vapply(k_range, function(k) {
      if (k == 1) sum(scale(X, scale = FALSE)^2)
      else sum(stats::kmeans(X, centers = k, nstart = nstart)$withinss)
    }, numeric(1))
    tab <- data.frame(k = k_range, wss = wss)
    suggested <- elbow_k(k_range, wss)
    return(list(table = tab, suggested = suggested, method = method))
  }

  if (method == "silhouette") {
    kk <- k_range[k_range >= 2]
    d <- stats::dist(X)
    avg <- vapply(kk, function(k) {
      cl <- stats::kmeans(X, centers = k, nstart = nstart)$cluster
      attr(silhouette_widths(cl, d), "avg_width")
    }, numeric(1))
    tab <- data.frame(k = kk, avg_silhouette = avg)
    suggested <- kk[which.max(avg)]
    return(list(table = tab, suggested = suggested, method = method))
  }

  # Gap statistic (Tibshirani, Walther & Hastie, 2001)
  kk <- k_range[k_range >= 1]
  gap_out <- gap_statistic(X, kk, nstart = nstart, B = B)
  list(table = gap_out$table, suggested = gap_out$suggested, method = method)
}

# ---- internal helpers ------------------------------------------------------

#' Coerce flexible input to a scaled numeric matrix
#' @noRd
numeric_matrix <- function(data, cols, scale) {
  if (inherits(data, "dist")) {
    stop("This diagnostic needs the raw data, not a `dist` object.",
         call. = FALSE)
  }
  if (is.data.frame(data)) {
    if (is.null(cols)) {
      cols <- names(data)[vapply(data, is.numeric, logical(1))]
    } else {
      check_columns(data, cols)
    }
    if (length(cols) < 1) stop("Need at least one numeric column.", call. = FALSE)
    mat <- as.matrix(data[stats::complete.cases(data[cols]), cols, drop = FALSE])
  } else if (is.matrix(data) && is.numeric(data)) {
    mat <- data[stats::complete.cases(data), , drop = FALSE]
  } else {
    stop("`data` must be a data frame or a numeric matrix.", call. = FALSE)
  }
  if (scale) mat <- scale(mat)
  mat
}

#' Build the (clusters, dist) pair needed for silhouette widths
#' @noRd
sil_prepare <- function(data, clusters, cols, scale, distance) {
  if (inherits(data, "dist")) {
    n <- attr(data, "Size")
    if (length(clusters) != n) {
      stop("`clusters` must have one entry per object in the `dist`.",
           call. = FALSE)
    }
    return(list(clusters = as.integer(as.factor(clusters)), dist = data))
  }
  if (is.data.frame(data)) {
    if (is.null(cols)) {
      cols <- names(data)[vapply(data, is.numeric, logical(1))]
    } else {
      check_columns(data, cols)
    }
    cc <- stats::complete.cases(data[cols])
    mat <- as.matrix(data[cc, cols, drop = FALSE])
    cl <- clusters[cc]
  } else if (is.matrix(data) && is.numeric(data)) {
    cc <- stats::complete.cases(data)
    mat <- data[cc, , drop = FALSE]
    cl <- clusters[cc]
  } else {
    stop("`data` must be a data frame, numeric matrix or `dist` object.",
         call. = FALSE)
  }
  if (length(cl) != nrow(mat)) {
    stop("`clusters` must have one entry per row of `data`.", call. = FALSE)
  }
  if (scale) mat <- scale(mat)
  list(clusters = as.integer(as.factor(cl)),
       dist = stats::dist(mat, method = distance))
}

#' Silhouette widths, via cluster::silhouette or a base-R fallback
#'
#' Returns a data frame with columns `cluster`, `neighbor` and `sil_width`, one
#' row per observation, plus an `avg_width` attribute. With fewer than two
#' distinct clusters the result has zero rows.
#' @noRd
silhouette_widths <- function(clusters, dist) {
  clusters <- as.integer(as.factor(clusters))
  if (length(unique(clusters)) < 2L) {
    out <- data.frame(cluster = integer(0), neighbor = integer(0),
                      sil_width = numeric(0))
    attr(out, "avg_width") <- NA_real_
    return(out)
  }

  if (requireNamespace("cluster", quietly = TRUE)) {
    sil <- cluster::silhouette(clusters, dist)
    m <- as.matrix(sil)  # columns: cluster, neighbor, sil_width
    out <- data.frame(cluster = m[, "cluster"],
                      neighbor = m[, "neighbor"],
                      sil_width = m[, "sil_width"])
    attr(out, "avg_width") <- mean(out$sil_width)
    return(out)
  }

  base_silhouette(clusters, dist)
}

#' Base-R silhouette computation (Rousseeuw, 1987)
#'
#' For each observation i: a(i) is the mean distance to the other members of its
#' own cluster; b(i) is the minimum, over other clusters, of the mean distance
#' to that cluster's members. The silhouette is (b - a) / max(a, b), and is 0 for
#' singleton clusters.
#' @noRd
base_silhouette <- function(clusters, dist) {
  D <- as.matrix(dist)
  n <- length(clusters)
  cl_levels <- sort(unique(clusters))
  members <- lapply(cl_levels, function(g) which(clusters == g))
  names(members) <- as.character(cl_levels)

  sil_width <- numeric(n)
  neighbor <- integer(n)
  for (i in seq_len(n)) {
    own <- clusters[i]
    own_idx <- members[[as.character(own)]]
    own_others <- setdiff(own_idx, i)
    if (length(own_others) == 0L) {
      # Singleton cluster: silhouette defined as 0.
      sil_width[i] <- 0
      others <- setdiff(cl_levels, own)
      neighbor[i] <- if (length(others)) others[1] else own
      next
    }
    a_i <- mean(D[i, own_others])
    other_means <- vapply(setdiff(cl_levels, own), function(g) {
      mean(D[i, members[[as.character(g)]]])
    }, numeric(1))
    b_i <- min(other_means)
    neighbor[i] <- setdiff(cl_levels, own)[which.min(other_means)]
    denom <- max(a_i, b_i)
    sil_width[i] <- if (denom == 0) 0 else (b_i - a_i) / denom
  }

  out <- data.frame(cluster = clusters, neighbor = neighbor,
                    sil_width = sil_width)
  attr(out, "avg_width") <- mean(sil_width)
  out
}

#' Pick the elbow of a within-SS curve by maximum distance to the chord
#'
#' Connects the first and last (k, wss) points with a straight line and returns
#' the k whose point is farthest below that chord, a common, parameter-free
#' "elbow" heuristic (the Kneedle idea).
#' @noRd
elbow_k <- function(k, wss) {
  if (length(k) < 3) return(k[which.max(-diff(c(wss, wss[length(wss)])))])
  x <- as.numeric(k)
  y <- as.numeric(wss)
  x1 <- x[1]; y1 <- y[1]
  x2 <- x[length(x)]; y2 <- y[length(y)]
  # Perpendicular distance from each point to the chord (x1,y1)-(x2,y2).
  num <- abs((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1)
  den <- sqrt((y2 - y1)^2 + (x2 - x1)^2)
  d <- num / den
  k[which.max(d)]
}

#' Gap statistic with a uniform reference distribution
#' @noRd
gap_statistic <- function(X, kk, nstart = 10, B = 50) {
  log_wk <- function(mat, k) {
    if (k == 1) {
      log(sum(scale(mat, scale = FALSE)^2))
    } else {
      log(sum(stats::kmeans(mat, centers = k, nstart = nstart)$withinss))
    }
  }
  obs <- vapply(kk, function(k) log_wk(X, k), numeric(1))

  mins <- apply(X, 2, min)
  maxs <- apply(X, 2, max)
  n <- nrow(X); p <- ncol(X)
  ref <- matrix(0, nrow = B, ncol = length(kk))
  for (b in seq_len(B)) {
    Xb <- matrix(stats::runif(n * p), nrow = n, ncol = p)
    Xb <- sweep(sweep(Xb, 2, maxs - mins, "*"), 2, mins, "+")
    ref[b, ] <- vapply(kk, function(k) log_wk(Xb, k), numeric(1))
  }
  ref_mean <- colMeans(ref)
  gap <- ref_mean - obs
  sdk <- apply(ref, 2, stats::sd)
  sk <- sdk * sqrt(1 + 1 / B)

  # Smallest k such that gap(k) >= gap(k+1) - s(k+1).
  suggested <- kk[length(kk)]
  for (i in seq_len(length(kk) - 1L)) {
    if (gap[i] >= gap[i + 1] - sk[i + 1]) {
      suggested <- kk[i]
      break
    }
  }
  tab <- data.frame(k = kk, logW = obs, E_logW = ref_mean, gap = gap, se = sk)
  list(table = tab, suggested = suggested)
}
