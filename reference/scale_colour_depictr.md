# depictr colour and fill scales

Discrete ggplot2 scales using
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

## Usage

``` r
scale_colour_depictr(...)

scale_color_depictr(...)

scale_fill_depictr(...)
```

## Arguments

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
