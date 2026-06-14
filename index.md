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

## Installation

``` r

# install.packages("remotes")
remotes::install_github("pablobernabeu/depictr")
```

## What’s in the box

**Explore data**:
[`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
[`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md),
[`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md),
[`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md),
[`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md),
[`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md),
[`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md),
[`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
[`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md),
[`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md),
[`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md).

**Multivariate, clustering & survival**:
[`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md),
[`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md),
[`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md),
[`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md),
[`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md).

**Time series**:
[`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md),
[`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md),
[`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md).

**Model estimates & inference**:
[`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md),
[`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
[`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md),
[`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md),
[`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md),
[`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md),
[`random_effects_plot()`](https://pablobernabeu.github.io/depictr/reference/random_effects_plot.md),
[`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md),
[`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md).

**Diagnostics & classification**:
[`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md),
[`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md),
[`qq_plot()`](https://pablobernabeu.github.io/depictr/reference/qq_plot.md),
[`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md),
[`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md),
[`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/pr_curve_plot.md),
[`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md),
[`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md),
[`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md),
[`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md).

**Uncertainty & power**:
[`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md),
[`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md).

**Theming & reporting**:
[`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md),
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
/
[`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md),
[`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md),
[`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md),
[`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md),
[`arrange_plots()`](https://pablobernabeu.github.io/depictr/reference/arrange_plots.md),
[`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md).

Heavier modelling back-ends (`lme4`, `broom`, `simr`) are optional (in
`Suggests`) and used only when present; the core functions, examples,
tests and vignettes run on base `lm`/`glm` and the bundled data alone.

## A short tour

``` r

library(depictr)

# Explore
explore_bivariate(crop_yield, fertilizer, yield)
correlation_heatmap(wellbeing_survey)

# Model
fit <- lm(yield ~ rainfall + fertilizer + soil_ph + treatment, data = crop_yield)
coefficient_plot(fit, order = "descending")
effects_plot(fit, "fertilizer")
interaction_plot(lm(yield ~ fertilizer * treatment, data = crop_yield),
                 "fertilizer", "treatment")

# Diagnose & classify
residual_diagnostics_plot(fit)
gfit <- glm(accuracy ~ word_frequency + RT, data = lexical_decision,
            family = binomial)
roc_curve_plot(gfit)

# Report
arrange_plots(qq_plot(fit), influence_plot(fit), ncol = 2, tag_levels = "A")
```

## Bundled data

Three reproducibly simulated datasets ship with the package and power
every example and vignette: `lexical_decision` (a psycholinguistic
experiment), `wellbeing_survey` (a survey with realistic missingness)
and `crop_yield` (an agronomy field trial). They are generated by
[`data-raw/generate_datasets.R`](https://pablobernabeu.github.io/depictr/data-raw/generate_datasets.R)
with fixed seeds.

## Learn more

- [`vignette("depictr")`](https://pablobernabeu.github.io/depictr/articles/depictr.md):
  getting started
- [`vignette("exploring-data")`](https://pablobernabeu.github.io/depictr/articles/exploring-data.md):
  exploratory plots and tables
- [`vignette("model-estimates")`](https://pablobernabeu.github.io/depictr/articles/model-estimates.md):
  estimates, comparison, predictions, random effects
- [`vignette("diagnostics-and-uncertainty")`](https://pablobernabeu.github.io/depictr/articles/diagnostics-and-uncertainty.md):
  diagnostics, classification, posteriors, power

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
  until an `ANTHROPIC_API_KEY` secret is added to the repository.
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
[LICENSE.md](https://pablobernabeu.github.io/depictr/LICENSE.md).
