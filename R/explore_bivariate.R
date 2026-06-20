# Bivariate plot -------------------------------------------------------------

#' Plot any pair of variables
#'
#' Chooses an appropriate plot for the relationship between two variables
#' according to their types. Two numeric variables are shown as a scatter plot
#' with a fitted trend; a numeric and a categorical variable as box plots of the
#' numeric variable by level; and two categorical variables as a filled bar
#' chart of proportions.
#'
#' @param data A data frame.
#' @param x,y The two variables (string or unquoted name).
#' @param method Smoothing method for the numeric-numeric case (passed to
#'   [ggplot2::geom_smooth()]); `NULL` for no trend.
#' @param palette Colours used when a fill/colour is needed; defaults to
#'   [depictr_palette()].
#' @param title,x_lab,y_lab Title and axis labels (default to variable names).
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' explore_bivariate(crop_yield, fertiliser, yield)        # numeric ~ numeric
#' explore_bivariate(lexical_decision, condition, RT)      # categorical ~ numeric
#' explore_bivariate(wellbeing_survey, region, education)  # categorical ~ categorical
explore_bivariate <- function(data, x, y, method = "lm", palette = NULL,
                              title = NULL, x_lab = NULL, y_lab = NULL) {
  x <- resolve_var(data, rlang::enquo(x), "x")
  y <- resolve_var(data, rlang::enquo(y), "y")
  x_lab <- x_lab %||% x
  y_lab <- y_lab %||% y

  x_num <- is.numeric(data[[x]])
  y_num <- is.numeric(data[[y]])
  d <- data[!is.na(data[[x]]) & !is.na(data[[y]]), , drop = FALSE]

  if (x_num && y_num) {
    return(scatter_trend(d, x, y, method = method, title = title,
                         x_lab = x_lab, y_lab = y_lab))
  }

  if (x_num != y_num) {
    # One numeric, one categorical -> boxplots of the numeric by the category
    cat_var <- if (x_num) y else x
    num_var <- if (x_num) x else y
    d[[cat_var]] <- as.factor(d[[cat_var]])
    pal <- palette %||% depictr_palette(nlevels(d[[cat_var]]))
    p <- ggplot2::ggplot(
      d, ggplot2::aes(x = .data[[cat_var]], y = .data[[num_var]],
                      fill = .data[[cat_var]])
    ) +
      ggplot2::geom_boxplot(alpha = 0.7, outlier.alpha = 0.4, na.rm = TRUE) +
      ggplot2::scale_fill_manual(values = pal) +
      ggplot2::labs(x = if (x_num) y_lab else x_lab,
                    y = if (x_num) x_lab else y_lab, title = title) +
      theme_depictr(grid = "y") +
      ggplot2::theme(legend.position = "none")
    return(p)
  }

  # Both categorical -> filled bar chart of proportions
  d[[x]] <- as.factor(d[[x]])
  d[[y]] <- as.factor(d[[y]])
  tab <- as.data.frame(table(x = d[[x]], y = d[[y]]), stringsAsFactors = FALSE)
  denom <- stats::ave(tab$Freq, tab$x, FUN = sum)
  tab$prop <- ifelse(denom > 0, tab$Freq / denom, 0)
  tab$x <- factor(tab$x, levels = levels(d[[x]]))
  tab$y <- factor(tab$y, levels = levels(d[[y]]))
  pal <- palette %||% depictr_palette(nlevels(tab$y))

  ggplot2::ggplot(tab, ggplot2::aes(x = .data$x, y = .data$prop,
                                    fill = .data$y)) +
    ggplot2::geom_col(width = 0.8) +
    ggplot2::scale_fill_manual(values = pal, name = y_lab) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(x = x_lab, y = paste("Proportion of", y_lab), title = title) +
    theme_depictr(grid = "y") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
}
