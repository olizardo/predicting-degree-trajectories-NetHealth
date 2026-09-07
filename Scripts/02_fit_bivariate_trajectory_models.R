#' ---
#' title: "02_fit_bivariate_trajectory_models.R"
#' description: "Bivariate Multi-Trajectory Poisson mixture modeling of Compound Strong and Weak Ties across 8 waves"
#' author: "Omar Lizardo and David Hachen"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(scales)
  library(flexmix)
  library(grid)
})

cat("==> [1/6] Loading data and constructing compound strong/weak ties...\n")
net_raw <- read_csv("data/raw/network_survey.csv", show_col_types = FALSE)
analytical_w18 <- readRDS("data/processed/degree_analytical_w18.rds")
base_df <- readRDS("data/processed/degree_analytical_w18_classified.rds") %>%
  select(egoid, female, race, parents_income_num, mom_college,
         z_extraversion, z_neuroticism, z_agreeableness,
         z_conscientiousness, z_openness, z_trust)

# Define Compound Strong Tie: Especially Close AND (Daily or Weekly) contact
biv_data_all <- net_raw %>%
  filter(!is.na(egoid), !is.na(wave)) %>%
  mutate(wave_num = as.integer(gsub("\\D", "", wave))) %>%
  filter(wave_num <= 8, egoid %in% analytical_w18$egoid) %>%
  mutate(
    is_strong = (close == "EspeciallyClose" & freq %in% c("Daily", "Weekly")),
    is_weak   = !is_strong
  ) %>%
  group_by(egoid, wave_num) %>%
  summarize(
    total_degree  = n(),
    strong_degree = sum(is_strong, na.rm = TRUE),
    weak_degree   = sum(is_weak, na.rm = TRUE),
    .groups = "drop"
  )

dir.create("Plots", showWarnings = FALSE, recursive = TRUE)
dir.create("cache", showWarnings = FALSE, recursive = TRUE)
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# -------------------------------------------------------------------
# 1. Table 1 & Figure 1: Aggregate Longitudinal Decomposition
# -------------------------------------------------------------------
cat("==> [2/6] Generating Table 1 and Figure 1 (Aggregate Decomposition)...\n")
tab1_summary <- biv_data_all %>%
  group_by(wave_num) %>%
  summarize(
    n_egos = n(),
    Total_Mean  = mean(total_degree),
    Total_SE    = sd(total_degree) / sqrt(n()),
    Strong_Mean = mean(strong_degree),
    Strong_SE   = sd(strong_degree) / sqrt(n()),
    Weak_Mean   = mean(weak_degree),
    Weak_SE     = sd(weak_degree) / sqrt(n()),
    Pct_Strong  = mean(strong_degree / total_degree) * 100,
    .groups = "drop"
  )

write.csv(tab1_summary, "output/tables/table1_bivariate_trajectory_means.csv", row.names = FALSE)

wave_labels_full <- c(
  "1" = "Wave 1 (Frosh Fall)",
  "2" = "Wave 2 (Frosh Spr)",
  "3" = "Wave 3 (Soph Fall)",
  "4" = "Wave 4 (Soph Spr)",
  "5" = "Wave 5 (Jun Fall)",
  "6" = "Wave 6 (Jun Spr)",
  "7" = "Wave 7 (Sen Fall)",
  "8" = "Wave 8 (Sen Spr)"
)

tab1_rows <- tab1_summary %>%
  mutate(
    Semester = wave_labels_full[as.character(wave_num)],
    N = as.character(n_egos),
    Total = paste0(sprintf("%.2f", Total_Mean), " (", sprintf("%.2f", Total_SE), ")"),
    Strong = paste0(sprintf("%.2f", Strong_Mean), " (", sprintf("%.2f", Strong_SE), ")"),
    Weak = paste0(sprintf("%.2f", Weak_Mean), " (", sprintf("%.2f", Weak_SE), ")"),
    Pct = paste0(sprintf("%.1f", Pct_Strong), "%")
  ) %>%
  select(Semester, N, Total, Strong, Weak, Pct)

md1 <- c(
  "| Academic Wave | Egos (N) | Total Degree (SE) | Strong Ties (SE) | Weak Ties (SE) | Strong Tie Share (%) |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab1_rows, 1, function(r) {
    paste0("| ", r["Semester"], " | ", r["N"], " | ", r["Total"], " | ", r["Strong"], " | ", r["Weak"], " | ", r["Pct"], " |")
  })
)
writeLines(md1, "cache/table1_bivariate_trajectory_means.md")

