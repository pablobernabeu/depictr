# Cumulative lift chart

Shows how many times more positive cases a classifier captures, at each
depth of the score-ordered population, than random targeting would. A
lift of 3 at the top 10% means that decile contains three times the
baseline rate of positives. The horizontal line at 1 is the no-model
baseline. Pass a named list of models or of (actual, score) pairs to
overlay several colour-coded lift curves with a legend.

## Usage

``` r
lift_plot(
  x,
  score = NULL,
  colour = depictr_brand(),
  legend_inside = FALSE,
  title = NULL
)
```

## Arguments

- x:

  A binomial `glm`, the vector of observed outcomes (0 and 1, logical or
  a two-level factor with the positive class second) or a named list of
  models or of (actual, score) pairs to overlay.

- score:

  When `x` is an outcome vector, the matching scores or predicted
  probabilities, or a list of them for several models.

- colour:

  Curve colour for a single model. Defaults to the depictr brand blue.
  Ignored when several models are overlaid.

- legend_inside:

  When `TRUE` and several models are overlaid, the legend is drawn
  inside the panel, over a translucent background, in the top-right
  corner, which the decreasing lift curve leaves empty. Otherwise, it is
  drawn in a right-hand margin. Defaults to `FALSE`.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# Lift is measured against the base rate, so the example uses the rare
# clinical-trial adverse event (about 10% positive).
gfit <- glm(adverse_event ~ biomarker + age + arm,
            data = clinical_trial, family = binomial)
lift_plot(gfit)


# Compare two models.
reduced <- glm(adverse_event ~ biomarker, data = clinical_trial,
               family = binomial)
lift_plot(list(Full = gfit, Reduced = reduced))
```
