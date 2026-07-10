# data-raw/generate_datasets.R
#
# Reproducibly simulate the datasets bundled with depictr. These are
# synthetic (no personal or proprietary data), so they can be shipped freely
# and every example/vignette runs out of the box. Run this script from the
# package root to regenerate data/*.rda:
#
#   Rscript data-raw/generate_datasets.R
#
# Each dataset sets its own seed immediately before it is generated, so the
# output is identical on every run regardless of the order of the blocks.

# ---------------------------------------------------------------------------
# 1. lexical_decision
#    A simulated psycholinguistic lexical-decision experiment with a fully
#    crossed, counterbalanced design, built for crossed-random-effects mixed
#    models: lmer(RT ~ condition + modality + word_frequency +
#                  (1 | participant) + (1 | item)).
#
#    Design (24 participants x 40 items = 960 trials, each item seen once per
#    participant). Two within-participant, within-item 2-level factors are
#    counterbalanced with a Latin-square list rotation:
#      * condition: related vs. unrelated priming (unrelated ~35 ms slower).
#      * modality:  visual vs. auditory presentation.
#    Participants are split into 4 groups; the (group, item) cell selects one
#    of the 4 condition x modality combinations via a rotation keyed on the
#    item index. This guarantees that, ACROSS participants, every item appears
#    equally often in each condition AND in each modality (so neither factor is
#    collinear with the item random intercept), and WITHIN each participant the
#    four cells are balanced across items.
#
#    word_frequency is a genuine continuous item-level covariate (Zipf scale).
#    RT is log-normal: exp(intercept + participant RE + item RE + fixed
#    effects + residual), with a plausible floor. accuracy is generated from
#    EXOGENOUS predictors (word_frequency, condition, modality) plus random
#    effects, NOT from RT, so the classification demos are not circular.
# ---------------------------------------------------------------------------

set.seed(2026)

n_participants <- 24L
n_items        <- 40L

participants <- sprintf("P%02d", seq_len(n_participants))
items        <- sprintf("I%02d", seq_len(n_items))

# Item-level properties: a real item-level covariate and item random intercept.
item_freq <- round(stats::runif(n_items, 1.5, 6.5), 2)   # Zipf frequency
item_re   <- stats::rnorm(n_items, 0, 0.06)              # item RE (log-RT scale)

# Participant random intercept (log-RT scale) and per-participant group.
participant_re    <- stats::rnorm(n_participants, 0, 0.10)
participant_group <- ((seq_len(n_participants) - 1L) %% 4L) + 1L  # 1..4

# Latin-square assignment of the 2 x 2 cell (condition x modality) to each
# (participant group, item). The four cells are indexed 0..3; the cell for a
# given group g and item i is (group_offset[g] + item) mod 4. Because the
# four group offsets are a permutation of 0..3 and there are 6 participants per
# group, every item is seen 6 times in each of the four cells across the 24
# participants -> perfect counterbalancing of both factors against item.
cell_levels <- expand.grid(
  condition = c("related", "unrelated"),
  modality  = c("visual", "auditory"),
  stringsAsFactors = FALSE
)                                            # 4 rows, indices 1..4
group_offset <- c(0L, 1L, 2L, 3L)            # one rotation step per group

grid <- expand.grid(participant = participants, item = items,
                    stringsAsFactors = FALSE)
p_idx <- match(grid$participant, participants)
i_idx <- match(grid$item, items)
g_idx <- participant_group[p_idx]

cell <- ((group_offset[g_idx] + (i_idx - 1L)) %% 4L) + 1L
grid$condition <- cell_levels$condition[cell]
grid$modality  <- cell_levels$modality[cell]
grid$word_frequency <- item_freq[i_idx]

# ---- Reaction time (log-normal) -------------------------------------------
# Fixed effects expressed on the natural (ms) scale, then converted so the
# multiplicative log-normal model yields an interpretable ~35 ms priming
# effect near the grand mean.
intercept   <- log(620)
freq_c       <- item_freq - mean(item_freq)
eta <- intercept +
  participant_re[p_idx] +
  item_re[i_idx] +
  0.055 * (grid$condition == "unrelated") +   # ~35 ms slower when unrelated
  0.040 * (grid$modality  == "auditory")  +   # auditory a touch slower
  -0.030 * freq_c[i_idx] +                     # frequent words faster
  stats::rnorm(nrow(grid), 0, 0.18)            # residual (log scale)

grid$RT <- round(exp(eta))
grid$RT[grid$RT < 250] <- 250L                 # plausible floor

# ---- Accuracy (exogenous; NOT derived from RT) ----------------------------
# Higher accuracy for frequent words and related primes; visual a touch
# easier; small participant/item random effects. Tuned to an overall error
# rate of a few percent, as in a real lexical-decision task.
acc_p_re <- stats::rnorm(n_participants, 0, 0.4)
acc_i_re <- stats::rnorm(n_items, 0, 0.4)
acc_lin <- 2.6 +
  0.45 * freq_c[i_idx] +
  0.35 * (grid$condition == "related") +
  0.20 * (grid$modality  == "visual") +
  acc_p_re[p_idx] +
  acc_i_re[i_idx]
