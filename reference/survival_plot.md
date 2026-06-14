# Kaplan-Meier survival plot

Draws Kaplan-Meier survival curves, optionally by group, with stepwise
confidence limits and censoring marks. The Kaplan-Meier estimate and its
Greenwood standard error are computed with base R, so no modelling
package is required; a `survfit` object from the 'survival' package is
also accepted.

## Usage

``` r
survival_plot(
  time,
  status = NULL,
  group = NULL,
  conf_level = 0.95,
  censor_marks = TRUE,
  palette = NULL,
  title = NULL,
  x_lab = "Time",
  y_lab = "Survival probability"
)
```

## Arguments

- time:

  A numeric vector of follow-up times, a data frame with `time`,
  `status` and optional `group` columns, or a `survfit` object.

- status:

  Event indicator (1 = event, 0 = censored) when `time` is a vector.

- group:

  Optional grouping variable (a vector, or a column name when `time` is
  a data frame).

- conf_level:

  Confidence level for the limits (`NA` to omit them).

- censor_marks:

  Whether to mark censoring times with a `+`.

- palette:

  Colours for the groups; defaults to
  [`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md).

- title, x_lab, y_lab:

  Title and axis labels.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## References

Kaplan EL, Meier P (1958). “Nonparametric Estimation from Incomplete
Observations.” *Journal of the American Statistical Association*,
**53**(282), 457–481.
[doi:10.1080/01621459.1958.10501452](https://doi.org/10.1080/01621459.1958.10501452)
.

Greenwood M (1926). *The Natural Duration of Cancer*, volume 33 of
*Reports on Public Health and Medical Subjects*. His Majesty's
Stationery Office, London.

## Examples

``` r
set.seed(1)
n <- 200
grp <- sample(c("control", "treated"), n, replace = TRUE)
time <- rexp(n, rate = ifelse(grp == "treated", 0.05, 0.1))
cens <- runif(n, 0, 30)
obs  <- pmin(time, cens)
event <- as.integer(time <= cens)
survival_plot(obs, event, group = grp, title = "Survival by treatment")
```
