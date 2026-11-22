# Plot the distribution of a variable

Draws a histogram, a density curve or both, optionally split by a
grouping variable, for a first look at a continuous variable.

## Usage

``` r
explore_distribution(
  data,
  x,
  group = NULL,
  type = c("histogram", "density", "both"),
  bins = 30,
  alpha = 0.6,
  position = NULL,
  palette = NULL,
  facet = FALSE,
  legend_inside = FALSE,
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

  Optional grouping variable (string or unquoted name) mapped to colour
  and fill. A numeric code counts as a group, but a numeric column with
  more than 20 distinct values is refused as continuous. Rows with a
  missing group are dropped with a message, and levels without rows are
  left out of the plot and its palette.

- type:

  One of `"histogram"`, `"density"` or `"both"`.

- bins:

  Number of histogram bins.

- alpha:

  Fill transparency, which helps when groups overlap.

- position:

  Histogram position adjustment, such as `"identity"`, `"stack"` or
  `"dodge"`. The default (`NULL`) chooses `"dodge"` when `group` is set,
  so that overlapping bars stay readable, and `"identity"` otherwise.

- palette:

  Colours for the groups. Defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- facet:

  When a `group` is given, whether to draw one panel per group in place
  of an overlay. Panels are much clearer once there are more than two or
  three groups, since overlaid histograms in particular become hard to
  read. Defaults to `FALSE`. Ignored when there is no `group`.

- legend_inside:

  When `TRUE` and a `group` is given without `facet`, the colour legend
  is drawn inside the panel, over a translucent background, in the
  top-right corner, which a unimodal histogram or density leaves empty.
  Otherwise, it is drawn in a right-hand margin. Defaults to `FALSE`.

- title, x_lab:

  Plot title and x-axis label, which defaults to the variable name.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
explore_distribution(lexical_decision, RT)

explore_distribution(lexical_decision, RT, group = condition, type = "density")

# One panel per group keeps many groups legible:
explore_distribution(wellbeing_survey, life_satisfaction, group = region,
                     type = "both", facet = TRUE)
```
