# Bar chart of a categorical variable

Counts (or proportions) of the levels of a categorical variable,
optionally split by a grouping variable.

## Usage

``` r
explore_categorical(
  data,
  x,
  group = NULL,
  proportion = FALSE,
  position = c("dodge", "stack", "fill"),
  sort = TRUE,
  horizontal = FALSE,
  palette = NULL,
  title = NULL,
  x_lab = NULL
)
```

## Arguments

- data:

  A data frame.

- x:

  The categorical variable (string or unquoted name).

- group:

  Optional grouping variable mapped to fill.

- proportion:

  Show proportions instead of counts? When `group` is set, proportions
  are computed within each group.

- position:

  Bar position when `group` is set: `"dodge"`, `"stack"` or `"fill"`.

- sort:

  Order the bars from most to least frequent?

- horizontal:

  Draw horizontal bars (helpful with many or long labels)?

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab:

  Plot title and category-axis label (defaults to the variable name).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
explore_categorical(wellbeing_survey, region)

explore_categorical(wellbeing_survey, education, group = region,
                    proportion = TRUE, position = "dodge")
```
