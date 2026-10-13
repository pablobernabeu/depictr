# One rule for the grouping variable of every grouped plot.
#
# A numeric code becomes a group, and a numeric column with more than 20
# distinct values is refused as continuous. Levels without data leave the
# legend and the palette, and rows with a missing group are dropped with a
# message. The colours pinned below are pinned in the Python twin's
# tests/test_grouping.py as well, so that a level takes the same colour in both
# packages.

# Each plot is called on a frame with numeric `x` and `y`, a categorical `cat`
# for explore_categorical() to count and the grouping column `grp`. The
# aesthetics are those each function maps to the group.
grouped_plots <- list(
  scatter_trend = list(
    plot = function(d) scatter_trend(d, x, y, group = grp),
    aes = c("colour", "fill")
  ),
  ecdf_plot = list(
    plot = function(d) ecdf_plot(d, y, group = grp),
    aes = "colour"
  ),
  explore_distribution = list(
    plot = function(d) explore_distribution(d, y, group = grp, type = "both"),
    aes = c("colour", "fill")
  ),
  raincloud_plot = list(
    plot = function(d) raincloud_plot(d, y, group = grp),
    aes = c("colour", "fill")
  ),
  group_comparison_plot = list(
    plot = function(d) group_comparison_plot(d, y, grp),
    aes = "colour"
  ),
  explore_categorical = list(
    plot = function(d) explore_categorical(d, cat, group = grp),
    aes = "fill"
  ),
  ridgeline_plot = list(
    plot = function(d) ridgeline_plot(d, y, grp),
    aes = "fill"
  ),
  outlier_plot = list(
    plot = function(d) outlier_plot(d, y, group = grp),
    aes = "fill"
  )
)

# The colour each level takes, read from the trained scale of the built plot,
# whose limits are the levels that take a colour.
level_colours <- function(p, aesthetic) {
  sc <- ggplot2::ggplot_build(p)$plot$scales$get_scales(aesthetic)
  lims <- sc$get_limits()
  stats::setNames(as.character(sc$map(lims)), lims)
}

# The palette colours drawn in any layer of the built plot. An unused level
# that kept a slot shows up here as a colour the legend does not explain.
drawn_palette <- function(p, aesthetic) {
  layers <- ggplot2::ggplot_build(p)$data
  drawn <- unique(unlist(lapply(layers, function(d) d[[aesthetic]])))
  sort(intersect(drawn, c(depictr_palette(8), depictr_opt("na_value"))))
}

# The colour scales of every panel of an explore_pairs() matrix.
pairs_level_colours <- function(pp) {
  out <- list()
  for (i in seq_along(pp)) {
    for (aesthetic in c("colour", "fill")) {
      sc <- ggplot2::ggplot_build(pp[[i]])$plot$scales$get_scales(aesthetic)
      if (!is.null(sc)) {
        lims <- sc$get_limits()
        out[[paste("panel", i, aesthetic)]] <- stats::setNames(
          as.character(sc$map(lims)), lims)
      }
    }
  }
  out
}

expect_level_colours <- function(name, p, expected) {
  for (aesthetic in grouped_plots[[name]]$aes) {
    expect_identical(level_colours(p, aesthetic), expected,
                     label = paste(name, aesthetic, "scale"))
    expect_identical(drawn_palette(p, aesthetic), sort(unname(expected)),
                     label = paste(name, aesthetic, "layers"))
  }
}

expect_pairs_colours <- function(pp, expected) {
  scales <- pairs_level_colours(pp)
  # Two density panels with a fill and a colour scale each, and a scatter and
  # a correlation panel with a colour scale each.
  expect_length(scales, 6)
  for (key in names(scales)) {
    expect_identical(scales[[key]], expected, label = key)
  }
}

# wellbeing_survey without its North respondents: the factor keeps North as
# an unused level between East and South.
unused_frame <- function() {
  sub <- subset(wellbeing_survey, region != "North")
  data.frame(x = sub$age, y = sub$income, cat = sub$education,
             grp = sub$region)
}

# crop_yield with a block coded 1 and 2.
numeric_frame <- function() {
  data.frame(x = crop_yield$fertiliser, y = crop_yield$yield,
             cat = rep(c("a", "b", "c", "d"), length.out = nrow(crop_yield)),
             grp = rep(c(1, 2), length.out = nrow(crop_yield)))
}

# crop_yield with the treatment of its first five fields missing.
missing_frame <- function() {
  d <- data.frame(x = crop_yield$fertiliser, y = crop_yield$yield,
                  cat = rep(c("a", "b", "c", "d"),
                            length.out = nrow(crop_yield)),
                  grp = crop_yield$treatment)
  d$grp[1:5] <- NA
  d
}

