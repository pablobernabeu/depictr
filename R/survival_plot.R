# Kaplan-Meier survival plot -------------------------------------------------

#' Kaplan-Meier survival plot
#'
#' Draws Kaplan-Meier survival curves, optionally by group, with stepwise
#' confidence limits and censoring marks. The Kaplan-Meier estimate and its
#' Greenwood standard error are computed with base R, so no modelling package is
#' required; a `survfit` object from the 'survival' package is also accepted.
#'
#' For publication-ready figures the plot offers the three annotations that
#' define a "survminer-style" Kaplan-Meier display, each behind its own
#' argument and off by default so existing behaviour is unchanged:
#'
#' * **Number-at-risk table** (`risk_table = TRUE`): a small panel composed
#'   beneath the curves with 'patchwork', giving the number of subjects still at
#'   risk in each group at the x-axis breaks.
#' * **Median-survival guides** (`median_line = TRUE`): dashed reference lines
#'   from the 0.5 survival level down to each group's median survival time, with
#'   the median value labelled. Groups whose curve never reaches 0.5 (median not
#'   estimable) are skipped.
#' * **Log-rank test** (`logrank = TRUE`): for two or more groups, the
#'   chi-squared log-rank statistic and its p-value are added as a subtitle.
#'   [survival::survdiff()] is used when the 'survival' package is installed,
#'   otherwise an equivalent base-R log-rank test is computed from the
#'   risk/event tables.
#'
#' @param time A numeric vector of follow-up times, a data frame with `time`,
#'   `status` and optional `group` columns, or a `survfit` object.
#' @param status Event indicator when `time` is a vector. Either the 0/1
#'   convention (`0` = censored, `1` = event) or the [survival::Surv()] 1/2
#'   convention (`1` = censored, `2` = event) is accepted; logical values are
#'   also allowed. Other codings raise an error.
#' @param group Optional grouping variable (a vector, or a column name when
#'   `time` is a data frame).
#' @param conf_level Confidence level for the limits (`NA` to omit them).
#' @param censor_marks Whether to mark censoring times with a `+`.
#' @param risk_table Whether to add a number-at-risk table beneath the curves
#'   (composed with 'patchwork'). Defaults to `FALSE`.
#' @param median_line Whether to draw dashed guides to each group's median
#'   survival time and label it. Defaults to `FALSE`.
#' @param logrank Whether to add a log-rank test of the group difference as a
#'   subtitle (two or more groups only). Defaults to `FALSE`.
#' @param risk_breaks Optional numeric vector of times at which to report the
#'   number at risk. Defaults to the curve's x-axis breaks.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param legend_inside When `TRUE` (and there are several groups), draw the
#'   group legend inside the panel -- in the bottom-left corner a
#'   monotone-decreasing survival curve always leaves empty -- over a translucent
#'   background, instead of in a right-hand margin. Defaults to `FALSE`.
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object, or - when `risk_table = TRUE` - a
#'   'patchwork' object stacking the curves above the risk table.
#' @references
#' \insertRef{kaplan1958}{depictr}
#'
#' \insertRef{greenwood1926}{depictr}
#'
#' The log-rank test follows Mantel (1966).
#' @export
#' @examples
#' set.seed(1)
#' n <- 200
#' grp <- sample(c("control", "treated"), n, replace = TRUE)
#' time <- rexp(n, rate = ifelse(grp == "treated", 0.05, 0.1))
#' cens <- runif(n, 0, 30)
#' obs  <- pmin(time, cens)
#' event <- as.integer(time <= cens)
#' survival_plot(obs, event, group = grp, title = "Survival by treatment")
#'
#' # survminer-style figure: risk table, median guides and a log-rank test
#' data(clinical_trial)
#' survival_plot(clinical_trial$time, clinical_trial$event,
#'               group = clinical_trial$arm, risk_table = TRUE,
#'               median_line = TRUE, logrank = TRUE,
#'               x_lab = "Months", title = "Overall survival")
survival_plot <- function(time, status = NULL, group = NULL, conf_level = 0.95,
                          censor_marks = TRUE, risk_table = FALSE,
                          median_line = FALSE, logrank = FALSE,
                          risk_breaks = NULL, palette = NULL,
                          legend_inside = FALSE, title = NULL,
                          x_lab = "Time", y_lab = "Survival probability") {
  km <- km_input(time, status, group, conf_level)
  has_ci <- !is.na(conf_level) && all(c("lower", "upper") %in% names(km$curve))
  groups <- unique(km$curve$group)
  multi <- length(groups) > 1
  pal <- palette %||% depictr_palette(length(groups))
  # Stable group -> colour map shared by the curve and the risk table.
  col_map <- stats::setNames(pal[seq_along(groups)], groups)

  aes_main <- if (multi) {
    ggplot2::aes(x = .data$time, y = .data$surv, colour = .data$group)
  } else {
    ggplot2::aes(x = .data$time, y = .data$surv)
  }
  p <- ggplot2::ggplot(km$curve, aes_main)

  if (has_ci) {
    p <- p +
      ggplot2::geom_step(ggplot2::aes(y = .data$lower), linetype = 3,
                         linewidth = 0.4, na.rm = TRUE) +
      ggplot2::geom_step(ggplot2::aes(y = .data$upper), linetype = 3,
                         linewidth = 0.4, na.rm = TRUE)
  }
  p <- p + ggplot2::geom_step(linewidth = 0.9, na.rm = TRUE)

  if (censor_marks && nrow(km$censor) > 0) {
    cens_aes <- if (multi) {
      ggplot2::aes(x = .data$time, y = .data$surv, colour = .data$group)
    } else {
      ggplot2::aes(x = .data$time, y = .data$surv)
    }
    p <- p + ggplot2::geom_point(data = km$censor, cens_aes, shape = 3,
                                 size = 2, na.rm = TRUE)
  }

  # ---- median-survival guides --------------------------------------------
  medians <- km_medians(km$curve, groups)
  if (median_line) {
    p <- add_median_guides(p, medians, multi, col_map)
  }

  # ---- log-rank subtitle --------------------------------------------------
  subtitle <- NULL
  if (logrank && multi) {
    subtitle <- logrank_label(km$counts)
  }

  if (multi) {
    p <- p + ggplot2::scale_colour_manual(values = col_map, name = NULL)
  }

  p <- p +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                                labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title, subtitle = subtitle) +
    theme_depictr() +
    # The y tick labels are short percentages, so tighten the gap between them
    # and the axis title.
    ggplot2::theme(axis.title.y = ggplot2::element_text(
      margin = ggplot2::margin(r = 2)))

  # A monotone-decreasing survival curve always leaves the bottom-left empty;
  # when asked, tuck the group legend there rather than spending a whole column
  # on it beside the plot.
  if (legend_inside && multi) {
    p <- p + legend_inside_theme(c(0.015, 0.04), c(0, 0))
  }

  if (!risk_table) return(p)

  # ---- number-at-risk table, composed beneath the curves -----------------
  breaks <- risk_breaks %||% risk_break_default(km$curve$time)
  natrisk <- n_at_risk(km$counts, breaks)
  tbl <- risk_table_plot(natrisk, breaks, col_map, multi, x_lab)

  # Share the x-scale between the two panels so the columns line up with the
  # curve, and drop the curve's own x-axis (the table carries it).
  xr <- range(c(0, km$curve$time, breaks), na.rm = TRUE)
  p <- p +
    ggplot2::scale_x_continuous(limits = xr, breaks = breaks) +
    ggplot2::theme(axis.title.x = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_blank(),
                   plot.margin = ggplot2::margin(10, 12, 2, 12))
  tbl <- tbl + ggplot2::scale_x_continuous(limits = xr, breaks = breaks)

  patchwork::wrap_plots(p, tbl, ncol = 1, heights = c(4, 1))
}

