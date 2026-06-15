# Tier-4 model-comparison toolkit for the classification curves --------------
# Covers: the named-list (multi-model) overlay path with per-curve AUC/AP and a
# legend; bootstrap CI bands on the ROC; Youden-J and max-F1 operating points
# verified against an independent brute-force argmax; confusion_matrix_plot()
# reusing the Youden threshold; the new threshold_plot(); and backward
# compatibility of every single-model call.

# A small, well-separated binary problem reused across the plot tests.
make_glm <- function(n = 250, seed = 1) {
  withr::local_seed(seed)
  x <- rnorm(n)
  y <- factor(ifelse(plogis(1.2 * x) > runif(n), "yes", "no"))
  glm(y ~ x, data = data.frame(x = x, y = y), family = binomial)
}

# Independent brute-force confusion-matrix metrics at a given threshold.
cm_metrics <- function(actual, score, thr) {
  pred <- score >= thr
  tp <- sum(pred & actual == 1)
  fp <- sum(pred & actual == 0)
  fn <- sum(!pred & actual == 1)
  tn <- sum(!pred & actual == 0)
  sens <- tp / (tp + fn)
  spec <- tn / (tn + fp)
  prec <- if (tp + fp > 0) tp / (tp + fp) else NA_real_
  f1 <- if (!is.na(prec) && prec + sens > 0)
    2 * prec * sens / (prec + sens) else 0
  c(sensitivity = sens, specificity = spec, precision = prec, f1 = f1,
    j = sens + spec - 1)
}

# ---- backward compatibility ------------------------------------------------

test_that("single-model calls are unchanged and build without warnings", {
  g <- make_glm()
  plots <- list(
    roc_curve_plot(g), pr_curve_plot(g), gain_plot(g), lift_plot(g),
    calibration_plot(g, bins = 6), confusion_matrix_plot(g, threshold = 0.5)
  )
  for (p in plots) {
    expect_s3_class(p, "ggplot")
    expect_no_warning(ggplot2::ggplot_build(p))
  }
  # AUC / AP attributes are still scalars in the single-model case.
  expect_length(attr(roc_curve_plot(g), "auc"), 1L)
  expect_null(names(attr(roc_curve_plot(g), "auc")))
  expect_length(attr(pr_curve_plot(g), "average_precision"), 1L)
})

# ---- multi-model overlay ---------------------------------------------------

test_that("a named list overlays colour-coded curves with per-curve AUC/AP", {
  withr::local_seed(2)
  n <- 300
  x1 <- rnorm(n); x2 <- rnorm(n)
  y <- rbinom(n, 1, plogis(0.9 * x1 + 0.5 * x2))
  fit_full <- glm(y ~ x1 + x2, family = binomial)
  fit_red  <- glm(y ~ x1, family = binomial)

  p <- roc_curve_plot(list(Full = fit_full, Reduced = fit_red))
  b <- ggplot2::ggplot_build(p)

  # Two distinct curve colours from the depictr qualitative palette.
  line_layer <- b$data[[2]]
  cols <- unique(line_layer$colour)
  expect_length(cols, 2L)
  expect_true(all(toupper(cols) %in% toupper(depictr_palette(2))))

  # AUC attribute is a named vector, one per model.
  auc <- attr(p, "auc")
  expect_named(auc, c("Full", "Reduced"))
  # The richer model should not be worse here.
  expect_gte(auc[["Full"]], auc[["Reduced"]] - 1e-8)

  # PR overlay yields a named average-precision vector.
  ap <- attr(pr_curve_plot(list(Full = fit_full, Reduced = fit_red)),
             "average_precision")
  expect_named(ap, c("Full", "Reduced"))

  # gain / lift / calibration overlays build without warnings.
  for (p2 in list(gain_plot(list(Full = fit_full, Reduced = fit_red)),
                  lift_plot(list(Full = fit_full, Reduced = fit_red)),
                  calibration_plot(list(Full = fit_full, Reduced = fit_red),
                                   bins = 6))) {
    expect_no_warning(ggplot2::ggplot_build(p2))
  }
})

