# Plot a two-way interaction of predicted values

Shows how the predicted relationship between a focal predictor and the
response changes across the levels (or representative values) of a
second, moderating predictor. Other predictors are held at typical
values.

## Usage

``` r
interaction_plot(
  model,
  predictor,
  moderator,
  moderator_values = NULL,
  conf_level = 0.95,
  n = 80,
  band = TRUE,
  palette = NULL,
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- model:

  A fitted model (`lm`, `glm`, `merMod`, ...).

- predictor:

  Name of the focal predictor on the x-axis (string).

- moderator:

  Name of the moderating predictor, mapped to colour (string).

- moderator_values:

  For a numeric moderator, the values to show. Defaults to the 10th,
  50th and 90th percentiles.

- conf_level:

  Confidence level for the bands/intervals.

- n:

  Number of points across the range of a numeric focal predictor.

- band:

  Whether to draw confidence bands (numeric focal predictor).

- palette:

  Colours for the moderator; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
fit <- lm(yield ~ fertiliser * treatment + rainfall, data = crop_yield)
interaction_plot(fit, "fertiliser", "treatment")
```
