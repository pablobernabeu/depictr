# data-raw/generate_datasets.R
#
# Reproducibly simulate the datasets bundled with modelviz. These are
# synthetic (no personal or proprietary data), so they can be shipped freely
# and every example/vignette runs out of the box. Run this script from the
# package root to regenerate data/*.rda:
#
#   Rscript data-raw/generate_datasets.R
#
# The random seeds are fixed, so the output is identical on every run.

set.seed(2026)

# ---------------------------------------------------------------------------
# 1. lexical_decision
#    A simulated psycholinguistic lexical-decision experiment: participants
#    judge whether letter strings are real words, in a related or unrelated
#    priming condition and in the visual or auditory modality. Ideal for
#    mixed-effects modelling (crossed participant and item random effects).
# ---------------------------------------------------------------------------

n_participants <- 24L
n_items        <- 40L

participants <- sprintf("P%02d", seq_len(n_participants))
items        <- sprintf("I%02d", seq_len(n_items))

# Item-level properties
item_freq     <- round(stats::runif(n_items, 1.5, 6.5), 2)      # Zipf frequency
item_modality <- sample(c("visual", "auditory"), n_items, replace = TRUE)

# Random intercepts
participant_re <- stats::rnorm(n_participants, 0, 45)
item_re        <- stats::rnorm(n_items, 0, 35)

grid <- expand.grid(participant = participants, item = items,
                    stringsAsFactors = FALSE)
grid$condition <- sample(c("related", "unrelated"), nrow(grid), replace = TRUE)
grid$modality  <- item_modality[match(grid$item, items)]
grid$word_frequency <- item_freq[match(grid$item, items)]

# Linear predictor for reaction time (ms)
mu <- 620 +
  participant_re[match(grid$participant, participants)] +
  item_re[match(grid$item, items)] +
  ifelse(grid$condition == "unrelated", 35, 0) +     # priming effect
  ifelse(grid$modality == "auditory", 25, 0) +       # modality effect
  -18 * (grid$word_frequency - mean(item_freq))       # frequency effect

grid$RT <- round(mu + stats::rnorm(nrow(grid), 0, 60))
grid$RT[grid$RT < 250] <- 250L                        # plausible floor

# Accuracy: higher for more frequent words, lower when slow
acc_lin <- 2.2 + 0.25 * (grid$word_frequency - mean(item_freq)) -
  0.004 * (grid$RT - 620)
grid$accuracy <- stats::rbinom(nrow(grid), 1, plogis(acc_lin))

grid$participant <- factor(grid$participant)
grid$item        <- factor(grid$item)
grid$condition   <- factor(grid$condition, levels = c("related", "unrelated"))
grid$modality    <- factor(grid$modality, levels = c("visual", "auditory"))

lexical_decision <- grid[, c("participant", "item", "condition", "modality",
                             "word_frequency", "RT", "accuracy")]
rownames(lexical_decision) <- NULL

# ---------------------------------------------------------------------------
# 2. wellbeing_survey
#    A simulated cross-sectional wellbeing survey with realistic missingness,
#    for descriptive, correlation and missing-data examples.
# ---------------------------------------------------------------------------

set.seed(11)
n <- 300L
region    <- factor(sample(c("North", "South", "East", "West"), n, replace = TRUE))
age       <- round(stats::rnorm(n, 42, 14))
age[age < 18] <- 18L
education <- factor(
  sample(c("secondary", "undergraduate", "postgraduate"), n, replace = TRUE,
         prob = c(0.45, 0.4, 0.15)),
  levels = c("secondary", "undergraduate", "postgraduate")
)
income      <- round(stats::rlnorm(n, log(28000), 0.45))
stress      <- round(pmin(pmax(stats::rnorm(n, 4, 1.4), 1), 7), 1)
sleep_hours <- round(pmin(pmax(stats::rnorm(n, 7 - 0.25 * (stress - 4), 1), 3), 11), 1)
exercise_days <- stats::rpois(n, lambda = pmax(0.5, 3 - 0.3 * (stress - 4)))
exercise_days[exercise_days > 7] <- 7L

life_satisfaction <- round(pmin(pmax(
  4.5 - 0.45 * (stress - 4) + 0.25 * (sleep_hours - 7) +
    0.15 * exercise_days + 0.000005 * (income - 28000) +
    stats::rnorm(n, 0, 0.8), 1), 7), 1)

wellbeing_survey <- data.frame(
  id = sprintf("R%03d", seq_len(n)),
  region = region,
  age = age,
  education = education,
  income = income,
  stress = stress,
  sleep_hours = sleep_hours,
  exercise_days = exercise_days,
  life_satisfaction = life_satisfaction,
  stringsAsFactors = FALSE
)

# Inject missingness: income missing more often at higher stress (MAR),
# a few values missing completely at random elsewhere.
p_income_na <- plogis(-2.5 + 0.4 * (wellbeing_survey$stress - 4))
wellbeing_survey$income[stats::runif(n) < p_income_na] <- NA
wellbeing_survey$sleep_hours[sample(n, 18)] <- NA
wellbeing_survey$exercise_days[sample(n, 12)] <- NA
wellbeing_survey$life_satisfaction[sample(n, 7)] <- NA

# ---------------------------------------------------------------------------
# 3. crop_yield
#    A simulated agronomy field trial: yield as a function of rainfall,
#    fertiliser, soil pH and a management treatment. For regression,
#    coefficient and scatter-trend examples.
# ---------------------------------------------------------------------------

set.seed(303)
n <- 200L
field     <- sprintf("F%03d", seq_len(n))
treatment <- factor(sample(c("standard", "enhanced"), n, replace = TRUE),
                    levels = c("standard", "enhanced"))
rainfall   <- round(stats::rnorm(n, 520, 80))             # mm per season
fertilizer <- round(stats::runif(n, 0, 150))              # kg per hectare
soil_ph    <- round(stats::rnorm(n, 6.4, 0.5), 2)

yield <- 2.0 +
  0.004 * (rainfall - 520) +
  0.012 * fertilizer +
  0.9 * (soil_ph - 6.4) +
  ifelse(treatment == "enhanced", 0.8, 0) +
  -0.00004 * (rainfall - 520)^2 +
  stats::rnorm(n, 0, 0.6)
yield <- round(pmax(yield, 0.2), 2)                       # tonnes per hectare

crop_yield <- data.frame(
  field = field,
  treatment = treatment,
  rainfall = rainfall,
  fertilizer = fertilizer,
  soil_ph = soil_ph,
  yield = yield,
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

dir.create("data", showWarnings = FALSE)
save(lexical_decision, file = "data/lexical_decision.rda", compress = "bzip2")
save(wellbeing_survey, file = "data/wellbeing_survey.rda", compress = "bzip2")
save(crop_yield,       file = "data/crop_yield.rda",       compress = "bzip2")

message("Datasets written to data/.")
