# Predicted values from a model ----------------------------------------------

#' Plot predicted values for one predictor
#'
#' Shows the values a model predicts as one focal predictor varies, holding the
#' other predictors at typical values (the mean for numeric predictors, the most
#' frequent level for factors). A confidence band (numeric predictor) or
#' confidence intervals (factor predictor) convey uncertainty.
#'
#' The prediction grid holds the variables the formula names, on their own
#' scale, and [stats::predict()] re-applies each transformation to it. A model
#' with terms such as `log(rainfall)`, `poly(fertiliser, 2)`, `splines::ns()`,
#' `scale()`, `factor()` or `I()` is therefore predicted as fitted, and the
#' x-axis shows the raw variable. Typical values and the range of the focal
#' predictor are taken over the rows the model was fitted to. A numeric
#' variable that enters only through `factor()` is held at its most frequent
#' value. A variable that enters only through a transformation is recovered
#' from the data named in the model's call, so such a model fitted to
#' workspace vectors without `data =` is refused. A term computed from
#' statistics of its rows, such as `I(x - mean(x))`, is refused too, since
#' `predict()` would compute it afresh over the grid. Centre such a variable in
#' the data, or use `scale()`, which `predict()` re-applies as fitted.
#'
#' An offset, whether an `offset()` term or the `offset` argument, is held at
#' its mean over the rows the model was fitted to, on the link scale. For a
#' Poisson rate model with `offset(log(exposure))`, the line is the expected
#' count at the geometric-mean exposure. The offset stays at its mean when the
#' focal predictor enters it too, as in `log(exposure) + offset(log(exposure))`,
#' so the line then shows the predictor's effect beyond the offset. The y-axis
#' label ends in "at the mean offset".
#'
#' Predictions and standard errors come from [stats::predict()]; `glm`
#' predictions are formed on the link scale and back-transformed, so a binomial
#' model shows predicted probabilities. Mixed models fitted with
#' [lme4::lmer()]/[lme4::glmer()] are supported too: predictions use only the
#' fixed effects (as `re.form = NA` does) and standard errors come from the
#' fixed-effect design matrix and `vcov()`. Works with `lm`, `glm` and
#' `merMod`; other model classes are attempted on a best-effort basis.
#'
#' @param model A fitted model (`lm`, `glm`, `merMod`, ...).
#' @param predictor Name of the focal predictor (string): a variable in the
#'   model's formula, or a model-frame name such as `"log(rainfall)"`, which
#'   stands for the one variable it transforms. A term built from several
#'   variables, such as `"I(rainfall * fertiliser)"`, is refused.
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
#' fit <- lm(yield ~ rainfall + fertiliser + treatment, data = crop_yield)
#' effects_plot(fit, "fertiliser")
#' effects_plot(fit, "treatment")
#'
#' gfit <- glm(accuracy ~ word_frequency + condition,
#'             data = lexical_decision, family = binomial)
#' effects_plot(gfit, "word_frequency")        # predicted probability
effects_plot <- function(model, predictor, conf_level = 0.95, n = 100,
                         rug = TRUE, colour = depictr_brand(),
                         title = NULL, x_lab = NULL, y_lab = NULL) {
  raw <- model_raw_data(model)
  predictor <- resolve_predictor(predictor, raw, "predictor")
  is_factor <- predictor %in% raw$categorical
  values <- grid_values(raw$data[[predictor]], is_factor, n)

  grid <- model_predict_grid(model, stats::setNames(list(values), predictor),
                             conf_level, raw = raw)
  x_lab <- x_lab %||% predictor
  y_lab <- y_lab %||% prediction_label(grid)

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
        data = raw$data, ggplot2::aes(x = .data[[predictor]]),
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
#' The grid is built as in [effects_plot()]. It holds the raw variables, so
#' transformed terms are predicted as fitted. Typical values come from the
#' estimation sample, and an offset is held at its mean on the link scale.
#'
#' @param model A fitted model (`lm`, `glm`, `merMod`, ...).
#' @param predictor Name of the focal predictor on the x-axis (string), given
#'   as in [effects_plot()]: `"log(rainfall)"` means `rainfall`.
#' @param moderator Name of the moderating predictor, mapped to colour
#'   (string), given in the same way as `predictor`. It must be a different
#'   variable.
#' @param moderator_values For a numeric moderator, the values to show, on the
#'   variable's own scale. Defaults to the 10th, 50th and 90th percentiles in
#'   the estimation sample.
#' @param conf_level Confidence level for the bands/intervals.
#' @param n Number of points across the range of a numeric focal predictor.
#' @param band Whether to draw confidence bands (numeric focal predictor).
#' @param palette Colours for the moderator; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ fertiliser * treatment + rainfall, data = crop_yield)
#' interaction_plot(fit, "fertiliser", "treatment")
interaction_plot <- function(model, predictor, moderator,
                             moderator_values = NULL, conf_level = 0.95,
                             n = 80, band = TRUE, palette = NULL,
                             title = NULL, x_lab = NULL, y_lab = NULL) {
  raw <- model_raw_data(model)
  predictor <- resolve_predictor(predictor, raw, "predictor")
  moderator <- resolve_predictor(moderator, raw, "moderator")
  if (identical(predictor, moderator)) {
    stop("`predictor` and `moderator` name the same variable, `", predictor,
         "`.", call. = FALSE)
  }
  focal_factor <- predictor %in% raw$categorical
  focal_values <- grid_values(raw$data[[predictor]], focal_factor, n)

  modr <- raw$data[[moderator]]
  mod_values <- if (moderator %in% raw$categorical) {
    grid_values(modr, TRUE)
  } else if (!is.null(moderator_values)) {
    moderator_values
  } else {
    stats::quantile(modr, c(0.1, 0.5, 0.9), na.rm = TRUE, names = FALSE)
  }

  grid <- model_predict_grid(
    model,
    stats::setNames(list(focal_values, mod_values), c(predictor, moderator)),
    conf_level, raw = raw
  )
  grid$.mod <- factor(format(grid[[moderator]]),
                      levels = format(mod_values))
  # The moderator levels are encoded by colour. Use the canonical depictr
  # scales so the palette is sourced in one place; an explicit `palette`
  # override (a vector of colours) is honoured by slicing it per request.
  pal <- palette %||% depictr_palette(length(mod_values))
  pal_fun <- function(k) pal[seq_len(k)]
  x_lab <- x_lab %||% predictor
  y_lab <- y_lab %||% prediction_label(grid)

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

# ---- internal helpers ------------------------------------------------------

#' The raw variables behind a model, over the rows it was fitted to
#'
#' A prediction grid has to hold the variables a formula names. predict()
#' rebuilds every term, `log(rainfall)` as much as `rainfall`, from those
#' variables. A grid column named after a term is therefore ignored, and a
#' variable missing from the grid is looked up in the formula's environment.
#' When every variable is a column of the model frame, because no term
#' transforms its variable, the model frame supplies them. Otherwise, they are
#' recovered from the data the call names and cut to the rows of the model
#' frame, so typical values remain statistics of the estimation sample. A
#' formula or offset that reads a data frame with `$` is refused, and so is a
#' term that predict() would compute afresh over a grid (see
#' grid_unsafe_terms()).
#'
#' @return A list. `data` holds the variables over the estimation rows.
#'   `predictors` are the variables that enter through a term, in formula
#'   order, and `offset_only` those that enter only through an offset.
#'   `categorical` names the variables held at their most frequent value, and
#'   `terms` gives the variables behind each model-frame name. `offset_mean`
#'   is the mean offset over the estimation rows on the link scale, or `NULL`
#'   for a model without one.
#' @noRd
model_raw_data <- function(model) {
  is_mer <- inherits(model, "merMod")
  tt <- if (is_mer) stats::terms(model, fixed.only = TRUE) else stats::terms(model)
  mf <- stats::model.frame(model)

  # attr(tt, "variables") is a call to list(). Its arguments are the response,
  # if any, and the variables of the terms and of the offset() terms, at the
  # positions attr(tt, "response") and attr(tt, "offset") give.
  exprs <- as.list(attr(tt, "variables"))[-1L]
  offsets <- attr(tt, "offset")
  resp <- attr(tt, "response")
  term_exprs <- exprs[setdiff(seq_along(exprs), c(if (resp > 0) resp, offsets))]
  term_vars <- lapply(term_exprs, all.vars)
  names(term_vars) <- vapply(term_exprs, deparse_var, character(1))
  call_offset <- stats::getCall(model)$offset
  offset_vars <- unique(c(unlist(lapply(exprs[offsets], all.vars)),
                          all.vars(call_offset)))
  predictors <- unique(unlist(term_vars))
  vars <- union(predictors, offset_vars)

  # In log(d$expo), predict() takes expo from d whatever the grid holds.
  whole <- names_read_whole(c(term_exprs, exprs[offsets], list(call_offset)))
  if (length(whole)) {
    stop("The formula or offset reads columns of `", whole[1L], "` with `$` ",
         "or `[[`, so predict() would take them from `", whole[1L], "` and ",
         "ignore the prediction grid. Name the columns themselves, with ",
         "`data =`, and refit the model.", call. = FALSE)
  }

  data <- if (all(vars %in% names(mf))) {
    mf[vars]
  } else {
    recover_model_data(model, vars, tt, mf, is_mer)
  }
  attr(data, "terms") <- NULL
  # Unused levels are dropped, as lm() drops them from the model frame, so a
  # factor sweeps and is held only at levels the model estimated.
  data <- droplevels(data)
  if (!all(vapply(term_exprs, is.name, logical(1)))) {
    unsafe <- grid_unsafe_terms(data, tt, mf, names(term_vars))
    if (length(unsafe)) {
      several <- !anyNA(unsafe) && length(unsafe) > 1L
      stop(if (anyNA(unsafe)) {
        "A term of this model cannot be computed from a single row of its data"
      } else if (!several) {
        paste0("The term `", unsafe, "` depends on statistics of the rows it ",
               "is computed from")
      } else {
        paste0("The terms ", paste0("`", unsafe, "`", collapse = " and "),
               " depend on statistics of the rows they are computed from")
      }, ". predict() computes every term afresh over a prediction grid, so ",
      "transform the ", if (several) "variables" else "variable",
      " in the data and refit the model.", call. = FALSE)
    }
  }
  predictors <- intersect(predictors, names(data))
  offset_vars <- intersect(offset_vars, names(data))

  categorical <- names(data)[vapply(names(data), function(v) {
    !is.numeric(data[[v]]) || enters_through_factor(v, term_exprs)
  }, logical(1))]

  has_offset <- length(offsets) > 0L || !is.null(call_offset)
  offset_mean <- if (has_offset) {
    mean(if (is_mer) lme4::getME(model, "offset") else stats::model.offset(mf))
  }

  list(data = data, predictors = predictors,
       offset_only = setdiff(offset_vars, predictors),
       categorical = categorical, terms = term_vars,
       response = names(mf)[1], offset_mean = offset_mean)
}

#' The variables `vars` over the estimation rows, from the data the call names
#'
#' The data are refused unless they rebuild the model frame the fit stored, so
#' a data frame changed or shortened since the fit is caught before it can
#' supply typical values the model never saw.
#' @noRd
recover_model_data <- function(model, vars, tt, mf, is_mer) {
  env <- environment(tt)
  data_arg <- stats::getCall(model)$data
  if (is.null(data_arg)) {
    stop("Cannot recover the data this model was fitted to; refit it with ",
         "`data =`.", call. = FALSE)
  }
  unrecoverable <- function() {
    what <- if (is.language(data_arg)) {
      paste0("`", deparse_var(data_arg), "`")
    } else {
      "the data frame in its call"
    }
    stop("Cannot recover the data this model was fitted to: ", what,
         " is missing or has changed since the fit, so refit the model.",
         call. = FALSE)
  }
  data <- tryCatch(
    if (is_mer) lme4::getData(model) else eval(data_arg, env),
    error = function(e) NULL
  )
  if (!is.data.frame(data)) unrecoverable()
  keep <- match(rownames(mf), rownames(data))
  if (anyNA(keep)) unrecoverable()

  # A name the data lack was found in the formula's environment when the model
  # was fitted. A variable there has a value for every row of the data. A
  # value of any other length is a constant of a term, as the `k` of
  # ns(x, df = k) and the knots of ns(x, knots = kn) are. predict() finds such
  # a constant again, so the grid leaves it out.
  outside <- setdiff(vars, names(data))
  constant <- vapply(outside, function(v) {
    value <- tryCatch(get(v, envir = env), error = function(e) NULL)
    is.atomic(value) && !is.null(value) && length(value) != nrow(data)
  }, logical(1))
  vars <- setdiff(vars, outside[constant])
  if (!length(vars)) return(data[keep, 0L, drop = FALSE])

  # Every other variable has to become a column of the grid, or predict()
  # would look it up in the formula's environment.
  raw <- tryCatch(
    stats::get_all_vars(
      stats::reformulate(sprintf("`%s`", vars), env = env), data = data
    ),
    error = function(e) NULL
  )
  if (is.null(raw) || !all(vars %in% names(raw))) unrecoverable()
  raw <- raw[keep, vars, drop = FALSE]
  mismatch <- model_frame_mismatch(raw, tt, mf,
                                   call_offset = stats::getCall(model)$offset)
  if (length(mismatch)) unrecoverable()
  raw
}

#' The columns of a stored model frame that raw data fail to rebuild
#'
#' The terms carry their "predvars", so poly(), ns() and scale() are rebuilt
#' with the coefficients of the fit, and each column has to match the stored
#' one. Factors and strings are compared as text, since lme4 may store a
#' string as a factor.
#' @param cols The model-frame columns to compare. By default, every column
#'   the rebuild shares with `mf`.
#' @param call_offset The call's `offset` argument, compared with the stored
#'   "(offset)" column when given.
#' @return The names of the columns that differ, or NA when the rebuild fails.
#' @noRd
model_frame_mismatch <- function(raw, tt, mf, cols = NULL, call_offset = NULL) {
  rebuilt <- tryCatch(
    stats::model.frame(stats::delete.response(tt), raw,
                       na.action = stats::na.pass),
    error = function(e) NULL
  )
  if (is.null(rebuilt)) return(NA_character_)
  same <- function(a, b) {
    if (is.factor(a) || is.character(a) || is.factor(b) || is.character(b)) {
      return(identical(as.character(a), as.character(b)))
    }
    isTRUE(all.equal(unclass(a), unclass(b), check.attributes = FALSE))
  }
  shared <- intersect(names(rebuilt), names(mf))
  cols <- if (is.null(cols)) shared else intersect(cols, shared)
  bad <- cols[!vapply(cols, function(cl) same(mf[[cl]], rebuilt[[cl]]),
                      logical(1))]
  if (!is.null(call_offset) && "(offset)" %in% names(mf)) {
    off <- tryCatch(eval(call_offset, raw, environment(tt)),
                    error = function(e) NULL)
    if (is.null(off) || !same(mf[["(offset)"]], off)) bad <- c(bad, "(offset)")
  }
  bad
}

#' The terms predict() would compute afresh over a prediction grid
#'
#' predict() rebuilds every term from the rows of new data alone. poly(), ns()
#' and scale() come out as fitted, since the terms carry the coefficients of
#' the fit in their "predvars". A term such as I(x - mean(x)) takes a statistic
#' of whatever rows it is given, so over a grid it shifts. Each estimation row
#' at a numeric variable's minimum or maximum, where such a statistic lies
#' furthest from the row's own value, is therefore rebuilt on its own. Offsets
#' are left out, since the grid's offset is replaced by the mean model offset.
#' @param cols The model-frame names of the terms to check.
#' @return The names in `cols` that a single row fails to rebuild, or NA when a
#'   single row cannot be rebuilt at all.
#' @noRd
grid_unsafe_terms <- function(data, tt, mf, cols) {
  extremes <- lapply(Filter(is.numeric, data), function(x) {
    c(which.min(x), which.max(x))
  })
  rows <- unique(c(1L, unlist(extremes, use.names = FALSE)))
  unique(unlist(lapply(rows, function(i) {
    model_frame_mismatch(data[i, , drop = FALSE], tt, mf[i, , drop = FALSE],
                         cols = cols)
  })))
}

#' The names an expression reads whole with `$` or `[[`, such as d in d$expo
#'
#' An empty argument, as in `x[, 1]`, is skipped, since it cannot be passed on.
#' @noRd
names_read_whole <- function(exprs) {
  found <- character()
  walk <- function(e) {
    if (!is.call(e)) return(invisible())
    fn <- e[[1L]]
    if ((identical(fn, as.name("$")) || identical(fn, as.name("[["))) &&
        is.name(e[[2L]])) {
      found <<- c(found, as.character(e[[2L]]))
    }
    args <- as.list(e)[-1L]
    for (i in seq_along(args)) {
      if (!identical(args[i], list(quote(expr = )))) walk(args[[i]])
    }
  }
  for (e in exprs) walk(e)
  unique(found)
}

#' Whether the variable `v` enters a term as factor(v) or a relative
#' @noRd
enters_through_factor <- function(v, exprs) {
  any(vapply(exprs, function(e) {
    if (!is.call(e) || length(e) < 2L) return(FALSE)
    fn <- e[[1L]]
    if (is.call(fn) && identical(fn[[1L]], as.name("::"))) fn <- fn[[3L]]
    is.name(fn) &&
      as.character(fn) %in% c("factor", "as.factor", "ordered", "as.ordered") &&
      identical(e[[2L]], as.name(v))
  }, logical(1)))
}

#' A variable's name as model.frame() writes it (its internal deparse2())
#' @noRd
deparse_var <- function(x) {
  paste(deparse(x, width.cutoff = 500L,
                backtick = !is.symbol(x) && is.language(x)),
        collapse = " ")
}

#' Map a name the user gave to one of the model's variables
#'
#' A variable of the formula stands for itself. A model-frame name such as
#' "log(rainfall)" or "I(rainfall^2)" stands for the one variable it
#' transforms, even where that variable also enters untransformed, so that the
#' grid varies the variable predict() reads.
#' @noRd
resolve_predictor <- function(name, raw, arg) {
  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    stop("`", arg, "` must be a single name (a string).", call. = FALSE)
  }
  if (name %in% raw$predictors) return(name)
  if (name %in% raw$offset_only) {
    stop("`", name, "` enters the model only through its offset, which is ",
         "held at its mean, so it cannot be varied.", call. = FALSE)
  }
  key <- tryCatch(deparse_var(str2lang(name)), error = function(e) name)
  used <- if (key %in% names(raw$terms)) {
    intersect(raw$terms[[key]], raw$predictors)
  }
  if (length(used) == 1L) return(used)
  if (length(used) > 1L) {
    stop("`", arg, "` names the term `", name, "`, which combines ",
         paste(used, collapse = ", "), "; name one of these variables.",
         call. = FALSE)
  }
  stop("`", arg, "` must be one of the model's predictors: ",
       paste(raw$predictors, collapse = ", "), ".", call. = FALSE)
}

#' The values a focal variable takes in the grid
#'
#' A sweep across the observed range of a numeric variable, and otherwise each
#' level, or each value of a numeric variable that enters through factor().
#' @noRd
grid_values <- function(x, categorical, n = 100) {
  if (!categorical) {
    return(seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n))
  }
  if (is.numeric(x)) sort(unique(x[!is.na(x)])) else levels(as.factor(x))
}

