# Tier-4 theming: CVD-aware palette preview + global options ------------------

# --- (a) colour-vision-deficiency transform ---------------------------------

test_that("simulate_cvd() at severity zero returns the colours unchanged", {
  cols <- c("#005b96", "#e69f00", "#009e73")
  # Severity zero is the identity matrix, so the round trip through linear RGB
  # must come back to the same eight-bit colour, in canonical lower-case hex.
  for (tp in c("protan", "deutan", "tritan")) {
    expect_identical(simulate_cvd(cols, tp, severity = 0), cols)
  }
})

test_that("simulate_cvd() preserves achromatic colours (grey/black/white)", {
  # The Machado severity-1.0 matrices have rows that sum to 1, so neutral greys
  # map to themselves under every deficiency. This is the defining sanity check.
  for (tp in c("protan", "deutan", "tritan")) {
    expect_identical(simulate_cvd("#808080", tp), "#808080")
    expect_identical(simulate_cvd("#000000", tp), "#000000")
    expect_identical(simulate_cvd("#ffffff", tp), "#ffffff")
  }
  # Equivalently, the matrix rows must each sum to ~1.
  for (tp in c("protan", "deutan", "tritan")) {
    expect_equal(unname(rowSums(.cvd_matrices[[tp]])), c(1, 1, 1),
                 tolerance = 1e-4)
  }
})

test_that("simulate_cvd() matches an independent Machado re-implementation", {
  # Re-implement the deutan transform from scratch (no shared code) and confirm
  # simulate_cvd() reproduces it bit-for-bit, guarding against a transposed
  # matrix or swapped channels.
  indep_deutan <- function(hex) {
    M <- matrix(c(
       0.367322,  0.860646, -0.227968,
       0.280085,  0.672501,  0.047413,
      -0.011820,  0.042940,  0.968881), nrow = 3, byrow = TRUE)
    srgb <- as.numeric(grDevices::col2rgb(hex)) / 255
    lin <- ifelse(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055)^2.4)
    out <- pmax(pmin(as.numeric(M %*% lin), 1), 0)
    enc <- ifelse(out <= 0.0031308, out * 12.92, 1.055 * out^(1 / 2.4) - 0.055)
    tolower(grDevices::rgb(enc[1], enc[2], enc[3]))
  }
  test <- c("#005b96", "#e69f00", "#d55e00", "#ff0000", "#3366cc")
  expect_identical(
    vapply(test, indep_deutan, character(1), USE.NAMES = FALSE),
    simulate_cvd(test, "deutan")
  )
})

test_that("simulate_cvd() matches colorspace, an independent implementation", {
  # colorspace implements the same Machado model from the published matrices.
  # Agreement to the eight-bit colour is the strongest external check available
  # without leaving CRAN.
  skip_if_not_installed("colorspace")
  pal <- depictr_palette()
  for (tp in c("protan", "deutan", "tritan")) {
    theirs <- tolower(switch(
      tp,
      protan = colorspace::protan(pal, severity = 1),
      deutan = colorspace::deutan(pal, severity = 1),
      tritan = colorspace::tritan(pal, severity = 1)
    ))
    expect_identical(simulate_cvd(pal, tp), theirs, info = tp)
  }
})

test_that("simulate_cvd() reddens out: red loses red, gains green under protan", {
  rp <- grDevices::col2rgb(simulate_cvd("#ff0000", "protan"))[, 1]
  expect_lt(rp["red"], 255)
  expect_gt(rp["green"], 0)
})

test_that("simulate_cvd() refuses an unknown deficiency and an out-of-range severity", {
  expect_error(simulate_cvd("#005b96", "none"),
               "^`deficiency` must be one of 'protan', 'deutan' or 'tritan'\\.$")
  expect_error(simulate_cvd("#005b96", c("protan", "deutan")),
               "^`deficiency` must be one of 'protan', 'deutan' or 'tritan'\\.$")
  expect_error(simulate_cvd("#005b96", "deutan", severity = 2),
               "^`severity` must lie in \\[0, 1\\]\\.$")
  expect_error(simulate_cvd("#005b96", "deutan", severity = NA),
               "^`severity` must lie in \\[0, 1\\]\\.$")
})

