# CRAN update release checklist for depictr

This checklist is for each update release on CRAN. GitHub Actions runs the
checks, so a browser is enough to submit. A local R toolchain is optional.

## Before submitting

- [ ] Bump the version in `DESCRIPTION`, move the development section of
  `NEWS.md` under a heading for that version and give `CITATION.cff` the
  matching version. `inst/CITATION` reads `meta$Version` and the About article
  the installed version, so both need an edit only when the year changes.
- [ ] `DESCRIPTION` complete: Title, Description, Authors@R (aut, cre),
  License (MIT + file LICENSE), URL, BugReports, Language: en-GB.
- [ ] Every exported function has a runnable example. The heavy back-ends
  (lme4, broom, simr) are in Suggests and used conditionally.
- [ ] Every check of the R-CMD-check workflow passes on the head to submit:
  - the six platform legs, the Linux R-devel leg with its Latin-9 test run,
  - 'NAMESPACE and man/ match the roxygen comments', which regenerates both
    with the roxygen2 version `DESCRIPTION` records,
  - 'Strong dependencies only', which checks the package with
    `_R_CHECK_DEPENDS_ONLY_=true`,
  - 'R (declared minimum, 4.1)', which runs the tests on the R floor in
    `Depends`,
  - the two 'Declared minimum dependencies' jobs.
- [ ] Spell check: `devtools::check()` runs the spelling test in
  `tests/spelling.R`, which stops at any word found neither in the British
  English dictionary nor in `inst/WORDLIST`. A plain `R CMD check` skips it.
- [ ] Rewrite `cran-comments.md` for this submission, with its check results,
  test environments, notes and downstream dependencies. Until then, it describes
  the last submission.
- [ ] Add the label `cran-tarball` to the release pull request. The
  cran-tarball workflow builds the tarball and checks it with
  `R CMD check --as-cran` and CRAN's incoming checks, URL checks included. It
  must give no ERROR or WARNING, and any NOTE must be explained in
  `cran-comments.md`. The run summary gives the tarball's SHA-256 and the
  reverse dependencies. Remove the label afterwards.

## Submitting

- [ ] Download the tarball artifact of that run, unzip it, upload the tarball
  at <https://cran.r-project.org/submit.html> with `cran-comments.md` in the
  comment field, and confirm the email. The maintainer's release guide gives
  the steps in full.

## After acceptance

- [ ] Date the release in `CITATION.cff` by the day it first became public,
  on CRAN or as a GitHub release, and record each channel's day in the comment
  above `date-released`.
- [ ] Tag the release on GitHub and publish a GitHub release from the tag,
  which Zenodo archives.
- [ ] Check that the `pkgdown` workflow has published the site to GitHub Pages.
  It runs on each published release and on every push to the default branch.
