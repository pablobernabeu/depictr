# Plot a correlation matrix as a heatmap

Computes the pairwise correlations between the numeric columns of a data
frame and displays them as a colour-coded heatmap, optionally annotated
with the correlation values.

## Usage

``` r
correlation_heatmap(
  data,
  cols = NULL,
  method = "pearson",
  use = "pairwise.complete.obs",
  show_values = TRUE,
  digits = 2,
  palette = depictr_palette(5, "diverging")[c(1, 3, 5)],
  reorder = FALSE,
  title = NULL
)
```

## Arguments

- data:

  A data frame.

- cols:

  Optional character vector of columns to include. If `NULL`, all
  numeric columns are used.

- method:

  Correlation method: `"pearson"`, `"spearman"` or `"kendall"`.

- use:

  Missing-value handling passed to
  [`stats::cor()`](https://rdrr.io/r/stats/cor.html).

- show_values:

  Whether to annotate each cell with its correlation.

- digits:

  Number of decimal places for the annotations.

- palette:

  Length-3 vector of colours for the lowest, mid (zero) and highest
  correlations. Defaults to the endpoints and midpoint of the
  colourblind-aware
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md)
  diverging ramp (negative correlations red, zero neutral, positive
  correlations brand blue).

- reorder:

  Whether to reorder the variables by hierarchical clustering of the
  correlation matrix (using \\1 - r\\ as the distance), so that blocks
  of mutually correlated variables sit together and structure is easier
  to see. Defaults to `FALSE` (the order of `cols`). Skipped with a
  message if any correlation is undefined (`NA`).

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Columns with (near-)zero variance cannot be correlated and are dropped
automatically with an informative message, so the raw
`"the standard deviation is zero"` warning from
[`stats::cor()`](https://rdrr.io/r/stats/cor.html) is not surfaced. If,
after dropping them, any cells still come out `NA` (e.g. two variables
that never co-occur under `"pairwise.complete.obs"`), those cells are
rendered in grey and labelled `n/a` rather than left blank.

## Examples

``` r
correlation_heatmap(wellbeing_survey)

correlation_heatmap(crop_yield, method = "spearman", show_values = FALSE)

# Cluster correlated variables together:
correlation_heatmap(wellbeing_survey, reorder = TRUE)
```
