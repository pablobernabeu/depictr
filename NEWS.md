# depictr (development version)

## Figures that misreported the data

* `estimation_plot()`, and `group_comparison_plot(differences = TRUE)` which
  calls it, failed in a fresh R session with "Can't find method for generic
  `/(e1, e2)`", or with "non-numeric argument to binary operator" under
  ggplot2 3.5. The two panels were stacked with patchwork's `/` operator, which
  exists only once patchwork has been loaded, and nothing in depictr loaded it.
  The panels are now composed with `patchwork::wrap_plots()`, and depictr
  imports patchwork, so `library(depictr)` loads it.

* `coefficient_plot()` attached an unnamed `labels` vector to the wrong
  coefficients. The labels were assigned after the terms had been reversed or
  sorted for display, so in `lm(yield ~ rainfall + fertiliser + soil_ph)` soil pH
  was labelled 'Rainfall'. An unnamed vector is now bound to the terms in model
  order before any reordering. `compare_models()` and
  `frequentist_bayesian_plot()` counted one row per term and source, or one per
  posterior draw, and so refused a vector with one label per term. Both now
  accept one, read with the terms in the order they first appear. Named labels
  are unchanged and remain the safer form. The documentation of `order` now says
  which end the largest estimate lands at.

* `model_fit_table()` and the `model_report()` subtitle misreported R² for `glm`
  models. McFadden's ratio was applied to every family, so a Gaussian `glm`
  could report a negative value and a quasi-likelihood family reported `NA`.
  The null model was refitted with `update()`. That used more rows than the
  model when a predictor had missing values, dropped an offset written in the
  formula, put an intercept in the null of a model fitted without one and gave
  `NA` for a model fitted inside a function. Every `glm`, including
  quasi-likelihood and negative binomial fits, now reports the deviance R²,
  1 - D/D0, computed from the deviances the fit already holds. It equals the
  ordinary R² for a Gaussian model with the identity link and McFadden's R²
  for binary logistic regression, so a binary logistic value changes only
  where the old refit went wrong. Values for Poisson, grouped binomial, Gamma
  and other models change by definition. The `model_report()` subtitle now
  calls it the deviance R², where it said pseudo-R².
* For mixed models fitted by REML with `lme4::lmer()`, `model_fit_table()` now
  takes AIC, BIC and the log-likelihood from a maximum-likelihood refit and
  says so in a message. REML criteria cannot be compared between models with
  different fixed effects, which is the comparison the model-estimates
  vignette makes. If a refit fails, a warning says so and that model's
  criteria are `NA`. The `R2` column stays `NA` for mixed models, as the help
  page now documents.

* A `glm` fitted with `na.action = na.exclude` broke the classification and
  diagnostic plots. Its fitted values are padded with `NA` to the length of the
  data while its response is not, and the plots paired the two. The ROC,
  precision-recall, threshold, gain and lift plots and the confusion matrix
  failed, and `calibration_plot()` silently dropped bins and drew the rest with
  other rows' outcomes. In the Q-Q panel of `residual_diagnostics_plot()`, the
  quantile residuals set each response against another row's fitted value, and
  for a Gaussian model they were all `NA`, so the panel was empty. All of them
  now use the model's own unpadded components. `residual_diagnostics_plot()` and
  `influence_plot()` also leave the excluded rows out of their frames, for an
  `lm` as for a `glm`. They no longer warn about removing those rows, and the
  2p/n leverage line of `influence_plot()` no longer counts them.
* The quantile residuals in the Q-Q panel of `residual_diagnostics_plot()`
  ignored prior weights in Gaussian and Gamma models. Every observation was given
  the same scale, so a correctly specified weighted model showed spurious
  departures from the line. The weights now scale each observation's variance,
  as they do in the fit.

