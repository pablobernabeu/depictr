# Forest / coefficient plot --------------------------------------------------

#' Forest (coefficient) plot
#'
#' Draws a horizontal point-and-interval ("forest") plot of model estimates.
#' The input can be a fitted model (anything [tidy_estimates()] understands) or
#' a data frame of pre-computed estimates.
#'
#' @param x A fitted model or a tidy data frame of estimates.
#' @param conf_level Confidence/credible level, passed to [tidy_estimates()]
#'   when `x` is a model: a single number strictly between 0 and 1.
#' @param intercept Whether to keep the intercept term. Defaults to `FALSE`,
#'   since the intercept is seldom of interest on a forest plot and its scale
#'   often overwhelms the other terms.
#' @param order Order of the terms. `"ascending"` puts the smallest estimate at
#'   the bottom and the largest at the top, so estimates increase up the axis.
#'   `"descending"` does the reverse, and `"none"` keeps model order from top
#'   to bottom. The faceted layout (`facet = TRUE`) stacks its panels the
#'   other way up.
#' @param labels Optional display labels for the terms. An unnamed vector gives
#'   one label per term in model order (the order [tidy_estimates()] returns,
#'   after the intercept is dropped unless `intercept = TRUE`), whatever
#'   `order` is. A named vector mapping raw term names to labels, such as
#'   `c(soil_ph = "Soil pH")`, is safer. If `NULL`, the coefficient of a
#'   factor level is labelled with its variable and level, inside interaction
#'   terms too, so the contrast of enhanced with the reference level reads
#'   `treatment: enhanced`. Other names are tidied with [format_terms()].
#' @param interaction Passed to [format_terms()] to control how interaction
#'   terms are rendered (ignored when `labels` is supplied).
#' @param point_colour,reference_colour Colours for the estimates and the
#'   reference line.
#' @param reference_line Position of a vertical reference line. Defaults to 0,
#'   or to 1 when `exponentiate = TRUE`, where a ratio of 1 means no effect.
#'   Use `NA` to omit it.
#' @param point_size,line_size Size of the points and interval lines.
#' @param facet Whether to give each term its own panel with a free x-axis,
#'   laid out one per row. This removes the squish that occurs when terms live
#'   on very different scales (for example a large intercept alongside small
#'   slopes). Defaults to `FALSE`, preserving the shared-axis layout. A
#'   convenience alias for `scales = "free"`.
#' @param scales Either `"fixed"` (the default, a single shared x-axis) or
#'   `"free"` (one free-scaled panel per term). When `facet = TRUE` this is
#'   forced to `"free"`.
#' @param standardise Whether to scale each coefficient by the spread of its
#'   inputs, following Gelman (2008). A continuous input (numeric, with more
#'   than two distinct values) is scaled by `sd_multiple` times its standard
#'   deviation in the rows the model used, so its slope becomes the change in
#'   the outcome per SD. Factor, character, logical and two-valued numeric
#'   inputs (0/1, say) are left unscaled, since a contrast already compares
#'   two groups and its per-SD value would depend on how balanced the groups
#'   happen to be. An interaction is scaled
#'   through its inputs: `rainfall:treatment` by the SD of `rainfall`, and a
#'   product of two continuous inputs by both their SDs. Matrix-valued terms
#'   such as `poly()` and `ns()` are left unscaled, with a message. An
#'   interaction of continuous inputs draws a warning unless they are all
#'   centred. Otherwise, each input's main effect is its slope where the
#'   others are zero, and Gelman's remedy is to centre the inputs and refit. A continuous slope and
#'   a contrast are comparable only roughly, most nearly with
#'   `sd_multiple = 2`. Requires a fitted model (ignored, with a warning, for a
#'   tidy data frame). Defaults to `FALSE`.
#' @param sd_multiple How many standard deviations of a continuous input one
#'   unit of the standardised scale spans when `standardise = TRUE`. Defaults
#'   to 1. Use 2 for Gelman's (2008) convention, under which the coefficient
#'   of a continuous input is comparable to that of a balanced binary one.
#' @param exponentiate Whether to draw the exponentiated estimates and
#'   intervals on a log10 axis, which shows the coefficients of a logistic
#'   regression as odds ratios and those of a Poisson or negative binomial
#'   model as rate ratios. It applies after `standardise`, so a standardised
#'   slope becomes a ratio per SD of its predictor. A data frame `x` must hold
#'   estimates on the link scale. Defaults to `FALSE`.
#' @param title,subtitle,x_lab Plot title, subtitle and x-axis label. `x_lab`
#'   defaults to "Estimate", or, when `standardise`, "Estimate per SD of
#'   predictor" ("per 2 SD" with `sd_multiple = 2`), followed by "(contrasts
#'   unscaled)" when a factor or binary term is drawn. The label names the
#'   convention on the figure itself, because only the predictors are rescaled
#'   here: a fully standardised beta would rescale the outcome too. With
#'   `exponentiate = TRUE`, "Estimate" gives way to the name of the ratio:
#'   "Odds ratio" for a logit link, "Rate ratio" for a log link in a Poisson,
#'   quasi-Poisson or negative binomial model, "Risk ratio" for a binomial
#'   model with a log link and "exp(Estimate)" otherwise. The last covers an
#'   `lm(log(y) ~ x)` slope, whose exponential is a ratio of geometric means.
#'
#' @references
#' \insertRef{gelman2008}{depictr}
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' fit <- lm(yield ~ rainfall + fertiliser + soil_ph + treatment,
#'           data = crop_yield)
#' coefficient_plot(fit)
#'
#' # Order terms and add a title
#' coefficient_plot(fit, order = "descending", title = "Drivers of crop yield")
#'
#' # When an intercept or large term squishes the rest, give each term its own
#' # free-scaled panel:
#' coefficient_plot(fit, intercept = TRUE, facet = TRUE)
#'
#' # Or scale the continuous slopes per SD of their predictors, leaving the
#' # treatment contrast in the outcome's units:
#' coefficient_plot(fit, standardise = TRUE)
#'
#' # Odds ratios from a logistic regression, on a log axis with the line at 1:
#' gfit <- glm(accuracy ~ word_frequency + condition,
#'             data = lexical_decision, family = binomial)
#' coefficient_plot(gfit, exponentiate = TRUE)
coefficient_plot <- function(x,
                      conf_level = 0.95,
                      intercept = FALSE,
                      order = c("none", "ascending", "descending"),
                      labels = NULL,
                      interaction = c("times", "asterisk", "colon", "space"),
                      point_colour = depictr_brand(),
                      reference_colour = depictr_reference(),
                      reference_line = if (exponentiate) 1 else 0,
                      point_size = 2.2,
                      line_size = 0.7,
                      facet = FALSE,
                      scales = c("fixed", "free"),
                      standardise = FALSE,
                      sd_multiple = 1,
                      exponentiate = FALSE,
                      title = NULL,
                      subtitle = NULL,
                      x_lab = NULL) {
  check_conf_level(conf_level)
  order <- match.arg(order)
  interaction <- match.arg(interaction)
  scales <- match.arg(scales)
  if (facet) scales <- "free"

  if (!is.numeric(sd_multiple) || length(sd_multiple) != 1 ||
      !is.finite(sd_multiple) || sd_multiple <= 0) {
    stop("`sd_multiple` must be a single positive number.", call. = FALSE)
  }
  check_exponentiate(exponentiate)

  est <- tidy_estimates(x, conf_level = conf_level)

  # Optionally scale each slope by the spread of its continuous inputs, which
  # removes the dead band that appears when, say, a per-mm rainfall slope sits
  # next to a treatment contrast. Contrasts keep their units (Gelman, 2008).
  contrasts_unscaled <- FALSE
  if (standardise) {
    est <- standardise_estimates(est, x, sd_multiple)
    contrasts_unscaled <- isTRUE(attr(est, "contrasts_unscaled"))
  }
  # Exponentiated after standardising, so a standardised slope becomes a ratio
  # per SD of its predictor.
  est <- exponentiate_estimates(est, exponentiate)
  stem <- if (exponentiate) ratio_label(x) else "Estimate"
  x_lab <- x_lab %||%
    if (standardise) {
      standardised_axis_label(sd_multiple, contrasts_unscaled, stem)
    } else {
      stem
    }

  # By default a factor's coefficient is labelled with its variable and level
  # (e.g. "conditionunrelated" -> "condition: unrelated"). User `labels` take
  # precedence.
  warn_unused_labels(est$term, labels)
  labels <- merge_pretty_labels(labels, pretty_coef_map(x, interaction))

  intercept_dropped <- FALSE
  if (!intercept) {
    is_intercept <- est$term %in% c("(Intercept)", "Intercept", "b_Intercept")
    intercept_dropped <- any(is_intercept)
    est <- est[!is_intercept, , drop = FALSE]
  }
  if (nrow(est) == 0) {
    stop("No terms left to plot (did you drop the only term?).", call. = FALSE)
  }

  # An unnamed `labels` vector is read in model order, so it is attached to the
  # rows before order_terms() reverses or sorts them, and each label travels
  # with its own term. Keying it by term name would mis-bind a data frame that
  # repeats a term.
  positional <- !is.null(labels) && is.null(names(labels))
  if (positional) {
    check_label_count(labels, nrow(est), "the model has", "in model order",
                      intercept_dropped)
    est$label <- as.character(labels)
  }

  est <- order_terms(est, order)

  if (!positional) est$label <- make_labels(est$term, labels, interaction)
  est$label <- factor(est$label, levels = est$label)

  p <- ggplot2::ggplot(
    est,
    ggplot2::aes(x = .data$estimate, y = .data$label)
  )

  # In the shared-axis layout the reference line spans the whole plot; in the
  # faceted layout it is drawn per panel (see add_term_facets()), so that a
  # large-intercept panel is not stretched back to the reference value.
  if (!is.na(reference_line) && scales == "fixed") {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line, linetype = 2, colour = reference_colour
    )
  }

  p <- p +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      orientation = "y", width = 0.18, linewidth = line_size,
      colour = point_colour, na.rm = TRUE
    ) +
    ggplot2::geom_point(size = point_size, colour = point_colour) +
    ggplot2::labs(x = x_lab, y = NULL, title = title, subtitle = subtitle) +
    theme_depictr(grid = "x")
  # Ratios are symmetric on a log scale, where 0.5 and 2 sit equally far from 1.
  if (exponentiate) p <- p + ggplot2::scale_x_log10()

  if (scales == "free") {
    p <- add_term_facets(p, reference_line = reference_line,
                         reference_colour = reference_colour)
  }

  p
}

