# depictr 0.4.0

## Upgrading from the previous release (0.3.0)

### Changed results

* Confidence intervals for a `glm` whose dispersion is estimated (Gaussian,
  Gamma, inverse Gaussian and quasi families) use the t distribution, as
  `summary.glm()` does, where they used z and were too narrow. They widen
  wherever depictr reports or draws them.
* `coefficient_plot(standardise = TRUE)`, and so `model_report()`, scales
  continuous inputs by their standard deviation and an interaction through its
  continuous inputs, leaving factor, logical and two-valued inputs unscaled
  (Gelman, 2008), where it scaled every model-matrix column, so a contrast
  depended on group balance.
* `coefficient_plot(standardise = TRUE)` leaves `poly()`, `ns()` and other
  matrix terms unscaled, with a message, and warns about an interaction of
  continuous inputs that are not all centred. The axis and panel titles say
  which inputs were scaled.
* `coefficient_plot()` reads an unnamed `labels` vector in model order,
  whatever `order` is, where it matched the vector to the terms as reversed or
  sorted for display, so a vector written for 0.3.0 can put labels on other
  terms. Named labels are unaffected.
* `model_fit_table()` and the `model_report()` subtitle give every `glm` the
  deviance R², where they applied McFadden's ratio to every family and could
  refit the null model on other rows. Binary logistic values change only where
  that refit went wrong.
* `model_fit_table()` takes the AIC, BIC and log-likelihood of an
  `lme4::lmer()` REML fit from a maximum-likelihood refit, with a message,
  where it reported REML criteria, which cannot be compared between models with
  different fixed effects.
* `vif_plot()` computes VIFs from the coefficients' covariance, as `car::vif()`
  does, where it ignored the fit's weights. Values change for a weighted `lm`,
  a binomial or Poisson `glm` and any other `glm` that weights its observations
  unequally. A model without an intercept changes too, with a warning.
* `tidy_estimates()` exponentiates the estimates and limits of an `lm`, a
  `glm`, an lme4 fit and a data frame when given `exponentiate = TRUE`, where
  it ignored the argument for these and returned the link scale.
* `effects_plot()`, `interaction_plot()` and `model_report()` build the
  prediction grid from the raw variables, so `predict()` re-applies every
  transformation, where a transformed term beside its raw variable gave a flat
  effect line or coincident interaction lines.
* `calibration_plot()` and the Q-Q panel of `residual_diagnostics_plot()` pair
  each outcome of a `glm` fitted with `na.action = na.exclude` with its own
  fitted value, where they paired it with another row's.
* `residual_diagnostics_plot()` and `influence_plot()` leave out the rows that
  `na.action = na.exclude` excludes, for an `lm` as for a `glm`, without the
  warning they gave, and the 2p/n leverage line of `influence_plot()` no longer
  counts them.
* The Q-Q panel of `residual_diagnostics_plot()` scales the quantile residuals
  of a weighted Gaussian or Gamma model by its prior weights, which it ignored,
  and leaves out observations with zero prior weight.
* `binned_residual_plot()` and the binned panel of `residual_diagnostics_plot()`
  draw the band from the fitted model, where the empirical band was too narrow
  in bins without events, and leave out observations with zero prior weight.
  `binned_residual_plot(band = "empirical")`, though not the panel, restores
  the old band.
* `model_report()` draws binned-residual and quantile-residual panels for a
  `glm`, as `residual_diagnostics_plot()` does, where it drew normal-theory
  panels that flag a correct logistic model. `glm_panels = FALSE` restores the
  old panels, and `seed` fixes the randomised residuals.
* `frequentist_bayesian_plot()` and `posterior_plot()` keep only the `b_`
  parameters of a `posterior` draws object that has them, as one made from a
  brms fit does, with a message, where `frequentist_bayesian_plot()` drew the
  group-level effects as parameters and pooled `b_Intercept` with `Intercept`.
