# The depictr colour palettes

Colourblind-aware palettes shared by every depictr plot. The qualitative
palette is based on the Okabe-Ito set (Okabe & Ito, 2008), a widely
recommended categorical palette that stays distinguishable under the
common forms of colour-vision deficiency, with the depictr brand blue
leading. The sequential and diverging palettes are perceptually ordered
single-hue and red-blue ramps.

## Usage

``` r
depictr_palette(
  n = NULL,
  type = c("qualitative", "sequential", "diverging"),
  order = c("default", "contrast")
)
```

## Arguments

- n:

  Number of colours to return. If `NULL` (the default) the full
  qualitative palette is returned. For the qualitative palette an `n`
  larger than the available base colours is interpolated; the sequential
  and diverging palettes are ramps and accept any `n`. Interpolating the
  built-in qualitative palette beyond its eight base colours loses the
  colour-vision-deficiency guarantee and warns, so facet the groups or
  use the sequential ramp when many groups are needed.

- type:

  Palette type: `"qualitative"` (categorical groups), `"sequential"`
  (ordered low-to-high) or `"diverging"` (a midpoint with two
  directions).

- order:

  The order of the built-in qualitative palette: `"default"`, or
  `"contrast"` for the contrast-first order described below. The ramps
  have an order of their own and refuse `"contrast"`.

## Value

A character vector of hex colour codes.

## Details

The guarantee belongs to the eight Okabe-Ito colours themselves, not to
any number of colours: past eight the qualitative palette has to
interpolate between them, and the interpolated colours sit close enough
together to fail the package's own colour-distance check. That case
warns rather than handing back colours under a guarantee it cannot keep.

The qualitative palette can be overridden globally with
`options(depictr.palette = )` (see
[`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md));
when set, that custom palette replaces the built-in Okabe-Ito set and is
interpolated when more colours are requested than it provides. The
sequential and diverging ramps are unaffected.

## The contrast-first order

In the default order the second colour is the orange (`#e69f00`), at
2.25:1 against white. Any figure on white whose colour tells two or more
groups apart therefore fails the `geometry_contrast` row of
[`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md).
No more than three of the eight colours pass every colour row of that
audit together.

`order = "contrast"` puts those three first: the brand blue, the
vermillion (`#d55e00`) and the reddish purple (`#cc79a7`), then the
bluish green (`#009e73`) and the other four in their default order. Up
to three groups then pass every colour row, contrast against white
included. They stay at least 14.01 apart in CIEDE2000 under every vision
type, 6.86 apart in lightness and 3.06:1 against white. Four groups keep
3:1 against white, but the bluish green and the vermillion are 3.31
apart in lightness, which fails `greyscale_separability`. Asking for
more than four colours warns, since the fifth, the orange, falls below
3:1.

Under this order, the second group is drawn in the vermillion. That is
also the accent
([`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md))
that depictr uses for single highlights, such as the flagged points of
[`outlier_plot()`](https://pablobernabeu.github.io/depictr/reference/outlier_plot.md)
and the missing cells of
[`missingness_map()`](https://pablobernabeu.github.io/depictr/reference/missingness_map.md).
The default order is unchanged.

The order applies to the built-in palette alone. A palette set with
`depictr_options(palette = )` is the user's own, so it is returned in
the order it was set, with a warning. That is also how to make the order
the default for every later plot:
`depictr_options(palette = depictr_palette(order = "contrast"))`. The
palette is then the user's own, so asking for more than four colours no
longer warns.
[`scale_colour_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
and
[`scale_fill_depictr()`](https://pablobernabeu.github.io/depictr/reference/scale_colour_depictr.md)
take `order` for a single plot.

## References

Okabe M, Ito K (2008). “Color Universal Design (CUD): How to make
figures and presentations that are friendly to colorblind people.”
<https://jfly.uni-koeln.de/color/>. Accessed 2026-06-14.

World Wide Web Consortium (2023). “Web Content Accessibility Guidelines
(WCAG) 2.2.” W3C Recommendation, <https://www.w3.org/TR/WCAG22/>.
Accessed 2026-08-18.

## Examples

``` r
depictr_palette(3)
#> [1] "#005b96" "#e69f00" "#009e73"
depictr_palette(3, order = "contrast")
#> [1] "#005b96" "#d55e00" "#cc79a7"
depictr_palette(7, type = "sequential")
#> [1] "#E6EFF5" "#98BFDA" "#4A8FC0" "#2475AB" "#005B96" "#034678" "#08315A"
scales::show_col(depictr_palette())
```
