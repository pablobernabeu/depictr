# Principal component analysis plots -----------------------------------------

#' PCA biplot
#'
#' Runs a principal component analysis on the numeric columns of a data frame
#' (or takes an existing [stats::prcomp()] object) and draws a biplot: the
#' observations projected onto two components, with the variable loadings shown
#' as arrows. Optionally colour the observations by a grouping variable.
#'
#' @param x A data frame, or a [stats::prcomp()] object.
#' @param cols When `x` is a data frame, the numeric columns to analyse
#'   (default: all numeric).
#' @param group Optional grouping variable (a column name when `x` is a data
#'   frame, or a vector the length of the data) mapped to colour.
#' @param components Length-2 integer vector: which components to plot.
#' @param scale Whether to scale the variables to unit variance before the PCA.
#'   This is advisable when the variables are on different scales.
#' @param loadings Whether to draw variable-loading arrows.
#' @param point_alpha Point transparency.
#' @param palette Colours for the groups; defaults to [depictr_palette()].
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph", "yield"),
#'          group = "treatment")
pca_plot <- function(x, cols = NULL, group = NULL, components = c(1, 2),
                     scale = TRUE, loadings = TRUE, point_alpha = 0.7,
                     palette = NULL, title = NULL) {
  if (length(components) != 2) {
    stop("`components` must be two integers.", call. = FALSE)
  }
  grp <- NULL
  if (inherits(x, "prcomp")) {
    pca <- x
    if (!is.null(group)) grp <- as.factor(group)
  } else {
    if (!is.data.frame(x)) stop("`x` must be a data frame or prcomp object.",
                                call. = FALSE)
    if (!is.null(group)) {
      if (length(group) == 1 && group %in% names(x)) {
        grp <- as.factor(x[[group]])
      } else {
        grp <- as.factor(group)
      }
    }
    if (is.null(cols)) cols <- names(x)[vapply(x, is.numeric, logical(1))]
    else check_columns(x, cols)
    if (length(cols) < 2) stop("Need at least two numeric columns.",
                               call. = FALSE)
    pca <- stats::prcomp(x[stats::complete.cases(x[cols]), cols, drop = FALSE],
                         scale. = scale, center = TRUE)
    if (!is.null(grp)) grp <- grp[stats::complete.cases(x[cols])]
  }

  ci <- as.integer(components)
  ve <- (pca$sdev^2) / sum(pca$sdev^2)
  scores <- as.data.frame(pca$x[, ci, drop = FALSE])
  names(scores) <- c("PCx", "PCy")
  if (!is.null(grp)) scores$group <- grp

  if (is.null(grp)) {
    p <- ggplot2::ggplot(scores, ggplot2::aes(x = .data$PCx, y = .data$PCy)) +
      ggplot2::geom_point(alpha = point_alpha, colour = depictr_brand())
  } else {
    pal <- palette %||% depictr_palette(nlevels(grp))
    p <- ggplot2::ggplot(scores, ggplot2::aes(x = .data$PCx, y = .data$PCy,
                                              colour = .data$group)) +
      ggplot2::geom_point(alpha = point_alpha) +
      ggplot2::scale_colour_manual(values = pal, name = NULL)
  }
  p <- p + ggplot2::geom_hline(yintercept = 0, colour = "grey85") +
    ggplot2::geom_vline(xintercept = 0, colour = "grey85")

  if (loadings) {
    rot <- as.data.frame(pca$rotation[, ci, drop = FALSE])
    names(rot) <- c("PCx", "PCy")
    rot$varname <- rownames(rot)
    span <- max(abs(range(scores[c("PCx", "PCy")])))
    mult <- span / max(abs(as.matrix(rot[c("PCx", "PCy")]))) * 0.75
    rot$PCx <- rot$PCx * mult
    rot$PCy <- rot$PCy * mult
    # Place each label just past its arrow head, nudged outward along the arrow
    # direction, so labels sit beyond the point cloud and clear each other and
    # the arrows. A semi-transparent white box (geom_label) gives a halo that
    # keeps the text legible over the points.
    arrow_len <- sqrt(rot$PCx^2 + rot$PCy^2)
    nudge <- span * 0.08
    rot$labx <- rot$PCx + rot$PCx / arrow_len * nudge
    rot$laby <- rot$PCy + rot$PCy / arrow_len * nudge
    p <- p +
      ggplot2::geom_segment(
        data = rot,
        ggplot2::aes(x = 0, y = 0, xend = .data$PCx, yend = .data$PCy),
        arrow = ggplot2::arrow(length = ggplot2::unit(0.18, "cm")),
        colour = depictr_accent(), linewidth = 0.5, inherit.aes = FALSE
      ) +
      ggplot2::geom_label(
        data = rot,
        ggplot2::aes(x = .data$labx, y = .data$laby, label = .data$varname),
        colour = depictr_accent(), fontface = "bold", size = 3.6,
        fill = grDevices::adjustcolor("white", alpha.f = 0.7),
        linewidth = 0, label.padding = ggplot2::unit(0.12, "lines"),
        inherit.aes = FALSE
      )
  }

  p +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(
      x = sprintf("PC%d (%.1f%%)", ci[1], 100 * ve[ci[1]]),
      y = sprintf("PC%d (%.1f%%)", ci[2], 100 * ve[ci[2]]),
      title = title
    ) +
    theme_depictr()
}

#' Scree plot
#'
#' Shows the proportion of variance explained by each principal component, as
#' bars with a cumulative line. It is the customary aid for deciding how many
#' components to retain.
#'
#' @param x A data frame, or a [stats::prcomp()] object.
#' @param cols When `x` is a data frame, the numeric columns to analyse.
#' @param scale Whether to scale variables to unit variance before the PCA.
#' @param n Maximum number of components to display.
#' @param title Plot title.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' @examples
#' scree_plot(wellbeing_survey,
#'            cols = c("age", "income", "stress", "sleep_hours",
#'                     "exercise_days", "life_satisfaction"))
scree_plot <- function(x, cols = NULL, scale = TRUE, n = NULL, title = NULL) {
  if (inherits(x, "prcomp")) {
    pca <- x
  } else {
    if (is.null(cols)) cols <- names(x)[vapply(x, is.numeric, logical(1))]
    else check_columns(x, cols)
    pca <- stats::prcomp(x[stats::complete.cases(x[cols]), cols, drop = FALSE],
                         scale. = scale, center = TRUE)
  }
  ve <- (pca$sdev^2) / sum(pca$sdev^2)
  if (is.null(n)) n <- length(ve) else n <- min(n, length(ve))
  df <- data.frame(
    component = factor(paste0("PC", seq_len(n)),
                       levels = paste0("PC", seq_len(n))),
    variance = ve[seq_len(n)],
    cumulative = cumsum(ve[seq_len(n)])
  )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$component)) +
    ggplot2::geom_col(ggplot2::aes(y = .data$variance), fill = depictr_brand(),
                      width = 0.7) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cumulative, group = 1),
                       colour = depictr_accent(), linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(y = .data$cumulative),
                        colour = depictr_accent(), size = 1.8) +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 1),
      sec.axis = ggplot2::dup_axis(name = "Cumulative (line)")
    ) +
    ggplot2::labs(x = NULL, y = "Variance explained (bars)", title = title) +
    theme_depictr(grid = "y") +
    # Colour each axis title to match its geom -- brand-blue bars on the left,
    # accent cumulative line on the right -- so the dual axes are unambiguous.
    ggplot2::theme(
      axis.title.y.left = ggplot2::element_text(colour = depictr_brand()),
      axis.title.y.right = ggplot2::element_text(colour = depictr_accent())
    )
}
