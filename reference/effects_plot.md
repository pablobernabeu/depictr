# Plot predicted values for one predictor

Shows the values a model predicts as one focal predictor varies, holding
the other predictors at typical values (the mean for numeric predictors,
the most frequent level for factors). A confidence band (numeric
predictor) or confidence intervals (factor predictor) convey
uncertainty.

## Usage

``` r
effects_plot(
  model,
  predictor,
  conf_level = 0.95,
  n = 100,
  rug = TRUE,
  colour = "#005b96",
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- model:

  A fitted model (`lm`, `glm`, ...).

- predictor:

  Name of the focal predictor (string).

- conf_level:

  Confidence level for the interval.

- n:

  Number of points across the range of a numeric predictor.

- rug:

  Whether to add a rug of the observed predictor values (numeric
  predictors).

- colour:

  Colour for the line/points and band.

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Predictions and standard errors come from
[`stats::predict()`](https://rdrr.io/r/stats/predict.html); `glm`
predictions are formed on the link scale and back-transformed, so a
binomial model shows predicted probabilities. Works with `lm` and `glm`;
other model classes are attempted on a best-effort basis.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
effects_plot(fit, "fertilizer")

effects_plot(fit, "treatment")


gfit <- glm(accuracy ~ word_frequency + condition,
            data = lexical_decision, family = binomial)
effects_plot(gfit, "word_frequency")        # predicted probability
```