# ---- internal helpers ------------------------------------------------------

#' Build Kaplan-Meier curve and censoring data from flexible input
#' @noRd
km_input <- function(time, status, group, conf_level) {
  if (inherits(time, "survfit")) return(km_from_survfit(time, conf_level))

  if (is.data.frame(time)) {
    df <- time
    tcol <- intersect(c("time", "obs", "follow_up"), names(df))[1]
    scol <- intersect(c("status", "event"), names(df))[1]
    gcol <- intersect(c("group", "strata", "arm"), names(df))[1]
    if (is.na(tcol) || is.na(scol)) {
      stop("A data frame needs `time` and `status` columns.", call. = FALSE)
    }
    tv <- df[[tcol]]
    sv <- df[[scol]]
    gv <- if (!is.na(gcol)) df[[gcol]] else NULL
  } else {
    if (is.null(status)) stop("Supply `status` with the times.", call. = FALSE)
    tv <- time
    sv <- status
    gv <- group
  }
  gv <- if (is.null(gv)) rep("all", length(tv)) else as.character(gv)

  groups <- unique(gv)
  curves <- list()
  censors <- list()
  counts <- list()
  for (g in groups) {
    sub <- gv == g
    out <- km_estimate(tv[sub], sv[sub], conf_level)
    # Assign group with rep() so a zero-row censor data frame is left untouched
    # (direct `$group <- g` errors when the frame has no rows).
    out$curve$group <- rep(g, nrow(out$curve))
    out$censor$group <- rep(g, nrow(out$censor))
    curves[[g]] <- out$curve
    censors[[g]] <- out$censor
    counts[[g]] <- out$counts
  }
  list(curve = do.call(rbind, curves), censor = do.call(rbind, censors),
       counts = counts)
}

