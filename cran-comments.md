## Submission

This is a new submission of statviz, a unified toolkit of publication-ready
plots that span the analysis workflow (exploratory data analysis, model
estimates, predictions, diagnostics, classification, multivariate and survival
methods, time series, uncertainty and reporting).

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Ubuntu 24.04, R 4.3.3
* GitHub Actions: ubuntu-latest (release, devel, oldrel-1),
  windows-latest (release), macOS-latest (release)

## Notes on dependencies

* The heavier modelling back-ends that some functions can consume
  (lme4, broom, simr) are in Suggests and used conditionally, so the package
  installs and checks without them. Every example, test and vignette runs on
  base models (`lm`, `glm`), base R datasets (`AirPassengers`) and the bundled
  simulated datasets, so the full check passes without any optional package.

## Reproducibility

* The three bundled datasets are simulated (no personal or proprietary data)
  and are regenerated reproducibly by `data-raw/generate_datasets.R`.

## Downstream dependencies

There are currently no downstream dependencies.