unused_colours <- c(East = "#005b96", South = "#e69f00", West = "#009e73")
numeric_colours <- c(`1` = "#005b96", `2` = "#e69f00")
treatment_colours <- c(standard = "#005b96", enhanced = "#e69f00")
missing_message <- "5 observation(s) with a missing group were dropped."

for (name in names(grouped_plots)) {
  plot_fun <- grouped_plots[[name]]$plot

  test_that(paste0(name, "(): an unused level takes no colour and no slot"), {
    d <- unused_frame()
    expect_identical(levels(d$grp), c("East", "North", "South", "West"))
    # raincloud_plot() and group_comparison_plot() warned that North had too
    # few observations, and drew nothing for it.
    expect_no_warning(p <- plot_fun(d))
    expect_no_warning(ggplot2::ggplot_build(p))
    expect_level_colours(name, p, unused_colours)
  })

  test_that(paste0(name, "(): a numeric code becomes a group"), {
    # scatter_trend() failed with "Continuous value supplied to a discrete
    # scale", and explore_distribution() and ecdf_plot() drew one ungrouped
    # curve with a warning that the aesthetics were dropped.
    expect_no_warning(p <- plot_fun(numeric_frame()))
    expect_no_warning(ggplot2::ggplot_build(p))
    expect_level_colours(name, p, numeric_colours)
  })

  test_that(paste0(name, "(): rows with a missing group are dropped with a message"), {
    # scatter_trend() and outlier_plot() drew the missing rows as a grey group
    # of their own, raincloud_plot() failed with "'x' contains missing
    # values", and the others dropped them without a word.
    expect_message(p <- plot_fun(missing_frame()), missing_message,
                   fixed = TRUE)
    expect_level_colours(name, p, treatment_colours)
  })

  test_that(paste0(name, "(): a continuous or wholly missing group is refused"), {
    d <- numeric_frame()
    d$grp <- d$x
    expect_error(
      plot_fun(d),
      paste0("`group` (grp) is numeric with ", length(unique(d$x)),
             " distinct values; it looks continuous, not categorical. ",
             "Bin it, or convert it to a factor first."),
      fixed = TRUE
    )
    d <- missing_frame()
    d$grp <- NA
    expect_error(plot_fun(d), "`group` is missing for every observation.",
                 fixed = TRUE)
  })
}

test_that("explore_pairs() gives a level the same colour in every panel", {
  d <- unused_frame()
  pp <- explore_pairs(d, cols = c("x", "y"), group = grp)
  expect_pairs_colours(pp, unused_colours)
  # The correlation panel listed the unused level as "North: NA".
  labels <- ggplot2::ggplot_build(pp[[2]])$data[[1]]$label
  expect_length(labels, 3)
  expect_false(any(grepl("North", labels)))
})

test_that("explore_pairs() follows the same rule for codes and missing groups", {
  expect_pairs_colours(
    explore_pairs(numeric_frame(), cols = c("x", "y"), group = grp),
    numeric_colours
  )
  expect_message(
    pp <- explore_pairs(missing_frame(), cols = c("x", "y"), group = grp),
    missing_message, fixed = TRUE
  )
  expect_pairs_colours(pp, treatment_colours)
  d <- numeric_frame()
  d$grp <- d$x
  expect_error(explore_pairs(d, cols = c("x", "y"), group = grp),
               "it looks continuous, not categorical", fixed = TRUE)
  # A numeric group is left out of the default columns. It was drawn as a
  # variable of the matrix as well, and failed once it had become a factor.
  pp <- explore_pairs(numeric_frame(), group = grp)
  expect_length(pp, 4)
  expect_pairs_colours(pp, numeric_colours)
  # Named in `cols` as well, it failed with "'x' must be numeric".
  expect_error(
    explore_pairs(numeric_frame(), cols = c("x", "y", "grp"), group = grp),
    "`group` (grp) is drawn in colour, so it cannot also be one of `cols`.",
    fixed = TRUE
  )
})

test_that("group_comparison_plot() follows the rule with its difference panel", {
  # With differences = TRUE, estimation_plot() formed the groups, dropping
  # missing ones without a word and taking any number of numeric codes.
  withr::local_seed(1)
  expect_message(
    pp <- group_comparison_plot(missing_frame(), y, grp, differences = TRUE,
                                n_boot = 200),
    missing_message, fixed = TRUE
  )
  expect_identical(level_colours(pp[[1]], "colour"), treatment_colours)
  d <- numeric_frame()
  d$grp <- d$x
  expect_error(
    group_comparison_plot(d, y, grp, differences = TRUE, n_boot = 200),
    "it looks continuous, not categorical", fixed = TRUE
  )
})

