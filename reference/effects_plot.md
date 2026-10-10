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
  colour = depictr_brand(),
  title = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- model:

  A fitted model (`lm`, `glm`, `merMod`, ...).

- predictor:

  Name of the focal predictor (string): a variable in the model's
  formula, or a model-frame name such as `"log(rainfall)"`, which stands
  for the one variable it transforms. A term built from several
  variables, such as `"I(rainfall * fertiliser)"`, is refused.

- conf_level:

  Confidence level for the interval.

- n:

  Number of points across the range of a numeric predictor.

- rug:

  Whether to add a rug of the observed predictor values (numeric
  predictors).

- colour:

  Colour for the line/points and band. Defaults to the depictr brand
  blue.

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

The prediction grid holds the variables the formula names, on their own
scale, and [`stats::predict()`](https://rdrr.io/r/stats/predict.html)
re-applies each transformation to it. A model with terms such as
`log(rainfall)`, `poly(fertiliser, 2)`,
[`splines::ns()`](https://rdrr.io/r/splines/ns.html),
[`scale()`](https://rdrr.io/r/base/scale.html),
[`factor()`](https://rdrr.io/r/base/factor.html) or
[`I()`](https://rdrr.io/r/base/AsIs.html) is therefore predicted as
fitted, and the x-axis shows the raw variable. Typical values and the
range of the focal predictor are taken over the rows the model was
fitted to. A numeric variable that enters only through
[`factor()`](https://rdrr.io/r/base/factor.html) is held at its most
frequent value. A variable that enters only through a transformation is
recovered from the data named in the model's call, so such a model
fitted to workspace vectors without `data =` is refused. A term computed
from statistics of its rows, such as `I(x - mean(x))`, is refused too,
since [`predict()`](https://rdrr.io/r/stats/predict.html) would compute
it afresh over the grid. Centre such a variable in the data, or use
[`scale()`](https://rdrr.io/r/base/scale.html), which
[`predict()`](https://rdrr.io/r/stats/predict.html) re-applies as
fitted.

An offset, whether an [`offset()`](https://rdrr.io/r/stats/offset.html)
term or the `offset` argument, is held at its mean over the rows the
model was fitted to, on the link scale. For a Poisson rate model with
`offset(log(exposure))`, the line is the expected count at the
geometric-mean exposure. The offset stays at its mean when the focal
predictor enters it too, as in `log(exposure) + offset(log(exposure))`,
so the line then shows the predictor's effect beyond the offset. The
y-axis label ends in "at the mean offset".

Predictions and standard errors come from
[`stats::predict()`](https://rdrr.io/r/stats/predict.html); `glm`
predictions are formed on the link scale and back-transformed, so a
binomial model shows predicted probabilities. Mixed models fitted with
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html)/[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html)
are supported too: predictions use only the fixed effects (as
`re.form = NA` does) and standard errors come from the fixed-effect
design matrix and [`vcov()`](https://rdrr.io/r/stats/vcov.html). Works
with `lm`, `glm` and `merMod`; other model classes are attempted on a
best-effort basis.

## Examples

``` r
fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
effects_plot(fit, "fertiliser")

effects_plot(fit, "treatment")


gfit <- glm(accuracy ~ word_frequency + condition,
            data = lexical_decision, family = binomial)
effects_plot(gfit, "word_frequency")        # predicted probability
```