grid$accuracy <- stats::rbinom(nrow(grid), 1, stats::plogis(acc_lin))

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
#    for descriptive, correlation, regression and missing-data examples.
#    life_satisfaction now responds meaningfully to log-income (a real
#    coefficient) and to age (a mild plateau/U-shape), in addition to stress,
#    sleep and exercise. education is an ORDERED factor. Income is missing more
#    often at higher stress (MAR), which now matters because income predicts
#    the outcome.
# ---------------------------------------------------------------------------

set.seed(11)
n <- 300L
region    <- factor(sample(c("North", "South", "East", "West"), n, replace = TRUE))
age       <- round(stats::rnorm(n, 42, 14))
age[age < 18] <- 18L
education <- factor(
  sample(c("secondary", "undergraduate", "postgraduate"), n, replace = TRUE,
         prob = c(0.45, 0.4, 0.15)),
  levels = c("secondary", "undergraduate", "postgraduate"),
  ordered = TRUE
)

# Regions differ genuinely: the South and West carry more stress and lower
# incomes than the North and East. This flows through to life satisfaction
# (which depends on stress and income), so the region-grouped plots (faceted
# densities, ridgelines, the region dendrogram) compare real contrasts rather
# than four panels of the same sampling noise.
stress_shift <- c(North = -0.5, South = 0.7, East = -0.2, West = 0.4)[as.character(region)]
income_shift <- c(North = 0.14, South = -0.14, East = 0.05, West = -0.06)[as.character(region)]

income      <- round(stats::rlnorm(n, log(28000) + income_shift, 0.45))
stress      <- round(pmin(pmax(stats::rnorm(n, 4, 1.4) + stress_shift, 1), 7), 1)
sleep_hours <- round(pmin(pmax(stats::rnorm(n, 7 - 0.25 * (stress - 4), 1), 3), 11), 1)
exercise_days <- stats::rpois(n, lambda = pmax(0.5, 3 - 0.3 * (stress - 4)))
exercise_days[exercise_days > 7] <- 7L

# Meaningful effects: a real log-income coefficient (~+0.45 per natural-log
# unit, i.e. ~+0.31 per doubling of income) and a mild age plateau peaking in
# mid-life. Stress, sleep and exercise keep their effects.
log_income_c <- log(income) - mean(log(income))
age_c        <- age - 45
life_satisfaction <- round(pmin(pmax(
  4.2 - 0.40 * (stress - 4) + 0.22 * (sleep_hours - 7) +
    0.13 * exercise_days +
    0.45 * log_income_c +
    0.010 * age_c - 0.0011 * age_c^2 +     # mild inverted-U, peak ~ mid-40s
    stats::rnorm(n, 0, 0.7), 1), 7), 1)

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

# Inject missingness: income missing more often at higher stress (MAR) - now
# informative because income drives life_satisfaction - plus a few values
# missing completely at random elsewhere.
p_income_na <- stats::plogis(-2.5 + 0.4 * (wellbeing_survey$stress - 4))
wellbeing_survey$income[stats::runif(n) < p_income_na] <- NA
wellbeing_survey$sleep_hours[sample(n, 18)] <- NA
wellbeing_survey$exercise_days[sample(n, 12)] <- NA
wellbeing_survey$life_satisfaction[sample(n, 7)] <- NA

# ---------------------------------------------------------------------------
# 3. crop_yield
#    A simulated agronomy field trial: yield as a function of rainfall,
#    fertiliser, soil pH and a management treatment. For regression,
#    coefficient and scatter-trend examples. The data-generating process now
#    contains a GENUINE fertiliser x treatment interaction: fertiliser pays off
#    far more under the enhanced treatment, so interaction_plot() shows real
#    crossing slopes rather than noise. Main effects are retained.
# ---------------------------------------------------------------------------

set.seed(303)
n <- 200L
field     <- sprintf("F%03d", seq_len(n))
treatment <- factor(sample(c("standard", "enhanced"), n, replace = TRUE),
                    levels = c("standard", "enhanced"))
rainfall   <- round(stats::rnorm(n, 520, 80))             # mm per season
fertiliser <- round(stats::runif(n, 0, 150))             # kg per hectare
soil_ph    <- round(stats::rnorm(n, 6.4, 0.5), 2)

enhanced <- treatment == "enhanced"
yield <- 2.0 +
  0.004 * (rainfall - 520) +
  0.006 * fertiliser +                       # fertiliser slope under standard
  0.9 * (soil_ph - 6.4) +
  ifelse(enhanced, 0.5, 0) +                  # treatment main effect
  0.012 * fertiliser * enhanced +            # INTERACTION: extra payoff when enhanced
  -0.00004 * (rainfall - 520)^2 +
  stats::rnorm(n, 0, 0.6)
