# data-raw/make_logo.R
# Generate the package hex logo (man/figures/logo.png) using only ggplot2,
# so it can be regenerated without extra dependencies.

library(ggplot2)

# Hexagon vertices
hex <- function(r = 1) {
  ang <- seq(30, 390, by = 60) * pi / 180
  data.frame(x = r * cos(ang), y = r * sin(ang))
}
h  <- hex(1)
hi <- hex(0.93)

# A small forest-plot motif inside the hex
set.seed(7)
motif <- data.frame(
  y = c(0.45, 0.15, -0.15, -0.45),
  est = c(0.35, -0.18, 0.12, -0.30),
  lo  = c(0.10, -0.40, -0.08, -0.52),
  hi  = c(0.60, 0.04, 0.34, -0.08)
)

motif$y <- motif$y * 0.7 + 0.18    # lift the motif to leave room for text

p <- ggplot() +
  geom_polygon(data = h,  aes(x, y), fill = "#0a3d62", colour = NA) +
  geom_polygon(data = hi, aes(x, y), fill = "#005b96", colour = NA) +
  annotate("segment", x = 0, xend = 0, y = -0.12, yend = 0.55,
           colour = "#9fc3df", linewidth = 0.3) +
  geom_errorbarh(data = motif, aes(y = y, xmin = lo, xmax = hi),
                 height = 0.06, colour = "#ff7474", linewidth = 0.7) +
  geom_point(data = motif, aes(x = est, y = y),
             colour = "white", size = 1.7) +
  annotate("text", x = 0, y = -0.55, label = "statviz",
           colour = "white", fontface = "bold", size = 5.1) +
  coord_fixed(xlim = c(-1, 1), ylim = c(-1, 1)) +
  theme_void()

dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)
ggsave("man/figures/logo.png", p, width = 1.8, height = 1.8,
       dpi = 300, bg = "transparent")
message("Logo written to man/figures/logo.png")
