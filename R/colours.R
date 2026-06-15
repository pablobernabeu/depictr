# Internal colour accessors --------------------------------------------------
#
# Single source of truth for the named brand colours used across depictr.
# Plotting functions should call these accessors instead of repeating hex
# literals, so the palette can be changed in exactly one place. The full
# categorical palette lives in `depictr_palette()` (see theme_depictr.R); these
# helpers name the three colours that recur on their own outside that palette.

#' depictr brand blue
#'
#' The primary brand colour, used for single-series geoms, titles and the
#' default point colour on forest/caterpillar plots. Equal to
#' `depictr_palette(1)[1]` (the leading colour of the qualitative palette).
#'
#' @return A single hex colour string.
#' @keywords internal
#' @noRd
depictr_brand <- function() "#005b96"

#' depictr accent colour
#'
#' A secondary highlight colour for drawing attention to a single element
#' against the brand blue. This is the Okabe-Ito vermillion (Okabe & Ito,
#' 2008), chosen because it stays distinguishable from the brand blue under the
#' common forms of colour-vision deficiency.
#'
#' @return A single hex colour string.
#' @keywords internal
#' @noRd
depictr_accent <- function() "#d55e00"

#' depictr reference-line colour
#'
#' The muted grey used for reference lines (zero lines, identity lines, decision
#' thresholds) so they recede behind the data.
#'
#' @return A single grey colour string.
#' @keywords internal
#' @noRd
depictr_reference <- function() "grey60"
