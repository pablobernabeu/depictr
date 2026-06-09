# Cumulative lift chart

Shows how many times more positive cases a classifier captures, at each
depth of the score-ordered population, than random targeting would. A
lift of 3 at the top 10% means that decile contains three times the
baseline rate of positives. The horizontal line at 1 is the no-model
baseline.

## Usage

``` r
lift_plot(x, score = NULL, colour = "#005b96", title = NULL)
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
lift_plot(gfit)
```
