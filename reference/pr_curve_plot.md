# Precision-recall curve

Plots precision against recall for a binary classifier and reports the
average precision (the area under the curve). The precision-recall curve
is more informative than the ROC curve when the positive class is rare,
because it ignores the many true negatives. A horizontal line marks the
no-skill baseline (the positive-class prevalence).

## Usage

``` r
pr_curve_plot(x, score = NULL, colour = "#005b96", title = NULL)
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
object. The average precision is stored in
`attr(plot, "average_precision")`.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
pr_curve_plot(gfit)
```