# --- automated colourblind-safety assertion ---------------------------------

test_that("the default qualitative palette stays distinguishable under CVD", {
  # For every vision type, no two palette colours may collapse together. CIE76
  # distance >= 5 is comfortably above the ~2.3 just-noticeable-difference, so
  # every pair remains clearly separable. The observed worst case (deutan) is
  # ~7.4, leaving a healthy margin.
  report <- palette_safety()
  saf <- report$by_condition
  expect_named(saf, c("normal", "protan", "deutan", "tritan"))
  expect_true(report$safe)
  expect_identical(report$worst_condition, "deutan")
  expect_identical(report$worst_pair, c("#cc79a7", "#999999"))
  expect_equal(report$min_delta_e, 7.4)
  expect_true(all(saf > 5),
              info = paste("min CVD distances:",
                           paste(round(saf, 2), collapse = ", ")))

  # Cross-check the safety statistic with an independent Lab computation: the
  # minimum pairwise distance computed directly from col2rgb -> XYZ -> Lab.
  independent_min <- function(cols) {
    rgb <- grDevices::col2rgb(cols) / 255
    lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
    m <- matrix(c(0.4124564, 0.3575761, 0.1804375,
                  0.2126729, 0.7151522, 0.0721750,
                  0.0193339, 0.1191920, 0.9503041), nrow = 3, byrow = TRUE)
    xyz <- (m %*% lin) / c(0.95047, 1, 1.08883)
    f <- function(t) ifelse(t > 0.008856, t^(1 / 3), 7.787 * t + 16 / 116)
    lab <- cbind(116 * f(xyz[2, ]) - 16,
                 500 * (f(xyz[1, ]) - f(xyz[2, ])),
                 200 * (f(xyz[2, ]) - f(xyz[3, ])))
    d <- as.matrix(stats::dist(lab)); diag(d) <- Inf; min(d)
  }
  pal <- depictr_palette()
  for (tp in c("normal", "protan", "deutan", "tritan")) {
    seen <- if (tp == "normal") pal else simulate_cvd(pal, tp)
    expect_equal(saf[[tp]], round(independent_min(seen), 2), tolerance = 1e-3)
  }
})

test_that("palette_safety() needs a pair, and reports the closest one", {
  # One colour has no pairwise distance. The no-pair sentinel used to survive to
  # the result as an infinite distance with safe = TRUE, and a worst pair naming
  # the same colour twice.
  expect_error(palette_safety("#005b96"),
               "^`colours` needs at least two colours to have a pairwise distance\\.$")
  expect_error(palette_safety(character(0)),
               "^`colours` needs at least two colours to have a pairwise distance\\.$")
  # Passing nothing at all still means the default palette.
  expect_identical(palette_safety()$worst_pair,
                   palette_safety(depictr_palette())$worst_pair)
  # Two colours a hair apart stay close under every condition.
  near <- palette_safety(c("#005b96", "#015c97"))
  expect_false(near$safe)
  expect_identical(near$worst_pair, c("#005b96", "#015c97"))
})