* `frequentist_bayesian_plot()` and `posterior_plot()` leave out the
  group-level effects of a `stanreg` fit and the log densities `lp__` and
  `lprior` of any draws, which they drew as parameters.
* `frequentist_bayesian_plot()` with draws plots only the terms both inputs
  share, with a message naming those it drops, where `sigma` and terms without
  a posterior took rows of their own, and sets the outer posterior interval by
  `conf_level`, where it stayed at 95%.
* `frequentist_bayesian_plot()` reads a `brms::fixef()` matrix as a summary,
  where it drew the matrix's four columns as parameters.
* `survival_plot()` draws log-log confidence limits by default (Borgan &
  Liestøl, 1990), where it drew untransformed Greenwood limits. Unless `time`
  is a `survfit` object, `conf_type = "plain"` restores them, apart from the
  last step of a curve that falls to zero. `conf_type = "log"` gives the
  default of `survival::survfit()`.
* `survival_plot()` recomputes a `survfit` object's limits at `conf_level` and
  `conf_type`, where it copied the object's own and ignored `conf_level`.
  `conf_type = "log"` restores the limits of an object made with the defaults
  of `survfit()`.
* `survival_plot()` draws limits for a `survfit` object made with
  `conf.type = "none"`, where it drew none. `conf_level = NA` leaves them out.
  An object without standard errors, or with Peto or modified lower limits,
  keeps its own and warns when they differ from those asked for.
* `survival_plot()` reads the `status` coding once over all observations, where
  it read each group separately and so drew a group whose subjects are all
  censored under the 1/2 coding falling to zero. That group's curve now stays
  at one.
* `survival_plot()` honours `group` and `status`, as a column name or a vector,
  when `time` is a data frame, where it read them only from conventionally
  named columns and could pool the groups.
* The number-at-risk table of `survival_plot()` counts a subject followed up to
  exactly a break and keeps a last break equal to the longest follow-up, both
  of which a floating-point error in the default breaks left out.
* The median guides of `survival_plot()` follow `survival::quantile.survfit()`,
  where a rounding error could label the wrong time, a `survfit` curve flat at
  0.5 could take its midpoint from a censoring time and a curve that ends at
  0.5 got no guide.
* Unless `time` is a `survfit` object, the confidence band of `survival_plot()`
  reaches the last event of a curve that falls to zero, where it stopped one
  event early.
* `k_diagnostic()` and `cluster_plot()` default to `k_range = NULL`, which
  searches `1:8` for the gap and elbow criteria. The old `2:8` let the gap
  statistic find clusters in pure noise and kept the elbow from suggesting two.
  `k_range = 2:8` restores it.
* `silhouette_plot()` keeps the cluster labels it is given in its bands and in
  its `"silhouette"` table, whose `cluster` and `neighbor` columns are factors
  of them, where it recoded them to 1, 2, 3 and so on and gave `neighbor` as
  integer codes.
* `ts_forecast()` and the forecast overlay of `timeseries_plot()` forecast the
  seasonally adjusted series with a random walk with drift, as
  `forecast::stlf(method = "rwdrift", s.window = "periodic")` does, where they
  extrapolated the last cycle's trend with intervals far too narrow. The
  overlay caption names the method.
* `timeseries_plot()` continues a forecast along the history's own axis,
  numeric or `Date`, where it restarted near the start of the axis, and sorts
  an unsorted `time` before forecasting.
* `timeseries_plot()` centres the moving average of an even `rolling` window,
  as a 2×12 average for `rolling = 12` (Hyndman & Athanasopoulos, 2021), where
  the average was drawn half an observation early. Odd windows are unchanged.
* `timeseries_plot()` draws one line per column of a multivariate `ts` or a
  matrix, where it joined the columns into one series.
* `summary_table()` summarises a date or date-time column as one `Range` row
  and a duration as mean (SD) in a unit that the statistic names, where it gave
  one row per distinct value.
* `palette_safety()` and `check_figure()` measure colour separability with
  CIEDE2000 (Sharma, Wu & Dalal, 2005), where the 1976 distance overstated the
  differences between saturated colours, so distances and some verdicts change.
  `metric = "cie76"` restores the old measure.
