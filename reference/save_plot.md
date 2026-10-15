# Save a plot with publication-ready defaults

A convenience wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
with sensible defaults for figures in papers and reports: a moderate
size, 300 dpi, and the output directory created if needed. The device is
inferred from the file extension, and PDF, EPS and TIFF files are
written to pass the technical checks journals run on submitted figures.
With `check = TRUE`, the figure is also audited with
[`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
at the width it is saved at.

## Usage

``` r
save_plot(
  filename,
  plot = ggplot2::last_plot(),
  width = 7,
  height = 4.5,
  units = "in",
  dpi = 300,
  check = FALSE,
  ...
)
```

## Arguments

- filename:

  Output file path. The extension sets the device (e.g. `.png`, `.pdf`,
  `.eps`, `.tiff`).

- plot:

  The plot to save; defaults to the last plot drawn.

- width, height:

  Dimensions.

- units:

  Units for `width` and `height`.

- dpi:

  Resolution for raster devices. An EPS rasterises its translucent
  layers, and whatever they overlap, at this resolution or at 600 dpi,
  whichever is higher.

- check:

  Whether to audit the figure with
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  at the width it is saved at, given as both `width_cm` and
  `render_width_cm`, so that the text sizes it reports are the printed
  ones. A warning names each check the figure fails. Defaults to
  `FALSE`. The audit runs before the file is written, so a plot it
  cannot read is refused without saving. For other thresholds, such as a
  journal's own text floor, call
  [`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md)
  with the saved width as both widths.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html),
  which passes what it does not use on to the device. A `device` or
  device argument given here overrides the defaults described under
  "Formats journals accept".

## Value

The `filename`, invisibly. With `check = TRUE`, the audit report is
attached to it as the attribute `"check"`, which `attr(, "check")`
reads.

## Formats journals accept

When no `device` is given, three formats are written differently from
ggplot2's defaults.

A PDF is written with
[`grDevices::cairo_pdf()`](https://rdrr.io/r/grDevices/cairo.html),
which embeds its fonts. ggplot2's default,
[`grDevices::pdf()`](https://rdrr.io/r/grDevices/pdf.html), names the
fonts without embedding them.

An EPS or PostScript file is written with
[`grDevices::cairo_ps()`](https://rdrr.io/r/grDevices/cairo.html), with
its fonts embedded too. PostScript has no transparency, and
[`grDevices::postscript()`](https://rdrr.io/r/grDevices/postscript.html)
leaves every translucent layer out of the file: the points and the
confidence band of the plot in the examples below vanish.
[`cairo_ps()`](https://rdrr.io/r/grDevices/cairo.html) rasterises those
layers, together with whatever they overlap, at `fallback_resolution`,
by default `max(dpi, 600)` here. A message says so when a layer of the
plot, or of any panel of a patchwork, is translucent. A PDF keeps such
layers as vector graphics.

A TIFF is compressed with LZW, which is lossless. Uncompressed, a figure
of 7 by 4.5 inches at 300 dpi takes 8.1 MiB, and one at the largest size
PLOS accepts takes more than the 10 MB PLOS allows. The TIFF is drawn on
white unless `bg` is given, so a transparent background, as in
[`ggplot2::theme_void()`](https://ggplot2.tidyverse.org/reference/ggtheme.html),
leaves no alpha channel in the file.

Without cairo, a PDF is written with
[`pdf()`](https://rdrr.io/r/grDevices/pdf.html) and a message says how
to embed its fonts with
[`grDevices::embedFonts()`](https://rdrr.io/r/grDevices/embedFonts.html),
and an EPS is written with
[`postscript()`](https://rdrr.io/r/grDevices/postscript.html) and a
warning. R for macOS from CRAN loads cairo only where XQuartz
(<https://www.xquartz.org>) is installed, and a Mac with neither XQuartz
nor ragg writes the TIFF uncompressed, with a warning from
[`grDevices::tiff()`](https://rdrr.io/r/grDevices/png.html). A `device`,
or a device argument such as `fallback_resolution`, `compression` or
`bg`, passed in `...` is used as given, so `device = "pdf"`,
`device = "eps"` or `device = "tiff"` restores ggplot2's own behaviour.

Which formats three publishers accepted on 2 October 2026:

|  |  |  |  |
|----|----|----|----|
| Format | PLOS | Nature (final artwork) | Elsevier |
| PDF | No | Yes, as vector art | Yes |
| EPS | Yes, with fonts embedded | Yes, as vector art | Yes, with fonts embedded |
| TIFF | Yes, LZW-compressed RGB or greyscale, no alpha channel, at most 10 MB | No | Yes |

Nature also asks for fonts embedded as TrueType 2 or 42, never Type 3,
and for line art and text that are not rasterised. A figure with
translucent layers therefore goes to Nature as a PDF. Elsevier asks for
a graph sent as a TIFF at 1000 dpi, so pass `dpi = 1000` for one.

The Python twin takes the plot first, as `save_plot(plot, filename)`.

## References

PLOS ONE. Figures. <https://journals.plos.org/plosone/s/figures>

Nature. Guide to preparing final artwork.
<https://www.nature.com/documents/nature-final-artwork.pdf>

Nature research figure guide. Preparing figures: our specifications.
<https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/>

Elsevier. Artwork overview.
<https://www.elsevier.com/about/policies-and-standards/author/artwork-and-media-instructions/artwork-overview>

## Examples

``` r
p <- scatter_trend(crop_yield, fertiliser, yield)
tmp <- file.path(tempdir(), "yield.png")
save_plot(tmp, p)

# A TIFF well within the 10 MB that PLOS allows.
save_plot(file.path(tempdir(), "yield.tiff"), p)

# Audited at the 8.9 cm column it is saved for, where its text prints at
# the size it is drawn.
saved <- save_plot(file.path(tempdir(), "yield-column.png"), p,
                   width = 8.9, height = 6, units = "cm", check = TRUE)
attr(saved, "check")
#>                         check measured threshold        verdict
#> 1         colour_separability       NA       5.0 not applicable
#> 2  colour_separability_protan       NA       5.0 not applicable
#> 3  colour_separability_deutan       NA       5.0 not applicable
#> 4  colour_separability_tritan       NA       5.0 not applicable
#> 5      greyscale_separability       NA       5.0 not applicable
#> 6                   text_size     8.80       6.0           pass
#> 7               text_contrast     8.45       4.5           pass
#> 8           geometry_contrast       NA       3.0 not applicable
#> 9          redundant_encoding       NA       1.0 not applicable
#> 10       annotation_text_size       NA       6.0 not applicable
#>                                                             detail
#> 1     No two encoding colours: nothing is distinguished by colour.
#> 2     No two encoding colours: nothing is distinguished by colour.
#> 3     No two encoding colours: nothing is distinguished by colour.
#> 4     No two encoding colours: nothing is distinguished by colour.
#> 5     No two encoding colours: nothing is distinguished by colour.
#> 6  Smallest text 8.80 pt, drawn at 8.90 cm and printed at 8.90 cm.
#> 7              Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.
#> 8     No two encoding colours: nothing is distinguished by colour.
#> 9     No two encoding colours: nothing is distinguished by colour.
#> 10                      The figure draws no text inside the panel.
```
