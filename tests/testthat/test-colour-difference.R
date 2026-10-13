# Colour difference: CIEDE2000, and the CIE76 distance it replaces ------------

test_that("CIEDE2000 reproduces the 34 pairs Sharma, Wu and Dalal published", {
  # Their supplementary test data, as the authors distribute it, with the
  # differences given to four decimals. The pairs include the discontinuities
  # in the mean hue and the hue difference, where implementations go wrong.
  # The Python suite reads an identical copy of the file.
  pairs <- utils::read.csv(test_path("fixtures", "sharma2005.csv"))
  expect_identical(nrow(pairs), 34L)
  first <- as.matrix(pairs[, c("L1", "a1", "b1")])
  second <- as.matrix(pairs[, c("L2", "a2", "b2")])
  ours <- .ciede2000(first, second)
  expect_true(all(abs(ours - pairs$delta_e_2000) <= 1e-4),
              info = paste("pairs", paste(pairs$pair[
                abs(ours - pairs$delta_e_2000) > 1e-4], collapse = ", ")))
  # The formula is symmetric in its two colours.
  expect_equal(.ciede2000(second, first), ours)
})

test_that("the 1976 distance overstates differences between saturated colours", {
  # Two blues a reader can barely tell apart, measured both ways. The Python
  # suite pins the same numbers.
  blues <- c("#005b96", "#0060a8")
  expect_equal(palette_safety(blues)$by_condition[["normal"]], 2.69)
  expect_equal(palette_safety(blues, metric = "cie76")$by_condition[["normal"]],
               8.2)
})

test_that("ggplot2's default five colours pass under CIE76 and fail under CIEDE2000", {
  # Under deuteranopia the sky blue and the pink become #709df5 and #80a3ef,
  # 7.35 apart by the 1976 distance, which certified the palette as safe, and
  # 2.74 apart in CIEDE2000.
  hue5 <- c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3")
  expect_identical(simulate_cvd(c("#00B0F6", "#E76BF3"), "deutan"),
                   c("#709df5", "#80a3ef"))
  now <- palette_safety(hue5)
  expect_false(now$safe)
  expect_equal(now$min_delta_e, 2.74)
  expect_identical(now$worst_condition, "deutan")
  expect_identical(now$worst_pair, c("#00B0F6", "#E76BF3"))
  expect_identical(palette_safety(hue5, metric = "ciede2000"), now)
  old <- palette_safety(hue5, metric = "cie76")
  expect_true(old$safe)
  expect_equal(old$min_delta_e, 7.35)
  expect_identical(old$worst_pair, c("#00B0F6", "#E76BF3"))
})

test_that("palette_safety() refuses a metric it does not know", {
  expect_error(palette_safety(metric = "cie94"), "should be one of")
})