* `simulate_cvd()` at partial severity interpolates between the published
  matrices of Machado et al. (2009), where it drew the full-severity matrix
  towards the identity, so its colours between severities 0 and 1 change. Full
  severity is unchanged.
* `check_figure()` measures each text against its own background, holds large
  text to 3:1 and measures a translucent plot or panel background as the colour
  it shows, where it measured all text against the plot background at 4.5:1.
* `check_figure()` composites translucent colours over their background with
  the alpha each geom applies, where it measured them as opaque, and compares
  colours and fill colours each among themselves, where it pooled them, so
  verdicts can change in either direction.
* `check_figure()` counts a colour or fill split across layers, one value per
  layer, as a colour encoding, where it reported none, and counts shape and
  line type split that way towards `redundant_encoding`.
* `check_figure()` adds a tenth row, `annotation_text_size`, which holds the
  text inside the panel, such as annotations, `geom_text()` labels and the cell
  values of depictr's plots, to the size floor, so a figure that passed can
  fail.

### Changed interface

* depictr requires ggplot2 3.5.2 or later, where it declared 3.5.0, with which
  the current patchwork cannot load, and suggests lme4 1.1-19 or later.
* `coefficient_plot()`, `timeseries_plot()` and `decompose_plot()` take new
  arguments before `title`, `palette` and `confidence` respectively, so those
  arguments and the ones after them must be passed by name.
* `tidy_estimates()`, `save_plot()`, `frequentist_bayesian_plot()`,
  `scale_colour_depictr()` and `scale_fill_depictr()` take a new argument
  before `...`, so an argument meant for `...` must be passed by name.
* A `conf_level` outside (0, 1), such as 95, is refused by every function that
  takes one, where a level of 0 or 1 gave the model estimates zero-width or
  unbounded intervals, 95 gave missing intervals or an error and
  `roc_curve_plot()` without `ci` ignored the level. Without `ci`,
  `roc_curve_plot()` also refuses `NULL`, which it ignored.
* Every function that takes a `conf_level`, except `survival_plot()` and
  `calibration_plot()`, refuses `NA`, where most gave missing intervals. Those
  two still take it to leave the limits out, and both refuse `NaN`, which they
  read as `NA`.
* `compare_models()` and `frequentist_bayesian_plot()` read an unnamed
  `labels` vector as one label per term, in the order the terms first appear,
  where they took one label per row of the stacked estimates or per posterior
  draw, and refuse a vector of the old length.
* For a `posterior` draws object that holds `b_` parameters,
  `frequentist_bayesian_plot()` and `posterior_plot()` take `labels` keys
  without the prefix, so a key such as `b_rainfall` written for 0.3.0 no longer
  matches.
* `survival_plot()` refuses a factor, character or non-integer `status`, which
  it read by its level codes, as missing or truncated to an integer.
* `survival_plot()` refuses a `status` coded 0/1 in some groups and 1/2 in
  others, which it read group by group.
* `survival_plot()` refuses a `group` or `status` name that matches no column
  of a data frame `time`, which it ignored.
* `effects_plot()`, `interaction_plot()` and `model_report()` refuse a formula
  term computed from statistics of its rows, such as `I(x - mean(x))`, which
  shifted the line, a formula that reads columns with `$` and a transformed
  term whose data the call cannot supply.
* `frequentist_bayesian_plot()` with draws refuses inputs that share no terms
  and two terms of either input that would share a label, and
  `posterior_plot()` refuses a `brms::fixef()` matrix and two parameters that
  would share a label.
* `explore_distribution()`, `ecdf_plot()`, `raincloud_plot()`,
  `group_comparison_plot()`, `explore_categorical()`, `explore_pairs()`,
  `ridgeline_plot()` and `outlier_plot()` refuse a numeric `group` with more
  than 20 distinct values, which they drew, and `scatter_trend()` refuses one
  when called, where it returned a plot that failed when drawn.