# ---- internal helpers ------------------------------------------------------

#' Build a raw-name -> readable-label map for a model's factor columns
#'
#' Turns the design-matrix names that R produces for factor levels into
#' labels that name the variable and the level: `conditionunrelated` becomes
#' `condition: unrelated`. A two-level factor is labelled the same way as a
#' factor with more levels. Its one coefficient is still the contrast between
#' that level and the reference, and the level tells the reader which way round
#' the contrast runs. An interaction column is labelled
#' from its components: in `rainfall:treatmentenhanced` the second becomes
#' `treatment: enhanced`, joined to `rainfall` by the separator that
#' `interaction` names, as [format_terms()] joins them. A component is split
#' into variable and level when its variable is a factor (logical and
#' character inputs included, which `model.matrix()` codes the same way) or
#' when its term spans several columns, as `poly()` does. A one-column term
#' whose column name extends its label, such as `poly(x, 1)`, is labelled with
#' the term alone, as before. Each entry is also keyed under a `b_` prefix so
#' a brms summary term aligns with its frequentist counterpart. Columns with
#' no such component are left to [format_terms()], which tidies them and shows
#' underscores as spaces. Returns a named character vector, or `NULL` when `x`
#' is not a supported model or has no factor columns.
#' @noRd
pretty_coef_map <- function(x, interaction = "times") {
  if (!inherits(x, c("lm", "glm", "merMod", "lmerMod", "glmerMod",
                     "lmerModLmerTest"))) {
    return(NULL)
  }
  tl <- tryCatch(attr(stats::terms(x), "term.labels"), error = function(e) NULL)
  mm <- tryCatch(stats::model.matrix(x), error = function(e) NULL)
  if (is.null(tl) || is.null(mm)) return(NULL)
  assign <- attr(mm, "assign")
  cols <- colnames(mm)
  if (is.null(assign) || length(assign) != length(cols)) return(NULL)
  factors <- base::names(attr(mm, "contrasts"))
  sep <- interaction_separator(interaction)
  out <- character(0)
  for (i in seq_along(cols)) {
    a <- assign[i]
    if (a < 1 || a > length(tl)) next                 # intercept / unknown
    # model.matrix() names an interaction column by joining one piece per
    # variable with ":", in the order of the term label, so the pieces line
    # up with the variables. A level that itself holds a colon breaks the
    # alignment, and such a column is left to format_terms().
    vars <- strsplit(tl[a], ":", fixed = TRUE)[[1]]
    pieces <- strsplit(cols[i], ":", fixed = TRUE)[[1]]
    if (length(pieces) != length(vars)) next
    extends <- startsWith(pieces, vars) & nchar(pieces) > nchar(vars)
    if (!any(extends)) next                           # continuous: format_terms
    is_level <- extends & (vars %in% factors | sum(assign == a) > 1L)
    pieces[is_level] <- paste0(
      vars[is_level], ": ",
      substring(pieces[is_level], nchar(vars[is_level]) + 1L)
    )
    pieces[extends & !is_level] <- vars[extends & !is_level]
    val <- gsub("_", " ", paste(pieces, collapse = sep), fixed = TRUE)
    out[cols[i]] <- val
    out[paste0("b_", cols[i])] <- val   # align a brms b_-prefixed summary term
  }
  # Continuous terms are left to format_terms(), which also handles their
  # b_-prefixed Bayesian counterparts, so the two still align.
  if (length(out)) out else NULL
}

