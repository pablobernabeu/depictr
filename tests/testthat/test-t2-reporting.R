# Tier-2 reporting changes ---------------------------------------------------

test_that("arrange_plots() title uses the canonical brand colour", {
  p1 <- explore_distribution(crop_yield, yield)
  p2 <- scatter_trend(crop_yield, fertiliser, yield)
  combined <- arrange_plots(p1, p2, ncol = 2, title = "Crop yield",
                            tag_levels = "A")

  # The patchwork annotation theme carries the title colour; it must be the
  # single-source-of-truth brand blue, not a stray hex literal.
  title_col <- combined$patches$annotation$theme$plot.title$colour
  expect_identical(title_col, depictr_brand())
  expect_identical(title_col, "#005b96")
})

test_that(".relative_luminance() is vectorised and matches WCAG anchors", {
  # Pure black and white anchor the [0, 1] range.
  expect_equal(.relative_luminance("#000000"), 0, tolerance = 1e-8)
  expect_equal(.relative_luminance("#ffffff"), 1, tolerance = 1e-8)

  lum <- .relative_luminance(c("#000000", "#ffffff"))
  expect_length(lum, 2)
  expect_true(lum[1] < lum[2])

  # The palette yellow is light; the brand blue is dark.
  expect_gt(.relative_luminance("#f0e442"), 0.4)
  expect_lt(.relative_luminance(depictr_brand()), 0.4)
})

test_that(".legible_text_colour() takes black or white, whichever contrasts more", {
  # Black and white tie against a relative luminance of 0.179, which falls
  # between these two greys, and each reaches 4.58:1 there. The Python twin's
  # _legible_text_colour() pins the same vector.
  okabe_ito <- c("#005b96", "#e69f00", "#009e73", "#d55e00", "#cc79a7",
                 "#56b4e9", "#f0e442", "#999999")
  expect_identical(
    .legible_text_colour(c("#757575", "#767676", okabe_ito)),
    c("#ffffff", "#000000", "#ffffff", rep("#000000", 7))
  )
  # Every colour of a 16-level grid over the three channels.
  levels <- sprintf("%02x", seq(0, 255, by = 17))
  grid <- expand.grid(r = levels, g = levels, b = levels,
                      stringsAsFactors = FALSE)
  fills <- paste0("#", grid$r, grid$g, grid$b)
  chosen <- .legible_text_colour(fills)
  other <- ifelse(chosen == "#000000", "#ffffff", "#000000")
  expect_true(all(.contrast_ratio(chosen, fills) >= .contrast_ratio(other, fills)))
  expect_gte(min(.contrast_ratio(chosen, fills)), 4.58)
})

# Each label's colour and its WCAG contrast against the tile drawn beneath it,
# read back from a built plot, with the contrast the other of black and white
# would have had.
label_contrasts <- function(built, tile_layer = 1,
                            text_layer = length(built$data)) {
  tiles <- built$data[[tile_layer]][, c("PANEL", "x", "y", "fill")]
  texts <- built$data[[text_layer]][, c("PANEL", "x", "y", "colour", "label")]
  cells <- merge(tiles, texts, by = c("PANEL", "x", "y"))
  other <- ifelse(cells$colour == "#000000", "#ffffff", "#000000")
  cells$ratio <- .contrast_ratio(cells$colour, cells$fill)
  cells$other <- .contrast_ratio(other, cells$fill)
  cells
}

test_that("palette_preview() labels are legible on every swatch", {
  # The old rule switched from white to grey10 at a relative luminance of 0.4,
  # although the two tie near 0.2. Four of the eight default swatches therefore
  # had white labels at 2.85 to 3.87:1, where grey10 would have reached 4.50 to
  # 6.11:1.
  for (tp in c("qualitative", "sequential", "diverging")) {
    cells <- label_contrasts(ggplot2::ggplot_build(palette_preview(8, type = tp)))
    expect_identical(nrow(cells), 8L)
    expect_true(all(cells$colour %in% c("#000000", "#ffffff")))
    expect_true(all(cells$ratio >= 4.5))
    expect_true(all(cells$ratio >= cells$other))
  }
  # The pale yellow takes black, the brand blue white.
  cells <- label_contrasts(ggplot2::ggplot_build(palette_preview(8)))
  expect_identical(cells$colour[cells$label == "#f0e442"], "#000000")
  expect_identical(cells$colour[cells$label == "#005b96"], "#ffffff")
})

