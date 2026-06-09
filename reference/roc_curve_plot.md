# ROC curve

Plots the receiver operating characteristic (ROC) curve for a binary
classifier and reports the area under the curve (AUC). The input can be
a fitted binomial `glm`, or a pair of vectors: the observed binary
outcome and a continuous score (e.g. predicted probabilities).

## Usage

``` r
roc_curve_plot(x, score = NULL, colour = "#005b96", title = NULL)
```

## Arguments

- x:

  A binomial `glm`, or the vector of observed outcomes (0/1, logical or
  a two-level factor with the positive class second).

- score:

  When `x` is an outcome vector, the matching vector of scores or
  predicted probabilities.

- colour:

  Curve colour.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. The AUC is also stored in `attr(plot, "auc")`.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + condition + RT,
            data = lexical_decision, family = binomial)
roc_curve_plot(gfit)
```
