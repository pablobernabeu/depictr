# A "Table 1" style descriptive summary

Builds the kind of descriptive table that opens many empirical papers:
numeric variables are summarised as mean (SD), categorical variables as
counts and percentages, optionally split into one column per level of a
grouping variable. The result is a plain data frame, ready to pass to
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) or a table
package.

## Usage

``` r
summary_table(data, vars = NULL, group = NULL, digits = 1)
```

## Arguments

- data:

  A data frame.

- vars:

  Columns to summarise. If `NULL`, all columns except `group` are used.

- group:

  Optional grouping variable; one summary column is produced per level,
  alongside an overall column.

- digits:

  Number of decimal places for numeric summaries.

## Value

A data frame with columns `variable`, `statistic`, `Overall` and one
column per group level.

## Examples

``` r
summary_table(crop_yield, vars = c("yield", "rainfall", "treatment"))
#>    variable statistic      Overall
#> 1     yield Mean (SD)    3.1 (1.1)
#> 2  rainfall Mean (SD) 517.1 (80.9)
#> 3 treatment  standard    107 (54%)
#> 4            enhanced     93 (46%)
summary_table(wellbeing_survey,
              vars = c("life_satisfaction", "education"),
              group = "region")
#>            variable     statistic   Overall      East     North     South
#> 1 life_satisfaction     Mean (SD) 5.0 (1.1) 5.2 (1.0) 5.1 (1.1) 4.6 (1.0)
#> 2         education     secondary 140 (47%)  31 (45%)  37 (45%)  33 (49%)
#> 3                   undergraduate 113 (38%)  28 (41%)  29 (35%)  22 (33%)
#> 4                    postgraduate  47 (16%)  10 (14%)  16 (20%)  12 (18%)
#>        West
#> 1 4.9 (1.1)
#> 2  39 (48%)
#> 3  34 (41%)
#> 4   9 (11%)
```
