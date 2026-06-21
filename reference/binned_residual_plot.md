# Binned-residual plot for a generalised linear model

For a fitted `glm` (especially binary or count models), a plot of raw
residuals against fitted values is hard to read because the residuals
take only a few values. Following Gelman and Hill (2007), this plot
instead splits the data into equal-count bins of fitted values and
plots, for each bin, the mean residual against the mean fitted value.
Under a well-specified model the binned residuals scatter around zero,
and about 95% of them should fall within the grey \\\pm 2\\
standard-error band, computed per bin as
\\2\\\hat{\sigma}\_{\text{bin}}/\sqrt{n\_{\text{bin}}}\\ from the
residuals in that bin. Systematic departures (a trend, or many points
outside the band) indicate a misspecified mean structure.

## Usage

``` r
binned_residual_plot(
  model,
  bins = NULL,
  type = c("response", "pearson"),
  point_colour = depictr_brand(),
  band_colour = depictr_accent(),
  title = NULL
)
```

## Arguments

- model:

  A fitted `glm` object (an `lm` is also accepted and treated as a
  Gaussian GLM).

- bins:

  Number of bins. The default follows Gelman and Hill's rule of thumb of
  roughly \\\sqrt{n}\\ bins (bounded to a sensible range).

- type:

  Residual type used for the bin means: `"response"` (observed minus
  fitted on the response scale, the Gelman-Hill default) or `"pearson"`.

- point_colour, band_colour:

  Colours for the bin points and the \\\pm 2\\ SE band. Default to the
  depictr brand and accent colours.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. The per-bin summary (mean fitted, mean residual, SE bound and an
`outside` flag) is attached as `attr(plot, "bins")`.

## References

Gelman A, Hill J (2007). *Data Analysis Using Regression and
Multilevel/Hierarchical Models*. Cambridge University Press, Cambridge,
UK. ISBN 978-0-521-68689-1.
[doi:10.1017/CBO9780511790942](https://doi.org/10.1017/CBO9780511790942)
.

## Examples

``` r
gfit <- glm(adverse_event ~ biomarker + age + arm,
            data = clinical_trial, family = binomial)
binned_residual_plot(gfit)
```
