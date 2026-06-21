# depictr colour and fill scales

Discrete ggplot2 scales using
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).
These are the canonical colour and fill scales used throughout the
package. They honour the global `options(depictr.palette = )` (via
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md))
and `options(depictr.na_value = )` settings; see
[`depictr_options()`](https://pablobernabeu.github.io/depictr/reference/depictr_options.md).

## Usage

``` r
scale_colour_depictr(
  n = NULL,
  palette = NULL,
  na.value = depictr_opt("na_value"),
  ...
)

scale_color_depictr(
  n = NULL,
  palette = NULL,
  na.value = depictr_opt("na_value"),
  ...
)

scale_fill_depictr(
  n = NULL,
  palette = NULL,
  na.value = depictr_opt("na_value"),
  ...
)
```

## Arguments

- n:

  Optional number of colours to draw from
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).
  By default ggplot2 requests exactly as many colours as there are
  groups; pass `n` only to force a fixed slice of the palette.

- palette:

  Optional palette override: a function of one argument (the number of
  colours) returning a character vector of colours. Defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- na.value:

  Colour for `NA` levels. Defaults to the resolved `depictr.na_value`
  option (the muted grey `"grey80"` unless changed).

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 scale that can be added to a plot.

## Examples

``` r
library(ggplot2)
ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
  geom_point() +
  scale_colour_depictr() +
  theme_depictr()
```
