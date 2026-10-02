test_that("pca_plot() works from data frames and prcomp objects", {
  expect_s3_class(
    pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "yield")),
    "ggplot"
  )
  expect_s3_class(
    pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "yield"),
             group = "treatment"),
    "ggplot"
  )
  pc <- prcomp(crop_yield[c("rainfall", "fertiliser", "yield")], scale. = TRUE)
  expect_s3_class(pca_plot(pc), "ggplot")
  expect_error(pca_plot(crop_yield, cols = "yield"), "at least two")
})

# The built layer drawn with a given geom, such as "GeomSegment".
built_layer <- function(p, geom) {
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  ggplot2::ggplot_build(p)$data[[which(geoms == geom)]]
}

test_that("pca_plot() fixes the aspect and draws arrows along the loadings", {
  cols <- c("age", "income", "stress", "sleep_hours", "life_satisfaction")
  p <- pca_plot(wellbeing_survey, cols = cols)
  # A free aspect ratio let the device stretch one axis against the other, so
  # the angles on the page depended on the figure's size. ggplot2 4.0.0 made
  # coord_fixed() a wrapper of coord_cartesian(ratio = ), so the test checks
  # what the coord does, whatever its class.
  expect_false(p$coordinates$is_free())
  expect_identical(p$coordinates$ratio, 1)
  # The labels sit beyond the point cloud and must not be clipped.
  expect_identical(p$coordinates$clip, "off")
  # The laid-out panel is as much taller than wide as its y range is longer
  # than its x range, so one unit spans the same length on both axes.
  g <- ggplot2::ggplotGrob(p)
  expect_true(g$respect)
  panel <- g$layout[grepl("^panel", g$layout$name), ]
  ranges <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]
  expect_equal(as.numeric(g$heights[panel$t]) / as.numeric(g$widths[panel$l]),
               diff(ranges$y.range) / diff(ranges$x.range), tolerance = 1e-9)

  # One scale factor for both axes keeps each arrow on its loading's direction.
  keep <- stats::complete.cases(wellbeing_survey[cols])
  rot <- prcomp(wellbeing_survey[keep, cols], scale. = TRUE)$rotation
  seg <- built_layer(p, "GeomSegment")
  expect_equal(atan2(seg$yend - seg$y, seg$xend - seg$x),
               unname(atan2(rot[, 2], rot[, 1])), tolerance = 1e-9)
  # The factor makes the largest coordinate of any arrow three quarters of the
  # largest absolute score, as the documentation says and the Python twin does.
  span <- max(abs(unlist(p$data[c("PCx", "PCy")])))
  mult <- 0.75 * span / max(abs(rot[, 1:2]))
  expect_equal(cbind(seg$xend, seg$yend), unname(rot[, 1:2]) * mult,
               tolerance = 1e-9)
})

# Each case of `group` has a test of its own, so that an error on one cannot
# hide what the next one does.
test_that("pca_plot() refuses a misspelt group column, quoted or not", {
  cols <- c("rainfall", "fertiliser", "yield")
  not_found <- function(name) {
    paste0("Column `", name, "` (argument `group`) not found in the data.")
  }
  # A misspelt string became a level of its own on one point, beside 199 NA,
  # and a bare one failed with R's "object 'treatmnt' not found".
  expect_error(pca_plot(crop_yield, cols = cols, group = "treatmnt"),
               not_found("treatmnt"), fixed = TRUE)
  expect_error(pca_plot(crop_yield, cols = cols, group = treatmnt),
               not_found("treatmnt"), fixed = TRUE)
})

test_that("pca_plot() reads a bare name that finds a function as a column", {
  cols <- c("rainfall", "fertiliser", "yield")
  # `time` and `family` are functions in stats. Read as a vector of groups,
  # each was refused for its length, which hid the missing column.
  expect_error(pca_plot(crop_yield, cols = cols, group = time),
               "Column `time` (argument `group`) not found in the data.",
               fixed = TRUE)
  expect_error(pca_plot(crop_yield, cols = cols, group = family),
               "Column `family` (argument `group`) not found in the data.",
               fixed = TRUE)
  pc <- prcomp(crop_yield[cols], scale. = TRUE)
  expect_error(pca_plot(pc, group = time),
               paste("With a prcomp object, pass `group` as a vector with",
                     "one value per observation."),
               fixed = TRUE)
})

test_that("pca_plot() refuses a group vector of the wrong length", {
  cols <- c("rainfall", "fertiliser", "yield")
  # A short vector was padded with NA.
  expect_error(pca_plot(crop_yield, cols = cols,
                        group = crop_yield$treatment[1:10]),
               "`group` has length 10 but `x` has 200 rows.", fixed = TRUE)
  # The length is that of `x` before incomplete rows are dropped.
  gappy <- crop_yield
  gappy$rainfall[1] <- NA
  expect_error(pca_plot(gappy, cols = cols, group = gappy$treatment[-1]),
               "`group` has length 199 but `x` has 200 rows.", fixed = TRUE)
})

