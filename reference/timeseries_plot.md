# Time-series plot

Plots one or more series over time, with an optional moving-average
overlay. The input can be a `ts` object, a numeric vector, or a data
frame with a time column, a value column and an optional grouping
column.

## Usage

``` r
timeseries_plot(
  x,
  time = NULL,
  value = NULL,
  group = NULL,
  rolling = NULL,
  palette = NULL,
  point = FALSE,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- x:

  A `ts` object, a numeric vector, or a data frame.

- time:

  When `x` is a data frame, the time column (string or unquoted name);
  when `x` is a numeric vector, an optional vector of times.

- value:

  When `x` is a data frame, the value column.

- group:

  When `x` is a data frame, an optional grouping column mapped to
  colour.

- rolling:

  Optional integer window for a centred moving-average overlay.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- point:

  Add points as well as the line?

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
timeseries_plot(AirPassengers, rolling = 12,
                title = "Air passengers", y_lab = "Passengers")
```
