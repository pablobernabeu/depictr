# Compare estimates from several models or sources

Overlays the estimates from two or more models (or tidy estimate tables)
on a single forest plot, with one colour per source. This is the general
engine behind
[`frequentist_bayesian_plot()`](https://pablobernabeu.github.io/depictr/reference/frequentist_bayesian_plot.md)
(frequentist vs. Bayesian) and is also handy for comparing nested
models, several optimisers, or estimates before and after a
transformation.

## Usage

``` r
compare_models(
  ...,
  names = NULL,
  conf_level = 0.95,
  intercept = FALSE,
  order = c("none", "ascending", "descending"),
  labels = NULL,
  interaction = c("times", "asterisk", "colon", "space"),
  dodge_width = 0.6,
  reference_line = 0,
  palette = NULL,
  point_size = 2.2,
  line_size = 0.7,
  legend_title = "Source",
  legend_ncol = 1,
  title = NULL,
  subtitle = NULL,
  x_lab = "Estimate"
)
```

## Arguments

- ...:

  Two or more fitted models and/or tidy data frames of estimates. Name
  the arguments to label the sources (e.g.
  `compare_models(Frequentist = m1, Bayesian = m2)`).

- names:

  Optional character vector of source labels, overriding the names of
  `...`.

- conf_level:

  Confidence/credible level for models.

- intercept:

  Keep the intercept term? Defaults to `FALSE`.

- order:

  Order terms by their average estimate across sources: `"none"`,
  `"ascending"` or `"descending"`.

- labels:

  Optional display labels (see
  [`coefficient_plot()`](https://pablobernabeu.github.io/depictr/reference/coefficient_plot.md)).

- interaction:

  Passed to
  [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md).

- dodge_width:

  Vertical spacing between sources sharing a term.

- reference_line:

  Position of a vertical reference line (`NA` to omit).

- palette:

  Colours for the sources; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- point_size, line_size:

  Point and interval-line sizes.

- legend_title, legend_ncol:

  Legend title and number of columns.

- title, subtitle, x_lab:

  Title, subtitle and x-axis label.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
m1 <- lm(yield ~ rainfall + fertilizer + soil_ph, data = crop_yield)
m2 <- lm(yield ~ rainfall + fertilizer + soil_ph,
         data = crop_yield[crop_yield$treatment == "standard", ])
compare_models(`All fields` = m1, `Standard only` = m2,
                       title = "Estimates by subset")
#> `height` was translated to `width`.
```