#' Merge the automatic label maps of several sources, the first one winning
#' @noRd
pretty_coef_maps <- function(sources, interaction = "times") {
  maps <- lapply(sources, pretty_coef_map, interaction = interaction)
  out <- NULL
  for (m in maps) out <- merge_pretty_labels(out, m)
  out
}

#' Merge an auto term-label map under any user-supplied labels (user wins)
#' @noRd
merge_pretty_labels <- function(user, auto) {
  if (is.null(auto)) return(user)
  if (is.null(user)) return(auto)
  if (is.null(names(user))) return(user)   # positional labels: respect as given
  c(user, auto[setdiff(names(auto), names(user))])
}

#' Standardise estimates by the SD of each continuous input
#'
#' Multiplies each estimate, its interval and its standard error by the
#' spread of the inputs that make up its model-matrix column, following
#' Gelman (2008). A continuous input (numeric, more than two distinct values)
#' contributes `sd_multiple` times its standard deviation in the model frame.
#' A factor, logical or two-valued numeric input contributes 1, so a contrast
#' keeps its own units and does not change with how balanced the groups are.
#' An interaction column takes the product of its inputs' multipliers, which
#' makes it the change in a per-SD slope. Scaling the product column by its
#' own SD would give a number with no interpretation. Matrix-valued inputs
#' such as `poly()` or `ns()` bases are left unscaled with a message.
#'
#' Needs a fitted model. For a data-frame input, or a model whose columns
#' cannot be traced back to its inputs, it warns and returns `est` unchanged.
#' The result carries a `contrasts_unscaled` attribute, `TRUE` when a column
#' involves a factor or binary input, for the axis label.
#' @noRd
standardise_estimates <- function(est, x, sd_multiple = 1) {
  if (inherits(x, "data.frame")) {
    warning("`standardise` needs a fitted model, not a data frame; ignoring it.",
            call. = FALSE)
    return(est)
  }
  sc <- input_scales(x, sd_multiple)
  if (is.null(sc)) {
    warning("Could not trace the model's coefficients to its inputs, so ",
            "`standardise` is ignored.", call. = FALSE)
    return(est)
  }
  hit <- match(est$term, names(sc$multiplier))
  mult <- unname(sc$multiplier[hit])
  mult[is.na(mult)] <- 1

  if (length(sc$matrix_inputs)) {
    message("`standardise` leaves matrix-valued terms unscaled: ",
            paste(sc$matrix_inputs, collapse = ", "), ". Their columns are ",
            "basis functions, not slopes per unit of one input.")
  }
  if (length(sc$uncentred_interactions)) {
    several <- length(sc$uncentred_interactions) > 1
    warning("`standardise`: ", paste(sc$uncentred_interactions, collapse = ", "),
            if (several) " are interactions" else " is an interaction",
            " of uncentred continuous inputs, so the main ",
            "effect of each is its slope where the others are zero. Centre the ",
            "inputs and refit for main effects at their means (Gelman, 2008).",
            call. = FALSE)
  }

  for (col in intersect(c("estimate", "conf.low", "conf.high", "std.error"),
                        names(est))) {
    est[[col]] <- est[[col]] * mult
  }
  attr(est, "contrasts_unscaled") <-
    any(est$term %in% sc$contrast_columns)
  est
}