test_that("palette_preview() builds for every type without warnings", {
  for (tp in c("qualitative", "sequential", "diverging", "all")) {
    expect_no_warning(ggplot2::ggplot_build(palette_preview(6, type = tp)))
  }
})

test_that("arrange_plots() builds without deprecation warnings", {
  p1 <- explore_distribution(crop_yield, yield)
  p2 <- scatter_trend(crop_yield, fertiliser, yield)
  combined <- arrange_plots(p1, p2, title = "T", subtitle = "S")
  # Print to a throwaway device so the default device never opens (a bare
  # print() in a non-interactive session would leave an Rplots.pdf behind).
  withr::local_pdf(NULL)
  expect_no_warning(print(combined))
})

# save_plot(): files that pass journals' technical checks ---------------------

# Whether a file's bytes contain a piece of text, read as bytes so that the
# compressed streams around it do not matter.
file_contains <- function(path, text) {
  bytes <- readBin(path, "raw", file.size(path))
  length(grepRaw(text, bytes, fixed = TRUE)) > 0
}

# One numeric tag of a TIFF's first image directory: 259 is the compression (5
# for LZW) and 277 the samples per pixel (3 for RGB, 4 with an alpha channel).
# The file is parsed from its bytes so that the test needs no image package.
tiff_tag <- function(path, tag) {
  bytes <- readBin(path, "raw", file.size(path))
  endian <- if (identical(rawToChar(bytes[1:2]), "II")) "little" else "big"
  int <- function(at, size) {
    readBin(bytes[at + seq_len(size)], "integer", size = size,
            signed = size == 4, endian = endian)
  }
  ifd <- int(4, 4)
  for (i in seq_len(int(ifd, 2))) {
    entry <- ifd + 2 + 12 * (i - 1)
    if (int(entry, 2) == tag) {
      # A value of type SHORT (3) takes the first two bytes of its field.
      size <- if (int(entry + 2, 2) == 3) 2 else 4
      return(int(entry + 8, size))
    }
  }
  NA_integer_
}

# The tests of what cairo writes need cairo to load. On Linux and macOS,
# capabilities("cairo") says only that R was built with cairo, and R for macOS
# from CRAN loads it only where XQuartz is installed, which GitHub's macOS
# runners lack. What save_plot() writes there instead is tested on every
# platform further down, by taking cairo away.
skip_without_cairo <- function() {
  skip_if_not(.cairo_available(), "cairo cannot be loaded here")
}

# ggsave() compresses a TIFF with ragg wherever ragg is installed, and otherwise
# with the cairo TIFF device on Linux and macOS. Windows compresses with its own
# device, and since R for Windows ships cairo, the check passes there too.
skip_without_tiff_compression <- function() {
  skip_if_not(requireNamespace("ragg", quietly = TRUE) || .cairo_available(),
              "neither ragg nor cairo can compress a TIFF here")
}

test_that("save_plot() embeds the fonts in a PDF", {
  skip_without_cairo()
  f <- withr::local_tempfile(fileext = ".pdf")
  save_plot(f, scatter_trend(crop_yield, fertiliser, yield))
  # pdf() names Helvetica without embedding it. An embedded font is a font
  # program stream, which the font descriptor points to as /FontFile2 (TrueType)
  # or /FontFile3, and Type 3 fonts are the bitmap-like kind journals refuse.
  expect_true(file_contains(f, "/FontFile"))
  expect_false(file_contains(f, "/Type3"))
})