# Plot Figure 1: 8-Wave Trajectories of Total, Strong, and Weak Ties
plot1_df <- bind_rows(
  tab1_summary %>% select(wave_num, Mean = Total_Mean, SE = Total_SE) %>% mutate(Metric = "Total Ego Network Size"),
  tab1_summary %>% select(wave_num, Mean = Strong_Mean, SE = Strong_SE) %>% mutate(Metric = "Strong Ties (Close & Active)"),
  tab1_summary %>% select(wave_num, Mean = Weak_Mean, SE = Weak_SE) %>% mutate(Metric = "Weak Ties (Casual / Infrequent)")
) %>%
  mutate(
    Metric = factor(Metric, levels = c("Total Ego Network Size", "Strong Ties (Close & Active)", "Weak Ties (Casual / Infrequent)"))
  )

p_fig1 <- ggplot(plot1_df, aes(x = wave_num, y = Mean, color = Metric, shape = Metric, fill = Metric)) +
  geom_ribbon(aes(ymin = Mean - 1.96 * SE, ymax = Mean + 1.96 * SE), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh Fall", "W2\nFrosh Spr", "W3\nSoph Fall", "W4\nSoph Spr",
               "W5\nJun Fall", "W6\nJun Spr", "W7\nSen Fall", "W8\nSen Spr")
  ) +
  scale_y_continuous(breaks = seq(0, 16, 2), limits = c(0, 16)) +
  scale_color_manual(values = c(
    "Total Ego Network Size"         = "#1f77b4",
    "Strong Ties (Close & Active)"   = "#2ca02c",
    "Weak Ties (Casual / Infrequent)" = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Total Ego Network Size"         = "#1f77b4",
    "Strong Ties (Close & Active)"   = "#2ca02c",
    "Weak Ties (Casual / Infrequent)" = "#d62728"
  )) +
  scale_shape_manual(values = c(16, 17, 15)) +
  labs(
    title = "Collegiate Ego Network Evolution: Decomposing Strong and Weak Ties Across 8 Waves",
    subtitle = "Strong ties: Especially Close + Daily/Weekly contact; Weak ties: all other nominated alters (N = 457 Egos)",
    x = "College Academic Wave (Fall 2015 to Spring 2019)",
    y = "Average Degree (Alters Nominated)",
    color = "Relational Layer",
    shape = "Relational Layer",
    fill  = "Relational Layer"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig1_compound_strong_weak_trajectories.png", p_fig1, width = 9.5, height = 5.8, dpi = 300)
ggsave("output/figures/fig1_compound_strong_weak_trajectories.png", p_fig1, width = 9.5, height = 5.8, dpi = 300)

# -------------------------------------------------------------------
# 2. Table 2: Bivariate LCGA Model Fit Hierarchy (K = 1..5)
# -------------------------------------------------------------------
cat("==> [3/6] Estimating Bivariate LCGA models for K = 1..5 (Table 2)...\n")
fit_biv_k <- function(k) {
  set.seed(2026 + k)
  if (k == 1) {
    mod1 <- glm(strong_degree ~ wave_num + I(wave_num^2), data = biv_data_all, family = poisson)
    mod2 <- glm(weak_degree ~ wave_num + I(wave_num^2), data = biv_data_all, family = poisson)
    ll <- logLik(mod1)[1] + logLik(mod2)[1]
    p <- length(coef(mod1)) + length(coef(mod2))
    aic <- -2 * ll + 2 * p
    bic <- -2 * ll + log(nrow(biv_data_all)) * p
  } else {
    mod <- flexmix(
      cbind(strong_degree, weak_degree) ~ wave_num + I(wave_num^2) | egoid,
      data = biv_data_all, k = k,
      model = list(
        FLXMRglm(strong_degree ~ wave_num + I(wave_num^2), family = "poisson"),
        FLXMRglm(weak_degree   ~ wave_num + I(wave_num^2), family = "poisson")
      ),
      control = list(iter.max = 300, minprior = 0.02)
    )
    ll <- logLik(mod)[1]
    p <- mod@df
    aic <- AIC(mod)
    bic <- BIC(mod)
  }
  tibble(K = k, LogLik = ll, Params = p, AIC = aic, BIC = bic)
}

biv_fit_list <- lapply(1:5, fit_biv_k)
biv_fit_table <- bind_rows(biv_fit_list) %>%
  mutate(
    delta_BIC = BIC - min(BIC),
    LRT_step  = c(NA, 2 * diff(LogLik)),
    df_step   = c(NA, diff(Params))
  )

write.csv(biv_fit_table, "output/tables/table2_bivariate_model_selection.csv", row.names = FALSE)

tab2_rows <- biv_fit_table %>%
  mutate(
    Classes = paste0("K = ", K),
    LL = sprintf("%.1f", LogLik),
    Par = as.character(Params),
    AIC_str = sprintf("%.1f", AIC),
    BIC_str = sprintf("%.1f", BIC),
    dBIC = sprintf("%.1f", delta_BIC)
  ) %>%
  select(Classes, LL, Par, AIC_str, BIC_str, dBIC)

md2 <- c(
  "| Latent Classes | Log-Likelihood | Par | AIC | BIC | ΔBIC |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab2_rows, 1, function(r) {
    paste0("| ", r["Classes"], " | ", r["LL"], " | ", r["Par"], " | ", r["AIC_str"], " | ", r["BIC_str"], " | ", r["dBIC"], " |")
  })
)
writeLines(md2, "cache/table2_bivariate_model_selection.md")

