# Precision-recall curve

Plots precision against recall for a binary classifier and reports the
average precision (the area under the curve). The precision-recall curve
is more informative than the ROC curve when the positive class is rare,
because it ignores the many true negatives. A horizontal line marks the
no-skill baseline (the positive-class prevalence). Pass a *named list*
of models / (actual, score) pairs to overlay several colour-coded curves
with a legend and per-curve average precision.

## Usage

``` r
pr_curve_plot(
  x,
  score = NULL,
  colour = depictr_brand(),
  f1 = FALSE,
  title = NULL
)
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

- f1:

  Logical; if `TRUE`, mark the maximum-F1 operating point on each curve
  (the threshold maximising the harmonic mean of precision and recall).

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. The average precision is stored in
`attr(plot, "average_precision")` (a named vector when several models
are supplied).

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
pr_curve_plot(gfit)


# Mark the maximum-F1 operating point.
pr_curve_plot(gfit, f1 = TRUE)


# Compare two models with per-curve average precision in the legend.
reduced <- glm(accuracy ~ word_frequency, data = lexical_decision,
               family = binomial)
pr_curve_plot(list(Full = gfit, Reduced = reduced))
```
