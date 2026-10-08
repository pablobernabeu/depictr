# Run every Rd example with warnings treated as errors.
#
# Usage, from the package root:
#   Rscript dev/run_examples_strict.R
#
# R CMD check runs the examples but lets their warnings through, and the test
# suite passes with warnings too. That is how a ggplot2 floor the code could
# not honour went unnoticed: on ggplot2 3.5.x, label layers warned about an
# unknown `linewidth` and drew borders, and reference lines warned about an
# unknown `inherit.aes`, while every check stayed green. The floors job in
# .github/workflows/R-CMD-check.yaml runs this script against the declared
# minimum ggplot2.
#
# Examples run as R CMD check runs them: \dontrun{} code is skipped and
# \donttest{} code is run. Each one is sourced with its values printed, so a
# plot is drawn (to a null device) and warnings raised while drawing are seen.
# The one warning allowed is depictr_palette()'s notice that it interpolated
# colours past its base set, which an example may ask for on purpose.

if (!file.exists("DESCRIPTION") || !dir.exists("man")) {
  stop("Run this script from the package root.", call. = FALSE)
}

pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
for (p in c("ggplot2", "patchwork")) {
  cat(p, format(utils::packageVersion(p)), "\n")
}

allowed <- "colours interpolated through"
rd_files <- sort(list.files("man", pattern = "\\.Rd$", full.names = TRUE))
# The pages use Rdpack's macros, which parse_Rd() reports as unknown unless it
# is given them.
macros <- tools::loadPkgRdMacros(".")
failures <- character()
n_run <- 0L

grDevices::pdf(NULL)
for (rd in rd_files) {
  ex <- tempfile(fileext = ".R")
  tools::Rd2ex(tools::parse_Rd(rd, macros = macros), ex,
               commentDontrun = TRUE, commentDonttest = FALSE)
  # Rd2ex writes nothing for a page without examples.
  if (!file.exists(ex)) next
  n_run <- n_run + 1L
  outcome <- tryCatch(
    {
      withCallingHandlers(
        utils::capture.output(
          source(ex, local = new.env(parent = globalenv()),
                 print.eval = TRUE, echo = FALSE)
        ),
        warning = function(w) {
          if (!grepl(allowed, conditionMessage(w), fixed = TRUE)) {
            stop(simpleError(paste("warning:", conditionMessage(w))))
          }
          invokeRestart("muffleWarning")
        }
      )
      NULL
    },
    error = function(e) conditionMessage(e)
  )
  unlink(ex)
  if (!is.null(outcome)) {
    failures[[basename(rd)]] <- outcome
    cat("FAIL ", basename(rd), "\n  ", outcome, "\n", sep = "")
  }
}
invisible(grDevices::dev.off())

cat(n_run, "pages with examples run,", length(failures), "failed.\n")
if (length(failures)) {
  stop("Examples failed or warned: ",
       paste(names(failures), collapse = ", "), call. = FALSE)
}