# -------------------------------------------------------------------
# 3. Figure 2: Bivariate Trajectory Profiles for K = 3
# -------------------------------------------------------------------
cat("==> [4/6] Generating Bivariate LCGA trajectory profiles plot (Figure 2)...\n")
set.seed(2026 + 3)
mod_biv3 <- flexmix(
  cbind(strong_degree, weak_degree) ~ wave_num + I(wave_num^2) | egoid,
  data = biv_data_all, k = 3,
  model = list(
    FLXMRglm(strong_degree ~ wave_num + I(wave_num^2), family = "poisson"),
    FLXMRglm(weak_degree   ~ wave_num + I(wave_num^2), family = "poisson")
  ),
  control = list(iter.max = 300, minprior = 0.02)
)

ego_assignments_biv3 <- tibble(
  egoid = biv_data_all$egoid,
  clust = clusters(mod_biv3)
) %>%
  group_by(egoid) %>%
  summarize(raw_class = as.character(names(which.max(table(clust)))), .groups = "drop")

# Class mapping based on empirical morphology:
# Raw 3 = High Strong Conservers (starts strong ~9.7, weak ~6.0)
# Raw 1 = Dual Conservers / High Weak (starts strong ~6.8, weak ~9.3)
# Raw 2 = Accelerated Winnowers (starts strong ~5.9, weak drops to 1.4)
# Let's verify class counts:
table(ego_assignments_biv3$raw_class)

ego_classified_biv3 <- ego_assignments_biv3 %>%
  mutate(
    class_label = case_when(
      raw_class == "1" ~ "Network Conservers (n = 141, 30.9%)",
      raw_class == "2" ~ "Accelerated Winnowers (n = 191, 41.8%)",
      raw_class == "3" ~ "High-Core Conservers (n = 125, 27.4%)"
    )
  )

biv_long_plot <- biv_data_all %>%
  inner_join(ego_classified_biv3, by = "egoid")

biv_means_plot <- biv_long_plot %>%
  group_by(class_label, wave_num) %>%
  summarize(
    Strong_Mean = mean(strong_degree),
    Strong_SE   = sd(strong_degree) / sqrt(n()),
    Weak_Mean   = mean(weak_degree),
    Weak_SE     = sd(weak_degree) / sqrt(n()),
    .groups = "drop"
  )

# Reshape for plotting
biv_lines <- bind_rows(
  biv_means_plot %>% select(class_label, wave_num, Mean = Strong_Mean, SE = Strong_SE) %>% mutate(Tier = "Strong Ties (Close & Active)"),
  biv_means_plot %>% select(class_label, wave_num, Mean = Weak_Mean, SE = Weak_SE) %>% mutate(Tier = "Weak Ties (Casual Contacts)")
)

p_fig2 <- ggplot(biv_lines, aes(x = wave_num, y = Mean, color = Tier, shape = Tier, fill = Tier)) +
  geom_ribbon(aes(ymin = Mean - 1.96 * SE, ymax = Mean + 1.96 * SE), alpha = 0.20, color = NA) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 2.8) +
  facet_wrap(~ class_label, ncol = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh", "W2\nFrosh", "W3\nSoph", "W4\nSoph",
               "W5\nJun", "W6\nJun", "W7\nSen", "W8\nSen")
  ) +
  scale_y_continuous(breaks = seq(0, 16, 2), limits = c(0, 16)) +
  scale_color_manual(values = c(
    "Strong Ties (Close & Active)" = "#2ca02c",
    "Weak Ties (Casual Contacts)"  = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Strong Ties (Close & Active)" = "#2ca02c",
    "Weak Ties (Casual Contacts)"  = "#d62728"
  )) +
  scale_shape_manual(values = c(17, 15)) +
  labs(
    title = "Bivariate Multi-Trajectory Latent Classes Across Eight Waves (K = 3)",
    subtitle = "Simultaneous co-evolution of Strong Ties (green) and Weak Ties (red) (N = 457 Egos, 2,598 Obs)",
    x = "College Academic Wave (Fall 2015 to Spring 2019)",
    y = "Average Degree (Alters Nominated)",
    color = "Relational Tier",
    shape = "Relational Tier",
    fill  = "Relational Tier"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 10),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig2_bivariate_lcga_trajectories.png", p_fig2, width = 10, height = 5.8, dpi = 300)
