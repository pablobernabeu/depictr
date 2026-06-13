# Tidy raw coefficient names for display

Cleans up the term names produced by modelling functions so that they
read well on a plot: the intercept is renamed, an optional `b_`/`bs_`
Bayesian prefix is stripped, and interaction colons are converted to a
chosen symbol.

## Usage

``` r
format_terms(
  x,
  interaction = c("times", "asterisk", "colon", "space"),
  strip_prefix = TRUE,
  tidy_intercept = TRUE,
  wrap = NULL
)
```

## Arguments

- x:

  Character vector of term names.

- interaction:

  How to render interaction colons: `"times"` (the default, a Unicode
  multiplication sign), `"asterisk"`, `"colon"` (unchanged) or
  `"space"`.

- strip_prefix:

  Whether to remove a leading `b_` or `bs_` (as added by 'brms').

- tidy_intercept:

  Whether to replace `(Intercept)` with `"Intercept"`.

- wrap:

  Optional integer width at which to wrap long labels onto new lines
  (see [`base::strwrap()`](https://rdrr.io/r/base/strwrap.html)). `NULL`
  (default) leaves labels unwrapped.

## Value

A character vector the same length as `x`.

## Examples

``` r
format_terms(c("(Intercept)", "b_conditionB", "freq:condition"))
#> [1] "Intercept"        "conditionB"       "freq × condition"
format_terms("region:education:age", interaction = "asterisk")
#> [1] "region * education * age"
```
