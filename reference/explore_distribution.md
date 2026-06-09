# Plot the distribution of a variable

Draws a histogram, a density curve, or both, optionally split by a
grouping variable. A quick first look at a continuous variable.

## Usage

``` r
explore_distribution(
  data,
  x,
  group = NULL,
  type = c("histogram", "density", "both"),
  bins = 30,
  alpha = 0.6,
  position = "identity",
  palette = NULL,
  title = NULL,
  x_lab = NULL
)
```

## Arguments

- data:

  A data frame.

- x:

  The continuous variable to display. Either a string or an unquoted
  column name.

- group:

  Optional grouping variable (string or unquoted name) mapped to
  colour/fill.

- type:

  One of `"histogram"`, `"density"` or `"both"`.

- bins:

  Number of histogram bins.

- alpha:

  Fill transparency (useful when groups overlap).

- position:

  Histogram position adjustment, e.g. `"identity"`, `"stack"` or
  `"dodge"`.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab:

  Plot title and x-axis label (defaults to the variable name).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
explore_distribution(lexical_decision, RT)

explore_distribution(lexical_decision, RT, group = condition, type = "density")
```
