# Caterpillar plot of random effects

Displays the conditional modes ("BLUPs") of a mixed model's random
effects as a sorted point-and-interval ("caterpillar") plot. It is the
usual way to inspect by-group departures from the average, and to
identify unusual groups.

## Usage

``` r
random_effects_plot(
  x,
  conf_level = 0.95,
  sort = TRUE,
  point_colour = "#005b96",
  title = NULL,
  x_lab = "Random effect"
)
```

## Arguments

- x:

  Either a mixed model fitted with 'lme4' (`merMod`), or a data frame
  with one row per group level and columns such as `level`/`group`,
  `estimate`, and either `conf.low`/`conf.high` or `std.error`. An
  optional `term` column facets the plot.

- conf_level:

  Confidence level when intervals are derived from standard errors.

- sort:

  Whether to order the levels by their estimate.

- point_colour:

  Colour for the points and intervals.

- title, x_lab:

  Plot title and value-axis label.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# From a data frame of by-group estimates:
re <- data.frame(
  level = paste0("G", 1:10),
  estimate = sort(rnorm(10)),
  std.error = runif(10, 0.2, 0.5)
)
random_effects_plot(re)
#> `height` was translated to `width`.


# \donttest{
if (requireNamespace("lme4", quietly = TRUE)) {
  m <- lme4::lmer(RT ~ condition + (1 | participant), data = lexical_decision)
  random_effects_plot(m)
}
#> `height` was translated to `width`.

# }
```
