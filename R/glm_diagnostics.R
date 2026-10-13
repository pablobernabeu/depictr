# GLM-appropriate diagnostics: binned and quantile residuals -----------------

#' Binned-residual plot for a generalised linear model
#'
#' For a fitted `glm` (especially binary or count models), a plot of raw
#' residuals against fitted values is hard to read because the residuals take
#' only a few values. Following Gelman and Hill (2007), this plot instead splits
#' the data into equal-count bins of fitted values and plots, for each bin, the
#' mean residual against the mean fitted value, inside a grey band of
#' \eqn{\pm 2} standard errors of that mean. Under a well-specified model, the
#' binned residuals scatter around zero, and about 95% of them should fall
#' within the band. Systematic departures (a trend, or many points outside the
#' band) indicate a misspecified mean structure.
#'
#' By default (`band = "model"`), the standard error is the one the fitted
#' model implies. The model gives the response \eqn{y_i} the variance
#' \eqn{\phi V(\hat\mu_i) / w_i}, where \eqn{V} is the family's variance
#' function, \eqn{w_i} the prior weight and \eqn{\phi} the dispersion. The
#' dispersion is 1 for the binomial and Poisson families,
#' `summary(model)$dispersion` for the others and \eqn{\hat\sigma^2} for an
#' `lm`. Taking this as the variance of the response residual
#' \eqn{y_i - \hat\mu_i}, the band gives the mean of the \eqn{n_b} residuals in
#' bin \eqn{b} the standard error
#' \eqn{\sqrt{\sum_{i \in b} \phi V(\hat\mu_i) / w_i} / n_b}. A Pearson
#' residual, \eqn{(y_i - \hat\mu_i) \sqrt{w_i / V(\hat\mu_i)}}, then has
#' variance \eqn{\phi}, so its bin mean has standard error
#' \eqn{\sqrt{\phi / n_b}}. The fit absorbs a little of each observation's
#' variance, so a residual varies slightly less than this and the band errs on
#' the wide side. Observations with zero prior weight take no part in the fit
#' and are left out of the bins.
#'
#' `band = "empirical"` draws the band of depictr 0.3.0 and earlier, the one
#' `arm::binnedplot()` draws: twice the standard deviation of the residuals in
#' the bin, divided by \eqn{\sqrt{n_b}}. It collapses wherever the outcomes in
#' a bin are all alike. The residuals in a logistic model's bin without events
#' all lie just below zero, so its band nearly vanishes and the bin is flagged.
#' Where events are rare, such bins are what the model expects. The example
#' below, a correctly specified model, has five of its seventeen bins flagged
#' by that band and none by the model's.
#'
#' @param model A fitted `glm` object (an `lm` is also accepted and treated as a
#'   Gaussian GLM).
#' @param bins Number of bins. The default follows Gelman and Hill's rule of
#'   thumb of roughly \eqn{\sqrt{n}} bins (bounded to a sensible range).
#' @param type Residual type used for the bin means: `"response"` (observed
#'   minus fitted on the response scale, the Gelman-Hill default) or
#'   `"pearson"`.
#' @param point_colour,band_colour Colours for the bin points and the
#'   \eqn{\pm 2} SE band. Default to the depictr brand and accent colours.
#' @param title Plot title.
#' @param band Where the standard errors come from. The default, `"model"`,
#'   takes them from the variance the fitted model implies for each residual.
#'   `"empirical"` takes them from the spread of the residuals in each bin, as
#'   in depictr 0.3.0 and `arm::binnedplot()`.
#'
#' @return A [ggplot2::ggplot] object. The per-bin summary (mean fitted value,
#'   mean residual, number of observations `n`, the band's half-width `se2`
#'   and an `outside` flag) is attached as `attr(plot, "bins")`.
#' @references
#' \insertRef{gelman2007}{depictr}
#' @export
#' @examples
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' binned_residual_plot(gfit)
#'
#' # The band of depictr 0.3.0, which flags the bins that hold no events:
#' binned_residual_plot(gfit, band = "empirical")
binned_residual_plot <- function(model, bins = NULL,
                                 type = c("response", "pearson"),
                                 point_colour = depictr_brand(),
                                 band_colour = depictr_accent(),
                                 title = NULL,
                                 band = c("model", "empirical")) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  type <- match.arg(type)
  band <- match.arg(band)
  bd <- binned_residual_data(model, bins = bins, type = type, band = band)

  p <- ggplot2::ggplot(bd, ggplot2::aes(x = .data$fitted, y = .data$resid)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2,
                        colour = depictr_reference()) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = -.data$se2, ymax = .data$se2),
      fill = band_colour, alpha = 0.12
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$se2), colour = band_colour,
                       linetype = 3, linewidth = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = -.data$se2), colour = band_colour,
                       linetype = 3, linewidth = 0.5) +
    ggplot2::geom_point(
      ggplot2::aes(colour = .data$outside), size = 2, alpha = 0.85
    ) +
    ggplot2::scale_colour_manual(
      values = c(`FALSE` = point_colour, `TRUE` = band_colour),
      guide = "none"
    ) +
    ggplot2::labs(
      x = "Mean fitted value (binned)", y = "Mean residual",
      title = title %||% "Binned residuals"
    ) +
    theme_depictr()
  attr(p, "bins") <- bd
  p
}

