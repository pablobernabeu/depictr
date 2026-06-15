# Regression tests for summary_table() and correlation_heatmap() fixes.

# --- summary_table(): single-value (sub)group -------------------------------

test_that("summary_table() does not print 'mean (NA)' for single-value cells", {
  df <- data.frame(g = c("a", "a", "b"), x = c(1, 2, 5))
  tab <- summary_table(df, vars = "x", group = "g")

  cell <- tab[tab$statistic == "Mean (SD)", "b"]
  # Group "b" has a single observation: SD is undefined, so no "(NA)".
  expect_false(grepl("NA", cell))
  expect_match(cell, "n=1")
  # The two-observation group still gets a proper Mean (SD).
  expect_match(tab[tab$statistic == "Mean (SD)", "a"], "\\d\\.\\d \\(\\d\\.\\d\\)")
})

# --- summary_table(): identifier columns skipped when vars = NULL -----------

test_that("summary_table(vars = NULL) skips high-cardinality ID columns", {
  # crop_yield$field is a unique identifier per row.
  expect_message(
    tab <- summary_table(crop_yield),
    "skipping high-cardinality"
  )
  expect_false("field" %in% tab$variable)
  # No junk one-per-row rows: far fewer than nrow(crop_yield).
  expect_lt(nrow(tab), 20)
  # Real variables are still summarised.
  expect_true("treatment" %in% tab$variable)
  expect_true("yield" %in% tab$variable)
})

test_that("summary_table() still includes an ID column if asked explicitly", {
  tab <- summary_table(crop_yield, vars = c("field", "yield"))
  expect_true("field" %in% tab$variable)
})

# --- summary_table(): N and missingness reporting ---------------------------

test_that("summary_table() reports overall and per-group N", {
  tab <- summary_table(crop_yield, vars = "yield")
  expect_equal(tab$variable[1], "N")
  expect_equal(tab$Overall[1], as.character(nrow(crop_yield)))

  grouped <- summary_table(crop_yield, vars = "yield", group = "treatment")
  expect_equal(grouped$variable[1], "N")
  lv <- levels(crop_yield$treatment)
  expect_true(all(lv %in% names(grouped)))
  # Per-group N matches the actual counts.
  expect_equal(grouped[1, "standard"],
               as.character(sum(crop_yield$treatment == "standard")))
})

test_that("summary_table() reports per-variable missingness when present", {
  # wellbeing_survey$sleep_hours contains NAs.
  tab <- summary_table(wellbeing_survey, vars = "sleep_hours")
  expect_true("Missing, n (%)" %in% tab$statistic)
  miss_cell <- tab[tab$statistic == "Missing, n (%)", "Overall"]
  expect_match(miss_cell, sprintf("^%d ", sum(is.na(wellbeing_survey$sleep_hours))))

  # No missingness row for a complete variable.
  tab2 <- summary_table(crop_yield, vars = "yield")
  expect_false("Missing, n (%)" %in% tab2$statistic)

  # missing = FALSE suppresses the row entirely.
  tab3 <- summary_table(wellbeing_survey, vars = "sleep_hours", missing = FALSE)
  expect_false("Missing, n (%)" %in% tab3$statistic)
})

# --- correlation_heatmap(): zero-variance columns ---------------------------

test_that("correlation_heatmap() drops zero-variance columns without warning", {
  df <- data.frame(a = c(1, 2, 3, 4, 5),
                   b = c(2, 4, 6, 8, 10),
                   const = c(7, 7, 7, 7, 7))

  expect_message(
    p <- correlation_heatmap(df),
    "zero-variance"
  )
  expect_s3_class(p, "ggplot")
  # The constant column must not appear in the correlation data.
  expect_false("const" %in% as.character(p$data$var1))

  # No raw "standard deviation is zero" warning should reach the caller,
  # even when the plot is fully built.
  expect_no_warning(suppressMessages(ggplot2::ggplot_build(
    correlation_heatmap(df)
  )))
})

test_that("correlation_heatmap() errors if too few columns remain after drop", {
  df <- data.frame(a = c(1, 2, 3), k = c(5, 5, 5), j = c(9, 9, 9))
  expect_error(
    suppressMessages(correlation_heatmap(df)),
    "two numeric"
  )
})

test_that("correlation_heatmap() labels undefined (NA) cells as 'n/a'", {
  # a and b never co-occur, so their pairwise correlation is NA.
  df <- data.frame(a = c(1, 2, 3, NA, NA, NA),
                   b = c(NA, NA, NA, 4, 5, 6),
                   c = c(1, 2, 3, 4, 5, 6))
  p <- correlation_heatmap(df, show_values = TRUE)
  gb <- ggplot2::ggplot_build(p)
  labels <- gb$data[[2]]$label
  expect_true(any(labels == "n/a"))
})
