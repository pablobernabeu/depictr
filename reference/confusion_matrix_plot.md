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
  normalize = c("none", "row", "col"),
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

- normalize:

  One of `"none"`, `"row"` (by actual class) or `"col"` (by predicted
  class); controls the fill shading and the cell annotation.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
confusion_matrix_plot(gfit, threshold = 0.5)
```
