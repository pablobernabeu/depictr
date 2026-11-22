# Map the missing values in a data frame

Draws a tile map of the data frame with one column per variable and one
row per observation, shading the cells that are missing. The variables
are ordered by their proportion of missing values, and that proportion
is shown in the axis labels, so variables and patterns that need
attention before modelling are easy to spot.

## Usage

``` r
missingness_map(
  data,
  cols = NULL,
  sort = TRUE,
  show_pct = TRUE,
  colours = c("grey85", depictr_accent()),
  legend_inside = FALSE,
  title = NULL
)
```

## Arguments

- data:

  A data frame.

- cols:

  Optional character vector of columns to include (by default, all).

- sort:

  Whether to order variables by their proportion of missing values.

- show_pct:

  Whether to append the percentage missing to each variable label.

- colours:

  Length-2 vector: colours for present and missing cells. Defaults to a
  muted grey (`"grey85"`) for present cells and, for missing cells, the
  accent colour set with `accent` in
  [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md),
  the colourblind-safe vermillion `#d55e00` unless changed.

- legend_inside:

  When `TRUE` and `sort = TRUE`, the legend is drawn inside the panel,
  in the top-right corner, where the most complete columns put a solid
  block of present cells, so it hides no missing cell. Otherwise, it is
  drawn in a right-hand margin. Defaults to `FALSE`.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
missingness_map(wellbeing_survey)
```
