# Compose several plots into one figure

A wrapper around
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
that adds the usual finishing touches: duplicate legends collected into
one, automatic panel tags (A, B, C and so on) and an overall title and
subtitle.

## Usage

``` r
arrange_plots(
  ...,
  ncol = NULL,
  nrow = NULL,
  guides = c("collect", "keep"),
  title = NULL,
  subtitle = NULL,
  tag_levels = "A"
)
```

## Arguments

- ...:

  Plots to combine, or a single list of plots.

- ncol, nrow:

  Layout dimensions, passed to patchwork.

- guides:

  How to treat legends: `"collect"` (merge duplicates) or `"keep"`.

- title, subtitle:

  Overall title and subtitle.

- tag_levels:

  Panel tag style, such as `"A"`, `"1"` or `"i"`, or `NULL` for no tags.

## Value

A 'patchwork' object.

## Examples

``` r
p1 <- explore_distribution(crop_yield, yield)
p2 <- scatter_trend(crop_yield, fertiliser, yield)
arrange_plots(p1, p2, ncol = 2, title = "Crop yield", tag_levels = "A")
```
