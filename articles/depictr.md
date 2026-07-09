# Getting started with depictr

**depictr** is a single, consistent toolkit of plots that span the whole
analysis workflow, from a first look at the data, through model
estimates and predictions, to diagnostics, uncertainty and reporting.
Every plotting function returns a `ggplot2` object ([Wickham,
2016](#ref-wickham2016)) (or a `patchwork` for composite panels), so you
can keep customising with the usual `+` syntax, and every plot shares
one theme, one palette and one set of label conventions.

``` r

library(depictr)
```

## Five datasets to explore

The package ships with five reproducibly simulated datasets, each chosen
to exercise a different family of plots. They are documented under their
names
(e.g. [`?lexical_decision`](https://pablobernabeu.github.io/depictr/reference/lexical_decision.md))
and load with [`data()`](https://rdrr.io/r/utils/data.html):

- `lexical_decision`: a counterbalanced, crossed reaction-time/accuracy
  experiment (participant, item, condition, modality, word frequency).
  For mixed models and the classification plots.
- `wellbeing_survey`: a cross-sectional survey (life satisfaction,
  stress, sleep, income, age, ordered education, region) with
  *informative* missingness. For descriptives, correlations, regression
  and missing data.
- `crop_yield`: a field trial with a genuine fertiliser-by-treatment
  interaction. For regression, scatter-trend and interaction plots.
- `clinical_trial`: a two-arm trial with separating survival curves and
  a rare adverse-event outcome. For survival and imbalanced
  classification.
- `monthly_sales`: two seasonal monthly series (indoor/outdoor). For the
  time-series plots.

## A tour by task

Begin with the data.
[`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md)
chooses a suitable plot for any pair of variables, here a scatter with a
trend because both are numeric.

``` r

explore_bivariate(crop_yield, fertiliser, yield)
```

![](depictr_files/figure-html/unnamed-chunk-2-1.png)

Turn next to the model. After fitting it,
[`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
draws a forest plot of the estimates.

``` r

fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment, data = crop_yield)
coefficient_plot(fit, order = "descending", title = "Drivers of crop yield")
```

![](depictr_files/figure-html/unnamed-chunk-3-1.png)

To see what the model implies,
[`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md)
traces the predicted response as one predictor varies.

``` r

effects_plot(fit, "fertiliser")
```

![](depictr_files/figure-html/unnamed-chunk-4-1.png)

[`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
gathers the usual checks of the fit into one panel.

``` r

residual_diagnostics_plot(fit)
```

![](depictr_files/figure-html/unnamed-chunk-5-1.png)

For uncertainty,
[`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
summarises posterior or simulation draws as a distribution per
parameter. These are the real fixed-effect posterior draws from a
Bayesian fit of the lexical-decision model, shipped with the package.

``` r

draws <- readRDS(system.file("extdata", "lexdec_draws.rds", package = "depictr"))
posterior_plot(draws[c("conditionunrelated", "modalityauditory",
                       "word_frequency")],
               labels = c(conditionunrelated = "condition",
                          modalityauditory = "modality",
                          word_frequency = "word frequency"),
               title = "Lexical-decision fixed effects (ms)")
```

![](depictr_files/figure-html/unnamed-chunk-6-1.png)

## The shared spine: `tidy_estimates()`

Most of the model functions rest on
[`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md),
which turns a model, or a data frame of pre-computed estimates, into one
standard table. Because the plotting functions also accept that table,
estimates from any source (Bayesian posteriors, bootstrap intervals, or
figures taken from a paper) can be supplied directly.

``` r

tidy_estimates(fit)
#>                term     estimate    std.error     conf.low    conf.high
#> 1       (Intercept) -7.156372471 0.7307020339 -8.597465983 -5.715278960
#> 2          rainfall  0.003869765 0.0006025038  0.002681505  0.005058026
#> 3        fertiliser  0.011266582 0.0010906005  0.009115695  0.013417469
#> 4           soil_ph  1.030217728 0.1056219670  0.821909657  1.238525800
#> 5 treatmentenhanced  1.317044684 0.0978270830  1.124109715  1.509979654
```

## A consistent, accessible look

[`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md),
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
and
[`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
style your own plots too:

``` r

library(ggplot2)
ggplot(crop_yield, aes(fertiliser, yield, colour = treatment)) +
  geom_point(alpha = 0.7) +
  scale_colour_depictr() +
  theme_depictr()
```

![](depictr_files/figure-html/unnamed-chunk-8-1.png)

The qualitative palette is based on the Okabe-Ito set ([Okabe & Ito,
2008](#ref-okabe2008)), which stays distinguishable under the common
forms of colour-vision deficiency; sequential and diverging variants are
available too. Preview them with:

``` r

palette_preview(type = "all")
```

![](depictr_files/figure-html/unnamed-chunk-9-1.png)

[`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)
can also *simulate* a colour-vision deficiency, so you can check a
palette as a deuteranope (red-green) would see it:

``` r

palette_preview(cvd = "deutan")
```

![](depictr_files/figure-html/unnamed-chunk-10-1.png)

Set the look once for a whole script with
[`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
(base size, base family, brand and accent colours, or a custom palette),
instead of passing the same arguments to every call. Called with no
arguments it reports the current settings:

``` r

depictr_options()
#> $base_size
#> [1] 11
#> 
#> $base_family
#> [1] ""
#> 
#> $brand
#> [1] "#005b96"
#> 
#> $accent
#> [1] "#d55e00"
#> 
#> $reference
#> [1] "grey60"
#> 
#> $palette
#> NULL
#> 
#> $na_value
#> [1] "grey80"
```

## Where to next

The remaining articles go into each area in turn.
[`vignette("exploring-data")`](https://pablobernabeu.github.io/depictr/articles/exploring-data.md)
covers distributions, categories, bivariate plots, scatter-plot
matrices, correlations, missingness, outliers, summary tables and the
estimation plots.
[`vignette("model-estimates")`](https://pablobernabeu.github.io/depictr/articles/model-estimates.md)
is the flagship: forest plots, model comparison, predicted values,
interactions, random effects, optimiser checks and the
frequentist-over-Bayesian-posterior overlay.
[`vignette("diagnostics-and-uncertainty")`](https://pablobernabeu.github.io/depictr/articles/diagnostics-and-uncertainty.md)
covers residuals, GLM-appropriate binned residuals, the classification
suite (ROC, PR, gains, lift, calibration, thresholds) on an imbalanced
outcome, and power curves. Two further articles,
[`vignette("multivariate-and-survival")`](https://pablobernabeu.github.io/depictr/articles/multivariate-and-survival.md)
and
[`vignette("time-series")`](https://pablobernabeu.github.io/depictr/articles/time-series.md),
cover the remaining methods.

## References

Okabe, M., & Ito, K. (2008). *Color Universal Design (CUD): How to make
figures and presentations that are friendly to colorblind people*.
<https://jfly.uni-koeln.de/color/>.

Wickham, H. (2016). *ggplot2: Elegant graphics for data analysis* (2nd
ed.). Springer. <https://doi.org/10.1007/978-3-319-24277-4>