#' Trace each model-matrix column to its inputs and their scaling multipliers
#'
#' Uses the `assign` attribute of the model matrix and the factors matrix of
#' the model's terms to find the inputs behind each column. Each input is then
#' classified in the model frame (the rows the fit used) as continuous,
#' contrast (factor, character, logical or at most two distinct values) or
#' matrix-valued. Returns `NULL` when any of the pieces is missing, so the
#' caller can refuse to guess.
#' @return A list with `multiplier` (named by column), `contrast_columns`,
#'   `matrix_inputs` and `uncentred_interactions`.
#' @noRd
input_scales <- function(x, sd_multiple) {
  mm <- tryCatch(stats::model.matrix(x), error = function(e) NULL)
  tt <- tryCatch(stats::terms(x), error = function(e) NULL)
  mf <- tryCatch(stats::model.frame(x), error = function(e) NULL)
  if (is.null(mm) || is.null(tt) || is.null(mf)) return(NULL)
  assign <- attr(mm, "assign")
  fac <- attr(tt, "factors")
  if (is.null(assign) || length(assign) != ncol(mm)) return(NULL)
  if (any(assign > 0) && (length(fac) == 0 || max(assign) > ncol(fac))) {
    return(NULL)
  }
  inputs_of <- function(a) rownames(fac)[fac[, a] > 0]
  used <- unique(unlist(lapply(unique(assign[assign > 0]), inputs_of)))
  if (!all(used %in% names(mf))) return(NULL)

  kind <- vapply(used, function(v) input_kind(mf[[v]]), character(1))
  scale <- vapply(used, function(v) {
    if (kind[[v]] == "continuous") {
      sd_multiple * stats::sd(as.numeric(mf[[v]]), na.rm = TRUE)
    } else {
      1
    }
  }, numeric(1))

  cols <- colnames(mm)
  multiplier <- stats::setNames(rep(1, length(cols)), cols)
  contrast <- logical(length(cols))
  for (i in seq_along(cols)) {
    if (assign[i] < 1) next
    vars <- inputs_of(assign[i])
    multiplier[i] <- prod(scale[vars])
    contrast[i] <- any(kind[vars] == "contrast")
  }

  # An interaction of two or more continuous inputs leaves each main effect
  # conditional on the others at zero. Centred inputs make that zero the mean,
  # which is Gelman's remedy, so only uncentred ones are reported.
  terms_used <- unique(assign[assign > 0])
  uncentred <- character(0)
  for (a in terms_used) {
    vars <- inputs_of(a)
    cont <- vars[kind[vars] == "continuous"]
    if (length(cont) < 2) next
    off_centre <- vapply(cont, function(v) {
      val <- as.numeric(mf[[v]])
      abs(mean(val, na.rm = TRUE)) >
        sqrt(.Machine$double.eps) * stats::sd(val, na.rm = TRUE)
    }, logical(1))
    if (any(off_centre)) uncentred <- c(uncentred, colnames(fac)[a])
  }

  list(multiplier = multiplier,
       contrast_columns = cols[contrast],
       matrix_inputs = used[kind == "matrix"],
       uncentred_interactions = uncentred)
}

