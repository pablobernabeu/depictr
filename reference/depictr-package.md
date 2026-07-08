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

- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md):
  histograms / densities of one variable.

- [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md):
  empirical cumulative distribution, optionally by group.

- [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md):
  bar charts of a categorical variable.

- [`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md):
  a suitable plot for any pair of variables.

- [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md):
  a scatter-plot matrix.

- [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md):
  correlations as a heatmap.

- [`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md):
  a map of missing values.

- [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md):
  box / violin plots flagging outliers.

- [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md):
  half-violin, box and raw points together.

- [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md):
  overlapping per-group densities.

- [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md):
  group means with confidence intervals.

- [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md):
  group differences with bootstrap intervals.

- [`dumbbell_plot()`](https://pablobernabeu.github.io/depictr/reference/dumbbell_plot.md):
  a two-group comparison across categories.

- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md):
  scatter plot with a fitted trend.

- [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md):
  a "Table 1" style descriptive summary.

## Multivariate and survival

- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md):
  principal-component biplot.

- [`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md):
  variance explained by each component.

- [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md):
  k-means clusters on principal-component axes.

- [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md):
  silhouette widths of a clustering.

- [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md):
  suggest a number of clusters.

- [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md):
  hierarchical-clustering dendrogram.

- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md):
  Kaplan-Meier survival curves.

## Time series

- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md):
  one or more series over time.

- [`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md):
  autocorrelation / partial autocorrelation.

- [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md):
  trend / seasonal / remainder decomposition.

- [`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md):
  seasonal subseries across cycles.

- [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md):
  a simple forecast with prediction intervals.

## Model estimates and inference

- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md):
  the shared tidy estimate table.

- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md):
  forest / coefficient plot.

- [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md):
  estimates from several models, side by side.

- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md):
  frequentist vs. Bayesian estimates.

- [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md):
  predicted values for one predictor.

- [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md):
  predicted values across two predictors.

- [`random_effects_plot()`](https://pablobernabeu.github.io/depictr/reference/random_effects_plot.md):
  caterpillar plot of random effects.

- [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md):
  fixed effects across optimisers.

- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md):
  goodness-of-fit statistics across models.

## Diagnostics and classification

- [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md):
  residual-diagnostic panel.

- [`binned_residual_plot()`](https://pablobernabeu.github.io/depictr/reference/binned_residual_plot.md):
  binned residuals for logistic and other GLMs.

- [`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md):
  influence and leverage.

- [`qq_plot()`](https://pablobernabeu.github.io/depictr/reference/qq_plot.md):
  normal quantile-quantile plot.

- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md):
  multicollinearity (variance inflation factors).

- [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md):
  ROC curve(s) with AUC.

- [`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/pr_curve_plot.md):
  precision-recall curve with average precision.

- [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md):
  cumulative gains chart.

- [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md):
  cumulative lift chart.

- [`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md):
  calibration of predicted probabilities.

- [`threshold_plot()`](https://pablobernabeu.github.io/depictr/reference/threshold_plot.md):
  classification metrics across decision thresholds.

- [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md):
  confusion matrix as a heatmap.

## Uncertainty and power

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md):
  posterior intervals and densities.

- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md):
  power against sample size.

## Theming and reporting

- [`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md):
  the shared theme.

- [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md),
  [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md):
  the shared palette.

- [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md):
  preview the palettes.

- [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md):
  tidy raw coefficient names for display.

- [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md):
  a one-figure overview of a fitted model.

- [`arrange_plots()`](https://pablobernabeu.github.io/depictr/reference/arrange_plots.md):
  compose plots with a shared legend and title.

- [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md):
  save a plot with publication-ready defaults.

- [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md):
  set package-wide defaults once.

## Bundled data

[lexical_decision](https://pablobernabeu.github.io/depictr/reference/lexical_decision.md),
[wellbeing_survey](https://pablobernabeu.github.io/depictr/reference/wellbeing_survey.md),
[crop_yield](https://pablobernabeu.github.io/depictr/reference/crop_yield.md),
[clinical_trial](https://pablobernabeu.github.io/depictr/reference/clinical_trial.md)
and
[monthly_sales](https://pablobernabeu.github.io/depictr/reference/monthly_sales.md)
are reproducibly simulated datasets used throughout the examples and
vignettes.

## References

Wickham H (2016). *ggplot2: Elegant graphics for data analysis*, 2nd
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
([ORCID](https://orcid.org/0000-0003-1083-2460))

Authors:

- Pablo Bernabeu <pcbernabeu@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-1083-2460))