* A brms posterior passed as a `posterior` draws object was read as a plain
  table. `frequentist_bayesian_plot()` silently pooled `b_Intercept` with
  `Intercept`, the intercept brms reports for centred predictors, into one
  slab. It also drew the sampler's log density and every random effect as
  parameters. `posterior_plot()` stopped with an error about duplicated factor
  levels. Draws objects now keep their population-level (`b_`) parameters,
  named without the prefix as for a brms fit, with a message naming what was
  dropped. A `labels` key for one of them is written without the prefix too.
  In both functions, two parameters whose draws would share a label are now an
  error, and `lp__` and `lprior` are never drawn as parameters, whatever form
  the draws take. For a `stanreg` fit, the group-level `b[...]` and
  `Sigma[...]` draws are no longer read as fixed effects either.
* When `bayesian` holds draws, `frequentist_bayesian_plot()` now draws only the
  terms both inputs share, and a message names any it dropped. A `sigma` in the
  posterior, or a frequentist term with no posterior, no longer takes a row of
  its own. Inputs that share no terms are an error.
* A `brms::fixef()` matrix was read as draws, so it came out as four
  'parameters' named after its columns. `frequentist_bayesian_plot()` now takes
  the summary path for it, and `posterior_plot()`, which needs draws, refuses
  it. The summary path also no longer warns about label keys you never
  supplied.

* `survival_plot()` read the `status` coding separately in each group. Under the
  `survival::Surv()` 1/2 convention, a group whose subjects were all censored
  (all `1`) fits the 0/1 convention as well, so it was read as a group in which
  every subject had the event, and its curve fell to zero. Codings that mixed
  the two conventions across groups were accepted silently. The coding is now
  read once, over all observations.
* `survival_plot()` silently misread a factor `status`. The factor was coerced
  to its level codes and read under the 1/2 convention, so whichever level sorted
  first was taken as censored, whatever it meant. A character `status` became
  `NA` throughout, with only a coercion warning, and drew a flat curve at one.
  Both are now refused with an error that says to recode the indicator first.
* `survival_plot()` ignored its `group` and `status` arguments when `time` was a
  data frame. It read both from conventionally named columns only (`group`,
  `strata` or `arm`, and `status` or `event`), so
  `survival_plot(df, group = "treatment")` drew a single pooled curve with no
  legend, log-rank test or risk-table rows. A column name or a vector with one
  entry per row is now honoured for both, and takes precedence over the
  conventionally named column. A name that matches no column is an error.
* The number-at-risk table of `survival_plot()` could miscount at its default
  breaks. `pretty()` returns multiples of a binary floating-point step, so with
  follow-up up to 1.2 the break labelled 0.6 was 0.6000000000000001, and a
  subject followed up to exactly 0.6 was left out of the count there. A last
  break equal to the longest follow-up was lost the same way. The breaks are
  now rounded to their step before the counts are taken.

* `save_plot()` wrote files that fail the checks journals run on submitted
  figures. An EPS left out every translucent element, including all the points
  and the confidence band of the first `scatter_trend()` example, with only a
  terse device warning to show for it, and it named its fonts without embedding
  them. A PDF did not embed its fonts either. A TIFF was uncompressed: 8.1 MiB
  at the default 7 by 4.5 inches, and more than the 10 MB PLOS allows at the
  largest figure size it accepts. A transparent background, such as
  `theme_void()` leaves, could also give the TIFF the alpha channel PLOS
  refuses. PDF and EPS files now go through the cairo devices, which embed the
  fonts. An EPS rasterises its translucent layers, and whatever they overlap,
  at 600 dpi or more, with a message when it does. A TIFF is now LZW-compressed
  and drawn on white unless `bg` is given. On a Mac without ragg, it is drawn
  by the cairo TIFF device, because the default quartz one ignores compression.
  A `device` or device argument passed to `save_plot()` still wins. Without
  cairo, the old devices are used, with a message or a warning saying what the
  file lacks.

* `effects_plot()`, `interaction_plot()` and `model_report()` failed on any
  model with a transformed term (`log()`, `poly()`, `ns()`, `scale()`,
  `factor()`, `I()`) or an offset. Where a transformed term sat beside its raw
  variable, they drew a flat effect line or coincident interaction lines
  without complaint. The prediction grid is now built from the raw variables,
  so `predict()` re-applies every transformation, and offsets are held at their
  sample mean on the link scale, as the y-axis label now says. A model-frame
  name such as `"log(rainfall)"` stands for the variable it transforms, and the
  x-axis shows that variable.
