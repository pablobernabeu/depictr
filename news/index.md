# Changelog

## depictr (development version)

### Upgrading from the previous release (0.3.0)

#### Changed results

- Confidence intervals for a `glm` whose dispersion is estimated
  (Gaussian, Gamma, inverse Gaussian and quasi families) use the t
  distribution, as
  [`summary.glm()`](https://rdrr.io/r/stats/summary.glm.html) does,
  where they used z and were too narrow. They widen wherever depictr
  reports or draws them.
- `coefficient_plot(standardise = TRUE)`, and so
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md),
  scales continuous inputs by their standard deviation and an
  interaction through its continuous inputs, leaving factor, logical and
  two-valued inputs unscaled (Gelman, 2008), where it scaled every
  model-matrix column, so a contrast depended on group balance.
- `coefficient_plot(standardise = TRUE)` leaves
  [`poly()`](https://rdrr.io/r/stats/poly.html), `ns()` and other matrix
  terms unscaled, with a message, and warns about an interaction of
  continuous inputs that are not all centred. The axis and panel titles
  say which inputs were scaled.
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  reads an unnamed `labels` vector in model order, whatever `order` is,
  where it matched the vector to the terms as reversed or sorted for
  display, so a vector written for 0.3.0 can put labels on other terms.
  Named labels are unaffected.
- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md)
  and the
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  subtitle give every `glm` the deviance R², where they applied
  McFadden’s ratio to every family and could refit the null model on
  other rows. Binary logistic values change only where that refit went
  wrong.
- [`model_fit_table()`](https://pablobernabeu.github.io/depictr/reference/model_fit_table.md)
  takes the AIC, BIC and log-likelihood of an
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) REML fit from
  a maximum-likelihood refit, with a message, where it reported REML
  criteria, which cannot be compared between models with different fixed
  effects.
- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  computes VIFs from the coefficients’ covariance, as
  [`car::vif()`](https://rdrr.io/pkg/car/man/vif.html) does, where it
  ignored the fit’s weights. Values change for a weighted `lm`, a
  binomial or Poisson `glm` and any other `glm` that weights its
  observations unequally. A model without an intercept changes too, with
  a warning.
- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md)
  exponentiates the estimates and limits of an `lm`, a `glm`, an lme4
  fit and a data frame when given `exponentiate = TRUE`, where it
  ignored the argument for these and returned the link scale.