* `scatter_trend()`, `explore_distribution()`, `ecdf_plot()`,
  `raincloud_plot()`, `explore_categorical()` and `outlier_plot()` refuse a
  `group` missing for every row when called, where they drew it or returned a
  plot that failed when drawn.
* `power_curve_plot()` refuses rows of one curve that share a sample size,
  where it joined them into a zigzag line.
* `acf_plot()`, `decompose_plot()`, `seasonal_plot()` and `ts_forecast()`
  refuse a series of more than one column, and `timeseries_plot()` refuses a
  `forecast` for one, where they joined the columns into one series.
* `timeseries_plot()` refuses an even `rolling` window as long as the shortest
  series, since the centred average spans one observation more than the
  window.
* `pca_plot()` refuses a misspelt `group` column, a `group` vector of the wrong
  length and a column name passed with a `prcomp` object, which it read as one
  level or padded with `NA`.

### Changed output

* `coefficient_plot()`, `compare_models()`, `frequentist_bayesian_plot()`,
  `optimizer_fixef_plot()` and the coefficient panel of `model_report()` label
  a two-level factor or logical input with its level, as in
  `treatment: enhanced`, where they showed `treatment`. Except in
  `model_report()`, `labels = c(treatmentenhanced = "treatment")` restores an
  old label.
* In an interaction row, the same functions name the variable and level of
  every factor, as in `rainfall × treatment: enhanced`, where they showed
  `rainfall × treatmentenhanced`. Except in `model_report()`, a `labels` entry
  for the raw term restores it.
* `compare_models()` labels the factor levels of every model, as in
  `region: South`, where it labelled only those of the first model holding a
  factor and showed the rest as `regionSouth`. A `labels` entry for the raw term
  restores them.
* `compare_models(x_lab = NULL)`, and `frequentist_bayesian_plot(x_lab = NULL)`
  with summaries, draw the default axis title, 'Estimate' or the ratio's name,
  where they drew none. Adding `ggplot2::labs(x = NULL)` removes it.
* The `model_report()` subtitle of a `glm` calls its R² 'deviance R²', where it
  said 'pseudo-R²'.
* `estimation_plot()` and `group_comparison_plot(differences = TRUE)` give
  every group a column in the difference panel, the reference's first and
  empty, so each difference sits in its own group's column, where the
  difference panel had one column fewer than the groups and spread across the
  full width.
* The caption of `estimation_plot()` and
  `group_comparison_plot(differences = TRUE)` writes a round number of
  resamples in full, as 100,000, where it printed 1e+05.
* `group_comparison_plot(differences = TRUE)` keeps each group's colour
  whatever the `reference`, where the colours moved between groups, and
  `estimation_plot()` matches a named `palette` to the levels by name.
* `frequentist_bayesian_plot()` draws the frequentist estimates in brand blue
  and the Bayesian ones in orange on both paths, where the draws path swapped
  them, and adds a caption naming each source's interval level.
  `caption = NA` omits it.
* `save_plot()` writes PDF, EPS and PostScript files with the cairo devices,
  which embed the fonts, and a TIFF LZW-compressed on white unless `bg` is
  given, where the files failed journals' checks. `device = "pdf"`, `"eps"`,
  `"ps"` or `"tiff"` restores ggplot2's devices.
* `save_plot()` rasterises the translucent layers of an EPS or PostScript file
  at 600 dpi or more, with a message, where it left them out.
* Without cairo, as on a Mac without XQuartz, `save_plot()` writes a PDF, EPS
  or PostScript file with a message or warning saying what the file lacks, and
  a Mac with neither XQuartz nor ragg writes the TIFF uncompressed, with a
  warning.
* `seasonal_plot(style = "season")` draws its cycle lines from a ramp that
  starts at `#4a8fc0`, at 3.51:1 against white, where the earliest cycles were
  close to invisible.
  `palette = depictr_palette(n, type = "sequential")`, with `n` the number of
  cycles, restores the old ramp.
