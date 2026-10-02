# check_figure(): the accessibility and honesty audit -------------------------

library(ggplot2)

# Two reference figures with known answers. The good one is separable under
# every deficiency and in greyscale, contrasts well against white, keeps its
# text at the size it was drawn and adds a redundant shape. The bad one uses a
# red and a green that collapse to the same colour under deuteranopia, shrinks
# its text far below any print floor and leaves colour to do all the work.
good_figure <- function(...) {
  ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
                         shape = treatment)) +
    geom_point() +
    scale_colour_manual(values = c("#005b96", "#d55e00")) +
    theme_depictr(...)
}

bad_figure <- function() {
  ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
    geom_point() +
    scale_colour_manual(values = c("#d62728", "#309208")) +
    theme_depictr(base_size = 5)
}

measured_for <- function(report, check) {
  report$measured[report$check == check]
}

verdict_for <- function(report, check) {
  report$verdict[report$check == check]
}

detail_for <- function(report, check) {
  report$detail[report$check == check]
}

# The WCAG 2.2 contrast ratio recomputed from the published definition alone,
# independently of the package code: linearise each sRGB channel at the 0.04045
# breakpoint, weight the channels, then (L1 + 0.05) / (L2 + 0.05).
wcag <- function(a, b) {
  lum <- function(hex) {
    channel <- as.numeric(grDevices::col2rgb(hex)) / 255
    lin <- ifelse(channel <= 0.04045, channel / 12.92,
                  ((channel + 0.055) / 1.055)^2.4)
    sum(lin * c(0.2126, 0.7152, 0.0722))
  }
  la <- lum(a); lb <- lum(b)
  (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
}

# --- shape of the result -----------------------------------------------------

test_that("check_figure() returns the standard table shape", {
  report <- check_figure(good_figure())
  expect_s3_class(report, "data.frame")
  expect_identical(names(report),
                   c("check", "measured", "threshold", "verdict", "detail"))
  expect_identical(report$check, c(
    "colour_separability", "colour_separability_protan",
    "colour_separability_deutan", "colour_separability_tritan",
    "greyscale_separability", "text_size", "text_contrast",
    "geometry_contrast", "redundant_encoding"))
  expect_type(report$measured, "double")
  expect_type(report$threshold, "double")
  expect_true(all(report$verdict %in% c("pass", "fail", "not applicable")))
  expect_true(all(nzchar(report$detail)))
  expect_identical(rownames(report), as.character(seq_len(nrow(report))))
})

# --- the two verdicts the audit must be capable of ---------------------------

test_that("a deliberately good figure passes every check", {
  report <- check_figure(good_figure())
  expect_true(all(report$verdict == "pass"),
              info = paste(report$check[report$verdict != "pass"],
                           collapse = ", "))
})

test_that("a deliberately bad figure fails the checks it should, and only those", {
  report <- check_figure(bad_figure())
  # Red against green: fine to a normal-sighted reader, gone under deuteranopia.
  expect_identical(verdict_for(report, "colour_separability"), "pass")
  expect_identical(verdict_for(report, "colour_separability_deutan"), "fail")
  expect_lt(measured_for(report, "colour_separability_deutan"), 1)
  expect_gt(measured_for(report, "colour_separability"), 100)
  # Base size 5 puts the axis text at 4 pt, well under the 6 pt floor.
  expect_identical(verdict_for(report, "text_size"), "fail")
  expect_equal(measured_for(report, "text_size"), 4)
  # Nothing but colour separates the two groups.
  expect_identical(verdict_for(report, "redundant_encoding"), "fail")
  expect_equal(measured_for(report, "redundant_encoding"), 0)
  # The rest of the figure is fine, so the audit is not simply failing it.
  expect_identical(verdict_for(report, "text_contrast"), "pass")
  expect_identical(verdict_for(report, "geometry_contrast"), "pass")
})

test_that("the audit reports the numbers its Python twin reports", {
  # Pinned so the two engines cannot drift apart unnoticed. Each figure below is
  # constructible in both, and the Python suite pins the same three vectors.
  expect_equal(check_figure(good_figure())$measured,
               c(111.87, 89.87, 107.07, 98.5, 16.92, 8.8, 8.45, 3.87, 1))
  expect_equal(check_figure(bad_figure())$measured,
               c(116.25, 35.04, 0.37, 119.38, 6.32, 4, 8.45, 4.01, 0))

  eight <- data.frame(g = factor(letters[1:8]), x = 1:8, y = 1:8)
  p <- ggplot(eight, aes(x, y, colour = g)) + geom_point() +
    scale_colour_depictr() + theme_depictr()
  report <- check_figure(p)
  expect_equal(report$measured,
               c(33.43, 18.15, 7.4, 16.18, 0.79, 8.8, 8.45, 1.32, 0))
  # The detail strings are part of the contract too, since they carry the
  # colours the numbers came from.
  expect_identical(report$detail[1:5], c(
    "Closest pair #d55e00 and #e69f00 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #009e73 and #56b4e9 of 8 encoding colours.",
    "Closest pair #56b4e9 and #e69f00 in CIE lightness."))
  expect_identical(report$detail[6:9], c(
    "Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.",
    "Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.",
    "Lowest-contrast colour #f0e442 on #ffffff.",
    "Colour alone distinguishes the groups."))

  # A dark plot background behind a blank panel: the geometry is measured
  # against the plot background in both twins. The Python twin used to read the
  # invisible axes patch here, which is white, and passed the figure at 3.87.
  dark <- check_figure(good_figure() +
    theme(plot.background = ggplot2::element_rect(fill = "#333333")))
  expect_equal(dark$measured,
               c(111.87, 89.87, 107.07, 98.5, 16.92, 8.8, 1.49, 1.77, 1))
  expect_identical(dark$detail[dark$check == "geometry_contrast"],
                   "Lowest-contrast colour #005b96 on #333333.")
})

# --- the measurements themselves ---------------------------------------------

test_that("colour separability is the palette check restricted to the figure", {
  # The figure's two colours are what palette_safety() would report on them, so
  # the two exports cannot drift apart.
  report <- check_figure(good_figure())
  pair <- c("#005b96", "#d55e00")
  reference <- palette_safety(pair)
  expect_equal(measured_for(report, "colour_separability"),
               reference$by_condition[["normal"]])
  for (tp in c("protan", "deutan", "tritan")) {
    expect_equal(measured_for(report, paste0("colour_separability_", tp)),
                 reference$by_condition[[tp]])
  }
})

test_that("greyscale separability is the lightness gap, and the default palette fails it", {
  eight <- data.frame(g = factor(letters[1:8]), x = 1:8, y = 1:8)
  p <- ggplot(eight, aes(x, y, colour = g)) + geom_point() +
    scale_colour_depictr() + theme_depictr()
  report <- check_figure(p)
  # Measured independently: the orange and the sky blue of the Okabe-Ito set sit
  # 0.79 apart in CIE lightness, so they print as the same grey. The threshold
  # stays where it is and the documentation carries the limitation.
  lightness <- .srgb_to_lab(c("#e69f00", "#56b4e9"))[, "L"]
  expect_equal(measured_for(report, "greyscale_separability"),
               round(abs(diff(lightness)), 2))
  expect_equal(measured_for(report, "greyscale_separability"), 0.79)
  expect_identical(verdict_for(report, "greyscale_separability"), "fail")
  # The same eight colours clear every colour-vision check, which is the point:
  # the guarantee is about hue confusion, not about black-and-white printing.
  for (tp in c("colour_separability", "colour_separability_protan",
               "colour_separability_deutan", "colour_separability_tritan")) {
    expect_identical(verdict_for(report, tp), "pass")
  }
})

test_that("text size scales with the printed width", {
  p <- good_figure()
  full <- measured_for(check_figure(p), "text_size")
  half <- measured_for(check_figure(p, width_cm = 8.89), "text_size")
  expect_equal(full, 8.8)
  expect_equal(half, round(full / 2, 2))
  expect_identical(verdict_for(check_figure(p, width_cm = 8.89), "text_size"),
                   "fail")
  # Drawing narrower in the first place is the other half of the ratio.
  expect_equal(measured_for(check_figure(p, width_cm = 8.89,
                                         render_width_cm = 8.89), "text_size"),
               full)
})

test_that("contrast ratios match the WCAG definition computed independently", {
  # Black on white is the textbook 21:1 anchor.
  expect_equal(round(wcag("#000000", "#ffffff"), 2), 21)

  report <- check_figure(good_figure())
  # theme_depictr() draws the axis text in grey30 on a white plot background,
  # and the vermillion is the lower-contrast of the two encoding colours.
  expect_equal(measured_for(report, "text_contrast"),
               round(wcag("#4d4d4d", "#ffffff"), 2))
  expect_equal(measured_for(report, "geometry_contrast"),
               round(wcag("#d55e00", "#ffffff"), 2))

  # The two ratios are measured against different backgrounds, so a theme that
  # repaints them has to move both. The Python twin read the drawing surface
  # rather than the theme here and kept reporting text against white.
  repainted <- check_figure(good_figure() +
    theme(panel.background = ggplot2::element_rect(fill = "#333333"),
          plot.background = ggplot2::element_rect(fill = "#eeeeee")))
  expect_equal(measured_for(repainted, "text_contrast"),
               round(wcag("#4d4d4d", "#eeeeee"), 2))
  expect_equal(measured_for(repainted, "geometry_contrast"),
               round(wcag("#005b96", "#333333"), 2))
  expect_identical(repainted$detail[repainted$check == "text_contrast"],
                   "Lowest-contrast text #4d4d4d on #eeeeee at 8.80 pt.")
  # A blank plot background paints nothing, so white stands in for the paper.
  blanked <- check_figure(good_figure() +
    theme(plot.background = ggplot2::element_blank()))
  expect_equal(measured_for(blanked, "text_contrast"),
               round(wcag("#4d4d4d", "#ffffff"), 2))
})

# --- each text against its own background ------------------------------------

# A facetted figure with dark strips. The strip text size is set explicitly
# because the twins' default strip sizes differ.
strip_figure <- function(text_colour, strip_fill = "#1a1a1a") {
  good_figure() + facet_wrap(~treatment) +
    theme(strip.background = ggplot2::element_rect(fill = strip_fill),
          strip.text = ggplot2::element_text(colour = text_colour, size = 8.8))
}

test_that("strip text is measured against the strip it is drawn on", {
  # White on a near-black strip reads at 17.4:1. Measured against the white plot
  # background it used to read 1.00 and fail.
  light <- check_figure(strip_figure("white"))
  expect_equal(measured_for(light, "text_contrast"), 8.45)
  expect_identical(verdict_for(light, "text_contrast"), "pass")
  expect_identical(detail_for(light, "text_contrast"),
                   "Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.")
  # Dark grey on the same strip is unreadable. It used to pass at 8.45, the
  # value of the axis text, because it was measured against white.
  dark <- check_figure(strip_figure("#333333"))
  expect_equal(measured_for(dark, "text_contrast"), 1.38)
  expect_equal(measured_for(dark, "text_contrast"),
               round(wcag("#333333", "#1a1a1a"), 2))
  expect_identical(verdict_for(dark, "text_contrast"), "fail")
  expect_identical(detail_for(dark, "text_contrast"),
                   "Lowest-contrast text #333333 on #1a1a1a at 8.80 pt.")
  # A translucent strip is composited over the plot background before the text
  # is measured against it: black at alpha 128/255 over white is #7f7f7f.
  veiled <- check_figure(strip_figure("white", strip_fill = "#00000080"))
  expect_equal(measured_for(veiled, "text_contrast"),
               round(wcag("#ffffff", "#7f7f7f"), 2))
  expect_identical(detail_for(veiled, "text_contrast"),
                   "Lowest-contrast text #ffffff on #7f7f7f at 8.80 pt.")
})

test_that("legend text is measured against the legend box", {
  boxed <- function(text_colour) {
    good_figure() +
      theme(legend.background = ggplot2::element_rect(fill = "#222222"),
            legend.text = ggplot2::element_text(colour = text_colour),
            legend.title = ggplot2::element_text(colour = "white"))
  }
  light <- check_figure(boxed("white"))
  expect_identical(verdict_for(light, "text_contrast"), "pass")
  expect_equal(measured_for(light, "text_contrast"), 8.45)
  dark <- check_figure(boxed("#333333"))
  expect_equal(measured_for(dark, "text_contrast"),
               round(wcag("#333333", "#222222"), 2))
  expect_identical(detail_for(dark, "text_contrast"),
                   "Lowest-contrast text #333333 on #222222 at 8.80 pt.")
  # The box around all the legends paints beneath them when each legend's own
  # background is blank. plotnine does not draw that box, so the Python twin
  # measures the same theme against the plot background and fails it.
  outer <- check_figure(good_figure() +
    theme(legend.box.background = ggplot2::element_rect(fill = "#222222"),
          legend.background = ggplot2::element_blank(),
          legend.text = ggplot2::element_text(colour = "white"),
          legend.title = ggplot2::element_text(colour = "white")))
  expect_identical(verdict_for(outer, "text_contrast"), "pass")
  expect_equal(measured_for(outer, "text_contrast"), 8.45)
})

test_that("a translucent background is measured as the colour it shows", {
  # Blue at alpha 64/255 over the white plot background shows as #bfbfff. Its
  # alpha used to be dropped, so the panel was measured as opaque blue.
  report <- check_figure(good_figure() +
    theme(panel.background = ggplot2::element_rect(fill = "#0000ff40")))
  expect_equal(measured_for(report, "geometry_contrast"),
               round(wcag("#d55e00", "#bfbfff"), 2))
  expect_identical(detail_for(report, "geometry_contrast"),
                   "Lowest-contrast colour #d55e00 on #bfbfff.")
})

test_that("stock dark-theme facets pass the text check", {
  # theme_dark() draws light strip text on a dark strip. Measured against the
  # white plot background, it used to fail at 1.26.
  report <- check_figure(good_figure() + facet_wrap(~treatment) +
                           theme_dark())
  expect_identical(verdict_for(report, "text_contrast"), "pass")
})

test_that("large text is held to 3:1, judged at its printed size", {
  titled <- function(...) {
    good_figure() + labs(title = "A title") +
      theme(plot.title = ggplot2::element_text(colour = "#8c8c8c", ...))
  }
  # #8c8c8c on white is 3.36:1, short of 4.5 and clear of the 3 that WCAG 2.2
  # asks of text at 18 pt or more.
  large <- check_figure(titled(size = 20, face = "plain"))
  expect_equal(measured_for(large, "text_contrast"), 3.36)
  expect_equal(large$threshold[large$check == "text_contrast"], 3)
  expect_identical(verdict_for(large, "text_contrast"), "pass")
  expect_identical(detail_for(large, "text_contrast"),
                   "Lowest-contrast text #8c8c8c on #ffffff at 20.00 pt.")
  # Bold text counts as large from 14 pt.
  bold <- check_figure(titled(size = 14, face = "bold"))
  expect_equal(bold$threshold[bold$check == "text_contrast"], 3)
  expect_identical(verdict_for(bold, "text_contrast"), "pass")
  expect_identical(detail_for(bold, "text_contrast"),
                   "Lowest-contrast text #8c8c8c on #ffffff at 14.00 pt bold.")
  # The same plain title is not large at 14 pt, so it fails at 4.5.
  plain <- check_figure(titled(size = 14, face = "plain"))
  expect_equal(plain$threshold[plain$check == "text_contrast"], 4.5)
  expect_identical(verdict_for(plain, "text_contrast"), "fail")
  # Size is judged as printed: the 20 pt title in a half-width column prints at
  # 10 pt, which is normal-sized text again.
  shrunk <- check_figure(titled(size = 20, face = "plain"), width_cm = 8.89)
  expect_equal(shrunk$threshold[shrunk$check == "text_contrast"], 4.5)
  expect_identical(verdict_for(shrunk, "text_contrast"), "fail")
  expect_identical(detail_for(shrunk, "text_contrast"),
                   "Lowest-contrast text #8c8c8c on #ffffff at 10.00 pt.")
})

test_that("relative luminance follows the current WCAG 2.2 definition", {
  # The definition's breakpoint is 0.04045. It read 0.03928 before May 2021,
  # and no 8-bit channel value lies between the two, so no ratio moves.
  channels <- (0:255) / 255
  hex <- grDevices::rgb(channels, channels, channels)
  old <- ifelse(channels <= 0.03928, channels / 12.92,
                ((channels + 0.055) / 1.055)^2.4)
  expect_equal(.relative_luminance(hex), old)
  expect_equal(.relative_luminance(hex), .srgb_to_linear(channels))
})

test_that("redundant encoding counts the channels that vary alongside colour", {
  colour_only <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
    geom_point() + scale_colour_depictr() + theme_depictr()
  expect_equal(measured_for(check_figure(colour_only), "redundant_encoding"), 0)

  both <- ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
                                 shape = treatment, linetype = treatment)) +
    geom_line() + geom_point() + scale_colour_depictr() + theme_depictr()
  report <- check_figure(both)
  expect_equal(measured_for(report, "redundant_encoding"), 2)
  expect_identical(report$detail[report$check == "redundant_encoding"],
                   "Colour is joined by shape and linetype.")
})

