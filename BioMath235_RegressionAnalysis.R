# =============================================================================
# NHANES 2017-2020
# Survey-Weighted Logistic Regression:
# Effect of Health Insurance on Blood Sugar Screening
# =============================================================================

library(survey)
library(dplyr)
library(tidyr)

options(survey.lonely.psu = "adjust")

# -----------------------------------------------------------------------------
# 1. Load and prepare data
# -----------------------------------------------------------------------------
df <- read.csv("~/Downloads/nhanes_insurance_screening_analytic.csv", stringsAsFactors = FALSE)

df <- df %>%
  mutate(
    screened_bin = ifelse(screened == "Screened", 1, 0),
    insured      = factor(insured, levels = c("Uninsured", "Insured")),
    sex          = factor(sex, levels = c("Male", "Female")),
    race_eth     = factor(race_eth,
                          levels = c("Non-Hispanic White", "Mexican American",
                                     "Other Hispanic", "Non-Hispanic Black",
                                     "Non-Hispanic Asian", "Other/Multi")),
    education    = factor(education,
                          levels = c("< High school", "High school / GED",
                                     "Some college", "College graduate")),
    marital      = factor(marital,
                          levels = c("Married / partnered",
                                     "Widowed / divorced / separated",
                                     "Never married")),
    us_born      = factor(us_born,
                          levels = c("Born in U.S.", "Born outside U.S.")),
    interview_lang = factor(interview_lang, levels = c("English", "Spanish")),
    gen_health   = factor(gen_health,
                          levels = c("Excellent", "Very good", "Good",
                                     "Fair", "Poor")),
    hypertension = factor(hypertension,  levels = c("No", "Yes")),
    smoked_100   = factor(smoked_100,    levels = c("No", "Yes")),
    alcohol_ever = factor(alcohol_ever,  levels = c("No", "Yes"))
  )

# -----------------------------------------------------------------------------
# 2. Sample flow
# -----------------------------------------------------------------------------
cat("========================================\n")
cat("SAMPLE FLOW\n")
cat("========================================\n")
n0 <- nrow(df)
n1 <- sum(df$WTMECPRP > 0, na.rm = TRUE)

df_analytic <- df %>% filter(WTMECPRP > 0)

cat(sprintf("Full merged dataset:              %d\n", n0))
cat(sprintf("Excluded (zero MEC weight):       %d\n", n0 - n1))
cat(sprintf("Final analytic sample:            %d\n", n1))
cat(sprintf("  Insured:                        %d\n", sum(df_analytic$insured == "Insured")))
cat(sprintf("  Uninsured:                      %d\n", sum(df_analytic$insured == "Uninsured")))
cat(sprintf("  Screened:                       %d\n", sum(df_analytic$screened_bin == 1, na.rm=TRUE)))
cat(sprintf("  Not screened:                   %d\n", sum(df_analytic$screened_bin == 0, na.rm=TRUE)))

