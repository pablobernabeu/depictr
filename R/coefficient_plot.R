# Forest / coefficient plot --------------------------------------------------

#' Forest (coefficient) plot
#'
#' Draws a horizontal point-and-interval ("forest") plot of model estimates.
#' The input can be a fitted model (anything [tidy_estimates()] understands) or
#' a data frame of pre-computed estimates.
#'
#' @param x A fitted model or a tidy data frame of estimates.
#' @param conf_level Confidence/credible level, passed to [tidy_estimates()]
#'   when `x` is a model.
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
#'   `c(soil_ph = "Soil pH")`, is safer. If `NULL`, names are tidied with
#'   [format_terms()].
#' @param interaction Passed to [format_terms()] to control how interaction
#'   terms are rendered (ignored when `labels` is supplied).
#' @param point_colour,reference_colour Colours for the estimates and the
#'   reference line.
#' @param reference_line Position of a vertical reference line (e.g. `0` for
#'   differences, `1` for odds/risk ratios). Use `NA` to omit it.
#' @param point_size,line_size Size of the points and interval lines.
#' @param facet Whether to give each term its own panel with a free x-axis,
#'   laid out one per row. This removes the squish that occurs when terms live
#'   on very different scales (for example a large intercept alongside small
#'   slopes). Defaults to `FALSE`, preserving the shared-axis layout. A
#'   convenience alias for `scales = "free"`.
#' @param scales Either `"fixed"` (the default, a single shared x-axis) or
#'   `"free"` (one free-scaled panel per term). When `facet = TRUE` this is
#'   forced to `"free"`.
#' @param standardise Whether to standardise the coefficients by multiplying
#'   each by the standard deviation of its predictor column, putting them on a
#'   common scale so their magnitudes are comparable (and removing the empty
#'   band that otherwise appears when predictors are on very different scales).
#'   Requires a fitted model (ignored, with a warning, for a tidy data frame).
#'   Defaults to `FALSE`.
#' @param title,subtitle,x_lab Plot title, subtitle and x-axis label. `x_lab`
#'   defaults to "Estimate", or "Estimate per SD of predictor" when
#'   `standardise`. The label names the convention on the figure itself,
#'   because only the predictors are rescaled here: a fully standardised beta
#'   would rescale the outcome too.
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
#' # Or put the coefficients on a common, comparable scale:
#' coefficient_plot(fit, standardise = TRUE)
coefficient_plot <- function(x,
                      conf_level = 0.95,
                      intercept = FALSE,
                      order = c("none", "ascending", "descending"),
                      labels = NULL,
                      interaction = c("times", "asterisk", "colon", "space"),
                      point_colour = depictr_brand(),
                      reference_colour = depictr_reference(),
                      reference_line = 0,
                      point_size = 2.2,
                      line_size = 0.7,
                      facet = FALSE,
                      scales = c("fixed", "free"),
                      standardise = FALSE,
                      title = NULL,
                      subtitle = NULL,
                      x_lab = NULL) {
  order <- match.arg(order)
  interaction <- match.arg(interaction)
  scales <- match.arg(scales)
  if (facet) scales <- "free"

  est <- tidy_estimates(x, conf_level = conf_level)

  # Optionally put every coefficient on a common, comparable scale by
  # multiplying it (and its interval) by the standard deviation of its
  # predictor column. This removes the dead band that appears when, say, a
  # per-mm rainfall slope sits next to a per-category treatment effect.
  if (standardise) {
    est <- standardise_estimates(est, x)
  }
  # Name the convention on the axis: only the predictors are rescaled, so
  # "standardised estimate" would promise the fully standardised beta that the
  # reader of a travelling figure would reasonably assume it meant.
  x_lab <- x_lab %||%
    if (standardise) "Estimate per SD of predictor" else "Estimate"

  # Prettify coefficient names to the effect (variable) name by default
  # (e.g. "conditionunrelated" -> "condition"); user `labels` take precedence.
  warn_unused_labels(est$term, labels)
  labels <- merge_pretty_labels(labels, pretty_coef_map(x))

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

  if (scales == "free") {
    p <- add_term_facets(p, reference_line = reference_line,
                         reference_colour = reference_colour)
  }

  p
}

