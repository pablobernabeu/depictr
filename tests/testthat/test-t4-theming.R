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

test_that("partial severities use Machado et al.'s tabulated matrices", {
  # Machado et al. publish a matrix for every tenth of severity. Interpolating
  # from the identity to the severity-1 matrix gave a protan 0.5 first row of
  # 0.576143, 0.526292 and -0.102434 instead of the published one below.
  expect_equal(.cvd_matrix("protan", 0.5)[1, ],
               c(0.458064, 0.679578, -0.137642))
  expect_equal(.cvd_matrix("deutan", 0.5)[1, ],
               c(0.547494, 0.607765, -0.155259))
  expect_equal(.cvd_matrix("tritan", 0.5)[1, ],
               c(1.017277, 0.027029, -0.044306))
  # Between two tenths, the transform lies on the line between their matrices.
  tab <- .cvd_matrices_by_severity$deutan
  expect_equal(.cvd_matrix("deutan", 0.25), (tab[[3]] + tab[[4]]) / 2)
  for (tp in names(.cvd_matrices)) {
    m <- .cvd_matrices_by_severity[[tp]]
    expect_length(m, 11)
    # Severity zero is normal vision, and full severity keeps the matrices the
    # safety checks have always used, bit for bit.
    expect_identical(m[[1]], diag(3))
    expect_identical(m[[11]], .cvd_matrices[[tp]])
    expect_identical(.cvd_matrix(tp, 1), .cvd_matrices[[tp]])
    expect_identical(.cvd_matrix(tp, 0), diag(3))
    # Every published matrix maps a grey to itself, up to the six decimals the
    # table is printed to, which catches a mistyped entry.
    for (k in seq_along(m)) {
      expect_equal(unname(rowSums(m[[k]])), c(1, 1, 1), tolerance = 1e-5,
                   info = paste(tp, k - 1))
    }
  }
})

test_that("the tabulated matrices are those colorspace transcribed", {
  # colorspace and Python's colorspacious copied the same table from Machado
  # et al.'s supplementary page, and agree with each other entry for entry.
  skip_if_not_installed("colorspace")
  theirs <- list(protan = colorspace::protanomaly_cvd,
                 deutan = colorspace::deutanomaly_cvd,
                 tritan = colorspace::tritanomaly_cvd)
  for (tp in names(theirs)) {
    for (k in 0:10) {
      expect_identical(.cvd_matrices_by_severity[[tp]][[k + 1]],
                       unname(theirs[[tp]][[as.character(k)]]),
                       info = paste(tp, k))
    }
  }
})

test_that("simulate_cvd() at partial severity matches colorspace", {
  # colorspace interpolates linearly between the two neighbouring tenths, so
  # 0.25 and 0.75 test the interpolation and 0.3, 0.5 and 0.7 the table.
  skip_if_not_installed("colorspace")
  pal <- depictr_palette()
  # Each of the three tables, and the interpolation between them, is checked on
  # colours spread over the gamut as well as on the palette.
  pal <- c(pal, "#ff0000", "#00ff00", "#0000ff", "#3366cc", "#7f3f00",
           "#00ffff", "#ff00ff", "#202020")
  for (s in c(0.25, 0.3, 0.5, 0.7, 0.75)) {
    for (tp in c("protan", "deutan", "tritan")) {
      theirs <- tolower(switch(
        tp,
        protan = colorspace::protan(pal, severity = s),
        deutan = colorspace::deutan(pal, severity = s),
        tritan = colorspace::tritan(pal, severity = s)
      ))
      expect_identical(simulate_cvd(pal, tp, severity = s), theirs,
                       info = paste(tp, s))
    }
  }
})

