# Internal colour accessors --------------------------------------------------
#
# The named colours used across depictr: brand, accent and reference.
# Plotting functions call these accessors instead of repeating hex literals.
# The full categorical palette lives in `depictr_palette()` (see
# theme_depictr.R); these helpers name the three colours that recur on their
# own outside that palette.
#
# Each accessor reads the matching global option (set via
# `depictr_options()`), and only then the package default in options.R, so
# `options(depictr.brand = )` and its siblings recolour every plot that uses
# them. The brand option leaves the palettes alone: the built-in qualitative
# set and the sequential and diverging ramps of `depictr_palette()`, like
# seasonal_plot()'s cycle_palette(), write the brand blue as a literal of
# their own, and `options(depictr.palette = )` replaces the qualitative set
# only.

#' depictr brand blue
#'
#' The primary brand colour, used for single-series geoms, titles and the
#' default point colour on forest/caterpillar plots. Equal to
#' `depictr_palette(1)[1]` (the leading colour of the qualitative palette) when
#' no custom palette/brand option is set. Honours `options(depictr.brand = )`.
#'
#' @return A single hex colour string.
#' @keywords internal
#' @noRd
depictr_brand <- function() depictr_opt("brand")

#' depictr accent colour
#'
#' A secondary highlight colour for drawing attention to a single element
#' against the brand blue. The default is the Okabe-Ito vermillion (Okabe & Ito,
#' 2008), chosen because it stays distinguishable from the brand blue under the
#' common forms of colour-vision deficiency. Honours `options(depictr.accent = )`.
#'
#' @return A single hex colour string.
#' @keywords internal
#' @noRd
depictr_accent <- function() depictr_opt("accent")

#' depictr reference-line colour
#'
#' The muted grey used for reference lines (zero lines, identity lines, decision
#' thresholds) so they recede behind the data. Honours
#' `options(depictr.reference = )`.
#'
#' @return A single grey colour string.
#' @keywords internal
#' @noRd
depictr_reference <- function() depictr_opt("reference")

# Colour-vision-deficiency (CVD) simulation ----------------------------------
#
# Machado, Oliveira & Fernandes (2009) physiologically-based model. The
# transforms operate in *linear* RGB, so colours are linearised from sRGB,
# multiplied by the per-deficiency matrix, then re-encoded to sRGB.
# Reference: Machado GM, Oliveira MM, Fernandes LAF (2009), "A physiologically-
# based model for simulation of color vision deficiency", IEEE TVCG 15(6),
# 1291-1298.
#
# The matrices are those the authors publish for protanomaly, deuteranomaly
# and tritanomaly at severities 0.0 to 1.0 in steps of 0.1, on the article's
# supplementary page
# (https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html).
# They are identical, entry for entry, to the copies in colorspace 2.1.2 and
# Python's colorspacious 1.1.2. Each table below lists the eleven matrices row
# by row, nine numbers to a severity. The list order fixes the order
# deficiencies are reported in, and matches the Python twin's `_MACHADO`.

