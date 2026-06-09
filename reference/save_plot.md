# Save a plot with publication-ready defaults

A convenience wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
with sensible defaults for figures in papers and reports: a moderate
size, 300 dpi, and the output directory created if needed. The device is
inferred from the file extension.

## Usage

``` r
save_plot(
  filename,
  plot = ggplot2::last_plot(),
  width = 7,
  height = 4.5,
  units = "in",
  dpi = 300,
  ...
)
```

## Arguments

- filename:

  Output file path. The extension sets the device (e.g. `.png`, `.pdf`,
  `.tiff`).

- plot:

  The plot to save; defaults to the last plot drawn.

- width, height:

  Dimensions.

- units:

  Units for `width` and `height`.

- dpi:

  Resolution for raster devices.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The `filename`, invisibly.

## Examples

``` r
p <- scatter_trend(crop_yield, fertilizer, yield)
tmp <- file.path(tempdir(), "yield.png")
save_plot(tmp, p)
```