test_that("pca_plot() asks a prcomp object for one group per observation", {
  cols <- c("rainfall", "fertiliser", "yield")
  pc <- prcomp(crop_yield[cols], scale. = TRUE)
  # A short vector was recycled, and a column name put every point in one
  # level named after the column.
  expect_error(pca_plot(pc, group = crop_yield$treatment[1:10]),
               paste("`group` has length 10 but the prcomp object has scores",
                     "for 200 observations."),
               fixed = TRUE)
  prcomp_msg <- paste("With a prcomp object, pass `group` as a vector with",
                      "one value per observation.")
  expect_error(pca_plot(pc, group = "treatment"), prcomp_msg, fixed = TRUE)
  expect_error(pca_plot(pc, group = treatment), prcomp_msg, fixed = TRUE)
})

test_that("pca_plot() refuses a prcomp object without scores", {
  cols <- c("rainfall", "fertiliser", "yield")
  # Without scores there is nothing to count the group against, or to draw.
  no_scores <- prcomp(crop_yield[cols], scale. = TRUE, retx = FALSE)
  expect_error(pca_plot(no_scores, group = crop_yield$treatment),
               "The prcomp object holds no scores.", fixed = TRUE)
  expect_error(pca_plot(no_scores), "The prcomp object holds no scores.",
               fixed = TRUE)
})

test_that("pca_plot() takes an unquoted group column", {
  cols <- c("rainfall", "fertiliser", "yield")
  quoted <- pca_plot(crop_yield, cols = cols, group = "treatment")$data$group
  expect_identical(
    pca_plot(crop_yield, cols = cols, group = treatment)$data$group, quoted
  )
  # The groups of the rows the analysis drops are dropped with them.
  gappy <- crop_yield
  gappy$rainfall[1] <- NA
  expect_identical(pca_plot(gappy, cols = cols, group = treatment)$data$group,
                   as.factor(gappy$treatment)[-1])
})

test_that("pca_plot() takes group as a string, a variable or a vector", {
  cols <- c("rainfall", "fertiliser", "yield")
  quoted <- pca_plot(crop_yield, cols = cols, group = "treatment")$data$group
  expect_identical(quoted, as.factor(crop_yield$treatment))
  expect_identical(
    pca_plot(crop_yield, cols = cols, group = crop_yield$treatment)$data$group,
    quoted
  )
  held <- "treatment"
  expect_identical(pca_plot(crop_yield, cols = cols, group = held)$data$group,
                   quoted)
  pc <- prcomp(crop_yield[cols], scale. = TRUE)
  expect_identical(pca_plot(pc, group = crop_yield$treatment)$data$group,
                   quoted)
})

test_that("scree_plot() returns a ggplot", {
  expect_s3_class(
    scree_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
                                    "yield")),
    "ggplot"
  )
})

test_that("raincloud_plot() and group_comparison_plot() work", {
  expect_s3_class(raincloud_plot(lexical_decision, RT, group = condition),
                  "ggplot")
  expect_s3_class(raincloud_plot(crop_yield, yield), "ggplot")
  expect_error(raincloud_plot(crop_yield, treatment), "numeric")

  p <- group_comparison_plot(lexical_decision, RT, condition)
  expect_s3_class(p, "ggplot")
  expect_error(group_comparison_plot(crop_yield, treatment, treatment),
               "numeric")
})

test_that("survival_plot() accepts vectors, data frames and groups", {
  set.seed(1)
  n <- 120
  g <- sample(c("a", "b"), n, replace = TRUE)
  tt <- rexp(n, ifelse(g == "b", 0.05, 0.1))
  cc <- runif(n, 0, 30)
  obs <- pmin(tt, cc)
  ev <- as.integer(tt <= cc)
  expect_s3_class(survival_plot(obs, ev, group = g), "ggplot")
  expect_s3_class(survival_plot(obs, ev), "ggplot")
  df <- data.frame(time = obs, status = ev, group = g)
  expect_s3_class(survival_plot(df), "ggplot")
  expect_error(survival_plot(obs), "status")
})

test_that("vif_plot() and pr_curve_plot() work", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  expect_s3_class(vif_plot(fit), "ggplot")
  expect_error(vif_plot(lm(yield ~ rainfall, data = crop_yield)),
               "at least two")

  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  p <- pr_curve_plot(gfit)
  expect_s3_class(p, "ggplot")
  ap <- attr(p, "average_precision")
  expect_true(ap >= 0 && ap <= 1)
})