.cvd_matrices_by_severity <- lapply(list(
  protan = c(
    # 0.0
     1.000000,  0.000000,  0.000000,
     0.000000,  1.000000,  0.000000,
     0.000000,  0.000000,  1.000000,
    # 0.1
     0.856167,  0.182038, -0.038205,
     0.029342,  0.955115,  0.015544,
    -0.002880, -0.001563,  1.004443,
    # 0.2
     0.734766,  0.334872, -0.069637,
     0.051840,  0.919198,  0.028963,
    -0.004928, -0.004209,  1.009137,
    # 0.3
     0.630323,  0.465641, -0.095964,
     0.069181,  0.890046,  0.040773,
    -0.006308, -0.007724,  1.014032,
    # 0.4
     0.539009,  0.579343, -0.118352,
     0.082546,  0.866121,  0.051332,
    -0.007136, -0.011959,  1.019095,
    # 0.5
     0.458064,  0.679578, -0.137642,
     0.092785,  0.846313,  0.060902,
    -0.007494, -0.016807,  1.024301,
    # 0.6
     0.385450,  0.769005, -0.154455,
     0.100526,  0.829802,  0.069673,
    -0.007442, -0.022190,  1.029632,
    # 0.7
     0.319627,  0.849633, -0.169261,
     0.106241,  0.815969,  0.077790,
    -0.007025, -0.028051,  1.035076,
    # 0.8
     0.259411,  0.923008, -0.182420,
     0.110296,  0.804340,  0.085364,
    -0.006276, -0.034346,  1.040622,
    # 0.9
     0.203876,  0.990338, -0.194214,
     0.112975,  0.794542,  0.092483,
    -0.005222, -0.041043,  1.046265,
    # 1.0
     0.152286,  1.052583, -0.204868,
     0.114503,  0.786281,  0.099216,
    -0.003882, -0.048116,  1.051998
  ),
  deutan = c(
    # 0.0
     1.000000,  0.000000,  0.000000,
     0.000000,  1.000000,  0.000000,
     0.000000,  0.000000,  1.000000,
    # 0.1
     0.866435,  0.177704, -0.044139,
     0.049567,  0.939063,  0.011370,
    -0.003453,  0.007233,  0.996220,
    # 0.2
     0.760729,  0.319078, -0.079807,
     0.090568,  0.889315,  0.020117,
    -0.006027,  0.013325,  0.992702,
    # 0.3
     0.675425,  0.433850, -0.109275,
     0.125303,  0.847755,  0.026942,
    -0.007950,  0.018572,  0.989378,
    # 0.4
     0.605511,  0.528560, -0.134071,
     0.155318,  0.812366,  0.032316,
    -0.009376,  0.023176,  0.986200,
    # 0.5
     0.547494,  0.607765, -0.155259,
     0.181692,  0.781742,  0.036566,
    -0.010410,  0.027275,  0.983136,
    # 0.6
     0.498864,  0.674741, -0.173604,
     0.205199,  0.754872,  0.039929,
    -0.011131,  0.030969,  0.980162,
    # 0.7
     0.457771,  0.731899, -0.189670,
     0.226409,  0.731012,  0.042579,
    -0.011595,  0.034333,  0.977261,
    # 0.8
     0.422823,  0.781057, -0.203881,
     0.245752,  0.709602,  0.044646,
    -0.011843,  0.037423,  0.974421,
    # 0.9
     0.392952,  0.823610, -0.216562,
     0.263559,  0.690210,  0.046232,
    -0.011910,  0.040281,  0.971630,
    # 1.0
     0.367322,  0.860646, -0.227968,
     0.280085,  0.672501,  0.047413,
    -0.011820,  0.042940,  0.968881
  ),
  tritan = c(
    # 0.0
     1.000000,  0.000000,  0.000000,
     0.000000,  1.000000,  0.000000,
     0.000000,  0.000000,  1.000000,
    # 0.1
     0.926670,  0.092514, -0.019184,
     0.021191,  0.964503,  0.014306,
     0.008437,  0.054813,  0.936750,
    # 0.2
     0.895720,  0.133330, -0.029050,
     0.029997,  0.945400,  0.024603,
     0.013027,  0.104707,  0.882266,
    # 0.3
     0.905871,  0.127791, -0.033662,
     0.026856,  0.941251,  0.031893,
     0.013410,  0.148296,  0.838294,
    # 0.4
     0.948035,  0.089490, -0.037526,
     0.014364,  0.946792,  0.038844,
     0.010853,  0.193991,  0.795156,
    # 0.5
     1.017277,  0.027029, -0.044306,
    -0.006113,  0.958479,  0.047634,
     0.006379,  0.248708,  0.744913,
    # 0.6
     1.104996, -0.046633, -0.058363,
    -0.032137,  0.971635,  0.060503,
     0.001336,  0.317922,  0.680742,
    # 0.7
     1.193214, -0.109812, -0.083402,
    -0.058496,  0.979410,  0.079086,
    -0.002346,  0.403492,  0.598854,
    # 0.8
     1.257728, -0.139648, -0.118081,
    -0.078003,  0.975409,  0.102594,
    -0.003316,  0.501214,  0.502102,
    # 0.9
     1.278864, -0.125333, -0.153531,
    -0.084748,  0.957674,  0.127074,
    -0.000989,  0.601151,  0.399838,
    # 1.0
     1.255528, -0.076749, -0.178779,
    -0.078411,  0.930809,  0.147602,
     0.004733,  0.691367,  0.303900
  )
), function(entries) {
  unname(lapply(split(entries, rep(0:10, each = 9)), matrix, nrow = 3,
                byrow = TRUE))
})

