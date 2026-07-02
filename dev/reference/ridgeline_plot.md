# Ridgeline plot

Shows the distribution of a numeric variable across the levels of a
grouping variable as a column of partially overlapping density curves –
one ridge per group, stacked up the y-axis. It compares many
distributions in a compact space, making shifts in location and shape
easy to follow, and is a clearer choice than many overlaid densities
once there are several groups.

## Usage

``` r
ridgeline_plot(
  data,
  x,
  group,
  overlap = 1.4,
  alpha = 0.85,
  scale_height = TRUE,
  palette = NULL,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- data:

  A data frame.

- x:

  The numeric variable whose distribution is shown (string or unquoted
  name).

- group:

  The grouping variable (string or unquoted name); one ridge per level.

- overlap:

  How far each ridge extends into the next, as a multiple of the row
  spacing. `1` makes the tallest ridge just touch the next baseline;
  larger values overlap more. Defaults to `1.4`.

- alpha:

  Fill transparency of the ridges.

- scale_height:

  Whether to scale every ridge to the same peak height (`TRUE`, the
  default) or keep the true relative densities (`FALSE`).

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Plot title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Densities are computed with
[`stats::density()`](https://rdrr.io/r/stats/density.html) and scaled to
a common height; the `overlap` argument controls how far each ridge
reaches into the one above. Groups with fewer than two non-missing
values are dropped with a warning. The implementation is base R +
ggplot2, with no extra package dependency.

## Examples

``` r
ridgeline_plot(wellbeing_survey, life_satisfaction, region)

ridgeline_plot(lexical_decision, RT, condition)
```
