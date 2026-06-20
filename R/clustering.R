# Clustering plots -----------------------------------------------------------

#' Cluster scatter plot
#'
#' Runs k-means clustering on the numeric columns of a data frame (or uses a
#' supplied cluster assignment) and plots the observations on the first two
#' principal components, coloured by cluster, with optional convex hulls and
#' labelled centroids. Projecting onto principal components means the plot works
#' for any number of variables.
#'
#' @param data A data frame.
#' @param cols Numeric columns to cluster on (default: all numeric).
#' @param k Number of clusters for k-means (ignored if `clusters` is supplied,
#'   or overridden when `suggest_k` chooses a value).
#' @param clusters Optional vector of cluster assignments (e.g. from
#'   [stats::kmeans()] or [stats::cutree()]); use this to plot a clustering you
#'   computed yourself. Hierarchical or PAM assignments (such as
#'   [stats::cutree()] output matching [dendrogram_plot()]) are accepted. Must
#'   have exactly one entry per row of `data` (rows with missing values in
#'   `cols` are dropped from both before plotting).
#' @param scale Whether to scale variables to unit variance before clustering and the PCA.
#' @param suggest_k Optionally choose `k` automatically with a cluster-quality
#'   diagnostic instead of using the supplied `k`. Either `TRUE` (uses the
#'   average-silhouette criterion), a string naming the criterion
#'   (`"silhouette"`, `"wss"` or `"gap"`; see [k_diagnostic()]), or `NULL`
#'   (the default) to leave `k` unchanged. Ignored when `clusters` is supplied.
#' @param k_range Candidate values of `k` searched when `suggest_k` is set.
#' @param hulls Whether to draw a shaded convex hull around each cluster.
#' @param label_centers Whether to label the cluster centroids.
#' @param point_alpha Point transparency.
#' @param palette Colours for the clusters; defaults to [depictr_palette()].
#' @param title Plot title.
#' @param seed Optional integer seed for reproducible k-means (ignored when
#'   `clusters` is supplied). Default `NULL` leaves the RNG state untouched.
#' @param nstart Number of random starts for [stats::kmeans()].
#' @param iter.max Maximum iterations for [stats::kmeans()].
#'
#' @return A [ggplot2::ggplot] object. When `suggest_k` is used, the chosen `k`
#'   and the full diagnostic are attached as the attribute `"k_diagnostic"`.
#' @seealso [k_diagnostic()] and [silhouette_plot()] for cluster-quality
#'   diagnostics.
#' @export
#' @examples
#' cluster_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
#'                                   "yield"), k = 3, seed = 1)
#' # Let a silhouette diagnostic choose k:
#' cluster_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
#'                                   "yield"), suggest_k = TRUE, k_range = 2:6,
#'              seed = 1)
cluster_plot <- function(data, cols = NULL, k = 3, clusters = NULL,
                         scale = TRUE, suggest_k = NULL, k_range = 2:8,
                         hulls = TRUE, label_centers = TRUE,
                         point_alpha = 0.8, palette = NULL, title = NULL,
                         seed = NULL, nstart = 10, iter.max = 10) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(cols)) cols <- names(data)[vapply(data, is.numeric, logical(1))]
  else check_columns(data, cols)
  if (length(cols) < 2) stop("Need at least two numeric columns.", call. = FALSE)

  cc <- stats::complete.cases(data[cols])
  mat <- as.matrix(data[cc, cols, drop = FALSE])
  X <- if (scale) scale(mat) else mat

  kd <- NULL
  subtitle <- NULL
  if (is.null(clusters) && !is.null(suggest_k) &&
      !identical(suggest_k, FALSE)) {
    method <- if (isTRUE(suggest_k)) "silhouette" else suggest_k
    if (!is.null(seed)) {
      if (!is.numeric(seed) || length(seed) != 1) {
        stop("`seed` must be a single number or NULL.", call. = FALSE)
      }
      set.seed(seed)
    }
    kd <- k_diagnostic_data(data, k_range = k_range, method = method,
                            cols = cols, scale = scale, nstart = nstart)
    k <- kd$suggested
    subtitle <- sprintf("k = %d suggested by %s diagnostic", k, kd$method)
  }

  if (is.null(clusters)) {
    if (!is.null(seed)) {
      if (!is.numeric(seed) || length(seed) != 1) {
        stop("`seed` must be a single number or NULL.", call. = FALSE)
      }
      set.seed(seed)
    }
    km <- stats::kmeans(X, centers = k, nstart = nstart, iter.max = iter.max)
    cl <- km$cluster
  } else {
    # `clusters` is defined per row of `data`; validate against the full row
    # count *before* dropping incomplete rows so a length mismatch (e.g. a
    # vector sized to the complete rows) is caught instead of silently
    # over-indexing and misaligning the assignments.
    if (length(clusters) != nrow(data)) {
      stop("`clusters` must have one entry per row of `data`.", call. = FALSE)
    }
    cl <- clusters[cc]
  }

  pca <- stats::prcomp(X, center = TRUE, scale. = FALSE)
  ve <- (pca$sdev^2) / sum(pca$sdev^2)
  df <- data.frame(PCx = pca$x[, 1], PCy = pca$x[, 2],
                   cluster = factor(cl))
  # Route cluster colour/fill through the canonical depictr scales. With no
  # `palette` override this is exactly scale_*_depictr(); a supplied `palette`
  # is honoured by passing it as the scale's palette function.
  pal_fun <- if (is.null(palette)) NULL else function(k) palette

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$PCx, y = .data$PCy,
                                        colour = .data$cluster))
  if (hulls) {
    hull <- do.call(rbind, lapply(split(df, df$cluster), function(d) {
      d[grDevices::chull(d$PCx, d$PCy), , drop = FALSE]
    }))
    p <- p + ggplot2::geom_polygon(
      data = hull,
      ggplot2::aes(fill = .data$cluster, colour = .data$cluster),
      alpha = 0.15, linewidth = 0.3
    ) + scale_fill_depictr(palette = pal_fun, guide = "none")
  }
  p <- p + ggplot2::geom_point(alpha = point_alpha, size = 1.6)

  if (label_centers) {
    centers <- do.call(rbind, lapply(split(df, df$cluster), function(d) {
      data.frame(PCx = mean(d$PCx), PCy = mean(d$PCy),
                 cluster = d$cluster[1])
    }))
    p <- p + ggplot2::geom_text(
      data = centers,
      ggplot2::aes(label = .data$cluster), colour = "grey15",
      fontface = "bold", size = 4.2, show.legend = FALSE
    )
  }

  # When the centroids are labelled in place, the colour legend just repeats the
  # cluster numbers, so drop it; keep it when the labels are switched off.
  p <- p +
    scale_colour_depictr(palette = pal_fun, name = "Cluster",
                         guide = if (label_centers) "none" else "legend") +
    ggplot2::labs(
      x = sprintf("PC1 (%.1f%%)", 100 * ve[1]),
      y = sprintf("PC2 (%.1f%%)", 100 * ve[2]),
      title = title, subtitle = subtitle
    ) +
    theme_depictr()
  if (!is.null(kd)) attr(p, "k_diagnostic") <- kd
  p
}

