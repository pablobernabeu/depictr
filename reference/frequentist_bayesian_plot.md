# Plot frequentist and Bayesian estimates together

Presents the estimates from a frequentist model and a Bayesian model on
one plot, in the first two colours of the colourblind-safe
[`depictr_palette()`](https://pablobernabeu.github.io/depictr/reference/depictr_palette.md):
brand blue for the frequentist estimates and orange for the Bayesian
ones, whether the Bayesian side is drawn from draws or from summaries.

## Usage

``` r
frequentist_bayesian_plot(
  frequentist,
  bayesian,
  conf_level = 0.95,
  labels = NULL,
  interaction = c("times", "asterisk", "colon", "space"),
  intercept = TRUE,
  facet = TRUE,
  scales = c("free", "fixed"),
  note_frequentist_no_prior = FALSE,
  vertical_line_at_x = 0,
  title = NULL,
  subtitle = NULL,
  x_lab = "Estimate",
  caption = NULL,
  ...
)
```

## Arguments

- frequentist:

  A frequentist model (e.g. from `lm`, `glm` or
  [`lmerTest::lmer`](https://rdrr.io/pkg/lmerTest/man/lmer.html)) or a
  tidy data frame of estimates.

- bayesian:

  A Bayesian model, a `posterior` draws object, a draws matrix/data
  frame, a tidy data frame of posterior summaries or a summary matrix
  such as `brms::fixef()` returns.

- conf_level:

  Level of the intervals the function computes: the confidence intervals
  of a frequentist model and, when `bayesian` holds draws, the outer
  credible interval of each posterior (see Details).

- labels, interaction, intercept:

  See
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md).
  On both paths, an unnamed `labels` vector takes the frequentist terms
  first, then any that only the Bayesian input holds. `intercept`
  defaults to `TRUE` here, matching the original behaviour.

- facet, scales:

  Layout controls. Because a Bayesian model almost always carries a
  large intercept alongside small slopes, the comparison defaults to a
  faceted, free-scaled layout (`facet = TRUE`): each term gets its own
  panel and free x-axis, so every posterior and its frequentist overlay
  stay legible. Pass `facet = FALSE` (or `scales = "fixed"`) for the
  classic single shared-axis plot.

- note_frequentist_no_prior:

  If `TRUE`, append "(no prior)" to the frequentist legend label, which
  is helpful when the title names the Bayesian prior.

- vertical_line_at_x:

  Position of the vertical reference line (`NA` to omit).

- title, subtitle, x_lab:

  Title, subtitle and x-axis label.

- caption:

  Plot caption. The default (`NULL`) names the level of each source's
  intervals. Pass `NA` to omit the caption.

- ...:

  Further arguments passed to
  [`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md)
  on the summary path (ignored on the distribution path).

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

This is the modernised successor to the original
`frequentist_bayesian_plot()` gist, which built on `brms::mcmc_plot()`
to show the full Bayesian posterior with the frequentist estimate
overlaid. That namesake behaviour is restored here: when `bayesian`
carries posterior *draws* (a `brms`/`rstanarm` fit, a `posterior` draws
object, a draws matrix, or a long/wide draws data frame), the full
posterior *distribution* is drawn per term (a 'ggdist' half-eye) and the
frequentist point and confidence interval is overlaid at the same
position. When `bayesian` is only a table of posterior *summaries*, the
function shows the familiar two-source forest plot via
[`compare_models()`](https://pablobernabeu.github.io/depictr/reference/compare_models.md).
It reads tidy columns (`term`, `estimate`, `conf.low`, `conf.high`), the
`Estimate`, `Q2.5` and `Q97.5` of the matrix `brms::fixef()` returns,
and the `l-95% CI` and `u-95% CI` of `summary(fit)$fixed`.

Terms are aligned by their canonical display label, so the `brms`-style
`b_` prefix is reconciled automatically against the frequentist term
names. Draws are read as in
[`posterior_plot()`](https://pablobernabeu.github.io/depictr/reference/posterior_plot.md),
so a draws object holding `b_` parameters keeps only those, and two
terms that would share a label are an error. With draws, only the terms
both sides share are drawn, and a message names any dropped, such as a
`sigma` in the posterior. The forest plot of summaries draws every term
of either input.

`conf_level` is the level of every interval the function computes. For a
frequentist model, that is its confidence interval. For posterior draws,
it is the outer of the equal-tailed credible intervals drawn beneath
each half-eye, so the two sources are compared at one level. The inner
interval is 66%, drawn only when `conf_level` exceeds 0.66 so that it
stays the narrower of the two. A table of estimates keeps the interval
limits it holds, at whatever level they were computed. By default, a
caption names the level of each source's intervals or says that they are
as supplied.

## Examples

``` r
# Summary path: a tidy "Bayesian" summary as a data frame. The summary here
# stands in for a regularised posterior, so a weakly informative prior pulls
# each estimate toward zero and narrows its interval; a real posterior would
# come from the model fit rather than from arithmetic on the frequentist one.
freq <- lm(life_satisfaction ~ stress + sleep_hours + exercise_days,
           data = wellbeing_survey)
bayes <- tidy_estimates(freq)
bayes$estimate <- bayes$estimate * 0.9
half <- (bayes$conf.high - bayes$conf.low) / 2 * 0.8
bayes$conf.low <- bayes$estimate - half
bayes$conf.high <- bayes$estimate + half
frequentist_bayesian_plot(freq, bayes,
                          title = "Frequentist vs. Bayesian estimates")


# Distribution path: simulated posterior draws (one column per term) drawn as
# full posteriors with the frequentist point + CI overlaid.
set.seed(1)
co <- coef(freq)
draws <- as.data.frame(lapply(co, function(m) rnorm(400, m, abs(m) * 0.1 + 0.05)))
names(draws) <- names(co)
frequentist_bayesian_plot(freq, draws,
                          title = "Posterior with frequentist overlay")
```
