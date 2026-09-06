#' ---
#' title: "generate_md_tables.R"
#' description: "Pre-compile APA-formatted Markdown tables into cache/ for Google Doc synchronization"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})

dir.create("cache", showWarnings = FALSE, recursive = TRUE)

cat("==> Generating pre-compiled APA Markdown tables in cache/...\n")

# -------------------------------------------------------------------
# Table 1: Trajectory Schemes Distribution
# -------------------------------------------------------------------
analytical <- readRDS("data/processed/degree_analytical_classified.rds")

tab1_rows <- tribble(
  ~Classification_Scheme, ~Category_or_Cluster, ~N_Egos, ~Share,
  "Deductive 8-Category", "Downward Trend (Modal)", 79L, "17.6%",
  "Deductive 8-Category", "Monotonic Decrease", 81L, "18.0%",
  "Deductive 8-Category", "Zig-Zag", 77L, "17.1%",
  "Deductive 8-Category", "U-Shape", 69L, "15.3%",
  "Deductive 8-Category", "Inverted U-Shape", 62L, "13.8%",
  "Deductive 8-Category", "Flat", 40L, "8.9%",
  "Deductive 8-Category", "Upward Trend", 27L, "6.0%",
  "Deductive 8-Category", "Monotonic Increase", 15L, "3.3%",
  "Deductive 4-Category", "Down (Reference)", 160L, "35.6%",
  "Deductive 4-Category", "Mixed", 208L, "46.2%",
  "Deductive 4-Category", "Up", 42L, "9.3%",
  "Deductive 4-Category", "Flat", 40L, "8.9%",
  "k-Means Demeaned (k=4)", "Cluster 1 (Conservers)", 199L, "44.2%",
  "k-Means Demeaned (k=4)", "Cluster 2 (Winnowers)", 110L, "24.4%",
  "k-Means Demeaned (k=4)", "Cluster 3 (Late Droppers)", 89L, "19.8%",
  "k-Means Demeaned (k=4)", "Cluster 4 (Accumulators)", 52L, "11.6%"
)

md1 <- c(
  "| Classification Scheme | Trajectory Class | N | Percent |",
  "|:---|:---:|:---:|:---:|",
  apply(tab1_rows, 1, function(r) {
    paste0("| ", r["Classification_Scheme"], " | ", r["Category_or_Cluster"], " | ", r["N_Egos"], " | ", r["Share"], " |")
  })
)
writeLines(md1, "cache/table1_trajectory_schemes.md")

# -------------------------------------------------------------------
# Table 2: Variable Significance Rates (Slide 22 Replication)
# -------------------------------------------------------------------
t2_raw <- read_csv("output/tables/table2_variable_significance_rates.csv", show_col_types = FALSE)

tab2_rows <- t2_raw %>%
  mutate(
    Domain = case_when(
      clean_var %in% c("Race", "Religion", "Language", "Mother's Education", "Parents' Income", "Sex", "Citizenship", "Father's Education") ~ "Social Demographics",
      TRUE ~ "Personality & Personal Attributes"
    ),
    Percent_Sig = sprintf("%.1f%%", pr_models_sig * 100)
  ) %>%
  select(Domain, Variable = clean_var, N_Models = n_models, Percent_Sig)

md2 <- c(
  "| Domain | Predictor Variable | Models Tested | Significant (p < .05) |",
  "|:---|:---|:---:|:---:|",
  apply(tab2_rows, 1, function(r) {
    paste0("| ", r["Domain"], " | ", r["Variable"], " | ", r["N_Models"], " | ", r["Percent_Sig"], " |")
  })
)
writeLines(md2, "cache/table2_variable_significance_rates.md")

# -------------------------------------------------------------------
# Table 3: LCGA Model Selection Fit
# -------------------------------------------------------------------
t3_raw <- read_csv("output/tables/table3_lcga_model_selection_fit.csv", show_col_types = FALSE)

tab3_rows <- t3_raw %>%
  mutate(
    Classes = paste0("K = ", K),
    LogLik = sprintf("%.1f", LogLik),
    Par = as.character(n_params),
    AIC = sprintf("%.1f", AIC),
    BIC = sprintf("%.1f", BIC),
    delta_BIC = sprintf("%.1f", delta_BIC)
  ) %>%
  select(Classes, LogLik, Par, AIC, BIC, delta_BIC)

md3 <- c(
  "| Latent Classes | Log-Likelihood | Par | AIC | BIC | ΔBIC |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab3_rows, 1, function(r) {
    paste0("| ", r["Classes"], " | ", r["LogLik"], " | ", r["Par"], " | ", r["AIC"], " | ", r["BIC"], " | ", r["delta_BIC"], " |")
  })
)
writeLines(md3, "cache/table3_lcga_model_selection.md")

# -------------------------------------------------------------------
# Table 4: Multilevel Model Comparison
# -------------------------------------------------------------------
t4_raw <- read_csv("output/tables/table4_multilevel_model_fit.csv", show_col_types = FALSE)

