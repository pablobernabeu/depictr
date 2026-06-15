# Internal colour accessors --------------------------------------------------
#
# Single source of truth for the named brand colours used across depictr.
# Plotting functions should call these accessors instead of repeating hex
# literals, so the palette can be changed in exactly one place. The full
# categorical palette lives in `depictr_palette()` (see theme_depictr.R); these
# helpers name the three colours that recur on their own outside that palette.
#
# Each accessor falls back to the matching global option (set via
# `depictr_options()`), and only then to the package default, so users can
# recolour the whole package by setting `options(depictr.brand = )` etc. once.

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
# Machado, Oliveira & Fernandes (2009) physiologically-based model, severity
# 1.0. The transforms operate in *linear* RGB, so colours are linearised from
# sRGB, multiplied by the per-deficiency matrix, then re-encoded to sRGB.
# Reference: Machado GM, Oliveira MM, Fernandes LAF (2009), "A Physiologically-
# based Model for Simulation of Color Vision Deficiency", IEEE TVCG 15(6),
# 1291-1298. Matrices as published for the three dichromacies.

.cvd_matrices <- list(
  deutan = matrix(c(
     0.367322,  0.860646, -0.227968,
     0.280085,  0.672501,  0.047413,
    -0.011820,  0.042940,  0.968881
  ), nrow = 3, byrow = TRUE),
  protan = matrix(c(
     0.152286,  1.052583, -0.204868,
     0.114503,  0.786281,  0.099216,
    -0.003882, -0.048116,  1.051998
  ), nrow = 3, byrow = TRUE),
  tritan = matrix(c(
     1.255528, -0.076749, -0.178779,
    -0.078411,  0.930809,  0.147602,
     0.004733,  0.691367,  0.303900
  ), nrow = 3, byrow = TRUE)
)

# sRGB <-> linear-RGB transfer functions (IEC 61966-2-1). Vectorised, shape
# preserving so they can run over a 3 x n channel matrix.
.srgb_to_linear <- function(c) {
  ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4)
}
.linear_to_srgb <- function(c) {
  c <- pmax(pmin(c, 1), 0)
  ifelse(c <= 0.0031308, c * 12.92, 1.055 * c^(1 / 2.4) - 0.055)
}

#' Simulate colour-vision deficiency on a set of colours
#'
#' Approximates how `cols` appear under deuteranopia, protanopia or tritanopia
#' using the Machado et al. (2009) severity-1.0 model in linear-RGB space.
#'
#' @param cols Character vector of colours (anything [grDevices::col2rgb()]
#'   understands).
#' @param type One of `"none"`, `"deutan"`, `"protan"`, `"tritan"`. `"none"`
#'   returns the colours unchanged (normalised to hex).
#' @return A character vector of hex colours the same length as `cols`.
#' @noRd
cvd_simulate <- function(cols, type = c("none", "deutan", "protan", "tritan")) {
  type <- match.arg(type)
  rgb <- grDevices::col2rgb(cols) / 255   # 3 x n, sRGB in [0, 1]
  if (type == "none") {
    return(grDevices::rgb(rgb[1, ], rgb[2, ], rgb[3, ]))
  }
  lin <- .srgb_to_linear(rgb)               # 3 x n
  out_lin <- .cvd_matrices[[type]] %*% lin  # 3 x n
  out <- .linear_to_srgb(out_lin)
  grDevices::rgb(out[1, ], out[2, ], out[3, ])
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

#' Smallest pairwise CIE76 colour distance within a set
#'
#' Lower bound on how distinguishable a set of colours is: the minimum Euclidean
#' distance in CIE Lab space across all colour pairs. Larger is safer.
#' @noRd
.min_pairwise_distance <- function(cols) {
  lab <- .srgb_to_lab(cols)
  if (nrow(lab) < 2) return(Inf)
  d <- as.matrix(stats::dist(lab))
  diag(d) <- Inf
  min(d)
}

#' Colourblind-safety summary for a qualitative palette
#'
#' For each colour-vision type (including normal vision) it reports the smallest
#' perceptual (CIE Lab) distance between any pair of palette colours after
#' simulating that deficiency. A larger minimum distance means the palette stays
#' more distinguishable. Used by the package's automated accessibility test.
#'
#' @param cols Palette colours. Defaults to the built-in qualitative palette.
#' @return A named numeric vector, one minimum distance per vision type.
#' @noRd
palette_cvd_safety <- function(cols = depictr_palette()) {
  types <- c("none", "deutan", "protan", "tritan")
  vapply(types, function(tp) {
    .min_pairwise_distance(cvd_simulate(cols, tp))
  }, numeric(1))
}
