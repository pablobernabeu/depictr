# Audit a finished figure for accessibility and honesty

Checks a figure as it will be submitted, rather than the palette it was
built from.
[`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
can promise that the eight colours depictr ships stay apart under
colour-vision deficiency, but it knows nothing about the figure in front
of you: how many of those colours it uses, what you replaced them with,
how small the text will be once the figure is squeezed into a journal
column, or whether the only thing separating two groups is their colour.
`check_figure()` reads the built plot and answers those questions with
numbers.

## Usage

``` r
check_figure(
  plot,
  width_cm = 17.78,
  render_width_cm = 17.78,
  min_delta_e = 5,
  min_text_pt = 6,
  metric = c("ciede2000", "cie76")
)
```

## Arguments

- plot:

  A plot, as returned by any depictr plotting function, including one
  extended afterwards with `+`, or a multi-panel composite (see
  "Composites").

- width_cm:

  The width, in centimetres, that the figure will occupy in the finished
  document. Defaults to 17.78 cm, the seven inches
  [`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
  draws at, which means no scaling.

- render_width_cm:

  The width, in centimetres, that the figure is drawn at. Defaults to
  the same 17.78 cm. The ratio of the two widths is the factor every
  point size is multiplied by.

- min_delta_e:

  The smallest acceptable colour difference, on the scale of `metric`,
  for the colour separability checks, and the smallest acceptable
  difference in lightness for the greyscale check. Defaults to 5,
  matching
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md).

- min_text_pt:

  The smallest acceptable printed text size, in points, for the text
  around the panel and the text inside it alike. Defaults to 6, below
  the floor most journals set (see "Auditing at the printed size").

- metric:

  The colour difference the colour separability checks measure:
  `"ciede2000"`, the default, or `"cie76"`, the Euclidean distance in
  CIELAB that earlier versions measured. `"cie76"` is kept so that
  earlier results can be reproduced, and a later release will remove it.

## Value

A data frame with one row per check and columns `check`, `measured`,
`threshold`, `verdict` (`"pass"`, `"fail"` or `"not applicable"`) and
`detail`, a short note naming what produced the measurement. For a
composite, the rows of each panel in turn, after a leading integer
column `panel`.

## Details

Every row carries the value it measured next to the threshold it was
measured against, so a verdict can be argued with rather than merely
accepted. A check passes when the measured value is at least the
threshold. A check that has nothing to measure, such as colour
separability on a figure that encodes nothing by colour, reports `NA`
and a verdict of `"not applicable"` instead of a free pass.

## What each check measures

Colours and text are measured as drawn. A translucent colour is
composited over the background it is drawn on with the alpha it is drawn
with, so it is measured as the paler colour the reader sees. As ggplot2
draws them, bars, tiles, areas, densities, ribbons, polygons, violins,
boxplots, crossbars and smooths apply a layer's alpha to their fill and
leave the outline opaque. Lines, paths, segments, error bars and
reference lines apply it to their colour, and points apply it to both.
Any other geom is taken to apply it to both, the cautious assumption. A
colour that carries its own alpha keeps it when the layer sets none, as
ggplot2 draws it. A colour drawn at several alphas within one layer is
measured at the smallest. Where marks overlap one another, the colour
that shows depends on what lies beneath it, and that is not measured.

