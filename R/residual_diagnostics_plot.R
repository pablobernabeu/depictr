# Regression diagnostics -----------------------------------------------------

#' Residual-diagnostics panel for a fitted model
#'
#' Combines the classic regression diagnostic plots -- residuals vs. fitted, a
#' normal Q-Q plot of the standardised residuals, a scale-location plot, and
#' residuals vs. leverage -- into a single panel using 'patchwork'. Works with
#' `lm` and `glm` objects.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param which Character vector choosing which panels to show, any of
#'   `"resid_fitted"`, `"qq"`, `"scale_location"` and `"resid_leverage"`.
#' @param ncol Number of columns in the panel layout.
#' @param point_alpha Point transparency.
#' @param smooth Add a loess guide line to the residual panels?
#' @param title Overall title for the panel.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
#' residual_diagnostics_plot(fit)
#' residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
residual_diagnostics_plot <- function(model,
                                      which = c("resid_fitted", "qq",
                                                "scale_location",
                                                "resid_leverage"),
                                      ncol = 2, point_alpha = 0.6,
                                      smooth = TRUE, title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  which <- match.arg(which, several.ok = TRUE)

  df <- data.frame(
    fitted = stats::fitted(model),
    resid = stats::residuals(model),
    std_resid = stats::rstandard(model),
    leverage = stats::hatvalues(model)
  )
  df$sqrt_abs <- sqrt(abs(df$std_resid))

  panels <- list()
  if ("resid_fitted" %in% which) {
    panels$resid_fitted <- diag_scatter(
      df, "fitted", "resid", "Fitted values", "Residuals",
      "Residuals vs. fitted", point_alpha, smooth, hline = 0
    )
  }
  if ("qq" %in% which) {
    panels$qq <- ggplot2::ggplot(df, ggplot2::aes(sample = .data$std_resid)) +
      ggplot2::stat_qq(alpha = point_alpha, colour = "#005b96") +
      ggplot2::stat_qq_line(colour = "#e23b3b", linetype = 2) +
      ggplot2::labs(x = "Theoretical quantiles", y = "Standardised residuals",
                    title = "Normal Q-Q") +
      theme_depictr()
  }
  if ("scale_location" %in% which) {
    panels$scale_location <- diag_scatter(
      df, "fitted", "sqrt_abs", "Fitted values",
      expression(sqrt(abs("Std. residuals"))),
      "Scale-location", point_alpha, smooth
    )
  }
  if ("resid_leverage" %in% which) {
    panels$resid_leverage <- diag_scatter(
      df, "leverage", "std_resid", "Leverage", "Standardised residuals",
      "Residuals vs. leverage", point_alpha, smooth, hline = 0
    )
  }

  combined <- patchwork::wrap_plots(panels, ncol = ncol)
  if (!is.null(title)) {
    combined <- combined +
      patchwork::plot_annotation(
        title = title,
        theme = ggplot2::theme(
          plot.title = ggplot2::element_text(
            colour = "#005b96", face = "bold", hjust = 0.5
          )
        )
      )
  }
  combined
}

# ---- internal helpers ------------------------------------------------------

#' @noRd
diag_scatter <- function(df, x, y, x_lab, y_lab, title, alpha, smooth,
                         hline = NULL) {
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x]], y = .data[[y]]))
  if (!is.null(hline)) {
    p <- p + ggplot2::geom_hline(yintercept = hline, linetype = 2,
                                 colour = "grey60")
  }
  p <- p + ggplot2::geom_point(alpha = alpha, colour = "#005b96")
  if (smooth) {
    p <- p + ggplot2::geom_smooth(
      method = "loess", formula = y ~ x, se = FALSE,
      colour = "#e23b3b", linewidth = 0.7, na.rm = TRUE
    )
  }
  p + ggplot2::labs(x = x_lab, y = y_lab, title = title) + theme_depictr()
}
