# Scree plot

Shows the proportion of variance explained by each principal component,
as bars with a cumulative line. It is the customary aid for deciding how
many components to retain.

## Usage

``` r
scree_plot(x, cols = NULL, scale = TRUE, n = NULL, title = NULL)
```

## Arguments

- x:

  A data frame, or a
  [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html) object.

- cols:

  When `x` is a data frame, the numeric columns to analyse.

- scale:

  Whether to scale variables to unit variance before the PCA.

- n:

  Maximum number of components to display.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
scree_plot(wellbeing_survey,
           cols = c("age", "income", "stress", "sleep_hours",
                    "exercise_days", "life_satisfaction"))
```