* The raw values behind a transformed term come from the data named in the
  model's call. A model fitted to workspace vectors without `data =` is
  therefore refused, where it could silently plot its fitted values against the
  grid, and so is a data frame that has changed since the fit or a formula that
  reads one with `$`. A term computed from statistics of its rows, such as
  `I(x - mean(x))`, is refused as well, since `predict()` would compute it
  afresh over the grid. Beside its raw variable, such a term used to shift the
  line without complaint.

* `ts_forecast()`, and the forecast overlay of `timeseries_plot()`, drew
  prediction intervals far too narrow. In rolling-origin backtests on eight
  classic series, the nominal 95% band covered about 60% of one-step-ahead
  outcomes. The documentation credited its square-root widening to seasonal
  naive forecasting, whose variance does not grow that way. Forecasts now come
  from a random walk with drift on the STL-seasonally-adjusted series, with the
  last seasonal cycle added back, which reproduces
  `forecast::stlf(method = "rwdrift", s.window = "periodic")`. A new `lambda`
  argument in both functions applies a Box-Cox (or log) transformation for a
  seasonal swing that grows with the level, and a caption on the overlay names
  the interval and the method. A series of exactly two cycles now gets the
  package's own message, and `decompose_plot()` gains `s_window`. The
  vignette's claim that STL lets the seasonal component evolve held only for a
  window this release exposes for the first time.
* `timeseries_plot()` drew the forecast of a numeric `x` in the wrong place.
  The forecaster counted time in cycles from 1, while the history sits at the
  observation index or at the supplied `time`. The overlay therefore jumped
  back towards the start of the axis, and on a `Date` axis it landed in the
  year 4. The forecast now continues the history's own axis, one typical step
  at a time. An unsorted `time` is also put in order before forecasting, as it
  already was for the moving average.

* `pca_plot()` now fixes the aspect ratio, so the angles drawn between the
  loading arrows are their angles in loading space whatever the size of the
  device. The panel's height and width follow the ranges of its axes, so a
  figure of another shape gains blank space around the panel. The arrows and
  their labels are drawn in a neutral dark grey (`grey20`) in place of the
  accent, which is also the palette's fourth colour and so tied the variables
  to the fourth group. A misspelt `group` column, a column name passed with a
  `prcomp` object and a `group` vector of the wrong length are now errors. The
  first put one point in a level named after the misspelling and the rest in
  `NA`. The second put every point in one level named after the column, and
  the third was padded with `NA` or recycled in silence. `group` also takes an
  unquoted column name, as elsewhere in the package. A `prcomp` object fitted
  with `retx = FALSE` has no scores to draw, and it is now refused with a
  message that says so.

## Degenerate input

* `survival_plot()` truncated a non-integer status code, so `c(0, 0.5, 1)` was
  read as two censored observations and an event. Non-integer codes are now
  refused with the existing coding message.
* `survival_plot()` kept an arm whose every `status` was missing when `group`
  was a factor. The arm stayed in the legend with no curve and a row of zeros
  in the risk table, and `logrank = TRUE` failed with an error that did not say
  why. The arm is now dropped with the missing statuses, as it already was for
  a character `group`.

## Auditing a finished figure

* `check_figure()` measured all text against the plot background, so text on a
  coloured facet strip or legend box was judged against a background it is not
  drawn on: white strip text on a dark strip failed and unreadable grey strip text
  passed. Each text is now measured against its own background, with a
  translucent fill taken as the colour it shows over what lies beneath it. Large
  text (18 pt, or 14 pt bold, as printed) is held to the 3:1 that WCAG asks of it,
  where it used to be held to 4.5:1. The `text_contrast` row reports the text that
  falls furthest short of its own threshold and gives that threshold, and its
  detail names the text's printed size and weight. A translucent plot or panel
  background is also measured as the colour it shows. Its alpha used to be
  dropped, so `geometry_contrast` moves for such a figure. The
  relative-luminance code now cites the current WCAG 2.2 definition and its
  0.04045 breakpoint, which changes no ratio.

# depictr 0.3.0

## Auditing a finished figure

