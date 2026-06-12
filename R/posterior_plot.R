# Posterior intervals --------------------------------------------------------

#' Plot posterior distributions and intervals
#'
#' Summarises posterior (or, more generally, bootstrap or simulation) draws as a
#' point with two nested credible intervals, in the classic "half-eye" style of
#' uncertainty display. Draws may be supplied in long form (a parameter column
#' and a value column) or wide form (one column of draws per parameter), so the
#' function works with the output of any sampler and depends on no particular
#' modelling package.
#'
#' @param draws A data frame of draws: either long (parameter + value columns)
#'   or wide (one numeric column per parameter).
#' @param point Central summary: `"median"` or `"mean"`.
#' @param widths Two interval widths (inner and outer), as probabilities.
#' @param interaction Passed to [format_terms()] for the parameter labels.
#' @param reference_line Position of a vertical reference line (`NA` to omit).
#' @param colour Colour for the points and intervals.
#' @param title,x_lab Plot title and value-axis label.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' # Wide draws: one column per parameter
#' set.seed(1)
#' draws <- data.frame(
#'   intercept = rnorm(2000, 5, 0.3),
#'   slope = rnorm(2000, 0.8, 0.15),
#'   `slope:group` = rnorm(2000, -0.2, 0.2),
#'   check.names = FALSE
#' )
#' posterior_plot(draws)
posterior_plot <- function(draws, point = c("median", "mean"),
                           widths = c(0.66, 0.95),
                           interaction = c("times", "asterisk", "colon",
                                           "space"),
                           reference_line = 0, colour = "#005b96",
                           title = NULL, x_lab = "Value") {
  point <- match.arg(point)
  interaction <- match.arg(interaction)
  if (length(widths) != 2) stop("`widths` must have two values.", call. = FALSE)
  widths <- sort(widths)

  long <- draws_to_long(draws)
  point_fun <- if (point == "median") stats::median else mean

  params <- unique(long$parameter)
  summ <- do.call(rbind, lapply(params, function(p) {
    v <- long$value[long$parameter == p]
    inner <- stats::quantile(v, c((1 - widths[1]) / 2, 1 - (1 - widths[1]) / 2),
                             names = FALSE)
    outer <- stats::quantile(v, c((1 - widths[2]) / 2, 1 - (1 - widths[2]) / 2),
                             names = FALSE)
    data.frame(parameter = p, centre = point_fun(v),
               inner_lo = inner[1], inner_hi = inner[2],
               outer_lo = outer[1], outer_hi = outer[2],
               stringsAsFactors = FALSE)
  }))

  summ$label <- factor(format_terms(summ$parameter, interaction = interaction),
                       levels = rev(format_terms(params, interaction = interaction)))

  p <- ggplot2::ggplot(summ, ggplot2::aes(y = .data$label))
  if (!is.na(reference_line)) {
    p <- p + ggplot2::geom_vline(xintercept = reference_line, linetype = 2,
                                 colour = "grey60")
  }
  p +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = .data$outer_lo, xmax = .data$outer_hi),
      linewidth = 0.6, colour = colour
    ) +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = .data$inner_lo, xmax = .data$inner_hi),
      linewidth = 1.8, colour = colour
    ) +
    ggplot2::geom_point(ggplot2::aes(x = .data$centre), size = 2.2,
                        colour = "white") +
    ggplot2::geom_point(ggplot2::aes(x = .data$centre), size = 1.4,
                        colour = colour) +
    ggplot2::labs(x = x_lab, y = NULL, title = title) +
    theme_depictr(grid = "x")
}

# ---- internal helper -------------------------------------------------------

#' @noRd
draws_to_long <- function(draws) {
  if (!is.data.frame(draws)) stop("`draws` must be a data frame.", call. = FALSE)
  par_col <- intersect(c("parameter", "term", ".variable", "variable"),
                       names(draws))
  val_col <- intersect(c("value", ".value", "draw", "estimate"), names(draws))
  if (length(par_col) && length(val_col)) {
    return(data.frame(parameter = as.character(draws[[par_col[1]]]),
                      value = as.numeric(draws[[val_col[1]]]),
                      stringsAsFactors = FALSE))
  }
  num <- names(draws)[vapply(draws, is.numeric, logical(1))]
  if (length(num) < 1) {
    stop("Could not find draws: supply long (parameter + value) or wide ",
         "(numeric columns) data.", call. = FALSE)
  }
  data.frame(
    parameter = rep(num, each = nrow(draws)),
    value = unlist(draws[num], use.names = FALSE),
    stringsAsFactors = FALSE
  )
}