test_that("interpolating past the base set warns, and the base set does not", {
  old <- options(depictr.palette = NULL)
  on.exit(options(old), add = TRUE)

  # The warning is about interpolation, so asking for the base set (or a slice
  # of it, or either ramp) must stay quiet.
  expect_no_warning(depictr_palette())
  expect_no_warning(depictr_palette(8))
  expect_no_warning(depictr_palette(20, type = "sequential"))

  expect_warning(
    pal <- depictr_palette(10),
    paste0("^10 colours interpolated through the 8-colour Okabe-Ito set: the ",
           "colour-vision-deficiency guarantee holds only up to 8 categories\\. ",
           "Use a sequential palette, or facet the groups, if the distinction ",
           "must survive colour-vision deficiency\\.$")
  )
  expect_length(pal, 10)
  # The claim the warning makes is true: the interpolated set fails the
  # package's own check, while the eight it is made for clears it.
  expect_false(palette_safety(pal)$safe)
  expect_true(palette_safety(depictr_palette(8))$safe)
})

test_that("a user-supplied palette is interpolated without the Okabe-Ito warning", {
  # The message names Okabe-Ito, and a custom palette never carried that
  # guarantee, so there is nothing to withdraw.
  old <- depictr_options(palette = c("#1b9e77", "#d95f02", "#7570b3"))
  on.exit(do.call(depictr_options, old), add = TRUE)
  expect_no_warning(pal <- depictr_palette(9))
  expect_length(pal, 9)
})

test_that("scale_colour_depictr() warns at draw time past eight groups", {
  old <- options(depictr.palette = NULL)
  on.exit(options(old), add = TRUE)
  df <- data.frame(g = factor(letters[1:10]), v = 1:10)
  p <- ggplot2::ggplot(df, ggplot2::aes(g, v, colour = g)) +
    ggplot2::geom_point() + scale_colour_depictr()
  expect_warning(ggplot2::ggplot_build(p),
                 "colour-vision-deficiency guarantee holds only up to 8")
})

# --- palette_preview() CVD rendering ----------------------------------------

test_that("palette_preview() builds without warnings for every cvd setting", {
  for (cv in c("none", "deutan", "protan", "tritan")) {
    expect_no_warning(ggplot2::ggplot_build(palette_preview(8, cvd = cv)))
  }
})

test_that("palette_preview(cvd=) recolours tiles but keeps original hex labels", {
  none_fill <- ggplot2::ggplot_build(
    palette_preview(8, cvd = "none"))$data[[1]]$fill
  deut_fill <- ggplot2::ggplot_build(
    palette_preview(8, cvd = "deutan"))$data[[1]]$fill
  # Tiles change under simulation ...
  expect_false(identical(none_fill, deut_fill))
  # ... and equal the simulated colours of the true palette.
  expect_identical(toupper(deut_fill),
                   toupper(simulate_cvd(depictr_palette(8), "deutan")))

  # The text labels keep the *original* hex codes, not the simulated ones.
  built <- ggplot2::ggplot_build(palette_preview(8, cvd = "deutan"))
  text_layer <- built$data[[length(built$data)]]
  expect_true("label" %in% names(text_layer))
  expect_setequal(toupper(text_layer$label), toupper(depictr_palette(8)))
})

test_that("palette_preview() label colour is chosen against the SHOWN tile", {
  # WCAG-luminance label choice must use the simulated tile, so labels stay
  # legible after CVD recolouring too.
  built <- ggplot2::ggplot_build(palette_preview(8, cvd = "tritan"))
  layers <- built$data
  fills <- layers[[1]]$fill                       # shown (simulated) tiles
  text_layer <- layers[[length(layers)]]
  expect_true(all(text_layer$colour %in% c("grey10", "white")))
  expected <- ifelse(.relative_luminance(fills) > 0.4, "grey10", "white")
  expect_identical(text_layer$colour, expected)
})

# --- (b) global options -----------------------------------------------------