# The full-severity matrices, which palette_safety(), check_figure() and
# palette_preview() use.
.cvd_matrices <- lapply(.cvd_matrices_by_severity, `[[`, 11)

# The transform for one deficiency and severity. Between two tabulated
# severities, the matrix is interpolated linearly, as the supplementary page
# suggests and as colorspace::interpolate_cvd_transform() and colorspacious do,
# so 0.25 lies halfway between the matrices for 0.2 and 0.3. Severities 0 and
# 1 take their matrices exactly as published, which keeps full-severity
# results bit for bit.
.cvd_matrix <- function(deficiency, severity) {
  tab <- .cvd_matrices_by_severity[[deficiency]]
  scaled <- 10 * severity
  i <- floor(scaled)
  f <- scaled - i
  if (f == 0) {
    return(tab[[i + 1]])
  }
  (1 - f) * tab[[i + 1]] + f * tab[[i + 2]]
}

# sRGB <-> linear-RGB transfer functions (IEC 61966-2-1). Vectorised, shape
# preserving so they can run over a 3 x n channel matrix.
.srgb_to_linear <- function(c) {
  ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4)
}
.linear_to_srgb <- function(c) {
  c <- pmax(pmin(c, 1), 0)
  ifelse(c <= 0.0031308, c * 12.92, 1.055 * c^(1 / 2.4) - 0.055)
}

#' Simulate how colours appear under a colour-vision deficiency
#'
#' Maps each colour to the colour a reader with a given form and severity of
#' colour-vision deficiency would perceive, using the physiologically-based
#' model of Machado, Oliveira and Fernandes (2009). The transformation is
#' defined on linear-light RGB, so a colour is decoded from sRGB to linear RGB
#' (the IEC 61966-2-1 transfer functions), transformed, then re-encoded.
#'
#' This is the simulator behind [palette_preview()]'s `cvd` argument, behind
#' [palette_safety()], and behind the colour-separability rows of
#' [check_figure()]. [simulate_figure()] applies it to every colour of a
#' finished figure.
#'
#' @param colours Character vector of colours, in any form
#'   [grDevices::col2rgb()] understands.
#' @param deficiency The deficiency to simulate: `"protan"` or `"deutan"`
#'   (the two red-green forms) or `"tritan"` (blue-yellow).
#' @param severity Severity in `[0, 1]`. Zero leaves the colours unchanged and
#'   one is the full deficiency. Machado et al. publish a matrix for each tenth
#'   of severity, which is used as it stands at 0.1, 0.2 and so on. A severity
#'   between two tenths takes the linear interpolation of their matrices, as
#'   the authors suggest and as the colorspace package does.
#'
#' @return A character vector of opaque, lower-case six-digit hex colours, the
#'   same length as `colours`. Any alpha is dropped, whereas
#'   [simulate_figure()] keeps it.
#' @references
#' \insertRef{machado2009}{depictr}
#' @export
#' @examples
#' simulate_cvd(c("#005b96", "#e69f00"), "deutan")
#'
#' # Half severity moves the colours only part of the way.
#' simulate_cvd(c("#005b96", "#e69f00"), "deutan", severity = 0.5)
simulate_cvd <- function(colours, deficiency, severity = 1) {
  .check_vision(deficiency, severity)
  .cvd_hex(colours, .cvd_matrix(deficiency, severity))
}

# Refuses a deficiency or severity the simulation does not cover.
.check_vision <- function(deficiency, severity) {
  if (!is.character(deficiency) || length(deficiency) != 1 ||
      is.na(deficiency) || !deficiency %in% names(.cvd_matrices)) {
    stop("`deficiency` must be one of 'protan', 'deutan' or 'tritan'.",
         call. = FALSE)
  }
  if (!is.numeric(severity) || length(severity) != 1 || is.na(severity) ||
      severity < 0 || severity > 1) {
    stop("`severity` must lie in [0, 1].", call. = FALSE)
  }
  invisible(NULL)
}

# The colours through the transform `m`, as opaque lower-case hex. Any alpha
# is ignored.
.cvd_hex <- function(colours, m) {
  rgb <- grDevices::col2rgb(colours) / 255   # 3 x n, sRGB in [0, 1]
  out <- .linear_to_srgb(m %*% .srgb_to_linear(rgb))
  tolower(grDevices::rgb(out[1, ], out[2, ], out[3, ]))
}

