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

# A colour as it shows over a background at a given alpha, recomputed by hand:
# each channel in [0, 1] is alpha * colour + (1 - alpha) * background, then
# floor(255 * x + 0.5) gives the 8-bit value.
mix <- function(colour, background, alpha) {
  fg <- as.numeric(grDevices::col2rgb(colour)) / 255
  bg <- as.numeric(grDevices::col2rgb(background)) / 255
  channels <- floor(255 * (alpha * fg + (1 - alpha) * bg) + 0.5)
  tolower(grDevices::rgb(channels[1], channels[2], channels[3],
                         maxColorValue = 255))
}

# Translucent versions of the good figure's colours, built the same way in both
# twins. `alpha = NULL` leaves the layer's alpha unset.
bars_figure <- function(alpha, values = c("#005b96", "#d55e00")) {
  two <- data.frame(g = c("a", "b"), y = c(1, 2))
  bars <- if (is.null(alpha)) geom_col() else geom_col(alpha = alpha)
  ggplot(two, aes(g, y, fill = g)) + bars +
    scale_fill_manual(values = values) +
    theme_depictr()
}

points_figure <- function(alpha) {
  ggplot(crop_yield, aes(rainfall, yield, colour = treatment,
                         shape = treatment)) +
    geom_point(alpha = alpha) +
    scale_colour_manual(values = c("#005b96", "#d55e00")) +
    theme_depictr()
}

# Densities whose fill is translucent and whose outline, mapped to the same
# groups, is drawn opaque.
density_figure <- function(alpha = 0.2) {
  ggplot(crop_yield, aes(yield, colour = treatment, fill = treatment)) +
    geom_density(alpha = alpha) +
    scale_colour_manual(values = c("#005b96", "#d55e00")) +
    scale_fill_manual(values = c("#005b96", "#d55e00")) +
    theme_depictr()
}

# The bad figure's red and green, drawn one group per layer. Each layer maps
# colour to a constant, so neither varies in colour on its own.
standard <- crop_yield[crop_yield$treatment == "standard", ]
enhanced <- crop_yield[crop_yield$treatment == "enhanced", ]

split_figure <- function() {
  ggplot(mapping = aes(rainfall, yield)) +
    geom_point(data = standard, aes(colour = "a")) +
    geom_point(data = enhanced, aes(colour = "b")) +
    scale_colour_manual(values = c("#d62728", "#309208")) +
    theme_depictr()
}

# Points coloured by a continuous variable, on the default gradient.
gradient_figure <- function() {
  ggplot(crop_yield, aes(rainfall, yield, colour = yield)) +
    geom_point() +
    theme_depictr()
}

# The rows that depend on what a figure tells apart by colour, which is every
# row but the three text rows.
encoding_rows <- function(report) {
  report[!report$check %in% c("text_size", "text_contrast",
                              "annotation_text_size"), ]
}

# The good figure with a note drawn inside the panel at 5.7 pt. ggplot2 sizes a
# layer's text in millimetres, so the size is given as 5.7 pt over .pt. The
# Python suite draws the same note at size 5.7, which plotnine takes as points.
annotated_figure <- function(size = 5.7 / ggplot2::.pt) {
  good_figure() +
    annotate("text", x = 800, y = 5, label = "note", size = size)
}

# Every colour row, which abstains with one shared detail when nothing
# discrete encodes.
colour_checks <- c("colour_separability", "colour_separability_protan",
                   "colour_separability_deutan", "colour_separability_tritan",
                   "greyscale_separability", "geometry_contrast",
                   "redundant_encoding")

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
    "geometry_contrast", "redundant_encoding", "annotation_text_size"))
  expect_identical(nrow(report), 10L)
  expect_type(report$measured, "double")
  expect_type(report$threshold, "double")
  expect_true(all(report$verdict %in% c("pass", "fail", "not applicable")))
  expect_true(all(nzchar(report$detail)))
  expect_identical(rownames(report), as.character(seq_len(nrow(report))))
})

# --- the two verdicts the audit must be capable of ---------------------------

test_that("a deliberately good figure passes every check that applies", {
  report <- check_figure(good_figure())
  # It draws no text inside the panel, so that row has nothing to measure.
  measured <- report[report$check != "annotation_text_size", ]
  expect_true(all(measured$verdict == "pass"),
              info = paste(measured$check[measured$verdict != "pass"],
                           collapse = ", "))
  expect_identical(verdict_for(report, "annotation_text_size"),
                   "not applicable")
})

