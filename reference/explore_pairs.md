# Scatter-plot matrix

A matrix of pairwise plots for a set of numeric variables: scatter plots
below the diagonal, densities on the diagonal and correlation
coefficients above the diagonal. Optionally colour everything by a
grouping variable. Built with 'patchwork', so it shares the package
theme and palette.

## Usage

``` r
explore_pairs(
  data,
  cols = NULL,
  group = NULL,
  max_cols = 8,
  point_alpha = 0.5,
  palette = NULL,
  title = NULL
)
```

## Arguments

- data:

  A data frame.

- cols:

  Numeric columns to include. If `NULL`, all numeric columns are used
  (up to `max_cols`).

- group:

  Optional grouping variable mapped to colour.

- max_cols:

  Safety cap on the number of variables (a k-by-k matrix grows quickly).

- point_alpha:

  Point transparency in the scatter panels.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title:

  Overall title for the matrix.

## Value

A 'patchwork' object (printable like a
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)).

## Examples

``` r
explore_pairs(crop_yield, cols = c("rainfall", "fertilizer", "yield"))

# \donttest{
explore_pairs(crop_yield, cols = c("rainfall", "fertilizer", "yield"),
              group = treatment)

# }
```