* `palette_preview()`, `confusion_matrix_plot()` and `correlation_heatmap()`
  draw each label in black or white, whichever contrasts more with its tile,
  where some labels fell below the 4.5:1 that WCAG asks of text.
* `pca_plot()` fixes the aspect ratio, so a figure of another shape gains blank
  space, and draws its loading arrows and labels in dark grey, where they took
  the accent, the palette's fourth colour.
* Without `group`, `power_curve_plot()` draws one curve per level of an
  `effect`, `param` or `term` column, with a message, where it joined them into
  one line.
* `power_curve_plot()` draws a confidence band from `<power>_lo` and
  `<power>_hi` columns, such as the `power_lo` and `power_hi` of a pilotr sweep
  over sample size, where it drew none, and reads them before `lower` and
  `upper`.
* `scatter_trend()`, `explore_distribution()`, `ecdf_plot()`,
  `raincloud_plot()`, `group_comparison_plot()`, `explore_categorical()`,
  `explore_pairs()`, `ridgeline_plot()` and `outlier_plot()` drop rows with a
  missing group, with a message, and give no colour to a level without rows, so
  the colours of the levels after it can shift.
* `ridgeline_plot()` keeps each ridge's colour when an earlier group is too
  sparse to draw, where the later ridges shifted colour.
  `group_comparison_plot()` and `raincloud_plot()` leave a level without rows
  off the axis, where they kept an empty place for it with a warning.
* `explore_distribution()` and `ecdf_plot()` draw a numeric group code, such as
  blocks numbered 1 and 2, as groups, where they drew one ungrouped curve.
* `explore_categorical()` orders its groups by level, where it sorted them
  alphabetically.
* With the default palette, `scatter_trend()`, `explore_distribution()`,
  `ecdf_plot()`, `raincloud_plot()`, `group_comparison_plot()`,
  `explore_categorical()`, `ridgeline_plot()` and `outlier_plot()` warn once
  past eight groups, when the plot is made, where they warned each time the
  plot was drawn.
* The caption of a grouped `timeseries_plot()` names the average of an even
  `rolling` window as, for example, '2×12 centred moving average', where it
  said '12-point'.
* `timeseries_plot()` keeps the level order of a factor `group`, where it
  ordered the groups by first appearance, and leaves out unused levels, so the
  legend order and colours can change.
* `decompose_plot(method = "classical")` leaves out missing values at either
  end of a series, so its panels start at the first observation and end at the
  last, where they spanned the missing stretch.
* `explore_bivariate()` treats dates, date-times and durations as numeric,
  where it took them for categories, so they give a scatter plot with a trend
  or box plots by level.
* `threshold_plot()` draws its metrics as steps that change at each score,
  where it joined adjacent scores with straight lines.
* `dumbbell_plot(sort = "none")` keeps a factor's level order, or else the
  order in which the categories first appear, where it sorted them
  alphabetically.
* `survival_plot()` drops an arm whose every `status` is missing, also when
  `group` is a factor, where it kept it in the legend with no curve and made
  `logrank = TRUE` fail.
* The `text_contrast` row of `check_figure()` reports the text furthest short
  of its own threshold, with that threshold and the text's printed size and
  weight, and a translucent colour is named with its alpha.
* The colour rows of `check_figure()` say when colour is a continuous scale,
  which they do not audit, where they said that nothing was distinguished by
  colour.
* The separability rows of `check_figure()` say whether their closest pair are
  colours or fill colours, and its `text_size` and `text_contrast` rows no
  longer say that a figure draws no text when all of its text is inside the
  panel.
* On ggplot2 3.5.x, `pca_plot()` and `silhouette_plot()` draw their labels
  without a border or a warning about `linewidth`, as on later versions.
* `citation("depictr")` gives the DOI that CRAN registered,
  <https://doi.org/10.32614/CRAN.package.depictr>, where it gave the Zenodo
  concept DOI, <https://doi.org/10.5281/zenodo.21266308>.