# --- what the audit declines to measure --------------------------------------

test_that("a continuous colour scale is not treated as a set of category codes", {
  # A gradient's neighbouring colours are meant to be close, so measuring the
  # distance between them would only ever report that a gradient is a gradient.
  report <- check_figure(correlation_heatmap(wellbeing_survey))
  for (check in c("colour_separability", "greyscale_separability",
                  "geometry_contrast", "redundant_encoding")) {
    expect_identical(verdict_for(report, check), "not applicable")
    expect_true(is.na(measured_for(report, check)))
  }
  # The heatmap's cell labels are a text layer, so they neither count as
  # encoding colours nor drag the text-size measurement down to their own size.
  expect_equal(measured_for(report, "text_size"), 8.8)
})

test_that("a figure with no colour encoding abstains rather than passing", {
  p <- ggplot(crop_yield, aes(rainfall, yield)) + geom_point() + theme_depictr()
  report <- check_figure(p)
  colour_checks <- c("colour_separability", "colour_separability_protan",
                     "colour_separability_deutan", "colour_separability_tritan",
                     "greyscale_separability", "geometry_contrast",
                     "redundant_encoding")
  expect_true(all(report$verdict[report$check %in% colour_checks] ==
                    "not applicable"))
  expect_true(all(is.na(report$measured[report$check %in% colour_checks])))
  expect_identical(
    unique(report$detail[report$check %in% colour_checks]),
    "No two encoding colours: nothing is distinguished by colour.")
  # Text is still there to measure.
  expect_identical(verdict_for(report, "text_size"), "pass")
})