test_that("simulate_cvd() at partial severity gives the twins' shared golden", {
  # The default palette's colours, simulated by this package and identical to
  # colorspace's. The Python suite pins the same colours, so the twins are held
  # to them where neither colorspace nor colorspacious is installed.
  okabe_ito <- c("#005b96", "#e69f00", "#009e73", "#d55e00", "#cc79a7",
                 "#56b4e9", "#f0e442", "#999999")
  golden <- list(
    "protan@0.25" = c("#235b97", "#d7a200", "#629873", "#bb6900", "#b482a7",
                      "#75b2ea", "#f4e13c", "#999999"),
    "deutan@0.25" = c("#1a5896", "#daa700", "#5e9574", "#bf7200", "#b686a6",
                      "#70aee9", "#f5e345", "#999999"),
    "tritan@0.25" = c("#0d5c8f", "#e2a042", "#389b79", "#ce632a", "#c57ea3",
                      "#60b4e2", "#f2e26e", "#999999"),
    "protan@0.5" = c("#305c97", "#cba300", "#7e9573", "#a66e00", "#a087a7",
                     "#87b2ea", "#f6df35", "#999999"),
    "deutan@0.5" = c("#225695", "#d2ac04", "#768f75", "#b07e00", "#a78fa6",
                     "#7caae9", "#f8e348", "#999999"),
    "tritan@0.5" = c("#005f8a", "#e99b55", "#059d7f", "#d75a32", "#cc7b9d",
                     "#4bb7dd", "#f4df86", "#999999"),
    "protan@0.75" = c("#385d98", "#c2a300", "#8f9372", "#937000", "#8f89a8",
                      "#92b2eb", "#f7de2d", "#999999"),
    "deutan@0.75" = c("#265495", "#cdb00a", "#828a76", "#a58600", "#9c94a5",
                      "#83a7e8", "#fae34b", "#999999"),
    "tritan@0.75" = c("#006580", "#f7916e", "#00a089", "#e7483e", "#d77694",
                      "#00bed3", "#fbdaa5", "#999999")
  )
  for (key in names(golden)) {
    parts <- strsplit(key, "@", fixed = TRUE)[[1]]
    expect_identical(
      simulate_cvd(okabe_ito, parts[1], severity = as.numeric(parts[2])),
      golden[[key]], info = key
    )
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
  # For every vision type, no two palette colours may collapse together. The
  # worst case is the reddish purple against the grey under deuteranopia, at
  # 6.43 in CIEDE2000 against the threshold of 5. The Python suite pins the
  # same four minima.
  report <- palette_safety()
  saf <- report$by_condition
  expect_named(saf, c("normal", "protan", "deutan", "tritan"))
  expect_equal(saf, c(normal = 21.25, protan = 13.44, deutan = 6.43,
                      tritan = 11.13))
  expect_true(report$safe)
  expect_identical(report$worst_condition, "deutan")
  expect_identical(report$worst_pair, c("#cc79a7", "#999999"))
  expect_equal(report$min_delta_e, 6.43)
  expect_true(all(saf > 5),
              info = paste("min CVD distances:",
                           paste(round(saf, 2), collapse = ", ")))
  # The 1976 distance put the same pair 7.4 apart.
  expect_equal(palette_safety(metric = "cie76")$min_delta_e, 7.4)

  # Cross-check the Lab conversion with an independent computation: the
  # minimum pairwise CIE76 distance computed directly from col2rgb -> XYZ ->
  # Lab. CIEDE2000 is computed from the same Lab values, and its formula is
  # checked against Sharma, Wu and Dalal's published pairs.
  cie76 <- palette_safety(metric = "cie76")$by_condition
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
    expect_equal(cie76[[tp]], round(independent_min(seen), 2),
                 tolerance = 1e-3)
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
  # Nine colours fail too, and nine is where the warning starts. The 1976
  # distance passed them, at 5.84.
  nine <- suppressWarnings(depictr_palette(9))
  expect_false(palette_safety(nine)$safe)
  expect_true(palette_safety(nine, metric = "cie76")$safe)
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

# --- the contrast-first order -------------------------------------------------

# Pinned identically in the Python twin's tests/test_palette_cvd.py.
contrast_first <- c("#005b96", "#d55e00", "#cc79a7", "#009e73",
                    "#e69f00", "#56b4e9", "#f0e442", "#999999")

test_that("depictr_palette(order = \"contrast\") puts the darker colours first", {
  old <- options(depictr.palette = NULL, depictr.accent = NULL)
  on.exit(options(old), add = TRUE)

  expect_identical(depictr_palette(order = "contrast"), contrast_first)
  expect_identical(depictr_palette(3, order = "contrast"), contrast_first[1:3])
  # The same eight colours, so the guarantee about the set still holds, and the
  # default order is unchanged.
  expect_setequal(depictr_palette(order = "contrast"), depictr_palette())
  expect_identical(depictr_palette(order = "default"), depictr_palette())
  expect_identical(depictr_palette(3), c("#005b96", "#e69f00", "#009e73"))

  # The figures the documentation quotes. Three colours stay 14.01 apart in
  # CIEDE2000 under every vision type and 6.86 apart in lightness, and the
  # first four clear 3:1 against white, which the fifth does not.
  expect_equal(palette_safety(contrast_first[1:3])$min_delta_e, 14.01)
  lightness <- sort(.srgb_to_lab(contrast_first[1:3])[, 1])
  expect_equal(round(min(diff(lightness)), 2), 6.86)
  ratios <- .contrast_ratio(contrast_first, "#ffffff")
  expect_true(all(ratios[1:4] >= 3))
  expect_lt(ratios[5], 3)

  # Under this order the accent is the second group's colour.
  expect_identical(depictr_palette(2, order = "contrast")[2], depictr_accent())
})

test_that("the contrast-first order warns past four colours", {
  old <- options(depictr.palette = NULL)
  on.exit(options(old), add = TRUE)

  expect_no_warning(depictr_palette(4, order = "contrast"))
  # The whole set, as handed to depictr_options(), names no number of groups.
  expect_no_warning(depictr_palette(order = "contrast"))
  expect_warning(
    pal <- depictr_palette(5, order = "contrast"),
    paste0("^Past four colours the contrast-first order no longer keeps every ",
           "colour at 3:1 against white\\.$")
  )
  expect_identical(pal, contrast_first[1:5])
})

test_that("only the built-in qualitative palette takes an order", {
  expect_error(depictr_palette(5, type = "sequential", order = "contrast"),
               paste0("^`order` applies to the qualitative palette, not to ",
                      "the sequential ramp\\.$"))
  expect_error(depictr_palette(type = "diverging", order = "contrast"),
               paste0("^`order` applies to the qualitative palette, not to ",
                      "the diverging ramp\\.$"))
  expect_no_error(depictr_palette(5, type = "sequential", order = "default"))
  expect_error(depictr_palette(3, order = "brightest"), "should be one of")

  # A palette set through the option is the user's own, so it comes back in
  # the order it was set.
  old <- depictr_options(palette = c("#1b9e77", "#d95f02", "#7570b3"))
  on.exit(do.call(depictr_options, old), add = TRUE)
  expect_warning(
    pal <- depictr_palette(3, order = "contrast"),
    paste0("^`order` applies to the built-in palette, so the depictr\\.palette ",
           "option is returned as it was set\\.$")
  )
  expect_identical(pal, c("#1b9e77", "#d95f02", "#7570b3"))
})

test_that("the depictr scales take the contrast-first order", {
  old <- options(depictr.palette = NULL)
  on.exit(options(old), add = TRUE)

  three <- data.frame(g = factor(letters[1:3]), v = 1:3)
  built <- ggplot2::ggplot_build(
    ggplot2::ggplot(three, ggplot2::aes(g, v, colour = g, fill = g)) +
      ggplot2::geom_col() +
      scale_colour_depictr(order = "contrast") +
      scale_fill_depictr(order = "contrast")
  )
  expect_identical(built$data[[1]]$colour, contrast_first[1:3])
  expect_identical(built$data[[1]]$fill, contrast_first[1:3])

  # Past four groups the warning comes when the plot is built, as it does past
  # eight.
  five <- data.frame(g = factor(letters[1:5]), v = 1:5)
  p <- ggplot2::ggplot(five, ggplot2::aes(g, v, colour = g)) +
    ggplot2::geom_point() + scale_colour_depictr(order = "contrast")
  expect_warning(ggplot2::ggplot_build(p), "^Past four colours")

  # A palette of one's own already fixes the colours and their order.
  expect_error(
    scale_fill_depictr(palette = function(k) rep("#000000", k),
                       order = "contrast"),
    "^Give `palette` or `order = \"contrast\"`, not both\\.$"
  )
  expect_error(scale_colour_depictr(order = "brightest"), "should be one of")

  # The global route the documentation gives: the reordered set as the
  # palette option.
  old_pal <- depictr_options(palette = depictr_palette(order = "contrast"))
  on.exit(do.call(depictr_options, old_pal), add = TRUE)
  expect_identical(depictr_palette(3), contrast_first[1:3])
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
  # The label is chosen against the simulated tile, so that it stays legible
  # after CVD recolouring too.
  for (cv in c("deutan", "protan", "tritan")) {
    built <- ggplot2::ggplot_build(palette_preview(8, cvd = cv))
    layers <- built$data
    fills <- layers[[1]]$fill                       # shown (simulated) tiles
    text_layer <- layers[[length(layers)]]
    black <- .contrast_ratio("#000000", fills)
    white <- .contrast_ratio("#ffffff", fills)
    expect_identical(text_layer$colour,
                     ifelse(black >= white, "#000000", "#ffffff"))
    expect_true(all(.contrast_ratio(text_layer$colour, fills) >= 4.5))
  }
  # Under protanopia the vermillion is shown as an olive that takes white,
  # where the true colour would take black, so a rule read off the true
  # colours fails the loop above.
  built <- ggplot2::ggplot_build(palette_preview(8, cvd = "protan"))
  text_layer <- built$data[[length(built$data)]]
  expect_identical(text_layer$colour[text_layer$label == "#d55e00"], "#ffffff")
  expect_identical(.legible_text_colour("#d55e00"), "#000000")
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
