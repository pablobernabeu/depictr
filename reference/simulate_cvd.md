# Simulate how colours appear under a colour-vision deficiency

Maps each colour to the colour a reader with a given form and severity
of colour-vision deficiency would perceive, using the
physiologically-based model of Machado, Oliveira and Fernandes (2009).
The transformation is defined on linear-light RGB, so a colour is
decoded from sRGB to linear RGB (the IEC 61966-2-1 transfer functions),
transformed, then re-encoded.

## Usage

``` r
simulate_cvd(colours, deficiency, severity = 1)
```

## Arguments

- colours:

  Character vector of colours, in any form
  [`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html)
  understands.

- deficiency:

  The deficiency to simulate: `"protan"` or `"deutan"` (the two
  red-green forms) or `"tritan"` (blue-yellow).

- severity:

  Severity in `[0, 1]`. Zero leaves the colours unchanged and one is the
  full deficiency. Intermediate values interpolate the transform towards
  the identity, an approximation to Machado et al.'s per-severity
  matrices.

## Value

A character vector of lower-case hex colours, the same length as
`colours`.

## Details

This is the simulator behind
[`palette_preview()`](https://pablobernabeu.github.io/depictr/reference/palette_preview.md)'s
`cvd` argument, behind
[`palette_safety()`](https://pablobernabeu.github.io/depictr/reference/palette_safety.md),
and behind the colour-separability rows of
[`check_figure()`](https://pablobernabeu.github.io/depictr/reference/check_figure.md).

## References

Machado GM, Oliveira MM, Fernandes LAF (2009). “A physiologically-based
model for simulation of color vision deficiency.” *IEEE Transactions on
Visualization and Computer Graphics*, **15**(6), 1291–1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113) .

## Examples

``` r
simulate_cvd(c("#005b96", "#e69f00"), "deutan")
#> [1] "#275295" "#cab411"

# Half severity moves the colours only part of the way.
simulate_cvd(c("#005b96", "#e69f00"), "deutan", severity = 0.5)
#> [1] "#1a5795" "#d8aa09"
```
