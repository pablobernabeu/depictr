# citation("depictr"), DESCRIPTION and the CITATION.cff that GitHub, Zenodo
# and reference managers read must name the same author and date the same
# release. inst/CITATION gave no ORCID iD, although DESCRIPTION and CITATION.cff
# did, and CITATION.cff dated 0.3.0 by CRAN's publication on 2026-09-01, five
# days after the GitHub release had made it public. A version is dated by the
# day it first became public on any channel, a CRAN publication or a GitHub
# release, with each channel's day recorded beside the date. The tests that read
# CITATION.cff skip outside the repository, since the file is not built into the
# package.

orcid_in_description <- function() {
  path <- system.file("DESCRIPTION", package = "depictr")
  authors <- eval(parse(text = read.dcf(path, fields = "Authors@R")[1, 1]))
  orcid <- unname(authors[[1]]$comment["ORCID"])
  expect_match(orcid, "^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$")
  orcid
}

citation_cff <- function() {
  path <- testthat::test_path("..", "..", "CITATION.cff")
  testthat::skip_if_not(file.exists(path), "CITATION.cff is not in this tree")
  readLines(path, encoding = "UTF-8", warn = FALSE)
}

cff_field <- function(lines, field) {
  line <- grep(sprintf("^%s:", field), lines, value = TRUE)
  expect_length(line, 1L)
  gsub('^[^:]+:\\s*"?|"?\\s*$', "", line)
}

# The comment lines directly above a field, joined into one string.
cff_comment_above <- function(lines, field) {
  i <- grep(sprintf("^%s:", field), lines)[1] - 1L
  comment <- character()
  while (i >= 1L && startsWith(lines[[i]], "#")) {
    comment <- c(lines[[i]], comment)
    i <- i - 1L
  }
  paste(comment, collapse = " ")
}

# The earliest day each released version was public on any channel.
first_public <- c("0.3.0" = "2026-08-27")

test_that("citation('depictr') gives the author's ORCID iD", {
  cit <- utils::readCitationFile(system.file("CITATION", package = "depictr"),
                                 meta = list(Version = "0.3.0"))
  author <- cit$author[[1]]
  expect_identical(unname(author$comment["ORCID"]), orcid_in_description())
  expect_identical(unname(author$comment["ORCID"]), "0000-0003-1083-2460")
})

test_that("CITATION.cff gives the ORCID iD that DESCRIPTION gives", {
  lines <- citation_cff()
  orcid <- trimws(grep("^\\s+orcid:", lines, value = TRUE))
  expect_identical(
    orcid,
    sprintf('orcid: "https://orcid.org/%s"', orcid_in_description())
  )
})

test_that("CITATION.cff dates the release by the day it first became public", {
  lines <- citation_cff()
  version <- cff_field(lines, "version")
  released <- cff_field(lines, "date-released")
  comment <- cff_comment_above(lines, "date-released")
  expect_match(comment, "GitHub release", fixed = TRUE)
  expect_match(comment, "CRAN", fixed = TRUE)
  days <- sort(regmatches(comment, gregexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", comment))[[1]])
  expect_gte(length(days), 1L)
  expect_identical(released, days[1])
  if (version %in% names(first_public)) {
    expect_identical(released, first_public[[version]])
  }
})