#' Classify one model-frame input for standardise_estimates()
#' @noRd
input_kind <- function(v) {
  if (is.matrix(v)) {
    if (ncol(v) > 1) return("matrix")
    v <- v[, 1]
  }
  if (is.factor(v) || is.character(v) || is.logical(v)) return("contrast")
  values <- unique(as.numeric(v[!is.na(v)]))
  if (length(values) > 2) "continuous" else "contrast"
}

#' Axis label for standardised estimates
#'
#' Only the predictors are rescaled, so the label says per SD of predictor and
#' never "standardised estimate", which conventionally means a fully
#' standardised beta. It says so when contrasts were left in their own units.
#' @param stem What is drawn: "Estimate", or the name of a ratio from
#'   ratio_label().
#' @noRd
standardised_axis_label <- function(sd_multiple, contrasts_unscaled,
                                    stem = "Estimate") {
  per <- if (sd_multiple == 1) "SD" else paste(format(sd_multiple), "SD")
  paste0(stem, " per ", per, " of predictor",
         if (isTRUE(contrasts_unscaled)) " (contrasts unscaled)")
}

#' Name an exponentiated estimate by the model's family and link
#'
#' exp() of a logit coefficient is an odds ratio. exp() of a log-link
#' coefficient is a rate ratio in a Poisson, quasi-Poisson or negative
#' binomial model and a risk ratio in a binomial one. Anything else, a data
#' frame or an identity link among them, is "exp(Estimate)": exp() of an
#' lm(log(y) ~ x) slope, for one, is a ratio of geometric means. The family
#' of a MASS::glm.nb() or lme4::glmer.nb() fit is named "Negative
#' Binomial(theta)".
#' @noRd
ratio_label <- function(x) {
  neutral <- "exp(Estimate)"
  if (is.data.frame(x)) return(neutral)
  fam <- tryCatch(stats::family(x), error = function(e) NULL)
  family <- if (is.list(fam)) fam$family else NULL
  link <- if (is.list(fam)) fam$link else NULL
  if (!is.character(family) || !is.character(link) || length(family) != 1 ||
      length(link) != 1) {
    return(neutral)
  }
  if (link == "logit") return("Odds ratio")
  if (link == "log") {
    if (family %in% c("binomial", "quasibinomial")) return("Risk ratio")
    if (family %in% c("poisson", "quasipoisson") ||
        startsWith(family, "Negative Binomial")) {
      return("Rate ratio")
    }
  }
  neutral
}

