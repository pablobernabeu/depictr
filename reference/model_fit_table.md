# Goodness-of-fit statistics across models

Collects the usual model-comparison statistics into one tidy data frame,
one row per model. These comprise the number of observations, the
degrees of freedom, AIC, BIC, the log-likelihood, an R-squared and the
root-mean-square error.

## Usage

``` r
model_fit_table(..., digits = 3)
```

## Arguments

- ...:

  One or more fitted models. Name the arguments to label the rows.

- digits:

  Number of decimal places to round to.

## Value

A data frame with one row per model and columns `model`, `n`, `df`,
`AIC`, `BIC`, `logLik`, `R2` and `RMSE`.

## Details

The R-squared depends on the kind of model. An `lm` reports the ordinary
coefficient of determination. Every `glm`, including quasi-likelihood
families and negative binomial fits from
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html), reports
the deviance R-squared, \\1 - D/D_0\\. Here \\D\\ is the residual
deviance of the model and \\D_0\\ the deviance of the null model, which
[`stats::glm()`](https://rdrr.io/r/stats/glm.html) fits to the same rows
with the same prior weights and offset. The null model has an intercept
only if the model has one. Both deviances are stored with the fit, so
nothing is refitted. The value is the share of the null deviance that
the predictors explain, the Kullback-Leibler R-squared of Cameron and
Windmeijer (1997). It equals the ordinary R-squared for a Gaussian model
with the identity link and McFadden's (1974) pseudo-R-squared for binary
logistic regression. For Poisson, grouped binomial, Gamma and other
models, the two measures differ. Mixed models (`merMod`) report an
R-squared of `NA`, since no single definition is standard for them.

A linear mixed model fitted with
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) by restricted
maximum likelihood (REML, its default) is refitted by maximum likelihood
with [`lme4::refitML()`](https://rdrr.io/pkg/lme4/man/refitML.html). Its
AIC, BIC and log-likelihood come from the refit, and a message says so.
A REML likelihood is the likelihood of the residuals left once the fixed
effects are removed. Two models with different fixed effects therefore
have REML likelihoods of different data, and their criteria cannot be
compared. The [`anova()`](https://rdrr.io/r/stats/anova.html) method for
lme4 fits refits them by maximum likelihood for the same reason. If a
refit fails, a warning says so, and that model's `df`, `AIC`, `BIC` and
`logLik` are `NA`. The other columns describe the model as supplied.

## References

Cameron AC, Windmeijer FAG (1997). “An R-squared measure of goodness of
fit for some common nonlinear regression models.” *Journal of
Econometrics*, **77**(2), 329–342.
[doi:10.1016/S0304-4076(96)01818-0](https://doi.org/10.1016/S0304-4076%2896%2901818-0)
.

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
