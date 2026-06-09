# Time-series decomposition plot

Decomposes a seasonal time series into trend, seasonal and remainder
components and shows them, with the original series, as stacked panels.

## Usage

``` r
decompose_plot(
  x,
  frequency = NULL,
  method = c("stl", "classical"),
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

- title:

  Plot title.

## Value

A 'patchwork' object (printable like a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)).

## Examples

``` r
decompose_plot(AirPassengers)

decompose_plot(AirPassengers, method = "classical")
```
