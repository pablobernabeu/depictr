# Seasonal-subseries (cycle) plot

Draws a seasonal-subseries plot (also called a cycle plot): the series
is split into one small panel per season (e.g. one panel per calendar
month for monthly data), and within each panel the value is drawn across
successive cycles (e.g. across years). A horizontal reference line in
every panel marks that season's mean. This makes the seasonal pattern
(differences *between* panels) and the within-season trend over time
(the slope *inside* each panel) visible at the same time, which a single
overlaid line cannot show.

## Usage

``` r
seasonal_plot(
  x,
  frequency = NULL,
  style = c("subseries", "season"),
  season_labels = NULL,
  means = TRUE,
  point = TRUE,
  palette = NULL,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- x:

  A `ts` object, or a numeric vector (then `frequency` is required).

- frequency:

  Number of observations per period (e.g. 12 for monthly data); taken
  from `x` when it is a `ts`.

- style:

  `"subseries"` for the faceted cycle plot (one panel per season) or
  `"season"` for one line per cycle across the seasons.

- season_labels:

  Optional character vector of length `frequency` giving the season
  (panel/axis) labels, e.g. `month.abb`. When `NULL` (default) sensible
  labels are inferred (month abbreviations for frequency 12, quarter
  labels for frequency 4, otherwise the season index).

- means:

  Whether to draw the per-season mean reference line
  (`style = "subseries"` only).

- point:

  Whether to add points as well as the connecting line.

- palette:

  Colours used for the cycle lines when `style = "season"`; defaults to
  a sequential ramp from
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Two layouts are offered. With `style = "subseries"` (the default) the
panels are faceted side by side, each tracing one season across cycles –
the classic Cleveland cycle plot, matching `feasts::gg_subseries()`.
With `style = "season"` every cycle is drawn as its own line over the
seasons on a shared axis (the seasonal-plot layout of
[`forecast::ggseasonplot()`](https://pkg.robjhyndman.com/forecast/reference/seasonplot.html)),
which is handy for spotting an unusual year.

## See also

[`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md),
[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)

## Examples

``` r
# Monthly air passengers: rising within-month trend, summer peak
seasonal_plot(AirPassengers)

seasonal_plot(AirPassengers, style = "season")
```
