#' ---
#' title: "03_predict_8wave_trajectories.R"
#' description: "Multinomial logistic regression predicting 8-wave LCGA trajectory membership"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(nnet)
})

cat("==> Loading 8-wave classified analytical dataset...\n")
classified <- readRDS("data/processed/degree_analytical_w18_classified.rds")

# Prepare complete cases for modeling
df_model <- classified %>%
  filter(
    !is.na(female), !is.na(race), !is.na(parents_income_num), !is.na(mom_college),
    !is.na(z_extraversion), !is.na(z_neuroticism), !is.na(z_agreeableness),
    !is.na(z_conscientiousness), !is.na(z_openness), !is.na(z_trust)
  )

# Set Moderate Winnowers as the reference class
df_model$trajectory_name <- relevel(df_model$trajectory_name, ref = "Moderate Winnowers")
cat("Analytical sample size for multinomial modeling: N =", nrow(df_model), "\n")

# Model 1: Demographic Predictors
m1 <- multinom(
  trajectory_name ~ female + race + parents_income_num + mom_college,
  data = df_model, trace = FALSE
)

# Model 2: Personality & Trust Predictors
m2 <- multinom(
  trajectory_name ~ z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust,
  data = df_model, trace = FALSE
)

# Model 3: Full Multivariable Specification
m3 <- multinom(
  trajectory_name ~ female + race + parents_income_num + mom_college +
    z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust,
  data = df_model, trace = FALSE
)

# Extract tidy results for Model 3
extract_multinom_tidy <- function(model) {
  s <- summary(model)
  coefs <- s$coefficients
  ses <- s$standard.errors
  z_vals <- coefs / ses
  p_vals <- (1 - pnorm(abs(z_vals))) * 2
  
  classes <- rownames(coefs)
  out_list <- list()
  
  for (cl in classes) {
    terms <- colnames(coefs)
    df_cl <- tibble(
      Comparison_Class = cl,
      Term = terms,
      Estimate = coefs[cl, ],
      SE = ses[cl, ],
      Z = z_vals[cl, ],
      P_Value = p_vals[cl, ],
      OR = exp(coefs[cl, ]),
      OR_Low = exp(coefs[cl, ] - 1.96 * ses[cl, ]),
      OR_High = exp(coefs[cl, ] + 1.96 * ses[cl, ])
    )
    out_list[[cl]] <- df_cl
  }
  bind_rows(out_list)
}

tidy_m3 <- extract_multinom_tidy(m3)
write.csv(tidy_m3, "output/tables/table3_mlogit_lcga_predictors.csv", row.names = FALSE)

# Clean Term Labels for APA Presentation
term_labels <- c(
  "(Intercept)"             = "Intercept",
  "female"                  = "Gender Identity: Woman (ref: Man)",
  "raceAsian"               = "Race: Asian (ref: White)",
  "raceBlack"               = "Race: Black (ref: White)",
  "raceHispanic/Latino"     = "Race: Hispanic/Latino (ref: White)",
  "raceOther/International" = "Race: Other/International (ref: White)",
  "parents_income_num"      = "Parents' Income (Ordinal Scale)",
  "mom_college"             = "Mother College Degree (ref: Non-degree)",
  "z_extraversion"          = "Extraversion (z-score)",
  "z_neuroticism"           = "Neuroticism (z-score)",
  "z_agreeableness"         = "Agreeableness (z-score)",
  "z_conscientiousness"     = "Conscientiousness (z-score)",
  "z_openness"              = "Openness (z-score)",
  "z_trust"                 = "Generalized Trust (z-score)"
)

# Create pre-compiled APA Markdown Table
tab3_formatted <- tidy_m3 %>%
  filter(Term != "(Intercept)") %>%
  mutate(
    Predictor = recode(Term, !!!term_labels),
    Est_SE = paste0(sprintf("%.2f", Estimate), " (", sprintf("%.2f", SE), ")"),
    OR_CI  = paste0(sprintf("%.2f", OR), " [", sprintf("%.2f", OR_Low), ", ", sprintf("%.2f", OR_High), "]"),
    P_Str  = ifelse(P_Value < 0.001, "< .001", sprintf("%.3f", P_Value))
  )

