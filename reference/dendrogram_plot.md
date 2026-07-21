# Dendrogram

Hierarchical-clustering dendrogram, drawn with ggplot2 so it shares the
package theme. Accepts a data frame (the distance matrix and clustering
are computed for you), a
[stats::dist](https://rdrr.io/r/stats/dist.html) object, or an
[stats::hclust](https://rdrr.io/r/stats/hclust.html) object. Optionally
cut the tree into `k` clusters, colouring the leaf labels and drawing
the cut height.

## Usage

``` r
dendrogram_plot(
  x,
  cols = NULL,
  distance = "euclidean",
  method = "complete",
  scale = TRUE,
  k = NULL,
  horizontal = FALSE,
  labels = NULL,
  palette = NULL,
  title = NULL
)
```

## Arguments

- x:

  A data frame, a `dist` object, or an `hclust` object.

- cols:

  When `x` is a data frame, the numeric columns to use.

- distance:

  Distance measure passed to
  [`stats::dist()`](https://rdrr.io/r/stats/dist.html).

- method:

  Linkage method passed to
  [`stats::hclust()`](https://rdrr.io/r/stats/hclust.html).

- scale:

  Whether to scale variables before computing distances (data frame
  input).

- k:

  Optional number of clusters to highlight (between 1 and the number of
  leaves). The cut-height line is drawn only when `2 <= k < n`.

- horizontal:

  Whether to draw the tree horizontally.

- labels:

  Whether to print the leaf labels. `NULL` (the default) chooses
  automatically: labels are shown for small trees (up to 40 leaves) and
  suppressed for larger ones, where they would otherwise collapse into
  an unreadable smear. `TRUE`/`FALSE` force them on or off. When labels
  are hidden and `k` is set, the cluster membership is instead conveyed
  by a coloured strip of leaf ticks along the bottom of the tree.

- palette:

  Colours for the `k` clusters; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# Cluster the survey regions by their wellbeing averages
d <- aggregate(cbind(stress, sleep_hours, life_satisfaction) ~ region,
               data = wellbeing_survey, FUN = mean)
rownames(d) <- d$region
dendrogram_plot(d[-1], k = 2)
```