test_that("a figure that draws no text says so rather than reporting a size", {
  p <- ggplot(crop_yield, aes(rainfall, yield)) + geom_point() +
    theme_void() + theme(legend.position = "none")
  report <- check_figure(p)
  expect_identical(verdict_for(report, "text_size"), "not applicable")
  expect_identical(verdict_for(report, "text_contrast"), "not applicable")
  expect_identical(report$detail[report$check == "text_size"],
                   "The figure draws no text.")
})

# --- degenerate inputs -------------------------------------------------------

test_that("a single row and a zero-variance grouping still audit", {
  one <- crop_yield[1, , drop = FALSE]
  report <- check_figure(ggplot(one, aes(rainfall, yield)) + geom_point() +
                           theme_depictr())
  expect_identical(nrow(report), 9L)
  expect_identical(verdict_for(report, "colour_separability"), "not applicable")

  # One group means one colour, which is not a pair, so the colour checks
  # abstain rather than declaring a lone colour infinitely safe.
  constant <- crop_yield
  constant$treatment <- factor("standard")
  report <- check_figure(ggplot(constant, aes(rainfall, yield,
                                              colour = treatment)) +
                           geom_point() + scale_colour_depictr() +
                           theme_depictr())
  expect_identical(verdict_for(report, "colour_separability"), "not applicable")
  expect_identical(verdict_for(report, "geometry_contrast"), "not applicable")
})

