# Raincloud plot

A "raincloud" combines three views of a distribution: a half-violin
density (the cloud), a narrow boxplot, and the raw jittered points (the
rain). It shows the shape, the summary and the individual data at once,
and is a popular, transparent alternative to the bare boxplot.
Implemented with base graphics primitives, so it needs no extra
packages.

## Usage

``` r
raincloud_plot(
  data,
  y,
  group = NULL,
  width = 0.4,
  point_alpha = 0.4,
  palette = NULL,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- data:

  A data frame.

- y:

  The numeric variable (string or unquoted name).

- group:

  Optional grouping variable on the x-axis.

- width:

  Maximum width of the half-violin.

- point_alpha:

  Transparency of the rain points.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
raincloud_plot(lexical_decision, RT, group = condition)

raincloud_plot(crop_yield, yield, group = treatment)
```