# -----------------------------------------------------------------------------
# 3. Covariate missingness
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("COVARIATE MISSINGNESS\n")
cat("========================================\n")
miss <- df_analytic %>%
  summarise(across(c(age, sex, race_eth, education, marital, us_born,
                     interview_lang, pir, bmi, gen_health,
                     hypertension, smoked_100, alcohol_ever),
                   ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Covariate", values_to = "N_Missing") %>%
  mutate(Pct_Missing = round(N_Missing / nrow(df_analytic) * 100, 1)) %>%
  arrange(desc(N_Missing))
print(as.data.frame(miss), row.names = FALSE)

# -----------------------------------------------------------------------------
# 4. Survey design
# Using WTMECPRP (MEC weight) since BMI from physical exam is included
# option(survey.lonely.psu="adjust") handles strata with single PSU
# -----------------------------------------------------------------------------
nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMECPRP,
  data    = df_analytic,
  nest    = TRUE
)

# -----------------------------------------------------------------------------
# 5. Crude screening rates by insurance
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("CRUDE WEIGHTED SCREENING RATES\n")
cat("========================================\n")
crude <- svyby(~screened_bin, ~insured, nhanes_design, svymean, na.rm = TRUE)
crude$pct <- round(crude$screened_bin * 100, 1)
crude$se_pct <- round(crude$se * 100, 1)
print(crude[, c("insured", "pct", "se_pct")])

# -----------------------------------------------------------------------------
# 6. Model 1: Unadjusted
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("MODEL 1: UNADJUSTED\n")
cat("========================================\n")
m1 <- svyglm(screened_bin ~ insured,
             design = nhanes_design,
             family = quasibinomial(link = "logit"))
print(summary(m1)$coefficients)
m1_or <- as.data.frame(exp(cbind(OR = coef(m1), confint(m1, df = Inf))))
m1_or$p_value <- summary(m1)$coefficients[, "Pr(>|t|)"]
cat("\nOR (95% CI), p-value:\n")
print(round(m1_or, 4))

# -----------------------------------------------------------------------------
# 7. Model 2: Demographically adjusted
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("MODEL 2: DEMOGRAPHICALLY ADJUSTED\n")
cat("========================================\n")
m2 <- svyglm(
  screened_bin ~ insured + age + sex + race_eth +
    education + pir + marital + us_born + interview_lang,
  design = nhanes_design,
  family = quasibinomial(link = "logit")
)
print(summary(m2)$coefficients)
m2_or <- as.data.frame(exp(cbind(OR = coef(m2), confint(m2, df = Inf))))
m2_or$p_value <- summary(m2)$coefficients[, "Pr(>|t|)"]
cat("\nOR (95% CI), p-value:\n")
print(round(m2_or, 4))

# -----------------------------------------------------------------------------
# 8. Model 3: Fully adjusted
# Use df=Inf for CIs to avoid the low-df problem with masked NHANES PSUs
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("MODEL 3: FULLY ADJUSTED\n")
cat("========================================\n")
m3 <- svyglm(
  screened_bin ~ insured + age + sex + race_eth +
    education + pir + marital + us_born + interview_lang +
    bmi + gen_health + hypertension + smoked_100 + alcohol_ever,
  design = nhanes_design,
  family = quasibinomial(link = "logit")
)
print(summary(m3)$coefficients)
m3_or <- as.data.frame(exp(cbind(OR = coef(m3), confint(m3, df = Inf))))
m3_or$p_value <- summary(m3)$coefficients[, "Pr(>|t|)"]
cat("\nOR (95% CI), p-value:\n")
print(round(m3_or, 4))

# -----------------------------------------------------------------------------
# 9. Clean combined results table (insurance row only — primary estimate)
# -----------------------------------------------------------------------------
cat("\n========================================\n")
cat("PRIMARY ESTIMATE: INSURANCE EFFECT\n")
cat("across all three models\n")
cat("========================================\n")

extract_insurance <- function(model, label) {
  or_ci <- exp(cbind(OR = coef(model), confint(model, df = Inf)))["insuredInsured",]
  pval  <- summary(model)$coefficients["insuredInsured", "Pr(>|t|)"]
  data.frame(Model    = label,
             OR       = round(or_ci["OR"], 3),
             CI_lower = round(or_ci["2.5 %"], 3),
             CI_upper = round(or_ci["97.5 %"], 3),
             p_value  = round(pval, 4))
}

ins_table <- rbind(
  extract_insurance(m1, "Unadjusted"),
  extract_insurance(m2, "Demographically Adjusted"),
  extract_insurance(m3, "Fully Adjusted")
)
rownames(ins_table) <- NULL
print(ins_table)

# -----------------------------------------------------------------------------
# 10. Full results table saved to CSV
# -----------------------------------------------------------------------------
format_model <- function(model, model_name) {
  coefs <- summary(model)$coefficients
  ors   <- exp(cbind(OR = coef(model), confint(model, df = Inf)))
  data.frame(
    Model    = model_name,
    Variable = rownames(coefs),
    OR       = round(ors[, "OR"], 3),
    CI_lower = round(ors[, "2.5 %"], 3),
    CI_upper = round(ors[, "97.5 %"], 3),
    p_value  = round(coefs[, "Pr(>|t|)"], 4),
    sig      = ifelse(coefs[,"Pr(>|t|)"] < 0.001, "***",
                      ifelse(coefs[,"Pr(>|t|)"] < 0.01,  "**",
                             ifelse(coefs[,"Pr(>|t|)"] < 0.05,  "*",
                                    ifelse(coefs[,"Pr(>|t|)"] < 0.10,  ".", "")))),
    row.names = NULL
  )
}

full_table <- rbind(
  format_model(m1, "1 - Unadjusted"),
  format_model(m2, "2 - Demographically Adjusted"),
  format_model(m3, "3 - Fully Adjusted")
)

write.csv(full_table, "~/Downloads/nhanes_regression_results.csv", row.names = FALSE)

cat("\n========================================\n")
cat("WALD TEST: INSURANCE TERM\n")
cat("========================================\n")
cat("Model 1:\n"); print(regTermTest(m1, ~insured))
cat("Model 2:\n"); print(regTermTest(m2, ~insured))
cat("Model 3:\n"); print(regTermTest(m3, ~insured))

cat("\nFull results table saved to nhanes_regression_results.csv\n")

