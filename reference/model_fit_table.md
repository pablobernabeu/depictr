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

## References

McFadden D (1974). “Conditional logit analysis of qualitative choice
behavior.” In Zarembka P (ed.), *Frontiers in econometrics*, 105–142.
Academic Press, New York, NY.

## Examples

``` r
m1 <- lm(yield ~ rainfall, data = crop_yield)
m2 <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
m3 <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
         data = crop_yield)
model_fit_table(simple = m1, medium = m2, full = m3)
#>    model   n df     AIC     BIC   logLik    R2  RMSE
#> 1 simple 200  3 640.110 650.005 -317.055 0.097 1.181
#> 2 medium 200  4 591.636 604.829 -291.818 0.299 1.041
#> 3   full 200  6 422.174 441.964 -205.087 0.705 0.675
```
