# Goodness-of-fit statistics across models

Collects the usual model-comparison statistics into one tidy data frame,
one row per model. These comprise the number of observations, the
degrees of freedom, AIC, BIC, the log-likelihood, an R-squared (ordinary
for `lm` and McFadden's pseudo-R-squared for `glm`) and the
root-mean-square error.

## Usage

``` r
model_fit_table(..., digits = 3)
```

## Arguments

- ...:

  Two or more fitted models. Name the arguments to label the rows.

- digits:

  Number of decimal places to round to.

## Value

A data frame with one row per model and columns `model`, `n`, `df`,
`AIC`, `BIC`, `logLik`, `R2` and `RMSE`.

## Examples

``` r
m1 <- lm(yield ~ rainfall, data = crop_yield)
m2 <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
m3 <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment,
         data = crop_yield)
model_fit_table(simple = m1, medium = m2, full = m3)
#>    model   n df     AIC     BIC   logLik    R2  RMSE
#> 1 simple 200  3 585.479 595.374 -289.739 0.114 1.030
#> 2 medium 200  4 526.072 539.266 -259.036 0.348 0.884
#> 3   full 200  6 406.816 426.606 -197.408 0.648 0.649
```
