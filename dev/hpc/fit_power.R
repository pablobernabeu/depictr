# simr power analysis on lexical_decision -> a real powerCurve object for the
# power_curve_plot demo/tests (and to fix the simr-path nlevels/nrow + title bugs).
args <- commandArgs(trailingOnly = TRUE)
OUT <- if (length(args) >= 1) args[1] else "."
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

load("data/lexical_decision.rda")
ld <- lexical_decision[lexical_decision$accuracy == 1L, ]
suppressPackageStartupMessages({ library(lme4); library(simr) })

m <- lmer(RT ~ condition + modality + word_frequency + (1 | participant) + (1 | item),
          data = ld)

## Power for the word_frequency slope as the number of participants grows.
mext <- extend(m, along = "participant", n = 60)
pc <- powerCurve(mext, test = fixed("word_frequency", "t"), along = "participant",
                 breaks = c(12, 24, 36, 48, 60), nsim = 100, seed = 2026)
saveRDS(pc, file.path(OUT, "powercurve_lexdec.rds"))
print(summary(pc))
write.csv(summary(pc), file.path(OUT, "powercurve_summary.csv"), row.names = FALSE)
cat("JOB B DONE\n")
