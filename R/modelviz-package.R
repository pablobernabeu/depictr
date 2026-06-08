#' modelviz: Publication-Ready Visualisation of Statistical Models and Data
#'
#' modelviz turns the output of common statistical analyses into clear,
#' publication-ready graphics, and adds a family of exploratory plots for the
#' data behind those analyses. Every function returns a [ggplot2::ggplot]
#' object, so plots can be further customised with the usual `+` syntax.
#'
#' @section Model-result plots:
#' \itemize{
#'   \item [coef_plot()] -- forest / coefficient plot from a fitted model or a
#'     tidy estimate table.
#'   \item [compare_estimates_plot()] -- overlay estimates from several sources
#'     (e.g. frequentist vs. Bayesian, or several optimisers) in one plot.
#'   \item [frequentist_bayesian_plot()] -- a focused wrapper for the common
#'     case of comparing a frequentist and a Bayesian fit.
#'   \item [optimizer_fixef_plot()] -- fixed effects across the optimisers
#'     returned by [lme4::allFit()].
#'   \item [power_curve_plot()] -- power analysis curve from a 'simr' power
#'     curve or a tidy data frame.
#'   \item [residual_diagnostics_plot()] -- residual-diagnostic panel for `lm`
#'     and `glm` models.
#' }
#'
#' @section Data-exploration plots:
#' \itemize{
#'   \item [distribution_plot()] -- histograms / densities, optionally by group.
#'   \item [correlation_matrix_plot()] -- correlation heatmap.
#'   \item [missingness_plot()] -- map of missing values.
#'   \item [scatter_trend_plot()] -- scatter plot with a fitted trend.
#' }
#'
#' @section Shared building blocks:
#' \itemize{
#'   \item [tidy_estimates()] -- standardise model output into one tidy table.
#'   \item [theme_modelviz()] -- the shared ggplot2 theme.
#'   \item [modelviz_palette()] / [scale_colour_modelviz()] -- the shared palette.
#'   \item [format_terms()] -- tidy raw coefficient names for display.
#' }
#'
#' @section Bundled data:
#' [lexical_decision], [wellbeing_survey] and [crop_yield] are reproducibly
#' simulated datasets used throughout the examples and vignettes.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data
## usethis namespace: end
NULL