test_that("per-curve AUC equals the Mann-Whitney statistic for each model", {
  g1 <- make_glm(seed = 3)
  g2 <- make_glm(seed = 4)
  p <- roc_curve_plot(list(A = g1, B = g2))
  auc <- attr(p, "auc")
  for (nm in c("A", "B")) {
    g <- if (nm == "A") g1 else g2
    a <- as.integer(g$y); s <- stats::fitted(g)
    W <- suppressWarnings(stats::wilcox.test(s[a == 1], s[a == 0])$statistic)
    mw <- as.numeric(W) / (sum(a == 1) * sum(a == 0))
    expect_equal(unname(auc[[nm]]), mw, tolerance = 1e-10)
  }
})

test_that("(actual, score) pair lists and outcome+score lists both work", {
  g <- make_glm(seed = 5)
  a <- as.integer(g$y); s <- stats::fitted(g)
  s2 <- jitter(s, amount = 0.05)

  p_pairs <- roc_curve_plot(list(A = list(actual = a, score = s),
                                 B = data.frame(actual = a, score = s2)))
  p_vlist <- roc_curve_plot(list(A = a, B = a), score = list(s, s2))

  expect_equal(unname(attr(p_pairs, "auc")["A"]),
               unname(attr(p_vlist, "auc")["A"]))
  expect_named(attr(p_pairs, "auc"), c("A", "B"))
})

test_that("multi-model overlay requires a uniquely named list", {
  g <- make_glm()
  expect_error(roc_curve_plot(list(g, g)), "named")
  expect_error(roc_curve_plot(list(A = g, A = g)), "unique")
  expect_error(roc_curve_plot(list()), "empty")
})

# ---- Youden's J ------------------------------------------------------------

test_that("Youden point equals the brute-force argmax of sensitivity+specificity-1", {
  g <- make_glm(seed = 6)
  a <- as.integer(g$y); s <- stats::fitted(g)

  p <- roc_curve_plot(g, youden = TRUE)
  yp <- attr(p, "youden")

  cands <- sort(unique(s), decreasing = TRUE)
  J <- vapply(cands, function(t) cm_metrics(a, s, t)[["j"]], numeric(1))
  best_t <- cands[which.max(J)]

  expect_equal(yp$threshold, best_t, tolerance = 1e-10)
  expect_equal(yp$j, max(J), tolerance = 1e-10)
  # The marked point lies on the ROC at (1 - specificity, sensitivity).
  m <- cm_metrics(a, s, yp$threshold)
  expect_equal(yp$tpr, m[["sensitivity"]], tolerance = 1e-10)
  expect_equal(yp$fpr, 1 - m[["specificity"]], tolerance = 1e-10)

  # A Youden marker point is actually drawn (accent colour, single point).
  b <- ggplot2::ggplot_build(p)
  pt_layer <- b$data[[which(vapply(b$data,
    function(d) nrow(d) == 1 && "shape" %in% names(d), logical(1)))[1]]]
  expect_equal(unique(pt_layer$colour), depictr_accent())
})

# ---- max F1 ----------------------------------------------------------------

test_that("max-F1 point equals the brute-force argmax of F1", {
  g <- make_glm(seed = 8)
  a <- as.integer(g$y); s <- stats::fitted(g)

  p <- pr_curve_plot(g, f1 = TRUE)
  fp <- attr(p, "max_f1")

  cands <- sort(unique(s), decreasing = TRUE)
  F1 <- vapply(cands, function(t) cm_metrics(a, s, t)[["f1"]], numeric(1))
  best_t <- cands[which.max(F1)]

  expect_equal(fp$threshold, best_t, tolerance = 1e-10)
  expect_equal(fp$f1, max(F1), tolerance = 1e-10)
})

# ---- confusion matrix reuses the Youden threshold --------------------------