* New `check_figure()`, an accessibility and honesty audit of the figure you are
  about to submit. Until now the package could vouch for its palette and say
  nothing about a finished plot, which is the thing a reader sees. Give it
  anything a depictr function returns, including a plot extended afterwards with
  `+`, and it introspects the build and returns a tidy table. The rows cover the
  separability of the encoding colours under each dichromacy and in greyscale, the
  smallest text size against a stated physical output width, the WCAG contrast of
  the text and of the geometry against their backgrounds, and whether any
  distinction is carried by colour alone. Every row carries the value it measured
  beside the threshold it was measured against, so a verdict can be argued with.
* The colour-vision helpers are exported. `simulate_cvd()` and `palette_safety()`
  were internal here while the Python twin exported both, so the advertised parity
  did not hold. They now match in name, arguments, return shape and refusal
  wording. `simulate_cvd()` gains a `severity` argument and returns lower-case hex,
  as the Python twin does. `palette_safety()` returns the full report, naming the
  worst condition, the closest pair and the verdict. The old return was a bare
  vector of distances.
* The accessibility claim has been narrowed to what is true. The default
  eight-colour palette clears every colour-vision check and fails the new greyscale
  check: its orange (`#e69f00`) and sky blue (`#56b4e9`) differ by 0.79 in CIE
  lightness, so a black-and-white printer renders them as the same grey. The
  Okabe-Ito guarantee is about hue confusion and was never a claim about greyscale.
  The threshold stays where it is, and `vignette("depictr")` now states the
  limitation where the claim is made, so the package's own defaults are held to the
  same standard as anybody else's.

## Figures that misreported the data

* `quantile_residuals()` produced nonsense for a `cbind(successes, failures)`
  binomial model. The two-column response matrix was flattened to a vector and
  the raw success counts were then multiplied by the trial totals a second time,
  so the residuals of a well-specified model centred far from zero and the Q-Q
  diagnostic looked catastrophically misspecified. The matrix response now
  supplies its counts and trial totals directly, and the residuals are standard
  normal again where they should be.
* `ridgeline_plot()` stacked its overlaps upside down. The row sort meant to
  draw the top ridge first is a no-op, because ggplot2 draws ribbon groups in
  factor-level order, so each upper ridge painted over the one below it, the
  opposite of the conventional ridgeline overlap. The draw order is now carried
  by the group aesthetic, with the colour assignment unchanged.
* `random_effects_plot(sort = TRUE)` froze every facet in the first facet's
  order. With more than one term the level factor was shared across panels, so
  only the first panel came out sorted and the rest zig-zagged. Each facet now
  orders its own levels, with the plain level names kept on the axis.
* A user-supplied `title` in `power_curve_plot()` is no longer run through
  `format_terms()`, which turned a colon into a multiplication sign and blanked
  underscores. Only a title recovered from the power-curve object, which is a raw
  term name, is tidied.
* `survival_plot()` drew a phantom arm for a group that does not exist. An `NA` in
  `group` became a level of its own, matching no observation, so the plot gained an
  all-censored curve for a group nobody was in, and under `logrank = TRUE` it failed
  outright. Missing groups are now dropped with a message saying how many.
* `survival_plot()` silently discarded non-finite follow-up times. Dropping a case
  from a Kaplan-Meier fit changes the denominator, and so every step of the curve and
  every cell of the number-at-risk table, while the figure carries no trace of it. It
  now refuses them, with the same message as the Python twin, since whether to drop
  or impute is the analyst's decision to make. This replaces a silent drop, so it is
  a behaviour change for anyone who relied on the old handling.
* `depictr_palette()` interpolated past its accessibility guarantee without saying
  so. Beyond the eight Okabe-Ito base colours the palette is a ramp, and the
  colour-vision-deficiency guarantee that is this package's reason for existing stops
  holding, so the interpolated palette fails the package's own safety check. It now
  warns at the point of interpolation, and only for the built-in palette, since a
  user-supplied one carries no such claim. The documentation is qualified to match.
* `summary_table()` counted missing-group records in `Overall` and in no group
  column, so the per-group sizes silently fell short of the headline N. They now get a
  `Missing` column of their own.