## New features

* `simulate_figure()` shows a finished ggplot or patchwork, legend and
  colourbar included, as a reader with a colour-vision deficiency sees it, and
  returns a gtable to draw or save.
* `depictr_palette(order = "contrast")`, also in `scale_colour_depictr()` and
  `scale_fill_depictr()`, reorders the palette so that up to three groups pass
  every colour check of `check_figure()` and four keep 3:1 against white.
  `depictr_options(palette = )` can make it the default.
* `exponentiate = TRUE` in `coefficient_plot()` and `compare_models()` gives
  odds, rate or risk ratios, which the plots draw on a log axis with the
  reference line at 1 and an axis title naming the ratio.
* `check_figure()` audits a patchwork composite, the package's own included,
  panel by panel, with a leading `panel` column, where it refused one.
* `check_figure(max_text_pt = )` checks a ceiling on text size in a
  `text_size_max` row, and `save_plot(check = TRUE)` audits a figure at the
  width it is saved at, gives one warning that names each failed check and
  attaches the report as `attr(, "check")`.
* `power_curve_plot(solved = )` marks a solved sample size, such as the result
  of pilotr's `target_n()`, with a dashed line and its interval as a grey band.
* `power_curve_plot()` reads the output of pilotr's `power_curve_mixed()` as it
  is, with its `n_subject` column and its band, and gains `n`, `power`,
  `group`, `lower`, `upper` and `y_lab` after its existing arguments. Several
  curves are told apart by colour and line type.
* `coefficient_plot(standardise = TRUE, sd_multiple = 2)` scales continuous
  inputs by two standard deviations, Gelman's (2008) convention.
* `ts_forecast()` and `timeseries_plot()` gain `lambda`, for a Box-Cox or log
  transformation, and `decompose_plot()` gains `s_window`, the STL seasonal
  window.

## Minor improvements

* `posterior_plot()` and `frequentist_bayesian_plot()` format each parameter's
  label once, and `format_terms()` is much faster on long vectors, so a draws
  object with many draws no longer takes minutes to plot.
* `pca_plot()` takes an unquoted `group` column name and refuses a `prcomp` fit
  that holds no scores, with a message that says so.
* `vif_plot()` refuses a model with aliased coefficients and names their terms,
  where it failed with an unrelated base-R error.
* `correlation_heatmap()` refuses a column in `cols` that it cannot correlate,
  such as a factor or a date, and names it, where it failed with an error that
  did not.
* `explore_pairs()` refuses a numeric `group` named in `cols` with a message
  that says so, where it failed with an error from `cor()`.
* `decompose_plot()` and `ts_forecast()` refuse a missing value inside the
  series with a message that names `x`, and a series of exactly two cycles gets
  the package's own message.

## Fixes

* `estimation_plot()` and `group_comparison_plot(differences = TRUE)` work in a
  fresh R session, where they failed unless patchwork had been loaded.
* `effects_plot()`, `interaction_plot()` and `model_report()` work with a
  transformed term, such as `log()`, `poly()` or `ns()`, and with an offset,
  held at its mean on the link scale, where they failed. A name such as
  `"log(rainfall)"` stands for the variable it transforms.
* `random_effects_plot()` draws models with several uncorrelated or split
  random-effect terms per grouping factor, such as `(1 + x || g)`, fitted with
  `lmer()` or `glmer()`, where it failed.
* A `glm` fitted with `na.action = na.exclude` works in the ROC,
  precision-recall, threshold, gain and lift plots and in
  `confusion_matrix_plot()`, which failed.
* `posterior_plot()` reads a `posterior` draws object made from a brms fit, on
  which it failed with an error about duplicated factor levels.
* `posterior_plot()` accepts an unnamed `labels` vector with one label per
  parameter, which it refused.
* `frequentist_bayesian_plot()` with summaries no longer warns about `labels`
  keys it was not given.
