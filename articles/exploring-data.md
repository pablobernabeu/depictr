# Exploring data

depictr provides a coherent set of exploratory plots and a descriptive
table, all sharing the package theme and palette. Column names can be
given quoted or unquoted.

## One variable

[`explore_distribution()`](https://pablobernabeu.github.io/depictr/reference/explore_distribution.md)
for a numeric variable,
[`explore_categorical()`](https://pablobernabeu.github.io/depictr/reference/explore_categorical.md)
for a categorical one.

``` r

explore_distribution(lexical_decision, RT, group = condition, type = "density")
```

![](exploring-data_files/figure-html/unnamed-chunk-1-1.png)

``` r

explore_categorical(wellbeing_survey, education, group = region,
                    proportion = TRUE, position = "dodge")
```

![](exploring-data_files/figure-html/unnamed-chunk-2-1.png)

## Two variables, any types

[`explore_bivariate()`](https://pablobernabeu.github.io/depictr/reference/explore_bivariate.md)
selects the appropriate plot automatically: a scatter plot for two
numeric variables, box plots for a numeric variable against a
categorical one, and a filled bar chart for two categorical variables.

``` r

explore_bivariate(lexical_decision, condition, RT)
```

![](exploring-data_files/figure-html/unnamed-chunk-3-1.png)

For a focused scatter with a fitted trend, use
[`scatter_trend()`](https://pablobernabeu.github.io/depictr/reference/scatter_trend.md):

``` r

scatter_trend(crop_yield, fertilizer, yield, group = treatment)
```

![](exploring-data_files/figure-html/unnamed-chunk-4-1.png)

## Many variables at once

[`explore_pairs()`](https://pablobernabeu.github.io/depictr/reference/explore_pairs.md)
is a scatter-plot matrix;
[`correlation_heatmap()`](https://pablobernabeu.github.io/depictr/reference/correlation_heatmap.md)
condenses the same information into a single coloured grid.

``` r

explore_pairs(crop_yield, cols = c("rainfall", "fertilizer", "soil_ph", "yield"))
```

![](exploring-data_files/figure-html/unnamed-chunk-5-1.png)

``` r

correlation_heatmap(wellbeing_survey)
```

![](exploring-data_files/figure-html/unnamed-chunk-6-1.png)

## Distributions across groups

[`raincloud_plot()`](https://pablobernabeu.github.io/depictr/reference/raincloud_plot.md)
shows the density, the box summary and the raw points together, and
[`group_comparison_plot()`](https://pablobernabeu.github.io/depictr/reference/group_comparison_plot.md)
adds the group means with confidence intervals over the raw data. By
showing the estimate alongside its uncertainty, the latter conveys
whether the groups differ more faithfully than a bar chart.

``` r

raincloud_plot(lexical_decision, RT, group = condition)
```

![](exploring-data_files/figure-html/unnamed-chunk-7-1.png)

``` r

group_comparison_plot(lexical_decision, RT, condition)
```

![](exploring-data_files/figure-html/unnamed-chunk-8-1.png)

## Data quality: outliers and missingness

``` r

outlier_plot(crop_yield, yield)
```

![](exploring-data_files/figure-html/unnamed-chunk-9-1.png)

``` r

missingness_map(wellbeing_survey)
```

![](exploring-data_files/figure-html/unnamed-chunk-10-1.png)

## A descriptive summary table

[`summary_table()`](https://pablobernabeu.github.io/depictr/reference/summary_table.md)
builds a “Table 1”: mean (SD) for numeric variables, counts and
percentages for categorical ones, optionally by group. It returns a
plain data frame, ready for
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html).

``` r

tab <- summary_table(wellbeing_survey,
                     vars = c("life_satisfaction", "stress", "education"),
                     group = "region")
knitr::kable(tab)
```

| variable | statistic | Overall | East | North | South | West |
|:---|:---|:---|:---|:---|:---|:---|
| life_satisfaction | Mean (SD) | 5.0 (1.1) | 5.2 (1.0) | 5.1 (1.1) | 4.6 (1.0) | 4.9 (1.1) |
| stress | Mean (SD) | 4.0 (1.3) | 3.9 (1.2) | 3.8 (1.5) | 4.3 (1.2) | 3.9 (1.3) |
| education | secondary | 140 (47%) | 31 (45%) | 37 (45%) | 33 (49%) | 39 (48%) |
|  | undergraduate | 113 (38%) | 28 (41%) | 29 (35%) | 22 (33%) | 34 (41%) |
|  | postgraduate | 47 (16%) | 10 (14%) | 16 (20%) | 12 (18%) | 9 (11%) |
