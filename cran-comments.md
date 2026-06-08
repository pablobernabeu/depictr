## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Ubuntu 24.04, R 4.3.3
* GitHub Actions: ubuntu-latest (release, devel, oldrel-1),
  windows-latest (release), macOS-latest (release)

## Notes

* The heavier modelling packages that some functions can consume
  (lme4, broom, broom.mixed, brms, simr) are in Suggests and used
  conditionally, so the package installs and checks without them. Examples
  and the test suite rely only on base models (`lm`, `glm`) and the bundled
  simulated datasets, so they run everywhere.

## Downstream dependencies

There are currently no downstream dependencies.