#' Dendrogram
#'
#' Hierarchical-clustering dendrogram, drawn with ggplot2 so it shares the
#' package theme. Accepts a data frame (the distance matrix and clustering are
#' computed for you), a [stats::dist] object, or an [stats::hclust] object.
#' Optionally cut the tree into `k` clusters, colouring the leaf labels and
#' drawing the cut height.
#'
#' @param x A data frame, a `dist` object, or an `hclust` object.
#' @param cols When `x` is a data frame, the numeric columns to use.
#' @param distance Distance measure passed to [stats::dist()].
#' @param method Linkage method passed to [stats::hclust()].
#' @param scale Whether to scale variables before computing distances (data frame input).
#' @param k Optional number of clusters to highlight (between 1 and the number
#'   of leaves). The cut-height line is drawn only when `2 <= k < n`.
#' @param horizontal Whether to draw the tree horizontally.
#' @param labels Whether to print the leaf labels. `NULL` (the default) chooses
#'   automatically: labels are shown for small trees (up to 40 leaves) and
#'   suppressed for larger ones, where they would otherwise collapse into an
#'   unreadable smear. `TRUE`/`FALSE` force them on or off. When labels are
#'   hidden and `k` is set, the cluster membership is instead conveyed by a
#'   coloured strip of leaf ticks along the bottom of the tree.
#' @param palette Colours for the `k` clusters; defaults to [depictr_palette()].
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Cluster the US states by the bundled survey's regional averages
#' d <- aggregate(cbind(stress, sleep_hours, life_satisfaction) ~ region,
#'                data = wellbeing_survey, FUN = mean)
#' rownames(d) <- d$region
#' dendrogram_plot(d[-1], k = 2)
dendrogram_plot <- function(x, cols = NULL, distance = "euclidean",
                            method = "complete", scale = TRUE, k = NULL,
                            horizontal = FALSE, labels = NULL, palette = NULL,
                            title = NULL) {
  hc <- as_hclust(x, cols, distance, method, scale)
  segs <- dendro_segments(hc)
  n <- length(hc$order)
  # Position leaves at their plot x and y = 0
  leaf_x <- numeric(n)
  leaf_x[hc$order] <- seq_len(n)
  leaves <- data.frame(x = leaf_x, y = 0,
                       label = hc$labels %||% as.character(seq_len(n)),
                       stringsAsFactors = FALSE)

  # Decide whether to print leaf labels. Auto (NULL): show them only for small
  # trees, where they stay legible; beyond ~40 leaves they overlap into an
  # unreadable band, so suppress them and convey clusters via coloured ticks.
  if (is.null(labels)) {
    show_labels <- n <= 40L
  } else {
    if (!is.logical(labels) || length(labels) != 1 || is.na(labels)) {
      stop("`labels` must be TRUE, FALSE or NULL.", call. = FALSE)
    }
    show_labels <- labels
  }

  cut_h <- NULL
  if (!is.null(k)) {
    if (!is.numeric(k) || length(k) != 1 || k < 1 || k > n) {
      stop("`k` must be a single number between 1 and the number of leaves.",
           call. = FALSE)
    }
    k <- as.integer(k)
    # `cutree()` returns assignments in leaf (i.e. observation) order, so map
    # them onto the leaves positionally. Matching by name fails when the tree
    # has no labels (dist/unnamed hclust input), because both the synthetic
    # leaf labels and `cutree()`'s output are unnamed.
    cl <- stats::cutree(hc, k = k)
    leaves$cluster <- factor(cl)
    # The cut height sits between successive merge heights; it is only
    # meaningful when 2 <= k < n (k = 1 keeps every observation together and
    # k = n splits them all, so there is no interior gap to mark).
    if (k >= 2 && k < n) {
      cut_h <- mean(rev(hc$height)[c(k - 1, k)])
    }
  }

  # `pal_fun` routes leaf-cluster colour through the canonical depictr scale; a
  # supplied `palette` is honoured by passing it as the scale's palette function.
  pal_fun <- if (is.null(palette)) NULL else function(j) palette

  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = segs,
      ggplot2::aes(x = .data$x, xend = .data$xend, y = .data$y,
                   yend = .data$yend),
      colour = "grey35", linewidth = 0.4
    )

  if (!is.null(k) && !is.null(cut_h)) {
    p <- p + ggplot2::geom_hline(yintercept = cut_h, linetype = 2,
                                 colour = "grey70")
  }

  if (show_labels) {
    if (!is.null(k)) {
      p <- p +
        ggplot2::geom_text(
          data = leaves,
          ggplot2::aes(x = .data$x, y = .data$y, label = .data$label,
                       colour = .data$cluster),
          angle = if (horizontal) 0 else 90,
          hjust = 1.05, size = 3, show.legend = FALSE
        ) +
        scale_colour_depictr(palette = pal_fun)
    } else {
      p <- p + ggplot2::geom_text(
        data = leaves,
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
        angle = if (horizontal) 0 else 90, hjust = 1.05, size = 3,
        colour = "grey25"
      )
    }
  } else if (!is.null(k)) {
    # Labels are hidden but we still want to convey the k clusters. Draw a
    # coloured strip of short ticks below each leaf, one per observation, so the
    # clustering is visible without any text.
    tick_len <- max(hc$height) * 0.03
    ticks <- leaves
    ticks$yend <- -tick_len
    p <- p +
      ggplot2::geom_segment(
        data = ticks,
        ggplot2::aes(x = .data$x, xend = .data$x, y = 0, yend = .data$yend,
                     colour = .data$cluster),
        linewidth = 1.1, show.legend = FALSE
      ) +
      scale_colour_depictr(palette = pal_fun)
  }
  # When labels are hidden and there is no k, nothing is drawn at the bottom.

  # Reserve a little more room below the tree when a coloured tick strip is
  # shown so it is not clipped at the panel edge.
  lower_expand <- if (!show_labels && !is.null(k)) 0.06 else 0.12
  p <- p +
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(lower_expand, 0.04))
    ) +
    ggplot2::labs(x = NULL, y = "Height", title = title) +
    theme_depictr(grid = "none") +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank())
  if (horizontal) p <- p + ggplot2::coord_flip()
  p
}

