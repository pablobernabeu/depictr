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
  # First qualitative colour is the brand blue
  expect_equal(toupper(statviz_palette(1)), "#005B96")
})

test_that("statviz_palette() supports sequential and diverging types", {
  expect_length(statviz_palette(5, type = "sequential"), 5)
  expect_length(statviz_palette(9, type = "diverging"), 9)
  expect_true(all(grepl("^#", statviz_palette(4, type = "sequential"))))
  expect_s3_class(palette_preview(type = "all"), "ggplot")
  expect_s3_class(palette_preview(6, type = "diverging"), "ggplot")
})

test_that("theme_statviz() and scales return the right objects", {
  expect_s3_class(theme_statviz(), "theme")
  expect_s3_class(scale_colour_statviz(), "Scale")
  expect_s3_class(scale_fill_statviz(), "Scale")
})