test_that("an empty plot audits without error", {
  report <- check_figure(ggplot() + theme_depictr())
  expect_identical(nrow(report), 9L)
})

test_that("a measurement exactly on the threshold passes", {
  # The boundary is inclusive: a check passes when measured >= threshold.
  p <- good_figure()
  measured <- measured_for(check_figure(p), "text_size")
  expect_identical(verdict_for(check_figure(p, min_text_pt = measured),
                               "text_size"), "pass")
  expect_identical(
    verdict_for(check_figure(p, min_text_pt = measured + 0.01), "text_size"),
    "fail")
})

# --- refusals ----------------------------------------------------------------

test_that("check_figure() refuses what it cannot audit", {
  expect_error(check_figure(1),
               paste0("^`plot` must be a plot object, as returned by any ",
                      "depictr plotting function\\.$"))
  expect_error(check_figure("a plot"),
               paste0("^`plot` must be a plot object, as returned by any ",
                      "depictr plotting function\\.$"))
  # A composite inherits from ggplot, so it would otherwise reach the build and
  # fail obscurely; each panel has its own scales, theme and text anyway.
  composite <- arrange_plots(ggplot() + theme_depictr(),
                             ggplot() + theme_depictr())
  expect_error(check_figure(composite),
               paste0("^`plot` is a multi-panel composite\\. Check each panel ",
                      "on its own\\.$"))
})

