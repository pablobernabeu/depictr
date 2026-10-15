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
tidy_estimates(x, conf_level = 0.95, exponentiate = FALSE, ...)
```

## Arguments

- x:

  A fitted model or a data frame of results.

- conf_level:

  Confidence (or credible) level for the interval.

- exponentiate:

  Whether to exponentiate the estimates and interval limits, which turns
  log-odds into odds ratios and log rates into rate ratios. The
  `std.error` column stays on the link scale, as in
  [`broom::tidy()`](https://generics.r-lib.org/reference/tidy.html). A
  data frame is read as estimates on the link scale. Defaults to
  `FALSE`.

- ...:

  Passed to methods (and to
  [`broom::tidy()`](https://generics.r-lib.org/reference/tidy.html) in
  the fallback). The `merMod` method additionally accepts `effects`,
  which currently only supports `"fixed"`.

## Value

A data frame with one row per term and the columns `term`, `estimate`,
`std.error`, `conf.low` and `conf.high`.

## Details

Methods are provided for `lm`, `glm` and `merMod` (mixed models fitted
with 'lme4') objects, and for data frames. For any other model class the
function falls back to
[`broom::tidy()`](https://generics.r-lib.org/reference/tidy.html) when
the 'broom' package is installed.

Confidence intervals are Wald intervals, estimate +/- multiplier \*
standard error, with the multiplier the model's own tests use. An `lm`
object gets the t interval of
[`stats::confint()`](https://rdrr.io/r/stats/confint.html). A `glm`
whose dispersion is estimated (Gaussian, Gamma, inverse Gaussian and
quasi families) gets t on the residual degrees of freedom, since
[`stats::summary.glm()`](https://rdrr.io/r/stats/summary.glm.html) then
tests with t. One whose dispersion is fixed (binomial, Poisson and
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html)) gets z.
The choice is read from the column the summary reports, "t value" or "z
value". At 12 residual degrees of freedom, the t interval is about 11%
wider than the z interval, and at 100 about 1% wider. A `merMod` fit
gets z, since 'lme4' gives no degrees of freedom. Supply a data frame
with your own intervals (for example profiled or posterior intervals) to
override this.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
tidy_estimates(fit)
#>                term     estimate    std.error     conf.low   conf.high
#> 1       (Intercept) -0.764921362 0.3933784207 -1.540719161 0.010876437
#> 2          rainfall  0.004527229 0.0007284476  0.003090628 0.005963831
#> 3        fertiliser  0.010488592 0.0013233496  0.007878760 0.013098424
#> 4 treatmentenhanced  1.290135752 0.1189761405  1.055498001 1.524773503

# Odds ratios from a logistic regression:
gfit <- glm(accuracy ~ word_frequency + condition,
            data = lexical_decision, family = binomial)
tidy_estimates(gfit, exponentiate = TRUE)
#>                 term  estimate std.error  conf.low conf.high
#> 1        (Intercept) 6.4237841 0.3895402 2.9937372 13.783776
#> 2     word_frequency 1.3544310 0.1132865 1.0847440  1.691167
#> 3 conditionunrelated 0.8622706 0.2726054 0.5053607  1.471247

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
