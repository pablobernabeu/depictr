# Forecast a seasonal series with STL plus seasonal-naive drift

A lightweight, dependency-free forecaster for a single seasonal series.
The series is decomposed with
[`stats::stl()`](https://rdrr.io/r/stats/stl.html) into trend, seasonal
and remainder. The trend is extrapolated linearly from its last
`frequency` fitted values (the recent local slope), the seasonal pattern
is carried forward by repeating the last full cycle of the seasonal
component (a seasonal-naive forecast), and the point forecast is their
sum.

## Usage

``` r
ts_forecast(x, h = 12, frequency = NULL, level = 0.95)
```

## Arguments

- x:

  A `ts` object, or a numeric vector (then `frequency` is required).

- h:

  Forecast horizon: the number of future steps (a positive integer).

- frequency:

  Number of observations per period; taken from `x` when it is a `ts`.

- level:

  Prediction-interval coverage (a single number strictly between 0 and
  1).

## Value

A data frame with one row per forecast step and columns `time` (the
future times, on the same scale as
[`stats::time()`](https://rdrr.io/r/stats/time.html)), `fit`, `lwr` and
`upr`.

## Details

Prediction intervals are a random-walk-style normal band: the one-step
standard deviation is estimated from the STL remainder and the interval
at horizon `h` is `fit +/- z * sigma * sqrt(h)`, so the band necessarily
widens with the horizon. This mirrors how seasonal-naive forecast
variance accumulates over time and gives an honest, monotonically
growing uncertainty band without pulling in a heavy modelling
dependency. For a fully specified statistical model use, for example,
[`forecast::forecast()`](https://generics.r-lib.org/reference/forecast.html)
and pass the resulting fit/interval columns to
[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
directly.

## See also

[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)

## Examples

``` r
fc <- ts_forecast(AirPassengers, h = 12)
head(fc)
#>       time      fit      lwr      upr
#> 1 1961.000 477.4164 437.8107 517.0222
#> 2 1961.083 471.7217 415.7107 527.7326
#> 3 1961.167 507.9436 439.3444 576.5427
#> 4 1961.250 506.7005 427.4890 585.9119
#> 5 1961.333 513.2907 424.7296 601.8518
#> 6 1961.417 555.3931 458.3792 652.4069
# Interval width grows with the horizon
diff(fc$upr - fc$lwr) >= 0
#>  [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
```
