# Global options: set the depictr look once -----------------------------------

# The package-level defaults. These are the values used when the matching
# `options(depictr.*)` entry is unset. Everything that is theming-related
# resolves through `depictr_opt()` so that a single global option flows through
# the theme, the palettes, the scales and the colour accessors.
.depictr_option_defaults <- list(
  base_size   = 11,
  base_family = "",
  brand       = "#005b96",
  accent      = "#d55e00",
  reference   = "grey60",
  palette     = NULL,
  na_value    = "grey80"
)

#' Resolve a single depictr option
#'
#' Internal accessor that returns the global `options(depictr.<name>)` value if
#' it is set, otherwise the package default. Keeping this in one place means the
#' theme, palettes, scales and colour accessors all honour the same options.
#'
#' @param name Option name without the `depictr.` prefix.
#' @return The resolved option value.
#' @noRd
depictr_opt <- function(name) {
  if (!name %in% names(.depictr_option_defaults)) {
    stop("Unknown depictr option: ", name, call. = FALSE)
  }
  val <- getOption(paste0("depictr.", name), default = NULL)
  if (is.null(val)) .depictr_option_defaults[[name]] else val
}

#' Get or set the depictr look-and-feel options
#'
#' depictr reads a small set of global options so that you can configure the
#' shared look of every plot once, at the top of a script or in your
#' `.Rprofile`, instead of passing the same arguments to each function. The
#' options are honoured by [theme_depictr()] (base size, base family and the
#' brand colour used for titles), by [depictr_palette()] and the
#' [scale_colour_depictr()] family (an optional custom qualitative palette), and
#' by the colour accessors `depictr_brand()`, `depictr_accent()` and
#' `depictr_reference()`.
#'
#' Called with no arguments, `depictr_options()` returns the currently resolved
#' values (option if set, otherwise package default). Called with named
#' arguments it sets the matching `options(depictr.<name> = )` entries and
#' returns the *previous* resolved values invisibly, so the pattern
#' `old <- depictr_options(...); on.exit(do.call(depictr_options, old))` restores
#' them. Pass `NULL` for an argument to clear that option and fall back to the
#' package default.
#'
#' @param base_size Base font size in points for [theme_depictr()].
#' @param base_family Base font family for [theme_depictr()].
#' @param brand The depictr brand colour, used for plot titles and single-series
#'   geoms. It coincides with the default palette's first colour but does not
#'   alter a palette; use `palette` for that. Returned by `depictr_brand()`.
#' @param accent A secondary highlight colour. Returned by `depictr_accent()`.
#' @param reference The colour used for reference / annotation lines. Returned
#'   by `depictr_reference()`.
#' @param palette An optional custom qualitative palette: a character vector of
#'   hex colours used by [depictr_palette()] (type `"qualitative"`) and the
#'   discrete scales in place of the built-in Okabe-Ito set. `NULL` restores the
#'   built-in palette.
#' @param na_value Colour used for `NA` levels by [scale_colour_depictr()] and
#'   [scale_fill_depictr()].
#'
#' @return A named list of the resolved option values. When setting, the
#'   *previous* values are returned invisibly.
#' @export
#' @examples
#' # Inspect the current settings
#' depictr_options()
#'
#' # Set a larger base size and a different accent, then restore
#' old <- depictr_options(base_size = 14, accent = "#e69f00")
#' theme_depictr()              # now uses base_size 14
#' do.call(depictr_options, old)
#'
#' # Use a custom qualitative palette everywhere
#' old <- depictr_options(palette = c("#1b9e77", "#d95f02", "#7570b3"))
#' depictr_palette(3)
#' do.call(depictr_options, old)
depictr_options <- function(base_size, base_family, brand, accent, reference,
                            palette, na_value) {
  known <- names(.depictr_option_defaults)

  # Snapshot the currently resolved values (for the return value / restoring).
  current <- stats::setNames(lapply(known, depictr_opt), known)

  # Collect only the arguments the caller actually supplied. Using
  # `supplied[name] <- list(value)` (rather than `supplied$name <- value`) is
  # essential: it preserves an explicitly supplied NULL as a list element, so
  # NULL can flow through to options() and clear that option. `supplied$x <- NULL`
  # would instead *remove* the element and the option would never be reset --
  # breaking the documented "pass NULL to restore the default" contract.
  supplied <- list()
  if (!missing(base_size))   supplied["base_size"]   <- list(base_size)
  if (!missing(base_family)) supplied["base_family"] <- list(base_family)
  if (!missing(brand))       supplied["brand"]       <- list(brand)
  if (!missing(accent))      supplied["accent"]      <- list(accent)
  if (!missing(reference))   supplied["reference"]   <- list(reference)
  if (!missing(palette))     supplied["palette"]     <- list(palette)
  if (!missing(na_value))    supplied["na_value"]    <- list(na_value)

  if (length(supplied) == 0) {
    return(current)
  }

  validate_depictr_options(supplied)

  # Build the options() payload, prefixing each name. A NULL value in the list
  # clears that option via options(name = NULL), so getOption() then falls back
  # to the package default -- exactly the documented restore behaviour.
  payload <- stats::setNames(supplied, paste0("depictr.", names(supplied)))
  do.call(options, payload)

  invisible(current)
}

#' Validate user-supplied depictr options
#' @noRd
validate_depictr_options <- function(supplied) {
  is_one_number <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  is_one_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x)

  if (!is.null(supplied$base_size) && !is_one_number(supplied$base_size)) {
    stop("`base_size` must be a single finite number.", call. = FALSE)
  }
  if (!is.null(supplied$base_size) && supplied$base_size <= 0) {
    stop("`base_size` must be positive.", call. = FALSE)
  }
  if (!is.null(supplied$base_family) && !is_one_string(supplied$base_family)) {
    stop("`base_family` must be a single string.", call. = FALSE)
  }
  for (nm in c("brand", "accent", "reference", "na_value")) {
    val <- supplied[[nm]]
    if (!is.null(val)) {
      if (!is_one_string(val) || !is_colour(val)) {
        stop("`", nm, "` must be a single valid colour.", call. = FALSE)
      }
    }
  }
  if (!is.null(supplied$palette)) {
    pal <- supplied$palette
    if (!is.character(pal) || length(pal) < 1L || anyNA(pal) ||
        !all(is_colour(pal))) {
      stop("`palette` must be a character vector of valid colours, or NULL.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Is `x` a valid colour specification recognised by grDevices?
#' @noRd
is_colour <- function(x) {
  vapply(x, function(col) {
    tryCatch({
      grDevices::col2rgb(col)
      TRUE
    }, error = function(e) FALSE)
  }, logical(1))
}
