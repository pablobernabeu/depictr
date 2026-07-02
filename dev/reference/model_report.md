# A one-figure model report

Assembles a compact, consistent overview of a fitted model in a single
figure: the coefficient estimates, the predicted effect of a focal
predictor, a residuals-against-fitted plot and a normal Q-Q plot, with a
subtitle of key fit statistics. It is a convenience wrapper that
composes several depictr plots with
[`arrange_plots()`](https://pablobernabeu.github.io/depictr/dev/reference/arrange_plots.md),
and serves well for a rapid model review or a report appendix.

## Usage

``` r
model_report(
  model,
  predictor = NULL,
  standardise = TRUE,
  title = NULL,
  subtitle = NULL
)
```

## Arguments

- model:

  A fitted `lm` or `glm` model.

- predictor:

  Focal predictor for the effect panel. If `NULL`, the first numeric
  predictor (or, failing that, the first predictor) is used.

- standardise:

  Whether the coefficient panel shows standardised coefficients (each
  scaled by its predictor's standard deviation). Defaults to `TRUE`,
  which keeps the panel readable in this compact overview by putting
  predictors on a common scale; set `FALSE` for raw estimates.

- title:

  Overall title.

- subtitle:

  Overall subtitle. If `NULL`, a line of fit statistics (number of
  observations, R-squared and AIC) is used.

## Value

A 'patchwork' object (printable like a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)).

## Examples

``` r
fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
          data = crop_yield)
model_report(fit, title = "Crop-yield model")


gfit <- glm(accuracy ~ word_frequency + RT + condition,
            data = lexical_decision, family = binomial)
model_report(gfit)
```
