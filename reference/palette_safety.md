# Check that a palette stays distinguishable under each deficiency

For normal vision and each deficiency at full severity, the palette's
colours are converted to CIE L*a*b\* and the smallest pairwise colour
difference (CIE76 Delta-E) is found. The lower this minimum, the more
likely two categories are to be confused. A palette counts as safe when
the minimum across all four conditions is at least `threshold`.

## Usage

``` r
palette_safety(colours = NULL, threshold = 5)
```

## Arguments

- colours:

  The palette to test. Defaults to the depictr qualitative palette.
  Needs at least two colours: a pairwise distance over fewer than two
  has no value, rather than an infinitely safe one.

- threshold:

  The smallest acceptable Delta-E.

## Value

A list with `min_delta_e` (the worst case across conditions),
`by_condition` (a named numeric vector, one minimum Delta-E for normal
vision and for each deficiency), `worst_condition` and `worst_pair` (the
closest colours and where they were closest), `safe` and `threshold`.

## Details

The default `threshold` of 5 is calibrated against the reference
colourblind-safe palette: the Okabe-Ito set's tightest pair (reddish
purple against grey) sits at Delta-E 7.4 under full deuteranopia, so the
cut must lie below that to pass the recommended palette, while still
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

## Examples

``` r
palette_safety()
#> $min_delta_e
#> [1] 7.4
#> 
#> $by_condition
#> normal protan deutan tritan 
#>  33.43  18.15   7.40  16.18 
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
#> [1] 0.41
#> 
#> $by_condition
#> normal protan deutan tritan 
#>   0.42   0.41   0.42   0.41 
#> 
#> $worst_condition
#> [1] "protan"
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
```