test_that("check_figure() refuses non-positive and non-scalar settings", {
  p <- good_figure()
  for (arg in c("width_cm", "render_width_cm", "min_delta_e", "min_text_pt")) {
    pattern <- paste0("^`", arg, "` must be a single positive number\\.$")
    expect_error(do.call(check_figure, c(list(p), stats::setNames(list(0), arg))),
                 pattern)
    expect_error(do.call(check_figure, c(list(p), stats::setNames(list(-1), arg))),
                 pattern)
    expect_error(do.call(check_figure,
                         c(list(p), stats::setNames(list(c(1, 2)), arg))),
                 pattern)
    expect_error(do.call(check_figure,
                         c(list(p), stats::setNames(list("wide"), arg))),
                 pattern)
    expect_error(do.call(check_figure,
                         c(list(p), stats::setNames(list(NA_real_), arg))),
                 pattern)
  }
})

# --- the audit sees what the user added --------------------------------------

test_that("check_figure() reads the extended plot, not the one depictr returned", {
  # The whole point of introspecting the build: a user's replacement scale is
  # what the figure ships with, so it is what gets audited.
  base <- explore_distribution(lexical_decision, RT, group = condition)
  expect_identical(verdict_for(check_figure(base), "colour_separability"),
                   "pass")
  # Replacing a scale that is already there is the ordinary way a user overrides
  # depictr's colours, and ggplot2 says so every time; the message is not the
  # subject of this test.
  broken <- suppressMessages(
    base + scale_fill_manual(values = c("#d62728", "#309208")) +
      scale_colour_manual(values = c("#d62728", "#309208")))
  expect_identical(
    verdict_for(check_figure(broken), "colour_separability_deutan"), "fail")
})

