# Influence plot

A bubble plot of leverage against the studentised residuals, with bubble
area proportional to Cook's distance. It summarises in a single picture
which observations most influence a fitted model. Reference lines mark
large residuals and high-leverage points, and the most influential
observations are labelled.

## Usage

``` r
influence_plot(model, n_label = 3, colour = depictr_brand(), title = NULL)
```

## Arguments

- model:

  A fitted `lm` or `glm` model.

- n_label:

  Number of most-influential points (by Cook's distance) to label.

- colour:

  Bubble colour. Defaults to the depictr brand blue.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## References

Cook RD (1977). “Detection of Influential Observation in Linear
Regression.” *Technometrics*, **19**(1), 15–18.
[doi:10.1080/00401706.1977.10489493](https://doi.org/10.1080/00401706.1977.10489493)
.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
influence_plot(fit)
```
