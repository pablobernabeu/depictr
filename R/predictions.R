# Predicted values from a model ----------------------------------------------

#' Plot predicted values for one predictor
#'
#' Shows the values a model predicts as one focal predictor varies, holding the
#' other predictors at typical values (the mean for numeric predictors, the most
#' frequent level for factors). A confidence band (numeric predictor) or
#' confidence intervals (factor predictor) convey uncertainty.
#'
#' Predictions and standard errors come from [stats::predict()]; `glm`
#' predictions are formed on the link scale and back-transformed, so a binomial
#' model shows predicted probabilities. Mixed models fitted with
#' [lme4::lmer()]/[lme4::glmer()] are supported too: predictions use only the
#' fixed effects (`re.form = NA`) and standard errors come from the fixed-effect
#' design matrix and `vcov()`. Works with `lm`, `glm` and `merMod`; other model
#' classes are attempted on a best-effort basis.
#'
#' @param model A fitted model (`lm`, `glm`, `merMod`, ...).
#' @param predictor Name of the focal predictor (string).
#' @param conf_level Confidence level for the interval.
#' @param n Number of points across the range of a numeric predictor.
#' @param rug Whether to add a rug of the observed predictor values (numeric predictors).
#' @param colour Colour for the line/points and band. Defaults to the depictr
#'   brand blue.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertilizer + treatment, data = crop_yield)
#' effects_plot(fit, "fertilizer")
#' effects_plot(fit, "treatment")
#'
#' gfit <- glm(accuracy ~ word_frequency + condition,
#'             data = lexical_decision, family = binomial)
#' effects_plot(gfit, "word_frequency")        # predicted probability
effects_plot <- function(model, predictor, conf_level = 0.95, n = 100,
                         rug = TRUE, colour = depictr_brand(),
                         title = NULL, x_lab = NULL, y_lab = NULL) {
  mf <- stats::model.frame(model)
  if (!predictor %in% names(mf)[-1]) {
    stop("`predictor` must be one of the model's predictors: ",
         paste(names(mf)[-1], collapse = ", "), ".", call. = FALSE)
  }
  focal <- mf[[predictor]]
  is_factor <- !is.numeric(focal)
  values <- if (is_factor) {
    levels(as.factor(focal))
  } else {
    seq(min(focal, na.rm = TRUE), max(focal, na.rm = TRUE), length.out = n)
  }

  grid <- model_predict_grid(model, stats::setNames(list(values), predictor),
                             conf_level)
  resp <- attr(grid, "response")
  x_lab <- x_lab %||% predictor
  y_lab <- y_lab %||% if (isTRUE(attr(grid, "binomial"))) {
    "Predicted probability"
  } else {
    paste("Predicted", resp)
  }

  if (is_factor) {
    grid[[predictor]] <- factor(grid[[predictor]], levels = values)
    p <- ggplot2::ggplot(grid, ggplot2::aes(x = .data[[predictor]],
                                            y = .data$fit)) +
      ggplot2::geom_pointrange(
        ggplot2::aes(ymin = .data$lwr, ymax = .data$upr),
        colour = colour, linewidth = 0.7, size = 0.5
      )
  } else {
    p <- ggplot2::ggplot(grid, ggplot2::aes(x = .data[[predictor]],
                                            y = .data$fit)) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lwr, ymax = .data$upr),
                           fill = colour, alpha = 0.18) +
      ggplot2::geom_line(colour = colour, linewidth = 0.9)
    if (rug) {
      p <- p + ggplot2::geom_rug(
        data = mf, ggplot2::aes(x = .data[[predictor]]),
        sides = "b", alpha = 0.3, inherit.aes = FALSE
      )
    }
  }
  p + ggplot2::labs(x = x_lab, y = y_lab, title = title) + theme_depictr()
}