#' Show a finished figure as a reader with a colour-vision deficiency sees it
#'
#' [simulate_cvd()] simulates a set of colours, and this function the figure
#' they end up in, legend, colourbar, text and background included.
#'
#' The plot is turned into the table of grobs that would be drawn, with
#' [ggplot2::ggplotGrob()] or, for a patchwork, [patchwork::patchworkGrob()].
#' Every colour in that table then goes through [simulate_cvd()]. That covers
#' the line and fill colours of each grob, at any depth, and each cell of a
#' raster, such as a colourbar, a [ggplot2::geom_raster()] layer or an image
#' added with [ggplot2::annotation_raster()]. Each colour keeps its alpha
#' channel. Missing and transparent colours are left as they are, and so are
#' gradient and pattern fills such as [grid::linearGradient()], which keep
#' their original colours.
#'
#' The colours are changed after the plot is built. Changing the colours of
#' the data before it is built would leave the legend keys and any colourbar
#' in their original colours, so the legend would no longer match the figure.
#'
#' The figure stays vector graphics, so it can be saved at any size. The Python
#' twin's `simulate_figure()` uses the same matrices but rasterises the figure
#' and simulates its pixels, so it returns an image.
#'
#' @param plot A ggplot or a patchwork, as it would be saved.
#' @inheritParams simulate_cvd
#'
#' @return A gtable, which [grid::grid.draw()] draws and [save_plot()] saves.
#' @references
#' \insertRef{machado2009}{depictr}
#' @seealso [check_figure()], which measures what this shows.
#' @export
#' @examples
#' library(ggplot2)
#' p <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
#'   geom_point() +
#'   scale_colour_depictr() +
#'   theme_depictr()
#'
#' # The figure as a reader with deuteranopia sees it.
#' seen <- simulate_figure(p, "deutan")
#' grid::grid.newpage()
#' grid::grid.draw(seen)
#'
#' # Saved for a side-by-side comparison with the original.
#' save_plot(file.path(tempdir(), "yield-deutan.png"), seen)
simulate_figure <- function(plot, deficiency, severity = 1) {
  .check_vision(deficiency, severity)
  # A patchwork is a ggplot too, so it is recognised first.
  drawn <- if (inherits(plot, "patchwork")) {
    patchwork::patchworkGrob(plot)
  } else if (inherits(plot, "ggplot")) {
    ggplot2::ggplotGrob(plot)
  } else {
    stop("`plot` must be a ggplot or a patchwork.", call. = FALSE)
  }
  .simulate_grob(drawn, .cvd_matrix(deficiency, severity))
}

# A grob with every colour it draws, and every colour of the grobs it holds,
# passed through the transform `m`. A gtable keeps its grobs in `grobs`, and
# any other gTree in `children`. The children keep their names, so the order
# in which a gTree draws them still holds.
.simulate_grob <- function(g, m) {
  if (!is.null(g$gp$col)) g$gp$col <- .simulate_colours(g$gp$col, m)
  if (!is.null(g$gp$fill)) g$gp$fill <- .simulate_colours(g$gp$fill, m)
  if (inherits(g, "rastergrob")) g$raster <- .simulate_raster(g$raster, m)
  if (!is.null(g$grobs)) {
    g$grobs <- lapply(g$grobs, .simulate_grob, m = m)
  }
  if (!is.null(g$children)) {
    g$children <- do.call(grid::gList,
                          lapply(g$children, .simulate_grob, m = m))
  }
  g
}

# Colours through the transform `m`, each keeping its alpha. An opaque colour
# comes back as six hex digits, as simulate_cvd() gives it, and a translucent
# one with its alpha appended as two more. Missing and transparent colours,
# and a fill that is not a colour, such as a gradient, are left as they are.
.simulate_colours <- function(colours, m) {
  if (!is.character(colours)) return(colours)
  shown <- !is.na(colours) & !colours %in% c("transparent", "NA")
  if (!any(shown)) return(colours)
  # A raster or a scatter repeats a few colours many times over.
  distinct <- unique(colours[shown])
  alpha <- grDevices::col2rgb(distinct, alpha = TRUE)[4, ]
  seen <- .cvd_hex(distinct, m)
  seen[alpha < 255] <- paste0(seen[alpha < 255],
                              sprintf("%02x", alpha[alpha < 255]))
  colours[shown] <- seen[match(colours[shown], distinct)]
  colours
}

