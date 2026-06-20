# Extra diagnostics: influence and Q-Q ---------------------------------------

#' Influence plot
#'
#' A bubble plot of leverage against the studentised residuals, with bubble area
#' proportional to Cook's distance. It summarises in a single picture which
#' observations most influence a fitted model. Reference lines mark large
#' residuals and high-leverage points, and the most influential observations are
#' labelled.
#'
#' @param model A fitted `lm` or `glm` model.
#' @param n_label Number of most-influential points (by Cook's distance) to
#'   label.
#' @param colour Bubble colour. Defaults to the depictr brand blue.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @references
#' \insertRef{cook1977}{depictr}
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
#' influence_plot(fit)
influence_plot <- function(model, n_label = 3, colour = depictr_brand(),
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
                        colour = depictr_reference()) +
    ggplot2::geom_vline(xintercept = lev_thresh, linetype = 3,
                        colour = depictr_reference()) +
    ggplot2::geom_point(ggplot2::aes(size = .data$cook), alpha = 0.5,
                        colour = colour) +
    ggplot2::geom_text(
      data = top,
      ggplot2::aes(label = .data$label),
      vjust = -0.8, size = 3, colour = depictr_accent()
    ) +
    ggplot2::scale_size_area(name = "Cook's D", max_size = 9) +
    ggplot2::labs(x = "Leverage", y = "Studentised residual", title = title) +
    theme_depictr()
}

#' Normal quantile-quantile plot
#'
#' A normal Q-Q plot for a numeric vector or for the standardised residuals of a
#' fitted model, with a reference line and an optional confidence band that makes
#' departures from normality easier to judge. Points that stray outside the band
#' are unusual under normality; under a normal sample roughly `level` of the
#' points fall inside a pointwise band.
#'
#' Two band constructions are offered. `"pointwise"` is analytic: it uses the
#' large-sample standard error of the \eqn{i}-th order statistic,
#' \eqn{\mathrm{se} = \frac{\hat\sigma}{\phi(z_i)}\sqrt{p_i(1-p_i)/n}}, around
#' the fitted reference line. `"simulate"` builds a Monte-Carlo envelope by
#' repeatedly drawing normal samples of the same size and taking the empirical
#' quantiles of the simulated order statistics, which needs no large-sample
#' approximation.
#'
#' @param x A numeric vector, or a fitted `lm`/`glm` model (its standardised
#'   residuals are used).
#' @param colour Point colour. Defaults to the depictr brand blue.
#' @param title,x_lab,y_lab Title and axis labels.
#' @param band Whether to draw a confidence band/envelope.
#' @param band_type Band construction: `"pointwise"` (analytic order-statistic
#'   standard errors, the default) or `"simulate"` (a Monte-Carlo envelope).
#' @param level Confidence level for the band.
#' @param n_sim Number of simulations for `band_type = "simulate"`.
#' @param band_fill Fill colour of the band.
#' @param seed Optional integer seed for the simulated envelope, for
#'   reproducibility.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' qq_plot(rnorm(100))
#' qq_plot(rt(100, df = 3), band_type = "simulate")
#' fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
#' qq_plot(fit)
qq_plot <- function(x, colour = depictr_brand(), title = NULL,
                    x_lab = "Theoretical quantiles",
                    y_lab = NULL, band = TRUE,
                    band_type = c("pointwise", "simulate"),
                    level = 0.95, n_sim = 1000,
                    band_fill = depictr_reference(), seed = NULL) {
  band_type <- match.arg(band_type)
  if (inherits(x, "lm")) {
    vals <- stats::rstandard(x)
    y_lab <- y_lab %||% "Standardised residuals"
  } else {
    if (!is.numeric(x)) stop("`x` must be numeric or a model.", call. = FALSE)
    vals <- as.numeric(x)
    y_lab <- y_lab %||% "Sample quantiles"
  }
  vals <- vals[is.finite(vals)]
  df <- data.frame(sample = vals)

  p <- ggplot2::ggplot(df, ggplot2::aes(sample = .data$sample))
  if (isTRUE(band) && length(vals) >= 3) {
    bd <- qq_band(vals, type = band_type, level = level, n_sim = n_sim,
                  seed = seed)
    p <- p + ggplot2::geom_ribbon(
      data = bd,
      ggplot2::aes(x = .data$theoretical, ymin = .data$lower,
                   ymax = .data$upper),
      inherit.aes = FALSE, fill = band_fill, alpha = 0.18
    )
  }
  p +
    ggplot2::stat_qq(colour = colour, alpha = 0.6) +
    ggplot2::stat_qq_line(colour = depictr_reference(), linetype = 2) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()
}

#' Confidence band for a normal Q-Q plot
#'
#' Returns a data frame of `theoretical` quantiles with `lower`/`upper` band
#' limits, used by [qq_plot()]. The reference line is fitted robustly through the
#' first and third theoretical/sample quartiles (matching
#' [ggplot2::stat_qq_line()]).
#' @param vals Numeric sample (finite values only).
#' @param type `"pointwise"` (analytic) or `"simulate"` (Monte-Carlo).
#' @param level Confidence level.
#' @param n_sim Number of simulations for the Monte-Carlo envelope.
#' @param seed Optional RNG seed.
#' @noRd
qq_band <- function(vals, type = c("pointwise", "simulate"),
                    level = 0.95, n_sim = 1000, seed = NULL) {
  type <- match.arg(type)
  n <- length(vals)
  probs <- stats::ppoints(n)
  z <- stats::qnorm(probs)
  sorted <- sort(vals)

  # Robust reference line through the quartiles (as stat_qq_line does).
  qx <- stats::qnorm(c(0.25, 0.75))
  qy <- stats::quantile(vals, c(0.25, 0.75), type = 7, names = FALSE)
  slope <- diff(qy) / diff(qx)
  intercept <- qy[1L] - slope * qx[1L]
  centre <- intercept + slope * z

  alpha <- 1 - level
  if (type == "pointwise") {
    # Large-sample SE of the order statistics around the reference line.
    dens <- stats::dnorm(z)
    se <- (slope / dens) * sqrt(probs * (1 - probs) / n)
    crit <- stats::qnorm(1 - alpha / 2)
    lower <- centre - crit * se
    upper <- centre + crit * se
  } else {
    if (!is.null(seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv)) {
        old <- get(".Random.seed", envir = .GlobalEnv)
        on.exit(assign(".Random.seed", old, envir = .GlobalEnv), add = TRUE)
      }
      set.seed(seed)
    }
    # Monte-Carlo envelope of the order statistics of a standard normal sample,
    # rescaled by the same robust reference line.
    sims <- matrix(stats::rnorm(n * n_sim), nrow = n, ncol = n_sim)
    sims <- apply(sims, 2, sort)
    qlo <- apply(sims, 1, stats::quantile, probs = alpha / 2, names = FALSE)
    qhi <- apply(sims, 1, stats::quantile, probs = 1 - alpha / 2, names = FALSE)
    lower <- intercept + slope * qlo
    upper <- intercept + slope * qhi
  }
  data.frame(theoretical = z, lower = lower, upper = upper, sample = sorted)
}
