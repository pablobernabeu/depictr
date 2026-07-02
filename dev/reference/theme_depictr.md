# The depictr ggplot2 theme

A clean, minimal theme used by every plotting function in the package.
It is a light modification of
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
with subtle gridlines, centred titles and comfortable margins.

## Usage

``` r
theme_depictr(
  base_size = depictr_opt("base_size"),
  base_family = depictr_opt("base_family"),
  grid = "xy"
)
```

## Arguments

- base_size:

  Base font size, in points. Defaults to the `depictr.base_size` option.

- base_family:

  Base font family. Defaults to the `depictr.base_family` option.

- grid:

  Which major gridlines to keep: `"xy"`, `"x"`, `"y"` or `"none"`.

## Value

A ggplot2 theme object.

## Details

The default `base_size` and `base_family` come from the global options
`depictr.base_size` and `depictr.base_family` (see
[`depictr_options()`](https://pablobernabeu.github.io/depictr/dev/reference/depictr_options.md)),
so the package-wide font size can be set once; passing the arguments
explicitly overrides them. The title colour is the resolved
`depictr_brand()`, which in turn honours `options(depictr.brand = )`.

## Examples

``` r
library(ggplot2)
ggplot(crop_yield, aes(fertiliser, yield)) +
  geom_point() +
  theme_depictr()
```
