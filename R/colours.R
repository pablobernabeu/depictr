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
# Machado, Oliveira & Fernandes (2009) physiologically-based model. The
# transforms operate in *linear* RGB, so colours are linearised from sRGB,
# multiplied by the per-deficiency matrix, then re-encoded to sRGB.
# Reference: Machado GM, Oliveira MM, Fernandes LAF (2009), "A physiologically-
# based model for simulation of color vision deficiency", IEEE TVCG 15(6),
# 1291-1298. Matrices as published for the three dichromacies at full severity;
# partial severities interpolate towards the identity. The list order fixes the
# order deficiencies are reported in, and matches the Python twin.

.cvd_matrices <- list(
  protan = matrix(c(
     0.152286,  1.052583, -0.204868,
     0.114503,  0.786281,  0.099216,
    -0.003882, -0.048116,  1.051998
  ), nrow = 3, byrow = TRUE),
  deutan = matrix(c(
     0.367322,  0.860646, -0.227968,
     0.280085,  0.672501,  0.047413,
    -0.011820,  0.042940,  0.968881
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
#' [check_figure()].
#'
#' @param colours Character vector of colours, in any form
#'   [grDevices::col2rgb()] understands.
#' @param deficiency The deficiency to simulate: `"protan"` or `"deutan"`
#'   (the two red-green forms) or `"tritan"` (blue-yellow).
#' @param severity Severity in `[0, 1]`. Zero leaves the colours unchanged and
#'   one is the full deficiency. Intermediate values interpolate the transform
#'   towards the identity, an approximation to Machado et al.'s per-severity
#'   matrices.
#'
#' @return A character vector of lower-case hex colours, the same length as
#'   `colours`.
#' @references
#' \insertRef{machado2009}{depictr}
#' @export
#' @examples
#' simulate_cvd(c("#005b96", "#e69f00"), "deutan")
#'
#' # Half severity moves the colours only part of the way.
#' simulate_cvd(c("#005b96", "#e69f00"), "deutan", severity = 0.5)
simulate_cvd <- function(colours, deficiency, severity = 1) {
  if (!is.character(deficiency) || length(deficiency) != 1 ||
      is.na(deficiency) || !deficiency %in% names(.cvd_matrices)) {
    stop("`deficiency` must be one of 'protan', 'deutan' or 'tritan'.",
         call. = FALSE)
  }
  if (!is.numeric(severity) || length(severity) != 1 || is.na(severity) ||
      severity < 0 || severity > 1) {
    stop("`severity` must lie in [0, 1].", call. = FALSE)
  }
  m <- (1 - severity) * diag(3) + severity * .cvd_matrices[[deficiency]]
  rgb <- grDevices::col2rgb(colours) / 255   # 3 x n, sRGB in [0, 1]
  out <- .linear_to_srgb(m %*% .srgb_to_linear(rgb))
  tolower(grDevices::rgb(out[1, ], out[2, ], out[3, ]))
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

#' Smallest pairwise CIE76 colour difference within a set
#'
#' Lower bound on how distinguishable a set of colours is: the minimum Euclidean
#' distance in CIE Lab space across all colour pairs. Larger is safer. The pair
#' is walked in the same order as the Python twin so that a tie between two
#' equally close pairs resolves to the same pair in both engines.
#'
#' @return A list with `distance` and `pair`, the one-based indices of the two
#'   closest colours.
#' @noRd
.min_pairwise_delta_e <- function(cols) {
  lab <- .srgb_to_lab(cols)
  n <- nrow(lab)
  best <- Inf
  pair <- c(1L, 1L)
  for (i in seq_len(n - 1)) {
    for (j in seq(i + 1, n)) {
      d <- sqrt(sum((lab[i, ] - lab[j, ])^2))
      if (d < best) {
        best <- d
        pair <- c(i, j)
      }
    }
  }
  list(distance = best, pair = pair)
}

#' Check that a palette stays distinguishable under each deficiency
#'
#' For normal vision and each deficiency at full severity, the palette's colours
#' are converted to CIE L*a*b* and the smallest pairwise colour difference
#' (CIE76 Delta-E) is found. The lower this minimum, the more likely two
#' categories are to be confused. A palette counts as safe when the minimum
#' across all four conditions is at least `threshold`.
#'
#' The default `threshold` of 5 is calibrated against the reference
#' colourblind-safe palette: the Okabe-Ito set's tightest pair (reddish purple
#' against grey) sits at Delta-E 7.4 under full deuteranopia, so the cut must
#' lie below that to pass the recommended palette, while still flagging colours
#' that become near-identical under a deficiency. The difference includes
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
#' @param threshold The smallest acceptable Delta-E.
#'
#' @return A list with `min_delta_e` (the worst case across conditions),
#'   `by_condition` (a named numeric vector, one minimum Delta-E for normal
#'   vision and for each deficiency), `worst_condition` and `worst_pair` (the
#'   closest colours and where they were closest), `safe` and `threshold`.
#' @references
#' \insertRef{okabe2008}{depictr}
#'
#' \insertRef{machado2009}{depictr}
#' @export
#' @examples
#' palette_safety()
#'
#' # Two colours a hair apart are flagged.
#' palette_safety(c("#005b96", "#015c97"))
palette_safety <- function(colours = NULL, threshold = 5) {
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
    .min_pairwise_delta_e(seen)
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