test_that("depictr_options() returns defaults when nothing is set", {
  # Guard: ensure no option leaks in from another test.
  old <- options(depictr.base_size = NULL, depictr.brand = NULL,
                 depictr.accent = NULL, depictr.reference = NULL,
                 depictr.palette = NULL, depictr.na_value = NULL,
                 depictr.base_family = NULL)
  on.exit(options(old), add = TRUE)

  cur <- depictr_options()
  expect_equal(cur$base_size, 11)
  expect_identical(cur$brand, "#005b96")
  expect_identical(cur$accent, "#d55e00")
  expect_identical(cur$reference, "grey60")
  expect_null(cur$palette)
  expect_identical(cur$na_value, "grey80")

  # Accessors agree with the resolved defaults.
  expect_identical(depictr_brand(), "#005b96")
  expect_identical(depictr_accent(), "#d55e00")
  expect_identical(depictr_reference(), "grey60")
})

test_that("setting options flows into accessors, palette, scales and theme", {
  old <- depictr_options(base_size = 18, brand = "#111111", accent = "#e69f00",
                         reference = "black",
                         palette = c("#1b9e77", "#d95f02", "#7570b3"),
                         na_value = "#cccccc")
  on.exit(do.call(depictr_options, old), add = TRUE)

  # Accessors
  expect_identical(depictr_brand(), "#111111")
  expect_identical(depictr_accent(), "#e69f00")
  expect_identical(depictr_reference(), "black")

  # Palette (qualitative honours the custom set; ramps are unaffected)
  expect_identical(depictr_palette(3), c("#1b9e77", "#d95f02", "#7570b3"))
  expect_length(depictr_palette(5), 5)             # interpolated beyond 3
  expect_length(depictr_palette(7, type = "sequential"), 7)

  # Theme base size + brand-coloured title
  th <- theme_depictr()
  expect_equal(th$text$size, 18)
  expect_identical(th$plot.title$colour, "#111111")

  # Scales pick up the custom palette and na.value
  b <- ggplot2::ggplot_build(
    ggplot2::ggplot(data.frame(g = factor(letters[1:3]), v = 1:3),
                    ggplot2::aes(g, v, fill = g)) +
      ggplot2::geom_col() + scale_fill_depictr())
  expect_setequal(unique(b$data[[1]]$fill),
                  c("#1b9e77", "#d95f02", "#7570b3"))
  expect_identical(scale_colour_depictr()$na.value, "#cccccc")
})

test_that("depictr_options() restores defaults when cleared with NULL", {
  old <- depictr_options(brand = "#abcdef", base_size = 22,
                         palette = c("#000000", "#ffffff"))
  expect_identical(depictr_brand(), "#abcdef")
  expect_identical(depictr_palette(2), c("#000000", "#ffffff"))

  # Restoring with the snapshot (which carries NULL for palette) must clear it.
  do.call(depictr_options, old)
  expect_identical(depictr_brand(), "#005b96")
  expect_equal(theme_depictr()$text$size, 11)
  expect_identical(depictr_palette(3), c("#005b96", "#e69f00", "#009e73"))
  expect_null(depictr_options()$palette)
})

test_that("depictr_options() validates its inputs", {
  expect_error(depictr_options(base_size = -1), "positive")
  expect_error(depictr_options(base_size = "big"), "number")
  expect_error(depictr_options(brand = "notacolour"), "valid colour")
  expect_error(depictr_options(palette = c("#005b96", "nope")), "valid colours")
})

test_that("unset options leave Tier-2 default behaviour untouched", {
  # With no options set, every Tier-2 contract still holds.
  old <- options(depictr.base_size = NULL, depictr.brand = NULL,
                 depictr.accent = NULL, depictr.reference = NULL,
                 depictr.palette = NULL, depictr.na_value = NULL)
  on.exit(options(old), add = TRUE)

  expect_identical(depictr_brand(), depictr_palette(1)[1])
  expect_identical(scale_colour_depictr()$na.value, "grey80")
  expect_identical(theme_depictr()$plot.title$colour, "#005b96")
  expect_equal(theme_depictr()$text$size, 11)
  expect_identical(
    depictr_palette(),
    c("#005b96", "#e69f00", "#009e73", "#d55e00", "#cc79a7",
      "#56b4e9", "#f0e442", "#999999")
  )
})
