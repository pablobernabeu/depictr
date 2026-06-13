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
  hulls = TRUE,
  label_centers = TRUE,
  point_alpha = 0.8,
  palette = NULL,
  title = NULL
)
```

## Arguments

- data:

  A data frame.

- cols:

  Numeric columns to cluster on (default: all numeric).

- k:

  Number of clusters for k-means (ignored if `clusters` is supplied).

- clusters:

  Optional vector of cluster assignments (e.g. from
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html) or
  [`stats::cutree()`](https://rdrr.io/r/stats/cutree.html)); use this to
  plot a clustering you computed yourself.

- scale:

  Whether to scale variables to unit variance before clustering and the
  PCA.

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

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
cluster_plot(crop_yield, cols = c("rainfall", "fertilizer", "soil_ph",
                                  "yield"), k = 3)
```