# The cells of a raster through the transform `m`, as a raster of colours. A
# nativeRaster, as png::readPNG(native = TRUE) returns, packs each pixel into
# one integer, red in the lowest byte and alpha in the highest, and stores the
# image row by row, so it is unpacked into colours first.
.simulate_raster <- function(raster, m) {
  if (inherits(raster, "nativeRaster")) {
    packed <- as.vector(unclass(raster))
    byte <- function(shift) bitwAnd(bitwShiftR(packed, shift), 255L)
    colours <- grDevices::rgb(byte(0L), byte(8L), byte(16L), byte(24L),
                              maxColorValue = 255)
    cells <- matrix(colours, nrow = dim(raster)[1], ncol = dim(raster)[2],
                    byrow = TRUE)
  } else {
    cells <- as.matrix(grDevices::as.raster(raster))
  }
  grDevices::as.raster(matrix(.simulate_colours(as.vector(cells), m),
                              nrow = nrow(cells), ncol = ncol(cells)))
}

# Perceptual distance and the colourblind-safety check -----------------------

#' Convert sRGB colours to CIE Lab (D65)
#' @noRd
.srgb_to_lab <- function(cols) {
  rgb <- grDevices::col2rgb(cols) / 255
  lin <- .srgb_to_linear(rgb)               # 3 x n
  m <- matrix(c(
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041
  ), nrow = 3, byrow = TRUE)
  xyz <- m %*% lin                          # 3 x n (D65)
  white <- c(0.95047, 1.00000, 1.08883)
  xyz <- xyz / white
  f <- function(t) ifelse(t > 0.008856, t^(1 / 3), 7.787 * t + 16 / 116)
  fx <- f(xyz[1, ]); fy <- f(xyz[2, ]); fz <- f(xyz[3, ])
  cbind(L = 116 * fy - 16, a = 500 * (fx - fy), b = 200 * (fy - fz))
}

# Degrees to radians and back, as the products that Python's math.radians()
# and math.degrees() compute, so that the twins round alike.
.radians_per_degree <- pi / 180
.degrees_per_radian <- 180 / pi

