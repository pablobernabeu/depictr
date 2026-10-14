# simulate_figure(): a finished figure as a reader with a CVD sees it -------

# Every grob of class `cls` in a grob tree, depth first. A gtable keeps its
# grobs in `grobs`, and any other gTree in `children`.
grobs_of_class <- function(g, cls) {
  found <- if (inherits(g, cls)) list(g) else list()
  for (child in c(g$grobs, g$children)) {
    found <- c(found, grobs_of_class(child, cls))
  }
  found
}

# The line colours of every grob of class `cls` in a grob tree.
line_colours <- function(g, cls) {
  unlist(lapply(grobs_of_class(g, cls), function(x) x$gp$col))
}

# The grob a gtable lays out under `name`, and the legend, which ggplot2 puts in
# one of several guide boxes.
laid_out <- function(gt, name) gt$grobs[[match(name, gt$layout$name)]]
legend_box <- function(gt) {
  boxes <- gt$grobs[grepl("^guide-box", gt$layout$name)]
  boxes[vapply(boxes, inherits, logical(1), "gtable")][[1]]
}

# What simulate_cvd() makes of each colour, with its alpha written after it as
# ggplot2 writes it, in hexadecimal. An opaque colour carries no alpha.
simulated_with_alpha <- function(colours, deficiency, severity = 1) {
  rgba <- grDevices::col2rgb(colours, alpha = TRUE)
  seen <- simulate_cvd(colours, deficiency, severity)
  ifelse(rgba[4, ] == 255, seen, paste0(seen, sprintf("%02x", rgba[4, ])))
}

grouped <- function() {
  ggplot2::ggplot(crop_yield, ggplot2::aes(rainfall, yield,
                                           colour = treatment)) +
    ggplot2::geom_point(alpha = 0.6) +
    ggplot2::labs(title = "Yield by rainfall") +
    scale_colour_depictr() +
    theme_depictr()
}

test_that("simulate_figure() recolours the points and the legend keys alike", {
  withr::local_pdf(NULL)
  p <- grouped()
  before <- ggplot2::ggplotGrob(p)
  for (tp in c("protan", "deutan", "tritan")) {
    after <- simulate_figure(p, tp)
    expect_s3_class(after, "gtable")
    expect_identical(after$layout, before$layout)
    # Recolouring the data before the plot is built would leave the legend
    # keys in the original colours, so both are checked.
    for (part in list(function(gt) laid_out(gt, "panel"), legend_box)) {
      was <- line_colours(part(before), "points")
      expect_true(length(was) > 0)
      expect_identical(tolower(line_colours(part(after), "points")),
                       simulated_with_alpha(was, tp), info = tp)
    }
    # Text is recoloured too: the title is drawn in the brand blue.
    expect_identical(line_colours(laid_out(after, "title"), "text"),
                     simulate_cvd(depictr_brand(), tp))
  }
  # The two keys show the two simulated palette colours at the points' alpha
  # of 0.6, which is 0x99.
  keys <- line_colours(legend_box(simulate_figure(p, "deutan")), "points")
  expect_identical(keys, paste0(simulate_cvd(depictr_palette(2), "deutan"),
                                "99"))
})

test_that("simulate_figure() follows simulate_cvd() at partial severity", {
  withr::local_pdf(NULL)
  p <- grouped()
  was <- line_colours(legend_box(ggplot2::ggplotGrob(p)), "points")
  for (s in c(0.25, 0.5)) {
    seen <- line_colours(legend_box(simulate_figure(p, "protan", s)), "points")
    expect_identical(seen, simulated_with_alpha(was, "protan", s))
  }
  # At severity zero the colours are those drawn, written as lower-case hex.
  seen <- line_colours(legend_box(simulate_figure(p, "tritan", 0)), "points")
  expect_identical(seen, tolower(was))
})

test_that("simulate_figure() recolours a colourbar", {
  withr::local_pdf(NULL)
  p <- ggplot2::ggplot(crop_yield, ggplot2::aes(rainfall, yield,
                                                colour = fertiliser)) +
    ggplot2::geom_point() +
    ggplot2::scale_colour_viridis_c()
  bar <- function(gt) grobs_of_class(legend_box(gt), "rastergrob")[[1]]$raster
  was <- bar(ggplot2::ggplotGrob(p))
  seen <- bar(simulate_figure(p, "deutan"))
  expect_s3_class(seen, "raster")
  expect_identical(dim(seen), dim(was))
  expect_false(identical(as.vector(as.matrix(seen)),
                         as.vector(as.matrix(was))))
  expect_identical(as.vector(as.matrix(seen)),
                   simulated_with_alpha(as.vector(as.matrix(was)), "deutan"))
})

