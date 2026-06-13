# Cumulative gains chart

Shows how many of the positive cases are captured as a growing share of
the population is targeted in order of predicted score. It is the
customary chart for judging a classifier's value for ranking and
targeting, as in marketing, triage and fraud detection. The diagonal
marks the no-model baseline and the upper envelope a perfect model.

## Usage

``` r
gain_plot(x, score = NULL, colour = "#005b96", title = NULL)
```

## Arguments

- x:

  A binomial `glm`, or the vector of observed outcomes (0/1, logical or
  a two-level factor with the positive class second).

- score:

  When `x` is an outcome vector, the matching scores or predicted
  probabilities.

- colour:

  Curve colour.

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
```
