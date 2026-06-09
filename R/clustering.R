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
#' @param k Number of clusters for k-means (ignored if `clusters` is supplied).
#' @param clusters Optional vector of cluster assignments (e.g. from
#'   [stats::kmeans()] or [stats::cutree()]); use this to plot a clustering you
#'   computed yourself.
#' @param scale Scale variables to unit variance before clustering and the PCA?
#' @param hulls Draw a shaded convex hull around each cluster?
#' @param label_centers Label the cluster centroids?
#' @param point_alpha Point transparency.
#' @param palette Colours for the clusters; defaults to [statviz_palette()].
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' cluster_plot(crop_yield, cols = c("rainfall", "fertilizer", "soil_ph",
#'                                   "yield"), k = 3)
cluster_plot <- function(data, cols = NULL, k = 3, clusters = NULL,
                         scale = TRUE, hulls = TRUE, label_centers = TRUE,
                         point_alpha = 0.8, palette = NULL, title = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(cols)) cols <- names(data)[vapply(data, is.numeric, logical(1))]
  else check_columns(data, cols)
  if (length(cols) < 2) stop("Need at least two numeric columns.", call. = FALSE)

  cc <- stats::complete.cases(data[cols])
  mat <- as.matrix(data[cc, cols, drop = FALSE])
  X <- if (scale) scale(mat) else mat

  if (is.null(clusters)) {
    km <- stats::kmeans(X, centers = k, nstart = 10)
    cl <- km$cluster
  } else {
    cl <- clusters[cc]
    if (length(cl) != nrow(X)) {
      stop("`clusters` must have one entry per row of `data`.", call. = FALSE)
    }
  }

  pca <- stats::prcomp(X, center = TRUE, scale. = FALSE)
  ve <- (pca$sdev^2) / sum(pca$sdev^2)
  df <- data.frame(PCx = pca$x[, 1], PCy = pca$x[, 2],
                   cluster = factor(cl))
  pal <- palette %||% statviz_palette(nlevels(df$cluster))

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
    ) + ggplot2::scale_fill_manual(values = pal, guide = "none")
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

  p +
    ggplot2::scale_colour_manual(values = pal, name = "Cluster") +
    ggplot2::labs(
      x = sprintf("PC1 (%.1f%%)", 100 * ve[1]),
      y = sprintf("PC2 (%.1f%%)", 100 * ve[2]),
      title = title
    ) +
    theme_statviz()
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
#' @param scale Scale variables before computing distances (data frame input)?
#' @param k Optional number of clusters to highlight.
#' @param horizontal Draw the tree horizontally?
#' @param palette Colours for the `k` clusters; defaults to [statviz_palette()].
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
                            horizontal = FALSE, palette = NULL, title = NULL) {
  hc <- as_hclust(x, cols, distance, method, scale)
  segs <- dendro_segments(hc)
  # Position leaves at their plot x and y = 0
  leaf_x <- numeric(length(hc$order))
  leaf_x[hc$order] <- seq_along(hc$order)
  leaves <- data.frame(x = leaf_x, y = 0,
                       label = hc$labels %||% as.character(seq_along(leaf_x)))

  if (!is.null(k)) {
    cl <- stats::cutree(hc, k = k)
    leaves$cluster <- factor(cl[match(leaves$label, names(cl))])
    cut_h <- mean(rev(hc$height)[c(k - 1, k)])
  }

  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = segs,
      ggplot2::aes(x = .data$x, xend = .data$xend, y = .data$y,
                   yend = .data$yend),
      colour = "grey35", linewidth = 0.4
    )

  if (!is.null(k)) {
    pal <- palette %||% statviz_palette(nlevels(leaves$cluster))
    p <- p +
      ggplot2::geom_hline(yintercept = cut_h, linetype = 2,
                          colour = "grey70") +
      ggplot2::geom_text(
        data = leaves,
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$label,
                     colour = .data$cluster),
        angle = if (horizontal) 0 else 90,
        hjust = 1.05, size = 3, show.legend = FALSE
      ) +
      ggplot2::scale_colour_manual(values = pal)
  } else {
    p <- p + ggplot2::geom_text(
      data = leaves,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      angle = if (horizontal) 0 else 90, hjust = 1.05, size = 3,
      colour = "grey25"
    )
  }

  p <- p +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.12, 0.04))) +
    ggplot2::labs(x = NULL, y = "Height", title = title) +
    theme_statviz(grid = "none") +
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
    segs[[s]] <- data.frame(x = lx, xend = lx, y = ly, yend = h); s <- s + 1L
    segs[[s]] <- data.frame(x = rx, xend = rx, y = ry, yend = h); s <- s + 1L
    segs[[s]] <- data.frame(x = lx, xend = rx, y = h, yend = h);  s <- s + 1L
  }
  do.call(rbind, segs)
}