* A seeded plot leaked its seed into the caller's random stream in a session that had
  not yet drawn a random number, so the documented reproducibility guarantee quietly
  failed in exactly the fresh session that would rely on it.
* `compare_models(facet = TRUE)` now honours `depictr_options(reference = )` for its
  per-panel reference line. `seasonal_plot()` no longer labels a frequency-7 series
  Mon..Sun, an alignment a plain `ts` cannot know. And a mistyped `labels` key now
  warns, so the raw parameter name no longer sits on the plot.

## Degenerate input

* `survival_plot()` now says when it drops observations with a missing status,
  in the wording of the missing-group message. The drop was previously silent.
  A status that is missing for every observation is an error. This brings the
  third kind of incomplete survival input into line with the other two, a missing
  group being announced and a non-finite time refused.
* `silhouette_plot()` checks that `clusters` has one entry per row of `data`
  before dropping incomplete rows. A vector sized to the complete rows used to
  slip past the late check, because subsetting it with the logical index padded
  it with `NA`, and then died in the distance computation. It is now refused with
  the same message `cluster_plot()` uses.
* `tidy_estimates()` no longer fails on a rank-deficient `lm` with a raw
  "differing number of rows" error. `confint()` keeps aliased terms as `NA` rows
  while `coef(summary())` drops them, so the intervals are now cut to the estimated
  terms, with a message naming the aliased terms that were left out.
* `cluster_plot()` and `k_diagnostic()` drop zero-variance columns with a message
  when `scale = TRUE`, as `correlation_heatmap()` already did, so a raw k-means
  error no longer escapes. `k_diagnostic()` now names the values of `k_range` it
  cannot evaluate instead of dropping them from the search without a word, and
  `explore_pairs()` labels an undefined correlation `n/a` where it once printed
  `r = NA` beside a raw `stats::cor()` warning.

## Metadata and documentation

* The declared minimum dependency versions are now installed and tested by a CI job.
  The patchwork floor is raised from 1.2.0 to 1.3.0. That was verified by running
  it: 1.2.0 cannot run `model_report()` at all, because
  `patchwork::free(type =, side =)` arrived in 1.3.0.
* `gain_plot()` documents that the perfect-model reference line is drawn for a
  single model only, which is what the code has always done, and a test now pins
  it. The line bends at the prevalence of the outcome, and overlaid models need
  not share a prevalence.
* `model_fit_table()` documents that a single model is enough, which is what the
  code always accepted, and `raincloud_plot()` no longer claims to be built from
  base graphics primitives: like `ridgeline_plot()`, it is base R and ggplot2
  alone.
* `?depictr` again lists every exported function (`scale_fill_depictr()` and the
  `scale_color_depictr()` alias were missing), the README no longer describes the Python
  package as a feature-parity twin (its own README says otherwise), CONTRIBUTING no
  longer claims the maintenance workflows close their own issues, and the
  `standardise = TRUE` axis label now names the x-only convention the figure uses.
* The README no longer opens with a link to the documentation site, which on the site's
  own home page pointed the reader at the page in front of them.
* Every vignette now turns console colour off and fixes the console width while it
  renders. pkgdown passes the calling terminal's colour support into its build
  subprocess, so a coloured message or error would otherwise reach the reader as escape
  sequences in the middle of the text.

# depictr 0.2.2

## Examples that match the chart

* The precision-recall, gain and lift examples move to an outcome with a scarce
  positive class, which is the case those charts are documented for. They
  previously ran on an outcome that was 94 per cent positive, so the gain curve
  sat on the diagonal and lift hovered at one.
* The calibration example fits a model and plots its predicted probabilities,
  since a reliability curve is a check on a fitted model.
* The power-curve article names the effect the shipped simulation actually
  covers, and its no-simr branch reads a summary derived from that simulation,
  so the two branches agree by construction.

## Fixes

* `vif_plot()` restricts its scale to the severity levels present, which removes
  an empty key entry from the rendered figure.

# depictr 0.2.1

## Documentation

* The introductory vignette shows `depictr_palette()` returning the palette's
  hex colours directly, ready for `scale_fill_manual()` or a base-graphics
  `col =` argument, and shows `depictr_options()` setting defaults for every
  later plot and returning the previous values, so the earlier look can be put
  back afterwards.