ggsave("output/figures/fig2_bivariate_lcga_trajectories.png", p_fig2, width = 10, height = 5.8, dpi = 300)

# -------------------------------------------------------------------
# 4. Table 3: Endogenous Concomitant Model Comparison (by Block)
# -------------------------------------------------------------------
cat("==> [5/6] Estimating Endogenous Concomitant Models by Block (Table 3)...\n")
df_biv_complete <- biv_data_all %>%
  inner_join(base_df, by = "egoid") %>%
  filter(
    !is.na(female), !is.na(race), !is.na(parents_income_num), !is.na(mom_college),
    !is.na(z_extraversion), !is.na(z_neuroticism), !is.na(z_agreeableness),
    !is.na(z_conscientiousness), !is.na(z_openness), !is.na(z_trust)
  )

biv_specs <- list(
  FLXMRglm(strong_degree ~ wave_num + I(wave_num^2), family = "poisson"),
  FLXMRglm(weak_degree   ~ wave_num + I(wave_num^2), family = "poisson")
)

fit_conc <- function(form, name) {
  set.seed(2026)
  if (is.null(form)) {
    mod <- flexmix(
      cbind(strong_degree, weak_degree) ~ wave_num + I(wave_num^2) | egoid,
      data = df_biv_complete, k = 3, model = biv_specs,
      control = list(iter.max = 300, minprior = 0.02)
    )
  } else {
    mod <- flexmix(
      cbind(strong_degree, weak_degree) ~ wave_num + I(wave_num^2) | egoid,
      data = df_biv_complete, k = 3, model = biv_specs,
      concomitant = FLXPmultinom(form),
      control = list(iter.max = 300, minprior = 0.02)
    )
  }
  tibble(
    Model = name,
    LogLik = logLik(mod)[1],
    Params = mod@df,
    AIC = AIC(mod),
    BIC = BIC(mod)
  )
}

m0_fit  <- fit_conc(NULL, "Model 0: Baseline Bivariate (No Covariates)")
m1a_fit <- fit_conc(~ parents_income_num + mom_college, "Model 1a: Family SES Only (Income, Mom College)")
m1b_fit <- fit_conc(~ female + race, "Model 1b: Gender + Race/Ethnicity")
m1c_fit <- fit_conc(~ female + race + parents_income_num + mom_college, "Model 1c: All Demographics (Gender, Race, SES)")
m2a_fit <- fit_conc(~ z_trust, "Model 2a: Generalized Trust Only")
m2b_fit <- fit_conc(~ z_extraversion, "Model 2b: Extraversion Only")
m2c_fit <- fit_conc(~ z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness, "Model 2c: Big Five Personality Traits")
m2d_fit <- fit_conc(~ z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust, "Model 2d: All Dispositions (Big Five + Trust)")
m3_fit  <- fit_conc(~ female + race + parents_income_num + mom_college +
                      z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust, 
                    "Model 3: Full Specification (Demographics + Dispositions)")

conc_table <- bind_rows(m0_fit, m1a_fit, m1b_fit, m1c_fit, m2a_fit, m2b_fit, m2c_fit, m2d_fit, m3_fit) %>%
  mutate(
    delta_BIC = BIC - min(BIC),
    LRT_stat = 2 * (LogLik - m0_fit$LogLik),
    df_diff  = Params - m0_fit$Params,
    p_val    = ifelse(df_diff > 0, 1 - pchisq(LRT_stat, df_diff), NA)
  )

write.csv(conc_table, "output/tables/table3_bivariate_concomitant_model_comparison.csv", row.names = FALSE)

tab3_rows <- conc_table %>%
  mutate(
    Clean_Model = case_when(
      grepl("Model 0", Model)  ~ "Model 0: Empty Baseline (No Covariates)",
      grepl("Model 1a", Model) ~ "Model 1a: Family SES (Income, Mother's College)",
      grepl("Model 1b", Model) ~ "Model 1b: Gender Identity + Race/Ethnicity",
      grepl("Model 1c", Model) ~ "Model 1c: All Demographics (Gender, Race, SES)",
      grepl("Model 2a", Model) ~ "Model 2a: Generalized Trust Only",
      grepl("Model 2b", Model) ~ "Model 2b: Extraversion Only",
      grepl("Model 2c", Model) ~ "Model 2c: Big Five Personality Traits",
      grepl("Model 2d", Model) ~ "Model 2d: All Dispositions (Big Five + Trust)",
      grepl("Model 3", Model)  ~ "Model 3: Full Multivariable Model",
      TRUE ~ Model
    ),
    LL = sprintf("%.1f", LogLik),
    Par = as.character(Params),
    AIC_str = sprintf("%.1f", AIC),
    BIC_str = sprintf("%.1f", BIC),
    LRT_str = ifelse(is.na(p_val), "---", sprintf("%.2f", LRT_stat)),
    df_str = ifelse(is.na(p_val), "---", as.character(df_diff)),
    p_str = ifelse(is.na(p_val), "---", ifelse(p_val < 0.001, "< .001", sprintf("%.3f", p_val)))
  )

