test_that("pca_plot() works from data frames and prcomp objects", {
  expect_s3_class(
    pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "yield")),
    "ggplot"
  )
  expect_s3_class(
    pca_plot(crop_yield, cols = c("rainfall", "fertiliser", "yield"),
             group = "treatment"),
    "ggplot"
  )
  pc <- prcomp(crop_yield[c("rainfall", "fertiliser", "yield")], scale. = TRUE)
  expect_s3_class(pca_plot(pc), "ggplot")
  expect_error(pca_plot(crop_yield, cols = "yield"), "at least two")
})

test_that("scree_plot() returns a ggplot", {
  expect_s3_class(
    scree_plot(crop_yield, cols = c("rainfall", "fertiliser", "soil_ph",
                                    "yield")),
    "ggplot"
  )
})

test_that("raincloud_plot() and group_comparison_plot() work", {
  expect_s3_class(raincloud_plot(lexical_decision, RT, group = condition),
                  "ggplot")
  expect_s3_class(raincloud_plot(crop_yield, yield), "ggplot")
  expect_error(raincloud_plot(crop_yield, treatment), "numeric")

  p <- group_comparison_plot(lexical_decision, RT, condition)
  expect_s3_class(p, "ggplot")
  expect_error(group_comparison_plot(crop_yield, treatment, treatment),
               "numeric")
})

test_that("survival_plot() accepts vectors, data frames and groups", {
  set.seed(1)
  n <- 120
  g <- sample(c("a", "b"), n, replace = TRUE)
  tt <- rexp(n, ifelse(g == "b", 0.05, 0.1))
  cc <- runif(n, 0, 30)
  obs <- pmin(tt, cc)
  ev <- as.integer(tt <= cc)
  expect_s3_class(survival_plot(obs, ev, group = g), "ggplot")
  expect_s3_class(survival_plot(obs, ev), "ggplot")
  df <- data.frame(time = obs, status = ev, group = g)
  expect_s3_class(survival_plot(df), "ggplot")
  expect_error(survival_plot(obs), "status")
})

test_that("vif_plot() and pr_curve_plot() work", {
  fit <- lm(yield ~ rainfall + fertiliser + soil_ph, data = crop_yield)
  expect_s3_class(vif_plot(fit), "ggplot")
  expect_error(vif_plot(lm(yield ~ rainfall, data = crop_yield)),
               "at least two")

  gfit <- glm(accuracy ~ word_frequency + RT + condition,
              data = lexical_decision, family = binomial)
  p <- pr_curve_plot(gfit)
  expect_s3_class(p, "ggplot")
  ap <- attr(p, "average_precision")
  expect_true(ap >= 0 && ap <= 1)
})
