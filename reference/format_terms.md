# Tidy raw coefficient names for display

Tidies the term names produced by modelling functions so that they read
well on a plot: the intercept is renamed, an optional Bayesian prefix
`b_` or `bs_` is stripped, interaction colons are converted to a chosen
symbol and underscores are shown as spaces, so `word_frequency` becomes
`"word frequency"`. The prefix is stripped from every component of an
interaction, such as `b_x:b_y`, and not only from the leading term.
Missing values (`NA`) stay `NA` and are not rendered as the text `"NA"`.

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
  (see [`base::strwrap()`](https://rdrr.io/r/base/strwrap.html)).
  `NULL`, the default, leaves labels unwrapped.

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
