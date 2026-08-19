# Audit a finished figure for accessibility and honesty

Checks a figure as it will be submitted, rather than the palette it was
built from.
[`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md)
can promise that the eight colours depictr ships stay apart under
colour-vision deficiency, but it knows nothing about the figure in front
of you: how many of those colours it actually uses, what you replaced
them with, how small the text will be once the figure is squeezed into a
journal column, or whether the only thing separating two groups is their
colour. `check_figure()` reads the built plot and answers those
questions with numbers.

## Usage

``` r
check_figure(
  plot,
  width_cm = 17.78,
  render_width_cm = 17.78,
  min_delta_e = 5,
  min_text_pt = 6
)
```

## Arguments

- plot:

  A plot, as returned by any depictr plotting function, including one
  extended afterwards with `+`.

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

  The smallest acceptable CIE76 colour difference, used for the colour
  and greyscale separability checks. Defaults to 5, matching
  [`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md).

- min_text_pt:

  The smallest acceptable printed text size, in points. Defaults to 6, a
  common publisher floor for figure text.

## Value

A data frame with one row per check and columns `check`, `measured`,
`threshold`, `verdict` (`"pass"`, `"fail"` or `"not applicable"`) and
`detail`, a short note naming what produced the measurement.

## Details

Every row carries the value it measured next to the threshold it was
measured against, so a verdict can be argued with rather than merely
accepted. A check passes when the measured value is at least the
threshold. A check that has nothing to measure, such as colour
separability on a figure that encodes nothing by colour, reports `NA`
and a verdict of `"not applicable"` instead of a free pass.

## What each check measures

`colour_separability` is the smallest CIE76 colour difference (Delta-E)
between any two of the figure's encoding colours, and the three
`colour_separability_*` rows repeat that measurement after simulating
each dichromacy at full severity with
[`simulate_cvd()`](https://pablobernabeu.github.io/depictr/reference/simulate_cvd.md).
Encoding colours are the distinct colour and fill values a layer uses to
tell groups apart; a continuous colour or fill scale is a smooth ramp
rather than a set of codes, so it is excluded.

`greyscale_separability` is the smallest difference in CIE lightness
between those same colours, which is what survives printing in black and
white.

`text_size` is the smallest point size of any text the figure draws,
after scaling by `width_cm / render_width_cm`: a figure drawn seven
inches wide and printed in an 8.9 cm column has every point size halved.
Text drawn inside the panel, by a layer such as
[`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
or by an annotation, is deliberately left out. It sits on the marks
rather than on the background, so there is no one background to measure
its contrast against, and the two engines size a layer's text in
different units, which would leave the check disagreeing with its Python
twin on the same figure.

`text_contrast` and `geometry_contrast` are the smallest WCAG 2.x
contrast ratios of, respectively, any drawn text against the plot
background and any encoding colour against the panel background.

`redundant_encoding` counts how many of shape and line type also vary in
a layer whose colour varies. Zero means the distinction between groups
is carried by colour alone, which is the single most common way an
otherwise careful figure becomes unreadable.

## A limitation of the default palette

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

## References

Machado GM, Oliveira MM, Fernandes LAF (2009). “A physiologically-based
model for simulation of color vision deficiency.” *IEEE Transactions on
Visualization and Computer Graphics*, **15**(6), 1291–1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113) .

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

# A figure that clears every check: two well-separated colours, a redundant
# shape, and text left at the size it was drawn.
good <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
                               shape = treatment)) +
  geom_point() +
  scale_colour_manual(values = c("#005b96", "#d55e00")) +
  theme_depictr()
check_figure(good)
#>                        check measured threshold verdict
#> 1        colour_separability   111.87       5.0    pass
#> 2 colour_separability_protan    89.87       5.0    pass
#> 3 colour_separability_deutan   107.07       5.0    pass
#> 4 colour_separability_tritan    98.50       5.0    pass
#> 5     greyscale_separability    16.92       5.0    pass
#> 6                  text_size     8.80       6.0    pass
#> 7              text_contrast     8.45       4.5    pass
#> 8          geometry_contrast     3.87       3.0    pass
#> 9         redundant_encoding     1.00       1.0    pass
#>                                                              detail
#> 1           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 2           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 3           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 4           Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 5                Closest pair #005b96 and #d55e00 in CIE lightness.
#> 6 Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.
#> 7                          Lowest-contrast text #4d4d4d on #ffffff.
#> 8                        Lowest-contrast colour #d55e00 on #ffffff.
#> 9                                        Colour is joined by shape.

# The same figure destined for an 8.9 cm journal column, where the text is
# half the size it looks on screen.
check_figure(good, width_cm = 8.9)
#>                        check measured threshold verdict
#> 1        colour_separability   111.87       5.0    pass
#> 2 colour_separability_protan    89.87       5.0    pass
#> 3 colour_separability_deutan   107.07       5.0    pass
#> 4 colour_separability_tritan    98.50       5.0    pass
#> 5     greyscale_separability    16.92       5.0    pass
#> 6                  text_size     4.40       6.0    fail
#> 7              text_contrast     8.45       4.5    pass
#> 8          geometry_contrast     3.87       3.0    pass
#> 9         redundant_encoding     1.00       1.0    pass
#>                                                             detail
#> 1          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 2          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 3          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 4          Closest pair #005b96 and #d55e00 of 2 encoding colours.
#> 5               Closest pair #005b96 and #d55e00 in CIE lightness.
#> 6 Smallest text 8.80 pt, drawn at 17.78 cm and printed at 8.90 cm.
#> 7                         Lowest-contrast text #4d4d4d on #ffffff.
#> 8                       Lowest-contrast colour #d55e00 on #ffffff.
#> 9                                       Colour is joined by shape.
```
