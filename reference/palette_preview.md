# Preview the depictr palettes

Displays the colours returned by
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
as labelled swatches. It is useful when choosing how many groups to
show, selecting a palette type, or documenting a figure. Each swatch's
hex label is drawn in near-black or white, whichever is more legible
against that tile (chosen by the tile's relative luminance), so labels
stay readable on both light and dark colours.

## Usage

``` r
palette_preview(
  n = 8,
  type = c("qualitative", "sequential", "diverging", "all"),
  cvd = c("none", "deutan", "protan", "tritan")
)
```

## Arguments

- n:

  Number of colours to preview.

- type:

  Palette type to preview: `"qualitative"`, `"sequential"`,
  `"diverging"`, or `"all"` to show all three.

- cvd:

  Colour-vision-deficiency simulation for the tiles: `"none"` (the
  default, true colours), `"deutan"` (red-green, deuteranopia),
  `"protan"` (red-green, protanopia) or `"tritan"` (blue-yellow,
  tritanopia).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Set `cvd` to render the swatches as they would appear under a
colour-vision deficiency, using the Machado et al. (2009) simulation.
The tiles are recoloured to the simulated appearance while the labels
keep the *original* hex code, so you can check at a glance whether two
groups would still be told apart by a colourblind reader.

## References

Machado GM, Oliveira MM, Fernandes LAF (2009). “A Physiologically-Based
Model for Simulation of Color Vision Deficiency.” *IEEE Transactions on
Visualization and Computer Graphics*, **15**(6), 1291–1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113) .

## Examples

``` r
palette_preview()

palette_preview(7, type = "sequential")

palette_preview(type = "all")

palette_preview(cvd = "deutan")
```
