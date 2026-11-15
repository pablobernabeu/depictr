## Submission

This is an update from depictr 0.3.0, which CRAN published on 2026-09-01, to
0.4.0.

0.4.0 changes results and interfaces. Some functions return different values
for the same input (the confidence intervals of a 'glm' with an estimated
dispersion, standardised coefficients, fit statistics, variance inflation
factors and binned-residual bands among them), some arguments must now be
passed by name and some input that 0.3.0 accepted is refused. The package also
requires ggplot2 3.5.2 or later, where it required 3.5.0. NEWS.md lists each of
these changes under 'Upgrading from the previous release (0.3.0)', in three
parts: 'Changed results', 'Changed interface' and 'Changed output'.

## R CMD check results

0 errors | 0 warnings | 0 notes

With CRAN's incoming checks turned on, the check can give one NOTE:
https://otexts.com/fpp3/, the online edition of a textbook that two help pages
and a vignette cite, sometimes answers with status 202 'Accepted'.
urlchecker::url_check() finds the URL correct.

## Test environments

GitHub Actions, run 43735418221 on 2026-11-15, started by pull request #26 at
commit 2b2c2f3 on the release branch. The package sources of this submission
are those of that commit. Because a pull request started the run, each job
checked out GitHub's merge of that commit into main (36f731e), which differs
from 2b2c2f3 only in one workflow file under .github, a directory that
.Rbuildignore keeps out of the tarball. Each leg built the tarball with
`--compact-vignettes=gs+qpdf` and ran `R CMD check --as-cran --no-manual` on
it, without the CRAN incoming checks, which r-lib/actions turns off. Each leg
ended with 'Status: OK':

* ubuntu-latest (Ubuntu 26.04.1 LTS), R 4.6.2
* ubuntu-latest (Ubuntu 26.04.1 LTS), R-devel (2026-11-14 r90890)
* ubuntu-latest (Ubuntu 26.04.1 LTS), R 4.5.3
* windows-latest (x86_64-w64-mingw32), R 4.6.2
* windows-latest (x86_64-w64-mingw32), R-devel (2026-11-14 r90890 ucrt)
* macos-latest (macOS Tahoe 26.7.2, aarch64-apple-darwin23), R 4.6.2

The test suite passed in every leg, with no failures or warnings. Four tests
skip everywhere because they read repository files that R CMD check cannot
reach: CITATION.cff in two of them and the R sources in the other two. Five
more skip on macOS, where the cairo device cannot be loaded.

Two more jobs of the same run installed the declared minimum versions of the
imported ggplot2 (3.5.2) and patchwork (1.3.0, and in the second job the newest
patchwork) on R 4.3.3 (oldrel-3) under ubuntu-latest. In both, the test suite
passed and every example ran without a warning.

Three more checks of the same run, all on Ubuntu 26.04.1 LTS, had no failure:

* R CMD check with `_R_CHECK_DEPENDS_ONLY_=true` on R 4.6.2, so that the
  examples and tests saw only the packages in Depends and Imports, ended with
  'Status: OK'. The tests that need a suggested package skipped.
* The test suite ran on R 4.1.3, the floor in DESCRIPTION, with the packages
  in Depends and Imports, testthat and the recommended packages that come with
  R installed, among them survival, cluster, MASS and boot from Suggests. The
  tests that need another suggested package skipped.
* On the R-devel leg, the test suite ran again in a Latin-9 locale
  (en_US.iso885915) with NOT_CRAN unset, as on CRAN's
  r-devel-linux-x86_64-debian-clang flavour.

## Notes

* The modelling back-ends that some functions can take (lme4, lmerTest, broom,
  simr, survival, ggdist, posterior and cluster) are in Suggests and used
  conditionally, so the package installs and checks without them.
* ragg is in Suggests for save_plot(). When ragg is installed, ggsave() writes
  a TIFF with it, and otherwise with grDevices::tiff().
* MASS, boot, callr, colorspace and spelling are used by the tests only, and
  each test that needs one of them skips when it is absent. MASS supplies the
  negative binomial fits that some tests check. boot is the reference against
  which the package's bootstrap intervals are compared. colorspace is an
  independent implementation of the Machado colour-vision transforms, against
  which the package's own transforms are compared. callr runs one test in a
  fresh R session. The boot and callr tests and tests/spelling.R skip on CRAN.
  testthat and withr run the tests, and knitr and rmarkdown build the
  vignettes.
* Example variants that draw several multi-panel figures are wrapped in
  `\donttest{}`. In the run above, R CMD check timed no example at more than
  five seconds in any leg.
* The five bundled datasets are reproducibly simulated and contain no personal
  or proprietary data.

## Downstream dependencies

There are no reverse dependencies on CRAN.
