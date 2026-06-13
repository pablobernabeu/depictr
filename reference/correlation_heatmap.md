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
  palette = c("#b2182b", "white", "#005b96"),
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
  correlations.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
correlation_heatmap(wellbeing_survey)

correlation_heatmap(crop_yield, method = "spearman", show_values = FALSE)
```
