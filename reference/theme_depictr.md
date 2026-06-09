# The depictr ggplot2 theme

A clean, minimal theme used by every plotting function in the package.
It is a light modification of
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
with subtle gridlines, centred titles and comfortable margins.

## Usage

``` r
theme_depictr(base_size = 11, base_family = "", grid = "xy")
```

## Arguments

- base_size:

  Base font size, in points.

- base_family:

  Base font family.

- grid:

  Which major gridlines to keep: `"xy"`, `"x"`, `"y"` or `"none"`.

## Value

A ggplot2 theme object.

## Examples

``` r
library(ggplot2)
ggplot(crop_yield, aes(fertilizer, yield)) +
  geom_point() +
  theme_depictr()
```
