# Confusion matrix heatmap

Cross-tabulates predicted against actual classes and displays the counts
as a heatmap. The input can be a fitted binomial `glm` (with a
probability threshold) or a pair of vectors of actual and predicted
classes.

## Usage

``` r
confusion_matrix_plot(
  x,
  predicted = NULL,
  threshold = 0.5,
  normalise = c("none", "row", "col"),
  title = NULL
)
```

## Arguments

- x:

  A binomial `glm`, or the vector of actual classes.

- predicted:

  When `x` is an actual-class vector, the matching predicted classes.

- threshold:

  When `x` is a `glm`, the probability threshold for the positive class.
  As well as a number in `[0, 1]`, you may pass the string `"youden"` to
  reuse the Youden's J optimal threshold (the same operating point
  [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/roc_curve_plot.md)
  marks), so the confusion matrix and the ROC curve agree on the
  cut-off.

- normalise:

  One of `"none"`, `"row"` (by actual class) or `"col"` (by predicted
  class); controls the fill shading and the cell annotation.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. The threshold actually used is stored in
`attr(plot, "threshold")`.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
confusion_matrix_plot(gfit, threshold = 0.5)


# Reuse the Youden-optimal operating point.
confusion_matrix_plot(gfit, threshold = "youden")
```
