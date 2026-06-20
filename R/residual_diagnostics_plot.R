# Regression diagnostics -----------------------------------------------------

#' Residual-diagnostics panel for a fitted model
#'
#' Combines the classic regression diagnostic plots (residuals against fitted
#' values, a normal Q-Q plot of the standardised residuals, a scale-location
#' plot, and residuals against leverage) into a single panel using 'patchwork'.
#' The function works with `lm` and `glm` objects.
#'
#' For a `glm`, the default panels are made GLM-aware (`glm_panels = TRUE`): the
#' "residuals vs. fitted" panel is replaced by a *binned*-residual plot
#' (Gelman & Hill, 2007; see [binned_residual_plot()]), which is readable even
#' for binary or count models, and the Q-Q panel uses *randomized quantile*
#' residuals (Dunn & Smyth, 1996), which are standard normal under a correctly
#' specified model regardless of the response family. The scale-location and
#' leverage panels are unchanged. For an `lm` the behaviour is identical to
#' before. Set `glm_panels = FALSE` to force the classic `lm`-style panels for a
#' `glm` as well.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param which Character vector choosing which panels to show, any of
#'   `"resid_fitted"`, `"qq"`, `"scale_location"` and `"resid_leverage"`.
#' @param ncol Number of columns in the panel layout.
#' @param point_alpha Point transparency.
#' @param smooth Whether to add a loess guide line to the residual panels.
#' @param title Overall title for the panel.
#' @param glm_panels For a `glm`, whether to use the GLM-appropriate binned and
#'   quantile-residual panels (the default) instead of the classic `lm` panels.
#'   Ignored for an `lm`.
#' @param seed Optional integer seed for the randomisation of discrete quantile
#'   residuals, for reproducible `glm` Q-Q panels.
#'
#' @return A 'patchwork' object (printable like a [ggplot2::ggplot]).
#' @references
#' \insertRef{gelman2007}{depictr}
#'
#' \insertRef{dunn1996}{depictr}
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
#' residual_diagnostics_plot(fit)
#' residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
#'
#' # A logistic GLM gets binned and quantile-residual panels automatically:
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' residual_diagnostics_plot(gfit)
residual_diagnostics_plot <- function(model,
                                      which = c("resid_fitted", "qq",
                                                "scale_location",
                                                "resid_leverage"),
                                      ncol = 2, point_alpha = 0.6,
                                      smooth = TRUE, title = NULL,
                                      glm_panels = TRUE, seed = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  which <- match.arg(which, several.ok = TRUE)
  use_glm <- isTRUE(glm_panels) && inherits(model, "glm")

  df <- data.frame(
    fitted = stats::fitted(model),
    resid = stats::residuals(model),
    std_resid = stats::rstandard(model),
    leverage = stats::hatvalues(model)
  )
  df$sqrt_abs <- sqrt(abs(df$std_resid))

  panels <- list()
  if ("resid_fitted" %in% which) {
    panels$resid_fitted <- if (use_glm) {
      binned_residual_plot(model)
    } else {
      diag_scatter(
        df, "fitted", "resid", "Fitted values", "Residuals",
        "Residuals vs. fitted", point_alpha, smooth, hline = 0
      )
    }
  }
  if ("qq" %in% which) {
    panels$qq <- if (use_glm) {
      qr <- quantile_residuals(model, seed = seed)
      qlab <- if (isTRUE(attr(qr, "quantile"))) {
        "Quantile residuals"
      } else {
        "Deviance residuals"
      }
      qvals <- as.numeric(qr)
      qdf <- data.frame(sample = qvals[is.finite(qvals)])
      ggplot2::ggplot(qdf, ggplot2::aes(sample = .data$sample)) +
        ggplot2::stat_qq(alpha = point_alpha, colour = depictr_brand()) +
        ggplot2::stat_qq_line(colour = depictr_reference(), linetype = 2) +
        ggplot2::labs(x = "Theoretical quantiles", y = qlab,
                      title = "Normal Q-Q") +
        theme_depictr()
    } else {
      ggplot2::ggplot(df, ggplot2::aes(sample = .data$std_resid)) +
        ggplot2::stat_qq(alpha = point_alpha, colour = depictr_brand()) +
        ggplot2::stat_qq_line(colour = depictr_reference(), linetype = 2) +
        ggplot2::labs(x = "Theoretical quantiles", y = "Standardised residuals",
                      title = "Normal Q-Q") +
        theme_depictr()
    }
  }
  if ("scale_location" %in% which) {
    panels$scale_location <- diag_scatter(
      df, "fitted", "sqrt_abs", "Fitted values",
      expression(sqrt(group("|", "Std. residuals", "|"))),
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
            colour = depictr_brand(), face = "bold", hjust = 0.5
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
                                 colour = depictr_reference())
  }
  p <- p + ggplot2::geom_point(alpha = alpha, colour = depictr_brand())
  if (smooth) {
    p <- p + ggplot2::geom_smooth(
      method = "loess", formula = y ~ x, se = FALSE,
      colour = depictr_reference(), linewidth = 0.7, na.rm = TRUE
    )
  }
  p + ggplot2::labs(x = x_lab, y = y_lab, title = title) + theme_depictr()
}