test_that("check_figure() leaves the plot it was given untouched", {
  p <- good_figure()
  before <- ggplot2::ggplot_build(p)$data
  check_figure(p)
  expect_equal(ggplot2::ggplot_build(p)$data, before)
})

# --- the declared ggplot2 floor ----------------------------------------------

test_that("the pre-4.0.0 theme completion resolves what complete_theme() does", {
  # check_figure() calls ggplot2::complete_theme() where ggplot2 has it and
  # assembles the equivalent from the exported API below 4.0.0. Only the
  # declared-minimum-dependencies job installs a ggplot2 that takes the second
  # branch, so left to itself the compatibility path is exercised in one job
  # rather than across the matrix. Comparing the two wherever both exist is what
  # stops them drifting apart in between.
  complete_theme <- .ggplot2_export("complete_theme")
  skip_if(is.null(complete_theme),
          "This ggplot2 has no complete_theme() to compare against.")
  # A complete theme, an empty one, a lone element added to the default, and a
  # complete theme that paints nothing: the four shapes the completion has to
  # tell apart.
  plots <- list(
    good_figure(),
    ggplot(crop_yield, aes(rainfall, yield)) + geom_point(),
    ggplot(crop_yield, aes(rainfall, yield)) + geom_point() +
      theme(plot.background = ggplot2::element_rect(fill = "#eeeeee")),
    ggplot(crop_yield, aes(rainfall, yield)) + geom_point() + theme_void()
  )
  for (p in plots) {
    theme <- ggplot2::ggplot_build(p)$plot$theme
    for (element in c("plot.background", "panel.background", "text")) {
      expect_equal(
        ggplot2::calc_element(element, .completed_theme_compat(theme)),
        ggplot2::calc_element(element, complete_theme(theme)))
    }
  }
})
