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
#' @param status Event indicator (1 = event, 0 = censored) when `time` is a
#'   vector.
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
    out$curve$group <- g
    out$censor$group <- g
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
  status <- as.integer(status[keep])
  ut <- sort(unique(time[status == 1]))
  if (length(ut) == 0) {
    curve <- data.frame(time = 0, surv = 1, lower = 1, upper = 1)
    return(list(curve = curve, censor = empty_censor()))
  }
  n_risk  <- vapply(ut, function(t) sum(time >= t), numeric(1))
  n_event <- vapply(ut, function(t) sum(time == t & status == 1), numeric(1))
  surv <- cumprod(1 - n_event / n_risk)

  curve <- data.frame(time = c(0, ut), surv = c(1, surv))
  if (!is.na(conf_level)) {
    cum <- cumsum(n_event / (n_risk * (n_risk - n_event)))
    se <- surv * sqrt(cum)
    z <- stats::qnorm(1 - (1 - conf_level) / 2)
    curve$lower <- c(1, pmax(0, surv - z * se))
    curve$upper <- c(1, pmin(1, surv + z * se))
  }

  # Censoring marks: survival level at each censoring time
  ct <- sort(time[status == 0])
  if (length(ct)) {
    sl <- vapply(ct, function(t) {
      idx <- sum(ut <= t)
      if (idx == 0) 1 else surv[idx]
    }, numeric(1))
    censor <- data.frame(time = ct, surv = sl)
  } else {
    censor <- empty_censor()
  }
  list(curve = curve, censor = censor)
}

#' @noRd
empty_censor <- function() data.frame(time = numeric(0), surv = numeric(0))

#' @noRd
km_from_survfit <- function(sf, conf_level) {
  s <- summary(sf)
  grp <- if (!is.null(s$strata)) as.character(s$strata) else "all"
  curve <- data.frame(time = s$time, surv = s$surv, group = grp)
  if (!is.null(s$lower)) {
    curve$lower <- s$lower
    curve$upper <- s$upper
  }
  list(curve = curve, censor = empty_censor())
}
