# Normal quantile-quantile plot

A normal Q-Q plot for a numeric vector or for the standardised residuals
of a fitted model, with a reference line.

## Usage

``` r
qq_plot(
  x,
  colour = "#005b96",
  title = NULL,
  x_lab = "Theoretical quantiles",
  y_lab = NULL
)
```

## Arguments

- x:

  A numeric vector, or a fitted `lm`/`glm` model (its standardised
  residuals are used).

- colour:

  Point colour.

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
qq_plot(rnorm(100))

fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
qq_plot(fit)
```
