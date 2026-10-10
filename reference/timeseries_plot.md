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
  forecast = NULL,
  frequency = NULL,
  level = 0.95,
  lambda = NULL,
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

  Optional integer window for a centred moving-average overlay. The data
  are ordered by time (within each group) before the moving average is
  computed, so unsorted input is handled correctly.

- forecast:

  Optional forecast overlay for a single (non-grouped) series. Either an
  integer horizon (number of future steps) to forecast with the built-in
  STL plus random walk with drift (see
  [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)),
  or a pre-computed forecast supplied as a data frame with columns
  `time`, `fit` and (optionally) `lwr`/`upr`, for instance from a fitted
  [`forecast::forecast()`](https://generics.r-lib.org/reference/forecast.html)
  object. The point forecast continues the line and a shaded
  prediction-interval ribbon is drawn behind it. The built-in forecast
  is captioned with its coverage and method, and its band widens with
  the horizon on the scale it is made on (see `lambda`). For a numeric
  `x`, it is made from the values in time order and continues the
  history's own time axis, one typical step at a time.

- frequency:

  Number of observations per period, used only to coerce a numeric `x`
  to a `ts` when an integer `forecast` horizon is requested.

- level:

  Prediction-interval coverage for the built-in forecast (a single
  number strictly between 0 and 1, e.g. `0.95`).

- lambda:

  Optional Box-Cox transformation for the built-in forecast, passed to
  [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md).
  `0` forecasts on the log scale, which suits a series whose seasonal
  swing grows with its level.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- point:

  Whether to add points as well as the line.

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md),
[`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md),
[`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md)

## Examples

``` r
timeseries_plot(AirPassengers, rolling = 12,
                title = "Air passengers", y_lab = "Passengers")

# 24-month forecast with a 90% prediction interval, made on the log scale
# because the seasonal swing grows with the number of passengers
timeseries_plot(AirPassengers, forecast = 24, level = 0.9, lambda = 0)
```
