# CRAN release checklist for depictr

A short, practical checklist for the first CRAN submission. Items marked
**[done]** are already in place in this repository; the rest need a networked
machine with a full R toolchain.

## Before submitting

- [done] `DESCRIPTION` complete: Title, Description, Authors@R (aut, cre),
  License (MIT + file LICENSE), URL, BugReports, Language: en-GB.
- [done] `NAMESPACE`, all `man/*.Rd`, and `NEWS.md` generated and current.
- [done] Every exported function has a runnable example; heavy back-ends
  (lme4, broom, simr) are in Suggests and used conditionally.
- [done] Tests (testthat, edition 3) and six vignettes build offline.
- [done] `cran-comments.md` drafted.
- [ ] **Confirm the name is free**: run `available.packages()` / check
  <https://cran.r-project.org/package=depictr>. (No conflict found at the time
  of writing; `statVisual` is archived.)
- [ ] Run `urlchecker::url_check()` to validate URLs (the GitHub URLs resolve
  only once the repository is named `depictr`).
- [ ] Run `devtools::check(remote = TRUE, manual = TRUE)` — exercises the
  CRAN incoming checks and the PDF manual that were skipped in the offline
  build here. Expect 0 errors / 0 warnings; the only local note (`simr` not
  installable offline) disappears where Suggests are available.
- [ ] Run `devtools::check_win_devel()` and a `rhub::rhub_check()` across
  platforms.
- [ ] Spell check: `devtools::spell_check()` (British English).
- [ ] Bump to a release version if desired and update `NEWS.md`.

## Submitting

- [ ] `devtools::submit_cran()` (or `devtools::release()`), then confirm the
  email.

## After acceptance

- [ ] Tag the release on GitHub.
- [ ] The `pkgdown` workflow publishes the site to GitHub Pages on push to the
  default branch; enable Pages (gh-pages branch) in the repository settings.

## Repository note

This package currently lives in the `frequentist_bayesian_plot` repository for
historical reasons. Rename it to `depictr` on GitHub (Settings -> rename) so the
package URLs (`https://github.com/pablobernabeu/depictr`) resolve; renaming
preserves history and stars.
