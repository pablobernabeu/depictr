# Influence plot

A bubble plot of leverage against the studentised residuals, with bubble
area proportional to Cook's distance. It summarises in a single picture
which observations most influence a fitted model. Reference lines mark
large residuals and high-leverage points, and the most influential
observations are labelled.

## Usage

``` r
influence_plot(model, n_label = 3, colour = "#005b96", title = NULL)
```

## Arguments

- model:

  A fitted `lm` or `glm` model.

- n_label:

  Number of most-influential points (by Cook's distance) to label.

- colour:

  Bubble colour.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
influence_plot(fit)
```
