# Suggest a number of clusters

Computes a cluster-quality diagnostic across a range of `k` and draws
the diagnostic curve, with the suggested `k` highlighted. Three criteria
are available: the average silhouette width (maximised), the total
within-cluster sum of squares "elbow" (the point of maximum curvature),
and the gap statistic (the smallest `k` whose gap is within one standard
error of the next, using the Tibshirani et al. heuristic).

## Usage

``` r
k_diagnostic(
  data,
  k_range = 2:8,
  method = c("silhouette", "wss", "gap"),
  cols = NULL,
  scale = TRUE,
  nstart = 10,
  B = 50,
  title = NULL
)
```

## Arguments

- data:

  A data frame or numeric matrix.

- k_range:

  Integer vector of candidate cluster counts to evaluate.

- method:

  Diagnostic: `"silhouette"`, `"wss"` (within sum of squares elbow) or
  `"gap"`.

- cols:

  When `data` is a data frame, the numeric columns to use.

- scale:

  Whether to scale variables to unit variance first.

- nstart:

  Number of random starts for
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html).

- B:

  Number of reference bootstrap samples for the gap statistic.

- title:

  Plot title.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object showing the diagnostic value against `k`, with the suggested `k`
marked and named in the subtitle. The underlying computation is attached
as attributes: `attr(p, "k_table")` (a data frame with one row per `k`),
`attr(p, "suggested")` (the chosen `k`) and `attr(p, "method")`.

## References

Rousseeuw, P. J. (1987). Silhouettes: A graphical aid to the
interpretation and validation of cluster analysis. *Journal of
Computational and Applied Mathematics*, 20, 53-65.
[doi:10.1016/0377-0427(87)90125-7](https://doi.org/10.1016/0377-0427%2887%2990125-7)

Tibshirani, R., Walther, G., & Hastie, T. (2001). Estimating the number
of clusters in a data set via the gap statistic. *Journal of the Royal
Statistical Society: Series B*, 63(2), 411-423.
[doi:10.1111/1467-9868.00293](https://doi.org/10.1111/1467-9868.00293)

## Examples

``` r
p <- k_diagnostic(crop_yield, k_range = 2:6,
                  cols = c("rainfall", "fertiliser", "soil_ph", "yield"))
attr(p, "suggested")
#> [1] 2
```