test_that("simulate_figure() recolours an image drawn in the plot", {
  withr::local_pdf(NULL)
  image <- matrix(c("#ff0000", "#00ff00", "#0000ff80", NA), nrow = 2)
  p <- ggplot2::ggplot() +
    ggplot2::annotation_raster(image, 0, 1, 0, 1) +
    ggplot2::coord_cartesian(xlim = c(0, 1), ylim = c(0, 1))
  drawn <- grobs_of_class(simulate_figure(p, "protan"), "rastergrob")
  expect_length(drawn, 1)
  cells <- as.matrix(drawn[[1]]$raster)
  expect_identical(dim(cells), c(2L, 2L))
  expect_identical(cells[1:3], simulated_with_alpha(image[1:3], "protan"))
  expect_true(is.na(cells[4]))
})

test_that("a native raster is read in its own layout before it is recoloured", {
  # A nativeRaster, as png::readPNG(native = TRUE) returns one, packs each
  # pixel into one integer, red in the lowest byte and alpha in the highest,
  # and stores the rows one after another.
  pack <- function(r, g, b, a) {
    u <- r + g * 256 + b * 65536 + a * 16777216
    as.integer(ifelse(u >= 2^31, u - 2^32, u))
  }
  native <- structure(
    pack(c(255, 0, 0, 255, 0, 0), c(0, 255, 0, 255, 0, 255),
         c(0, 0, 255, 255, 0, 255), c(255, 255, 255, 255, 255, 128)),
    dim = c(2L, 3L), class = "nativeRaster", channels = 4L
  )
  cells <- as.matrix(.simulate_raster(native, .cvd_matrix("deutan", 1)))
  colours <- matrix(c("#ff0000", "#00ff00", "#0000ff",
                      "#ffffff", "#000000", "#00ffff80"),
                    nrow = 2, byrow = TRUE)
  expect_identical(cells,
                   matrix(simulated_with_alpha(colours, "deutan"), nrow = 2))
})

test_that("missing, transparent and pattern colours are left as they are", {
  gradient <- grid::linearGradient(c("#ff0000", "#00ff00"))
  tree <- grid::gTree(name = "tree", children = grid::gList(
    grid::rectGrob(name = "clear",
                   gp = grid::gpar(col = NA, fill = "transparent")),
    grid::rectGrob(name = "graded",
                   gp = grid::gpar(col = c("#ff0000", NA, "NA"),
                                   fill = gradient))
  ))
  out <- .simulate_grob(tree, .cvd_matrix("deutan", 1))
  expect_identical(out$children$clear$gp, tree$children$clear$gp)
  expect_identical(out$children$graded$gp$fill, tree$children$graded$gp$fill)
  expect_identical(out$children$graded$gp$col,
                   c(simulate_cvd("#ff0000", "deutan"), NA, "NA"))
  expect_identical(names(out$children), names(tree$children))
  expect_identical(out$childrenOrder, tree$childrenOrder)
})

test_that("simulate_figure() takes a patchwork, panel by panel", {
  withr::local_pdf(NULL)
  scatter <- grouped()
  bars <- ggplot2::ggplot(crop_yield, ggplot2::aes(treatment,
                                                   fill = treatment)) +
    ggplot2::geom_bar() +
    scale_fill_depictr() +
    theme_depictr()
  composite <- arrange_plots(scatter, bars, guides = "keep")
  before <- patchwork::patchworkGrob(composite)
  after <- simulate_figure(composite, "deutan")
  expect_s3_class(after, "gtable")
  was <- line_colours(before, "points")
  expect_identical(tolower(line_colours(after, "points")),
                   simulated_with_alpha(was, "deutan"))
  fills <- function(gt) {
    unlist(lapply(grobs_of_class(gt, "rect"), function(x) {
      if (is.character(x$gp$fill)) x$gp$fill
    }))
  }
  expect_true(all(simulate_cvd(depictr_palette(2), "deutan") %in%
                    tolower(fills(after))))
})

test_that("the simulated figure can be drawn and saved", {
  withr::local_pdf(NULL)
  seen <- simulate_figure(grouped(), "deutan")
  expect_no_error(grid::grid.draw(seen))
  path <- withr::local_tempfile(fileext = ".png")
  expect_no_error(save_plot(path, seen, width = 4, height = 3, dpi = 72))
  expect_true(file.exists(path))
})

test_that("simulate_figure() refuses what it cannot simulate", {
  withr::local_pdf(NULL)
  p <- grouped()
  expect_error(simulate_figure(p, "normal"),
               "`deficiency` must be one of 'protan', 'deutan' or 'tritan'.",
               fixed = TRUE)
  expect_error(simulate_figure(p, "deutan", severity = 1.5),
               "`severity` must lie in [0, 1].", fixed = TRUE)
  for (not_a_plot in list(ggplot2::ggplotGrob(p), 1:3, NULL)) {
    expect_error(simulate_figure(not_a_plot, "deutan"),
                 "`plot` must be a ggplot or a patchwork.", fixed = TRUE)
  }
})
