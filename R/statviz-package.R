#' statviz: A Unified Toolkit for Visualising Statistical Models and Data
#'
#' statviz provides a consistent, publication-ready set of plots that span the
#' whole analysis workflow -- from a first look at the data, through model
#' estimates and predictions, to diagnostics, uncertainty and reporting. Every
#' plotting function returns a [ggplot2::ggplot] object (or a 'patchwork' for
#' composite panels), so results can be customised with the usual `+` syntax,
#' and every plot shares one theme, one colourblind-aware palette and one set of
#' label conventions.
#'
#' @section Exploring data:
#' \itemize{
#'   \item [explore_distribution()] -- histograms / densities of one variable.
#'   \item [explore_categorical()] -- bar charts of a categorical variable.
#'   \item [explore_bivariate()] -- the right plot for any pair of variables.
#'   \item [explore_pairs()] -- a scatter-plot matrix.
#'   \item [correlation_heatmap()] -- correlations as a heatmap.
#'   \item [missingness_map()] -- a map of missing values.
#'   \item [outlier_plot()] -- box / violin plots flagging outliers.
#'   \item [raincloud_plot()] -- half-violin, box and raw points together.
#'   \item [group_comparison_plot()] -- group means with confidence intervals.
#'   \item [scatter_trend()] -- scatter plot with a fitted trend.
#'   \item [summary_table()] -- a "Table 1" style descriptive summary.
#' }
#'
#' @section Multivariate and survival:
#' \itemize{
#'   \item [pca_plot()] -- principal-component biplot.
#'   \item [scree_plot()] -- variance explained by each component.
#'   \item [survival_plot()] -- Kaplan-Meier survival curves.
#' }
#'
#' @section Model estimates and inference:
#' \itemize{
#'   \item [tidy_estimates()] -- the shared tidy estimate table.
#'   \item [coefficient_plot()] -- forest / coefficient plot.
#'   \item [compare_models()] -- estimates from several models, side by side.
#'   \item [frequentist_bayesian_plot()] -- frequentist vs. Bayesian estimates.
#'   \item [effects_plot()] -- predicted values for one predictor.
#'   \item [interaction_plot()] -- predicted values across two predictors.
#'   \item [random_effects_plot()] -- caterpillar plot of random effects.
#'   \item [optimizer_fixef_plot()] -- fixed effects across optimisers.
#'   \item [model_fit_table()] -- goodness-of-fit statistics across models.
#' }
#'
#' @section Diagnostics and classification:
#' \itemize{
#'   \item [residual_diagnostics_plot()] -- residual-diagnostic panel.
#'   \item [influence_plot()] -- influence and leverage.
#'   \item [qq_plot()] -- normal quantile-quantile plot.
#'   \item [vif_plot()] -- multicollinearity (variance inflation factors).
#'   \item [roc_curve_plot()] -- ROC curve(s) with AUC.
#'   \item [pr_curve_plot()] -- precision-recall curve with average precision.
#'   \item [calibration_plot()] -- calibration of predicted probabilities.
#'   \item [confusion_matrix_plot()] -- confusion matrix as a heatmap.
#' }
#'
#' @section Uncertainty and power:
#' \itemize{
#'   \item [posterior_plot()] -- posterior intervals and densities.
#'   \item [power_curve_plot()] -- power against sample size.
#' }
#'
#' @section Theming and reporting:
#' \itemize{
#'   \item [theme_statviz()] -- the shared theme.
#'   \item [statviz_palette()], [scale_colour_statviz()] -- the shared palette.
#'   \item [palette_preview()] -- preview the palettes.
#'   \item [format_terms()] -- tidy raw coefficient names for display.
#'   \item [arrange_plots()] -- compose plots with a shared legend and title.
#'   \item [save_plot()] -- save a plot with publication-ready defaults.
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
