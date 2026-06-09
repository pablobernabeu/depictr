# Compare group means with confidence intervals

An estimation-style plot of a numeric outcome across the levels of a
grouping variable: each group's mean with a confidence interval, over a
backdrop of the raw (jittered) data. A clearer answer to "do these
groups differ?" than a bar chart, because it shows both the estimate and
its uncertainty.

## Usage

``` r
group_comparison_plot(
  data,
  y,
  group,
  conf_level = 0.95,
  show_points = TRUE,
  point_alpha = 0.25,
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

  The numeric outcome (string or unquoted name).

- group:

  The grouping variable (string or unquoted name).

- conf_level:

  Confidence level for the intervals (t-based).

- show_points:

  Draw the raw data behind the means?

- point_alpha:

  Transparency of the raw points.

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
group_comparison_plot(lexical_decision, RT, condition)

group_comparison_plot(crop_yield, yield, treatment)
```
