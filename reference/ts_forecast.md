# Forecast a seasonal series with STL and a random walk with drift

A dependency-free forecaster for a single seasonal series, which
forecasts by decomposition (Hyndman & Athanasopoulos, 2021, Section
5.7). [`stats::stl()`](https://rdrr.io/r/stats/stl.html) with
`s.window = "periodic"` estimates a seasonal component that repeats
unchanged in every cycle (Cleveland et al., 1990). The seasonally
adjusted series, the data minus that component, is forecast with a
random walk with drift, and the last cycle of the seasonal component is
added back. The result reproduces
`forecast::stlf(x, method = "rwdrift", s.window = "periodic")`.

## Usage

``` r
ts_forecast(x, h = 12, frequency = NULL, level = 0.95, lambda = NULL)
```

## Arguments

- x:

  A `ts` object, or a numeric vector (then `frequency` is required),
  holding one series. It needs more than two full cycles of
  observations. Missing values at either end are trimmed, so the
  forecast starts after the last observation, and a missing value inside
  the series is an error. A multivariate `ts` or a matrix with several
  columns is refused.

- h:

  Forecast horizon: the number of future steps (a positive integer).

- frequency:

  Number of observations per period; taken from `x` when it is a `ts`.

- level:

  Prediction-interval coverage (a single number strictly between 0 and
  1).

- lambda:

  Optional Box-Cox transformation parameter. `NULL`, the default,
  forecasts the series as it is. `0` forecasts its logarithm, and any
  other number forecasts `(x^lambda - 1) / lambda`. Every observation
  must then be positive. The forecasts and limits are transformed back
  to the original scale, where the point forecast is the median of the
  forecast distribution, without the bias adjustment that would make it
  the mean (Hyndman & Athanasopoulos, 2021, Section 5.6). A forecast or
  limit beyond the range the transformation can reach comes back as `0`
  (for a positive `lambda`) or `Inf` (for a negative one).

## Value

A data frame with one row per forecast step and columns `time` (the
future times, on the same scale as
[`stats::time()`](https://rdrr.io/r/stats/time.html)), `fit`, `lwr` and
`upr`.

## Details

The prediction interval at horizon `h` is `fit +/- z * sigma_h`, with
`z = qnorm((1 + level) / 2)`. The forecast standard deviation is that of
a random walk with drift,
`sigma_h = sigma * sqrt(h * (1 + h / (T - 1)))` (Hyndman &
Athanasopoulos, 2021, Section 5.5), where `sigma` is the standard
deviation of the steps of the seasonally adjusted series and `T` the
length of the series. The band widens with the horizon, and the second
term carries the uncertainty in the estimated drift.

The model assumes a seasonal pattern that adds to the level of the
series and stays the same from cycle to cycle. When the seasonal swing
grows with the level, as in `AirPassengers`, forecast on the log scale
with `lambda = 0`. The band treats the seasonal component as known, so
it leaves out the uncertainty in estimating it. In a rolling-origin
backtest on five classic series whose seasonal swing does not grow with
their level, the nominal 95% band covered 92% of one-step-ahead outcomes
(`dev/ts_forecast_backtest.R` in the source repository). From three to
12 steps ahead, it covered 99%. The band therefore runs somewhat narrow
at the shortest horizons and wide further out, where the uncertainty of
a random walk keeps growing while these series stay close to their
trend. For a different model, fit it with, for example,
[`forecast::forecast()`](https://generics.r-lib.org/reference/forecast.html)
and pass its columns to
[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
as a data frame.

## References

Cleveland RB, Cleveland WS, McRae JE, Terpenning I (1990). “STL: A
seasonal-trend decomposition procedure based on loess.” *Journal of
Official Statistics*, **6**(1), 3–73.

Hyndman RJ, Athanasopoulos G (2021). *Forecasting: Principles and
practice*, 3rd edition. OTexts, Melbourne, Australia.
<https://otexts.com/fpp3/>.

## See also

[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md),
[`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)

## Examples

``` r
# The seasonal swing of AirPassengers grows with the number of passengers,
# so it is forecast on the log scale.
fc <- ts_forecast(AirPassengers, h = 12, lambda = 0)
head(fc)
#>       time      fit      lwr      upr
#> 1 1961.000 440.0658 409.0407 473.4443
#> 2 1961.083 434.4320 391.6185 481.9261
#> 3 1961.167 499.4146 439.6286 567.3309
#> 4 1961.250 489.3344 422.1291 567.2391
#> 5 1961.333 493.5143 418.1409 582.4744
#> 6 1961.417 564.4599 470.4572 677.2453
# On that scale, the band widens with the horizon
diff(log(fc$upr) - log(fc$lwr)) > 0
#>  [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
```