#' A variable's typical value: the mean, or the most frequent value
#'
#' A numeric variable that enters through factor() is held at its most
#' frequent value, since its mean is usually no level of the factor.
#' @noRd
typical_value <- function(x, categorical) {
  if (is.numeric(x) && !categorical) return(mean(x, na.rm = TRUE))
  if (is.numeric(x)) {
    values <- sort(unique(x[!is.na(x)]))
    return(values[which.max(tabulate(match(x, values)))])
  }
  f <- as.factor(x)
  factor(names(which.max(table(f))), levels = levels(f))
}

#' The offset predict() adds for new data
#'
#' Each offset() term of the formula and the call's `offset` argument,
#' evaluated in the grid, as predict.lm() evaluates them.
#' @noRd
newdata_offset <- function(model, nd) {
  tt <- stats::terms(model)
  env <- environment(tt)
  off <- rep(0, nrow(nd))
  for (i in attr(tt, "offset")) {
    off <- off + eval(attr(tt, "variables")[[i + 1L]], nd, env)
  }
  call_offset <- stats::getCall(model)$offset
  if (!is.null(call_offset)) off <- off + eval(call_offset, nd, env)
  off
}

#' The y-axis label of a prediction grid
#' @noRd
prediction_label <- function(grid) {
  label <- if (isTRUE(attr(grid, "binomial"))) {
    "Predicted probability"
  } else {
    paste("Predicted", attr(grid, "response"))
  }
  if (isTRUE(attr(grid, "offset"))) paste(label, "at the mean offset") else label
}

