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
* `estimation_plot()` for estimation statistics: group effect sizes
  (mean differences, Cohen's *d* / Hedges' *g*) with bootstrap confidence
  intervals, in the spirit of the "new statistics".

## Multivariate, clustering and survival

* `pca_plot()` and `scree_plot()` (principal component analysis),
  `cluster_plot()` (k-means on principal-component axes) and
  `dendrogram_plot()` (hierarchical clustering), and `survival_plot()`
  (Kaplan-Meier curves with a number-at-risk table, median survival and an
  optional log-rank test, all computed in base R).
* `silhouette_plot()` and `k_diagnostic()` help choose and validate the number
  of clusters (silhouette widths; elbow and average-silhouette diagnostics).

## Time series

* `timeseries_plot()` (one or more series with an optional moving average),
  `acf_plot()` (autocorrelation / partial autocorrelation) and
  `decompose_plot()` (trend / seasonal / remainder decomposition).
* `seasonal_plot()` (seasonal subseries) and `ts_forecast()` (a simple,
  dependency-free forecast with prediction intervals).

## Model estimates and inference

* `tidy_estimates()` -- the shared tidy estimate table (methods for `lm`,
  `glm`, `merMod` and data frames; falls back to `broom::tidy()`).
* `coefficient_plot()`, `compare_models()`, `frequentist_bayesian_plot()`,
  `effects_plot()`, `interaction_plot()`, `random_effects_plot()`,
  `optimizer_fixef_plot()` and `model_fit_table()`.
* `frequentist_bayesian_plot()` now draws the full Bayesian posterior for each
  term as a half-eye density and overlays the matching frequentist point
  estimate and confidence interval, so the two inferential frameworks can be
  compared directly. It reads posterior draws from `brmsfit`, `stanreg`,
  `draws`/`matrix` objects or a data frame.

## Diagnostics and classification

* `residual_diagnostics_plot()`, `influence_plot()`, `qq_plot()`,
  `vif_plot()`, `roc_curve_plot()`, `pr_curve_plot()`, `gain_plot()`,
  `lift_plot()`, `calibration_plot()` and `confusion_matrix_plot()`.
* `binned_residual_plot()` (binned residuals for logistic and other GLMs, with
  approximate error bounds) and `threshold_plot()` (classification metrics
  across decision thresholds, highlighting Youden's *J* and the maximum-F1
  cut-off).

## Uncertainty and power

* `posterior_plot()` summarises posterior draws with a choice of styles
  (`"halfeye"`, `"interval"`, `"gradient"` or `"dots"`) and can annotate a
  region of practical equivalence (ROPE) and the probability of direction.
* `power_curve_plot()` for power-analysis curves (e.g. from `simr`).

## Theming and reporting

* `theme_depictr()`, `depictr_palette()`, `scale_colour_depictr()` (and
  `scale_color_depictr()`, `scale_fill_depictr()`), `palette_preview()`,
  `format_terms()`, `model_report()` (a one-figure model overview),
  `arrange_plots()` and `save_plot()`.
* `depictr_options()` sets package-wide defaults once -- the brand and accent
  colours, qualitative palette, base font size and family, and the colour used
  for missing values -- which every plot and scale then honours.

## Data

* Five reproducibly simulated datasets: `lexical_decision` (counterbalanced
  priming experiment), `wellbeing_survey` (with realistic missingness),
  `crop_yield` (a fertilizer-by-treatment field trial), `clinical_trial`
  (right-censored survival with a rare adverse event) and `monthly_sales`
  (two seasonal retail series).

## Accessibility

* The qualitative palette is based on the colourblind-safe Okabe-Ito set
  (led by the depictr brand blue), and `depictr_palette()` provides
  `sequential` and `diverging` variants. `palette_preview()` can show any one,
  or all three, and can simulate deuteranopia, protanopia or tritanopia so a
  palette's legibility can be checked directly.

## Notes

* Heavier modelling back-ends (`lme4`, `broom`, `simr`, `survival`, `brms`,
  `posterior`, `ggdist`, `cluster`, `boot`) are in `Suggests` and used only
  when available, so the package installs and checks without them. Vignettes
  draw on small precomputed model fits shipped in `inst/extdata/`, so they
  knit without a Bayesian or mixed-model toolchain.