#' CIEDE2000 colour difference between the rows of two Lab matrices
#'
#' The formula as Sharma, Wu and Dalal (2005) set it out, with the parametric
#' weights kL, kC and kH at 1. Where the definition leaves a choice, theirs is
#' followed. A neutral colour has a hue angle of zero. A pair in which either
#' colour is neutral has no hue difference, and its mean hue is the sum of the
#' two hue angles. The Python twin's `_ciede2000()` evaluates the same
#' expressions in the same order. The 34 pairs the authors published are in
#' tests/testthat/fixtures/sharma2005.csv.
#'
#' @param lab1,lab2 Matrices with the columns L, a and b, one colour per row,
#'   or vectors of length three.
#' @return A numeric vector, one difference per row.
#' @noRd
.ciede2000 <- function(lab1, lab2) {
  lab1 <- matrix(lab1, ncol = 3)
  lab2 <- matrix(lab2, ncol = 3)
  l1 <- lab1[, 1]; a1 <- lab1[, 2]; b1 <- lab1[, 3]
  l2 <- lab2[, 1]; a2 <- lab2[, 2]; b2 <- lab2[, 3]

  # a* is scaled up for colours of low chroma, the formula's correction for
  # greys, before chroma and hue are taken.
  c_bar <- (sqrt(a1^2 + b1^2) + sqrt(a2^2 + b2^2)) / 2
  g <- 0.5 * (1 - sqrt(c_bar^7 / (c_bar^7 + 25^7)))
  a1p <- (1 + g) * a1
  a2p <- (1 + g) * a2
  c1p <- sqrt(a1p^2 + b1^2)
  c2p <- sqrt(a2p^2 + b2^2)
  hue <- function(b, a) {
    h <- ifelse(b == 0 & a == 0, 0, atan2(b, a) * .degrees_per_radian)
    ifelse(h < 0, h + 360, h)
  }
  h1p <- hue(b1, a1p)
  h2p <- hue(b2, a2p)

  # The differences in lightness, chroma and hue, the hue difference taken the
  # short way round the circle.
  neutral <- c1p * c2p == 0
  dlp <- l2 - l1
  dcp <- c2p - c1p
  dhp <- h2p - h1p
  dhp <- ifelse(neutral, 0,
                ifelse(dhp > 180, dhp - 360,
                       ifelse(dhp < -180, dhp + 360, dhp)))
  dbig_hp <- 2 * sqrt(c1p * c2p) * sin(dhp / 2 * .radians_per_degree)

  # The weights for lightness, chroma and hue, taken at the pair's means. The
  # term that couples the chroma and hue differences is the formula's
  # correction for blues.
  lbp <- (l1 + l2) / 2
  cbp <- (c1p + c2p) / 2
  hbp <- ifelse(neutral, h1p + h2p,
                ifelse(abs(h1p - h2p) <= 180, (h1p + h2p) / 2,
                       ifelse(h1p + h2p < 360, (h1p + h2p + 360) / 2,
                              (h1p + h2p - 360) / 2)))
  t_term <- 1 - 0.17 * cos((hbp - 30) * .radians_per_degree) +
    0.24 * cos(2 * hbp * .radians_per_degree) +
    0.32 * cos((3 * hbp + 6) * .radians_per_degree) -
    0.20 * cos((4 * hbp - 63) * .radians_per_degree)
  d_theta <- 30 * exp(-((hbp - 275) / 25)^2)
  r_c <- 2 * sqrt(cbp^7 / (cbp^7 + 25^7))
  s_l <- 1 + 0.015 * (lbp - 50)^2 / sqrt(20 + (lbp - 50)^2)
  s_c <- 1 + 0.045 * cbp
  s_h <- 1 + 0.015 * cbp * t_term
  r_t <- -sin(2 * d_theta * .radians_per_degree) * r_c

  lightness <- dlp / s_l
  chroma <- dcp / s_c
  hue_term <- dbig_hp / s_h
  sqrt(lightness^2 + chroma^2 + hue_term^2 + r_t * chroma * hue_term)
}

#' Smallest pairwise colour difference within a set
#'
#' Lower bound on how distinguishable a set of colours is: the minimum colour
#' difference across all colour pairs, CIEDE2000 or, with `metric = "cie76"`,
#' the Euclidean distance in CIELAB. Larger is safer. The pairs are walked in
#' the same order as the Python twin so that a tie between two equally close
#' pairs resolves to the same pair in both engines.
#'
#' @param groups Optional labels, one per colour. A pair whose labels are equal
#'   is skipped: [check_figure()] labels each drawn colour with the colour it
#'   was declared as, so that one group drawn in two ways is not set against
#'   itself.
#' @param metric `"ciede2000"` or `"cie76"`.
#' @return A list with `distance` and `pair`, the one-based indices of the two
#'   closest colours.
#' @noRd
.min_pairwise_delta_e <- function(cols, groups = NULL, metric = "ciede2000") {
  lab <- .srgb_to_lab(cols)
  n <- nrow(lab)
  none <- list(distance = Inf, pair = c(1L, 1L))
  if (n < 2) return(none)
  # utils::combn() lists the pairs as the Python twin's nested loops visit
  # them, i before j, and which.min() keeps the first of equally close pairs.
  pairs <- t(utils::combn(n, 2))
  if (!is.null(groups)) {
    pairs <- pairs[groups[pairs[, 1]] != groups[pairs[, 2]], , drop = FALSE]
  }
  if (!nrow(pairs)) return(none)
  first <- lab[pairs[, 1], , drop = FALSE]
  second <- lab[pairs[, 2], , drop = FALSE]
  d <- if (metric == "cie76") {
    sqrt(rowSums((first - second)^2))
  } else {
    .ciede2000(first, second)
  }
  closest <- which.min(d)
  list(distance = d[[closest]], pair = pairs[closest, ])
}