#' Build a prediction grid, holding non-varying predictors at typical values
#'
#' The grid holds the raw variables of `raw` (see model_raw_data()), each at
#' its typical value except those in `vary`. An offset is held at its mean
#' over the estimation rows on the link scale. The offset predict() adds for
#' the grid is replaced by that mean, since an offset expression cannot in
#' general be inverted to a value of its variable.
#' @noRd
model_predict_grid <- function(model, vary, conf_level = 0.95,
                               raw = model_raw_data(model)) {
  data <- raw$data
  vars <- names(data)
  typical <- lapply(vars, function(v) {
    typical_value(data[[v]], v %in% raw$categorical)
  })
  names(typical) <- vars
  for (nm in names(vary)) typical[[nm]] <- vary[[nm]]

  # The grid holds every variable of `raw`, which model_raw_data() makes every
  # variable the formula names but the constants of its terms. predict() would
  # otherwise take a missing one from the formula's environment, where a
  # workspace vector of the same name may sit.
  nd <- expand.grid(typical, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  for (v in vars) {
    if (!is.numeric(data[[v]])) {
      nd[[v]] <- factor(nd[[v]], levels = levels(as.factor(data[[v]])))
    }
  }
  off_mean <- raw$offset_mean

  alpha <- 1 - conf_level
  if (inherits(model, "merMod")) {
    # lme4 models: predict.merMod has no se.fit, and for new data it adds a
    # formula offset but not an `offset` argument. The fixed-effect predictor
    # is therefore formed from the fixed-effect design matrix, with the SE from
    # the same matrix and the variance-covariance of the fixed effects. The
    # factor levels of the fit are passed on, as predict.merMod passes them,
    # so a grid that holds a factor at one level keeps its full coding.
    fam <- stats::family(model)
    terms_fe <- stats::delete.response(stats::terms(model, fixed.only = TRUE))
    mf_fe <- stats::model.frame(model, fixed.only = TRUE)
    rhs <- intersect(vapply(as.list(attr(terms_fe, "variables"))[-1L],
                            deparse_var, character(1)), names(mf_fe))
    xlev <- lapply(Filter(is.factor, mf_fe[rhs]), levels)
    contr <- attr(stats::model.matrix(model), "contrasts")
    X <- stats::model.matrix(terms_fe, data = nd, contrasts.arg = contr,
                             xlev = xlev)
    V <- as.matrix(stats::vcov(model))
    X <- X[, colnames(V), drop = FALSE]
    link_fit <- drop(X %*% lme4::fixef(model)[colnames(V)])
    if (!is.null(off_mean)) link_fit <- link_fit + off_mean
    se <- sqrt(rowSums((X %*% V) * X))
    inv <- fam$linkinv
    z <- stats::qnorm(1 - alpha / 2)             # asymptotic for mixed models
    nd$fit <- inv(link_fit)
    nd$lwr <- inv(link_fit - z * se)
    nd$upr <- inv(link_fit + z * se)
    attr(nd, "binomial") <- fam$family == "binomial"
  } else if (inherits(model, "glm")) {
    z <- stats::qnorm(1 - alpha / 2)             # Wald interval on the link scale
    pr <- stats::predict(model, newdata = nd, type = "link", se.fit = TRUE)
    link_fit <- pr$fit
    if (!is.null(off_mean)) {
      link_fit <- link_fit - newdata_offset(model, nd) + off_mean
    }
    inv <- stats::family(model)$linkinv
    nd$fit <- inv(link_fit)
    nd$lwr <- inv(link_fit - z * pr$se.fit)
    nd$upr <- inv(link_fit + z * pr$se.fit)
    attr(nd, "binomial") <- stats::family(model)$family == "binomial"
  } else {
    pr <- stats::predict(model, newdata = nd, se.fit = TRUE)
    fit <- pr$fit
    if (!is.null(off_mean)) fit <- fit - newdata_offset(model, nd) + off_mean
    # Use a t multiplier with the residual df when available (matches
    # predict.lm / confint for lm); fall back to the Normal quantile otherwise.
    df <- tryCatch(stats::df.residual(model), error = function(e) NULL)
    mult <- if (!is.null(df) && is.finite(df) && df > 0) {
      stats::qt(1 - alpha / 2, df)
    } else {
      stats::qnorm(1 - alpha / 2)
    }
    nd$fit <- fit
    nd$lwr <- fit - mult * pr$se.fit
    nd$upr <- fit + mult * pr$se.fit
    attr(nd, "binomial") <- FALSE
  }
  attr(nd, "response") <- raw$response
  attr(nd, "offset") <- !is.null(off_mean)
  nd
}
