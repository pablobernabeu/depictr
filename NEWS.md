# depictr 0.1.0

First release. depictr is a unified, consistent toolkit of publication-ready
plots spanning the whole analysis workflow. It grew out of, and generalises,
three earlier plotting functions (`frequentist_bayesian_plot`,
`plot.fixef.allFit` and `powercurvePlot`).

## Exploring data

* `explore_distribution()`, `explore_categorical()`, `explore_bivariate()`,
  `explore_pairs()`, `correlation_heatmap()`, `missingness_map()`,
  `outlier_plot()`, `raincloud_plot()`, `group_comparison_plot()`,
  `scatter_trend()` and `summary_table()`.

## Multivariate, clustering and survival

* `pca_plot()` and `scree_plot()` (principal component analysis),
  `cluster_plot()` (k-means on principal-component axes) and
  `dendrogram_plot()` (hierarchical clustering), and `survival_plot()`
  (Kaplan-Meier curves, computed in base R).

## Time series

* `timeseries_plot()` (series with an optional moving average), `acf_plot()`
  (autocorrelation / partial autocorrelation) and `decompose_plot()`
  (trend / seasonal / remainder decomposition).

## Model estimates and inference

* `tidy_estimates()` -- the shared tidy estimate table (methods for `lm`,
  `glm`, `merMod` and data frames; falls back to `broom::tidy()`).
* `coefficient_plot()`, `compare_models()`, `frequentist_bayesian_plot()`,
  `effects_plot()`, `interaction_plot()`, `random_effects_plot()`,
  `optimizer_fixef_plot()` and `model_fit_table()`.

## Diagnostics and classification

* `residual_diagnostics_plot()`, `influence_plot()`, `qq_plot()`,
  `vif_plot()`, `roc_curve_plot()`, `pr_curve_plot()`, `gain_plot()`,
  `lift_plot()`, `calibration_plot()` and `confusion_matrix_plot()`.

## Uncertainty and power

* `posterior_plot()` and `power_curve_plot()`.

## Theming and reporting

* `theme_depictr()`, `depictr_palette()`, `scale_colour_depictr()` (and
  `scale_color_depictr()`, `scale_fill_depictr()`), `palette_preview()`,
  `format_terms()`, `model_report()` (a one-figure model overview),
  `arrange_plots()` and `save_plot()`.

## Data

* Three reproducibly simulated datasets: `lexical_decision`,
  `wellbeing_survey` and `crop_yield`.

## Accessibility

* The qualitative palette is now based on the colourblind-safe Okabe-Ito set
  (led by the depictr brand blue), and `depictr_palette()` gains `sequential`
  and `diverging` variants. `palette_preview()` can show any one, or all three.

## Notes

* Heavier modelling back-ends (`lme4`, `broom`, `simr`) are in `Suggests` and
  used only when available, so the package installs and checks without them.