test_that("twenty distinct codes are still groups", {
  d <- numeric_frame()
  d$grp <- rep(1:20, length.out = nrow(d))
  # Twenty groups are past the eight colours of the palette, which says so.
  expect_warning(p <- scatter_trend(d, x, y, group = grp),
                 "20 colours interpolated", fixed = TRUE)
  expect_length(level_colours(p, "colour"), 20)
})

test_that("no colour scale is added where no layer draws in it", {
  # Grouped histogram bars have no outline, and a raincloud of groups too
  # sparse for a half-violin fills nothing. A scale named by level for either
  # warned that it had found no level to colour.
  d <- unused_frame()
  expect_no_warning(
    ggplot2::ggplot_build(explore_distribution(d, y, group = grp))
  )
  sparse <- data.frame(y = c(1, 9), g = c("a", "b"))
  expect_warning(p <- raincloud_plot(sparse, y, group = g), "n < 2")
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("a group too sparse for a ridge leaves the other ridges their colours", {
  # The sparse group's level had no ridge to train the fill scale, so the
  # colours of the levels after it moved up by one.
  d <- data.frame(y = c(5, seq(1, 10, length.out = 20),
                        seq(4, 13, length.out = 20)),
                  g = rep(c("a", "b", "c"), c(1, 20, 20)))
  expect_warning(p <- ridgeline_plot(d, y, g), "n < 2: a", fixed = TRUE)
  expect_identical(level_colours(p, "fill"),
                   c(b = "#e69f00", c = "#009e73"))
})

test_that("an unused level leaves the axis of the plots that place groups on it", {
  d <- unused_frame()
  axis_labels <- function(p, axis) {
    params <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]
    as.character(params[[axis]]$get_labels())
  }
  # group_comparison_plot() moved the empty North to the end of the axis.
  expect_identical(axis_labels(group_comparison_plot(d, y, grp), "x"),
                   c("East", "South", "West"))
  expect_identical(axis_labels(raincloud_plot(d, y, group = grp), "x"),
                   c("East", "South", "West"))
  expect_identical(axis_labels(outlier_plot(d, y, group = grp), "x"),
                   c("East", "South", "West"))
  expect_identical(axis_labels(ridgeline_plot(d, y, grp), "y"),
                   c("East", "South", "West"))
})

test_that("a named palette pins colours to levels, and an unnamed one follows them", {
  d <- unused_frame()
  named <- c(West = "#000000", East = "#cc79a7", South = "#56b4e9")
  p <- scatter_trend(d, x, y, group = grp, palette = named)
  expect_identical(level_colours(p, "colour"),
                   named[c("East", "South", "West")])
  # An unnamed palette is taken in level order over the levels in use.
  unnamed <- c("#000000", "#cc79a7", "#56b4e9", "#f0e442")
  expected <- c(East = "#000000", South = "#cc79a7", West = "#56b4e9")
  p <- raincloud_plot(d, y, group = grp, palette = unnamed)
  expect_identical(level_colours(p, "colour"), expected)
  expect_identical(level_colours(p, "fill"), expected)
  pp <- explore_pairs(d, cols = c("x", "y"), group = grp, palette = unnamed)
  expect_pairs_colours(pp, expected)
})

test_that("explore_categorical() orders and colours the groups by level", {
  # The groups were ordered alphabetically, so postgraduate took the first
  # colour, where the Python twin gives it to secondary.
  p <- explore_categorical(wellbeing_survey, region, group = education)
  expect_identical(
    level_colours(p, "fill"),
    c(secondary = "#005b96", undergraduate = "#e69f00",
      postgraduate = "#009e73")
  )
})

test_that("prepare_group() names the palette by level unless it is named", {
  d <- unused_frame()
  prep <- prepare_group(d, "grp")
  expect_identical(levels(prep$data$grp), c("East", "South", "West"))
  expect_identical(prep$levels, c("East", "South", "West"))
  expect_identical(prep$palette, unused_colours)
  named <- c(South = "#000000", West = "#cc79a7", East = "#56b4e9")
  expect_identical(prepare_group(d, "grp", named)$palette, named)
  expect_identical(prepare_group(d, "grp", c("red", "blue", "black"))$palette,
                   c(East = "red", South = "blue", West = "black"))
  # Without a group, the data and the palette pass through untouched.
  none <- prepare_group(d, NULL, "red")
  expect_identical(none$data, d)
  expect_identical(none$palette, "red")
})
