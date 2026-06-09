# Extract a tidy table of estimates

`tidy_estimates()` turns the output of a model (or an existing data
frame of results) into a single standardised table with the columns
`term`, `estimate`, `std.error`, `conf.low` and `conf.high`. It is the
common currency used by
[`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
and
[`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md),
but is useful on its own.

## Usage

``` r
tidy_estimates(x, conf_level = 0.95, ...)
```

## Arguments

- x:

  A fitted model or a data frame of results.

- conf_level:

  Confidence (or credible) level for the interval.

- ...:

  Passed to methods (and to
  [`broom::tidy()`](https://broom.tidymodels.org/reference/reexports.html)
  in the fallback). The `merMod` method additionally accepts `effects`,
  which currently only supports `"fixed"`.

## Value

A data frame with one row per term and the columns `term`, `estimate`,
`std.error`, `conf.low` and `conf.high`.

## Details

Methods are provided for `lm`, `glm` and `merMod` (mixed models fitted
with 'lme4') objects, and for data frames. For any other model class the
function falls back to
[`broom::tidy()`](https://broom.tidymodels.org/reference/reexports.html)
when the 'broom' package is installed.

Confidence intervals are computed with the normal approximation
(estimate +/- z \* standard error) for `glm` and `merMod` objects, which
is fast and dependency-free; `lm` objects use the exact t-based
interval. Supply a data frame with your own intervals (for example
profiled or posterior intervals) to override this.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
tidy_estimates(fit)
#>                term     estimate    std.error     conf.low   conf.high
#> 1       (Intercept) -0.275272372 0.3918770683 -1.048109292 0.497564549
#> 2          rainfall  0.004354379 0.0007256674  0.002923260 0.005785498
#> 3        fertilizer  0.010805426 0.0013182990  0.008205554 0.013405297
#> 4 treatmentenhanced  0.667003840 0.1185220609  0.433261598 0.900746082

# A data frame of pre-computed estimates is standardised, not re-fitted:
df <- data.frame(
  parameter = c("a", "b"),
  Estimate = c(0.2, -0.4),
  "2.5 %" = c(0.1, -0.6),
  "97.5 %" = c(0.3, -0.2),
  check.names = FALSE
)
tidy_estimates(df)
#>   term estimate std.error conf.low conf.high
#> 1    a      0.2        NA      0.1       0.3
#> 2    b     -0.4        NA     -0.6      -0.2
```