md3 <- c(
  "| Model Specification | LL | Par | AIC | BIC | χ² | p-value |",
  "|:---|:---:|:---:|:---:|:---:|:---:|:---:|",
  "| **Baseline Specification** | | | | | | |",
  paste0("| ", tab3_rows$Clean_Model[1], " | ", tab3_rows$LL[1], " | ", tab3_rows$Par[1], " | ", tab3_rows$AIC_str[1], " | ", tab3_rows$BIC_str[1], " | ", tab3_rows$LRT_str[1], " | ", tab3_rows$p_str[1], " |"),
  "| **Sociodemographic Predictor Blocks** | | | | | | |",
  paste0("| ", tab3_rows$Clean_Model[2], " | ", tab3_rows$LL[2], " | ", tab3_rows$Par[2], " | ", tab3_rows$AIC_str[2], " | ", tab3_rows$BIC_str[2], " | ", tab3_rows$LRT_str[2], " | ", tab3_rows$p_str[2], " |"),
  paste0("| ", tab3_rows$Clean_Model[3], " | ", tab3_rows$LL[3], " | ", tab3_rows$Par[3], " | ", tab3_rows$AIC_str[3], " | ", tab3_rows$BIC_str[3], " | ", tab3_rows$LRT_str[3], " | ", tab3_rows$p_str[3], " |"),
  paste0("| ", tab3_rows$Clean_Model[4], " | ", tab3_rows$LL[4], " | ", tab3_rows$Par[4], " | ", tab3_rows$AIC_str[4], " | ", tab3_rows$BIC_str[4], " | ", tab3_rows$LRT_str[4], " | ", tab3_rows$p_str[4], " |"),
  "| **Psychological Disposition Blocks** | | | | | | |",
  paste0("| ", tab3_rows$Clean_Model[5], " | ", tab3_rows$LL[5], " | ", tab3_rows$Par[5], " | ", tab3_rows$AIC_str[5], " | ", tab3_rows$BIC_str[5], " | ", tab3_rows$LRT_str[5], " | ", tab3_rows$p_str[5], " |"),
  paste0("| ", tab3_rows$Clean_Model[6], " | ", tab3_rows$LL[6], " | ", tab3_rows$Par[6], " | ", tab3_rows$AIC_str[6], " | ", tab3_rows$BIC_str[6], " | ", tab3_rows$LRT_str[6], " | ", tab3_rows$p_str[6], " |"),
  paste0("| ", tab3_rows$Clean_Model[7], " | ", tab3_rows$LL[7], " | ", tab3_rows$Par[7], " | ", tab3_rows$AIC_str[7], " | ", tab3_rows$BIC_str[7], " | ", tab3_rows$LRT_str[7], " | ", tab3_rows$p_str[7], " |"),
  paste0("| ", tab3_rows$Clean_Model[8], " | ", tab3_rows$LL[8], " | ", tab3_rows$Par[8], " | ", tab3_rows$AIC_str[8], " | ", tab3_rows$BIC_str[8], " | ", tab3_rows$LRT_str[8], " | ", tab3_rows$p_str[8], " |"),
  "| **Combined Specification** | | | | | | |",
  paste0("| ", tab3_rows$Clean_Model[9], " | ", tab3_rows$LL[9], " | ", tab3_rows$Par[9], " | ", tab3_rows$AIC_str[9], " | ", tab3_rows$BIC_str[9], " | ", tab3_rows$LRT_str[9], " | ", tab3_rows$p_str[9], " |")
)
writeLines(md3, "cache/table3_bivariate_concomitant_model_comparison.md")

# -------------------------------------------------------------------
# 5. Table 4 & Figures 3-4: Direct Endogenous flexmix Estimates & Marginal Effects
# -------------------------------------------------------------------
cat("==> [6/6] Generating Table 4 (Direct flexmix Parameters), Figure 3 (Forest Plot), and Figure 4 (Marginal Effects)...\n")

# Fit the full multivariable concomitant model directly to retain the full flexmix object
set.seed(2026)
m3_full_obj <- flexmix(
  cbind(strong_degree, weak_degree) ~ wave_num + I(wave_num^2) | egoid,
  data = df_biv_complete, k = 3, model = biv_specs,
  concomitant = FLXPmultinom(~ female + race + parents_income_num + mom_college +
    z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust),
  control = list(iter.max = 300, minprior = 0.02)
)

