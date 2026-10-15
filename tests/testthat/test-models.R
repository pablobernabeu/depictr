test_that("power_curve_plot() accepts a data frame and reads the title", {
  pc <- data.frame(nlevels = c(10, 20, 30), mean = c(0.3, 0.6, 0.85),
                   lower = c(0.2, 0.5, 0.78), upper = c(0.4, 0.7, 0.92))
  p <- power_curve_plot(pc, title = "Power for cond")
  expect_s3_class(p, "ggplot")
  expect_error(power_curve_plot(data.frame(a = 1)), "sample-size")
})

test_that("power_curve_plot() leaves a user title alone but tidies a derived one", {
  # Regression: a user-supplied title was run through format_terms(), so
  # "Power analysis: RT_model" rendered with a multiplication sign in place
  # of the colon and the underscore blanked.
  pc <- data.frame(nlevels = c(10, 20, 30), mean = c(0.3, 0.6, 0.85))
  p <- power_curve_plot(pc, title = "Power analysis: RT_model")
  expect_identical(p$labels$title, "Power analysis: RT_model")

  # A title recovered from the object is a raw term name and is still tidied.
  attr(pc, "title") <- "word_frequency:condition"
  p2 <- power_curve_plot(pc)
  expect_identical(p2$labels$title, "word frequency × condition")
})

# A table shaped like pilotr's power_curve_mixed() output: one row per sample
# size and focal effect, interleaved by sample size as sweep_spec() stacks them,
# with Wilson bounds in power_lo and power_hi. Built by hand, so the test does
# not depend on pilotr.
pilotr_power_table <- function() {
  data.frame(
    n_subject = rep(c(8, 12, 16, 20), each = 2),
    effect = rep(c("cond", "freq"), times = 4),
    power = c(0.30, 0.10, 0.55, 0.20, 0.75, 0.31, 0.88, 0.42),
    power_lo = c(0.19, 0.04, 0.42, 0.11, 0.62, 0.20, 0.77, 0.30),
    power_hi = c(0.44, 0.21, 0.67, 0.33, 0.85, 0.44, 0.94, 0.55)
  )
}

test_that("power_curve_plot() draws one line per pilotr effect, with its band", {
  pc <- pilotr_power_table()
  expect_message(p <- power_curve_plot(pc), "`effect`")
  b <- ggplot2::ggplot_build(p)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")

  line <- b$data[[which(geoms == "GeomLine")]]
  expect_length(unique(line$group), 2)
  expect_length(unique(line$colour), 2)
  expect_length(unique(line$linetype), 2)
  # Each curve rises with n; the old single line alternated between effects.
  for (g in split(line, line$group)) {
    expect_false(is.unsorted(g$y[order(g$x)]))
  }

  ribbon <- b$data[[which(geoms == "GeomRibbon")]]
  expect_setequal(ribbon$ymin, pc$power_lo)
  expect_setequal(ribbon$ymax, pc$power_hi)

  # Naming the column gives the same figure without the message.
  expect_no_message(p2 <- power_curve_plot(pc, group = "effect"))
  expect_identical(p2$labels$colour, "effect")
  expect_identical(p2$labels$linetype, "effect")

  # Error bars in place of the band take each curve's colour.
  p3 <- power_curve_plot(pc, group = "effect", ribbon = FALSE)
  geoms3 <- vapply(p3$layers, function(l) class(l$geom)[1], "")
  bars <- ggplot2::ggplot_build(p3)$data[[which(geoms3 == "GeomErrorbar")]]
  expect_length(unique(bars$colour), 2)
})

test_that("power_curve_plot() no longer joins stacked curves into one line", {
  # Columns the function always recognised, so the old code drew this table
  # as a single line alternating between the two effects.
  pc <- pilotr_power_table()
  names(pc)[names(pc) == "n_subject"] <- "n"
  pc$power_lo <- pc$power_hi <- NULL
  expect_message(p <- power_curve_plot(pc), "`effect`")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  line <- ggplot2::ggplot_build(p)$data[[which(geoms == "GeomLine")]]
  expect_length(unique(line$group), 2)
  for (g in split(line, line$group)) {
    expect_false(is.unsorted(g$y[order(g$x)]))
  }
})

