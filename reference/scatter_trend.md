# Scatter plot with a fitted trend

Plots `y` against `x` with an optional fitted trend line and confidence
band, optionally split by a grouping variable.

## Usage

``` r
scatter_trend(
  data,
  x,
  y,
  group = NULL,
  method = "lm",
  se = TRUE,
  point_alpha = 0.6,
  palette = NULL,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- data:

  A data frame.

- x, y:

  The variables for the horizontal and vertical axes (string or unquoted
  column name).

- group:

  Optional grouping variable mapped to colour.

- method:

  Smoothing method passed to
  [`ggplot2::geom_smooth()`](https://ggplot2.tidyverse.org/reference/geom_smooth.html),
  e.g. `"lm"`, `"loess"`, or `NULL` for no trend line.

- se:

  Whether to draw the confidence band around the trend.

- point_alpha:

  Point transparency.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Title and axis labels (default to variable names).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
scatter_trend(crop_yield, fertilizer, yield)

scatter_trend(crop_yield, fertilizer, yield, group = treatment,
                   method = "lm")
```
