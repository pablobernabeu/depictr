# Regression tests for the classification helpers (ROC / PR / gains).
# Covers: order-independent AUC & average precision (tie handling), NA handling
# in as_binary()/binary_inputs(), factor-level safety, and real class names in
# confusion_matrix_plot() for glm inputs.

test_that("AUC is order-independent and equals Mann-Whitney with ties at 0.5", {
  # All-equal scores: AUC must be 0.5 for every row ordering.
  actual <- c(rep(1, 5), rep(0, 5))
  score  <- rep(0.5, 10)
  withr::local_seed(1)
  for (i in 1:5) {
    ord <- sample(length(actual))
    auc <- suppressMessages(
      attr(roc_curve_plot(actual[ord], score[ord]), "auc")
    )
    expect_equal(auc, 0.5)
  }

  # Partially-tied case must match an independent Mann-Whitney computation and
  # be invariant to row order.
  withr::local_seed(42)
  a <- c(rep(1, 12), rep(0, 18))
  s <- round(runif(30), 1)           # rounding induces many ties
  auc <- suppressMessages(attr(roc_curve_plot(a, s), "auc"))
  W <- suppressWarnings(stats::wilcox.test(s[a == 1], s[a == 0])$statistic)
  mw <- as.numeric(W) / (sum(a == 1) * sum(a == 0))
  expect_equal(auc, mw)

  ord <- sample(length(a))
  auc_shuffled <- suppressMessages(attr(roc_curve_plot(a[ord], s[ord]), "auc"))
  expect_equal(auc_shuffled, auc)
})

test_that("average precision and gains are order-independent under ties", {
  withr::local_seed(7)
  a <- c(rep(1, 8), rep(0, 12))
  s <- round(runif(20), 1)
  ap1 <- suppressMessages(attr(pr_curve_plot(a, s), "average_precision"))
  ord <- sample(length(a))
  ap2 <- suppressMessages(attr(pr_curve_plot(a[ord], s[ord]),
                               "average_precision"))
  expect_equal(ap1, ap2)

  g1 <- gain_table(a, s)
  g2 <- gain_table(a[ord], s[ord])
  expect_equal(g1, g2)
  # Tied scores collapse into single steps: fewer rows than observations + 1.
  expect_lt(nrow(g1), length(a) + 1L)
})

test_that("as_binary() tolerates NA and complete cases are dropped pairwise", {
  expect_equal(as_binary(c(0, 1, NA, 1, 0)), c(0L, 1L, NA, 1L, 0L))

  a <- c(0, 1, NA, 1, 0, 1, 0, NA, 1, 0)
  s <- c(0.1, 0.9, 0.5, 0.8, 0.2, 0.7, 0.3, 0.4, 0.6, 0.15)
  io <- suppressMessages(binary_inputs(a, s))
  expect_length(io$actual, 8L)          # two NA outcomes dropped
  expect_false(anyNA(io$actual))
  expect_false(anyNA(io$score))
  expect_message(binary_inputs(a, s), "dropped")

  # A missing score also removes its pair.
  a2 <- c(0, 1, 1, 1, 0, 1, 0, 0, 1, 0)
  s2 <- c(0.1, 0.9, 0.5, 0.8, NA, 0.7, 0.3, 0.4, 0.6, 0.15)
  io2 <- suppressMessages(binary_inputs(a2, s2))
  expect_length(io2$actual, 9L)
})

test_that("as_binary() handles factor levels safely with an explicit positive", {
  # >2 levels is an error, not a silent mislabelling.
  expect_error(
    as_binary(factor(c("a", "b", "c"))),
    "exactly two"
  )

  f <- factor(c("no", "yes", "no", "yes"))
  expect_equal(as_binary(f), c(0L, 1L, 0L, 1L))        # last level positive
  expect_equal(as_binary(f, positive = "no"), c(1L, 0L, 1L, 0L))
  expect_error(as_binary(f, positive = "maybe"), "not a level")
})

test_that("confusion_matrix_plot() keeps the model's real class names", {
  withr::local_seed(1)
  df <- data.frame(
    y = factor(sample(c("no", "yes"), 80, replace = TRUE)),
    x = rnorm(80)
  )
  gfit <- glm(y ~ x, data = df, family = binomial)
  p <- confusion_matrix_plot(gfit, threshold = 0.5)
  expect_setequal(levels(p$data$Actual), c("no", "yes"))
  expect_setequal(levels(p$data$Predicted), c("no", "yes"))
  # The hardcoded 0/1 labels must be gone.
  expect_false(any(c("0", "1") %in% as.character(p$data$Actual)))

  # Logical responses surface as TRUE/FALSE.
  df2 <- data.frame(y = sample(c(TRUE, FALSE), 60, replace = TRUE),
                    x = rnorm(60))
  g2 <- glm(y ~ x, data = df2, family = binomial)
  p2 <- confusion_matrix_plot(g2)
  expect_setequal(levels(p2$data$Actual), c("FALSE", "TRUE"))

  # The multiclass vector path is unaffected.
  expect_s3_class(
    confusion_matrix_plot(c("a", "b", "a"), predicted = c("a", "a", "b")),
    "ggplot"
  )
})