* `ts_forecast()`, the forecast overlay of `timeseries_plot()` and
  `decompose_plot()` with its default STL method read a one-column `ts` and
  trim missing values at either end of a series, where the STL decomposition
  failed. A forecast starts after the last observation.
* `seasonal_plot()` accepts a frequency that is not a whole number, such as
  365.25 / 7, and rounds it down to whole seasons with a message, where it
  refused every such frequency.
* `scatter_trend()` accepts a numeric group code, which failed with a
  discrete-scale error.
* `explore_pairs()` leaves a numeric `group` out of its default columns, where
  it failed with an error from `cor()`.
* On ggplot2 3.5.x, the reference lines of `coefficient_plot()`,
  `frequentist_bayesian_plot()` and `posterior_plot()` no longer warn about an
  unknown `inherit.aes`.

## Deprecated

* `metric = "cie76"` in `palette_safety()` and `check_figure()`, kept to
  reproduce colour distances computed before this release. The default,
  `"ciede2000"`, replaces it, and a later release will remove it.

## Documentation

* The README and the help pages of `depictr_palette()`, `depictr_options()`
  and `palette_safety()` no longer call the built-in palette the Okabe-Ito set.
  The help page of `depictr_palette()` says that it keeps six of that set's
  eight colours, with the brand blue and a grey in place of its blue and black.
* The README points to the Python README's list of the differences between the
  twins, where it said that they differ in a few places.
* Help pages that described behaviour the code does not have now match it.
  `explore_pairs()` refuses columns beyond `max_cols`, `posterior_plot()`
  refuses an unknown `style` and `depictr_palette(n = NULL)` gives seven
  colours for a ramp. `depictr_options()` and `theme_depictr()` no longer
  present `depictr_brand()`, `depictr_accent()` and `depictr_reference()` as
  functions to call, since the package does not export them.
  `cluster_plot(seed = NULL)` draws from the session's random-number stream,
  `coefficient_plot()` applies `interaction` to the terms a named `labels`
  vector leaves out and `survival_plot()` tests a `survfit` object with the
  base-R log-rank test. `missingness_map()` takes its missing-cell colour from
  the accent, `k_diagnostic()` takes the elbow farthest from the chord,
  `dumbbell_plot()` puts the shortest dumbbell at the top only when every
  difference is negative and `estimation_plot()` no longer says that zero lines
  up with the reference group's mean.
* `vignette("exploring-data")` says that `summary_table()` takes its column
  names as strings and that an argument naming several columns, such as `cols`,
  takes a character vector, where it said that column names could be given
  quoted or unquoted. It also says that, of the model-estimate plots, only
  `coefficient_plot()` takes `standardise` and that every plotting function
  returns a ggplot, where it said that all of them took `standardise` and that
  every function returned a ggplot. `vignette("model-estimates")` and the help
  page of `coefficient_plot()` no longer claim that standardised magnitudes are
  comparable. The help page of `threshold_plot()` and
  `vignette("diagnostics-and-uncertainty")` say that the maximum-F1 threshold is
  drawn dotted and the Youden threshold dashed, where they said both were
  dashed. `vignette("multivariate-and-survival")` says that only an arm whose
  curve reaches 0.5 gets a median guide, and `vignette("time-series")` says that
  STL holds the seasonal component fixed under the default
  `s_window = "periodic"`, where it said that STL lets it change from year to
  year.
* The help page of `check_figure()` gains a section on auditing a figure at the
  width it is printed at, with the text floors of four publishers, where it
  called 6 pt a common publisher floor, and says that four colours of the
  default palette fall below 3:1 against white. The help page of `save_plot()`
  describes the formats that three publishers accept.
* `vignette("depictr")` shows a figure drawn by `simulate_figure()` and covers
  four publishers' text floors, Nature's ceiling, the contrast-first palette
  order and how the audit treats a continuous colour scale.

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
  only the first panel came out sorted and the rest zigzagged. Each facet now
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
  state afterwards, so passing one for reproducibility has no side effect on
  your own subsequent random draws.