# ---- internal helpers ------------------------------------------------------

#' Build a raw-name -> readable-effect-name map for a model's factor terms
#'
#' Turns the design-matrix names that R produces for factor levels (e.g.
#' `conditionunrelated`) into the readable *effect* (variable) name
#' (`condition`). For a two-level factor the single coefficient is named by its
#' variable alone; the contrast against the implicit reference level is
#' understood, so the level is not repeated. A factor with several non-reference
#' levels keeps the level too (`region: South`) so the rows stay distinct. Each
#' entry is also keyed under a `b_` prefix so a brms summary term aligns with its
#' frequentist counterpart. Continuous terms and interactions are left to
#' [format_terms()] (which tidies them and shows underscores as spaces).
#' Returns a named character vector, or `NULL` when `x` is not a supported model.
#' @noRd
pretty_coef_map <- function(x) {
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
  nice <- function(s) gsub("_", " ", s, fixed = TRUE)
  out <- character(0)
  for (i in seq_along(cols)) {
    a <- assign[i]
    if (a < 1 || a > length(tl)) next                 # intercept / unknown
    term <- tl[a]
    if (grepl(":", term, fixed = TRUE)) next          # interactions: format_terms
    col <- cols[i]
    if (startsWith(col, term) && nchar(col) > nchar(term)) {
      # Factor level column: name it by the variable alone for a two-level
      # factor, or "variable: level" when several levels share the variable.
      val <- if (sum(assign == a) == 1L) {
        nice(term)
      } else {
        nice(paste0(term, ": ", substring(col, nchar(term) + 1L)))
      }
      out[col] <- val
      out[paste0("b_", col)] <- val   # align a brms b_-prefixed summary term
    }
    # Continuous terms (col == term) are left to format_terms(), which also
    # handles their b_-prefixed Bayesian counterparts, so the two still align.
  }
  if (length(out)) out else NULL
}

#' Merge an auto term-label map under any user-supplied labels (user wins)
#' @noRd
merge_pretty_labels <- function(user, auto) {
  if (is.null(auto)) return(user)
  if (is.null(user)) return(auto)
  if (is.null(names(user))) return(user)   # positional labels: respect as given
  c(user, auto[setdiff(names(auto), names(user))])
}

#' Standardise estimates by the SD of each predictor column
#'
#' Multiplies each estimate and its interval by the standard deviation of the
#' matching model-matrix column, giving x-standardised coefficients on a common
#' scale. Terms with no matching column (or the intercept, whose column has SD
#' 0) are left unscaled. Needs a fitted model; warns and returns `est` unchanged
#' for a data-frame input.
#' @noRd
standardise_estimates <- function(est, x) {
  if (inherits(x, "data.frame")) {
    warning("`standardise` needs a fitted model, not a data frame; ignoring it.",
            call. = FALSE)
    return(est)
  }
  mm <- tryCatch(stats::model.matrix(x), error = function(e) NULL)
  if (is.null(mm)) {
    warning("Could not obtain the model matrix; `standardise` ignored.",
            call. = FALSE)
    return(est)
  }
  sds <- apply(mm, 2, stats::sd)
  sc <- sds[match(est$term, colnames(mm))]
  sc[is.na(sc)] <- 1
  sc[est$term %in% c("(Intercept)", "Intercept", "b_Intercept")] <- 1
  for (col in intersect(c("estimate", "conf.low", "conf.high", "std.error"),
                        names(est))) {
    est[[col]] <- est[[col]] * sc
  }
  est
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
      out <- out + ggplot2::geom_vline(
        data = ref,
        ggplot2::aes(xintercept = .data$xintercept),
        linetype = 2, colour = reference_colour, inherit.aes = FALSE
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
