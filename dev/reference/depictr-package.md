# depictr: A Unified Toolkit for Visualising Statistical Models and Data

depictr provides a consistent set of plots that span the whole analysis
workflow, from a first look at the data, through model estimates and
predictions, to diagnostics, uncertainty and reporting. Every plotting
function returns a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object (or a 'patchwork' for composite panels), so results can be
customised with the usual `+` syntax, and every plot shares one theme,
one colourblind-aware palette and one set of label conventions.

## Exploring data

- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_distribution.md):
  histograms / densities of one variable.

- [`explore_categorical()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_categorical.md):
  bar charts of a categorical variable.

- [`explore_bivariate()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_bivariate.md):
  a suitable plot for any pair of variables.

- [`explore_pairs()`](https://pablobernabeu.github.io/depictr/dev/reference/explore_pairs.md):
  a scatter-plot matrix.

- [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/dev/reference/correlation_heatmap.md):
  correlations as a heatmap.

- [`missingness_map()`](https://pablobernabeu.github.io/depictr/dev/reference/missingness_map.md):
  a map of missing values.

- [`outlier_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/outlier_plot.md):
  box / violin plots flagging outliers.

- [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/raincloud_plot.md):
  half-violin, box and raw points together.

- [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/group_comparison_plot.md):
  group means with confidence intervals.

- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/dev/reference/scatter_trend.md):
  scatter plot with a fitted trend.

- [`summary_table()`](https://pablobernabeu.github.io/depictr/dev/reference/summary_table.md):
  a "Table 1" style descriptive summary.

## Multivariate and survival

- [`pca_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/pca_plot.md):
  principal-component biplot.

- [`scree_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/scree_plot.md):
  variance explained by each component.

- [`cluster_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/cluster_plot.md):
  k-means clusters on principal-component axes.

- [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/dendrogram_plot.md):
  hierarchical-clustering dendrogram.

- [`survival_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/survival_plot.md):
  Kaplan-Meier survival curves.

## Time series

- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/timeseries_plot.md):
  one or more series over time.

- [`acf_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/acf_plot.md):
  autocorrelation / partial autocorrelation.

- [`decompose_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/decompose_plot.md):
  trend / seasonal / remainder decomposition.

## Model estimates and inference

- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/dev/reference/tidy_estimates.md):
  the shared tidy estimate table.

- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/coefficient_plot.md):
  forest / coefficient plot.

- [`compare_models()`](https://pablobernabeu.github.io/depictr/dev/reference/compare_models.md):
  estimates from several models, side by side.

- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/frequentist_bayesian_plot.md):
  frequentist vs. Bayesian estimates.

- [`effects_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/effects_plot.md):
  predicted values for one predictor.

- [`interaction_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/interaction_plot.md):
  predicted values across two predictors.

- [`random_effects_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/random_effects_plot.md):
  caterpillar plot of random effects.

- [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/optimizer_fixef_plot.md):
  fixed effects across optimisers.

- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/dev/reference/model_fit_table.md):
  goodness-of-fit statistics across models.

## Diagnostics and classification

- [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/residual_diagnostics_plot.md):
  residual-diagnostic panel.

- [`influence_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/influence_plot.md):
  influence and leverage.

- [`qq_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/qq_plot.md):
  normal quantile-quantile plot.

- [`vif_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/vif_plot.md):
  multicollinearity (variance inflation factors).

- [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/roc_curve_plot.md):
  ROC curve(s) with AUC.

- [`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/pr_curve_plot.md):
  precision-recall curve with average precision.

- [`gain_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/gain_plot.md):
  cumulative gains chart.

- [`lift_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/lift_plot.md):
  cumulative lift chart.

- [`calibration_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/calibration_plot.md):
  calibration of predicted probabilities.

- [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/confusion_matrix_plot.md):
  confusion matrix as a heatmap.

## Uncertainty and power

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/posterior_plot.md):
  posterior intervals and densities.

- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/power_curve_plot.md):
  power against sample size.

## Theming and reporting

- [`theme_depictr()`](https://pablobernabeu.github.io/depictr/dev/reference/theme_depictr.md):
  the shared theme.

- [`depictr_palette()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_palette.md),
  [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/dev/reference/scale_colour_depictr.md):
  the shared palette.

- [`palette_preview()`](https://pablobernabeu.github.io/depictr/dev/reference/palette_preview.md):
  preview the palettes.

- [`format_terms()`](https://pablobernabeu.github.io/depictr/dev/reference/format_terms.md):
  tidy raw coefficient names for display.

- [`model_report()`](https://pablobernabeu.github.io/depictr/dev/reference/model_report.md):
  a one-figure overview of a fitted model.

- [`arrange_plots()`](https://pablobernabeu.github.io/depictr/dev/reference/arrange_plots.md):
  compose plots with a shared legend and title.

- [`save_plot()`](https://pablobernabeu.github.io/depictr/dev/reference/save_plot.md):
  save a plot with publication-ready defaults.

## Bundled data

[lexical_decision](https://pablobernabeu.github.io/depictr/dev/reference/lexical_decision.md),
[wellbeing_survey](https://pablobernabeu.github.io/depictr/dev/reference/wellbeing_survey.md)
and
[crop_yield](https://pablobernabeu.github.io/depictr/dev/reference/crop_yield.md)
are reproducibly simulated datasets used throughout the examples and
vignettes.

## References

Wickham H (2016). *ggplot2: Elegant Graphics for Data Analysis*, 2nd
edition. Springer, Cham, Switzerland. ISBN 978-3-319-24277-4.
[doi:10.1007/978-3-319-24277-4](https://doi.org/10.1007/978-3-319-24277-4)
.

## See also

Useful links:

- <https://pablobernabeu.github.io/depictr/>

- <https://github.com/pablobernabeu/depictr>

- Report bugs at <https://github.com/pablobernabeu/depictr/issues>

## Author

**Maintainer**: Pablo Bernabeu <pcbernabeu@gmail.com>

Authors:

- Pablo Bernabeu <pcbernabeu@gmail.com>
