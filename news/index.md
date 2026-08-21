# Changelog

## depictr 0.3.0

### Auditing a finished figure

- New
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md),
  an accessibility and honesty audit of the figure you are about to
  submit. Until now the package could vouch for its palette and say
  nothing about a finished plot, which is the thing a reader sees. Give
  it anything a depictr function returns, including a plot extended
  afterwards with `+`, and it introspects the build and returns a tidy
  table. The rows cover the separability of the encoding colours under
  each dichromacy and in greyscale, the smallest text size against a
  stated physical output width, the WCAG contrast of the text and of the
  geometry against their backgrounds, and whether any distinction is
  carried by colour alone. Every row carries the value it measured
  beside the threshold it was measured against, so a verdict can be
  argued with.
- The colour-vision helpers are exported.
  [`simulate_cvd()`](https://pablobernabeu.github.io/depictr/reference/simulate_cvd.md)
  and
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
  were internal here while the Python twin exported both, so the
  advertised parity did not hold. They now match in name, arguments,
  return shape and refusal wording.
  [`simulate_cvd()`](https://pablobernabeu.github.io/depictr/reference/simulate_cvd.md)
  gains a `severity` argument and returns lower-case hex, as the Python
  twin does.
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
  returns the full report, naming the worst condition, the closest pair
  and the verdict. The old return was a bare vector of distances.
- The accessibility claim has been narrowed to what is true. The default
  eight-colour palette clears every colour-vision check and fails the
  new greyscale check: its orange (`#e69f00`) and sky blue (`#56b4e9`)
  differ by 0.79 in CIE lightness, so a black-and-white printer renders
  them as the same grey. The Okabe-Ito guarantee is about hue confusion
  and was never a claim about greyscale. The threshold stays where it
  is, and
  [`vignette("depictr")`](https://pablobernabeu.github.io/depictr/articles/depictr.md)
  now states the limitation where the claim is made, so the package’s
  own defaults are held to the same standard as anybody else’s.

### Figures that misreported the data

- `quantile_residuals()` produced nonsense for a
  `cbind(successes, failures)` binomial model. The two-column response
  matrix was flattened to a vector and the raw success counts were then
  multiplied by the trial totals a second time, so the residuals of a
  well-specified model centred far from zero and the Q-Q diagnostic
  looked catastrophically misspecified. The matrix response now supplies
  its counts and trial totals directly, and the residuals are standard
  normal again where they should be.
- [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  stacked its overlaps upside down. The row sort meant to draw the top
  ridge first is a no-op, because ggplot2 draws ribbon groups in
  factor-level order, so each upper ridge painted over the one below it,
  the opposite of the conventional ridgeline overlap. The draw order is
  now carried by the group aesthetic, with the colour assignment
  unchanged.
- `random_effects_plot(sort = TRUE)` froze every facet in the first
  facet’s order. With more than one term the level factor was shared
  across panels, so only the first panel came out sorted and the rest
  zig-zagged. Each facet now orders its own levels, with the plain level
  names kept on the axis.
- A user-supplied `title` in
  [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  is no longer run through
  [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md),
  which turned a colon into a multiplication sign and blanked
  underscores. Only a title recovered from the power-curve object, which
  is a raw term name, is tidied.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  drew a phantom arm for a group that does not exist. An `NA` in `group`
  became a level of its own, matching no observation, so the plot gained
  an all-censored curve for a group nobody was in, and under
  `logrank = TRUE` it failed outright. Missing groups are now dropped
  with a message saying how many.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  silently discarded non-finite follow-up times. Dropping a case from a
  Kaplan-Meier fit changes the denominator, and so every step of the
  curve and every cell of the number-at-risk table, while the figure
  carries no trace of it. It now refuses them, with the same message as
  the Python twin, since whether to drop or impute is the analyst’s
  decision to make. This replaces a silent drop, so it is a behaviour
  change for anyone who relied on the old handling.
- [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  interpolated past its accessibility guarantee without saying so.
  Beyond the eight Okabe-Ito base colours the palette is a ramp, and the
  colour-vision-deficiency guarantee that is this package’s reason for
  existing stops holding, so the interpolated palette fails the
  package’s own safety check. It now warns at the point of
  interpolation, and only for the built-in palette, since a
  user-supplied one carries no such claim. The documentation is
  qualified to match.
- [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md)
  counted missing-group records in `Overall` and in no group column, so
  the per-group sizes silently fell short of the headline N. They now
  get a `Missing` column of their own.
- A seeded plot leaked its seed into the caller’s random stream in a
  session that had not yet drawn a random number, so the documented
  reproducibility guarantee quietly failed in exactly the fresh session
  that would rely on it.
- `compare_models(facet = TRUE)` now honours
  `depictr_options(reference = )` for its per-panel reference line.
  [`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md)
  no longer labels a frequency-7 series Mon..Sun, an alignment a plain
  `ts` cannot know. And a mistyped `labels` key now warns, so the raw
  parameter name no longer sits on the plot.

### Degenerate input

- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  now says when it drops observations with a missing status, in the
  wording of the missing-group message. The drop was previously silent.
  A status that is missing for every observation is an error. This
  brings the third kind of incomplete survival input into line with the
  other two, a missing group being announced and a non-finite time
  refused.
- [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  checks that `clusters` has one entry per row of `data` before dropping
  incomplete rows. A vector sized to the complete rows used to slip past
  the late check, because subsetting it with the logical index padded it
  with `NA`, and then died in the distance computation. It is now
  refused with the same message
  [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  uses.
- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md)
  no longer fails on a rank-deficient `lm` with a raw “differing number
  of rows” error. [`confint()`](https://rdrr.io/r/stats/confint.html)
  keeps aliased terms as `NA` rows while `coef(summary())` drops them,
  so the intervals are now cut to the estimated terms, with a message
  naming the aliased terms that were left out.
- [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  and
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  drop zero-variance columns with a message when `scale = TRUE`, as
  [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
  already did, so a raw k-means error no longer escapes.
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  now names the values of `k_range` it cannot evaluate instead of
  dropping them from the search without a word, and
  [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
  labels an undefined correlation `n/a` where it once printed `r = NA`
  beside a raw [`stats::cor()`](https://rdrr.io/r/stats/cor.html)
  warning.

### Metadata and documentation

- The declared minimum dependency versions are now installed and tested
  by a CI job. The patchwork floor is raised from 1.2.0 to 1.3.0. That
  was verified by running it: 1.2.0 cannot run
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  at all, because `patchwork::free(type =, side =)` arrived in 1.3.0.
- [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md)
  documents that the perfect-model reference line is drawn for a single
  model only, which is what the code has always done, and a test now
  pins it. The line bends at the prevalence of the outcome, and overlaid
  models need not share a prevalence.
- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md)
  documents that a single model is enough, which is what the code always
  accepted, and
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
  no longer claims to be built from base graphics primitives: like
  [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md),
  it is base R and ggplot2 alone.
- [`?depictr`](https://pablobernabeu.github.io/depictr/reference/depictr-package.md)
  again lists every exported function
  ([`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  and the
  [`scale_color_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  alias were missing), the README no longer describes the Python package
  as a feature-parity twin (its own README says otherwise), CONTRIBUTING
  no longer claims the maintenance workflows close their own issues, and
  the `standardise = TRUE` axis label now names the x-only convention
  the figure uses.
- The README no longer opens with a link to the documentation site,
  which on the site’s own home page pointed the reader at the page in
  front of them.
- Every vignette now turns console colour off and fixes the console
  width while it renders. pkgdown passes the calling terminal’s colour
  support into its build subprocess, so a coloured message or error
  would otherwise reach the reader as escape sequences in the middle of
  the text.

## depictr 0.2.2

### Examples that match the chart

- The precision-recall, gain and lift examples move to an outcome with a
  scarce positive class, which is the case those charts are documented
  for. They previously ran on an outcome that was 94 per cent positive,
  so the gain curve sat on the diagonal and lift hovered at one.
- The calibration example fits a model and plots its predicted
  probabilities, since a reliability curve is a check on a fitted model.
- The power-curve article names the effect the shipped simulation
  actually covers, and its no-simr branch reads a summary derived from
  that simulation, so the two branches agree by construction.

### Fixes

- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  restricts its scale to the severity levels present, which removes an
  empty key entry from the rendered figure.

## depictr 0.2.1

### Documentation

- The introductory vignette shows
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  returning the palette’s hex colours directly, ready for
  [`scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  or a base-graphics `col =` argument, and shows
  [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
  setting defaults for every later plot and returning the previous
  values, so the earlier look can be put back afterwards.
- [`vignette("diagnostics-and-uncertainty")`](https://pablobernabeu.github.io/depictr/articles/diagnostics-and-uncertainty.md)
  saves an arranged panel with
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md),
  which writes at a print-ready 300 dpi by default and creates any
  missing directories.
- [`vignette("multivariate-and-survival")`](https://pablobernabeu.github.io/depictr/articles/multivariate-and-survival.md)
  adds `k_diagnostic(method = "gap")`, which compares within-cluster
  dispersion against a null reference and so, unlike the other two
  criteria, can support `k = 1`.
- [`vignette("time-series")`](https://pablobernabeu.github.io/depictr/articles/time-series.md)
  adds classical decomposition, which holds the seasonal component fixed
  across the series where STL lets it evolve from year to year.
- The
  [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  and
  [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  reference pages describe what each plot shows. Both pages previously
  described the prototype gists the plots grew from.
- On the documentation site, source chunks are set a little smaller than
  the output and the prose, so a typical line fits the narrower home and
  article columns without horizontal scrolling, and the copy button
  stays attached to its code block.

## depictr 0.2.0

### Fixes

- [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md)
  rejects a `ci` that resolves to fewer than one bootstrap resample,
  with a clear error. Until then it drew an all-`NA` band and an
  `[NA, NA]` AUC annotation, saying nothing.

### Data

- In `wellbeing_survey`, region now shifts stress and income, which flow
  through to life satisfaction. The region-grouped plots (faceted
  densities, ridgelines, the region dendrogram) therefore compare four
  distinct distributions where earlier they compared four samples of
  one. The bundled datasets are regenerated by
  `data-raw/generate_datasets.R` as before.

### Citation

- The package citation (`inst/CITATION` and `CITATION.cff`) carries the
  Zenodo concept DOI, and the citation title uses sentence case.

### Documentation

- The package overview
  ([`?depictr`](https://pablobernabeu.github.io/depictr/reference/depictr-package.md))
  lists every exported function and all five bundled datasets.
  Previously several functions and two datasets were missing.
- The
  [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  example fits deliberately collinear predictors, so the plot shows
  inflated VIFs sitting above the threshold line. The earlier example
  produced near-identical bars around 1, with the line off the axis.
- [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
  describes what `brand` and `accent` actually drive, and
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  notes that qualitative colours interpolated beyond the base set are
  not guaranteed to stay distinguishable under colour-vision deficiency.
- [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md)
  documents its own top-right inside-legend corner rather than
  inheriting
  [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md)‘s
  bottom-right wording, and `DESCRIPTION` notes that composite panels
  return ’patchwork’ objects.
- References throughout the documentation follow APA 7 and carry DOIs,
  and spelling is consistently British (en-GB).
- The documentation site’s home page is restructured around a pitch,
  gallery and signposts. The time-series decomposition example draws its
  trend confidence band. `LICENSE.md` carries the full MIT text so the
  site’s licence page renders in full, as in the sibling packages.

### Packaging and checks

- Example variants that render several multi-panel figures
  ([`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md),
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md),
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md))
  are wrapped in `\donttest{}` so each example file stays within CRAN’s
  five-second budget. The first call of every example still runs.
- `CITATION.cff` and the test artefact `Rplots.pdf` are excluded from
  the build tarball, and the test that produced `Rplots.pdf` draws to a
  null device instead.
- New tests pin the `legend_inside` gates. The legend moves inside the
  panel when a plot’s gate is satisfied, and the theme is left alone
  when it is not.

## depictr 0.1.1

- Documentation and packaging polish, with no change to the plotting
  API.
- The documentation site adopts the shared house style used across the
  package family, with a citation page carrying a copyable and
  downloadable BibTeX entry.
- Consolidated to a single `LICENSE` file, and added community and
  contribution files.

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
  spirit of the ‘new statistics’.
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
  help choose and validate the number of clusters (silhouette widths,
  plus elbow and average-silhouette diagnostics).

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
  provides the shared tidy estimate table, with methods for `lm`, `glm`,
  `merMod` and data frames and a fallback to
  [`broom::tidy()`](https://generics.r-lib.org/reference/tidy.html).
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
  sets package-wide defaults once, covering the brand and accent
  colours, qualitative palette, base font size and family, and the
  colour used for missing values. Every plot and scale then honours
  them.

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
- Every plot has had a pass for legibility.
  [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  cluster labels no longer clip.
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
  uses one colour per group across all layers.
  [`dendrogram_plot()`](https://pablobernabeu.github.io/depictr/reference/dendrogram_plot.md)
  hides leaf labels for large trees.
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md)
  picks each label’s colour from the tile luminance.
  [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md)
  and
  [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md)
  label their reference lines.
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  shows a single legend, and
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  now returns the diagnostic curve as a plot.
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  gains `standardise`, scaling each coefficient by its predictor’s
  standard deviation so magnitudes are comparable.
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  uses it by default, removing the empty band in its coefficient panel.
- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  shows the ordinary VIF (not its square root) for single-df terms,
  scales the axis to the data, and draws a single clearly-labelled
  threshold line (reported in the caption when it is off-axis), leaving
  no wide empty band or hard-to-read guides.
- `seasonal_plot(style = "season")` reverses its sequential legend so
  the darkest, most-recent cycle sits at the top, matching the plotted
  order.
- Factor coefficient names are prettified by default to the effect
  (variable) name in
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  and
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md),
  where they are read from the model, so `conditionunrelated` becomes
  `condition` and `word_frequency` becomes `word frequency`.
  [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  gain a `labels` argument for the same. Any user-supplied `labels` take
  precedence.
  [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  likewise shows underscores in its loading-arrow labels as spaces
  (`soil_ph` -\> `soil ph`).
- Redundant cluster legends are dropped:
  [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  (the bands are labelled in place) and
  [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  when the centroids are labelled.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  has been tidied in several ways. The log-rank annotation renders a
  proper chi-squared and an italic *p*, formatted APA style (no leading
  zero, *p* \< .001 below that threshold). The median guide is labelled
  `median <value>`. The y-axis title margin is tighter, and the colour
  legend and the number-at-risk table list the groups in the same order,
  following the group factor’s levels.
- A `legend_inside` argument (off by default) draws the legend inside
  the panel, over a semi-transparent background, in a corner the plot
  usually leaves empty, which reclaims the right-hand margin. It is
  offered by
  [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md),
  [`gain_plot()`](https://pablobernabeu.github.io/depictr/reference/gain_plot.md),
  [`lift_plot()`](https://pablobernabeu.github.io/depictr/reference/lift_plot.md)
  (bottom-right / top-right of the curve),
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md),
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md),
  [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`dumbbell_plot()`](https://pablobernabeu.github.io/depictr/reference/dumbbell_plot.md)
  and
  [`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md).
  For any other plot the same is one
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) call,
  and
  [`vignette("exploring-data")`](https://pablobernabeu.github.io/depictr/articles/exploring-data.md)
  shows how, alongside tidying legend titles.
- [`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md)
  now centres legend titles over their keys, which reads more tidily
  than ggplot2’s default left alignment, especially for an inside or a
  top/bottom legend.
- [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  reserves more headroom above the lower panel so the effect-size
  annotation (Hedges’ *g* / Cohen’s *d*) is never clipped.
- [`scree_plot()`](https://pablobernabeu.github.io/depictr/reference/scree_plot.md)
  colour-matches and names its dual axes, ‘Variance explained (bars)’ on
  the left and ‘Cumulative (line)’ on the right.
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
- Functions with an optional `seed`
  ([`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md),
  [`qq_plot()`](https://pablobernabeu.github.io/depictr/reference/qq_plot.md)
  and
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md))
  restore the caller’s random number generator state afterward, so
  passing one for reproducibility has no side effect on your own
  subsequent random draws.
