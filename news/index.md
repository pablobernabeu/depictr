# Changelog

## depictr 0.1.0

First release. depictr is a unified, consistent toolkit of
publication-ready plots spanning the whole analysis workflow. It grew
out of, and generalises, three earlier plotting functions
(`frequentist_bayesian_plot`, `plot.fixef.allFit` and `powercurvePlot`).

### Exploring data

- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md),
  [`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md),
  [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md),
  [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md),
  [`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md),
  [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md),
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
  [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md),
  [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md)
  and
  [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md).

### Multivariate, clustering and survival

- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  and
  [`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md)
  (principal component analysis),
  [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  (k-means on principal-component axes) and
  [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md)
  (hierarchical clustering), and
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  (Kaplan-Meier curves, computed in base R).

### Time series

- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  (series with an optional moving average),
  [`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md)
  (autocorrelation / partial autocorrelation) and
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  (trend / seasonal / remainder decomposition).

### Model estimates and inference

- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md)
  – the shared tidy estimate table (methods for `lm`, `glm`, `merMod`
  and data frames; falls back to
  [`broom::tidy()`](https://generics.r-lib.org/reference/tidy.html)).
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md),
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md),
  [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md),
  [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md),
  [`random_effects_plot()`](https://pablobernabeu.github.io/depictr/reference/random_effects_plot.md),
  [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  and
  [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md).

### Diagnostics and classification

- [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md),
  [`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md),
  [`qq_plot()`](https://pablobernabeu.github.io/depictr/reference/qq_plot.md),
  [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md),
  [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md),
  [`pr_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/pr_curve_plot.md),
  [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md),
  [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md),
  [`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md)
  and
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md).

### Uncertainty and power

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  and
  [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md).

### Theming and reporting

- [`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md),
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md),
  [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  (and
  [`scale_color_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md),
  [`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)),
  [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md),
  [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md),
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  (a one-figure model overview),
  [`arrange_plots()`](https://pablobernabeu.github.io/depictr/reference/arrange_plots.md)
  and
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md).

### Data

- Three reproducibly simulated datasets: `lexical_decision`,
  `wellbeing_survey` and `crop_yield`.

### Accessibility

- The qualitative palette is now based on the colourblind-safe Okabe-Ito
  set (led by the depictr brand blue), and
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  gains `sequential` and `diverging` variants.
  [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)
  can show any one, or all three.

### Notes

- Heavier modelling back-ends (`lme4`, `broom`, `simr`) are in
  `Suggests` and used only when available, so the package installs and
  checks without them.