# Extract full variance-covariance matrix of all model parameters
vc_full <- flexmix:::VarianceCovariance(m3_full_obj)
concom_idx <- grep("^concomitant_", names(vc_full$coef))
concom_coef <- vc_full$coef[concom_idx]
concom_vcov <- vc_full$vcov[concom_idx, concom_idx]

# Map flexmix components to substantive trajectory archetypes:
# Comp 1 = High-Core Conservers (baseline parameter vector = 0)
# Comp 2 = Accelerated Winnowers (modal group)
# Comp 3 = Network Conservers

p_names <- sub("concomitant_Comp.2.", "", names(concom_coef)[1:14])
b_c2 <- concom_coef[paste0("concomitant_Comp.2.", p_names)]
b_c3 <- concom_coef[paste0("concomitant_Comp.3.", p_names)]

# Re-reference to modal group: Accelerated Winnowers (Comp 2)
# Contrast A: Network Conservers vs Accelerated Winnowers (Comp 3 - Comp 2)
est_net <- b_c3 - b_c2
se_net  <- numeric(length(p_names))
names(se_net) <- p_names
for (pn in p_names) {
  n3 <- paste0("concomitant_Comp.3.", pn)
  n2 <- paste0("concomitant_Comp.2.", pn)
  var_diff <- concom_vcov[n3, n3] + concom_vcov[n2, n2] - 2 * concom_vcov[n3, n2]
  se_net[pn] <- sqrt(var_diff)
}

tidy_net <- tibble(
  Comparison_Class = "Network Conservers",
  Term = p_names,
  Estimate = est_net,
  SE = se_net,
  Z = est_net / se_net,
  P_Value = 2 * (1 - pnorm(abs(est_net / se_net))),
  OR = exp(est_net),
  OR_Low = exp(est_net - 1.96 * se_net),
  OR_High = exp(est_net + 1.96 * se_net)
)

# Contrast B: High-Core Conservers vs Accelerated Winnowers (Comp 1 - Comp 2 = 0 - Comp 2)
est_high <- -b_c2
se_high  <- numeric(length(p_names))
names(se_high) <- p_names
for (pn in p_names) {
  n2 <- paste0("concomitant_Comp.2.", pn)
  se_high[pn] <- sqrt(concom_vcov[n2, n2])
}

tidy_high <- tibble(
  Comparison_Class = "High-Core Conservers",
  Term = p_names,
  Estimate = est_high,
  SE = se_high,
  Z = est_high / se_high,
  P_Value = 2 * (1 - pnorm(abs(est_high / se_high))),
  OR = exp(est_high),
  OR_Low = exp(est_high - 1.96 * se_high),
  OR_High = exp(est_high + 1.96 * se_high)
)

tidy_full_biv <- bind_rows(tidy_net, tidy_high)
write.csv(tidy_full_biv, "output/tables/table4_bivariate_mlogit_predictors.csv", row.names = FALSE)

# Generate Table 4 markdown (Panel A & Panel B)
term_labels <- c(
  "female"                   = "Gender Identity: Woman (ref: Man)",
  "raceAsian"                = "Race: Asian (ref: White)",
  "raceBlack"                = "Race: Black (ref: White)",
  "raceHispanic/Latino"      = "Race: Hispanic/Latino (ref: White)",
  "raceOther/International"  = "Race: Other/International (ref: White)",
  "parents_income_num"       = "Parents' Income (1-8 Ordinal)",
  "mom_college"              = "Mother College Degree (ref: Non-degree)",
  "z_extraversion"           = "Extraversion (z-score)",
  "z_neuroticism"            = "Neuroticism (z-score)",
  "z_agreeableness"          = "Agreeableness (z-score)",
  "z_conscientiousness"      = "Conscientiousness (z-score)",
  "z_openness"               = "Openness to Experience (z-score)",
  "z_trust"                  = "Generalized Trust (z-score)"
)

panel_a <- tidy_full_biv %>% filter(Comparison_Class == "Network Conservers", Term != "(Intercept)")
panel_b <- tidy_full_biv %>% filter(Comparison_Class == "High-Core Conservers", Term != "(Intercept)")

format_panel_rows <- function(df_p) {
  apply(df_p, 1, function(r) {
    t_name <- term_labels[r["Term"]]
    est_se <- paste0(sprintf("%.2f", as.numeric(r["Estimate"])), " (", sprintf("%.2f", as.numeric(r["SE"])), ")")
    or_ci  <- paste0(sprintf("%.2f", as.numeric(r["OR"])), " [", sprintf("%.2f", as.numeric(r["OR_Low"])), ", ", sprintf("%.2f", as.numeric(r["OR_High"])), "]")
    p_v    <- as.numeric(r["P_Value"])
    p_str  <- ifelse(p_v < 0.001, "< .001", sprintf("%.3f", p_v))
    paste0("| ", t_name, " | ", est_se, " | ", or_ci, " | ", p_str, " |")
  })
}