#' Base-R Kaplan-Meier estimate with Greenwood standard errors
#' @noRd
km_estimate <- function(time, status, conf_level) {
  keep <- !is.na(time) & !is.na(status)
  time <- time[keep]
  status <- normalise_status(status[keep])
  has_ci <- !is.na(conf_level)
  n_obs <- length(time)
  tmax <- if (n_obs) max(time) else 0

  ut <- sort(unique(time[status == 1]))
  if (length(ut) == 0) {
    # All censored (or no data): a flat line at surv = 1 extended to the last
    # follow-up time, like survival::plot.survfit. Keep the column layout in
    # step with the event case so groups can be row-bound together.
    curve <- data.frame(time = unique(c(0, tmax)), surv = 1)
    if (has_ci) {
      curve$lower <- 1
      curve$upper <- 1
    }
    censor <- censor_marks_df(sort(time[status == 0]), ut, numeric(0))
    counts <- list(time = numeric(0), n_risk = numeric(0),
                   n_event = numeric(0), n = n_obs, tmax = tmax,
                   all_time = time, all_status = status)
    return(list(curve = curve, censor = censor, counts = counts))
  }
  n_risk  <- vapply(ut, function(t) sum(time >= t), numeric(1))
  n_event <- vapply(ut, function(t) sum(time == t & status == 1), numeric(1))
  surv <- cumprod(1 - n_event / n_risk)

  curve <- data.frame(time = c(0, ut), surv = c(1, surv))
  if (has_ci) {
    cum <- cumsum(n_event / (n_risk * (n_risk - n_event)))
    se <- surv * sqrt(cum)
    z <- stats::qnorm(1 - (1 - conf_level) / 2)
    curve$lower <- c(1, pmax(0, surv - z * se))
    curve$upper <- c(1, pmin(1, surv + z * se))
  }

  # Extend the flat step to the last follow-up time when censoring continues
  # past the final event (survival::plot.survfit does the same).
  if (tmax > ut[length(ut)]) {
    tail_row <- curve[nrow(curve), , drop = FALSE]
    tail_row$time <- tmax
    curve <- rbind(curve, tail_row)
  }

  # Censoring marks: survival level at each censoring time
  censor <- censor_marks_df(sort(time[status == 0]), ut, surv)
  # Per-event-time risk/event counts feed the at-risk table and log-rank test.
  counts <- list(time = ut, n_risk = n_risk, n_event = n_event,
                 n = n_obs, tmax = tmax, all_time = time, all_status = status)
  list(curve = curve, censor = censor, counts = counts)
}

