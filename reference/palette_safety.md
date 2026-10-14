# Check that a palette stays distinguishable under each deficiency

For normal vision and each deficiency at full severity, the palette's
colours are converted to CIELAB and the smallest colour difference
between any two of them is found. The difference is CIEDE2000 (Sharma,
Wu & Dalal, 2005) unless `metric` asks for the older measure. The lower
this minimum, the more likely two categories are to be confused. A
palette counts as safe when the minimum across all four conditions is at
least `threshold`.

## Usage

``` r
palette_safety(colours = NULL, threshold = 5, metric = c("ciede2000", "cie76"))
```

## Arguments

- colours:

  The palette to test. Defaults to the depictr qualitative palette.
  Needs at least two colours: a pairwise distance over fewer than two
  has no value, rather than an infinitely safe one.

- threshold:

  The smallest acceptable colour difference, on the scale of `metric`.

- metric:

  The colour difference to measure: `"ciede2000"`, the default, or
  `"cie76"`, the Euclidean distance in CIELAB that earlier versions
  measured. `"cie76"` is kept so that earlier results can be reproduced,
  and a later release will remove it.

## Value

A list with `min_delta_e` (the worst case across conditions),
`by_condition` (a named numeric vector, one minimum colour difference
for normal vision and for each deficiency), `worst_condition` and
`worst_pair` (the closest colours and where they were closest), `safe`
and `threshold`.

## Details

Earlier versions measured the Euclidean distance in CIELAB, known as
CIE76, which overstates the difference between saturated colours: the
blues `#005b96` and `#0060a8` are 8.20 apart by CIE76 and 2.69 by
CIEDE2000. ggplot2's default palette of five colours passed the check
under CIE76, although under deuteranopia its sky blue and its pink come
within 2.74 of each other in CIEDE2000.

The default `threshold` of 5 is calibrated against the reference
colourblind-safe palette: the Okabe-Ito set's tightest pair (reddish
purple against grey) sits at 6.43 under full deuteranopia, so the cut
must lie below that to pass the recommended palette, while still
flagging colours that become near-identical under a deficiency. The
difference includes lightness, which survives colour-vision deficiency,
so two colours that share a hue but differ in lightness are correctly
treated as distinguishable. Full severity is the worst case; most
colour-vision deficiency is milder.

This looks at a palette in the abstract. To audit a finished figure,
which uses only as many colours as it has groups and has text and a
background besides, see
[`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md).

## References

Okabe M, Ito K (2008). “Color Universal Design (CUD): How to make
figures and presentations that are friendly to colorblind people.”
<https://jfly.uni-koeln.de/color/>. Accessed 2026-06-14.

Machado GM, Oliveira MM, Fernandes LAF (2009). “A physiologically-based
model for simulation of color vision deficiency.” *IEEE Transactions on
Visualization and Computer Graphics*, **15**(6), 1291–1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113) .

Sharma G, Wu W, Dalal EN (2005). “The CIEDE2000 color-difference
formula: Implementation notes, supplementary test data, and mathematical
observations.” *Color Research & Application*, **30**(1), 21–30.
[doi:10.1002/col.20070](https://doi.org/10.1002/col.20070) .

## Examples

``` r
palette_safety()
#> $min_delta_e
#> [1] 6.43
#> 
#> $by_condition
#> normal protan deutan tritan 
#>  21.25  13.44   6.43  11.13 
#> 
#> $worst_condition
#> [1] "deutan"
#> 
#> $worst_pair
#> [1] "#cc79a7" "#999999"
#> 
#> $safe
#> [1] TRUE
#> 
#> $threshold
#> [1] 5
#> 

# Two colours a hair apart are flagged.
palette_safety(c("#005b96", "#015c97"))
#> $min_delta_e
#> [1] 0.34
#> 
#> $by_condition
#> normal protan deutan tritan 
#>   0.35   0.36   0.34   0.34 
#> 
#> $worst_condition
#> [1] "deutan"
#> 
#> $worst_pair
#> [1] "#005b96" "#015c97"
#> 
#> $safe
#> [1] FALSE
#> 
#> $threshold
#> [1] 5
#> 

# ggplot2's default palette of five colours, which passed under CIE76.
hue5 <- c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3")
palette_safety(hue5)$safe
#> [1] FALSE
palette_safety(hue5, metric = "cie76")$safe
#> [1] TRUE
```
