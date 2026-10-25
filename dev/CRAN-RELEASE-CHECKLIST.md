# CRAN update release checklist for depictr

A short, practical checklist for each update release on CRAN. Most of the checks
need a networked machine with a full R toolchain.

## Before submitting

- [ ] Bump the version in `DESCRIPTION`, move the development section of
  `NEWS.md` under a heading for that version and give `CITATION.cff` the
  matching version. `inst/CITATION` reads `meta$Version` and the About article
  the installed version, so both need an edit only when the year changes.
- [ ] `DESCRIPTION` complete: Title, Description, Authors@R (aut, cre),
  License (MIT + file LICENSE), URL, BugReports, Language: en-GB.
- [ ] `NAMESPACE`, all `man/*.Rd` and `NEWS.md` generated and current.
- [ ] Every exported function has a runnable example. The heavy back-ends
  (lme4, broom, simr) are in Suggests and used conditionally.
- [ ] Tests (testthat, edition 3) and the vignettes build offline.
- [ ] Spell check: `devtools::check()` runs the spelling test in
  `tests/spelling.R`, which stops at any word found neither in the British
  English dictionary nor in `inst/WORDLIST`. A plain `R CMD check` skips it.
- [ ] URLs validated. `R CMD check --as-cran` reports no invalid URLs, and the
  addresses in `DESCRIPTION`, `CITATION.cff` and `inst/CITATION` resolve when
  fetched by hand.
- [ ] `R CMD check --as-cran` run on a built tarball, with pandoc on the
  subprocess PATH: 0 errors and 0 warnings, with any note explained in
  `cran-comments.md`. The PDF manual builds.
- [ ] Checked with the suggested packages absent, using
  `_R_CHECK_DEPENDS_ONLY_=true`: status OK, with no errors, warnings or notes
  and the tests that need a suggested package skipped by their guards.
- [ ] Run a `rhub::rhub_check()` across platforms. GitHub Actions checks the R
  release on Linux, macOS and Windows, R-devel on Linux and Windows and
  oldrel-1 on Linux. Windows on R-devel is what `devtools::check_win_devel()`
  checks on win-builder, so that call is optional.
- [ ] Rewrite `cran-comments.md` for this submission, with its check results,
  test environments, notes and downstream dependencies. Until then, it describes
  the last submission.

## Submitting

- [ ] `devtools::submit_cran()` (or `devtools::release()`), then confirm the
  email.

## After acceptance

- [ ] Date the release in `CITATION.cff` by the day it first became public,
  on CRAN or as a GitHub release, and record each channel's day in the comment
  above `date-released`.
- [ ] Tag the release on GitHub and publish a GitHub release from the tag,
  which Zenodo archives.
- [ ] Check that the `pkgdown` workflow has published the site to GitHub Pages.
  It runs on each published release and on every push to the default branch.