test_that("power_curve_plot() refuses stacked curves it cannot separate", {
  pc <- pilotr_power_table()
  names(pc)[names(pc) == "effect"] <- "focal"
  expect_error(power_curve_plot(pc),
               "Several rows share a sample size; name the column")
  expect_s3_class(power_curve_plot(pc, group = focal), "ggplot")
})

test_that("power_curve_plot() takes column names, bounds and a y label", {
  pc <- data.frame(N = c(10, 20, 30), pw = c(0.3, 0.6, 0.85),
                   lo = c(0.2, 0.5, 0.78), hi = c(0.4, 0.7, 0.92))
  p <- power_curve_plot(pc, n = "N", power = "pw", lower = "lo", upper = hi)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_true("GeomRibbon" %in% geoms)
  expect_identical(p$labels$y, "pw")
  expect_identical(power_curve_plot(pc, n = N, power = pw,
                                    y_lab = "Power")$labels$y, "Power")

  expect_error(power_curve_plot(pc, n = "N", power = "pwr"),
               "Column `pwr` \\(argument `power`\\) not found")
  expect_error(power_curve_plot(pc, n = "N", power = "pw", lower = "lo"),
               "`lower` and `upper`")

  # A recognised power column keeps the axis title "Power".
  expect_identical(power_curve_plot(pilotr_power_table(),
                                    group = "effect")$labels$y, "Power")
})

test_that("power_curve_plot() reads a pilotr precision curve with one effect", {
  # precision_curve() names the effect in `param`; with one level there is one
  # curve, so nothing is grouped and no legend is drawn.
  pc <- data.frame(n_subject = c(15, 30, 60), param = "effect",
                   p_meaningful = c(0.14, 0.29, 0.525),
                   p_meaningful_lo = c(0.10, 0.23, 0.46),
                   p_meaningful_hi = c(0.19, 0.36, 0.59))
  expect_no_message(p <- power_curve_plot(pc, power = "p_meaningful"))
  b <- ggplot2::ggplot_build(p)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_length(unique(b$data[[which(geoms == "GeomLine")]]$group), 1)
  expect_setequal(b$data[[which(geoms == "GeomRibbon")]]$ymin,
                  pc$p_meaningful_lo)
  expect_identical(p$labels$y, "p_meaningful")
})

test_that("power_curve_plot() keeps its positional arguments", {
  pc <- data.frame(nlevels = c(10, 20, 30), mean = c(0.3, 0.6, 0.85))
  p <- power_curve_plot(pc, 0.9)
  b <- ggplot2::ggplot_build(p)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_equal(b$data[[which(geoms == "GeomHline")]]$yintercept, 0.9)
})

# The fields pilotr's target_n() returns for a solved sample size, of which the
# plot reads value, lo and hi. Built by hand, so the test does not depend on
# pilotr.
pilotr_solved <- function() {
  list(value = 120, lo = 104, hi = 139, level = 0.95, target = 0.8,
       x = "n_subject", y = "power", transform = "sqrt",
       n = 120, n_lo = 104, n_hi = 139)
}