#' Check that a palette stays distinguishable under each deficiency
#'
#' For normal vision and each deficiency at full severity, the palette's colours
#' are converted to CIELAB and the smallest colour difference between any two
#' of them is found. The difference is CIEDE2000 (Sharma, Wu & Dalal, 2005)
#' unless `metric` asks for CIE76. The lower this minimum, the
#' more likely two categories are to be confused. A palette counts as safe when
#' the minimum across all four conditions is at least `threshold`.
#'
#' The Euclidean distance in CIELAB, known as CIE76, overstates the difference
#' between saturated colours: the blues `#005b96` and `#0060a8` are 8.20 apart
#' by CIE76 and 2.69 by CIEDE2000. ggplot2's default palette of five colours
#' passes the check under CIE76, although under deuteranopia its sky blue and
#' its pink come within 2.74 of each other in CIEDE2000.
#'
#' The default `threshold` of 5 is calibrated against the built-in palette of
#' [depictr_palette()], which is based on the Okabe-Ito set with the brand blue
#' and a grey in place of its blue and black. That palette's tightest pair
#' (reddish purple against grey) sits at 6.43 under full deuteranopia, so the
#' cut must lie below that to pass the built-in palette, while still flagging
#' colours that become near-identical under a deficiency. The difference includes
#' lightness, which survives colour-vision deficiency, so two colours that share
#' a hue but differ in lightness are correctly treated as distinguishable. Full
#' severity is the worst case; most colour-vision deficiency is milder.
#'
#' This looks at a palette in the abstract. To audit a finished figure, which
#' uses only as many colours as it has groups and has text and a background
#' besides, see [check_figure()].
#'
#' @param colours The palette to test. Defaults to the depictr qualitative
#'   palette. Needs at least two colours: a pairwise distance over fewer than
#'   two has no value, rather than an infinitely safe one.
#' @param threshold The smallest acceptable colour difference, on the scale of
#'   `metric`.
#' @param metric The colour difference to measure: `"ciede2000"`, the default,
#'   or `"cie76"`, the Euclidean distance in CIELAB. `"cie76"` is kept so that
#'   results computed with it can be reproduced, and a later release will remove
#'   it.
#'
#' @return A list with `min_delta_e` (the worst case across conditions),
#'   `by_condition` (a named numeric vector, one minimum colour difference for
#'   normal vision and for each deficiency), `worst_condition` and `worst_pair`
#'   (the closest colours and where they were closest), `safe` and
#'   `threshold`.
#' @references
#' \insertRef{okabe2008}{depictr}
#'
#' \insertRef{machado2009}{depictr}
#'
#' \insertRef{sharma2005}{depictr}
#' @export
#' @examples
#' palette_safety()
#'
#' # Two colours a hair apart are flagged.
#' palette_safety(c("#005b96", "#015c97"))
#'
#' # ggplot2's default palette of five colours, which passes under CIE76.
#' hue5 <- c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3")
#' palette_safety(hue5)$safe
#' palette_safety(hue5, metric = "cie76")$safe
palette_safety <- function(colours = NULL, threshold = 5,
                           metric = c("ciede2000", "cie76")) {
  metric <- match.arg(metric)
  # `colours %||% depictr_palette()` would have swapped in the default palette
  # for an empty vector, reporting on eight colours the caller never passed.
  colours <- if (is.null(colours)) depictr_palette() else as.character(colours)
  if (length(colours) < 2) {
    # Otherwise the no-pair sentinel below survives to the result, which then
    # claims safe = TRUE at an infinite distance and names one colour as both
    # halves of the worst pair.
    stop("`colours` needs at least two colours to have a pairwise distance.",
         call. = FALSE)
  }
  conditions <- c("normal", names(.cvd_matrices))
  closest <- lapply(conditions, function(cond) {
    seen <- if (cond == "normal") colours else simulate_cvd(colours, cond)
    .min_pairwise_delta_e(seen, metric = metric)
  })
  names(closest) <- conditions
  by_condition <- vapply(closest, function(x) x$distance, numeric(1))
  worst_condition <- conditions[[which.min(by_condition)]]
  min_delta_e <- by_condition[[worst_condition]]
  list(
    min_delta_e = round(min_delta_e, 2),
    by_condition = round(by_condition, 2),
    worst_condition = worst_condition,
    worst_pair = colours[closest[[worst_condition]]$pair],
    # The verdict uses the unrounded distance, so a palette is never rounded
    # up over the threshold it actually misses.
    safe = min_delta_e >= threshold,
    threshold = threshold
  )
}
