# CRAN release checklist for depictr

A short, practical checklist for the first CRAN submission. Items marked
**[done]** are already in place in this repository. The rest need a networked
machine with a full R toolchain.

## Before submitting

- [done] `DESCRIPTION` complete: Title, Description, Authors@R (aut, cre),
  License (MIT + file LICENSE), URL, BugReports, Language: en-GB.
- [done] `NAMESPACE`, all `man/*.Rd` and `NEWS.md` generated and current.
- [done] Every exported function has a runnable example. The heavy back-ends
  (lme4, broom, simr) are in Suggests and used conditionally.
- [done] Tests (testthat, edition 3) and six vignettes build offline.
- [done] `cran-comments.md` drafted, and rewritten for 0.3.0 on 2026-08-21.
- [done] Bumped to 0.3.0, with the development section of `NEWS.md` moved under
  a heading for that version, and `CITATION.cff` given the matching version and
  release date. `inst/CITATION` reads `meta$Version`, so it needs no edit.
- [done] Name is free. <https://cran.r-project.org/package=depictr> returned 404
  on 2026-08-21, and `statVisual` remains archived.
- [done] URLs validated. `R CMD check --as-cran` reported no invalid URLs, and
  the four addresses in `DESCRIPTION`, `CITATION.cff` and `inst/CITATION` were
  fetched by hand and all resolved.
- [done] `R CMD check --as-cran` run on a built tarball, with pandoc on the
  subprocess PATH: 0 errors, 0 warnings, 1 note (the new-submission note). The
  PDF manual built.
- [done] Checked with the suggested packages absent, using
  `_R_CHECK_DEPENDS_ONLY_=true`: status OK, no errors, warnings or notes, with
  1224 tests passing and 17 skipped by their guards.
- [ ] Run `devtools::check_win_devel()` and a `rhub::rhub_check()` across
  platforms. GitHub Actions already covers Linux, macOS and Windows on release,
  devel and oldrel-1, so this is the remaining gap.
- [ ] Spell check: `devtools::spell_check()` (British English). The machine used
  for the runs above has no aspell dictionary, so this one is still outstanding.
  `inst/WORDLIST` holds the accepted technical terms.

## Submitting

- [ ] `devtools::submit_cran()` (or `devtools::release()`), then confirm the
  email.

## After acceptance

- [ ] Tag the release on GitHub.
- [ ] The `pkgdown` workflow publishes the site to GitHub Pages on push to the
  default branch, so enable Pages (gh-pages branch) in the repository settings.
