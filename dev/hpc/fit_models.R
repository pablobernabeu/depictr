# Fit the frequentist + Bayesian models on lexical_decision and cache outputs.
# Produces: frequentist lmerTest summary+CI, full brms fit, thinned fixed-effect
# posterior draws (shippable), brms fixef summary, and lme4::allFit results.
args <- commandArgs(trailingOnly = TRUE)
OUT <- if (length(args) >= 1) args[1] else "."
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

load("data/lexical_decision.rda")            # -> lexical_decision
ld <- lexical_decision[lexical_decision$accuracy == 1L, ]   # RT on correct trials
cat("correct trials:", nrow(ld), "of", nrow(lexical_decision), "\n")

## --- Frequentist (lmerTest): the frequentist side of frequentist_bayesian_plot
suppressPackageStartupMessages(library(lmerTest))
freq <- lmer(RT ~ condition + modality + word_frequency + (1 | participant) + (1 | item),
             data = ld)
freq_fixef <- summary(freq)$coefficients
freq_ci <- tryCatch(confint(freq, parm = "beta_", method = "Wald"),
                    error = function(e) confint(freq, method = "Wald"))
saveRDS(list(fixef = freq_fixef, ci = freq_ci), file.path(OUT, "freq_lexdec.rds"))
cat("== frequentist done ==\n"); print(round(freq_fixef, 3))

## --- Bayesian (brms)
suppressPackageStartupMessages(library(brms))
priors <- c(set_prior("normal(0, 100)", class = "b"),
            set_prior("normal(600, 200)", class = "Intercept"))
bfit <- brm(RT ~ condition + modality + word_frequency + (1 | participant) + (1 | item),
            data = ld, family = gaussian(), prior = priors,
            chains = 4, iter = 2000, warmup = 1000, cores = 4, seed = 2026,
            refresh = 200, control = list(adapt_delta = 0.95))
saveRDS(bfit, file.path(OUT, "brms_lexdec.rds"))
cat("== brms done ==\n")

## --- Thinned fixed-effect posterior draws (small + shippable as package data)
suppressPackageStartupMessages(library(posterior))
dr <- posterior::as_draws_df(bfit)
fe_cols <- grep("^b_", names(dr), value = TRUE)
fe <- as.data.frame(dr[, fe_cols, drop = FALSE])
names(fe) <- sub("^b_", "", names(fe))
set.seed(1); idx <- sort(sample(nrow(fe), min(1000, nrow(fe))))
lexdec_draws <- fe[idx, , drop = FALSE]
saveRDS(lexdec_draws, file.path(OUT, "lexdec_draws.rds"))
write.csv(lexdec_draws, file.path(OUT, "lexdec_draws.csv"), row.names = FALSE)
cat("== draws saved:", nrow(lexdec_draws), "x", ncol(lexdec_draws), "==\n")
print(utils::head(lexdec_draws, 2))

## --- brms fixef summary (Estimate, Q2.5, Q97.5) for the summary-path demo/tests
bfix <- brms::fixef(bfit)
saveRDS(bfix, file.path(OUT, "brms_fixef_lexdec.rds"))
write.csv(as.data.frame(bfix), file.path(OUT, "brms_fixef_lexdec.csv"))

## --- lme4 allFit across optimizers -> optimizer_fixef_plot demo/tests
suppressPackageStartupMessages(library(lme4))
m <- lmer(RT ~ condition + modality + word_frequency + (1 | participant) + (1 | item),
          data = ld, REML = FALSE)
af <- tryCatch(lme4::allFit(m, verbose = FALSE),
               error = function(e) { cat("allFit error:", conditionMessage(e), "\n"); NULL })
if (!is.null(af)) {
  saveRDS(summary(af), file.path(OUT, "allfit_lexdec.rds"))
  cat("== allFit done ==\n")
}
cat("JOB A DONE\n")
