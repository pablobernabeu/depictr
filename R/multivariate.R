# Principal component analysis plots -----------------------------------------

#' PCA biplot
#'
#' Runs a principal component analysis on the numeric columns of a data frame
#' (or takes an existing [stats::prcomp()] object) and draws a biplot: the
#' observations projected onto two components, with the variable loadings shown
#' as arrows. Optionally colour the observations by a grouping variable.
#'
#' Each arrow is a variable's loadings on the two components, taken from the
#' rotation matrix and multiplied by a factor that all the arrows share. The
#' factor makes the largest coordinate of any arrow three quarters of the
#' largest absolute score. Both axes use that one factor, as [stats::biplot()] uses one
#' ratio for both, and the aspect ratio is fixed at 1. An arrow's angle on the
#' page is therefore its angle in loading space, whatever the size of the
#' figure. The panel's height and width follow the ranges of its two axes, so a
#' figure of another shape leaves blank space around the panel. Because the
#' scores are drawn as they are and the arrows as loadings, the angle between
#' two arrows does not estimate the correlation between their variables. Arrows
#' and labels are drawn in a neutral dark grey (`grey20`), which is not in the
#' default palette, so no arrow reads as part of a group.
#'
#' @param x A data frame, or a [stats::prcomp()] object.
#' @param cols When `x` is a data frame, the numeric columns to analyse
#'   (default: all numeric).
#' @param group Optional grouping variable mapped to colour. When `x` is a data
#'   frame, give a column of `x`, unquoted or as a string, or a vector with one
#'   value per row of `x`. Rows with missing values count, although the
#'   analysis drops them. When `x` is a [stats::prcomp()] object, give a vector
#'   with one value per observation. A name that matches no column, or a vector
#'   of another length, is an error.
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
  group <- rlang::enquo(group)
  if (inherits(x, "prcomp")) {
    pca <- x
    if (is.null(pca$x)) {
      stop("The prcomp object holds no scores. Fit it with `retx = TRUE`, ",
           "the default.", call. = FALSE)
    }
    grp <- pca_group(group, data = NULL, n = nrow(pca$x))
  } else {
    if (!is.data.frame(x)) stop("`x` must be a data frame or prcomp object.",
                                call. = FALSE)
    grp <- pca_group(group, data = x, n = nrow(x))
    if (is.null(cols)) cols <- names(x)[vapply(x, is.numeric, logical(1))]
    else check_columns(x, cols)
    if (length(cols) < 2) stop("Need at least two numeric columns.",
                               call. = FALSE)
    complete <- stats::complete.cases(x[cols])
    pca <- stats::prcomp(x[complete, cols, drop = FALSE],
                         scale. = scale, center = TRUE)
    if (!is.null(grp)) grp <- grp[complete]
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
    # Show underscores in the loading labels as spaces, matching the package's
    # display convention (e.g. soil_ph -> "soil ph").
    rot$varname <- gsub("_", " ", rownames(rot), fixed = TRUE)
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
    # Arrows and labels are a neutral dark grey. The accent is also the fourth
    # colour of the qualitative palette, so accent arrows read as belonging to
    # the fourth group.
    p <- p +
      ggplot2::geom_segment(
        data = rot,
        ggplot2::aes(x = 0, y = 0, xend = .data$PCx, yend = .data$PCy),
        arrow = ggplot2::arrow(length = ggplot2::unit(0.18, "cm")),
        colour = "grey20", linewidth = 0.5, inherit.aes = FALSE
      ) +
      ggplot2::geom_label(
        data = rot,
        ggplot2::aes(x = .data$labx, y = .data$laby, label = .data$varname),
        colour = "grey20", fontface = "bold", size = 3.6,
        fill = grDevices::adjustcolor("white", alpha.f = 0.7),
        linewidth = 0, label.padding = ggplot2::unit(0.12, "lines"),
        inherit.aes = FALSE
      )
  }

  p +
    # One unit of PCx spans the same length on the page as one unit of PCy, so
    # the arrows keep their angles on a device of any shape. Clipping is off
    # so that a label beyond the point cloud can run past the panel edge.
    ggplot2::coord_fixed(ratio = 1, clip = "off") +
    ggplot2::labs(
      x = sprintf("PC%d (%.1f%%)", ci[1], 100 * ve[ci[1]]),
      y = sprintf("PC%d (%.1f%%)", ci[2], 100 * ve[ci[2]]),
      title = title
    ) +
    theme_depictr()
}

#' Resolve the `group` of pca_plot() to one value per observation
#'
#' `group` may name a column of the data frame, unquoted or as a string, or be
#' a vector with one value per observation. A bare name or a string that names
#' a column takes that column. Any other expression is evaluated where
#' pca_plot() was called, and a single string it gives is read as a column
#' name, as resolve_var() reads a variable holding one. A bare name that is
#' neither a column nor an object, or that finds only a function, is refused as
#' its quoted form would be. resolve_var() itself cannot serve, because
#' rlang::as_name() fails on an expression such as `crop_yield$treatment`.
#'
#' Every check runs before pca_plot() subsets anything. Indexing a short vector
#' with the complete-case mask pads it with `NA`, and assigning it to the
#' scores recycles it, so a wrong length used to pass in silence.
#'
#' @param quo The quosure of `group`.
#' @param data The data frame, or `NULL` when `x` is a prcomp object.
#' @param n The number of observations: the rows of `data`, or of the scores.
#' @return `NULL`, or a factor of length `n`.
#' @noRd
pca_group <- function(quo, data, n) {
  if (rlang::quo_is_null(quo)) return(NULL)
  expr <- rlang::quo_get_expr(quo)
  if (rlang::is_symbol(expr)) {
    name <- rlang::as_string(expr)
    if (!is.null(data) && name %in% names(data)) {
      return(as.factor(data[[name]]))
    }
    known <- rlang::env_has(rlang::quo_get_env(quo), name, inherit = TRUE)
    value <- if (known) rlang::eval_tidy(quo) else name
    # A name such as `time` or `family` finds a function on the search path,
    # and a function is never a set of groups. It is a column the data lack.
    if (is.function(value)) value <- name
  } else {
    value <- rlang::eval_tidy(quo)
  }
  if (is.null(value)) return(NULL)

  if (is.character(value) && length(value) == 1) {
    if (is.null(data)) {
      stop("With a prcomp object, pass `group` as a vector with one value ",
           "per observation.", call. = FALSE)
    }
    if (!value %in% names(data)) {
      stop("Column `", value, "` (argument `group`) not found in the data.",
           call. = FALSE)
    }
    return(as.factor(data[[value]]))
  }
  if (length(value) != n) {
    has <- if (is.null(data)) {
      paste("the prcomp object has scores for", n, "observations.")
    } else {
      paste0("`x` has ", n, " rows. Give one value per row of `x`, ",
             "including any row with a missing value.")
    }
    stop("`group` has length ", length(value), " but ", has, call. = FALSE)
  }
  as.factor(value)
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