- [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md),
  [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md)
  and
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  build the prediction grid from the raw variables, so
  [`predict()`](https://rdrr.io/r/stats/predict.html) re-applies every
  transformation, where a transformed term beside its raw variable gave
  a flat effect line or coincident interaction lines.
- [`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md)
  and the Q-Q panel of
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  pair each outcome of a `glm` fitted with `na.action = na.exclude` with
  its own fitted value, where they paired it with another row’s.
- [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  and
  [`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md)
  leave out the rows that `na.action = na.exclude` excludes, for an `lm`
  as for a `glm`, without the warning they gave, and the 2p/n leverage
  line of
  [`influence_plot()`](https://pablobernabeu.github.io/depictr/reference/influence_plot.md)
  no longer counts them.
- The Q-Q panel of
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  scales the quantile residuals of a weighted Gaussian or Gamma model by
  its prior weights, which it ignored, and leaves out observations with
  zero prior weight.
- [`binned_residual_plot()`](https://pablobernabeu.github.io/depictr/reference/binned_residual_plot.md)
  and the binned panel of
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  draw the band from the fitted model, where the empirical band was too
  narrow in bins without events, and leave out observations with zero
  prior weight. `binned_residual_plot(band = "empirical")`, though not
  the panel, restores the old band.
- [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  draws binned-residual and quantile-residual panels for a `glm`, as
  [`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
  does, where it drew normal-theory panels that flag a correct logistic
  model. `glm_panels = FALSE` restores the old panels, and `seed` fixes
  the randomised residuals.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  keep only the `b_` parameters of a `posterior` draws object that has
  them, as one made from a brms fit does, with a message, where
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  drew the group-level effects as parameters and pooled `b_Intercept`
  with `Intercept`.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  leave out the group-level effects of a `stanreg` fit and the log
  densities `lp__` and `lprior` of any draws, which they drew as
  parameters.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  with draws plots only the terms both inputs share, with a message
  naming those it drops, where `sigma` and terms without a posterior
  took rows of their own, and sets the outer posterior interval by
  `conf_level`, where it stayed at 95%.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  reads a `brms::fixef()` matrix as a summary, where it drew the
  matrix’s four columns as parameters.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  draws log-log confidence limits by default (Borgan & Liestøl, 1990),
  where it drew untransformed Greenwood limits. Unless `time` is a
  `survfit` object, `conf_type = "plain"` restores them, apart from the
  last step of a curve that falls to zero. `conf_type = "log"` gives the
  default of
  [`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html).
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  recomputes a `survfit` object’s limits at `conf_level` and
  `conf_type`, where it copied the object’s own and ignored
  `conf_level`. `conf_type = "log"` restores the limits of an object
  made with the defaults of `survfit()`.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  draws limits for a `survfit` object made with `conf.type = "none"`,
  where it drew none. `conf_level = NA` leaves them out. An object
  without standard errors, or with Peto or modified lower limits, keeps
  its own and warns when they differ from those asked for.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  reads the `status` coding once over all observations, where it read
  each group separately and so drew a group whose subjects are all
  censored under the 1/2 coding falling to zero. That group’s curve now
  stays at one.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  honours `group` and `status`, as a column name or a vector, when
  `time` is a data frame, where it read them only from conventionally
  named columns and could pool the groups.
- The number-at-risk table of
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  counts a subject followed up to exactly a break and keeps a last break
  equal to the longest follow-up, both of which a floating-point error
  in the default breaks left out.
- The median guides of
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  follow
  [`survival::quantile.survfit()`](https://rdrr.io/pkg/survival/man/quantile.survfit.html),
  where a rounding error could label the wrong time, a `survfit` curve
  flat at 0.5 could take its midpoint from a censoring time and a curve
  that ends at 0.5 got no guide.
- Unless `time` is a `survfit` object, the confidence band of
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  reaches the last event of a curve that falls to zero, where it stopped
  one event early.
- [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  and
  [`cluster_plot()`](https://pablobernabeu.github.io/depictr/reference/cluster_plot.md)
  default to `k_range = NULL`, which searches `1:8` for the gap and
  elbow criteria. The old `2:8` let the gap statistic find clusters in
  pure noise and kept the elbow from suggesting two. `k_range = 2:8`
  restores it.
- [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  keeps the cluster labels it is given in its bands and in its
  `"silhouette"` table, whose `cluster` and `neighbor` columns are
  factors of them, where it recoded them to 1, 2, 3 and so on and gave
  `neighbor` as integer codes.
- [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)
  and the forecast overlay of
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  forecast the seasonally adjusted series with a random walk with drift,
  as `forecast::stlf(method = "rwdrift", s.window = "periodic")` does,
  where they extrapolated the last cycle’s trend with intervals far too
  narrow. The overlay caption names the method.
- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  continues a forecast along the history’s own axis, numeric or `Date`,
  where it restarted near the start of the axis, and sorts an unsorted
  `time` before forecasting.
- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  centres the moving average of an even `rolling` window, as a 2×12
  average for `rolling = 12` (Hyndman & Athanasopoulos, 2021), where the
  average was drawn half an observation early. Odd windows are
  unchanged.
- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  draws one line per column of a multivariate `ts` or a matrix, where it
  joined the columns into one series.
- [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md)
  summarises a date or date-time column as one `Range` row and a
  duration as mean (SD) in a unit that the statistic names, where it
  gave one row per distinct value.
- [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
  and
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  measure colour separability with CIEDE2000 (Sharma, Wu & Dalal, 2005),
  where the 1976 distance overstated the differences between saturated
  colours, so distances and some verdicts change. `metric = "cie76"`
  restores the old measure.
- [`simulate_cvd()`](https://pablobernabeu.github.io/depictr/reference/simulate_cvd.md)
  at partial severity interpolates between the published matrices of
  Machado et al. (2009), where it drew the full-severity matrix towards
  the identity, so its colours between severities 0 and 1 change. Full
  severity is unchanged.
- [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  measures each text against its own background, holds large text to 3:1
  and measures a translucent plot or panel background as the colour it
  shows, where it measured all text against the plot background at
  4.5:1.
- [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  composites translucent colours over their background with the alpha
  each geom applies, where it measured them as opaque, and compares
  colours and fill colours each among themselves, where it pooled them,
  so verdicts can change in either direction.
- [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  counts a colour or fill split across layers, one value per layer, as a
  colour encoding, where it reported none, and counts shape and line
  type split that way towards `redundant_encoding`.
- [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  adds a tenth row, `annotation_text_size`, which holds the text inside
  the panel, such as annotations,
  [`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
  labels and the cell values of depictr’s plots, to the size floor, so a
  figure that passed can fail.

#### Changed interface

- depictr requires ggplot2 3.5.2 or later, where it declared 3.5.0, with
  which the current patchwork cannot load, and suggests lme4 1.1-19 or
  later.
- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  and
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  take new arguments before `title`, `palette` and `confidence`
  respectively, so those arguments and the ones after them must be
  passed by name.
- [`tidy_estimates()`](https://pablobernabeu.github.io/depictr/reference/tidy_estimates.md),
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md),
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md),
  [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  and
  [`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  take a new argument before `...`, so an argument meant for `...` must
  be passed by name.
- A `conf_level` outside (0, 1), such as 95, is refused by every
  function that takes one, where a level of 0 or 1 gave the model
  estimates zero-width or unbounded intervals, 95 gave missing intervals
  or an error and
  [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md)
  without `ci` ignored the level. Without `ci`,
  [`roc_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/roc_curve_plot.md)
  also refuses `NULL`, which it ignored.
- Every function that takes a `conf_level`, except
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  and
  [`calibration_plot()`](https://pablobernabeu.github.io/depictr/reference/calibration_plot.md),
  refuses `NA`, where most gave missing intervals. Those two still take
  it to leave the limits out, and both refuse `NaN`, which they read as
  `NA`.
- [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  and
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  read an unnamed `labels` vector as one label per term, in the order
  the terms first appear, where they took one label per row of the
  stacked estimates or per posterior draw, and refuse a vector of the
  old length.
- For a `posterior` draws object that holds `b_` parameters,
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  take `labels` keys without the prefix, so a key such as `b_rainfall`
  written for 0.3.0 no longer matches.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  refuses a factor, character or non-integer `status`, which it read by
  its level codes, as missing or truncated to an integer.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  refuses a `status` coded 0/1 in some groups and 1/2 in others, which
  it read group by group.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  refuses a `group` or `status` name that matches no column of a data
  frame `time`, which it ignored.
- [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md),
  [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md)
  and
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  refuse a formula term computed from statistics of its rows, such as
  `I(x - mean(x))`, which shifted the line, a formula that reads columns
  with `$` and a transformed term whose data the call cannot supply.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  with draws refuses inputs that share no terms and two terms of either
  input that would share a label, and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  refuses a `brms::fixef()` matrix and two parameters that would share a
  label.
- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md),
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
  [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md),
  [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md),
  [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md),
  [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  and
  [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
  refuse a numeric `group` with more than 20 distinct values, which they
  drew, and
  [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md)
  refuses one when called, where it returned a plot that failed when
  drawn.
- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md),
  [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md),
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
  [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md)
  and
  [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
  refuse a `group` missing for every row when called, where they drew it
  or returned a plot that failed when drawn.
- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  refuses rows of one curve that share a sample size, where it joined
  them into a zigzag line.
- [`acf_plot()`](https://pablobernabeu.github.io/depictr/reference/acf_plot.md),
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md),
  [`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md)
  and
  [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)
  refuse a series of more than one column, and
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  refuses a `forecast` for one, where they joined the columns into one
  series.
- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  refuses an even `rolling` window as long as the shortest series, since
  the centred average spans one observation more than the window.
- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  refuses a misspelt `group` column, a `group` vector of the wrong
  length and a column name passed with a `prcomp` object, which it read
  as one level or padded with `NA`.

#### Changed output

- [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md),
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md),
  [`optimizer_fixef_plot()`](https://pablobernabeu.github.io/depictr/reference/optimizer_fixef_plot.md)
  and the coefficient panel of
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  label a two-level factor or logical input with its level, as in
  `treatment: enhanced`, where they showed `treatment`. Except in
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md),
  `labels = c(treatmentenhanced = "treatment")` restores an old label.
- In an interaction row, the same functions name the variable and level
  of every factor, as in `rainfall × treatment: enhanced`, where they
  showed `rainfall × treatmentenhanced`. Except in
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md),
  a `labels` entry for the raw term restores it.
- [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  labels the factor levels of every model, as in `region: South`, where
  it labelled only those of the first model holding a factor and showed
  the rest as `regionSouth`. A `labels` entry for the raw term restores
  them.
- `compare_models(x_lab = NULL)`, and
  `frequentist_bayesian_plot(x_lab = NULL)` with summaries, draw the
  default axis title, ‘Estimate’ or the ratio’s name, where they drew
  none. Adding `ggplot2::labs(x = NULL)` removes it.
- The
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  subtitle of a `glm` calls its R² ‘deviance R²’, where it said
  ‘pseudo-R²’.
- [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  and `group_comparison_plot(differences = TRUE)` give every group a
  column in the difference panel, the reference’s first and empty, so
  each difference sits in its own group’s column, where the difference
  panel had one column fewer than the groups and spread across the full
  width.
- The caption of
  [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  and `group_comparison_plot(differences = TRUE)` writes a round number
  of resamples in full, as 100,000, where it printed 1e+05.
- `group_comparison_plot(differences = TRUE)` keeps each group’s colour
  whatever the `reference`, where the colours moved between groups, and
  [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  matches a named `palette` to the levels by name.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  draws the frequentist estimates in brand blue and the Bayesian ones in
  orange on both paths, where the draws path swapped them, and adds a
  caption naming each source’s interval level. `caption = NA` omits it.
- [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  writes PDF, EPS and PostScript files with the cairo devices, which
  embed the fonts, and a TIFF LZW-compressed on white unless `bg` is
  given, where the files failed journals’ checks. `device = "pdf"`,
  `"eps"`, `"ps"` or `"tiff"` restores ggplot2’s devices.
- [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  rasterises the translucent layers of an EPS or PostScript file at 600
  dpi or more, with a message, where it left them out.
- Without cairo, as on a Mac without XQuartz,
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  writes a PDF, EPS or PostScript file with a message or warning saying
  what the file lacks, and a Mac with neither XQuartz nor ragg writes
  the TIFF uncompressed, with a warning.
- `seasonal_plot(style = "season")` draws its cycle lines from a ramp
  that starts at `#4a8fc0`, at 3.51:1 against white, where the earliest
  cycles were close to invisible.
  `palette = depictr_palette(n, type = "sequential")`, with `n` the
  number of cycles, restores the old ramp.
- [`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md),
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md)
  and
  [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
  draw each label in black or white, whichever contrasts more with its
  tile, where some labels fell below the 4.5:1 that WCAG asks of text.
- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  fixes the aspect ratio, so a figure of another shape gains blank
  space, and draws its loading arrows and labels in dark grey, where
  they took the accent, the palette’s fourth colour.
- Without `group`,
  [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  draws one curve per level of an `effect`, `param` or `term` column,
  with a message, where it joined them into one line.
- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  draws a confidence band from `<power>_lo` and `<power>_hi` columns,
  such as the `power_lo` and `power_hi` of a pilotr sweep over sample
  size, where it drew none, and reads them before `lower` and `upper`.
- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md),
  [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md),
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
  [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md),
  [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md),
  [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md),
  [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  and
  [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
  drop rows with a missing group, with a message, and give no colour to
  a level without rows, so the colours of the levels after it can shift.
- [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  keeps each ridge’s colour when an earlier group is too sparse to draw,
  where the later ridges shifted colour.
  [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md)
  and
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
  leave a level without rows off the axis, where they kept an empty
  place for it with a warning.
- [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md)
  and
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md)
  draw a numeric group code, such as blocks numbered 1 and 2, as groups,
  where they drew one ungrouped curve.
- [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md)
  orders its groups by level, where it sorted them alphabetically.
- With the default palette,
  [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md),
  [`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md),
  [`ecdf_plot()`](https://pablobernabeu.github.io/depictr/reference/ecdf_plot.md),
  [`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md),
  [`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md),
  [`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md),
  [`ridgeline_plot()`](https://pablobernabeu.github.io/depictr/reference/ridgeline_plot.md)
  and
  [`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
  warn once past eight groups, when the plot is made, where they warned
  each time the plot was drawn.
- The caption of a grouped
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  names the average of an even `rolling` window as, for example, ‘2×12
  centred moving average’, where it said ‘12-point’.
- [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  keeps the level order of a factor `group`, where it ordered the groups
  by first appearance, and leaves out unused levels, so the legend order
  and colours can change.
- `decompose_plot(method = "classical")` leaves out missing values at
  either end of a series, so its panels start at the first observation
  and end at the last, where they spanned the missing stretch.
- [`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md)
  treats dates, date-times and durations as numeric, where it took them
  for categories, so they give a scatter plot with a trend or box plots
  by level.
- [`threshold_plot()`](https://pablobernabeu.github.io/depictr/reference/threshold_plot.md)
  draws its metrics as steps that change at each score, where it joined
  adjacent scores with straight lines.
- `dumbbell_plot(sort = "none")` keeps a factor’s level order, or else
  the order in which the categories first appear, where it sorted them
  alphabetically.
- [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  drops an arm whose every `status` is missing, also when `group` is a
  factor, where it kept it in the legend with no curve and made
  `logrank = TRUE` fail.
- The `text_contrast` row of
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  reports the text furthest short of its own threshold, with that
  threshold and the text’s printed size and weight, and a translucent
  colour is named with its alpha.
- The colour rows of
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  say when colour is a continuous scale, which they do not audit, where
  they said that nothing was distinguished by colour.
- The separability rows of
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  say whether their closest pair are colours or fill colours, and its
  `text_size` and `text_contrast` rows no longer say that a figure draws
  no text when all of its text is inside the panel.
- On ggplot2 3.5.x,
  [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  and
  [`silhouette_plot()`](https://pablobernabeu.github.io/depictr/reference/silhouette_plot.md)
  draw their labels without a border or a warning about `linewidth`, as
  on later versions.
- `citation("depictr")` gives the DOI that CRAN registered,
  <https://doi.org/10.32614/CRAN.package.depictr>, where it gave the
  Zenodo concept DOI, <https://doi.org/10.5281/zenodo.21266308>.

### New features

- [`simulate_figure()`](https://pablobernabeu.github.io/depictr/reference/simulate_figure.md)
  shows a finished ggplot or patchwork, legend and colourbar included,
  as a reader with a colour-vision deficiency sees it, and returns a
  gtable to draw or save.
- `depictr_palette(order = "contrast")`, also in
  [`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
  and
  [`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md),
  reorders the palette so that up to three groups pass every colour
  check of
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  and four keep 3:1 against white. `depictr_options(palette = )` can
  make it the default.
- `exponentiate = TRUE` in
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  and
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  gives odds, rate or risk ratios, which the plots draw on a log axis
  with the reference line at 1 and an axis title naming the ratio.
- [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  audits a patchwork composite, the package’s own included, panel by
  panel, with a leading `panel` column, where it refused one.
- `check_figure(max_text_pt = )` checks a ceiling on text size in a
  `text_size_max` row, and `save_plot(check = TRUE)` audits a figure at
  the width it is saved at, gives one warning that names each failed
  check and attaches the report as `attr(, "check")`.
- `power_curve_plot(solved = )` marks a solved sample size, such as the
  result of pilotr’s `target_n()`, with a dashed line and its interval
  as a grey band.
- [`power_curve_plot()`](https://pablobernabeu.github.io/depictr/reference/power_curve_plot.md)
  reads the output of pilotr’s `power_curve_mixed()` as it is, with its
  `n_subject` column and its band, and gains `n`, `power`, `group`,
  `lower`, `upper` and `y_lab` after its existing arguments. Several
  curves are told apart by colour and line type.
- `coefficient_plot(standardise = TRUE, sd_multiple = 2)` scales
  continuous inputs by two standard deviations, Gelman’s (2008)
  convention.
- [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)
  and
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  gain `lambda`, for a Box-Cox or log transformation, and
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  gains `s_window`, the STL seasonal window.

### Minor improvements

- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  and
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  format each parameter’s label once, and
  [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md)
  is much faster on long vectors, so a draws object with many draws no
  longer takes minutes to plot.
- [`pca_plot()`](https://pablobernabeu.github.io/depictr/reference/pca_plot.md)
  takes an unquoted `group` column name and refuses a `prcomp` fit that
  holds no scores, with a message that says so.
- [`vif_plot()`](https://pablobernabeu.github.io/depictr/reference/vif_plot.md)
  refuses a model with aliased coefficients and names their terms, where
  it failed with an unrelated base-R error.
- [`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
  refuses a column in `cols` that it cannot correlate, such as a factor
  or a date, and names it, where it failed with an error that did not.
- [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
  refuses a numeric `group` named in `cols` with a message that says so,
  where it failed with an error from
  [`cor()`](https://rdrr.io/r/stats/cor.html).
- [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  and
  [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md)
  refuse a missing value inside the series with a message that names
  `x`, and a series of exactly two cycles gets the package’s own
  message.

### Fixes

- [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  and `group_comparison_plot(differences = TRUE)` work in a fresh R
  session, where they failed unless patchwork had been loaded.
- [`effects_plot()`](https://pablobernabeu.github.io/depictr/reference/effects_plot.md),
  [`interaction_plot()`](https://pablobernabeu.github.io/depictr/reference/interaction_plot.md)
  and
  [`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
  work with a transformed term, such as
  [`log()`](https://rdrr.io/r/base/Log.html),
  [`poly()`](https://rdrr.io/r/stats/poly.html) or `ns()`, and with an
  offset, held at its mean on the link scale, where they failed. A name
  such as `"log(rainfall)"` stands for the variable it transforms.
- [`random_effects_plot()`](https://pablobernabeu.github.io/depictr/reference/random_effects_plot.md)
  draws models with several uncorrelated or split random-effect terms
  per grouping factor, such as `(1 + x || g)`, fitted with `lmer()` or
  `glmer()`, where it failed.
- A `glm` fitted with `na.action = na.exclude` works in the ROC,
  precision-recall, threshold, gain and lift plots and in
  [`confusion_matrix_plot()`](https://pablobernabeu.github.io/depictr/reference/confusion_matrix_plot.md),
  which failed.
- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  reads a `posterior` draws object made from a brms fit, on which it
  failed with an error about duplicated factor levels.
- [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  accepts an unnamed `labels` vector with one label per parameter, which
  it refused.
- [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  with summaries no longer warns about `labels` keys it was not given.
- [`ts_forecast()`](https://pablobernabeu.github.io/depictr/reference/ts_forecast.md),
  the forecast overlay of
  [`timeseries_plot()`](https://pablobernabeu.github.io/depictr/reference/timeseries_plot.md)
  and
  [`decompose_plot()`](https://pablobernabeu.github.io/depictr/reference/decompose_plot.md)
  with its default STL method read a one-column `ts` and trim missing
  values at either end of a series, where the STL decomposition failed.
  A forecast starts after the last observation.
- [`seasonal_plot()`](https://pablobernabeu.github.io/depictr/reference/seasonal_plot.md)
  accepts a frequency that is not a whole number, such as 365.25 / 7,
  and rounds it down to whole seasons with a message, where it refused
  every such frequency.
- [`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md)
  accepts a numeric group code, which failed with a discrete-scale
  error.
- [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
  leaves a numeric `group` out of its default columns, where it failed
  with an error from [`cor()`](https://rdrr.io/r/stats/cor.html).
- On ggplot2 3.5.x, the reference lines of
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md),
  [`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
  and
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  no longer warn about an unknown `inherit.aes`.

### Deprecated

- `metric = "cie76"` in
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
  and
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md),
  kept to reproduce colour distances computed before this release. The
  default, `"ciede2000"`, replaces it, and a later release will remove
  it.

### Documentation

- The README and the help pages of
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md),
  [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
  and
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
  no longer call the built-in palette the Okabe-Ito set. The help page
  of
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  says that it keeps six of that set’s eight colours, with the brand
  blue and a grey in place of its blue and black.
- The README points to the Python README’s list of the differences
  between the twins, where it said that they differ in a few places.
- Help pages that described behaviour the code does not have now match
  it.
  [`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
  refuses columns beyond `max_cols`,
  [`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md)
  refuses an unknown `style` and `depictr_palette(n = NULL)` gives seven
  colours for a ramp.
  [`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md)
  and
  [`theme_depictr()`](https://pablobernabeu.github.io/depictr/reference/theme_depictr.md)
  no longer present `depictr_brand()`, `depictr_accent()` and
  `depictr_reference()` as functions to call, since the package does not
  export them. `cluster_plot(seed = NULL)` draws from the session’s
  random-number stream,
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  applies `interaction` to the terms a named `labels` vector leaves out
  and
  [`survival_plot()`](https://pablobernabeu.github.io/depictr/reference/survival_plot.md)
  tests a `survfit` object with the base-R log-rank test.
  [`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md)
  takes its missing-cell colour from the accent,
  [`k_diagnostic()`](https://pablobernabeu.github.io/depictr/reference/k_diagnostic.md)
  takes the elbow farthest from the chord,
  [`dumbbell_plot()`](https://pablobernabeu.github.io/depictr/reference/dumbbell_plot.md)
  puts the shortest dumbbell at the top only when every difference is
  negative and
  [`estimation_plot()`](https://pablobernabeu.github.io/depictr/reference/estimation_plot.md)
  no longer says that zero lines up with the reference group’s mean.
- [`vignette("exploring-data")`](https://pablobernabeu.github.io/depictr/articles/exploring-data.md)
  says that
  [`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md)
  takes its column names as strings and that an argument naming several
  columns, such as `cols`, takes a character vector, where it said that
  column names could be given quoted or unquoted. It also says that, of
  the model-estimate plots, only
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  takes `standardise` and that every plotting function returns a ggplot,
  where it said that all of them took `standardise` and that every
  function returned a ggplot.
  [`vignette("model-estimates")`](https://pablobernabeu.github.io/depictr/articles/model-estimates.md)
  and the help page of
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)
  no longer claim that standardised magnitudes are comparable. The help
  page of
  [`threshold_plot()`](https://pablobernabeu.github.io/depictr/reference/threshold_plot.md)
  and
  [`vignette("diagnostics-and-uncertainty")`](https://pablobernabeu.github.io/depictr/articles/diagnostics-and-uncertainty.md)
  say that the maximum-F1 threshold is drawn dotted and the Youden
  threshold dashed, where they said both were dashed.
  [`vignette("multivariate-and-survival")`](https://pablobernabeu.github.io/depictr/articles/multivariate-and-survival.md)
  says that only an arm whose curve reaches 0.5 gets a median guide, and
  [`vignette("time-series")`](https://pablobernabeu.github.io/depictr/articles/time-series.md)
  says that STL holds the seasonal component fixed under the default
  `s_window = "periodic"`, where it said that STL lets it change from
  year to year.
- The help page of
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  gains a section on auditing a figure at the width it is printed at,
  with the text floors of four publishers, where it called 6 pt a common
  publisher floor, and says that four colours of the default palette
  fall below 3:1 against white. The help page of
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  describes the formats that three publishers accept.
- [`vignette("depictr")`](https://pablobernabeu.github.io/depictr/articles/depictr.md)
  shows a figure drawn by
  [`simulate_figure()`](https://pablobernabeu.github.io/depictr/reference/simulate_figure.md)
  and covers four publishers’ text floors, Nature’s ceiling, the
  contrast-first palette order and how the audit treats a continuous
  colour scale.

## depictr 0.3.0

CRAN release: 2026-09-01

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
  zigzagged. Each facet now orders its own levels, with the plain level
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
  restore the caller’s random number generator state afterwards, so
  passing one for reproducibility has no side effect on your own
  subsequent random draws.