* `vignette("diagnostics-and-uncertainty")` saves an arranged panel with
  `save_plot()`, which writes at a print-ready 300 dpi by default and creates
  any missing directories.
* `vignette("multivariate-and-survival")` adds `k_diagnostic(method = "gap")`,
  which compares within-cluster dispersion against a null reference and so,
  unlike the other two criteria, can support `k = 1`.
* `vignette("time-series")` adds classical decomposition, which holds the
  seasonal component fixed across the series where STL lets it evolve from year
  to year.
* The `optimizer_fixef_plot()` and `power_curve_plot()` reference pages
  describe what each plot shows. Both pages previously described the prototype
  gists the plots grew from.
* On the documentation site, source chunks are set a little smaller than the
  output and the prose, so a typical line fits the narrower home and article
  columns without horizontal scrolling, and the copy button stays attached to
  its code block.

# depictr 0.2.0

## Fixes

* `roc_curve_plot()` rejects a `ci` that resolves to fewer than one bootstrap
  resample, with a clear error. Until then it drew an all-`NA` band and an
  `[NA, NA]` AUC annotation, saying nothing.

## Data

* In `wellbeing_survey`, region now shifts stress and income, which flow through
  to life satisfaction. The region-grouped plots (faceted densities, ridgelines,
  the region dendrogram) therefore compare four distinct distributions where
  earlier they compared four samples of one. The bundled datasets are regenerated
  by `data-raw/generate_datasets.R` as before.

## Citation

* The package citation (`inst/CITATION` and `CITATION.cff`) carries the Zenodo
  concept DOI, and the citation title uses sentence case.

## Documentation

* The package overview (`?depictr`) lists every exported function and all five
  bundled datasets. Previously several functions and two datasets were missing.
* The `vif_plot()` example fits deliberately collinear predictors, so the plot
  shows inflated VIFs sitting above the threshold line. The earlier example
  produced near-identical bars around 1, with the line off the axis.
* `depictr_options()` describes what `brand` and `accent` actually drive, and
  `depictr_palette()` notes that qualitative colours interpolated beyond the
  base set are not guaranteed to stay distinguishable under colour-vision
  deficiency.
* `lift_plot()` documents its own top-right inside-legend corner rather than
  inheriting `gain_plot()`'s bottom-right wording, and `DESCRIPTION` notes
  that composite panels return 'patchwork' objects.
* References throughout the documentation follow APA 7 and carry DOIs, and
  spelling is consistently British (en-GB).
* The documentation site's home page is restructured around a pitch, gallery
  and signposts. The time-series decomposition example draws its trend
  confidence band. `LICENSE.md` carries the full MIT text so the site's
  licence page renders in full, as in the sibling packages.

## Packaging and checks

* Example variants that render several multi-panel figures
  (`posterior_plot()`, `residual_diagnostics_plot()`, `decompose_plot()`) are
  wrapped in `\donttest{}` so each example file stays within CRAN's
  five-second budget. The first call of every example still runs.
* `CITATION.cff` and the test artefact `Rplots.pdf` are excluded from the
  build tarball, and the test that produced `Rplots.pdf` draws to a null
  device instead.
* New tests pin the `legend_inside` gates. The legend moves inside the panel
  when a plot's gate is satisfied, and the theme is left alone when it is not.

# depictr 0.1.1

* Documentation and packaging polish, with no change to the plotting API.
* The documentation site adopts the shared house style used across the package
  family, with a citation page carrying a copyable and downloadable BibTeX entry.
* Consolidated to a single `LICENSE` file, and added community and contribution
  files.

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
  intervals, in the spirit of the 'new statistics'.
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
  of clusters (silhouette widths, plus elbow and average-silhouette
  diagnostics).

## Time series

* `timeseries_plot()` (one or more series with an optional moving average),
  `acf_plot()` (autocorrelation / partial autocorrelation) and
  `decompose_plot()` (trend / seasonal / remainder decomposition).
* `seasonal_plot()` (seasonal subseries) and `ts_forecast()` (a simple,
  dependency-free forecast with prediction intervals).