tab4_rows <- t4_raw %>%
  mutate(
    LogLik = sprintf("%.1f", LogLik),
    AIC = sprintf("%.1f", AIC),
    BIC = sprintf("%.1f", BIC)
  ) %>%
  select(Model, Description, LogLik, AIC, BIC)

md4 <- c(
  "| Model | Model Specification | Log-Likelihood | AIC | BIC |",
  "|:---|:---|:---:|:---:|:---:|",
  apply(tab4_rows, 1, function(r) {
    paste0("| ", r["Model"], " | ", r["Description"], " | ", r["LogLik"], " | ", r["AIC"], " | ", r["BIC"], " |")
  })
)
writeLines(md4, "cache/table4_multilevel_model_comparison.md")

# -------------------------------------------------------------------
# Table 5: Multilevel Poisson GLMM Fixed Effects (Model 4)
# -------------------------------------------------------------------
t5_raw <- read_csv("output/tables/table5_multilevel_glmm_estimates.csv", show_col_types = FALSE)

clean_terms <- c(
  "(Intercept)" = "Intercept (Baseline Degree)",
  "time" = "Time (Collegiate Wave)",
  "z_extraversion" = "Extraversion (z-score)",
  "z_neuroticism" = "Neuroticism (z-score)",
  "sexFemale" = "Gender Identity: Woman (ref: Man)",
  "raceAsian" = "Race: Asian (ref: White)",
  "raceBlack" = "Race: Black (ref: White)",
  "raceHispanic/Latino" = "Race: Hispanic/Latino (ref: White)",
  "raceOther/International" = "Race: Other/International (ref: White)",
  "parents_income_num" = "Parents' Income (Ordinal Scale)",
  "z_agreeableness" = "Agreeableness (z-score)",
  "z_conscientiousness" = "Conscientiousness (z-score)",
  "z_openness" = "Openness (z-score)",
  "z_trust" = "Generalized Trust (z-score)",
  "time:z_extraversion" = "Time x Extraversion",
  "time:z_neuroticism" = "Time x Neuroticism"
)

tab5_rows <- t5_raw %>%
  mutate(
    Variable = recode(term, !!!clean_terms),
    Est_SE = paste0(sprintf("%.2f", estimate), " (", sprintf("%.2f", std.error), ")"),
    IRR_CI = paste0(sprintf("%.2f", IRR), " [", sprintf("%.2f", conf.low.irr), ", ", sprintf("%.2f", conf.high.irr), "]"),
    p_val = p_format
  ) %>%
  select(Variable, Est_SE, IRR_CI, p_val)

md5 <- c(
  "| Predictor Variable | Estimate (SE) | Incidence Rate Ratio [95% CI] | p-value |",
  "|:---|:---:|:---:|:---:|",
  apply(tab5_rows, 1, function(r) {
    paste0("| ", r["Variable"], " | ", r["Est_SE"], " | ", r["IRR_CI"], " | ", r["p_val"], " |")
  })
)
writeLines(md5, "cache/table5_multilevel_glmm_estimates.md")

# -------------------------------------------------------------------
# Table 6: Decomposed Trajectory Means Across College
# -------------------------------------------------------------------
t6_raw <- read_csv("output/tables/table6_decomposed_trajectory_means.csv", show_col_types = FALSE)

wave_labels <- c(
  "1" = "Wave 1 (Frosh Fall)",
  "2" = "Wave 2 (Frosh Spr)",
  "3" = "Wave 3 (Soph Fall)",
  "4" = "Wave 4 (Soph Spr)",
  "5" = "Wave 5 (Jun Fall)",
  "6" = "Wave 6 (Jun Spr)",
  "7" = "Wave 7 (Sen Fall)",
  "8" = "Wave 8 (Sen Spr)"
)

tab6_rows <- t6_raw %>%
  mutate(
    Semester = wave_labels[as.character(wave_num)],
    N = as.character(n_egos),
    Total = paste0(sprintf("%.2f", Total_Mean), " (", sprintf("%.2f", Total_SE), ")"),
    Close = paste0(sprintf("%.2f", Close_Mean), " (", sprintf("%.2f", Close_SE), ")"),
    Daily = paste0(sprintf("%.2f", Daily_Mean), " (", sprintf("%.2f", Daily_SE), ")"),
    Support = ifelse(is.na(Support_Mean), "—", paste0(sprintf("%.2f", Support_Mean), " (", sprintf("%.2f", Support_SE), ")"))
  ) %>%
  select(Semester, N, Total, Close, Daily, Support)

md6 <- c(
  "| Academic Wave | Egos (N) | Total Degree (SE) | Close Ties (SE) | Daily Ties (SE) | Support Ties (SE) |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab6_rows, 1, function(r) {
    paste0("| ", r["Semester"], " | ", r["N"], " | ", r["Total"], " | ", r["Close"], " | ", r["Daily"], " | ", r["Support"], " |")
  })
)
writeLines(md6, "cache/table6_decomposed_trajectory_means.md")

cat("==> Pre-compiled tables generated successfully in cache/!\n")