#' Plot a two-way interaction of predicted values
#'
#' Shows how the predicted relationship between a focal predictor and the
#' response changes across the levels (or representative values) of a second,
#' moderating predictor. Other predictors are held at typical values.
#'
#' @param model A fitted model (`lm`, `glm`, `merMod`, ...).
#' @param predictor Name of the focal predictor on the x-axis (string).
#' @param moderator Name of the moderating predictor, mapped to colour (string).
#' @param moderator_values For a numeric moderator, the values to show. Defaults
#'   to the 10th, 50th and 90th percentiles.
#' @param conf_level Confidence level for the bands/intervals.
#' @param n Number of points across the range of a numeric focal predictor.
#' @param band Whether to draw confidence bands (numeric focal predictor).
#' @param palette Colours for the moderator; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ fertilizer * treatment + rainfall, data = crop_yield)
#' interaction_plot(fit, "fertilizer", "treatment")
interaction_plot <- function(model, predictor, moderator,
                             moderator_values = NULL, conf_level = 0.95,
                             n = 80, band = TRUE, palette = NULL,
                             title = NULL, x_lab = NULL, y_lab = NULL) {
  mf <- stats::model.frame(model)
  preds <- names(mf)[-1]
  for (v in c(predictor, moderator)) {
    if (!v %in% preds) {
      stop("`", v, "` is not a model predictor (", paste(preds, collapse = ", "),
           ").", call. = FALSE)
    }
  }
  focal <- mf[[predictor]]
  focal_factor <- !is.numeric(focal)
  focal_values <- if (focal_factor) {
    levels(as.factor(focal))
  } else {
    seq(min(focal, na.rm = TRUE), max(focal, na.rm = TRUE), length.out = n)
  }

  modr <- mf[[moderator]]
  mod_values <- if (!is.numeric(modr)) {
    levels(as.factor(modr))
  } else if (!is.null(moderator_values)) {
    moderator_values
  } else {
    stats::quantile(modr, c(0.1, 0.5, 0.9), na.rm = TRUE, names = FALSE)
  }

  grid <- model_predict_grid(
    model,
    stats::setNames(list(focal_values, mod_values), c(predictor, moderator)),
    conf_level
  )
  resp <- attr(grid, "response")
  grid$.mod <- factor(format(grid[[moderator]]),
                      levels = format(mod_values))
  # The moderator levels are encoded by colour. Use the canonical depictr
  # scales so the palette is sourced in one place; an explicit `palette`
  # override (a vector of colours) is honoured by slicing it per request.
  pal <- palette %||% depictr_palette(length(mod_values))
  pal_fun <- function(k) pal[seq_len(k)]
  x_lab <- x_lab %||% predictor
  y_lab <- y_lab %||% if (isTRUE(attr(grid, "binomial"))) {
    "Predicted probability"
  } else {
    paste("Predicted", resp)
  }

  if (focal_factor) {
    grid[[predictor]] <- factor(grid[[predictor]], levels = focal_values)
    p <- ggplot2::ggplot(grid, ggplot2::aes(x = .data[[predictor]],
                                            y = .data$fit, colour = .data$.mod)) +
      ggplot2::geom_pointrange(
        ggplot2::aes(ymin = .data$lwr, ymax = .data$upr),
        position = ggplot2::position_dodge(width = 0.4), linewidth = 0.7
      )
  } else {
    p <- ggplot2::ggplot(grid, ggplot2::aes(x = .data[[predictor]],
                                            y = .data$fit, colour = .data$.mod))
    if (band) {
      p <- p + ggplot2::geom_ribbon(
        ggplot2::aes(ymin = .data$lwr, ymax = .data$upr, fill = .data$.mod),
        alpha = 0.15, colour = NA
      ) + scale_fill_depictr(palette = pal_fun, guide = "none")
    }
    p <- p + ggplot2::geom_line(linewidth = 0.9)
  }

  p +
    scale_colour_depictr(palette = pal_fun, name = moderator) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()
}

# ---- internal helper -------------------------------------------------------

#' Build a prediction grid, holding non-varying predictors at typical values
#' @noRd
model_predict_grid <- function(model, vary, conf_level = 0.95) {
  mf <- stats::model.frame(model)
  resp <- names(mf)[1]
  vars <- names(mf)[-1]

  typical <- lapply(vars, function(v) {
    col <- mf[[v]]
    if (is.numeric(col)) {
      mean(col, na.rm = TRUE)
    } else {
      f <- as.factor(col)
      factor(names(which.max(table(f))), levels = levels(f))
    }
  })
  names(typical) <- vars
  for (nm in names(vary)) typical[[nm]] <- vary[[nm]]

  nd <- expand.grid(typical, stringsAsFactors = FALSE)
  for (v in vars) {
    if (is.factor(mf[[v]])) nd[[v]] <- factor(nd[[v]], levels = levels(mf[[v]]))
  }

  alpha <- 1 - conf_level
  if (inherits(model, "merMod")) {
    # lme4 models: predict.merMod has no se.fit. Use the fixed effects only
    # for the point estimate and derive the SE from the fixed-effect design
    # matrix and the variance-covariance of the fixed effects.
    fam <- stats::family(model)
    link_fit <- stats::predict(model, newdata = nd, re.form = NA, type = "link")
    terms_fe <- stats::delete.response(stats::terms(model, fixed.only = TRUE))
    contr <- attr(stats::model.matrix(model), "contrasts")
    X <- stats::model.matrix(terms_fe, data = nd, contrasts.arg = contr)
    V <- as.matrix(stats::vcov(model))
    X <- X[, colnames(V), drop = FALSE]
    se <- sqrt(diag(X %*% V %*% t(X)))
    inv <- fam$linkinv
    z <- stats::qnorm(1 - alpha / 2)             # asymptotic for mixed models
    nd$fit <- inv(link_fit)
    nd$lwr <- inv(link_fit - z * se)
    nd$upr <- inv(link_fit + z * se)
    attr(nd, "binomial") <- fam$family == "binomial"
  } else if (inherits(model, "glm")) {
    z <- stats::qnorm(1 - alpha / 2)             # Wald interval on the link scale
    pr <- stats::predict(model, newdata = nd, type = "link", se.fit = TRUE)
    inv <- stats::family(model)$linkinv
    nd$fit <- inv(pr$fit)
    nd$lwr <- inv(pr$fit - z * pr$se.fit)
    nd$upr <- inv(pr$fit + z * pr$se.fit)
    attr(nd, "binomial") <- stats::family(model)$family == "binomial"
  } else {
    pr <- stats::predict(model, newdata = nd, se.fit = TRUE)
    # Use a t multiplier with the residual df when available (matches
    # predict.lm / confint for lm); fall back to the Normal quantile otherwise.
    df <- tryCatch(stats::df.residual(model), error = function(e) NULL)
    mult <- if (!is.null(df) && is.finite(df) && df > 0) {
      stats::qt(1 - alpha / 2, df)
    } else {
      stats::qnorm(1 - alpha / 2)
    }
    nd$fit <- pr$fit
    nd$lwr <- pr$fit - mult * pr$se.fit
    nd$upr <- pr$fit + mult * pr$se.fit
    attr(nd, "binomial") <- FALSE
  }
  attr(nd, "response") <- resp
  nd
}