# Reshape into side-by-side comparison (Conservers vs Accelerated Winnowers)
conservers <- tab3_formatted %>%
  filter(Comparison_Class == "Network Conservers") %>%
  select(Predictor, Est_Cons = Est_SE, OR_Cons = OR_CI, P_Cons = P_Str)

winnowers <- tab3_formatted %>%
  filter(Comparison_Class == "Accelerated Winnowers") %>%
  select(Predictor, Est_Winn = Est_SE, OR_Winn = OR_CI, P_Winn = P_Str)

tab3_wide <- conservers %>%
  inner_join(winnowers, by = "Predictor")

md3 <- c(
  "| Predictor Variable | Conservers: Est (SE) | Conservers: OR [95% CI] | Conservers: p | Accel Winnowers: Est (SE) | Accel Winnowers: OR [95% CI] | Accel Winnowers: p |",
  "|:---|:---:|:---:|:---:|:---:|:---:|:---:|",
  apply(tab3_wide, 1, function(r) {
    paste0("| ", r["Predictor"], " | ", r["Est_Cons"], " | ", r["OR_Cons"], " | ", r["P_Cons"], " | ", r["Est_Winn"], " | ", r["OR_Winn"], " | ", r["P_Winn"], " |")
  })
)
writeLines(md3, "cache/table3_mlogit_lcga_predictors.md")
cat("==> Exported Table 3 to cache/table3_mlogit_lcga_predictors.md\n")

# -------------------------------------------------------------------
# Figure 4: Publication Forest Plot of Multinomial Odds Ratios
# -------------------------------------------------------------------
cat("==> Generating publication-grade Odds Ratio forest plot (Figure 4)...\n")

forest_df <- tidy_m3 %>%
  filter(Term != "(Intercept)") %>%
  mutate(
    Predictor = recode(Term, !!!term_labels),
    Predictor = factor(Predictor, levels = rev(c(
      "Gender Identity: Woman (ref: Man)",
      "Race: Asian (ref: White)",
      "Race: Black (ref: White)",
      "Race: Hispanic/Latino (ref: White)",
      "Race: Other/International (ref: White)",
      "Parents' Income (Ordinal Scale)",
      "Mother College Degree (ref: Non-degree)",
      "Extraversion (z-score)",
      "Neuroticism (z-score)",
      "Agreeableness (z-score)",
      "Conscientiousness (z-score)",
      "Openness (z-score)",
      "Generalized Trust (z-score)"
    ))),
    Comparison = factor(
      Comparison_Class,
      levels = c("Network Conservers", "Accelerated Winnowers"),
      labels = c("Network Conservers (vs. Moderate Winnowers)", "Accelerated Winnowers (vs. Moderate Winnowers)")
    ),
    Domain = ifelse(
      grepl("z_", Term), "Psychological Traits", "Sociodemographic Background"
    )
  )

p_forest <- ggplot(forest_df, aes(x = OR, y = Predictor, color = Comparison)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50", linewidth = 0.6) +
  geom_errorbar(aes(xmin = OR_Low, xmax = OR_High), width = 0.25, linewidth = 0.8, position = position_dodge(width = 0.5)) +
  geom_point(size = 2.8, position = position_dodge(width = 0.5)) +
  scale_x_log10(breaks = c(0.2, 0.5, 1.0, 2.0, 4.0), limits = c(0.15, 6.0)) +
  scale_color_manual(values = c(
    "Network Conservers (vs. Moderate Winnowers)" = "#1f77b4",
    "Accelerated Winnowers (vs. Moderate Winnowers)" = "#d62728"
  )) +
  labs(
    title = "Predictors of 8-Wave Degree Trajectory Group Membership",
    subtitle = "Multinomial Logistic Regression Odds Ratios with 95% Confidence Intervals (Reference: Moderate Winnowers; N = 433)",
    x = "Relative Risk Ratio / Odds Ratio (Log Scale)",
    y = "",
    color = "Trajectory Comparison"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    panel.border = element_rect(color = "grey80", fill = NA),
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig4_mlogit_forest_plot.png", p_forest, width = 10, height = 6.5, dpi = 300)
ggsave("output/figures/fig4_mlogit_forest_plot.png", p_forest, width = 10, height = 6.5, dpi = 300)

cat("\n==> Script 03 completed successfully! Generated Table 3 and Figure 4.\n")