test_that("power_curve_plot() marks a solved sample size and its interval", {
  pc <- data.frame(n_subject = c(40, 80, 120, 160, 200),
                   power = c(0.31, 0.62, 0.80, 0.90, 0.95),
                   power_lo = c(0.25, 0.55, 0.74, 0.85, 0.91),
                   power_hi = c(0.38, 0.68, 0.85, 0.93, 0.97))
  p <- power_curve_plot(pc, solved = pilotr_solved())
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  b <- ggplot2::ggplot_build(p)

  vline <- b$data[[which(geoms == "GeomVline")]]
  expect_equal(vline$xintercept, 120)
  expect_equal(vline$colour, depictr_reference())
  band <- b$data[[which(geoms == "GeomRect")]]
  expect_equal(c(band$xmin, band$xmax), c(104, 139))
  expect_equal(band$fill, depictr_reference())
  # The band lies beneath the confidence ribbon and the curve.
  expect_lt(which(geoms == "GeomRect"), which(geoms == "GeomRibbon"))
  expect_lt(which(geoms == "GeomRect"), which(geoms == "GeomLine"))

  # A one-row data frame of the same fields is read alike, and with no
  # `solved` neither layer is drawn.
  p2 <- power_curve_plot(pc, solved = data.frame(value = 120, lo = 104,
                                                 hi = 139))
  geoms2 <- vapply(p2$layers, function(l) class(l$geom)[1], "")
  expect_identical(geoms2, geoms)
  geoms3 <- vapply(power_curve_plot(pc)$layers,
                   function(l) class(l$geom)[1], "")
  expect_false(any(c("GeomVline", "GeomRect") %in% geoms3))

  # An interval that reaches past the swept sizes widens the axis to show it.
  wide <- ggplot2::ggplot_build(power_curve_plot(
    pc, solved = list(value = 190, lo = 150, hi = 260)
  ))
  x_range <- wide$layout$panel_params[[1]]$x.range
  expect_lte(x_range[1], 40)
  expect_gte(x_range[2], 260)
})

test_that("power_curve_plot() refuses a `solved` it cannot read", {
  pc <- data.frame(n = c(40, 80, 120), power = c(0.31, 0.62, 0.80))
  msg <- "`solved` needs numeric `value`, `lo` and `hi`, as pilotr's target_n() returns."
  expect_error(power_curve_plot(pc, solved = 120), msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = c(value = 120, lo = 104,
                                               hi = 139)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = list(value = 120, lo = 104)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = list(value = "120", lo = 104,
                                                  hi = 139)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = list(value = NA_real_, lo = 104,
                                                  hi = 139)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = list(value = TRUE, lo = 104,
                                                  hi = 139)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = list(value = c(120, 130),
                                                  lo = 104, hi = 139)),
               msg, fixed = TRUE)
  expect_error(power_curve_plot(pc, solved = data.frame(value = c(120, 130),
                                                        lo = 104, hi = 139)),
               msg, fixed = TRUE)
})

test_that("power_curve_plot() draws one line without a legend for a one-level effect", {
  # pilotr's power_curve_mixed() names the focal effect even when there is only
  # one, and a column with one level separates nothing.
  pc <- pilotr_power_table()
  pc <- pc[pc$effect == "cond", ]
  expect_no_message(p <- power_curve_plot(pc))
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  line <- ggplot2::ggplot_build(p)$data[[which(geoms == "GeomLine")]]
  expect_length(unique(line$group), 1)
  expect_null(p$mapping$colour)
  expect_null(p$mapping$linetype)
  expect_false(any(c("colour", "linetype") %in% names(p$labels)))
})

test_that("optimizer_fixef_plot() works from a data frame", {
  df <- expand.grid(optimizer = c("bobyqa", "Nelder_Mead"),
                    term = c("(Intercept)", "x1"))
  df$value <- c(5, 5.1, 0.2, 0.19)
  p <- optimizer_fixef_plot(df)
  expect_s3_class(p, "ggplot")

  # Dropping the intercept leaves the slope panels
  p2 <- optimizer_fixef_plot(df, intercept = FALSE)
  expect_false(any(grepl("Intercept", as.character(p2$data$panel))))
  expect_error(optimizer_fixef_plot(data.frame(a = 1)), "optimiser")
})

test_that("residual_diagnostics_plot() returns a patchwork", {
  fit <- lm(yield ~ rainfall + fertiliser, data = crop_yield)
  p <- residual_diagnostics_plot(fit)
  expect_s3_class(p, "patchwork")
  p2 <- residual_diagnostics_plot(fit, which = c("resid_fitted", "qq"))
  expect_s3_class(p2, "patchwork")
  expect_error(residual_diagnostics_plot("not a model"), "lm")
})
