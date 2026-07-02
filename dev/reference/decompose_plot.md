# Time-series decomposition plot

Decomposes a seasonal time series into trend, seasonal and remainder
components and shows them, with the original series, as stacked panels.

## Usage

``` r
decompose_plot(
  x,
  frequency = NULL,
  method = c("stl", "classical"),
  robust = FALSE,
  confidence = FALSE,
  level = 0.95,
  title = NULL
)
```

## Arguments

- x:

  A `ts` object, or a numeric vector (then `frequency` is required).

- frequency:

  Number of observations per period (e.g. 12 for monthly data); taken
  from `x` when it is a `ts`.

- method:

  `"stl"` (loess-based) or `"classical"`
  ([`stats::decompose()`](https://rdrr.io/r/stats/decompose.html)).

- robust:

  For `method = "stl"`, whether to fit a robust STL
  ([`stats::stl()`](https://rdrr.io/r/stats/stl.html) with
  `robust = TRUE`), which down-weights outliers in the loess fits so
  that an unusual point bleeds less into the trend and seasonal
  components. Ignored for the classical method.

- confidence:

  Whether to draw a confidence ribbon around the trend component. The
  band is a normal-approximation interval based on the remainder's
  standard deviation (see Details). `FALSE` reproduces the previous
  behaviour exactly.

- level:

  Coverage of the trend confidence ribbon (a single number strictly
  between 0 and 1).

- title:

  Plot title.

## Value

A 'patchwork' object (printable like a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)).

## Details

The trend confidence ribbon is a pragmatic normal-approximation band:
`trend +/- z * sd(remainder)`, where `z = qnorm((1 + level) / 2)` and
the remainder standard deviation is computed on the non-missing
remainder values. It conveys the scale of the unexplained variation
around the smoothed trend rather than a formal sampling-distribution
interval.

## See also

[`ts_forecast()`](https://pablobernabeu.github.io/depictr/dev/reference/ts_forecast.md),
[`seasonal_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/seasonal_plot.md)

## Examples

``` r
decompose_plot(AirPassengers)

decompose_plot(AirPassengers, method = "classical")

# Robust STL with a confidence ribbon on the trend
decompose_plot(AirPassengers, robust = TRUE, confidence = TRUE)
```
