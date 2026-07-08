#' depictr: A Unified Toolkit for Visualising Statistical Models and Data
#'
#' depictr provides a consistent set of plots that span the whole analysis
#' workflow, from a first look at the data, through model estimates and
#' predictions, to diagnostics, uncertainty and reporting. Every plotting
#' function returns a [ggplot2::ggplot] object (or a 'patchwork' for composite
#' panels), so results can be customised with the usual `+` syntax, and every
#' plot shares one theme, one colourblind-aware palette and one set of label
#' conventions.
#'
#' @section Exploring data:
#' \itemize{
#'   \item [explore_distribution()]: histograms / densities of one variable.
#'   \item [ecdf_plot()]: empirical cumulative distribution, optionally by group.
#'   \item [explore_categorical()]: bar charts of a categorical variable.
#'   \item [explore_bivariate()]: a suitable plot for any pair of variables.
#'   \item [explore_pairs()]: a scatter-plot matrix.
#'   \item [correlation_heatmap()]: correlations as a heatmap.
#'   \item [missingness_map()]: a map of missing values.
#'   \item [outlier_plot()]: box / violin plots flagging outliers.
#'   \item [raincloud_plot()]: half-violin, box and raw points together.
#'   \item [ridgeline_plot()]: overlapping per-group densities.
#'   \item [group_comparison_plot()]: group means with confidence intervals.
#'   \item [estimation_plot()]: group differences with bootstrap intervals.
#'   \item [dumbbell_plot()]: a two-group comparison across categories.
#'   \item [scatter_trend()]: scatter plot with a fitted trend.
#'   \item [summary_table()]: a "Table 1" style descriptive summary.
#' }
#'
#' @section Multivariate and survival:
#' \itemize{
#'   \item [pca_plot()]: principal-component biplot.
#'   \item [scree_plot()]: variance explained by each component.
#'   \item [cluster_plot()]: k-means clusters on principal-component axes.
#'   \item [silhouette_plot()]: silhouette widths of a clustering.
#'   \item [k_diagnostic()]: suggest a number of clusters.
#'   \item [dendrogram_plot()]: hierarchical-clustering dendrogram.
#'   \item [survival_plot()]: Kaplan-Meier survival curves.
#' }
#'
#' @section Time series:
#' \itemize{
#'   \item [timeseries_plot()]: one or more series over time.
#'   \item [acf_plot()]: autocorrelation / partial autocorrelation.
#'   \item [decompose_plot()]: trend / seasonal / remainder decomposition.
#'   \item [seasonal_plot()]: seasonal subseries across cycles.
#'   \item [ts_forecast()]: a simple forecast with prediction intervals.
#' }
#'
#' @section Model estimates and inference:
#' \itemize{
#'   \item [tidy_estimates()]: the shared tidy estimate table.
#'   \item [coefficient_plot()]: forest / coefficient plot.
#'   \item [compare_models()]: estimates from several models, side by side.
#'   \item [frequentist_bayesian_plot()]: frequentist vs. Bayesian estimates.
#'   \item [effects_plot()]: predicted values for one predictor.
#'   \item [interaction_plot()]: predicted values across two predictors.
#'   \item [random_effects_plot()]: caterpillar plot of random effects.
#'   \item [optimizer_fixef_plot()]: fixed effects across optimisers.
#'   \item [model_fit_table()]: goodness-of-fit statistics across models.
#' }
#'
#' @section Diagnostics and classification:
#' \itemize{
#'   \item [residual_diagnostics_plot()]: residual-diagnostic panel.
#'   \item [binned_residual_plot()]: binned residuals for logistic and other GLMs.
#'   \item [influence_plot()]: influence and leverage.
#'   \item [qq_plot()]: normal quantile-quantile plot.
#'   \item [vif_plot()]: multicollinearity (variance inflation factors).
#'   \item [roc_curve_plot()]: ROC curve(s) with AUC.
#'   \item [pr_curve_plot()]: precision-recall curve with average precision.
#'   \item [gain_plot()]: cumulative gains chart.
#'   \item [lift_plot()]: cumulative lift chart.
#'   \item [calibration_plot()]: calibration of predicted probabilities.
#'   \item [threshold_plot()]: classification metrics across decision thresholds.
#'   \item [confusion_matrix_plot()]: confusion matrix as a heatmap.
#' }
#'
#' @section Uncertainty and power:
#' \itemize{
#'   \item [posterior_plot()]: posterior intervals and densities.
#'   \item [power_curve_plot()]: power against sample size.
#' }
#'
#' @section Theming and reporting:
#' \itemize{
#'   \item [theme_depictr()]: the shared theme.
#'   \item [depictr_palette()], [scale_colour_depictr()]: the shared palette.
#'   \item [palette_preview()]: preview the palettes.
#'   \item [format_terms()]: tidy raw coefficient names for display.
#'   \item [model_report()]: a one-figure overview of a fitted model.
#'   \item [arrange_plots()]: compose plots with a shared legend and title.
#'   \item [save_plot()]: save a plot with publication-ready defaults.
#'   \item [depictr_options()]: set package-wide defaults once.
#' }
#'
#' @section Bundled data:
#' [lexical_decision], [wellbeing_survey], [crop_yield], [clinical_trial] and
#' [monthly_sales] are reproducibly simulated datasets used throughout the
#' examples and vignettes.
#'
#' @references
#' \insertRef{wickham2016}{depictr}
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data
#' @importFrom Rdpack reprompt
## usethis namespace: end
NULL

# ggplot2 computed-stat variables referenced inside after_stat().
utils::globalVariables(c("density", "count"))
