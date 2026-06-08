# Extra diagnostics: influence and Q-Q ---------------------------------------

#' Influence plot
#'
#' A bubble plot of leverage against the studentised residuals, with bubble area
#' proportional to Cook's distance -- the standard one-picture summary of which
#' observations most influence a fitted model. Reference lines mark large
#' residuals and high-leverage points, and the most influential observations are
#' labelled.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param n_label Number of most-influential points (by Cook's distance) to
#'   label.
#' @param colour Bubble colour.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
#' influence_plot(fit)
influence_plot <- function(model, n_label = 3, colour = "#005b96",
                           title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  df <- data.frame(
    leverage = stats::hatvalues(model),
    residual = stats::rstudent(model),
    cook = stats::cooks.distance(model)
  )
  df$label <- rownames(df)
  p <- length(stats::coef(model))
  n <- nrow(df)
  lev_thresh <- 2 * p / n

  top <- df[order(df$cook, decreasing = TRUE), , drop = FALSE]
  top <- utils::head(top, n_label)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$leverage, y = .data$residual)) +
    ggplot2::geom_hline(yintercept = c(-2, 0, 2), linetype = c(3, 2, 3),
                        colour = "grey60") +
    ggplot2::geom_vline(xintercept = lev_thresh, linetype = 3,
                        colour = "grey60") +
    ggplot2::geom_point(ggplot2::aes(size = .data$cook), alpha = 0.5,
                        colour = colour) +
    ggplot2::geom_text(
      data = top,
      ggplot2::aes(label = .data$label),
      vjust = -0.8, size = 3, colour = "#e23b3b"
    ) +
    ggplot2::scale_size_area(name = "Cook's D", max_size = 9) +
    ggplot2::labs(x = "Leverage", y = "Studentised residual", title = title) +
    theme_statviz()
}

#' Normal quantile-quantile plot
#'
#' A normal Q-Q plot for a numeric vector or for the standardised residuals of a
#' fitted model, with a reference line.
#'
#' @param x A numeric vector, or a fitted `lm`/`glm` model (its standardised
#'   residuals are used).
#' @param colour Point colour.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' qq_plot(rnorm(100))
#' fit <- lm(yield ~ rainfall + fertilizer, data = crop_yield)
#' qq_plot(fit)
qq_plot <- function(x, colour = "#005b96", title = NULL,
                    x_lab = "Theoretical quantiles",
                    y_lab = NULL) {
  if (inherits(x, "lm")) {
    vals <- stats::rstandard(x)
    y_lab <- y_lab %||% "Standardised residuals"
  } else {
    if (!is.numeric(x)) stop("`x` must be numeric or a model.", call. = FALSE)
    vals <- as.numeric(x)
    y_lab <- y_lab %||% "Sample quantiles"
  }
  df <- data.frame(sample = vals[is.finite(vals)])
  ggplot2::ggplot(df, ggplot2::aes(sample = .data$sample)) +
    ggplot2::stat_qq(colour = colour, alpha = 0.6) +
    ggplot2::stat_qq_line(colour = "#e23b3b", linetype = 2) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_statviz()
}
