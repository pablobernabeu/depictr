# Cumulative gains chart

Shows how many of the positive cases are captured as a growing share of
the population is targeted in order of predicted score. It is the
customary chart for judging a classifier's value for ranking and
targeting, as in marketing, triage and fraud detection. The diagonal
marks the no-model baseline and the upper envelope a perfect model. Pass
a *named list* of models / (actual, score) pairs to overlay several
colour-coded gains curves with a legend.

## Usage

``` r
gain_plot(x, score = NULL, colour = depictr_brand(), title = NULL)
```

## Arguments

- x:

  A binomial `glm`; the vector of observed outcomes (0/1, logical or a
  two-level factor with the positive class second); or a *named* list of
  models / (actual, score) pairs to overlay.

- score:

  When `x` is an outcome vector, the matching scores or predicted
  probabilities (or a list of them for the multi-model case).

- colour:

  Curve colour for the single-model case. Defaults to the depictr brand
  blue. Ignored when several models are overlaid.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
gain_plot(gfit)


# Compare two models.
reduced <- glm(accuracy ~ word_frequency, data = lexical_decision,
               family = binomial)
gain_plot(list(Full = gfit, Reduced = reduced))
```