yield <- round(pmax(yield, 0.2), 2)                       # tonnes per hectare

crop_yield <- data.frame(
  field = field,
  treatment = treatment,
  rainfall = rainfall,
  fertiliser = fertiliser,
  soil_ph = soil_ph,
  yield = yield,
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# 4a. clinical_trial
#    A simulated two-arm randomised clinical trial for time-to-event and
#    imbalanced-classification demos.
#      * time:   follow-up time in months.
#      * event:  0/1 indicator (1 = event observed, 0 = right-censored).
#      * arm:    treatment vs. placebo, with a REAL survival benefit so the
#                Kaplan-Meier curves separate and the log-rank test is
#                significant. The treated arm has noticeably fewer events
#                (realistic censoring driven by administrative end of study).
#      * age, biomarker: covariates that also affect the hazard.
#      * adverse_event: a realistically RARE binary safety outcome (~10% base
#                rate) that is predictable from the covariates and arm, giving
#                the precision-recall / gain / lift / calibration demos a
#                genuinely imbalanced target.
# ---------------------------------------------------------------------------

set.seed(404)
n <- 300L
arm <- factor(sample(c("placebo", "treatment"), n, replace = TRUE),
              levels = c("placebo", "treatment"))
age       <- round(stats::rnorm(n, 60, 10))
biomarker <- round(stats::rnorm(n, 0, 1), 2)             # standardised lab value

# Exponential survival: lower hazard (longer survival) on treatment; higher
# hazard with older age and higher biomarker. Coefficients are log-hazard.
log_hazard <- log(0.030) +                       # baseline ~33-month mean
  -0.85 * (arm == "treatment") +                 # protective treatment effect
  0.030 * (age - 60) +
  0.35 * biomarker
event_time  <- stats::rexp(n, rate = exp(log_hazard))
# Administrative censoring at the 36-month study end, plus modest random
# dropout, so the treated arm (longer event times) is more often censored.
admin_end   <- 36
dropout     <- stats::runif(n, 12, 60)
censor_time <- pmin(admin_end, dropout)
time   <- round(pmin(event_time, censor_time), 1)
event  <- as.integer(event_time <= censor_time)

# Rare adverse event (~10%), predictable from arm/age/biomarker.
ae_lin <- -2.7 +
  0.6 * (arm == "treatment") +
  0.04 * (age - 60) +
  0.7 * biomarker
adverse_event <- stats::rbinom(n, 1, stats::plogis(ae_lin))

clinical_trial <- data.frame(
  patient   = sprintf("PT%03d", seq_len(n)),
  arm       = arm,
  age       = age,
  biomarker = biomarker,
  time      = time,
  event     = event,
  adverse_event = adverse_event,
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# 4b. monthly_sales
#    A simulated seasonal monthly time series in tidy (date, series, value)
#    form, with two product lines. Each series has a linear trend, a clear
#    12-month seasonal cycle and noise, so the multi-group timeseries_plot()
#    path runs on first-party data and decompose_plot()/acf_plot() reveal
#    obvious seasonality. Six years of monthly observations per series.
# ---------------------------------------------------------------------------

set.seed(505)
start_date <- as.Date("2018-01-01")
n_months   <- 72L
dates      <- seq(start_date, by = "month", length.out = n_months)
month_idx  <- as.integer(format(dates, "%m"))
t_idx      <- seq_len(n_months)

make_series <- function(level, trend, amp, phase, noise_sd) {
  seasonal <- amp * sin(2 * pi * (month_idx - phase) / 12)
  round(level + trend * t_idx + seasonal + stats::rnorm(n_months, 0, noise_sd))
}

# Two contrasting product lines with different trends and seasonal peaks.
indoor  <- make_series(level = 200, trend =  1.5, amp = 45, phase =  1, noise_sd = 12)
outdoor <- make_series(level = 150, trend =  2.2, amp = 70, phase =  4, noise_sd = 15)

monthly_sales <- data.frame(
  date   = rep(dates, 2L),
  series = factor(rep(c("indoor", "outdoor"), each = n_months),
                  levels = c("indoor", "outdoor")),
  sales  = c(indoor, outdoor),
  stringsAsFactors = FALSE
)
rownames(monthly_sales) <- NULL

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

dir.create("data", showWarnings = FALSE)
save(lexical_decision, file = "data/lexical_decision.rda", compress = "bzip2")
save(wellbeing_survey, file = "data/wellbeing_survey.rda", compress = "bzip2")
save(crop_yield,       file = "data/crop_yield.rda",       compress = "bzip2")
save(clinical_trial,   file = "data/clinical_trial.rda",   compress = "bzip2")
save(monthly_sales,    file = "data/monthly_sales.rda",    compress = "bzip2")

message("Datasets written to data/.")
