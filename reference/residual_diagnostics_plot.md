# Residual-diagnostics panel for a fitted model

Combines the classic regression diagnostic plots – residuals vs. fitted,
a normal Q-Q plot of the standardised residuals, a scale-location plot,
and residuals vs. leverage – into a single panel using 'patchwork'.
Works with `lm` and `glm` objects.

## Usage

``` r
residual_diagnostics_plot(
  model,
  which = c("resid_fitted", "qq", "scale_location", "resid_leverage"),
  ncol = 2,
  point_alpha = 0.6,
  smooth = TRUE,
  title = NULL
)
```

## Arguments

- model:

  A fitted `lm` or `glm` model.

- which:

  Character vector choosing which panels to show, any of
  `"resid_fitted"`, `"qq"`, `"scale_location"` and `"resid_leverage"`.

- ncol:

  Number of columns in the panel layout.

- point_alpha:

  Point transparency.

- smooth:

  Add a loess guide line to the residual panels?

- title:

  Overall title for the panel.

## Value

A 'patchwork' object (printable like a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)).

## Examples

``` r
fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
residual_diagnostics_plot(fit)

residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
```
