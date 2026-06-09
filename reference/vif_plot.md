# Variance inflation factor plot

Computes a variance inflation factor (VIF) for each column of a model's
design matrix and shows them as a bar chart, with reference lines at the
usual rules of thumb (VIF = 5 and VIF = 10). High bars flag predictors
whose coefficients are unstable because they are collinear with the
others. VIFs are computed from base R (no 'car' dependency).

## Usage

``` r
vif_plot(model, threshold = 5, palette = c("#005b96", "#e23b3b"), title = NULL)
```

## Arguments

- model:

  A fitted `lm` or `glm` model with at least two predictors.

- threshold:

  Reference value drawn as a solid line (a second, dashed line is drawn
  at `threshold / 2`).

- palette:

  Length-2 colours for VIFs below and above `threshold`.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

For models with multi-level factors, each dummy column is shown
separately; interpret those with care (a generalised VIF is more
appropriate for factors with several levels).

## Examples

``` r
fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
vif_plot(fit)
```
