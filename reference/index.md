# Package index

## Exploring data

A first look at distributions, relationships, data quality and
summaries.

- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md)
  : Plot the distribution of a variable
- [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md)
  : Bar chart of a categorical variable
- [`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md)
  : Plot any pair of variables
- [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
  : Scatter-plot matrix
- [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
  : Plot a correlation matrix as a heatmap
- [`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md)
  : Map the missing values in a data frame
- [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
  : Box / violin plot highlighting outliers
- [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
  : Raincloud plot
- [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md)
  : Compare group means with confidence intervals
- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md)
  : Scatter plot with a fitted trend
- [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md)
  : A "Table 1" style descriptive summary

## Multivariate, clustering and survival

Principal components, k-means and hierarchical clustering, and
Kaplan-Meier survival curves.

- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  : PCA biplot
- [`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md)
  : Scree plot
- [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  : Cluster scatter plot
- [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md)
  : Dendrogram
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  : Kaplan-Meier survival plot

## Time series

Series over time, autocorrelation and decomposition.

- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  : Time-series plot
- [`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md)
  : Autocorrelation plot
- [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  : Time-series decomposition plot

## Model estimates and inference

Forest plots, model comparison, predicted values, interactions, random
effects and goodness-of-fit, built on a shared tidy estimate table.

- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md)
  : Extract a tidy table of estimates
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  : Forest (coefficient) plot
- [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  : Compare estimates from several models or sources
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  : Plot frequentist and Bayesian estimates together
- [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md)
  : Plot predicted values for one predictor
- [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md)
  : Plot a two-way interaction of predicted values
- [`random_effects_plot()`](https://pablobernabeu.github.io/depictr/reference/random_effects_plot.md)
  : Caterpillar plot of random effects
- [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  : Plot fixed effects across optimisers
- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md)
  : Goodness-of-fit statistics across models

## Diagnostics and classification

Residual diagnostics, influence, and the standard classification curves
and tables.

- [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  : Residual-diagnostics panel for a fitted model
- [`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md)
  : Influence plot
- [`qq_plot()`](https://pablobernabeu.github.io/depictr/reference/qq_plot.md)
  : Normal quantile-quantile plot
- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  : Variance inflation factor plot
- [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md)
  : ROC curve
- [`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/pr_curve_plot.md)
  : Precision-recall curve
- [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md)
  : Cumulative gains chart
- [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md)
  : Cumulative lift chart
- [`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md)
  : Calibration plot
- [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md)
  : Confusion matrix heatmap

## Uncertainty and power

Posterior summaries and power analysis curves.

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  : Plot posterior distributions and intervals
- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  : Plot a power analysis curve

## Theming and reporting

A shared theme and colourblind-aware palette, label helpers, plot
composition and saving, and a one-figure model report.

- [`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md)
  : The depictr ggplot2 theme
- [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  : The depictr colour palettes
- [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  [`scale_color_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  [`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  : depictr colour and fill scales
- [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)
  : Preview the depictr palettes
- [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md)
  : Tidy raw coefficient names for display
- [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  : A one-figure model report
- [`arrange_plots()`](https://pablobernabeu.github.io/depictr/reference/arrange_plots.md)
  : Compose several plots into one figure
- [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  : Save a plot with publication-ready defaults

## Data

Reproducibly simulated datasets used throughout the documentation.

- [`lexical_decision`](https://pablobernabeu.github.io/depictr/reference/lexical_decision.md)
  : Simulated lexical-decision experiment
- [`wellbeing_survey`](https://pablobernabeu.github.io/depictr/reference/wellbeing_survey.md)
  : Simulated wellbeing survey
- [`crop_yield`](https://pablobernabeu.github.io/depictr/reference/crop_yield.md)
  : Simulated crop-yield field trial
