# A "Table 1" style descriptive summary

Builds the kind of descriptive table that opens many empirical papers:
numeric variables are summarised as mean (SD), categorical variables as
counts and percentages, optionally split into one column per level of a
grouping variable. The result is a plain data frame, ready to pass to
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) or a table
package.

## Usage

``` r
summary_table(
  data,
  vars = NULL,
  group = NULL,
  digits = 1,
  missing = TRUE,
  max_levels = 20
)
```

## Arguments

- data:

  A data frame.

- vars:

  Columns to summarise. If `NULL`, all columns except `group` are used,
  with high-cardinality identifier-like columns skipped (see Details).

- group:

  Optional grouping variable; one summary column is produced per level,
  alongside an overall column.

- digits:

  Number of decimal places for numeric summaries.

- missing:

  Whether to add a `Missing, n (%)` row for variables that contain
  missing values. Defaults to `TRUE`.

- max_levels:

  When `vars` is `NULL`, character/factor columns whose distinct-level
  count is at least `max_levels` *and* exceeds half the number of rows
  are treated as identifiers and skipped. Defaults to `20`.

## Value

A data frame with columns `variable`, `statistic`, `Overall` and one
column per group level. The first row reports `N`.

## Details

The first row of the table always reports the sample size (`N`) overall
and per group. By default each variable is also followed by a
`Missing, n (%)` row whenever it contains missing values; set
`missing = FALSE` to suppress these.

When `vars` is `NULL`, high-cardinality character/factor columns (those
whose number of distinct levels approaches the number of rows, e.g.
identifier columns) are skipped automatically, with a message, rather
than being expanded into hundreds of one-per-row entries. Pass such a
column explicitly via `vars` to override this.

## Examples

``` r
summary_table(crop_yield, vars = c("yield", "rainfall", "treatment"))
#>    variable statistic      Overall
#> 1         N                    200
#> 2     yield Mean (SD)    3.0 (1.2)
#> 3  rainfall Mean (SD) 517.1 (80.9)
#> 4 treatment  standard    107 (54%)
#> 5            enhanced     93 (46%)
summary_table(wellbeing_survey,
              vars = c("life_satisfaction", "education"),
              group = "region")
#>            variable      statistic   Overall      East     North     South
#> 1                 N                      300        69        82        67
#> 2 life_satisfaction      Mean (SD) 4.3 (1.1) 4.7 (0.9) 4.8 (1.0) 3.6 (1.0)
#> 3                   Missing, n (%)    7 (2%)    1 (1%)    3 (4%)    1 (1%)
#> 4         education      secondary 140 (47%)  31 (45%)  37 (45%)  33 (49%)
#> 5                    undergraduate 113 (38%)  28 (41%)  29 (35%)  22 (33%)
#> 6                     postgraduate  47 (16%)  10 (14%)  16 (20%)  12 (18%)
#>        West
#> 1        82
#> 2 4.1 (1.0)
#> 3    2 (2%)
#> 4  39 (48%)
#> 5  34 (41%)
#> 6   9 (11%)
```
