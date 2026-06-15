# Kaplan-Meier survival plot -------------------------------------------------

#' Kaplan-Meier survival plot
#'
#' Draws Kaplan-Meier survival curves, optionally by group, with stepwise
#' confidence limits and censoring marks. The Kaplan-Meier estimate and its
#' Greenwood standard error are computed with base R, so no modelling package is
#' required; a `survfit` object from the 'survival' package is also accepted.
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
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels.
#'
#' @return A [ggplot2::ggplot] object.
#' @references
#' \insertRef{kaplan1958}{depictr}
#'
#' \insertRef{greenwood1926}{depictr}
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
survival_plot <- function(time, status = NULL, group = NULL, conf_level = 0.95,
                          censor_marks = TRUE, palette = NULL, title = NULL,
                          x_lab = "Time", y_lab = "Survival probability") {
  km <- km_input(time, status, group, conf_level)
  has_ci <- !is.na(conf_level) && all(c("lower", "upper") %in% names(km$curve))
  multi <- length(unique(km$curve$group)) > 1
  pal <- palette %||% depictr_palette(length(unique(km$curve$group)))

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

  if (multi) {
    p <- p + ggplot2::scale_colour_manual(values = pal, name = NULL)
  }

  p +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                                labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(x = x_lab, y = y_lab, title = title) +
    theme_depictr()
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
  for (g in groups) {
    sub <- gv == g
    out <- km_estimate(tv[sub], sv[sub], conf_level)
    # Assign group with rep() so a zero-row censor data frame is left untouched
    # (direct `$group <- g` errors when the frame has no rows).
    out$curve$group <- rep(g, nrow(out$curve))
    out$censor$group <- rep(g, nrow(out$censor))
    curves[[g]] <- out$curve
    censors[[g]] <- out$censor
  }
  list(curve = do.call(rbind, curves), censor = do.call(rbind, censors))
}

#' Base-R Kaplan-Meier estimate with Greenwood standard errors
#' @noRd
km_estimate <- function(time, status, conf_level) {
  keep <- !is.na(time) & !is.na(status)
  time <- time[keep]
  status <- normalise_status(status[keep])
  has_ci <- !is.na(conf_level)
  tmax <- if (length(time)) max(time) else 0

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
    return(list(curve = curve, censor = censor))
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
  list(curve = curve, censor = censor)
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
  for (g in grp_levels) {
    sel <- grp == g
    tt <- sf$time[sel]
    ss <- sf$surv[sel]
    ord <- order(tt)
    tt <- tt[ord]
    ss <- ss[ord]
    n_cens <- sf$n.censor[sel][ord]
    n_evt  <- sf$n.event[sel][ord]

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
  list(curve = curve, censor = censor)
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