#' Coerce an event-status vector to the 0/1 convention used internally
#'
#' Accepts logical values and the two common numeric encodings: 0/1
#' (0 = censored, 1 = event) and the [survival::Surv()] 1/2 convention
#' (1 = censored, 2 = event). Anything else is an error.
#' @noRd
normalise_status <- function(status) {
  if (is.logical(status)) return(as.integer(status))
  status <- as.integer(status)
  vals <- unique(status[!is.na(status)])
  if (length(vals) == 0) return(status)
  if (all(vals %in% c(0L, 1L))) {
    status
  } else if (all(vals %in% c(1L, 2L))) {
    status - 1L
  } else {
    stop("`status` must use the 0/1 (0 = censored) or 1/2 ",
         "(1 = censored) coding.", call. = FALSE)
  }
}

#' Survival level at each censoring time, as a (possibly empty) data frame
#' @noRd
censor_marks_df <- function(ct, ut, surv) {
  if (!length(ct)) return(empty_censor())
  sl <- vapply(ct, function(t) {
    idx <- sum(ut <= t)
    if (idx == 0) 1 else surv[idx]
  }, numeric(1))
  data.frame(time = ct, surv = sl)
}

#' @noRd
empty_censor <- function() data.frame(time = numeric(0), surv = numeric(0))

#' @noRd
km_from_survfit <- function(sf, conf_level) {
  # Use the survfit components directly rather than summary(): the latter drops
  # pure-censoring time rows, so the censoring marks and the flat tail would be
  # lost. This keeps the survfit path consistent with the vector/data-frame one
  # (origin row at time 0, censoring marks, extension to last follow-up).
  has_ci <- !is.na(conf_level) && !is.null(sf$lower)
  if (!is.null(sf$strata)) {
    grp_levels <- names(sf$strata)
    grp <- rep(grp_levels, times = sf$strata)
  } else {
    grp_levels <- "all"
    grp <- rep("all", length(sf$time))
  }

  curves <- list()
  censors <- list()
  counts <- list()
  for (g in grp_levels) {
    sel <- grp == g
    tt <- sf$time[sel]
    ss <- sf$surv[sel]
    ord <- order(tt)
    tt <- tt[ord]
    ss <- ss[ord]
    n_cens <- sf$n.censor[sel][ord]
    n_evt  <- sf$n.event[sel][ord]
    n_rsk  <- sf$n.risk[sel][ord]

    # Two views of the risk process. `time`/`n_risk`/`n_event` are restricted
    # to the distinct event times (survfit already tabulates ties) and drive the
    # base-R log-rank fallback. `risk_time`/`risk_n` keep the full step over all
    # reported times - including censoring times - so the number-at-risk table
    # is exact at arbitrary break points (the event-time view alone misses
    # subjects censored between events).
    ev <- n_evt > 0
    counts[[g]] <- list(time = tt[ev], n_risk = n_rsk[ev],
                        n_event = n_evt[ev],
                        risk_time = tt, risk_n = n_rsk,
                        n = if (length(n_rsk)) n_rsk[1] else 0,
                        tmax = if (length(tt)) max(tt) else 0,
                        all_time = NULL)

    # Build the step curve, prepending the (time = 0, surv = 1) origin.
    curve <- data.frame(time = c(0, tt), surv = c(1, ss),
                        group = rep(g, length(tt) + 1L))
    if (has_ci) {
      lo <- sf$lower[sel][ord]
      up <- sf$upper[sel][ord]
      # survfit reports NA limits at points with no events (e.g. tail rows);
      # carry the step forward so the band is drawn continuously.
      lo <- fill_forward(lo, 1)
      up <- fill_forward(up, 1)
      curve$lower <- c(1, lo)
      curve$upper <- c(1, up)
    }
    curves[[g]] <- curve

    # Censoring marks at the survival level current at each censoring time.
    ct <- tt[n_cens > 0]
    if (length(ct)) {
      # surv just after each event; for censoring marks use the level at that t.
      sl <- ss[n_cens > 0]
      cnt <- n_cens[n_cens > 0]
      censors[[g]] <- data.frame(time = rep(ct, cnt), surv = rep(sl, cnt),
                                 group = rep(g, sum(cnt)))
    }
  }

  curve <- do.call(rbind, curves)
  censor <- if (length(censors)) do.call(rbind, censors) else empty_censor()
  list(curve = curve, censor = censor, counts = counts)
}

