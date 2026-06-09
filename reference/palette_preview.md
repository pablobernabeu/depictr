# Preview the depictr palettes

Displays the colours returned by
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
as labelled swatches – handy when choosing how many groups to show,
picking a palette type, or documenting a figure.

## Usage

``` r
palette_preview(
  n = 8,
  type = c("qualitative", "sequential", "diverging", "all")
)
```

## Arguments

- n:

  Number of colours to preview.

- type:

  Palette type to preview: `"qualitative"`, `"sequential"`,
  `"diverging"`, or `"all"` to show all three.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
palette_preview()

palette_preview(7, type = "sequential")

palette_preview(type = "all")
```