#' Lay a forest plot out one term per row, each panel free-scaled
#'
#' Adds a one-column `facet_wrap()` over the term `label`, with a free x-axis so
#' every estimate is legible regardless of scale, and blanks the now-redundant
#' y-axis text (the term name moves to the strip). Shared by [coefficient_plot()],
#' [compare_models()] and (through it) [frequentist_bayesian_plot()].
#'
#' A reference line is drawn per panel, but only in the panels whose data range
#' actually brackets it. Drawing it everywhere would force a free-scaled panel
#' (for example a large intercept) to stretch back to the reference value,
#' re-introducing the very squish that faceting is meant to remove.
#'
#' @param p A ggplot whose data has a `label` column (term label) mapped to `y`
#'   and `conf.low`/`conf.high` (or `outer_lo`/`outer_hi`) interval columns.
#' @param reference_line Position of the per-panel reference line (`NA` to omit).
#' @param reference_colour Colour of the reference line. Defaults to the
#'   package-wide `reference` option so a faceted panel matches the shared-axis
#'   layout.
#' @noRd
add_term_facets <- function(p, reference_line = NA,
                            reference_colour = depictr_reference()) {
  out <- p +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$label),
      ncol = 1, scales = "free", strip.position = "top",
      labeller = ggplot2::label_wrap_gen(width = 28)
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.spacing.y = ggplot2::unit(2, "pt")
    )

  if (!is.na(reference_line)) {
    ref <- reference_line_panels(p$data, reference_line)
    if (nrow(ref)) {
      # geom_vline() never inherits the plot's aesthetics. Passing
      # inherit.aes = FALSE as well warns on ggplot2 3.5.x.
      out <- out + ggplot2::geom_vline(
        data = ref,
        ggplot2::aes(xintercept = .data$xintercept),
        linetype = 2, colour = reference_colour
      )
    }
  }
  out
}

#' Per-panel reference-line data: one row per term whose interval brackets it
#' @noRd
reference_line_panels <- function(df, reference_line) {
  lo_col <- if ("conf.low" %in% names(df)) "conf.low" else "outer_lo"
  hi_col <- if ("conf.high" %in% names(df)) "conf.high" else "outer_hi"
  lo <- tapply(df[[lo_col]], df$label, min, na.rm = TRUE)
  hi <- tapply(df[[hi_col]], df$label, max, na.rm = TRUE)
  keep <- is.finite(lo) & is.finite(hi) &
    reference_line >= lo & reference_line <= hi
  keep[is.na(keep)] <- FALSE
  if (!any(keep)) {
    return(data.frame(label = factor(character(0), levels = levels(df$label)),
                      xintercept = numeric(0)))
  }
  data.frame(
    label = factor(base::names(lo)[keep], levels = levels(df$label)),
    xintercept = reference_line,
    stringsAsFactors = FALSE
  )
}

