# GLM-appropriate diagnostics: binned and quantile residuals -----------------

#' Binned-residual plot for a generalised linear model
#'
#' For a fitted `glm` (especially binary or count models), a plot of raw
#' residuals against fitted values is hard to read because the residuals take
#' only a few values. Following Gelman and Hill (2007), this plot instead splits
#' the data into equal-count bins of fitted values and plots, for each bin, the
#' mean residual against the mean fitted value. Under a well-specified model the
#' binned residuals scatter around zero, and about 95% of them should fall
#' within the grey \eqn{\pm 2} standard-error band, computed per bin as
#' \eqn{2\,\hat{\sigma}_{\text{bin}}/\sqrt{n_{\text{bin}}}} from the residuals in
#' that bin. Systematic departures (a trend, or many points outside the band)
#' indicate a misspecified mean structure.
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
#'
#' @return A [ggplot2::ggplot] object. The per-bin summary (mean fitted, mean
#'   residual, SE bound and an `outside` flag) is attached as
#'   `attr(plot, "bins")`.
#' @references
#' \insertRef{gelman2007}{depictr}
#' @export
#' @examples
#' gfit <- glm(adverse_event ~ biomarker + age + arm,
#'             data = clinical_trial, family = binomial)
#' binned_residual_plot(gfit)
binned_residual_plot <- function(model, bins = NULL,
                                 type = c("response", "pearson"),
                                 point_colour = depictr_brand(),
                                 band_colour = depictr_accent(),
                                 title = NULL) {
  if (!inherits(model, "lm")) {
    stop("`model` must be an 'lm' or 'glm' object.", call. = FALSE)
  }
  type <- match.arg(type)
  bd <- binned_residual_data(model, bins = bins, type = type)

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
#' returns, per bin, the mean fitted value, the mean residual and the
#' \eqn{2\,\mathrm{sd}/\sqrt{n}} bound (Gelman & Hill, 2007). Used by
#' [binned_residual_plot()] and re-used by [residual_diagnostics_plot()].
#' @param model A fitted `lm`/`glm`.
#' @param bins Number of bins, or `NULL` for the \eqn{\sqrt{n}} default.
#' @param type Residual type, `"response"` or `"pearson"`.
#' @noRd
binned_residual_data <- function(model, bins = NULL,
                                 type = c("response", "pearson")) {
  type <- match.arg(type)
  fitted <- as.numeric(stats::fitted(model))
  resid <- as.numeric(stats::residuals(model, type = type))
  ok <- is.finite(fitted) & is.finite(resid)
  fitted <- fitted[ok]
  resid <- resid[ok]
  n <- length(fitted)
  if (n < 4) {
    stop("Too few observations for a binned-residual plot.", call. = FALSE)
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
    se <- if (nb > 1L) stats::sd(rb) / sqrt(nb) else NA_real_
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
#' Supported families: gaussian, binomial, poisson and Gamma (all relying only
#' on base R distribution functions, so no extra dependency is needed). For
#' other families the function returns deviance residuals (with an attribute
#' `quantile = FALSE`) so that callers can fall back gracefully.
#'
#' @param model A fitted `glm` (or `lm`, treated as Gaussian).
#' @param seed Optional integer seed for the randomisation of discrete
#'   residuals, for reproducibility.
#' @return A numeric vector of residuals, with attribute `quantile` (logical)
#'   indicating whether true quantile residuals were produced.
#' @noRd
quantile_residuals <- function(model, seed = NULL) {
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = .GlobalEnv)) {
      old <- get(".Random.seed", envir = .GlobalEnv)
      on.exit(assign(".Random.seed", old, envir = .GlobalEnv), add = TRUE)
    }
    set.seed(seed)
  }

  fam <- if (inherits(model, "glm")) stats::family(model)$family else "gaussian"
  mu <- stats::fitted(model)
  y <- stats::model.response(stats::model.frame(model))
  # Prior weights (binomial may store proportions with weights = trial counts).
  w <- model$prior.weights
  if (is.null(w)) w <- rep(1, length(mu))

  unsupported <- function() {
    r <- stats::residuals(model, type = "deviance")
    attr(r, "quantile") <- FALSE
    r
  }

  if (fam == "gaussian") {
    sigma <- sqrt(sum(stats::residuals(model)^2) / stats::df.residual(model))
    u <- stats::pnorm(as.numeric(y), mean = mu, sd = sigma)
  } else if (fam == "binomial") {
    # y may be 0/1, logical, factor, or a proportion with trial weights.
    yy <- as.numeric(y)
    if (is.factor(y)) yy <- as.numeric(y) - 1
    counts <- round(yy * w)
    a <- stats::pbinom(counts - 1, size = w, prob = mu)
    b <- stats::pbinom(counts, size = w, prob = mu)
    u <- stats::runif(length(mu), pmin(a, b), pmax(a, b))
  } else if (fam == "poisson") {
    yy <- as.numeric(y)
    a <- stats::ppois(yy - 1, lambda = mu)
    b <- stats::ppois(yy, lambda = mu)
    u <- stats::runif(length(mu), a, b)
  } else if (fam == "Gamma") {
    disp <- summary(model)$dispersion
    shape <- 1 / disp
    u <- stats::pgamma(as.numeric(y), shape = shape, rate = shape / mu)
  } else {
    return(unsupported())
  }

  u <- pmin(pmax(u, .Machine$double.eps), 1 - .Machine$double.eps)
  r <- stats::qnorm(u)
  attr(r, "quantile") <- TRUE
  r
}