# ---- internal helpers ------------------------------------------------------

#' @noRd
as_hclust <- function(x, cols, distance, method, scale) {
  if (inherits(x, "hclust")) return(x)
  if (inherits(x, "dist")) return(stats::hclust(x, method = method))
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame, dist or hclust object.", call. = FALSE)
  }
  if (is.null(cols)) cols <- names(x)[vapply(x, is.numeric, logical(1))]
  else check_columns(x, cols)
  mat <- as.matrix(x[stats::complete.cases(x[cols]), cols, drop = FALSE])
  if (scale) mat <- scale(mat)
  stats::hclust(stats::dist(mat, method = distance), method = method)
}

#' Compute line segments for an hclust dendrogram
#' @noRd
dendro_segments <- function(hc) {
  merge <- hc$merge
  height <- hc$height
  n <- nrow(merge) + 1L
  leaf_x <- numeric(n)
  leaf_x[hc$order] <- seq_len(n)

  node_x <- numeric(n - 1L)
  segs <- vector("list", (n - 1L) * 3L)
  s <- 1L
  for (m in seq_len(n - 1L)) {
    left <- merge[m, 1]
    right <- merge[m, 2]
    lx <- if (left < 0) leaf_x[-left] else node_x[left]
    rx <- if (right < 0) leaf_x[-right] else node_x[right]
    ly <- if (left < 0) 0 else height[left]
    ry <- if (right < 0) 0 else height[right]
    h <- height[m]
    node_x[m] <- (lx + rx) / 2
    segs[[s]] <- data.frame(x = lx, xend = lx, y = ly, yend = h)
    s <- s + 1L
    segs[[s]] <- data.frame(x = rx, xend = rx, y = ry, yend = h)
    s <- s + 1L
    segs[[s]] <- data.frame(x = lx, xend = rx, y = h, yend = h)
    s <- s + 1L
  }
  do.call(rbind, segs)
}
