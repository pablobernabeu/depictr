test_that("posterior_plot() tolerates NA draws (long form)", {
  set.seed(1)
  draws <- data.frame(
    parameter = rep(c("a", "b"), each = 200),
    value = c(rnorm(200), rnorm(200))
  )
  draws$value[c(5, 137, 350)] <- NA

  expect_no_error(p <- posterior_plot(draws))
  expect_s3_class(p, "ggplot")

  # Summary values must be finite (computed with na.rm = TRUE, not NA).
  built <- ggplot2::ggplot_build(p)
  centres <- built$data[[which.max(vapply(built$data,
    function(d) sum(!is.na(d$x)), integer(1)))]]$x
  expect_true(all(is.finite(centres)))
})

test_that("posterior_plot() tolerates NA draws (wide form)", {
  set.seed(2)
  draws <- data.frame(a = rnorm(300), b = rnorm(300))
  draws$a[10] <- NA

  expect_no_error(p <- posterior_plot(draws))
  expect_s3_class(p, "ggplot")
})

test_that("draws_to_long() drops NA values", {
  draws <- data.frame(value = c(1, NA, 3), parameter = c("a", "a", "a"))
  long <- draws_to_long(draws)
  expect_equal(long$value, c(1, 3))
  expect_false(any(is.na(long$value)))
})

test_that("wide draws drop known sampler index columns", {
  set.seed(3)
  draws <- data.frame(.draw = 1:500, a = rnorm(500), b = rnorm(500))
  long <- draws_to_long(draws)
  expect_setequal(unique(long$parameter), c("a", "b"))
  expect_false(".draw" %in% long$parameter)

  p <- posterior_plot(draws)
  expect_s3_class(p, "ggplot")
})

test_that("all known index columns are dropped, parameters retained", {
  set.seed(4)
  n <- 100
  draws <- data.frame(
    .chain = rep(1:2, each = n / 2),
    .iteration = rep(seq_len(n / 2), 2),
    .draw = seq_len(n),
    chain = rep(1:2, each = n / 2),
    iteration = rep(seq_len(n / 2), 2),
    draw = seq_len(n),
    .row = seq_len(n),
    intercept = rnorm(n, 5),
    slope = rnorm(n, 0.8)
  )
  long <- draws_to_long(draws)
  expect_setequal(unique(long$parameter), c("intercept", "slope"))
})

test_that("wide draws of only index columns error informatively", {
  draws <- data.frame(.chain = 1:10, .draw = 1:10)
  expect_error(draws_to_long(draws), "Could not find draws")
})