#' @noRd
order_terms <- function(est, order) {
  if (order == "none") {
    est <- est[rev(seq_len(nrow(est))), , drop = FALSE]
  } else if (order == "ascending") {
    est <- est[order(est$estimate), , drop = FALSE]
  } else if (order == "descending") {
    est <- est[order(est$estimate, decreasing = TRUE), , drop = FALSE]
  }
  est
}

#' Warn when a named `labels` entry matches no term
#'
#' `make_labels()` drops an entry whose name is not a term, so a mistyped key
#' leaves the raw parameter name on the plot with nothing to say the relabelling
#' never happened. The check lives here rather than in `make_labels()` because
#' it must see the user's `labels` before `merge_pretty_labels()` folds in the
#' automatic factor-level keys (which include `b_`-prefixed variants that a
#' frequentist fit never has), and the complete term list, which several callers
#' reach only after labelling row by row.
#' @noRd
warn_unused_labels <- function(terms, labels) {
  if (is.null(labels) || is.null(names(labels))) return(invisible(NULL))
  terms <- unique(terms)
  unused <- setdiff(names(labels), terms)
  if (length(unused)) {
    warning("`labels` keys not found among the parameters: ",
            paste(sort(unused), collapse = ", "),
            ". The parameters are ", paste(terms, collapse = ", "), ".",
            call. = FALSE)
  }
  invisible(NULL)
}

#' Refuse an unnamed `labels` vector that is not one label per term
#'
#' Shared by [coefficient_plot()] and, through `key_labels_by_term()`, by
#' [compare_models()] and [frequentist_bayesian_plot()]. They count their terms
#' differently but report a mismatch in the same words. The message says the
#' order the vector is read in, and whether the intercept was dropped before
#' counting, so the user can check the count against the model.
#' @param n Number of terms the vector has to label.
#' @param owner Subject and verb of the message, "the model has" or "the
#'   models have".
#' @param read_in The order the vector is read in, for the message.
#' @param intercept_dropped Whether an intercept was dropped before counting.
#' @noRd
check_label_count <- function(labels, n, owner, read_in, intercept_dropped) {
  if (length(labels) == n) return(invisible(NULL))
  stop("`labels` has length ", length(labels), " but ", owner, " ", n,
       if (n == 1) " term" else " terms", " to label (", read_in,
       if (intercept_dropped) ", after dropping the intercept", ").",
       call. = FALSE)
}

#' Key an unnamed `labels` vector by term name, one label per row drawn
#'
#' [compare_models()] holds each term once per source, and the distribution
#' path of [frequentist_bayesian_plot()] holds it once per posterior draw.
#' Neither can match the vector to its rows by position. Terms that share a
#' default label, such as `stress` and brms's `b_stress`, are drawn on one row
#' and take one label. The vector is therefore matched to the distinct default
#' labels in the order the terms first appear, then keyed by raw term name for
#' `make_labels()`.
#' @param terms Raw term names left after the intercept rule, repeats
#'   included, in the order the vector is read in.
#' @param auto Automatic label map from `pretty_coef_map()`, or `NULL`.
#' @param intercept_dropped Whether an intercept was dropped before counting.
#' @noRd
key_labels_by_term <- function(labels, terms, auto, interaction,
                               intercept_dropped) {
  default <- make_labels(terms, auto, interaction)
  drawn <- unique(default)
  check_label_count(labels, length(drawn), "the models have",
                    "in the order they first appear", intercept_dropped)
  keyed <- stats::setNames(as.character(labels)[match(default, drawn)], terms)
  keyed[!duplicated(base::names(keyed))]
}

#' Build display labels for a set of terms
#' @noRd
make_labels <- function(terms, labels, interaction) {
  if (is.null(labels)) {
    return(format_terms(terms, interaction = interaction))
  }
  if (!is.null(names(labels))) {
    out <- labels[terms]
    out[is.na(out)] <- format_terms(terms[is.na(out)], interaction = interaction)
    return(unname(out))
  }
  if (length(labels) != length(terms)) {
    stop("`labels` has length ", length(labels), " but there are ",
         length(terms), " terms to label.", call. = FALSE)
  }
  labels
}