#' Replace leading/internal NAs by carrying the previous value forward
#' @noRd
fill_forward <- function(x, init) {
  last <- init
  for (i in seq_along(x)) {
    if (is.na(x[i])) x[i] <- last else last <- x[i]
  }
  x
}

# ---- median survival -------------------------------------------------------

#' Median survival time per group from the step curve
#'
#' Matches the interpolated convention of [survival::quantile.survfit()]: the
#' median is the smallest time at which the survival estimate first drops below
#' 0.5; but when the curve lands *exactly* on 0.5 and stays flat there, the
#' median is the midpoint of that flat segment (the average of the time it
#' reaches 0.5 and the next time point on the curve - an event or the last
#' follow-up). `NA` when the curve never reaches 0.5, or reaches exactly 0.5 and
#' stays there with no later time (median not estimable).
#' @noRd
km_medians <- function(curve, groups) {
  out <- lapply(groups, function(g) {
    sub <- curve[curve$group == g, , drop = FALSE]
    sub <- sub[order(sub$time), , drop = FALSE]
    idx <- which(sub$surv <= 0.5)
    if (!length(idx)) {
      med <- NA_real_
    } else {
      i <- idx[1]
      if (sub$surv[i] < 0.5) {
        med <- sub$time[i]                 # curve jumped strictly below 0.5
      } else if (i < nrow(sub)) {
        med <- (sub$time[i] + sub$time[i + 1]) / 2  # flat at 0.5: interpolate
      } else {
        med <- NA_real_                    # ends exactly at 0.5: not estimable
      }
    }
    data.frame(group = g, median = med, stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

#' Add dashed guides from surv = 0.5 to each estimable median, plus labels
#' @noRd
add_median_guides <- function(p, medians, multi, col_map) {
  est <- medians[!is.na(medians$median), , drop = FALSE]
  if (nrow(est) == 0) return(p)
  ref <- depictr_reference()

  # Horizontal guide at the 0.5 survival level, drawn once.
  p <- p + ggplot2::geom_hline(yintercept = 0.5, linetype = 2,
                               colour = ref, linewidth = 0.4)
  # Vertical guides down to each median time.
  seg <- data.frame(x = est$median, group = est$group)
  if (multi) {
    p <- p + ggplot2::geom_segment(
      data = seg,
      ggplot2::aes(x = .data$x, xend = .data$x, y = 0, yend = 0.5,
                   colour = .data$group),
      linetype = 2, linewidth = 0.4, inherit.aes = FALSE, show.legend = FALSE
    )
  } else {
    p <- p + ggplot2::geom_segment(
      data = seg,
      ggplot2::aes(x = .data$x, xend = .data$x, y = 0, yend = 0.5),
      linetype = 2, linewidth = 0.4, colour = ref, inherit.aes = FALSE
    )
  }
  # Label each median value just above the x-axis at the crossing time, naming
  # it "median" so the dashed drop-line is unambiguous.
  lab <- data.frame(x = est$median, group = est$group,
                    label = paste0("median ", format_median(est$median)))
  if (multi) {
    p <- p + ggplot2::geom_text(
      data = lab,
      ggplot2::aes(x = .data$x, y = 0.04, label = .data$label,
                   colour = .data$group),
      hjust = -0.1, vjust = 0, size = 3, fontface = "bold",
      inherit.aes = FALSE, show.legend = FALSE
    )
  } else {
    p <- p + ggplot2::geom_text(
      data = lab,
      ggplot2::aes(x = .data$x, y = 0.04, label = .data$label),
      hjust = -0.1, vjust = 0, size = 3, fontface = "bold",
      colour = depictr_brand(), inherit.aes = FALSE
    )
  }
  p
}

#' @noRd
format_median <- function(x) {
  formatC(x, digits = 3, format = "g")
}

# ---- number at risk --------------------------------------------------------

#' Sensible default risk-table break times spanning `[0, max time]`
#' @noRd
risk_break_default <- function(time) {
  tmax <- max(time, na.rm = TRUE)
  if (!is.finite(tmax) || tmax <= 0) return(0)
  br <- pretty(c(0, tmax), n = 6)
  br[br >= 0 & br <= tmax]
}

#' Number of subjects at risk in each group at the requested times
#'
#' The number at risk at time `t` is the count with follow-up time \eqn{>= t}
#' (the standard convention used by [survival::summary.survfit()] with
#' `times =`). When the raw follow-up times are available (`all_time`) they are
#' counted directly; for the survfit path, where only the tabulated risk set at
#' event times is kept, the at-risk count is the risk set carried back from the
#' first event time at or after `t`.
#' @noRd
n_at_risk <- function(counts, breaks) {
  groups <- names(counts)
  rows <- lapply(groups, function(g) {
    ct <- counts[[g]]
    nr <- vapply(breaks, function(t) risk_at(ct, t), numeric(1))
    data.frame(group = g, time = breaks, n_risk = nr,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' Number at risk at a single time `t` for one group's count structure
#' @noRd
risk_at <- function(ct, t) {
  if (!is.null(ct$all_time)) {
    return(sum(ct$all_time >= t))
  }
  # survfit path. The risk set is a left-continuous step changing only at
  # reported times (events and censorings); the number at risk at time t equals
  # the risk set of the earliest reported time >= t. After the last reported
  # time everyone has left the risk set, so 0.
  rt <- ct$risk_time
  if (is.null(rt) || length(rt) == 0) return(0)
  idx <- which(rt >= t)
  if (length(idx)) ct$risk_n[idx[1]] else 0
}

#' A compact at-risk table as a ggplot, to be stacked under the curves
#' @noRd
risk_table_plot <- function(natrisk, breaks, col_map, multi, x_lab) {
  groups <- names(col_map)
  # Order rows top-to-bottom in the legend/group order.
  natrisk$group <- factor(natrisk$group, levels = rev(groups))
  y_lab <- if (multi) NULL else "At risk"

  p <- ggplot2::ggplot(
    natrisk,
    ggplot2::aes(x = .data$time, y = .data$group, label = .data$n_risk)
  )
  if (multi) {
    p <- p + ggplot2::geom_text(ggplot2::aes(colour = .data$group),
                                size = 3, show.legend = FALSE) +
      ggplot2::scale_colour_manual(values = col_map)
  } else {
    p <- p + ggplot2::geom_text(size = 3, colour = depictr_brand())
  }
  p +
    ggplot2::labs(x = x_lab, y = y_lab, title = "Number at risk") +
    theme_depictr(grid = "none") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = ggplot2::rel(0.9), hjust = 0,
                                         face = "bold", colour = "grey30"),
      axis.text.y = ggplot2::element_text(hjust = 0),
      plot.margin = ggplot2::margin(2, 12, 8, 12)
    )
}

# ---- log-rank test ---------------------------------------------------------

#' Log-rank test of the group difference, returning chi-squared, df and p
#'
#' Uses [survival::survdiff()] when the 'survival' package is available, and
#' otherwise an equivalent base-R Mantel-Haenszel log-rank test computed from
#' the per-group risk/event tables already carried on each curve.
#' @noRd
logrank_test <- function(counts) {
  groups <- names(counts)
  if (length(groups) < 2) return(NULL)

  # Prefer survival::survdiff() when the raw (time, status) are available - i.e.
  # the vector/data-frame path, which keeps `all_time`/`all_status`. The survfit
  # path keeps only the tabulated risk sets and falls through to base_logrank().
  have_raw <- all(vapply(counts, function(ct) !is.null(ct$all_status),
                         logical(1)))
  if (have_raw && requireNamespace("survival", quietly = TRUE)) {
    df <- do.call(rbind, lapply(groups, function(g) {
      ct <- counts[[g]]
      data.frame(time = ct$all_time, status = ct$all_status, group = g,
                 stringsAsFactors = FALSE)
    }))
    sd <- survival::survdiff(survival::Surv(df$time, df$status) ~ df$group)
    dfree <- length(sd$n) - 1
    return(list(chisq = unname(sd$chisq), df = dfree,
                p = stats::pchisq(sd$chisq, dfree, lower.tail = FALSE),
                method = "survival::survdiff"))
  }

  base_logrank(counts)
}

#' Base-R Mantel-Haenszel / log-rank statistic from per-group count tables
#'
#' At every distinct event time the observed events per group are compared with
#' their expectation under the null (no group difference), pooling the risk
#' sets. The statistic is \eqn{(O - E)' V^{-} (O - E)} with the standard
#' hypergeometric variance-covariance \eqn{V}; it is chi-squared on
#' (groups - 1) degrees of freedom (Mantel, 1966).
#' @noRd
base_logrank <- function(counts) {
  groups <- names(counts)
  k <- length(groups)
  # Pool over the union of event times.
  all_times <- sort(unique(unlist(lapply(counts, function(ct) ct$time))))
  if (length(all_times) == 0) return(NULL)

  # Per-time, per-group risk set: number with follow-up >= t. The survfit path
  # keeps risk sets only at event times, so reuse risk_at() for consistency.
  O <- numeric(k)            # observed events per group
  E <- numeric(k)            # expected events per group
  V <- matrix(0, k, k)       # variance-covariance
  for (t in all_times) {
    nj <- vapply(counts, function(ct) risk_at(ct, t), numeric(1))   # at risk
    dj <- vapply(counts, function(ct) {
      i <- match(t, ct$time)
      if (is.na(i)) 0 else ct$n_event[i]
    }, numeric(1))
    n <- sum(nj)
    d <- sum(dj)
    if (n <= 1 || d == 0) next
    O <- O + dj
    E <- E + d * nj / n
    # Hypergeometric variance of events; covariance across groups.
    fac <- d * (n - d) / (n - 1)
    p <- nj / n
    Vt <- fac * (diag(p, k) - outer(p, p))
    V <- V + Vt
  }
  OE <- O - E
  # Drop the last group to make V full rank (df = k - 1), then quadratic form.
  idx <- seq_len(k - 1)
  Vr <- V[idx, idx, drop = FALSE]
  chisq <- tryCatch(
    as.numeric(t(OE[idx]) %*% solve(Vr, OE[idx])),
    error = function(e) NA_real_
  )
  dfree <- k - 1
  list(chisq = chisq, df = dfree,
       p = stats::pchisq(chisq, dfree, lower.tail = FALSE),
       method = "base-R log-rank")
}

#' A short subtitle reporting the log-rank chi-squared and p-value
#'
#' Returns a plotmath expression so the statistic renders as a proper
#' chi-squared symbol and the p is italic, with no reliance on a Unicode glyph
#' (which fails on some Windows mbcs devices).
#' @noRd
logrank_label <- function(counts) {
  res <- logrank_test(counts)
  if (is.null(res) || is.na(res$chisq)) return(NULL)
  chi <- formatC(res$chisq, digits = 3, format = "g")
  if (res$p < 1e-4) {
    bquote("Log-rank " * chi^2 * "(" * .(res$df) * ") = " * .(chi) *
             ", " * italic(p) * " < 0.0001")
  } else {
    pv <- formatC(res$p, digits = 3, format = "g")
    bquote("Log-rank " * chi^2 * "(" * .(res$df) * ") = " * .(chi) *
             ", " * italic(p) * " = " * .(pv))
  }
}
