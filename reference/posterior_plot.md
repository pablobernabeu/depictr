# Plot posterior distributions and intervals

Summarises posterior (or, more generally, bootstrap or simulation) draws
as a point with two nested credible intervals, in the classic "half-eye"
style of uncertainty display. Draws may be supplied in long form (a
parameter column and a value column) or wide form (one column of draws
per parameter), so the function works with the output of any sampler and
depends on no particular modelling package.

## Usage

``` r
posterior_plot(
  draws,
  point = c("median", "mean"),
  widths = c(0.66, 0.95),
  interaction = c("times", "asterisk", "colon", "space"),
  reference_line = 0,
  colour = "#005b96",
  title = NULL,
  x_lab = "Value"
)
```

## Arguments

- draws:

  A data frame of draws: either long (parameter + value columns) or wide
  (one numeric column per parameter).

- point:

  Central summary: `"median"` or `"mean"`.

- widths:

  Two interval widths (inner and outer), as probabilities.

- interaction:

  Passed to
  [`format_terms()`](https://pablobernabeu.github.io/depictr/reference/format_terms.md)
  for the parameter labels.

- reference_line:

  Position of a vertical reference line (`NA` to omit).

- colour:

  Colour for the points and intervals.

- title, x_lab:

  Plot title and value-axis label.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# Wide draws: one column per parameter
set.seed(1)
draws <- data.frame(
  intercept = rnorm(2000, 5, 0.3),
  slope = rnorm(2000, 0.8, 0.15),
  `slope:group` = rnorm(2000, -0.2, 0.2),
  check.names = FALSE
)
posterior_plot(draws)
```
