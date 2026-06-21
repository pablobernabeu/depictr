# Tidy raw coefficient names for display

Cleans up the term names produced by modelling functions so that they
read well on a plot: the intercept is renamed, an optional `b_`/`bs_`
Bayesian prefix is stripped, interaction colons are converted to a
chosen symbol, and underscores are shown as spaces (e.g.
`word_frequency` becomes `"word frequency"`). The `b_`/`bs_` prefix is
stripped from *each* component of an interaction (e.g. `b_x:b_y`), not
just the leading term. Missing values (`NA`) are kept as `NA` rather
than being rendered as the literal text `"NA"`.

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

  Whether to remove a leading `b_` or `bs_` (as added by 'brms') from
  each interaction component.

- tidy_intercept:

  Whether to replace `(Intercept)` with `"Intercept"`.

- wrap:

  Optional integer width at which to wrap long labels onto new lines
  (see [`base::strwrap()`](https://rdrr.io/r/base/strwrap.html)). `NULL`
  (default) leaves labels unwrapped.

## Value

A character vector the same length as `x`, with `NA` preserved.

## Examples

``` r
format_terms(c("(Intercept)", "b_conditionB", "freq:condition"))
#> [1] "Intercept"        "conditionB"       "freq × condition"
format_terms("region:education:age", interaction = "asterisk")
#> [1] "region * education * age"
format_terms(c("word_frequency", "b_sleep_hours"))
#> [1] "word frequency" "sleep hours"   
format_terms(c("b_x:b_y", NA))
#> [1] "x × y" NA     
```
