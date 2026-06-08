# modelviz 0.1.0

First release. modelviz unifies and generalises three earlier plotting
functions into a single package for visualising statistical models and data.

## Model-result plots

* `coef_plot()` -- forest / coefficient plot from a fitted model or a tidy
  estimate table.
* `compare_estimates_plot()` -- overlay estimates from several models or
  sources on one plot.
* `frequentist_bayesian_plot()` -- a self-contained successor to the original
  gist; no longer requires a pre-built `brms::mcmc_plot()` object.
* `optimizer_fixef_plot()` -- successor to `plot.fixef.allFit()`, with robust
  faceting in place of the original manual layout.
* `power_curve_plot()` -- successor to `powercurvePlot()`, accepting both
  `simr` objects and tidy data frames.
* `residual_diagnostics_plot()` -- residual-diagnostic panel for `lm`/`glm`.

## Data-exploration plots

* `distribution_plot()`, `scatter_trend_plot()`,
  `correlation_matrix_plot()` and `missingness_plot()`.

## Shared building blocks

* `tidy_estimates()` -- standardise model output into one tidy table.
* `theme_modelviz()`, `modelviz_palette()`, `scale_colour_modelviz()` and
  `format_terms()`.

## Data

* Three reproducibly simulated datasets: `lexical_decision`,
  `wellbeing_survey` and `crop_yield`.