test_that("save_plot() keeps the translucent layers of an EPS and embeds fonts", {
  skip_without_cairo()
  f <- withr::local_tempfile(fileext = ".eps")
  # postscript() drops every element drawn with alpha below 1, here all 200
  # points and the confidence band, and says so only in a warning. cairo_ps()
  # rasterises the area those layers cover, with the trend line drawn over it.
  expect_no_warning(
    expect_message(
      save_plot(f, scatter_trend(crop_yield, fertiliser, yield)),
      "layers, and whatever they overlap, were rasterised at 600 dpi"
    )
  )
  expect_true(file_contains(f, "EPSF-3.0"))
  expect_false(file_contains(f, "%%DocumentNeededResources: font"))
})

test_that("save_plot() says nothing about rasterising an opaque EPS", {
  skip_without_cairo()
  f <- withr::local_tempfile(fileext = ".eps")
  # The smoothing layer carries an alpha but, without its band, draws nothing
  # with it, so nothing in this figure is rasterised.
  opaque <- scatter_trend(crop_yield, fertiliser, yield, se = FALSE,
                          point_alpha = 1)
  expect_no_message(expect_no_warning(save_plot(f, opaque)))
})

test_that("save_plot() notices a translucent panel anywhere in a composite", {
  skip_without_cairo()
  f <- withr::local_tempfile(fileext = ".eps")
  opaque <- scatter_trend(crop_yield, fertiliser, yield, se = FALSE,
                          point_alpha = 1)
  # The translucent panel comes first, so patchwork keeps it among the patches
  # and makes the opaque one the composite's own plot.
  combined <- arrange_plots(scatter_trend(crop_yield, fertiliser, yield),
                            opaque, ncol = 2)
  expect_message(save_plot(f, combined), "rasterised")
})

test_that("save_plot() compresses a TIFF", {
  skip_without_tiff_compression()
  f <- withr::local_tempfile(fileext = ".tiff")
  save_plot(f, scatter_trend(crop_yield, fertiliser, yield))
  # Uncompressed, 7 x 4.5 inches at 300 dpi is 8.1 MiB. PLOS caps a figure at
  # 10 MB, which the uncompressed file exceeds at PLOS's largest figure size.
  expect_lt(file.size(f), 1e6)
  expect_identical(tiff_tag(f, 259), 5L)
})

test_that("save_plot() writes a TIFF without an alpha channel, as PLOS asks", {
  skip_without_tiff_compression()
  f <- withr::local_tempfile(fileext = ".tiff")
  # theme_void() leaves the background transparent, which ragg and the cairo
  # TIFF device keep as a fourth channel. PLOS: "No alpha channels".
  save_plot(f, scatter_trend(crop_yield, fertiliser, yield) +
              ggplot2::theme_void())
  expect_identical(tiff_tag(f, 277), 3L)
})

test_that("a background given to save_plot() reaches ggsave() as given", {
  # Windows' own TIFF device never stores an alpha channel, so the file cannot
  # show that a transparent background was passed on. ggsave() can.
  seen <- list()
  local_mocked_bindings(
    ggsave = function(filename, ..., bg = NULL) seen[[length(seen) + 1]] <<- bg,
    .package = "ggplot2"
  )
  p <- ggplot2::ggplot()
  save_plot(withr::local_tempfile(fileext = ".tiff"), p)
  save_plot(withr::local_tempfile(fileext = ".tiff"), p, bg = "transparent")
  save_plot(withr::local_tempfile(fileext = ".png"), p)
  expect_identical(seen, list("white", "transparent"))
})

test_that("an explicit device or device argument still wins in save_plot()", {
  skip_without_cairo()
  p <- scatter_trend(crop_yield, fertiliser, yield)

  pdf_file <- withr::local_tempfile(fileext = ".pdf")
  expect_no_message(save_plot(pdf_file, p, device = "pdf"))
  expect_false(file_contains(pdf_file, "/FontFile"))

  eps_file <- withr::local_tempfile(fileext = ".eps")
  expect_message(save_plot(eps_file, p, fallback_resolution = 300),
                 "rasterised at 300 dpi")
})

