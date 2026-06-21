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
- [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  for estimation statistics: group effect sizes (mean differences,
  Cohen’s *d* / Hedges’ *g*) with bootstrap confidence intervals, in the
  spirit of the “new statistics”.
- [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md)
  (empirical cumulative distribution, optionally by group),
  [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  (overlapping per-group densities) and
  [`dumbbell_plot()`](https://pablobernabeu.github.io/depictr/reference/dumbbell_plot.md)
  (a connected two-group comparison across categories).
- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md)
  gains `facet` to draw one panel per group instead of overlaying them
  (much clearer beyond a few groups), and
  [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
  gains `reorder` to cluster correlated variables together.

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
  (Kaplan-Meier curves with a number-at-risk table, median survival and
  an optional log-rank test, all computed in base R).
- [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  and
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  help choose and validate the number of clusters (silhouette widths;
  elbow and average-silhouette diagnostics).

### Time series

- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  (one or more series with an optional moving average),
  [`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md)
  (autocorrelation / partial autocorrelation) and
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  (trend / seasonal / remainder decomposition).
- [`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md)
  (seasonal subseries) and
  [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)
  (a simple, dependency-free forecast with prediction intervals).

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
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  now draws the full Bayesian posterior for each term as a half-eye
  density and overlays the matching frequentist point estimate and
  confidence interval, so the two inferential frameworks can be compared
  directly. It reads posterior draws from `brmsfit`, `stanreg`,
  `draws`/`matrix` objects or a data frame.

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
- [`binned_residual_plot()`](https://pablobernabeu.github.io/depictr/reference/binned_residual_plot.md)
  (binned residuals for logistic and other GLMs, with approximate error
  bounds) and
  [`threshold_plot()`](https://pablobernabeu.github.io/depictr/reference/threshold_plot.md)
  (classification metrics across decision thresholds, highlighting
  Youden’s *J* and the maximum-F1 cut-off).

### Uncertainty and power

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  summarises posterior draws with a choice of styles (`"halfeye"`,
  `"interval"`, `"gradient"` or `"dots"`) and can annotate a region of
  practical equivalence (ROPE) and the probability of direction.
- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  for power-analysis curves (e.g. from `simr`).

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
- [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
  sets package-wide defaults once – the brand and accent colours,
  qualitative palette, base font size and family, and the colour used
  for missing values – which every plot and scale then honours.

### Layout and legibility

- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md),
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  and
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  gain a `facet`/`scales` option that lays each term out in its own
  free-scaled panel, so terms on very different scales (a large
  intercept alongside small slopes) stay legible instead of being
  squished onto the zero line.
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  uses this layout by default.
- A pass over every plot for legibility:
  [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  cluster labels no longer clip;
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
  uses one colour per group across all layers;
  [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md)
  hides leaf labels for large trees;
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md)
  picks each label’s colour from the tile luminance;
  [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md)/[`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md)
  label their reference lines;
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  shows a single legend; and
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  now returns the diagnostic curve as a plot.
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  gains `standardise`, scaling each coefficient by its predictor’s
  standard deviation so magnitudes are comparable;
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  uses it by default, removing the empty band in its coefficient panel.
- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  shows the ordinary VIF (not its square root) for single-df terms,
  scales the axis to the data, and draws a single clearly-labelled
  threshold line (reported in the caption when it is off-axis) – no more
  wide empty band or hard-to-read guides.
- `seasonal_plot(style = "season")` reverses its sequential legend so
  the darkest, most-recent cycle sits at the top, matching the plotted
  order.
- Factor coefficient names are prettified by default to the effect
  (variable) name – `conditionunrelated` becomes `condition`,
  `word_frequency` becomes `word frequency` – in
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  and
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  (read from the model);
  [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  gain a `labels` argument for the same. Any user-supplied `labels` take
  precedence.
- Redundant cluster legends are dropped:
  [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  (the bands are labelled in place) and
  [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  when the centroids are labelled.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md):
  the log-rank annotation now renders a proper chi-squared and an italic
  *p*; the median guide is labelled “median ”; the group legend sits
  inside the (always-empty) bottom-left of the panel; and the y-axis
  title margin is tighter.
- [`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md)
  colour-matches and names its dual axes – “Variance explained (bars)”
  on the left, “Cumulative (line)” on the right.
- Statistical letters are italic in annotations: the log-rank *p*,
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)’s
  *n* and *R*, and
  [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)’s
  *g* / *d*.
- British (en-GB) spelling throughout: the `crop_yield` column is now
  `fertiliser`,
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)/[`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  take `standardise`, and
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md)
  takes `normalise`.

### Data

- Five reproducibly simulated datasets: `lexical_decision`
  (counterbalanced priming experiment), `wellbeing_survey` (with
  realistic missingness), `crop_yield` (a fertiliser-by-treatment field
  trial), `clinical_trial` (right-censored survival with a rare adverse
  event) and `monthly_sales` (two seasonal retail series).

### Accessibility

- The qualitative palette is based on the colourblind-safe Okabe-Ito set
  (led by the depictr brand blue), and
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  provides `sequential` and `diverging` variants.
  [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)
  can show any one, or all three, and can simulate deuteranopia,
  protanopia or tritanopia so a palette’s legibility can be checked
  directly.

### Notes

- Heavier modelling back-ends (`lme4`, `broom`, `simr`, `survival`,
  `brms`, `posterior`, `ggdist`, `cluster`, `boot`) are in `Suggests`
  and used only when available, so the package installs and checks
  without them. Vignettes draw on small precomputed model fits shipped
  in `inst/extdata/`, so they knit without a Bayesian or mixed-model
  toolchain.