`colour_separability` is the smallest colour difference between two of
the figure's encoding colours, by the CIEDE2000 formula (Sharma, Wu &
Dalal, 2005) unless `metric` asks for the older CIE76. The three
`colour_separability_*` rows repeat that measurement after simulating
each dichromacy at full severity with
[`simulate_cvd()`](https://pablobernabeu.github.io/depictr/reference/simulate_cvd.md).
Encoding colours are the distinct colour and fill values that tell
groups apart. A layer contributes its colours when it maps colour or
fill to a discrete scale, even if it draws a single colour, or when it
draws two or more. Groups drawn one per layer are therefore audited as
they would be in one layer. A colour set as a constant, as in
`geom_point(colour = "red")`, is left out, even when another layer sets
a different one, and so is a lone colour passed through
[`ggplot2::scale_colour_identity()`](https://ggplot2.tidyverse.org/reference/scale_identity.html).
The audit cannot tell such a colour from decoration, so a colour meant
to tell groups apart should be mapped, with
[`ggplot2::scale_colour_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
to fix its values. The outline colours, across every layer, are compared
among themselves, and so are the fill colours, and the row reports the
closest pair from either set. An outline is therefore never compared
with its own fill, nor a group with itself as another layer draws it.

A continuous colour or fill scale, such as a heatmap's, is a smooth ramp
rather than a set of codes, and none of the colour rows audits it. When
nothing else in the figure encodes by colour, each of them abstains with
a `detail` that says so. Whether a ramp reads in order, to a reader with
a colour-vision deficiency and in greyscale as well, depends on how
evenly its lightness changes, which the audit does not measure. Prefer a
perceptually ordered map, such as viridis or depictr's sequential and
diverging ramps, over a rainbow (Crameri et al., 2020).

`greyscale_separability` is the smallest difference in CIE lightness
between those same colours, which is what survives printing in black and
white. It is the absolute difference in lightness, whichever `metric`
the colour rows use.

`text_size` is the smallest point size of the text the theme draws
around the panel: axis labels and titles, legends, facet strips, titles
and captions. It is scaled by `width_cm / render_width_cm`, so a figure
drawn seven inches wide and printed in an 8.9 cm column has every point
size halved. Text drawn inside the panel is measured by
`annotation_text_size`.

`text_contrast` is the WCAG 2.2 contrast ratio of the text that falls
furthest short of its own threshold. Each text is measured against the
background it is drawn on: a facet strip's fill for strip text, the
legend box's fill for legend text, and the plot background for the rest.
A translucent fill is measured as the colour it shows over what lies
beneath it, and so is text drawn with an alpha. Text that is large at
its printed size, 18 pt or 14 pt in bold, is held to 3:1, and other text
to 4.5:1, as success criterion 1.4.3 asks. The row's `threshold` is the
one that applies to the text it reports, and its `detail` names that
text's colour, background, printed size and weight.

`geometry_contrast` is the smallest WCAG 2.2 contrast ratio of any
encoded group's drawn colour against the panel background, or against
the plot background where the panel paints none. Where a layer maps its
outline colour to the same groups as its fill, each group counts the
better of the two, since WCAG lets a border carry a graphical object's
contrast. For a translucent colour, the `detail` names the colour, its
alpha and the colour it is drawn as.

`redundant_encoding` counts how many of shape and line type also vary
across the layers that draw the encoding colours. They are gathered as
the colours are. A layer contributes the values it maps to a discrete
scale, or the two or more it draws, and a shape or line type set as a
constant is left out. Zero means the distinction between groups is
carried by colour alone, which is the single most common way an
otherwise careful figure becomes unreadable.

`annotation_text_size` is the smallest point size of the text drawn
inside the panel, scaled as `text_size` is and held to the same
`min_text_pt`. That text comes from layers such as
[`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
and
[`ggplot2::geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html),
from annotations, and from depictr's own cell values and labels. Its
contrast is not measured, since it sits on the marks rather than on one
background. A label that a layer builds only when the figure is drawn,
as ggrepel builds its repelled labels, is not yet in the built plot, so
it is not measured either.

## Limitations of the default palette

The eight-colour qualitative palette clears the colour-separability
checks comfortably and fails `greyscale_separability`: its orange
(`#e69f00`) and sky blue (`#56b4e9`) differ by only 0.79 in lightness,
so they print as the same grey. The colourblind-safety guarantee depictr
makes is about hue confusion, and it was never a claim about greyscale.
A figure that may be printed in black and white should use fewer groups,
or a sequential palette, or add a redundant shape or line type; the four
leading colours of the palette are also not safe in greyscale, since the
bluish green and the vermillion differ by 3.55. The threshold has been
left where it is rather than moved to let the package's own defaults
through.

The palette falls short on contrast as well. Four of its eight colours
are below the 3:1 against white that WCAG asks of a graphical object:
the orange at 2.25:1, the sky blue at 2.31:1, the grey at 2.85:1 and the
yellow at 1.32:1. The orange is the second colour, so a default figure
on white whose colour tells two or more groups apart fails
`geometry_contrast`, and drawing its marks translucent lowers the ratio
further. Opaque marks, the vermillion (`#d55e00`, at 3.87:1) in the
orange's place and a redundant shape clear that row and
`redundant_encoding`, as the first example below shows.

## Auditing at the printed size

Text is drawn in points, so the size it prints at depends on the two
widths. A figure drawn at the size it will be printed, as
[`save_plot()`](https://pablobernabeu.github.io/depictr/reference/save_plot.md)
draws one given `width = 8.9, units = "cm"`, needs no scaling. Pass the
saved width as both `width_cm` and `render_width_cm`, or leave both at
their defaults. Given alone, `width_cm` audits the figure as though it
had been drawn seven inches wide and then shrunk to fit.

The default `min_text_pt` of 6 is lenient. As their guidelines stood on
30 September 2026, PLOS asked for text of 8 to 12 pt and APA Style for 8
to 14 pt. Elsevier asked for 7 pt as a rule of thumb, and Nature for 5
to 7 pt, with panel labels at 8 pt. Pass the floor of the journal the
figure is for as `min_text_pt`. The four pages are listed under
References.

## Composites

A composite, such as
[`arrange_plots()`](https://pablobernabeu.github.io/depictr/reference/arrange_plots.md),
[`residual_diagnostics_plot()`](https://pablobernabeu.github.io/depictr/reference/residual_diagnostics_plot.md)
and
[`model_report()`](https://pablobernabeu.github.io/depictr/reference/model_report.md)
return, is audited panel by panel. Each panel has its own scales, theme
and text, so each is audited as it would be on its own. The reports are
stacked under a leading integer column, `panel`, which only the report
of a composite has. The widths are those of the whole composite. A
panel's text keeps its point size whatever share of the width the panel
takes, so the text of every panel scales by the same ratio.

Panels are numbered depth-first through any composite nested inside, in
the order the composite holds them. That is the order patchwork tags
them in, and the reading order of a grid filled row by row. A spacer or
a guide area draws no figure of its own and takes no number. A wrapped
element, such as a grob or a table, cannot be read, so it keeps its
number and is left out of the report with a warning.

A panel's legend is measured with the panel, as the panel would draw it
on its own, even when `guides = "collect"` gathers it into one legend
for the composite. What the composite draws around its panels is not
measured: the title, subtitle and caption of
[`patchwork::plot_annotation()`](https://patchwork.data-imaginist.com/reference/plot_annotation.html)
and the panel tags.

## References

APA Style. Figures.
<https://apastyle.apa.org/style-grammar-guidelines/tables-figures/figures>

Crameri F, Shephard GE, Heron PJ (2020). “The misuse of colour in
science communication.” *Nature Communications*, **11**(1), 5444.
[doi:10.1038/s41467-020-19160-7](https://doi.org/10.1038/s41467-020-19160-7)
.

Elsevier. Artwork sizing.
<https://www.elsevier.com/about/policies-and-standards/author/artwork-and-media-instructions/artwork-sizing>

Machado GM, Oliveira MM, Fernandes LAF (2009). “A physiologically-based
model for simulation of color vision deficiency.” *IEEE Transactions on
Visualization and Computer Graphics*, **15**(6), 1291–1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113) .

Nature. Guide to preparing final artwork.
<https://www.nature.com/documents/nature-final-artwork.pdf>

PLOS ONE. Figures. <https://journals.plos.org/plosone/s/figures>

Sharma G, Wu W, Dalal EN (2005). “The CIEDE2000 color-difference
formula: Implementation notes, supplementary test data, and mathematical
observations.” *Color Research & Application*, **30**(1), 21–30.
[doi:10.1002/col.20070](https://doi.org/10.1002/col.20070) .

World Wide Web Consortium (2023). “Web Content Accessibility Guidelines
(WCAG) 2.2.” W3C Recommendation, <https://www.w3.org/TR/WCAG22/>.
Accessed 2026-08-18.

## See also

[`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
for the palette in the abstract, and
[`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)
to look at it.

## Examples

``` r
library(ggplot2)

# A figure that clears every check it can be held to: two well-separated
# colours, a redundant shape, and text left at the size it was drawn. It
# draws no text inside the panel, so that row is not applicable.
good <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
                               shape = treatment)) +
  geom_point() +
  scale_colour_manual(values = c("#005b96", "#d55e00")) +
  theme_depictr()
check_figure(good)
#>                         check measured threshold        verdict
#> 1         colour_separability    50.12       5.0           pass
#> 2  colour_separability_protan    49.67       5.0           pass
#> 3  colour_separability_deutan    58.30       5.0           pass
#> 4  colour_separability_tritan    61.99       5.0           pass
#> 5      greyscale_separability    16.92       5.0           pass
#> 6                   text_size     8.80       6.0           pass
#> 7               text_contrast     8.45       4.5           pass
#> 8           geometry_contrast     3.87       3.0           pass
#> 9          redundant_encoding     1.00       1.0           pass
#> 10       annotation_text_size       NA       6.0 not applicable
#>                                                               detail
#> 1            Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 2            Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 3            Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 4            Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 5                 Closest pair #005b96 and #d55e00 in CIE lightness.
#> 6  Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.
#> 7                Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.
#> 8                         Lowest-contrast colour #d55e00 on #ffffff.
#> 9                                         Colour is joined by shape.
#> 10                        The figure draws no text inside the panel.

# The same figure destined for an 8.9 cm journal column, where the text is
# half the size it looks on screen.
check_figure(good, width_cm = 8.9)
#>                         check measured threshold        verdict
#> 1         colour_separability    50.12       5.0           pass
#> 2  colour_separability_protan    49.67       5.0           pass
#> 3  colour_separability_deutan    58.30       5.0           pass
#> 4  colour_separability_tritan    61.99       5.0           pass
#> 5      greyscale_separability    16.92       5.0           pass
#> 6                   text_size     4.40       6.0           fail
#> 7               text_contrast     8.45       4.5           pass
#> 8           geometry_contrast     3.87       3.0           pass
#> 9          redundant_encoding     1.00       1.0           pass
#> 10       annotation_text_size       NA       6.0 not applicable
#>                                                              detail
#> 1           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 2           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 3           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 4           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 5                Closest pair #005b96 and #d55e00 in CIE lightness.
#> 6  Smallest text 8.80 pt, drawn at 17.78 cm and printed at 8.90 cm.
#> 7               Lowest-contrast text #4d4d4d on #ffffff at 4.40 pt.
#> 8                        Lowest-contrast colour #d55e00 on #ffffff.
#> 9                                        Colour is joined by shape.
#> 10                       The figure draws no text inside the panel.

# Saved at 8.9 cm in the first place, with save_plot(width = 8.9,
# units = "cm"), it is drawn at the size it prints, so both widths are 8.9.
check_figure(good, width_cm = 8.9, render_width_cm = 8.9)
#>                         check measured threshold        verdict
#> 1         colour_separability    50.12       5.0           pass
#> 2  colour_separability_protan    49.67       5.0           pass
#> 3  colour_separability_deutan    58.30       5.0           pass
#> 4  colour_separability_tritan    61.99       5.0           pass
#> 5      greyscale_separability    16.92       5.0           pass
#> 6                   text_size     8.80       6.0           pass
#> 7               text_contrast     8.45       4.5           pass
#> 8           geometry_contrast     3.87       3.0           pass
#> 9          redundant_encoding     1.00       1.0           pass
#> 10       annotation_text_size       NA       6.0 not applicable
#>                                                             detail
#> 1          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 2          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 3          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 4          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 5               Closest pair #005b96 and #d55e00 in CIE lightness.
#> 6  Smallest text 8.80 pt, drawn at 8.90 cm and printed at 8.90 cm.
#> 7              Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.
#> 8                       Lowest-contrast colour #d55e00 on #ffffff.
#> 9                                       Colour is joined by shape.
#> 10                      The figure draws no text inside the panel.

# Each panel of a composite is audited, and a column says which panel each
# row describes. At base size 5, the second panel's text is too small.
small <- good + theme_depictr(base_size = 5)
both <- check_figure(arrange_plots(good, small))
both[both$verdict == "fail", c("panel", "check", "measured")]
#>    panel     check measured
#> 16     2 text_size        4
```