test_that("confusion_matrix_plot(threshold = 'youden') reuses the ROC Youden cut-off", {
  g <- make_glm(seed = 9)
  yp <- attr(roc_curve_plot(g, youden = TRUE), "youden")
  pc <- confusion_matrix_plot(g, threshold = "youden")

  expect_equal(attr(pc, "threshold"), yp$threshold, tolerance = 1e-12)

  # Numeric thresholds are recorded too, and invalid strings error.
  expect_equal(attr(confusion_matrix_plot(g, threshold = 0.3), "threshold"), 0.3)
  expect_error(confusion_matrix_plot(g, threshold = "nope"))
})

# ---- bootstrap CI band -----------------------------------------------------

test_that("ROC bootstrap band brackets the point AUC and adds a ribbon", {
  withr::local_seed(10)
  g <- make_glm(n = 300, seed = 10)
  p <- roc_curve_plot(g, ci = 300, conf_level = 0.9)

  ci <- attr(p, "auc_ci")
  auc <- attr(p, "auc")
  expect_named(ci, c("lower", "upper"))
  expect_lte(ci[["lower"]], auc)
  expect_gte(ci[["upper"]], auc)
  expect_gte(ci[["lower"]], 0)
  expect_lte(ci[["upper"]], 1)

  # A ribbon layer (ymin/ymax) is present; ci = FALSE adds none.
  b <- ggplot2::ggplot_build(p)
  has_ribbon <- any(vapply(b$data,
    function(d) all(c("ymin", "ymax") %in% names(d)), logical(1)))
  expect_true(has_ribbon)

  b0 <- ggplot2::ggplot_build(roc_curve_plot(g))
  no_ribbon <- !any(vapply(b0$data,
    function(d) all(c("ymin", "ymax") %in% names(d)), logical(1)))
  expect_true(no_ribbon)
})

# ---- threshold_plot --------------------------------------------------------

test_that("threshold_plot() metric curves match an independent confusion matrix", {
  g <- make_glm(seed = 11)
  a <- as.integer(g$y); s <- stats::fitted(g)

  p <- threshold_plot(g, metrics = c("sensitivity", "specificity",
                                     "precision", "f1"), mark = NULL)
  expect_s3_class(p, "ggplot")
  b <- ggplot2::ggplot_build(p)
  # The line layer carries all four metrics across the distinct thresholds.
  ld <- b$data[[length(b$data)]]

  withr::local_seed(12)
  for (t in sample(sort(unique(s)), 8)) {
    m <- cm_metrics(a, s, t)
    rows <- ld[abs(ld$x - t) < 1e-9, ]
    got <- sort(round(rows$y, 8))
    want <- sort(round(c(m[["sensitivity"]], m[["specificity"]],
                         m[["precision"]], m[["f1"]]), 8))
    expect_equal(got, want, tolerance = 1e-7)
  }

  # The stored optimal thresholds agree with the curve helpers.
  thr <- attr(p, "thresholds")
  expect_equal(thr[["youden"]],
               attr(roc_curve_plot(g, youden = TRUE), "youden")$threshold,
               tolerance = 1e-12)
  expect_equal(thr[["f1"]],
               attr(pr_curve_plot(g, f1 = TRUE), "max_f1")$threshold,
               tolerance = 1e-12)
})

test_that("threshold_plot() honours metric selection and marker options", {
  g <- make_glm(seed = 13)

  # recall is an accepted alias for sensitivity; selecting a subset draws fewer
  # curves (one colour group per metric).
  p <- threshold_plot(g, metrics = c("recall", "specificity"), mark = "youden")
  b <- ggplot2::ggplot_build(p)
  line_layer <- b$data[[length(b$data)]]
  expect_length(unique(line_layer$colour), 2L)

  # Marking adds dashed reference vline(s); mark = NULL adds none.
  has_vline <- function(plot) {
    bb <- ggplot2::ggplot_build(plot)
    any(vapply(bb$data, function(d) "xintercept" %in% names(d), logical(1)))
  }
  expect_true(has_vline(threshold_plot(g, mark = "youden")))
  expect_false(has_vline(threshold_plot(g, mark = NULL)))

  expect_no_warning(ggplot2::ggplot_build(threshold_plot(g)))
})
