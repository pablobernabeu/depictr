# Calibration plot

Assesses how well predicted probabilities match observed frequencies.
The scores are split into bins; for each bin the mean predicted
probability is plotted against the observed event rate, with the
diagonal marking perfect calibration.

## Usage

``` r
calibration_plot(x, score = NULL, bins = 10, colour = "#005b96", title = NULL)
```

## Arguments

- x:

  A binomial `glm`, or the vector of observed outcomes.

- score:

  When `x` is an outcome vector, the matching predicted probabilities.

- bins:

  Number of (equal-count) bins.

- colour:

  Point/line colour.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
            family = binomial)
calibration_plot(gfit, bins = 8)
```
