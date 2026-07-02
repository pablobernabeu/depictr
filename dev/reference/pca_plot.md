# PCA biplot

Runs a principal component analysis on the numeric columns of a data
frame (or takes an existing
[`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html) object) and
draws a biplot: the observations projected onto two components, with the
variable loadings shown as arrows. Optionally colour the observations by
a grouping variable.

## Usage

``` r
pca_plot(
  x,
  cols = NULL,
  group = NULL,
  components = c(1, 2),
  scale = TRUE,
  loadings = TRUE,
  point_alpha = 0.7,
  palette = NULL,
  title = NULL
)
```

## Arguments

- x:

  A data frame, or a
  [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html) object.

- cols:

  When `x` is a data frame, the numeric columns to analyse (default: all
  numeric).

- group:

  Optional grouping variable (a column name when `x` is a data frame, or
  a vector the length of the data) mapped to colour.

- components:

  Length-2 integer vector: which components to plot.

- scale:

  Whether to scale the variables to unit variance before the PCA. This
  is advisable when the variables are on different scales.

- loadings:

  Whether to draw variable-loading arrows.

- point_alpha:

  Point transparency.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_palette.md).

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph", "yield"),
         group = "treatment")
```
