# depictr

**depictr** is a single, consistent toolkit of publication-ready plots
that span the whole analysis workflow, from a first look at the data,
through model estimates and predictions, to diagnostics, uncertainty and
reporting. Most packages address one part of this work; depictr aims to
cover it from end to end with *one* theme, *one* palette and *one* set
of label conventions. Every plotting function returns a
[ggplot2](https://ggplot2.tidyverse.org) object (or a
[patchwork](https://patchwork.data-imaginist.com) for composite panels),
so a plot can be refined further with the usual `+` syntax.

It grew out of three focused plotting functions
([frequentist_bayesian_plot](https://github.com/pablobernabeu/frequentist_bayesian_plot),
[plot.fixef.allFit](https://github.com/pablobernabeu/plot.fixef.allFit)
and [powercurvePlot](https://github.com/pablobernabeu/powercurvePlot)),
generalised and unified into one coherent package.

A Python sibling,
[depictr-py](https://github.com/pablobernabeu/depictr-py), mirrors the
same design on top of [plotnine](https://plotnine.org) and is on
[PyPI](https://pypi.org/project/depictr/) (`pip install depictr`).

## Gallery

A grouped density (the default palette is the colourblind-safe Okabe-Ito
set) and Kaplan-Meier survival curves with confidence bands and a
number-at-risk table, each from a single function call:

![Grouped density of response times by priming condition, in the
Okabe-Ito palette](reference/figures/README-distribution.png)

Grouped density of response times by priming condition, in the Okabe-Ito
palette

![Kaplan-Meier survival curves by treatment arm, with confidence bands,
censoring marks, a log-rank test and a number-at-risk
table](reference/figures/README-survival.png)

Kaplan-Meier survival curves by treatment arm, with confidence bands,
censoring marks, a log-rank test and a number-at-risk table

## Installation

``` r

# install.packages("remotes")
remotes::install_github("pablobernabeu/depictr")
```

## What’s in the box

**Explore data**:
[`explore_distribution()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_distribution.md),
[`ecdf_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/ecdf_plot.md),
[`explore_categorical()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_categorical.md),
[`explore_bivariate()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_bivariate.md),
[`explore_pairs()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_pairs.md),
[`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/dev/reference/correlation_heatmap.md),
[`missingness_map()`](https://pablobernabeu.github.io/depictr/dev/reference/missingness_map.md),
[`outlier_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/outlier_plot.md),
[`raincloud_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/raincloud_plot.md),
[`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/ridgeline_plot.md),
[`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/group_comparison_plot.md),
[`estimation_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/estimation_plot.md),
[`dumbbell_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/dumbbell_plot.md),
[`scatter_trend()`](https://pablobernabeu.github.io/depictr/dev/reference/scatter_trend.md),
[`summary_table()`](https://pablobernabeu.github.io/depictr/dev/reference/summary_table.md).

**Multivariate, clustering & survival**:
[`pca_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/pca_plot.md),
[`scree_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/scree_plot.md),
[`cluster_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/cluster_plot.md),
[`silhouette_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/silhouette_plot.md),
[`k_diagnostic()`](https://pablobernabeu.github.io/depictr/dev/reference/k_diagnostic.md),
[`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/dendrogram_plot.md),
[`survival_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/survival_plot.md).

**Time series**:
[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/timeseries_plot.md),
[`acf_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/acf_plot.md),
[`decompose_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/decompose_plot.md),
[`seasonal_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/seasonal_plot.md),
[`ts_forecast()`](https://pablobernabeu.github.io/depictr/dev/reference/ts_forecast.md).

**Model estimates & inference**:
[`tidy_estimates()`](https://pablobernabeu.github.io/depictr/dev/reference/tidy_estimates.md),
[`coefficient_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/coefficient_plot.md),
[`compare_models()`](https://pablobernabeu.github.io/depictr/dev/reference/compare_models.md),
[`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/frequentist_bayesian_plot.md),
[`effects_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/effects_plot.md),
[`interaction_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/interaction_plot.md),
[`random_effects_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/random_effects_plot.md),
[`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/optimizer_fixef_plot.md),
[`model_fit_table()`](https://pablobernabeu.github.io/depictr/dev/reference/model_fit_table.md).

**Diagnostics & classification**:
[`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/residual_diagnostics_plot.md),
[`binned_residual_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/binned_residual_plot.md),
[`influence_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/influence_plot.md),
[`qq_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/qq_plot.md),
[`vif_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/vif_plot.md),
[`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/roc_curve_plot.md),
[`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/pr_curve_plot.md),
[`gain_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/gain_plot.md),
[`lift_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/lift_plot.md),
[`calibration_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/calibration_plot.md),
[`threshold_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/threshold_plot.md),
[`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/confusion_matrix_plot.md).

**Uncertainty & power**:
[`posterior_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/posterior_plot.md),
[`power_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/power_curve_plot.md).

**Theming & reporting**:
[`theme_depictr()`](https://pablobernabeu.github.io/depictr/dev/reference/theme_depictr.md),
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_palette.md)
/
[`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/dev/reference/scale_colour_depictr.md),
[`palette_preview()`](https://pablobernabeu.github.io/depictr/dev/reference/palette_preview.md),
[`format_terms()`](https://pablobernabeu.github.io/depictr/dev/reference/format_terms.md),
[`model_report()`](https://pablobernabeu.github.io/depictr/dev/reference/model_report.md),
[`arrange_plots()`](https://pablobernabeu.github.io/depictr/dev/reference/arrange_plots.md),
[`save_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/save_plot.md),
[`depictr_options()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_options.md).

Heavier modelling back-ends (`lme4`, `broom`, `simr`) are optional (in
`Suggests`) and used only when present; the core functions, examples,
tests and vignettes run on base `lm`/`glm` and the bundled data alone.

## A short tour

``` r

library(depictr)

# Explore
explore_bivariate(crop_yield, fertiliser, yield)
correlation_heatmap(wellbeing_survey)

# Model
fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment, data = crop_yield)
coefficient_plot(fit, order = "descending")
effects_plot(fit, "fertiliser")
interaction_plot(lm(yield ~ fertiliser * treatment, data = crop_yield),
                 "fertiliser", "treatment")

# Diagnose & classify
residual_diagnostics_plot(fit)
gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
            family = binomial)
roc_curve_plot(gfit)

# Report
arrange_plots(qq_plot(fit), influence_plot(fit), ncol = 2, tag_levels = "A")
```

## Bundled data

Five reproducibly simulated datasets ship with the package and power
every example and vignette: `lexical_decision` (a counterbalanced
psycholinguistic experiment), `wellbeing_survey` (a survey with
realistic missingness), `crop_yield` (an agronomy field trial with a
fertiliser-by-treatment interaction), `clinical_trial` (right-censored
survival times with a rare adverse event) and `monthly_sales` (two
seasonal retail series). They are generated by
[`data-raw/generate_datasets.R`](https://pablobernabeu.github.io/depictr/dev/data-raw/generate_datasets.R)
with fixed seeds.

## Learn more

- [`vignette("depictr")`](https://pablobernabeu.github.io/depictr/dev/articles/depictr.md):
  getting started
- [`vignette("exploring-data")`](https://pablobernabeu.github.io/depictr/dev/articles/exploring-data.md):
  exploratory plots, estimation statistics and tables
- [`vignette("model-estimates")`](https://pablobernabeu.github.io/depictr/dev/articles/model-estimates.md):
  estimates, comparison, predictions, random effects, and Bayesian
  posteriors
- [`vignette("diagnostics-and-uncertainty")`](https://pablobernabeu.github.io/depictr/dev/articles/diagnostics-and-uncertainty.md):
  diagnostics, classification, posteriors, power
- [`vignette("multivariate-and-survival")`](https://pablobernabeu.github.io/depictr/dev/articles/multivariate-and-survival.md):
  PCA, clustering with diagnostics, survival curves
- [`vignette("time-series")`](https://pablobernabeu.github.io/depictr/dev/articles/time-series.md):
  trends, autocorrelation, decomposition, seasonality and forecasts

## How depictr relates to other packages

depictr aims for breadth and consistency across the workflow, and
complements the specialised packages rather than replacing them. For a
deeper treatment of any one area, several remain valuable, among them
[`ggstatsplot`](https://www.indrapatil.com/ggstatsplot/) (statistical
details on plots), [`sjPlot`](https://strengejacke.github.io/sjPlot/)
and the [easystats](https://easystats.github.io/easystats/) family
(`see`, `parameters`, `performance`),
[`marginaleffects`](https://marginaleffects.com) /
[`ggeffects`](https://strengejacke.github.io/ggeffects/) (predictions),
[`GGally`](https://ggobi.github.io/ggally/) (pairs),
[`factoextra`](https://rpkgs.datanovia.com/factoextra/) (PCA and
clustering), [`survminer`](https://rpkgs.datanovia.com/survminer/)
(survival), [`feasts`](https://feasts.tidyverts.org) / `ggfortify` (time
series), [`ggdist`](https://mjskay.github.io/ggdist/) / `dabestr`
(distributions and estimation) and
[`bayesplot`](https://mc-stan.org/bayesplot/) / `tidybayes` (Bayesian).
depictr offers a consistent and attractive default for all of these
tasks within a single package.

## Automated maintenance

depictr draws on a number of plotting and modelling packages, so several
scheduled GitHub Actions keep it healthy between releases:

- **`dependency-check`** runs **daily**, checking the package and its
  full test suite against both the current and the development versions
  of its dependencies, so a breaking change in any dependency is caught
  within a day. On failure it opens, and keeps updated, a single
  tracking issue.
- **`dependency-autofix`** runs whenever `dependency-check` fails: it
  asks Claude Code to find the smallest change that restores
  compatibility and to open a pull request, falling back to a comment on
  the tracking issue when no safe automated fix exists. It is inert
  until a `CLAUDE_CODE_OAUTH_TOKEN` secret is added to the repository —
  generate it with `claude setup-token` (it uses your Claude
  subscription, not billable API credits) and enable *Settings → Actions
  → General → Allow GitHub Actions to create and approve pull requests*.
- **`link-check`** runs weekly, validating every URL in the DESCRIPTION,
  README, help pages and vignettes with `urlchecker`, and opening a
  tracking issue if a link breaks or starts redirecting (both of which
  CRAN flags).
- **`R-CMD-check`** runs on every push and pull request across Linux,
  macOS and Windows (R release, development and previous release).

Each scheduled workflow can also be run on demand from the repository’s
**Actions** tab.

## Citing depictr

`citation("depictr")` gives the preferred reference. The methods the
package implements are cited in the relevant help pages and vignettes,
drawing on a single bibliography at `inst/REFERENCES.bib`.

## License

MIT (c) Pablo Bernabeu. See
[LICENSE.md](https://pablobernabeu.github.io/depictr/dev/LICENSE.md).