test_that("a deliberately bad figure fails the checks it should, and only those", {
  report <- check_figure(bad_figure())
  # Red against green: fine to a normal-sighted reader, gone under deuteranopia.
  expect_identical(verdict_for(report, "colour_separability"), "pass")
  expect_identical(verdict_for(report, "colour_separability_deutan"), "fail")
  expect_lt(measured_for(report, "colour_separability_deutan"), 1)
  expect_gt(measured_for(report, "colour_separability"), 50)
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
  # constructible in both, and the Python suite pins the same vectors. None of
  # them draws text inside the panel, so each ends in NA.
  expect_equal(check_figure(good_figure())$measured,
               c(50.12, 49.67, 58.3, 61.99, 16.92, 8.8, 8.45, 3.87, 1, NA))
  expect_equal(check_figure(bad_figure())$measured,
               c(69.59, 20.06, 0.11, 62.7, 6.32, 4, 8.45, 4.01, 0, NA))

  eight <- data.frame(g = factor(letters[1:8]), x = 1:8, y = 1:8)
  p <- ggplot(eight, aes(x, y, colour = g)) + geom_point() +
    scale_colour_depictr() + theme_depictr()
  report <- check_figure(p)
  expect_equal(report$measured,
               c(21.25, 13.44, 6.43, 11.13, 0.79, 8.8, 8.45, 1.32, 0, NA))
  # The detail strings are part of the contract too, since they carry the
  # colours the numbers came from.
  expect_identical(report$detail[1:5], c(
    "Closest pair #56b4e9 and #999999 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #cc79a7 and #e69f00 of 8 encoding colours.",
    "Closest pair #56b4e9 and #e69f00 in CIE lightness."))
  expect_identical(report$detail[6:10], c(
    "Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.",
    "Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.",
    "Lowest-contrast colour #f0e442 on #ffffff.",
    "Colour alone distinguishes the groups.",
    "The figure draws no text inside the panel."))

  # A note drawn inside the panel at 5.7 pt, below the 6 pt floor. The text-size
  # check never saw it, so the report used to read 8.80 pt as the smallest text.
  annotated <- check_figure(annotated_figure())
  expect_equal(annotated$measured,
               c(50.12, 49.67, 58.3, 61.99, 16.92, 8.8, 8.45, 3.87, 1, 5.7))
  expect_identical(annotated$detail[c(6, 10)], c(
    "Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.",
    "Smallest in-panel text 5.70 pt, drawn at 17.78 cm and printed at 17.78 cm."))

  # A dark plot background behind a blank panel: the geometry is measured
  # against the plot background in both twins. The Python twin used to read the
  # invisible axes patch here, which is white, and passed the figure at 3.87.
  dark <- check_figure(good_figure() +
    theme(plot.background = ggplot2::element_rect(fill = "#333333")))
  expect_equal(dark$measured,
               c(50.12, 49.67, 58.3, 61.99, 16.92, 8.8, 1.49, 1.77, 1, NA))
  expect_identical(dark$detail[dark$check == "geometry_contrast"],
                   "Lowest-contrast colour #005b96 on #333333.")

  # Translucent bars, measured as drawn: #005b96 and #d55e00 at alpha 0.3 show
  # as #b3cee0 and #f2cfb3. Read at full opacity, the figure passed geometry at
  # 3.87 and greyscale at 16.92.
  bars <- check_figure(bars_figure(alpha = 0.3))
  expect_equal(bars$measured,
               c(26.57, 22.54, 25.84, 35.95, 4.03, 8.8, 8.45, 1.46, 0, NA))
  expect_identical(bars$detail, c(
    rep("Closest pair #b3cee0 and #f2cfb3 of 2 encoding fill colours.", 4),
    "Closest pair #b3cee0 and #f2cfb3 in CIE lightness.",
    "Smallest text 8.80 pt, drawn at 17.78 cm and printed at 17.78 cm.",
    "Lowest-contrast text #4d4d4d on #ffffff at 8.80 pt.",
    paste("Lowest-contrast colour #d55e00 at alpha 0.30, drawn as #f2cfb3,",
          "on #ffffff."),
    "Colour alone distinguishes the groups.",
    "The figure draws no text inside the panel."))

  # The good figure's points at alpha 0.7, which the Get started vignette used
  # to show as mended. Its vermillion is drawn as #e28e4d, at 2.56:1.
  points <- check_figure(points_figure(alpha = 0.7))
  expect_equal(points$measured,
               c(43.96, 42.02, 47.69, 53.52, 10.77, 8.8, 8.45, 2.56, 1, NA))
  expect_identical(detail_for(points, "geometry_contrast"), paste(
    "Lowest-contrast colour #d55e00 at alpha 0.70, drawn as #e28e4d,",
    "on #ffffff."))

  # The bad figure's red and green with one group per layer, each layer mapping
  # colour to a constant. Every colour row used to read "not applicable".
  split <- check_figure(split_figure())
  expect_equal(split$measured,
               c(69.59, 20.06, 0.11, 62.7, 6.32, 8.8, 8.45, 4.01, 0, NA))
  expect_identical(split$detail[c(1:5, 8)], c(
    rep("Closest pair #309208 and #d62728 of 2 encoding colours.", 4),
    "Closest pair #309208 and #d62728 in CIE lightness.",
    "Lowest-contrast colour #309208 on #ffffff."))

  # A scatter coloured by a continuous variable. Every colour row abstains and
  # says why, where it used to say that nothing is distinguished by colour.
  gradient <- check_figure(gradient_figure())
  expect_equal(gradient$measured,
               c(NA, NA, NA, NA, NA, 8.8, 8.45, NA, NA, NA))
  expect_identical(unique(gradient$detail[gradient$check %in% colour_checks]),
                   "Colour is a continuous scale, which these checks do not audit.")
})

test_that("a figure in ggplot2's five colours fails the deuteranopia row", {
  # ggplot2's default colours for five groups, scales::hue_pal()(5). Under
  # deuteranopia the sky blue and the pink come 2.74 apart in CIEDE2000. The
  # 1976 distance put them 7.35 apart, and every colour row passed. The
  # Python suite pins the same rows.
  hue5 <- c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3")
  five <- data.frame(g = factor(letters[1:5]), x = 1:5, y = 1:5)
  p <- ggplot(five, aes(x, y, colour = g)) + geom_point() +
    scale_colour_manual(values = hue5) + theme_depictr()
  report <- check_figure(p)
  expect_equal(report$measured[1:4], c(26.71, 9.37, 2.74, 7.91))
  expect_identical(report$verdict[1:4], c("pass", "pass", "fail", "pass"))
  expect_identical(detail_for(report, "colour_separability_deutan"),
                   "Closest pair #00b0f6 and #e76bf3 of 5 encoding colours.")
  old <- check_figure(p, metric = "cie76")
  expect_equal(old$measured[1:4], c(60.58, 16.87, 7.35, 12.87))
  expect_identical(old$verdict[1:4], rep("pass", 4))
})

