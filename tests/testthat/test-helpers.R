test_that("format_terms() tidies names and interactions", {
  expect_equal(format_terms("(Intercept)"), "Intercept")
  expect_equal(format_terms("b_conditionB"), "conditionB")
  expect_equal(format_terms("a:b"), "a × b")
  expect_equal(format_terms("a:b", interaction = "asterisk"), "a * b")
  expect_equal(format_terms("a:b", interaction = "colon"), "a:b")
})

test_that("format_terms() can wrap long labels", {
  out <- format_terms("alpha:beta:gamma:delta", wrap = 8)
  expect_true(grepl("\n", out))
})

test_that("statviz_palette() returns the requested number of colours", {
  expect_length(statviz_palette(3), 3)
  expect_length(statviz_palette(20), 20)          # interpolates
  expect_match(statviz_palette(1), "^#")
  expect_error(statviz_palette(0), "positive")
})

test_that("theme_statviz() and scales return the right objects", {
  expect_s3_class(theme_statviz(), "theme")
  expect_s3_class(scale_colour_statviz(), "Scale")
  expect_s3_class(scale_fill_statviz(), "Scale")
})