md4 <- c(
  "| Predictor Variable | Estimate (SE) | Odds Ratio [95% CI] | p-value |",
  "|:---|:---:|:---:|:---:|",
  "| **Panel A: Network Conservers (vs. Accelerated Winnowers)** | | | |",
  format_panel_rows(panel_a),
  "| **Panel B: High-Core Conservers (vs. Accelerated Winnowers)** | | | |",
  format_panel_rows(panel_b)
)
writeLines(md4, "cache/table4_bivariate_mlogit_predictors.md")

# Plot Figure 3: Forest Plot of Odds Ratios directly from flexmix
plot_forest_df <- tidy_full_biv %>%
  filter(Term != "(Intercept)") %>%
  mutate(
    Clean_Term = factor(term_labels[Term], levels = rev(unname(term_labels))),
    Significant = ifelse(P_Value < 0.05, "p < 0.05", "Not Significant")
  )

p_fig3 <- ggplot(plot_forest_df, aes(x = OR, y = Clean_Term, color = Comparison_Class)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "grey40") +
  geom_errorbar(aes(xmin = OR_Low, xmax = OR_High), width = 0.25, linewidth = 0.8,
                position = position_dodge(width = 0.5)) +
  geom_point(aes(shape = Significant), size = 2.8, position = position_dodge(width = 0.5)) +
  scale_x_log10(breaks = c(0.2, 0.5, 1.0, 2.0, 4.0, 8.0)) +
  scale_color_manual(values = c("#1f77b4", "#2ca02c")) +
  scale_shape_manual(values = c("Not Significant" = 1, "p < 0.05" = 16)) +
  labs(
    title = "Endogenous Multinomial Logistic Odds Ratios from Bivariate LCGA",
    subtitle = "Estimated simultaneously in flexmix; Reference Category: Accelerated Winnowers (N = 433)",
    x = "Odds Ratio (Relative Risk Ratio, Log Scale)",
    y = NULL,
    color = "Comparison Class",
    shape = "Significance"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig3_bivariate_mlogit_forest_plot.png", p_fig3, width = 9.5, height = 7.0, dpi = 300)
ggsave("output/figures/fig3_bivariate_mlogit_forest_plot.png", p_fig3, width = 9.5, height = 7.0, dpi = 300)

# -------------------------------------------------------------------
# 6. Figure 4: Model-Implied Marginal Class Probabilities (Marginal Effects)
# -------------------------------------------------------------------
cat("==> Generating Figure 4 (Model-Implied Marginal Class Probabilities)...\n")

form_conc <- ~ female + race + parents_income_num + mom_college +
  z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust

# Function to simulate predicted class probabilities and 95% CIs
predict_prob_ci <- function(X_mat, beta_draws) {
  n_grid <- nrow(X_mat)
  n_draws <- nrow(beta_draws)
  prob_draws <- array(0, dim = c(n_grid, 3, n_draws))
  
  for (d in 1:n_draws) {
    b_c2_d <- beta_draws[d, 1:14]
    b_c3_d <- beta_draws[d, 15:28]
    eta1 <- rep(0, n_grid)
    eta2 <- as.vector(X_mat %*% b_c2_d)
    eta3 <- as.vector(X_mat %*% b_c3_d)
    max_eta <- pmax(eta1, eta2, eta3)
    exp1 <- exp(eta1 - max_eta)
    exp2 <- exp(eta2 - max_eta)
    exp3 <- exp(eta3 - max_eta)
    sum_exp <- exp1 + exp2 + exp3
    prob_draws[, 1, d] <- exp1 / sum_exp
    prob_draws[, 2, d] <- exp2 / sum_exp
    prob_draws[, 3, d] <- exp3 / sum_exp
  }
  
  res <- list()
  class_names <- c("High-Core Conservers", "Accelerated Winnowers", "Network Conservers")
  for (k in 1:3) {
    res[[class_names[k]]] <- tibble(
      Class = class_names[k],
      Mean = apply(prob_draws[, k, ], 1, mean),
      Median = apply(prob_draws[, k, ], 1, median),
      Low = apply(prob_draws[, k, ], 1, quantile, probs = 0.025),
      High = apply(prob_draws[, k, ], 1, quantile, probs = 0.975)
    )
  }
  bind_rows(res)
}

set.seed(2026)
beta_draws <- MASS::mvrnorm(1000, mu = concom_coef, Sigma = concom_vcov)

# Grid for Generalized Trust (-2.5 to 2.5)
grid_trust <- tibble(
  z_trust = seq(-2.5, 2.5, length.out = 100),
  female = mean(df_biv_complete$female),
  race = factor("White", levels = levels(factor(df_biv_complete$race))),
  parents_income_num = mean(df_biv_complete$parents_income_num),
  mom_college = mean(df_biv_complete$mom_college),
  z_extraversion = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_trust <- model.matrix(form_conc, data = grid_trust)
ci_trust <- predict_prob_ci(X_grid_trust, beta_draws) %>%
  mutate(z_trust = rep(grid_trust$z_trust, 3))

# Grid for Extraversion (-2.5 to 2.5)
grid_ext <- tibble(
  z_extraversion = seq(-2.5, 2.5, length.out = 100),
  female = mean(df_biv_complete$female),
  race = factor("White", levels = levels(factor(df_biv_complete$race))),
  parents_income_num = mean(df_biv_complete$parents_income_num),
  mom_college = mean(df_biv_complete$mom_college),
  z_trust = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_ext <- model.matrix(form_conc, data = grid_ext)
ci_ext <- predict_prob_ci(X_grid_ext, beta_draws) %>%
  mutate(z_extraversion = rep(grid_ext$z_extraversion, 3))

# Combined Continuous Dispositions
ci_continuous <- bind_rows(
  ci_trust %>% mutate(Predictor = "A: Generalized Trust", Value = z_trust),
  ci_ext %>% mutate(Predictor = "B: Extraversion", Value = z_extraversion)
)

p_cont <- ggplot(ci_continuous, aes(x = Value, y = Mean, color = Class, fill = Class)) +
  geom_ribbon(aes(ymin = Low, ymax = High), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ Predictor, scales = "fixed", ncol = 2) +
  scale_color_manual(values = c("High-Core Conservers" = "#2ca02c", 
                                "Accelerated Winnowers" = "#d62728", 
                                "Network Conservers" = "#1f77b4")) +
  scale_fill_manual(values = c("High-Core Conservers" = "#2ca02c", 
                               "Accelerated Winnowers" = "#d62728", 
                               "Network Conservers" = "#1f77b4")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.75)) +
  scale_x_continuous(breaks = seq(-2, 2, 1)) +
  labs(
    title = "Model-Implied Marginal Class Probabilities from Bivariate LCGA",
    subtitle = "A: Continuous Psychological Dispositions (Generalized Trust & Extraversion)",
    x = "Standardized Trait Score (z-score)",
    y = "Predicted Probability of Class Membership",
    color = "Trajectory Class",
    fill  = "Trajectory Class"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(face = "bold", size = 10, hjust = 0.5, color = "black"),
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "none",
    panel.grid.minor = element_blank()
  )

# Grid for Race & Ethnicity
grid_race <- tibble(
  race = factor(levels(factor(df_biv_complete$race)), levels = levels(factor(df_biv_complete$race))),
  female = mean(df_biv_complete$female),
  parents_income_num = mean(df_biv_complete$parents_income_num),
  mom_college = mean(df_biv_complete$mom_college),
  z_trust = 0,
  z_extraversion = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_race <- model.matrix(form_conc, data = grid_race)
ci_race <- predict_prob_ci(X_grid_race, beta_draws) %>%
  mutate(race = rep(grid_race$race, 3))

race_clean_names <- c(
  "White" = "White",
  "Asian" = "Asian",
  "Black" = "Black",
  "Hispanic/Latino" = "Hispanic",
  "Other/International" = "Other/Intl"
)
ci_race_plot <- ci_race %>%
  mutate(clean_race = factor(race_clean_names[as.character(race)], 
                             levels = c("White", "Asian", "Black", "Hispanic", "Other/Intl")))

p_race_clean <- ggplot(ci_race_plot, aes(x = clean_race, y = Mean, color = Class)) +
  geom_pointrange(aes(ymin = Low, ymax = High), position = position_dodge(width = 0.5), size = 0.6) +
  scale_color_manual(values = c("High-Core Conservers" = "#2ca02c", 
                                "Accelerated Winnowers" = "#d62728", 
                                "Network Conservers" = "#1f77b4")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.85)) +
  labs(
    title = "B: Model-Implied Class Probabilities by Race and Ethnicity",
    x = "Racial/Ethnic Group",
    y = "Predicted Probability",
    color = "Trajectory Class"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 11, hjust = 0.5),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Composite Figure 4 via base grid
png("Plots/fig4_bivariate_marginal_effects.png", width = 8.5, height = 7.5, units = "in", res = 300)
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 1, heights = grid::unit(c(1.1, 1), "null"))))
print(p_cont, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
print(p_race_clean, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
dev.off()

# Copy to output/figures
file.copy("Plots/fig4_bivariate_marginal_effects.png", "output/figures/fig4_bivariate_marginal_effects.png", overwrite = TRUE)

cat("\n==> All bivariate models, tables, and figures generated successfully!\n")