test_that("metric = \"cie76\" restores the 1976 distance", {
  # The numbers the audit reported before it measured CIEDE2000, pinned in the
  # Python suite as well. Only the four colour rows depend on the metric.
  eight <- data.frame(g = factor(letters[1:8]), x = 1:8, y = 1:8)
  p <- ggplot(eight, aes(x, y, colour = g)) + geom_point() +
    scale_colour_depictr() + theme_depictr()
  old <- check_figure(p, metric = "cie76")
  expect_equal(old$measured,
               c(33.43, 18.15, 7.4, 16.18, 0.79, 8.8, 8.45, 1.32, 0, NA))
  expect_identical(old$detail[1:4], c(
    "Closest pair #d55e00 and #e69f00 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #999999 and #cc79a7 of 8 encoding colours.",
    "Closest pair #009e73 and #56b4e9 of 8 encoding colours."))
  expect_identical(old[5:10, ], check_figure(p)[5:10, ])
  expect_equal(check_figure(bad_figure(), metric = "cie76")$measured,
               c(116.25, 35.04, 0.37, 119.38, 6.32, 4, 8.45, 4.01, 0, NA))
  # A composite measures every panel by the metric it is given.
  both <- check_figure(arrange_plots(good_figure(), bad_figure(),
                                     tag_levels = NULL), metric = "cie76")
  expect_equal(both$measured[both$check == "colour_separability_deutan"],
               c(107.07, 0.37))
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

test_that("two and three groups in the contrast-first order pass every colour row", {
  old <- options(depictr.palette = NULL)
  on.exit(options(old), add = TRUE)
  colour_rows <- c("colour_separability", "colour_separability_protan",
                   "colour_separability_deutan", "colour_separability_tritan",
                   "greyscale_separability", "geometry_contrast")
  grouped <- function(data, mapping, order) {
    ggplot(data, mapping) + geom_point() +
      scale_colour_depictr(order = order) + theme_depictr()
  }
  two <- aes(rainfall, yield, colour = treatment, shape = treatment)
  three <- aes(age, stress, colour = education, shape = education)
  # Education is an ordered factor, and ggplot2 advises against shapes for
  # one, so the three groups are drawn as plain categories.
  wellbeing_survey$education <- factor(wellbeing_survey$education,
                                       ordered = FALSE)

  for (p in list(grouped(crop_yield, two, "contrast"),
                 grouped(wellbeing_survey, three, "contrast"))) {
    report <- check_figure(p)
    expect_identical(report$verdict[report$check %in% colour_rows],
                     rep("pass", length(colour_rows)))
  }
  # Three groups sit where the documentation says: 6.86 apart in lightness,
  # with the reddish purple the lowest contrast at 3.06:1.
  report <- check_figure(grouped(wellbeing_survey, three, "contrast"))
  expect_equal(measured_for(report, "greyscale_separability"), 6.86)
  expect_equal(measured_for(report, "geometry_contrast"), 3.06)

  # In the default order the orange draws the second group, at 2.25:1.
  report <- check_figure(grouped(crop_yield, two, "default"))
  expect_identical(verdict_for(report, "geometry_contrast"), "fail")
  expect_equal(measured_for(report, "geometry_contrast"), 2.25)

  # The global route the documentation gives reaches depictr's own plots.
  old_pal <- depictr_options(palette = depictr_palette(order = "contrast"))
  on.exit(do.call(depictr_options, old_pal), add = TRUE)
  report <- check_figure(ecdf_plot(wellbeing_survey, stress, group = education))
  expect_identical(report$verdict[report$check %in% colour_rows],
                   rep("pass", length(colour_rows)))
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

# --- translucent marks and text, measured as drawn ---------------------------

test_that("translucent fills are measured as the colours they show", {
  bars <- check_figure(bars_figure(alpha = 0.3))
  expect_identical(mix("#005b96", "#ffffff", 0.3), "#b3cee0")
  expect_identical(mix("#d55e00", "#ffffff", 0.3), "#f2cfb3")
  expect_equal(measured_for(bars, "geometry_contrast"),
               round(wcag("#f2cfb3", "#ffffff"), 2))
  expect_identical(verdict_for(bars, "geometry_contrast"), "fail")
  expect_identical(verdict_for(bars, "greyscale_separability"), "fail")
  # The colour rows are palette_safety() on the drawn colours.
  reference <- palette_safety(c("#b3cee0", "#f2cfb3"))
  expect_equal(measured_for(bars, "colour_separability"),
               reference$by_condition[["normal"]])
  for (tp in c("protan", "deutan", "tritan")) {
    expect_equal(measured_for(bars, paste0("colour_separability_", tp)),
                 reference$by_condition[[tp]])
  }
  # A fill is mixed with the panel it is drawn on, here a dark one.
  dark <- check_figure(bars_figure(alpha = 0.3) +
    theme(panel.background = ggplot2::element_rect(fill = "#333333")))
  blue <- mix("#005b96", "#333333", 0.3)
  expect_equal(measured_for(dark, "geometry_contrast"),
               round(wcag(blue, "#333333"), 2))
  expect_identical(detail_for(dark, "geometry_contrast"), sprintf(
    "Lowest-contrast colour #005b96 at alpha 0.30, drawn as %s, on #333333.",
    blue))
  # Opaque bars keep the detail they always had.
  expect_identical(detail_for(check_figure(bars_figure(alpha = 1)),
                              "geometry_contrast"),
                   "Lowest-contrast colour #d55e00 on #ffffff.")
})

test_that("translucent points are measured as drawn", {
  points <- check_figure(points_figure(alpha = 0.7))
  expect_identical(mix("#d55e00", "#ffffff", 0.7), "#e28e4d")
  expect_equal(measured_for(points, "geometry_contrast"),
               round(wcag("#e28e4d", "#ffffff"), 2))
  expect_identical(verdict_for(points, "geometry_contrast"), "fail")
})

test_that("translucent text is measured as drawn", {
  # alpha("black", 0.25) is #00000040, black at 64/255 over white.
  veiled <- check_figure(good_figure() +
    theme(axis.text = ggplot2::element_text(colour = alpha("black", 0.25))))
  grey <- mix("#000000", "#ffffff", 64 / 255)
  expect_identical(grey, "#bfbfbf")
  expect_equal(measured_for(veiled, "text_contrast"), 1.84)
  expect_equal(measured_for(veiled, "text_contrast"),
               round(wcag(grey, "#ffffff"), 2))
  expect_identical(verdict_for(veiled, "text_contrast"), "fail")
  expect_identical(detail_for(veiled, "text_contrast"), paste(
    "Lowest-contrast text #000000 at alpha 0.25, drawn as #bfbfbf,",
    "on #ffffff at 8.80 pt."))
})

test_that("a gpar alpha is multiplied into text down the grob tree", {
  # grid multiplies a grob's alpha into its colour's own and carries a parent's
  # alpha down to its children. Black at 128/255, in a text grob at alpha 0.5
  # inside a tree at alpha 0.5, is drawn at 0.125, which is #dfdfdf on white.
  label <- grid::textGrob("label", gp = grid::gpar(col = "#00000080",
                                                   alpha = 0.5, fontsize = 10))
  tree <- grid::gTree(children = grid::gList(label),
                      gp = grid::gpar(alpha = 0.5))
  text <- .figure_text(tree, .completed_theme(theme_depictr()), "#ffffff")
  expect_equal(text$alpha, 128 / 255 * 0.25)
  expect_identical(text$colour, mix("#000000", "#ffffff", 128 / 255 * 0.25))
  expect_identical(text$colour, "#dfdfdf")
})

test_that("an opaque outline mapped to the same groups carries the contrast", {
  # WCAG lets a border carry a graphical object's contrast. The fills at alpha
  # 0.2 are pale, and the outlines, drawn opaque, are what is measured.
  outlined <- check_figure(density_figure())
  expect_equal(measured_for(outlined, "geometry_contrast"),
               round(wcag("#d55e00", "#ffffff"), 2))
  expect_identical(detail_for(outlined, "geometry_contrast"),
                   "Lowest-contrast colour #d55e00 on #ffffff.")
  # A constant black outline says nothing about which group a shape belongs
  # to, so it carries no credit and the pale fill is measured.
  plain <- check_figure(
    ggplot(crop_yield, aes(yield, fill = treatment)) +
      geom_density(alpha = 0.2, colour = "black") +
      scale_fill_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  pale <- mix("#d55e00", "#ffffff", 0.2)
  expect_equal(measured_for(plain, "geometry_contrast"),
               round(wcag(pale, "#ffffff"), 2))
  expect_identical(detail_for(plain, "geometry_contrast"), sprintf(
    "Lowest-contrast colour #d55e00 at alpha 0.20, drawn as %s, on #ffffff.",
    pale))
})

test_that("each aesthetic's colours are compared among themselves", {
  white <- "#ffffff"
  # The outlines and the pale fills of the densities form two sets, and the
  # row reports the closer of their two pairs, the fills.
  outlined <- check_figure(density_figure())
  fills <- c(mix("#005b96", white, 0.2), mix("#d55e00", white, 0.2))
  expect_equal(measured_for(outlined, "colour_separability"),
               palette_safety(fills)$by_condition[["normal"]])
  expect_identical(detail_for(outlined, "colour_separability"), sprintf(
    "Closest pair %s and %s of 2 encoding fill colours.", fills[[1]],
    fills[[2]]))
  # A fill at alpha 0.9 is a hair from its own opaque outline. Pooled, that
  # pair failed the figure. It is one group, so it is never compared.
  near <- check_figure(density_figure(alpha = 0.9))
  fills <- c(mix("#005b96", white, 0.9), mix("#d55e00", white, 0.9))
  expect_equal(measured_for(near, "colour_separability"),
               palette_safety(fills)$by_condition[["normal"]])
  expect_identical(verdict_for(near, "colour_separability"), "pass")
  # Nor across layers: translucent points beside opaque lines in the same two
  # colours are compared group against group, never a group with itself.
  layered <- check_figure(
    ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
      geom_point(alpha = 0.95) + geom_line() +
      scale_colour_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  blue <- c("#005b96", mix("#005b96", white, 0.95))
  vermillion <- c("#d55e00", mix("#d55e00", white, 0.95))
  across <- min(outer(seq_along(blue), seq_along(vermillion), Vectorize(
    function(i, j) {
      palette_safety(c(blue[[i]], vermillion[[j]]))$by_condition[["normal"]]
    })))
  expect_equal(measured_for(layered, "colour_separability"), across)
  expect_identical(verdict_for(layered, "colour_separability"), "pass")
})

test_that("verdicts on translucent fills can move in either direction", {
  # Red and green fills at alpha 0.6 are lighter by different amounts, so a
  # deuteranope tells them apart by lightness. Read at full opacity, they
  # failed at 0.11.
  red_green <- c("#d62728", "#309208")
  opaque <- check_figure(bars_figure(alpha = 1, values = red_green))
  translucent <- check_figure(bars_figure(alpha = 0.6, values = red_green))
  expect_equal(measured_for(opaque, "colour_separability_deutan"), 0.11)
  expect_identical(verdict_for(opaque, "colour_separability_deutan"), "fail")
  expect_equal(measured_for(translucent, "colour_separability_deutan"), 5.59)
  expect_identical(verdict_for(translucent, "colour_separability_deutan"),
                   "pass")
  # The good figure's colours, which pass at full opacity, fall below 3:1 as
  # fills at alpha 0.3.
  expect_identical(verdict_for(check_figure(bars_figure(alpha = 1)),
                               "geometry_contrast"), "pass")
  expect_identical(verdict_for(check_figure(bars_figure(alpha = 0.3)),
                               "geometry_contrast"), "fail")
})

test_that("a colour's own alpha gives way to the layer's, as ggplot2 draws it", {
  # scales::alpha(), which every geom calls, keeps a colour's own alpha only
  # when the layer sets none. The Python twin follows plotnine, which keeps the
  # colour's own alpha either way, so only the first case is shared.
  own <- c("#005b964d", "#d55e004d")
  unset <- check_figure(bars_figure(alpha = NULL, values = own))
  expect_identical(detail_for(unset, "geometry_contrast"), sprintf(
    "Lowest-contrast colour #d55e00 at alpha 0.30, drawn as %s, on #ffffff.",
    mix("#d55e00", "#ffffff", 77 / 255)))
  set <- check_figure(bars_figure(alpha = 0.6, values = own))
  expect_identical(detail_for(set, "geometry_contrast"), sprintf(
    "Lowest-contrast colour #d55e00 at alpha 0.60, drawn as %s, on #ffffff.",
    mix("#d55e00", "#ffffff", 0.6)))
})

test_that("the layer alpha reaches the parts each geom applies it to", {
  # As ggplot2 draws them: area geoms take it on the fill and leave the outline
  # opaque, lines take it on the colour, and points on both. A geom not listed
  # takes it on both, the cautious assumption.
  fill_only <- list(GeomCol, GeomBar, GeomTile, GeomRect, GeomArea,
                    GeomRibbon, GeomDensity, GeomPolygon, GeomViolin,
                    GeomBoxplot, GeomCrossbar, GeomSmooth)
  colour_only <- list(GeomPath, GeomLine, GeomStep, GeomSegment, GeomErrorbar,
                      GeomLinerange, GeomHline, GeomVline, GeomAbline)
  both <- list(GeomPoint, GeomPointrange, GeomDotplot)
  for (geom in fill_only) expect_identical(.alpha_targets(geom), "fill")
  for (geom in colour_only) expect_identical(.alpha_targets(geom), "colour")
  for (geom in both) {
    expect_identical(.alpha_targets(geom), c("colour", "fill"))
  }
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

# --- colours split across layers ---------------------------------------------

test_that("a colour mapped in several layers, one value each, is an encoding", {
  # The same red and green in one layer fail deuteranopia at 0.11. Split one
  # group per layer, every colour row read "not applicable".
  one_layer <- check_figure(
    ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
      geom_point() +
      scale_colour_manual(values = c("#d62728", "#309208")) +
      theme_depictr())
  split <- check_figure(split_figure())
  expect_identical(encoding_rows(split), encoding_rows(one_layer))
  expect_equal(measured_for(split, "colour_separability_deutan"), 0.11)
  expect_identical(verdict_for(split, "colour_separability_deutan"), "fail")
  # A layer inherits a constant the plot maps, as it inherits any mapping.
  inherited <- check_figure(
    ggplot(standard, aes(rainfall, yield, colour = "a")) +
      geom_point() +
      geom_point(data = enhanced, aes(colour = "b")) +
      scale_colour_manual(values = c("#d62728", "#309208")) +
      theme_depictr())
  expect_identical(encoding_rows(inherited), encoding_rows(one_layer))
  # Fills split across layers form one set, measured as drawn: translucent bars
  # drawn one per layer read as the one-layer bars do.
  two <- data.frame(g = c("a", "b"), y = c(1, 2))
  split_bars <- check_figure(
    ggplot(mapping = aes(g, y)) +
      geom_col(data = two[1, ], aes(fill = "a"), alpha = 0.3) +
      geom_col(data = two[2, ], aes(fill = "b"), alpha = 0.3) +
      scale_fill_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  expect_identical(encoding_rows(split_bars),
                   encoding_rows(check_figure(bars_figure(alpha = 0.3))))
})

test_that("shape and line type split across layers count as redundant", {
  shapes <- check_figure(
    ggplot(mapping = aes(rainfall, yield)) +
      geom_point(data = standard, aes(colour = "a", shape = "a")) +
      geom_point(data = enhanced, aes(colour = "b", shape = "b")) +
      scale_colour_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  expect_equal(measured_for(shapes, "redundant_encoding"), 1)
  expect_identical(detail_for(shapes, "redundant_encoding"),
                   "Colour is joined by shape.")
  lines <- check_figure(
    ggplot(mapping = aes(rainfall, yield)) +
      geom_line(data = standard, aes(colour = "a", linetype = "a")) +
      geom_line(data = enhanced, aes(colour = "b", linetype = "b")) +
      scale_colour_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  expect_identical(detail_for(lines, "redundant_encoding"),
                   "Colour is joined by linetype.")
  # Points that vary in shape beside lines that vary in line type count both
  # channels. Each layer varies in one, and the count used to stop at one.
  points_and_lines <- check_figure(
    ggplot(crop_yield, aes(rainfall, yield, colour = treatment)) +
      geom_point(aes(shape = treatment)) +
      geom_line(aes(linetype = treatment)) +
      scale_colour_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  expect_equal(measured_for(points_and_lines, "redundant_encoding"), 2)
  expect_identical(detail_for(points_and_lines, "redundant_encoding"),
                   "Colour is joined by shape and linetype.")
  # A shape set on each layer is a constant, so it is not counted.
  set_shapes <- check_figure(
    ggplot(mapping = aes(rainfall, yield)) +
      geom_point(data = standard, aes(colour = "a"), shape = 16) +
      geom_point(data = enhanced, aes(colour = "b"), shape = 17) +
      scale_colour_manual(values = c("#005b96", "#d55e00")) +
      theme_depictr())
  expect_equal(measured_for(set_shapes, "redundant_encoding"), 0)
  expect_identical(detail_for(set_shapes, "redundant_encoding"),
                   "Colour alone distinguishes the groups.")
})

test_that("frequentist_bayesian_plot() with draws is audited by colour", {
  # The half-eyes map colour to the Bayesian label and the overlay to the
  # frequentist one, in layers of their own, so every colour row of the
  # posterior figure used to read "not applicable". Without ggdist, the
  # fallback splits the colour across layers the same way.
  freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
             data = wellbeing_survey)
  withr::local_seed(1)
  co <- coef(freq)
  draws <- as.data.frame(lapply(co, function(m) {
    rnorm(400, m, abs(m) * 0.1 + 0.05)
  }))
  names(draws) <- names(co)
  posterior <- suppressMessages(frequentist_bayesian_plot(freq, draws))
  report <- check_figure(posterior)
  expect_false(anyNA(encoding_rows(report)$measured))
  pair <- depictr_palette(2)
  expect_equal(measured_for(report, "colour_separability"),
               palette_safety(pair)$by_condition[["normal"]])
  expect_identical(detail_for(report, "colour_separability"), sprintf(
    "Closest pair %s and %s of 2 encoding colours.", pair[[1]], pair[[2]]))
})

# --- text drawn inside the panel ---------------------------------------------

test_that("text inside the panel is held to the size floor in a row of its own", {
  # A 5.7 pt note fails the 6 pt floor. The theme's text keeps the row it
  # always had, still 8.80 pt.
  report <- check_figure(annotated_figure())
  expect_equal(measured_for(report, "annotation_text_size"), 5.7)
  expect_identical(verdict_for(report, "annotation_text_size"), "fail")
  expect_equal(report$threshold[report$check == "annotation_text_size"], 6)
  expect_equal(measured_for(report, "text_size"), 8.8)
  expect_identical(verdict_for(report, "text_size"), "pass")
  # The note scales with the printed width as the theme's text does.
  column <- check_figure(annotated_figure(), width_cm = 8.89)
  expect_equal(measured_for(column, "annotation_text_size"), 2.85)
  expect_identical(detail_for(column, "annotation_text_size"), paste(
    "Smallest in-panel text 5.70 pt, drawn at 17.78 cm and printed at",
    "8.89 cm."))
  expect_equal(measured_for(check_figure(annotated_figure(), width_cm = 8.89,
                                         render_width_cm = 8.89),
                            "annotation_text_size"), 5.7)
  # The smallest text across all the panels of a facetted figure: the note is
  # drawn in both, and a smaller label in the first alone.
  facetted <- check_figure(good_figure() + facet_wrap(~treatment) +
    annotate("text", x = 800, y = 5, label = "note", size = 7 / ggplot2::.pt) +
    geom_text(aes(rainfall, yield, label = "one"), data = standard[1, ],
              size = 6.5 / ggplot2::.pt, inherit.aes = FALSE))
  expect_equal(measured_for(facetted, "annotation_text_size"), 6.5)
  # A label's text is measured as text is: the box around it is not.
  labelled <- check_figure(good_figure() +
    annotate("label", x = 800, y = 5, label = "boxed", size = 5 / ggplot2::.pt))
  expect_equal(measured_for(labelled, "annotation_text_size"), 5)
})

test_that("a blank label draws nothing, so its size is not measured", {
  # One label is empty and set smaller than the other. The Python twin never
  # sees it, since matplotlib draws no text for it.
  labels <- data.frame(x = c(1, 2), y = c(1, 2), label = c("", "b"),
                       size = c(4, 9) / ggplot2::.pt)
  report <- check_figure(
    ggplot(labels, aes(x, y, label = label, size = size)) +
      geom_text() + scale_size_identity() + theme_depictr())
  expect_equal(measured_for(report, "annotation_text_size"), 9)
})

test_that("a figure whose only text is inside the panel says so", {
  # The theme draws no text, so the two rows that measure it abstain, and they
  # no longer claim that the figure draws no text at all.
  p <- ggplot(crop_yield[1:3, ], aes(rainfall, yield, label = field)) +
    geom_text(size = 8 / ggplot2::.pt) + theme_void()
  report <- check_figure(p)
  for (check in c("text_size", "text_contrast")) {
    expect_identical(verdict_for(report, check), "not applicable")
    expect_identical(detail_for(report, check),
                     "The figure draws no text outside the panel.")
  }
  expect_equal(measured_for(report, "annotation_text_size"), 8)
})

# --- what the audit declines to measure --------------------------------------

test_that("a continuous colour scale is not treated as a set of category codes", {
  # A gradient's neighbouring colours are meant to be close, so measuring the
  # distance between them would only ever report that a gradient is a gradient.
  heatmap <- correlation_heatmap(wellbeing_survey)
  report <- check_figure(heatmap)
  for (check in colour_checks) {
    expect_identical(verdict_for(report, check), "not applicable")
    expect_true(is.na(measured_for(report, check)))
    # The detail says why. It used to say that nothing is distinguished by
    # colour, which is false of a heatmap.
    expect_identical(detail_for(report, check),
                     "Colour is a continuous scale, which these checks do not audit.")
  }
  # The heatmap's cell labels are a text layer, so they neither count as
  # encoding colours nor drag the text-size measurement down to their own size.
  expect_equal(measured_for(report, "text_size"), 8.8)
  # They are measured in the row for text inside the panel instead. The Python
  # twin draws them at another size, so the value is read from this plot's own
  # text layer and is not pinned across the twins.
  labels <- Filter(function(layer) inherits(layer$geom, "GeomText"),
                   heatmap$layers)[[1]]
  expect_equal(measured_for(report, "annotation_text_size"),
               round(labels$aes_params$size * ggplot2::.pt, 2))
})

test_that("a continuous scale counts when the figure draws from it", {
  continuous_detail <- function(p) {
    report <- check_figure(p)
    unique(report$detail[report$check %in% colour_checks])
  }
  # A fill that a stat computes comes from a continuous scale, though no layer
  # maps it by name. The Python suite pins the same two cases.
  expect_identical(
    continuous_detail(ggplot(crop_yield, aes(rainfall, yield)) +
                        geom_bin_2d(bins = 10) + theme_depictr()),
    "Colour is a continuous scale, which these checks do not audit.")
  # A continuous scale added to a plot that maps nothing to it draws nothing.
  expect_identical(
    continuous_detail(ggplot(crop_yield, aes(rainfall, yield)) + geom_point() +
                        scale_colour_gradient() + theme_depictr()),
    "No two encoding colours: nothing is distinguished by colour.")
})

test_that("a figure with no colour encoding abstains rather than passing", {
  p <- ggplot(crop_yield, aes(rainfall, yield)) + geom_point() + theme_depictr()
  report <- check_figure(p)
  expect_true(all(report$verdict[report$check %in% colour_checks] ==
                    "not applicable"))
  expect_true(all(is.na(report$measured[report$check %in% colour_checks])))
  expect_identical(
    unique(report$detail[report$check %in% colour_checks]),
    "No two encoding colours: nothing is distinguished by colour.")
  # Text is still there to measure.
  expect_identical(verdict_for(report, "text_size"), "pass")
})

test_that("colours set layer by layer as constants abstain", {
  abstains <- function(p) {
    rows <- encoding_rows(check_figure(p))
    expect_identical(unique(rows$verdict), "not applicable")
    expect_identical(
      unique(rows$detail),
      "No two encoding colours: nothing is distinguished by colour.")
  }
  # A constant set on each layer is not a mapping. The audit cannot tell it
  # from decoration, so it leaves it out, as the help page says.
  abstains(ggplot(mapping = aes(rainfall, yield)) +
             geom_point(data = standard, colour = "#d62728") +
             geom_point(data = enhanced, colour = "#309208") +
             theme_depictr())
  # Nor is a colour passed through an identity scale.
  abstains(ggplot(mapping = aes(rainfall, yield)) +
             geom_point(data = standard, aes(colour = "#d62728")) +
             geom_point(data = enhanced, aes(colour = "#309208")) +
             scale_colour_identity() +
             theme_depictr())
  # One mapped value is one colour, which is not a pair.
  abstains(ggplot(crop_yield, aes(rainfall, yield, colour = "a")) +
             geom_point() + theme_depictr())
  # A reference line does not inherit the plot's mapping, so its black does
  # not join the mapped colour.
  abstains(ggplot(crop_yield, aes(rainfall, yield, colour = "a")) +
             geom_point() + geom_hline(yintercept = 5) + theme_depictr())
})

test_that("a figure that draws no text says so rather than reporting a size", {
  p <- ggplot(crop_yield, aes(rainfall, yield)) + geom_point() +
    theme_void() + theme(legend.position = "none")
  report <- check_figure(p)
  expect_identical(verdict_for(report, "text_size"), "not applicable")
  expect_identical(verdict_for(report, "text_contrast"), "not applicable")
  expect_identical(report$detail[report$check == "text_size"],
                   "The figure draws no text.")
  expect_identical(verdict_for(report, "annotation_text_size"),
                   "not applicable")
  expect_identical(detail_for(report, "annotation_text_size"),
                   "The figure draws no text inside the panel.")
})

# --- degenerate inputs -------------------------------------------------------

test_that("a single row and a zero-variance grouping still audit", {
  one <- crop_yield[1, , drop = FALSE]
  report <- check_figure(ggplot(one, aes(rainfall, yield)) + geom_point() +
                           theme_depictr())
  expect_identical(nrow(report), 10L)
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
  expect_identical(nrow(report), 10L)
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

# --- a text ceiling ----------------------------------------------------------

test_that("max_text_pt appends a ceiling row that passes at or below it", {
  # Without a ceiling, the report keeps its ten rows, so the default output and
  # the vectors both suites pin are unchanged. With one, its row comes last and
  # the ten before it are those of the plain report.
  plain <- check_figure(good_figure())
  report <- check_figure(good_figure(), max_text_pt = 7)
  expect_identical(nrow(report), 11L)
  expect_identical(report$check, c(plain$check, "text_size_max"))
  expect_identical(report[1:10, ], plain)
  # The largest text is the axis titles at the base size of 11 pt, which
  # Nature's 7 pt ceiling refuses. The Python suite pins the same row.
  expect_equal(measured_for(report, "text_size_max"), 11)
  expect_equal(report$threshold[report$check == "text_size_max"], 7)
  expect_identical(verdict_for(report, "text_size_max"), "fail")
  expect_identical(detail_for(report, "text_size_max"), paste(
    "Largest text 11.00 pt, drawn at 17.78 cm and printed at 17.78 cm."))
  # The one inverted row: it passes at or below its threshold, the boundary
  # included.
  expect_identical(verdict_for(check_figure(good_figure(), max_text_pt = 11),
                               "text_size_max"), "pass")
  expect_identical(verdict_for(check_figure(good_figure(),
                                            max_text_pt = 10.99),
                               "text_size_max"), "fail")
  # Printed at half the width it is drawn at, the same text clears it.
  column <- check_figure(good_figure(), width_cm = 8.89, max_text_pt = 7)
  expect_equal(measured_for(column, "text_size_max"), 5.5)
  expect_identical(verdict_for(column, "text_size_max"), "pass")
})

test_that("the ceiling measures the text inside the panel too", {
  # A 12 pt note is larger than any text the theme draws.
  report <- check_figure(annotated_figure(size = 12 / ggplot2::.pt),
                         max_text_pt = 7)
  expect_equal(measured_for(report, "text_size_max"), 12)
  # A figure that draws no text has nothing to hold to a ceiling.
  blank <- check_figure(ggplot() + theme_void(), max_text_pt = 7)
  expect_identical(verdict_for(blank, "text_size_max"), "not applicable")
  expect_identical(detail_for(blank, "text_size_max"),
                   "The figure draws no text.")
})

test_that("each panel of a composite is held to the ceiling", {
  report <- check_figure(arrange_plots(good_figure(), bad_figure(),
                                       tag_levels = NULL), max_text_pt = 7)
  expect_identical(nrow(report), 22L)
  ceiling <- report[report$check == "text_size_max", ]
  expect_identical(ceiling$panel, 1:2)
  expect_equal(ceiling$measured, c(11, 5))
  expect_identical(ceiling$verdict, c("fail", "pass"))
})

# --- composites --------------------------------------------------------------

test_that("a composite is audited panel by panel, in reading order", {
  # Pinned so the two engines cannot drift apart unnoticed: the Python suite
  # audits the same two panels and pins the same vector. Each panel reports
  # what its figure reports alone, under a leading panel column.
  report <- check_figure(arrange_plots(good_figure(), bad_figure(),
                                       tag_levels = NULL))
  expect_identical(names(report), c("panel", "check", "measured", "threshold",
                                    "verdict", "detail"))
  expect_identical(nrow(report), 20L)
  expect_identical(report$panel, rep(1:2, each = 10))
  expect_identical(report$check, rep(check_figure(good_figure())$check, 2))
  expect_equal(report$measured, c(
    50.12, 49.67, 58.3, 61.99, 16.92, 8.8, 8.45, 3.87, 1, NA,
    69.59, 20.06, 0.11, 62.7, 6.32, 4, 8.45, 4.01, 0, NA))
  expect_identical(rownames(report), as.character(seq_len(20)))
  second <- report[report$panel == 2, -1]
  rownames(second) <- NULL
  expect_identical(second, check_figure(bad_figure()))
})

test_that("composite-level titles and tags are not measured", {
  # patchwork draws them around the panels, and no panel holds them. A 2 pt
  # title and 2 pt tags would fail the text floor, yet the panels' rows are
  # those of the same panels without them.
  plain <- check_figure(arrange_plots(good_figure(), bad_figure(),
                                      tag_levels = NULL))
  annotated <- patchwork::wrap_plots(good_figure(), bad_figure()) +
    patchwork::plot_annotation(
      title = "Two panels", tag_levels = "A",
      theme = theme(plot.title = element_text(size = 2))) &
    theme(plot.tag = element_text(size = 2))
  expect_identical(check_figure(annotated), plain)
})

test_that("nested composites are walked depth-first, and spacers are not panels", {
  nested <- check_figure(arrange_plots(
    arrange_plots(good_figure(), bad_figure(), tag_levels = NULL),
    good_figure(), tag_levels = NULL))
  expect_identical(unique(nested$panel), 1:3)
  expect_equal(nested$measured[nested$check == "text_size"], c(8.8, 4, 8.8))

  # A spacer and a guide area draw no figure of their own, and patchwork tags
  # neither, so the panels around them are numbered 1 and 2.
  spaced <- check_figure(patchwork::wrap_plots(
    good_figure(), patchwork::plot_spacer(), bad_figure(),
    patchwork::guide_area(), guides = "collect"))
  expect_identical(unique(spaced$panel), 1:2)
  expect_equal(spaced$measured[spaced$check == "text_size"], c(8.8, 4))

  # With nothing but spacers, there is no panel to audit.
  empty <- check_figure(patchwork::wrap_plots(patchwork::plot_spacer(),
                                              patchwork::plot_spacer()))
  expect_identical(names(empty), names(spaced))
  expect_identical(nrow(empty), 0L)
})

test_that("a wrapped element keeps its number and is left out with a warning", {
  # The audit cannot read a grob, so it says so instead of reporting that the
  # panel draws no text.
  composite <- patchwork::wrap_plots(
    good_figure(), patchwork::wrap_elements(grid::textGrob("note")),
    bad_figure())
  expect_warning(report <- check_figure(composite),
                 "^Panel 2 is a wrapped element")
  expect_identical(unique(report$panel), c(1L, 3L))
})

test_that("the package's own composites are audited panel by panel", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  diagnostics <- check_figure(residual_diagnostics_plot(fit))
  expect_identical(unique(diagnostics$panel), 1:4)
  expect_identical(nrow(diagnostics), 40L)
  # model_report() frees each panel's axis title with patchwork::free(), which
  # changes the class of the panels it returns.
  report <- check_figure(model_report(fit))
  expect_identical(unique(report$panel), 1:4)
  expect_true(all(report$verdict[report$check == "text_size"] == "pass"))
})

# --- refusals ----------------------------------------------------------------

test_that("check_figure() refuses what it cannot audit", {
  expect_error(check_figure(1),
               paste0("^`plot` must be a plot object, as returned by any ",
                      "depictr plotting function\\.$"))
  expect_error(check_figure("a plot"),
               paste0("^`plot` must be a plot object, as returned by any ",
                      "depictr plotting function\\.$"))
})

test_that("check_figure() refuses a metric it does not know", {
  expect_error(check_figure(good_figure(), metric = "cie94"),
               "should be one of")
})

test_that("check_figure() refuses non-positive and non-scalar settings", {
  p <- good_figure()
  for (arg in c("width_cm", "render_width_cm", "min_delta_e", "min_text_pt",
                "max_text_pt")) {
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
  # what the figure ships with, so it is what gets audited. The dumbbell's
  # points are opaque, so the verdicts turn on the scale alone.
  base <- dumbbell_plot(lexical_decision, participant, RT, condition)
  expect_identical(
    verdict_for(check_figure(base), "colour_separability_deutan"), "pass")
  # Replacing a scale that is already there is the ordinary way a user overrides
  # depictr's colours, and ggplot2 says so every time; the message is not the
  # subject of this test.
  broken <- suppressMessages(
    base + scale_colour_manual(values = c("#d62728", "#309208")))
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