## Model estimates and inference

* `tidy_estimates()` provides the shared tidy estimate table, with methods for
  `lm`, `glm`, `merMod` and data frames and a fallback to `broom::tidy()`.
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
* `depictr_options()` sets package-wide defaults once, covering the brand and
  accent colours, qualitative palette, base font size and family, and the colour
  used for missing values. Every plot and scale then honours them.

## Layout and legibility

* `coefficient_plot()`, `compare_models()`, `posterior_plot()` and
  `frequentist_bayesian_plot()` gain a `facet`/`scales` option that lays each
  term out in its own free-scaled panel, so terms on very different scales (a
  large intercept alongside small slopes) stay legible instead of being squished
  onto the zero line. `frequentist_bayesian_plot()` uses this layout by default.
* Every plot has had a pass for legibility. `silhouette_plot()` cluster labels
  no longer clip. `raincloud_plot()` uses one colour per group across all
  layers. `dendrogram_plot()` hides leaf labels for large trees.
  `confusion_matrix_plot()` picks each label's colour from the tile luminance.
  `gain_plot()` and `lift_plot()` label their reference lines.
  `timeseries_plot()` shows a single legend, and `k_diagnostic()` now returns
  the diagnostic curve as a plot.
* `coefficient_plot()` gains `standardise`, scaling each coefficient by its
  predictor's standard deviation so magnitudes are comparable. `model_report()`
  uses it by default, removing the empty band in its coefficient panel.
* `vif_plot()` shows the ordinary VIF (not its square root) for single-df terms,
  scales the axis to the data, and draws a single clearly-labelled threshold
  line (reported in the caption when it is off-axis), leaving no wide empty band
  or hard-to-read guides.
* `seasonal_plot(style = "season")` reverses its sequential legend so the
  darkest, most-recent cycle sits at the top, matching the plotted order.
* Factor coefficient names are prettified by default to the effect (variable)
  name in `coefficient_plot()`, `compare_models()` and
  `frequentist_bayesian_plot()`, where they are read from the model, so
  `conditionunrelated` becomes `condition` and `word_frequency` becomes
  `word frequency`. `optimizer_fixef_plot()`
  and `posterior_plot()` gain a `labels` argument for the same. Any user-supplied
  `labels` take precedence. `pca_plot()` likewise shows underscores in its
  loading-arrow labels as spaces (`soil_ph` -> `soil ph`).
* Redundant cluster legends are dropped: `silhouette_plot()` (the bands are
  labelled in place) and `cluster_plot()` when the centroids are labelled.
* `survival_plot()` has been tidied in several ways. The log-rank annotation
  renders a proper chi-squared and an italic *p*, formatted APA style (no
  leading zero, *p* < .001 below that threshold). The median guide is labelled
  `median <value>`. The y-axis title margin is tighter, and the colour legend
  and the number-at-risk table list the groups in the same order, following the
  group factor's levels.
* A `legend_inside` argument (off by default) draws the legend inside the panel,
  over a semi-transparent background, in a corner the plot usually leaves empty,
  which reclaims the right-hand margin. It is offered by `roc_curve_plot()`,
  `gain_plot()`, `lift_plot()` (bottom-right / top-right of the curve),
  `ecdf_plot()`, `survival_plot()`, `explore_distribution()`, `dumbbell_plot()`
  and `missingness_map()`. For any other plot the same is one `theme()` call,
  and `vignette("exploring-data")` shows how, alongside tidying legend titles.
* `theme_depictr()` now centres legend titles over their keys, which reads more
  tidily than ggplot2's default left alignment, especially for an inside or a
  top/bottom legend.
* `estimation_plot()` reserves more headroom above the lower panel so the
  effect-size annotation (Hedges' *g* / Cohen's *d*) is never clipped.
* `scree_plot()` colour-matches and names its dual axes, 'Variance explained
  (bars)' on the left and 'Cumulative (line)' on the right.
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
* Functions with an optional `seed` (`cluster_plot()`, `qq_plot()` and
  `residual_diagnostics_plot()`) restore the caller's random number generator
  state afterward, so passing one for reproducibility has no side effect on
  your own subsequent random draws.