test_that("save_plot() falls back to pdf() and postscript() without cairo", {
  local_mocked_bindings(.cairo_available = function() FALSE)
  p <- scatter_trend(crop_yield, fertiliser, yield)

  pdf_file <- withr::local_tempfile(fileext = ".pdf")
  expect_message(save_plot(pdf_file, p), "embedFonts")
  expect_true(file.exists(pdf_file))
  expect_false(file_contains(pdf_file, "/FontFile"))

  eps_file <- withr::local_tempfile(fileext = ".eps")
  # postscript() raises its own semi-transparency warning, and save_plot() adds
  # one that says what it means for the file.
  expect_warning(
    expect_warning(save_plot(eps_file, p), "leaves out translucent layers"),
    "semi-transparency"
  )
  expect_true(file.exists(eps_file))
})

test_that("save_plot() falls back when the cairo device cannot open", {
  local_mocked_bindings(
    .cairo_available = function() TRUE,
    .open_cairo = function(...) stop("unable to start device")
  )
  f <- withr::local_tempfile(fileext = ".pdf")
  expect_message(save_plot(f, scatter_trend(crop_yield, fertiliser, yield)),
                 "embedFonts")
  expect_true(file.exists(f))
})

test_that("save_plot() falls back when cairo warns and opens no device", {
  # A cairo device whose library will not load fails this way on Linux and
  # macOS. ggsave() would then draw the figure on the caller's device, close
  # that device and write no file.
  local_mocked_bindings(
    .cairo_available = function() TRUE,
    .open_cairo = function(...) warning("failed to load cairo DLL")
  )
  grDevices::postscript(withr::local_tempfile(fileext = ".ps"))
  callers <- grDevices::dev.cur()
  withr::defer(grDevices::dev.off(callers))
  f <- withr::local_tempfile(fileext = ".pdf")
  expect_message(
    expect_warning(save_plot(f, scatter_trend(crop_yield, fertiliser, yield)),
                   "failed to load cairo DLL"),
    "embedFonts"
  )
  expect_true(file.exists(f))
  expect_identical(grDevices::dev.cur(), callers)
})

test_that(".cairo_available() agrees with whether a cairo device opens", {
  # On Linux and macOS, capabilities("cairo") says only that R was built with
  # cairo, and a cairo device whose library will not load warns and opens
  # nothing. Whether one opens is what .cairo_available() has to predict.
  before <- grDevices::dev.cur()
  f <- withr::local_tempfile(fileext = ".pdf")
  suppressWarnings(tryCatch(grDevices::cairo_pdf(f), error = function(e) NULL))
  opens <- !identical(grDevices::dev.cur(), before)
  if (opens) grDevices::dev.off()
  expect_identical(.cairo_available(), opens)
})

test_that("save_plot() writes the PDF and EPS asked for, with cairo or without", {
  # Without cairo, as on a Mac without XQuartz, the files come from pdf() and
  # postscript(), and the tests above check what save_plot() says about them.
  p <- scatter_trend(crop_yield, fertiliser, yield)
  pdf_file <- withr::local_tempfile(fileext = ".pdf")
  eps_file <- withr::local_tempfile(fileext = ".eps")
  suppressWarnings(suppressMessages({
    save_plot(pdf_file, p)
    save_plot(eps_file, p)
  }))
  expect_true(file.exists(pdf_file))
  expect_true(file.exists(eps_file))
})

test_that("a TIFF asks for the cairo type only where quartz would ignore LZW", {
  # ggsave() hands a TIFF to ragg when ragg is installed, and ragg compresses.
  expect_null(.tiff_type(ragg = TRUE, bitmap_type = "quartz", cairo = TRUE))
  expect_identical(
    .tiff_type(ragg = FALSE, bitmap_type = "quartz", cairo = TRUE), "cairo"
  )
  expect_null(.tiff_type(ragg = FALSE, bitmap_type = "cairo", cairo = TRUE))
  expect_null(.tiff_type(ragg = FALSE, bitmap_type = "quartz", cairo = FALSE))
})

test_that("save_plot() reads ggsave()'s named resolutions as numbers", {
  expect_identical(.dpi_number("retina"), 320)
  expect_identical(.dpi_number("print"), 300)
  expect_identical(.dpi_number(150), 150)
})