# ---- core computations -----------------------------------------------------

#' Per-bin binned-residual summary
#'
#' Splits the observations into `bins` equal-count groups of fitted values and
#' returns, per bin, the mean fitted value, the mean residual, the number of
#' observations and twice the standard error of the mean residual (Gelman &
#' Hill, 2007). The standard error comes from the fitted model or from the
#' residuals in the bin, as `band` says. Used by [binned_residual_plot()] and
#' re-used by [residual_diagnostics_plot()].
#' @param model A fitted `lm`/`glm`.
#' @param bins Number of bins, or `NULL` for the \eqn{\sqrt{n}} default.
#' @param type Residual type, `"response"` or `"pearson"`.
#' @param band `"model"` for the standard error the model implies, or
#'   `"empirical"` for the standard deviation of the bin's residuals over the
#'   square root of its count.
#' @noRd
binned_residual_data <- function(model, bins = NULL,
                                 type = c("response", "pearson"),
                                 band = c("model", "empirical")) {
  type <- match.arg(type)
  band <- match.arg(band)
  # The model's own components hold one value per row of the fit, as the prior
  # weights do, whereas fitted() and residuals() pad with NA the rows that
  # na.exclude left out.
  mu <- as.numeric(model$fitted.values)
  if (inherits(model, "glm")) {
    # A glm fitted with y = FALSE keeps no response, so it is recovered from
    # the working residuals, as residuals.glm() recovers it.
    y <- model$y %||%
      (mu + model$residuals * model$family$mu.eta(model$linear.predictors))
    w <- model$prior.weights
    v <- model$family$variance(mu)
  } else {
    y <- mu + model$residuals
    w <- model$weights %||% rep(1, length(mu))
    v <- rep(1, length(mu))
  }
  # An observation with zero prior weight takes no part in the fit, and the
  # model gives its residual no finite variance.
  ok <- is.finite(mu) & is.finite(as.numeric(y)) & w > 0
  fitted <- mu[ok]
  w <- w[ok]
  v <- v[ok]
  resid <- as.numeric(y)[ok] - fitted
  if (type == "pearson") resid <- resid * sqrt(w / v)
  n <- length(fitted)
  if (n < 4) {
    stop("Too few observations for a binned-residual plot.", call. = FALSE)
  }
  if (band == "model") {
    # The variance of each residual under the model: phi V(mu_i) / w_i on the
    # response scale, and phi for a Pearson residual. phi is 1 for the
    # binomial and Poisson families.
    phi <- if (inherits(model, "glm")) {
      summary(model)$dispersion
    } else {
      stats::sigma(model)^2
    }
    resid_var <- if (type == "pearson") rep(phi, n) else phi * v / w
  }

  if (is.null(bins)) {
    bins <- floor(sqrt(n))
    bins <- max(2L, min(bins, n %/% 2L))
  } else {
    if (!is.numeric(bins) || length(bins) != 1 || bins < 2) {
      stop("`bins` must be a single number >= 2.", call. = FALSE)
    }
    bins <- as.integer(bins)
  }

  # Equal-count bins by rank of the fitted values.
  rk <- rank(fitted, ties.method = "first")
  grp <- ceiling(rk / (n / bins))
  grp <- pmin(grp, bins)

  split_idx <- split(seq_len(n), grp)
  rows <- lapply(split_idx, function(ix) {
    nb <- length(ix)
    rb <- resid[ix]
    se <- if (band == "model") {
      # The mean of independent residuals: the root of their summed
      # variances over their count.
      sqrt(sum(resid_var[ix])) / nb
    } else if (nb > 1L) {
      stats::sd(rb) / sqrt(nb)
    } else {
      NA_real_
    }
    data.frame(
      fitted = mean(fitted[ix]),
      resid  = mean(rb),
      n      = nb,
      se2    = 2 * se
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$fitted), , drop = FALSE]
  rownames(out) <- NULL
  out$outside <- is.finite(out$se2) & abs(out$resid) > out$se2
  out
}

#' Randomised quantile residuals for a GLM
#'
#' Computes randomised quantile residuals (Dunn & Smyth, 1996): the residual for
#' observation \eqn{i} is \eqn{\Phi^{-1}(u_i)} where, for a continuous response,
#' \eqn{u_i = F(y_i;\hat\theta_i)} is the fitted CDF at the observation, and for
#' a discrete response \eqn{u_i} is drawn uniformly on
#' \eqn{(F(y_i - 1), F(y_i)]}. For a correctly specified model these residuals
#' are i.i.d. standard normal (equivalently, the \eqn{u_i} are uniform on
#' \eqn{(0,1)}), regardless of the response distribution, which makes the normal
#' Q-Q plot interpretable even for binary or count GLMs.
#'
#' Prior weights \eqn{w_i} enter each fitted distribution as they enter the
#' fit, through the variance \eqn{\phi V(\mu_i) / w_i}. The Gaussian standard
#' deviation is therefore \eqn{\sqrt{\phi / w_i}} and the Gamma shape
#' \eqn{w_i / \phi}, and binomial weights are numbers of trials. Poisson
#' residuals do not use the weights. An observation with zero prior weight
#' takes no part in the fit and gets `NA`.
#'
#' Supported families: gaussian, binomial, poisson and Gamma (all relying only
#' on base R distribution functions, so no extra dependency is needed). For
#' other families the function returns deviance residuals (with an attribute
#' `quantile = FALSE`) so that callers can fall back gracefully.
#'
#' @param model A fitted `glm` (or `lm`, treated as Gaussian).
#' @param seed Optional integer seed for the randomisation of discrete
#'   residuals, for reproducibility.
#' @return A numeric vector of residuals as long as [stats::residuals()]
#'   returns, so padded with `NA` at the rows that `na.action = na.exclude`
#'   left out of the fit. Its attribute `quantile` (logical) indicates whether
#'   true quantile residuals were produced.
#' @noRd
quantile_residuals <- function(model, seed = NULL) {
  if (!is.null(seed)) {
    # Leave the caller's random stream as we found it, including the case of a
    # session that has not drawn a random number yet (no state to save, so the
    # restoration is to remove the seed our set.seed() leaves behind).
    if (exists(".Random.seed", envir = .GlobalEnv)) {
      old <- get(".Random.seed", envir = .GlobalEnv)
      on.exit(assign(".Random.seed", old, envir = .GlobalEnv), add = TRUE)
    } else {
      on.exit(suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)),
              add = TRUE)
    }
    set.seed(seed)
  }

  fam <- if (inherits(model, "glm")) stats::family(model)$family else "gaussian"
  # The model's own components hold one value per row of the fit. fitted() and
  # residuals() pad with NA the rows na.exclude left out, while the model frame
  # never holds them, so mixing the two would recycle one against the other.
  mu <- model$fitted.values
  y <- stats::model.response(stats::model.frame(model))
  # Prior weights: a glm always stores them, an lm only when it was weighted.
  w <- model$prior.weights %||% model$weights %||% rep(1, length(mu))

  unsupported <- function() {
    r <- stats::residuals(model, type = "deviance")
    attr(r, "quantile") <- FALSE
    r
  }

  if (fam == "gaussian") {
    # Observation i has variance phi / w_i, where phi is the weighted residual
    # variance: the dispersion of a glm, sigma squared for an lm.
    phi <- if (inherits(model, "glm")) {
      summary(model)$dispersion
    } else {
      stats::sigma(model)^2
    }
    u <- stats::pnorm(as.numeric(y), mean = mu, sd = sqrt(phi / w))
  } else if (fam == "binomial") {
    # y may be 0/1, logical, factor, a proportion with trial weights, or a
    # cbind(successes, failures) matrix. The matrix response carries the counts
    # and trial totals directly; flattening it with as.numeric() would pair
    # each success count with the wrong trial size.
    if (is.matrix(y)) {
      counts <- y[, 1]
      size <- rowSums(y)
    } else {
      yy <- as.numeric(y)
      if (is.factor(y)) yy <- as.numeric(y) - 1
      size <- w
      counts <- round(yy * size)
    }
    a <- stats::pbinom(counts - 1, size = size, prob = mu)
    b <- stats::pbinom(counts, size = size, prob = mu)
    u <- stats::runif(length(mu), pmin(a, b), pmax(a, b))
  } else if (fam == "poisson") {
    yy <- as.numeric(y)
    a <- stats::ppois(yy - 1, lambda = mu)
    b <- stats::ppois(yy, lambda = mu)
    u <- stats::runif(length(mu), a, b)
  } else if (fam == "Gamma") {
    # Shape w_i / phi and mean mu_i, so the variance is phi * mu_i^2 / w_i.
    shape <- w / summary(model)$dispersion
    u <- stats::pgamma(as.numeric(y), shape = shape, rate = shape / mu)
  } else {
    return(unsupported())
  }

  u <- pmin(pmax(u, .Machine$double.eps), 1 - .Machine$double.eps)
  r <- stats::qnorm(u)
  # An observation with zero prior weight takes no part in the fit (nobs()
  # leaves it out too), so there is no fitted distribution to place it in.
  r[w == 0] <- NA_real_
  # Put back, as NA, the rows na.exclude left out, so that every branch returns
  # as many values as residuals() does, the deviance fallback included.
  r <- stats::naresid(model$na.action, r)
  attr(r, "quantile") <- TRUE
  r
}

#' The quantile residuals a Q-Q panel draws, with the axis label naming them
#'
#' Keeps the finite values of `quantile_residuals()`, so it drops the rows the
#' fit left out or gave zero weight. The label is "Deviance residuals" where
#' the family has no quantile residual and the deviance residuals stand in.
#' Shared by [residual_diagnostics_plot()] and [model_report()], so the two
#' panels of one model agree.
#'
#' @param model A fitted `glm`.
#' @param seed Optional integer seed, passed to `quantile_residuals()`.
#' @return A list of the numeric `sample` and its axis `label`.
#' @noRd
glm_qq_sample <- function(model, seed = NULL) {
  qr <- quantile_residuals(model, seed = seed)
  vals <- as.numeric(qr)
  list(
    sample = vals[is.finite(vals)],
    label = if (isTRUE(attr(qr, "quantile"))) {
      "Quantile residuals"
    } else {
      "Deviance residuals"
    }
  )
}
