# Cluster scatter plot

Runs k-means clustering on the numeric columns of a data frame (or uses
a supplied cluster assignment) and plots the observations on the first
two principal components, coloured by cluster, with optional convex
hulls and labelled centroids. Projecting onto principal components means
the plot works for any number of variables.

## Usage

``` r
cluster_plot(
  data,
  cols = NULL,
  k = 3,
  clusters = NULL,
  scale = TRUE,
  suggest_k = NULL,
  k_range = 2:8,
  hulls = TRUE,
  label_centers = TRUE,
  point_alpha = 0.8,
  palette = NULL,
  title = NULL,
  seed = NULL,
  nstart = 10,
  iter.max = 10
)
```

## Arguments

- data:

  A data frame.

- cols:

  Numeric columns to cluster on (default: all numeric).

- k:

  Number of clusters for k-means (ignored if `clusters` is supplied, or
  overridden when `suggest_k` chooses a value).

- clusters:

  Optional vector of cluster assignments (e.g. from
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html) or
  [`stats::cutree()`](https://rdrr.io/r/stats/cutree.html)); use this to
  plot a clustering you computed yourself. Hierarchical or PAM
  assignments (such as
  [`stats::cutree()`](https://rdrr.io/r/stats/cutree.html) output
  matching
  [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md))
  are accepted. Must have exactly one entry per row of `data` (rows with
  missing values in `cols` are dropped from both before plotting).

- scale:

  Whether to scale variables to unit variance before clustering and the
  PCA.

- suggest_k:

  Optionally choose `k` automatically with a cluster-quality diagnostic
  instead of using the supplied `k`. Either `TRUE` (uses the
  average-silhouette criterion), a string naming the criterion
  (`"silhouette"`, `"wss"` or `"gap"`; see
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)),
  or `NULL` (the default) to leave `k` unchanged. Ignored when
  `clusters` is supplied.

- k_range:

  Candidate values of `k` searched when `suggest_k` is set.

- hulls:

  Whether to draw a shaded convex hull around each cluster.

- label_centers:

  Whether to label the cluster centroids.

- point_alpha:

  Point transparency.

- palette:

  Colours for the clusters; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title:

  Plot title.

- seed:

  Optional integer seed for reproducible k-means (ignored when
  `clusters` is supplied). Default `NULL` leaves the RNG state
  untouched.

- nstart:

  Number of random starts for
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html).

- iter.max:

  Maximum iterations for
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. When `suggest_k` is used, the chosen `k` and the full diagnostic
are attached as the attribute `"k_diagnostic"`.

## See also

[`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
and
[`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
for cluster-quality diagnostics.

## Examples

``` r
cluster_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
                                  "yield"), k = 3, seed = 1)

# Let a silhouette diagnostic choose k:
cluster_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
                                  "yield"), suggest_k = TRUE, k_range = 2:6,
             seed = 1)
```
