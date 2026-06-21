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
* `ecdf_plot()` (empirical cumulative distribution, optionally by group),
  `ridgeline_plot()` (overlapping per-group densities) and `dumbbell_plot()`
  (a connected two-group comparison across categories).
* `explore_distribution()` gains `facet` to draw one panel per group instead of
  overlaying them (much clearer beyond a few groups), and
  `correlation_heatmap()` gains `reorder` to cluster correlated variables
  together.

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

## Layout and legibility

* `coefficient_plot()`, `compare_models()`, `posterior_plot()` and
  `frequentist_bayesian_plot()` gain a `facet`/`scales` option that lays each
  term out in its own free-scaled panel, so terms on very different scales (a
  large intercept alongside small slopes) stay legible instead of being squished
  onto the zero line. `frequentist_bayesian_plot()` uses this layout by default.
* A pass over every plot for legibility: `silhouette_plot()` cluster labels no
  longer clip; `raincloud_plot()` uses one colour per group across all layers;
  `dendrogram_plot()` hides leaf labels for large trees; `confusion_matrix_plot()`
  picks each label's colour from the tile luminance; `gain_plot()`/`lift_plot()`
  label their reference lines; `timeseries_plot()` shows a single legend; and
  `k_diagnostic()` now returns the diagnostic curve as a plot.
* `coefficient_plot()` gains `standardise`, scaling each coefficient by its
  predictor's standard deviation so magnitudes are comparable; `model_report()`
  uses it by default, removing the empty band in its coefficient panel.
* `vif_plot()` shows the ordinary VIF (not its square root) for single-df terms,
  scales the axis to the data, and draws a single clearly-labelled threshold
  line (reported in the caption when it is off-axis) -- no more wide empty band
  or hard-to-read guides.
* `seasonal_plot(style = "season")` reverses its sequential legend so the
  darkest, most-recent cycle sits at the top, matching the plotted order.
* Factor coefficient names are prettified by default to the effect (variable)
  name -- `conditionunrelated` becomes `condition`, `word_frequency` becomes
  `word frequency` -- in `coefficient_plot()`, `compare_models()`
  and `frequentist_bayesian_plot()` (read from the model); `optimizer_fixef_plot()`
  and `posterior_plot()` gain a `labels` argument for the same. Any user-supplied
  `labels` take precedence. `pca_plot()` likewise shows underscores in its
  loading-arrow labels as spaces (`soil_ph` -> `soil ph`).
* Redundant cluster legends are dropped: `silhouette_plot()` (the bands are
  labelled in place) and `cluster_plot()` when the centroids are labelled.
* `survival_plot()`: the log-rank annotation now renders a proper chi-squared
  and an italic *p*; the median guide is labelled "median <value>"; and the
  y-axis title margin is tighter.
* A `legend_inside` argument (off by default) draws the legend inside the panel,
  over a semi-transparent background, in a corner the plot usually leaves empty
  -- reclaiming the right-hand margin. It is offered by `roc_curve_plot()`,
  `gain_plot()`, `lift_plot()` (bottom-right / top-right of the curve),
  `ecdf_plot()`, `survival_plot()`, `explore_distribution()`, `dumbbell_plot()`
  and `missingness_map()`. For any other plot the same is one `theme()` call;
  `vignette("exploring-data")` shows how, alongside tidying legend titles.
* `theme_depictr()` now centres legend titles over their keys, which reads more
  tidily than ggplot2's default left alignment -- especially for an inside or a
  top/bottom legend.
* `estimation_plot()` reserves more headroom above the lower panel so the
  effect-size annotation (Hedges' *g* / Cohen's *d*) is never clipped.
* `scree_plot()` colour-matches and names its dual axes -- "Variance explained
  (bars)" on the left, "Cumulative (line)" on the right.
* Statistical letters are italic in annotations: the log-rank *p*,
  `model_report()`'s *n* and *R*, and `estimation_plot()`'s *g* / *d*.
* British (en-GB) spelling throughout: the `crop_yield` column is now
  `fertiliser`, `coefficient_plot()`/`model_report()` take `standardise`, and
  `confusion_matrix_plot()` takes `normalise`.

## Data

* Five reproducibly simulated datasets: `lexical_decision` (counterbalanced
  priming experiment), `wellbeing_survey` (with realistic missingness),
  `crop_yield` (a fertiliser-by-treatment field trial), `clinical_trial`
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
