# The depictr colour palettes

Colourblind-aware palettes shared by every depictr plot. The qualitative
palette is based on the Okabe-Ito set (Okabe & Ito, 2008), a widely
recommended categorical palette that stays distinguishable under the
common forms of colour-vision deficiency, with the depictr brand blue
leading. The sequential and diverging palettes are perceptually ordered
single-hue and red-blue ramps.

## Usage

``` r
depictr_palette(n = NULL, type = c("qualitative", "sequential", "diverging"))
```

## Arguments

- n:

  Number of colours to return. If `NULL` (the default) the full
  qualitative palette is returned. For the qualitative palette an `n`
  larger than the available base colours is interpolated; the sequential
  and diverging palettes are ramps and accept any `n`.

- type:

  Palette type: `"qualitative"` (categorical groups), `"sequential"`
  (ordered low-to-high) or `"diverging"` (a midpoint with two
  directions).

## Value

A character vector of hex colour codes.

## Details

The qualitative palette can be overridden globally with
`options(depictr.palette = )` (see
[`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md));
when set, that custom palette replaces the built-in Okabe-Ito set and is
interpolated when more colours are requested than it provides. The
sequential and diverging ramps are unaffected.

## References

Okabe M, Ito K (2008). “Color Universal Design (CUD): How to make
figures and presentations that are friendly to colorblind people.”
<https://jfly.uni-koeln.de/color/>. Accessed 2026-06-14.

## Examples

``` r
depictr_palette(3)
#> [1] "#005b96" "#e69f00" "#009e73"
depictr_palette(7, type = "sequential")
#> [1] "#E6EFF5" "#98BFDA" "#4A8FC0" "#2475AB" "#005B96" "#034678" "#08315A"
scales::show_col(depictr_palette())
```
