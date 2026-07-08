# Contributing to depictr

Thank you for considering a contribution. Issues and pull requests are both
welcome, whether they fix a bug, improve the documentation or add a plot.

## Reporting a problem or suggesting a feature

Please open an issue at <https://github.com/pablobernabeu/depictr/issues>. A small
reproducible example ([reprex](https://reprex.tidyverse.org)) helps a great deal,
and for a plotting bug a screenshot of the result is useful too.

## Setting up for development

```r
# install.packages("pak")
pak::pak("pablobernabeu/depictr")
pak::pak(c("devtools", "roxygen2", "testthat", "spelling"))
```

```r
devtools::document()   # regenerate man/ and NAMESPACE after editing roxygen
devtools::test()       # run the test suite
devtools::check()      # a full R CMD check
```

## Conventions

Every plotting function returns a ggplot2 object (or a patchwork for composite
panels), so a plot can be extended with the usual `+` syntax. New or changed
plots should keep the shared theme (`theme_depictr`) and the colourblind-safe
palette, and where a specialist package computes a quantity well, depictr
delegates to it and redraws the result rather than re-implementing it. The prose
follows British spelling; `spelling::spell_check_package()` keeps the word list
tidy.

## Automated maintenance

Scheduled workflows watch for breakage from upstream: a dependency canary rebuilds
the package against current and development dependency versions, and a link check
verifies the URLs in the sources. Both file a single issue on failure, using the
templates in `.github/issue-templates/`, and close it again once the check passes.

## Submitting a pull request

Base your work on `main`, keep the change focused, and add or update tests and
documentation alongside the code. Running `devtools::document()`,
`devtools::test()` and `devtools::check()` before opening the pull request saves a
round trip.

By contributing you agree that your contribution is licensed under the same MIT
licence as the package, and that you will follow the
[Code of Conduct](CODE_OF_CONDUCT.md).
