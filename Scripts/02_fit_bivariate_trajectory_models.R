#' ---
#' title: "02_fit_bivariate_trajectory_models.R"
#' description: "Trivariate Multi-Trajectory Poisson mixture modeling across Dunbar Cognitive Layers (Support Clique, Sympathy Shell, Periphery) over 8 waves"
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

cat("==> [1/6] Loading data and constructing 3-tier Dunbar cognitive layers...\n")
net_raw <- read_csv("data/raw/network_survey.csv", show_col_types = FALSE)
analytical_w18 <- readRDS("data/processed/degree_analytical_w18.rds")
base_df <- readRDS("data/processed/degree_analytical_w18_classified.rds") %>%
  dplyr::select(egoid, female, race, parents_income_num, mom_college, religion,
         z_extraversion, z_neuroticism, z_agreeableness,
         z_conscientiousness, z_openness, z_trust) %>%
  mutate(
    religion_3cat = factor(
      case_when(
        religion == "Catholic" ~ "Catholic",
        religion == "None" ~ "None",
        !is.na(religion) ~ "Other",
        TRUE ~ NA_character_
      ),
      levels = c("Catholic", "Other", "None") # Catholic as modal reference
    )
  )

# Define 3-Tier Dunbar Cognitive Layers:
# Tier 1 (Support Clique): Especially Close AND Daily contact (~4-5 alters)
# Tier 2 (Sympathy Shell): (Especially Close AND Weekly) OR (Merely Close AND Daily) (~4-5 alters)
# Tier 3 (Peripheral Perimeter): All other nominated alters (casual/dormant/monthly)
triv_data_all <- net_raw %>%
  filter(!is.na(egoid), !is.na(wave)) %>%
  mutate(wave_num = as.integer(gsub("\\D", "", wave))) %>%
  filter(wave_num <= 8, egoid %in% analytical_w18$egoid) %>%
  mutate(
    t1_clique    = (close == "EspeciallyClose" & freq == "Daily"),
    t2_sympathy  = (close == "EspeciallyClose" & freq == "Weekly") | (close == "MerelyClose" & freq == "Daily"),
    t3_periphery = !(t1_clique | t2_sympathy)
  ) %>%
  group_by(egoid, wave_num) %>%
  summarize(
    total_degree  = n(),
    t1_degree     = sum(t1_clique, na.rm = TRUE),
    t2_degree     = sum(t2_sympathy, na.rm = TRUE),
    t3_degree     = sum(t3_periphery, na.rm = TRUE),
    .groups = "drop"
  )

dir.create("Plots", showWarnings = FALSE, recursive = TRUE)
dir.create("cache", showWarnings = FALSE, recursive = TRUE)
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# -------------------------------------------------------------------
# 1. Table 1 & Figure 1: Aggregate Longitudinal Decomposition (Dunbar Layers)
# -------------------------------------------------------------------
cat("==> [2/6] Generating Table 1 and Figure 1 (Dunbar Layer Decomposition)...\n")
tab1_summary <- triv_data_all %>%
  group_by(wave_num) %>%
  summarize(
    n_egos = n(),
    Total_Mean = mean(total_degree),
    Total_SE   = sd(total_degree) / sqrt(n()),
    T1_Mean    = mean(t1_degree),
    T1_SE      = sd(t1_degree) / sqrt(n()),
    T2_Mean    = mean(t2_degree),
    T2_SE      = sd(t2_degree) / sqrt(n()),
    T3_Mean    = mean(t3_degree),
    T3_SE      = sd(t3_degree) / sqrt(n()),
    Core_Mean  = mean(t1_degree + t2_degree),
    Core_SE    = sd(t1_degree + t2_degree) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    T1_Pct   = T1_Mean / Total_Mean * 100,
    T2_Pct   = T2_Mean / Total_Mean * 100,
    T3_Pct   = T3_Mean / Total_Mean * 100,
    Core_Pct = Core_Mean / Total_Mean * 100
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

tab1_md <- tab1_summary %>%
  mutate(
    Wave_Label = wave_labels_full[as.character(wave_num)],
    Total_str  = paste0(sprintf("%.2f", Total_Mean), " (", sprintf("%.2f", Total_SE), ")"),
    T1_str     = paste0(sprintf("%.2f", T1_Mean), " (", sprintf("%.2f", T1_SE), ")"),
    T2_str     = paste0(sprintf("%.2f", T2_Mean), " (", sprintf("%.2f", T2_SE), ")"),
    Core_str   = paste0(sprintf("%.2f", Core_Mean), " (", sprintf("%.2f", Core_SE), ")"),
    T3_str     = paste0(sprintf("%.2f", T3_Mean), " (", sprintf("%.2f", T3_SE), ")"),
    Core_pct_str = paste0(sprintf("%.1f", Core_Pct), "%")
  ) %>%
  dplyr::select(Wave_Label, n_egos, Total_str, T1_str, T2_str, Core_str, T3_str, Core_pct_str)

md1 <- c(
  "| Academic Wave | Egos (N) | Total Degree (SE) | Support Clique (SE) | Sympathy Shell (SE) | Combined Core (SE) | Periphery (SE) | Core Share (%) |",
  "|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|",
  apply(tab1_md, 1, function(r) {
    paste0("| ", r["Wave_Label"], " | ", r["n_egos"], " | ", r["Total_str"], " | ", r["T1_str"], " | ", r["T2_str"], " | ", r["Core_str"], " | ", r["T3_str"], " | ", r["Core_pct_str"], " |")
  })
)
writeLines(md1, "cache/table1_bivariate_trajectory_means.md")

# Plot Figure 1
fig1_lines <- bind_rows(
  tab1_summary %>% dplyr::select(wave_num, Mean = Total_Mean, SE = Total_SE) %>% mutate(Tier = "Total Network Degree"),
  tab1_summary %>% dplyr::select(wave_num, Mean = T1_Mean, SE = T1_SE) %>% mutate(Tier = "Tier 1: Support Clique (Daily & Close)"),
  tab1_summary %>% dplyr::select(wave_num, Mean = T2_Mean, SE = T2_SE) %>% mutate(Tier = "Tier 2: Sympathy Shell (Weekly / Active)"),
  tab1_summary %>% dplyr::select(wave_num, Mean = T3_Mean, SE = T3_SE) %>% mutate(Tier = "Tier 3: Periphery (Casual / Dormant)")
) %>%
  mutate(
    Tier = factor(Tier, levels = c(
      "Total Network Degree",
      "Tier 1: Support Clique (Daily & Close)",
      "Tier 2: Sympathy Shell (Weekly / Active)",
      "Tier 3: Periphery (Casual / Dormant)"
    ))
  )

p_fig1 <- ggplot(fig1_lines, aes(x = wave_num, y = Mean, color = Tier, shape = Tier, fill = Tier, linetype = Tier)) +
  geom_ribbon(aes(ymin = Mean - 1.96 * SE, ymax = Mean + 1.96 * SE), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh", "W2\nFrosh", "W3\nSoph", "W4\nSoph",
               "W5\nJun", "W6\nJun", "W7\nSen", "W8\nSen")
  ) +
  scale_y_continuous(breaks = seq(0, 16, 2), limits = c(0, 16)) +
  scale_color_manual(values = c(
    "Total Network Degree"                     = "#222222",
    "Tier 1: Support Clique (Daily & Close)"    = "#2ca02c",
    "Tier 2: Sympathy Shell (Weekly / Active)"  = "#1f77b4",
    "Tier 3: Periphery (Casual / Dormant)"      = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Total Network Degree"                     = "#222222",
    "Tier 1: Support Clique (Daily & Close)"    = "#2ca02c",
    "Tier 2: Sympathy Shell (Weekly / Active)"  = "#1f77b4",
    "Tier 3: Periphery (Casual / Dormant)"      = "#d62728"
  )) +
  scale_shape_manual(values = c(18, 17, 16, 15)) +
  scale_linetype_manual(values = c("dashed", "solid", "longdash", "dotted")) +
  labs(
    title = "Decomposing Ego Network Evolution across Eight Collegiate Waves",
    subtitle = "Dunbar Cognitive Layers: Support Clique (green), Sympathy Shell (blue), and Periphery (red) (N = 457)",
    x = "College Academic Wave (Fall 2015 to Spring 2019)",
    y = "Average Alter Nominations",
    color = "Relational Layer",
    fill  = "Relational Layer",
    shape = "Relational Layer",
    linetype = "Relational Layer"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) +
  guides(
    color = guide_legend(nrow = 2, byrow = TRUE),
    fill  = guide_legend(nrow = 2, byrow = TRUE),
    shape = guide_legend(nrow = 2, byrow = TRUE),
    linetype = guide_legend(nrow = 2, byrow = TRUE)
  )

ggsave("Plots/fig1_compound_strong_weak_trajectories.png", p_fig1, width = 8.5, height = 5.6, dpi = 300)
ggsave("output/figures/fig1_compound_strong_weak_trajectories.png", p_fig1, width = 8.5, height = 5.6, dpi = 300)

# -------------------------------------------------------------------
# 2. Table 2: Model Selection for Trivariate Poisson LCGA (K = 1..5)
# -------------------------------------------------------------------
cat("==> [3/6] Estimating Trivariate LCGA models for K = 1..5 (Table 2)...\n")
triv_specs <- list(
  FLXMRglm(t1_degree ~ wave_num + I(wave_num^2), family = "poisson"),
  FLXMRglm(t2_degree ~ wave_num + I(wave_num^2), family = "poisson"),
  FLXMRglm(t3_degree ~ wave_num + I(wave_num^2), family = "poisson")
)

fit_triv_lcga <- function(k_val) {
  set.seed(2026)
  mod <- flexmix(
    cbind(t1_degree, t2_degree, t3_degree) ~ wave_num + I(wave_num^2) | egoid,
    data = triv_data_all, k = k_val, model = triv_specs,
    control = list(iter.max = 300, minprior = 0.02)
  )
  tibble(
    K = k_val,
    LogLik = logLik(mod)[1],
    Par = mod@df,
    AIC = AIC(mod),
    BIC = BIC(mod)
  )
}

triv_k_fits <- lapply(1:5, fit_triv_lcga)
tab2_triv <- bind_rows(triv_k_fits) %>%
  mutate(delta_BIC = BIC - min(BIC))

write.csv(tab2_triv, "output/tables/table2_bivariate_model_selection.csv", row.names = FALSE)

tab2_rows <- tab2_triv %>%
  mutate(
    K_str = paste0("K = ", K),
    LL = sprintf("%.1f", LogLik),
    AIC_str = sprintf("%.1f", AIC),
    BIC_str = sprintf("%.1f", BIC),
    dBIC_str = sprintf("%.1f", delta_BIC)
  )

md2 <- c(
  "| Latent Classes | Log-Likelihood | Par | AIC | BIC | ΔBIC |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab2_rows, 1, function(r) {
    paste0("| ", r["K_str"], " | ", r["LL"], " | ", r["Par"], " | ", r["AIC_str"], " | ", r["BIC_str"], " | ", r["dBIC_str"], " |")
  })
)
writeLines(md2, "cache/table2_bivariate_model_selection.md")

# -------------------------------------------------------------------
# 3. Figure 2: Trajectory Profiles for Optimal K = 4 Solution
# -------------------------------------------------------------------
cat("==> [4/6] Generating Trivariate LCGA trajectory profiles plot for K = 4 (Figure 2)...\n")
set.seed(2026)
mod_triv4 <- flexmix(
  cbind(t1_degree, t2_degree, t3_degree) ~ wave_num + I(wave_num^2) | egoid,
  data = triv_data_all, k = 4, model = triv_specs,
  control = list(iter.max = 300, minprior = 0.02)
)

ego_assignments_triv4 <- tibble(
  egoid = triv_data_all$egoid,
  clust = clusters(mod_triv4)
) %>%
  group_by(egoid) %>%
  summarize(raw_class = as.character(names(which.max(table(clust)))), .groups = "drop")

# Class mapping based on empirical morphology:
# Raw 4 = Expansive Periphery Conservers (n = 97, 21.2%)
# Raw 3 = Moderate Winnowers / Shell-Oriented (n = 124, 27.1%)
# Raw 1 = Extreme Peripheral Winnowers (n = 143, 31.3%)
# Raw 2 = Clique Conservers (n = 93, 20.4%)

ego_classified_triv4 <- ego_assignments_triv4 %>%
  mutate(
    class_label = factor(
      case_when(
        raw_class == "4" ~ "Expansive Periphery Conservers\n(n = 97, 21.2%)",
        raw_class == "3" ~ "Moderate Winnowers / Shell-Oriented\n(n = 124, 27.1%)",
        raw_class == "1" ~ "Extreme Peripheral Winnowers\n(n = 143, 31.3%)",
        raw_class == "2" ~ "Clique Conservers\n(n = 93, 20.4%)"
      ),
      levels = c(
        "Expansive Periphery Conservers\n(n = 97, 21.2%)",
        "Moderate Winnowers / Shell-Oriented\n(n = 124, 27.1%)",
        "Extreme Peripheral Winnowers\n(n = 143, 31.3%)",
        "Clique Conservers\n(n = 93, 20.4%)"
      )
    )
  )

triv_long_plot4 <- triv_data_all %>%
  inner_join(ego_classified_triv4, by = "egoid")

triv_means_plot4 <- triv_long_plot4 %>%
  group_by(class_label, wave_num) %>%
  summarize(
    T1_Mean = mean(t1_degree), T1_SE = sd(t1_degree) / sqrt(n()),
    T2_Mean = mean(t2_degree), T2_SE = sd(t2_degree) / sqrt(n()),
    T3_Mean = mean(t3_degree), T3_SE = sd(t3_degree) / sqrt(n()),
    .groups = "drop"
  )

triv_lines4 <- bind_rows(
  triv_means_plot4 %>% dplyr::select(class_label, wave_num, Mean = T1_Mean, SE = T1_SE) %>% mutate(Tier = "Tier 1: Support Clique (Daily & Close)"),
  triv_means_plot4 %>% dplyr::select(class_label, wave_num, Mean = T2_Mean, SE = T2_SE) %>% mutate(Tier = "Tier 2: Sympathy Shell (Weekly / Active)"),
  triv_means_plot4 %>% dplyr::select(class_label, wave_num, Mean = T3_Mean, SE = T3_SE) %>% mutate(Tier = "Tier 3: Periphery (Casual / Dormant)")
) %>%
  mutate(
    Tier = factor(Tier, levels = c(
      "Tier 1: Support Clique (Daily & Close)",
      "Tier 2: Sympathy Shell (Weekly / Active)",
      "Tier 3: Periphery (Casual / Dormant)"
    ))
  )

p_fig2 <- ggplot(triv_lines4, aes(x = wave_num, y = Mean, color = Tier, shape = Tier, fill = Tier, linetype = Tier)) +
  geom_ribbon(aes(ymin = pmax(0, Mean - 1.96 * SE), ymax = Mean + 1.96 * SE), alpha = 0.18, color = NA) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5) +
  facet_wrap(~ class_label, ncol = 4) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh", "W2\nFrosh", "W3\nSoph", "W4\nSoph",
               "W5\nJun", "W6\nJun", "W7\nSen", "W8\nSen")
  ) +
  scale_y_continuous(breaks = seq(0, 10, 2), limits = c(0, 10.5)) +
  scale_color_manual(values = c(
    "Tier 1: Support Clique (Daily & Close)"    = "#2ca02c",
    "Tier 2: Sympathy Shell (Weekly / Active)"  = "#1f77b4",
    "Tier 3: Periphery (Casual / Dormant)"      = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Tier 1: Support Clique (Daily & Close)"    = "#2ca02c",
    "Tier 2: Sympathy Shell (Weekly / Active)"  = "#1f77b4",
    "Tier 3: Periphery (Casual / Dormant)"      = "#d62728"
  )) +
  scale_shape_manual(values = c(17, 16, 15)) +
  scale_linetype_manual(values = c("solid", "longdash", "dotted")) +
  labs(
    title = "Trivariate Multi-Trajectory Latent Classes Across Eight Waves (Dunbar Cognitive Layers, K = 4)",
    subtitle = "Simultaneous co-evolution of Support Clique (green), Sympathy Shell (blue), and Periphery (red) (N = 457 Egos, 2,598 Obs)",
    x = "College Academic Wave (Fall 2015 to Spring 2019)",
    y = "Average Alter Nominations in Layer",
    color = "Relational Layer",
    shape = "Relational Layer",
    fill  = "Relational Layer",
    linetype = "Relational Layer"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 9.5, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 9),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) +
  guides(
    color = guide_legend(nrow = 1, byrow = TRUE),
    fill  = guide_legend(nrow = 1, byrow = TRUE),
    shape = guide_legend(nrow = 1, byrow = TRUE),
    linetype = guide_legend(nrow = 1, byrow = TRUE)
  )

ggsave("Plots/fig2_bivariate_lcga_trajectories.png", p_fig2, width = 12, height = 5.5, dpi = 300)
ggsave("output/figures/fig2_bivariate_lcga_trajectories.png", p_fig2, width = 12, height = 5.5, dpi = 300)

# -------------------------------------------------------------------
# 4. Table 3: Endogenous Concomitant Model Comparison (by Block, N = 432, K = 4)
# -------------------------------------------------------------------
cat("==> [5/6] Estimating Endogenous Concomitant Models by Block for K = 4 (Table 3)...\n")
df_triv_comp <- triv_data_all %>%
  inner_join(base_df, by = "egoid") %>%
  filter(
    !is.na(female), !is.na(race), !is.na(parents_income_num), !is.na(mom_college),
    !is.na(religion_3cat),
    !is.na(z_extraversion), !is.na(z_neuroticism), !is.na(z_agreeableness),
    !is.na(z_conscientiousness), !is.na(z_openness), !is.na(z_trust)
  )

fit_triv4_conc <- function(form, name) {
  set.seed(2026)
  if (is.null(form)) {
    mod <- flexmix(
      cbind(t1_degree, t2_degree, t3_degree) ~ wave_num + I(wave_num^2) | egoid,
      data = df_triv_comp, k = 4, model = triv_specs,
      control = list(iter.max = 300, minprior = 0.02)
    )
  } else {
    mod <- flexmix(
      cbind(t1_degree, t2_degree, t3_degree) ~ wave_num + I(wave_num^2) | egoid,
      data = df_triv_comp, k = 4, model = triv_specs,
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

m0_fit4  <- fit_triv4_conc(NULL, "Model 0: Empty Baseline (No Covariates)")
m1a_fit4 <- fit_triv4_conc(~ parents_income_num + mom_college, "Model 1a: Family SES (Income, Mother's College)")
m1b_fit4 <- fit_triv4_conc(~ female, "Model 1b: Gender Identity Only")
m1c_fit4 <- fit_triv4_conc(~ religion_3cat, "Model 1c: Religious Affiliation (Catholic, Other, None)")
m1d_fit4 <- fit_triv4_conc(~ race, "Model 1d: Race/Ethnicity Only")
m1e_fit4 <- fit_triv4_conc(~ female + race + parents_income_num + mom_college + religion_3cat, 
                           "Model 1e: All Sociodemographics (Gender, Race, SES, Religion)")
m2a_fit4 <- fit_triv4_conc(~ z_trust, "Model 2a: Generalized Trust Only")
m2b_fit4 <- fit_triv4_conc(~ z_extraversion, "Model 2b: Extraversion Only")
m2c_fit4 <- fit_triv4_conc(~ z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness, 
                           "Model 2c: Big Five Personality Traits")
m2d_fit4 <- fit_triv4_conc(~ z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust, 
                           "Model 2d: All Dispositions (Big Five + Trust)")
m3_fit4  <- fit_triv4_conc(~ female + race + parents_income_num + mom_college + religion_3cat +
                             z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust, 
                           "Model 3: Full Multivariable Model")

conc_triv4_table <- bind_rows(
  m0_fit4, m1a_fit4, m1b_fit4, m1c_fit4, m1d_fit4, m1e_fit4,
  m2a_fit4, m2b_fit4, m2c_fit4, m2d_fit4, m3_fit4
) %>%
  mutate(
    delta_BIC = BIC - min(BIC),
    LRT_stat = 2 * (LogLik - m0_fit4$LogLik),
    df_diff  = Params - m0_fit4$Params,
    p_val    = ifelse(df_diff > 0, 1 - pchisq(LRT_stat, df_diff), NA)
  )

write.csv(conc_triv4_table, "output/tables/table3_bivariate_concomitant_model_comparison.csv", row.names = FALSE)

tab3_rows4 <- conc_triv4_table %>%
  mutate(
    Clean_Model = Model,
    LL = sprintf("%.1f", LogLik),
    Par = as.character(Params),
    AIC_str = sprintf("%.1f", AIC),
    BIC_str = sprintf("%.1f", BIC),
    LRT_str = ifelse(is.na(p_val), "---", sprintf("%.2f", LRT_stat)),
    df_str = ifelse(is.na(p_val), "---", as.character(df_diff)),
    p_str = ifelse(is.na(p_val), "---", ifelse(p_val < 0.001, "< .001", sprintf("%.3f", p_val)))
  )

md3_k4 <- c(
  "| Model Specification | LL | Par | AIC | BIC | χ² | p-value |",
  "|:---|:---:|:---:|:---:|:---:|:---:|:---:|",
  "| **Baseline Specification** | | | | | | |",
  paste0("| ", tab3_rows4$Clean_Model[1], " | ", tab3_rows4$LL[1], " | ", tab3_rows4$Par[1], " | ", tab3_rows4$AIC_str[1], " | ", tab3_rows4$BIC_str[1], " | ", tab3_rows4$LRT_str[1], " | ", tab3_rows4$p_str[1], " |"),
  "| **Sociodemographic Predictor Blocks** | | | | | | |",
  paste0("| ", tab3_rows4$Clean_Model[2], " | ", tab3_rows4$LL[2], " | ", tab3_rows4$Par[2], " | ", tab3_rows4$AIC_str[2], " | ", tab3_rows4$BIC_str[2], " | ", tab3_rows4$LRT_str[2], " | ", tab3_rows4$p_str[2], " |"),
  paste0("| ", tab3_rows4$Clean_Model[3], " | ", tab3_rows4$LL[3], " | ", tab3_rows4$Par[3], " | ", tab3_rows4$AIC_str[3], " | ", tab3_rows4$BIC_str[3], " | ", tab3_rows4$LRT_str[3], " | ", tab3_rows4$p_str[3], " |"),
  paste0("| ", tab3_rows4$Clean_Model[4], " | ", tab3_rows4$LL[4], " | ", tab3_rows4$Par[4], " | ", tab3_rows4$AIC_str[4], " | ", tab3_rows4$BIC_str[4], " | ", tab3_rows4$LRT_str[4], " | ", tab3_rows4$p_str[4], " |"),
  paste0("| ", tab3_rows4$Clean_Model[5], " | ", tab3_rows4$LL[5], " | ", tab3_rows4$Par[5], " | ", tab3_rows4$AIC_str[5], " | ", tab3_rows4$BIC_str[5], " | ", tab3_rows4$LRT_str[5], " | ", tab3_rows4$p_str[5], " |"),
  paste0("| ", tab3_rows4$Clean_Model[6], " | ", tab3_rows4$LL[6], " | ", tab3_rows4$Par[6], " | ", tab3_rows4$AIC_str[6], " | ", tab3_rows4$BIC_str[6], " | ", tab3_rows4$LRT_str[6], " | ", tab3_rows4$p_str[6], " |"),
  "| **Psychological Disposition Blocks** | | | | | | |",
  paste0("| ", tab3_rows4$Clean_Model[7], " | ", tab3_rows4$LL[7], " | ", tab3_rows4$Par[7], " | ", tab3_rows4$AIC_str[7], " | ", tab3_rows4$BIC_str[7], " | ", tab3_rows4$LRT_str[7], " | ", tab3_rows4$p_str[7], " |"),
  paste0("| ", tab3_rows4$Clean_Model[8], " | ", tab3_rows4$LL[8], " | ", tab3_rows4$Par[8], " | ", tab3_rows4$AIC_str[8], " | ", tab3_rows4$BIC_str[8], " | ", tab3_rows4$LRT_str[8], " | ", tab3_rows4$p_str[8], " |"),
  paste0("| ", tab3_rows4$Clean_Model[9], " | ", tab3_rows4$LL[9], " | ", tab3_rows4$Par[9], " | ", tab3_rows4$AIC_str[9], " | ", tab3_rows4$BIC_str[9], " | ", tab3_rows4$LRT_str[9], " | ", tab3_rows4$p_str[9], " |"),
  paste0("| ", tab3_rows4$Clean_Model[10], " | ", tab3_rows4$LL[10], " | ", tab3_rows4$Par[10], " | ", tab3_rows4$AIC_str[10], " | ", tab3_rows4$BIC_str[10], " | ", tab3_rows4$LRT_str[10], " | ", tab3_rows4$p_str[10], " |"),
  "| **Combined Specification** | | | | | | |",
  paste0("| ", tab3_rows4$Clean_Model[11], " | ", tab3_rows4$LL[11], " | ", tab3_rows4$Par[11], " | ", tab3_rows4$AIC_str[11], " | ", tab3_rows4$BIC_str[11], " | ", tab3_rows4$LRT_str[11], " | ", tab3_rows4$p_str[11], " |")
)

writeLines(md3_k4, "cache/table3_bivariate_concomitant_model_comparison.md")

# -------------------------------------------------------------------
# 5. Figures 3-5: Model-Implied Marginal Class Probabilities (4-Faceted)
# -------------------------------------------------------------------
cat("==> [6/6] Generating 4-Faceted Figures (Trust, Extraversion, Race)...\n")

set.seed(2026)
m3_triv4_obj <- flexmix(
  cbind(t1_degree, t2_degree, t3_degree) ~ wave_num + I(wave_num^2) | egoid,
  data = df_triv_comp, k = 4, model = triv_specs,
  concomitant = FLXPmultinom(~ female + race + parents_income_num + mom_college + religion_3cat +
    z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust),
  control = list(iter.max = 300, minprior = 0.02)
)

vc_triv4 <- flexmix:::VarianceCovariance(m3_triv4_obj)
concom_idx_t4 <- grep("^concomitant_", names(vc_triv4$coef))
concom_coef_t4 <- vc_triv4$coef[concom_idx_t4]
concom_vcov_t4 <- vc_triv4$vcov[concom_idx_t4, concom_idx_t4]

form_conc_triv <- ~ female + race + parents_income_num + mom_college + religion_3cat +
  z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust

predict_prob_ci_triv4 <- function(X_mat, beta_draws) {
  n_grid <- nrow(X_mat)
  n_draws <- nrow(beta_draws)
  prob_draws <- array(0, dim = c(n_grid, 4, n_draws))
  
  for (d in 1:n_draws) {
    b_c2_d <- beta_draws[d, 1:16]
    b_c3_d <- beta_draws[d, 17:32]
    b_c4_d <- beta_draws[d, 33:48]
    eta1 <- rep(0, n_grid)
    eta2 <- as.vector(X_mat %*% b_c2_d)
    eta3 <- as.vector(X_mat %*% b_c3_d)
    eta4 <- as.vector(X_mat %*% b_c4_d)
    max_eta <- pmax(eta1, eta2, eta3, eta4)
    exp1 <- exp(eta1 - max_eta)
    exp2 <- exp(eta2 - max_eta)
    exp3 <- exp(eta3 - max_eta)
    exp4 <- exp(eta4 - max_eta)
    sum_exp <- exp1 + exp2 + exp3 + exp4
    prob_draws[, 1, d] <- exp1 / sum_exp # Comp 1: Moderate Winnowers
    prob_draws[, 2, d] <- exp2 / sum_exp # Comp 2: Clique Conservers
    prob_draws[, 3, d] <- exp3 / sum_exp # Comp 3: Extreme Winnowers
    prob_draws[, 4, d] <- exp4 / sum_exp # Comp 4: Expansive Conservers
  }
  
  class_names <- c(
    "Moderate Winnowers / Shell-Oriented",
    "Clique Conservers",
    "Extreme Peripheral Winnowers",
    "Expansive Periphery Conservers"
  )
  
  res <- list()
  for (k in 1:4) {
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
beta_draws_t4 <- MASS::mvrnorm(1000, mu = concom_coef_t4, Sigma = concom_vcov_t4)

# Grid for Generalized Trust (-2.5 to 2.5)
grid_trust_t4 <- tibble(
  z_trust = seq(-2.5, 2.5, length.out = 100),
  female = mean(df_triv_comp$female),
  race = factor("White", levels = levels(factor(df_triv_comp$race))),
  parents_income_num = mean(df_triv_comp$parents_income_num),
  mom_college = mean(df_triv_comp$mom_college),
  religion_3cat = factor("Catholic", levels = c("Catholic", "Other", "None")),
  z_extraversion = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_trust_t4 <- model.matrix(form_conc_triv, data = grid_trust_t4)
ci_trust_t4 <- predict_prob_ci_triv4(X_grid_trust_t4, beta_draws_t4) %>%
  mutate(z_trust = rep(grid_trust_t4$z_trust, 4))

# Grid for Extraversion (-2.5 to 2.5)
grid_ext_t4 <- tibble(
  z_extraversion = seq(-2.5, 2.5, length.out = 100),
  female = mean(df_triv_comp$female),
  race = factor("White", levels = levels(factor(df_triv_comp$race))),
  parents_income_num = mean(df_triv_comp$parents_income_num),
  mom_college = mean(df_triv_comp$mom_college),
  religion_3cat = factor("Catholic", levels = c("Catholic", "Other", "None")),
  z_trust = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_ext_t4 <- model.matrix(form_conc_triv, data = grid_ext_t4)
ci_ext_t4 <- predict_prob_ci_triv4(X_grid_ext_t4, beta_draws_t4) %>%
  mutate(z_extraversion = rep(grid_ext_t4$z_extraversion, 4))

# Grid for Race & Ethnicity
grid_race_t4 <- tibble(
  race = factor(levels(factor(df_triv_comp$race)), levels = levels(factor(df_triv_comp$race))),
  female = mean(df_triv_comp$female),
  parents_income_num = mean(df_triv_comp$parents_income_num),
  mom_college = mean(df_triv_comp$mom_college),
  religion_3cat = factor("Catholic", levels = c("Catholic", "Other", "None")),
  z_trust = 0,
  z_extraversion = 0,
  z_neuroticism = 0,
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0
)
X_grid_race_t4 <- model.matrix(form_conc_triv, data = grid_race_t4)
ci_race_t4 <- predict_prob_ci_triv4(X_grid_race_t4, beta_draws_t4) %>%
  mutate(race = rep(grid_race_t4$race, 4))

# Formatting for 4-Faceted Plots
class_order_wrapped <- c(
  "Expansive Periphery\nConservers",
  "Moderate Winnowers\n(Shell-Oriented)",
  "Extreme Peripheral\nWinnowers",
  "Clique\nConservers"
)

class_mapping_wrap <- c(
  "Expansive Periphery Conservers"       = "Expansive Periphery\nConservers",
  "Moderate Winnowers / Shell-Oriented" = "Moderate Winnowers\n(Shell-Oriented)",
  "Extreme Peripheral Winnowers"        = "Extreme Peripheral\nWinnowers",
  "Clique Conservers"                   = "Clique\nConservers"
)

palette_4_wrap <- c(
  "Expansive Periphery\nConservers"       = "#9467bd",
  "Moderate Winnowers\n(Shell-Oriented)" = "#ff7f0e",
  "Extreme Peripheral\nWinnowers"        = "#d62728",
  "Clique\nConservers"                   = "#2ca02c"
)

ci_trust_t4_w <- ci_trust_t4 %>%
  mutate(Class = factor(class_mapping_wrap[as.character(Class)], levels = class_order_wrapped))

ci_ext_t4_w <- ci_ext_t4 %>%
  mutate(Class = factor(class_mapping_wrap[as.character(Class)], levels = class_order_wrapped))

race_clean_names <- c(
  "White" = "White",
  "Asian" = "Asian",
  "Black" = "Black",
  "Hispanic/Latino" = "Hispanic",
  "Other/International" = "Other/Intl"
)
ci_race_plot_t4_w <- ci_race_t4 %>%
  mutate(
    clean_race = factor(race_clean_names[as.character(race)], 
                        levels = c("White", "Asian", "Black", "Hispanic", "Other/Intl")),
    Class = factor(class_mapping_wrap[as.character(Class)], levels = class_order_wrapped)
  )

theme_facet_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5, margin = margin(b = 6)),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30", margin = margin(b = 8)),
      strip.text = element_text(face = "bold", size = 9.5, lineheight = 1.1),
      strip.background = element_rect(fill = "grey95", color = NA),
      axis.title.x = element_text(size = 10.5, margin = margin(t = 6)),
      axis.title.y = element_text(size = 10.5, margin = margin(r = 6)),
      axis.text = element_text(size = 9),
      legend.position = "none",
      panel.grid.minor = element_blank(),
      panel.spacing = unit(1, "lines"),
      plot.margin = margin(t = 8, r = 12, b = 8, l = 10)
    )
}

# 1. Trust 4-Faceted Plot
p_trust_clean <- ggplot(ci_trust_t4_w, aes(x = z_trust, y = Mean, color = Class, fill = Class)) +
  geom_ribbon(aes(ymin = pmax(0, Low), ymax = pmin(1, High)), alpha = 0.22, color = NA) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ Class, ncol = 4) +
  scale_color_manual(values = palette_4_wrap) +
  scale_fill_manual(values = palette_4_wrap) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.70), breaks = seq(0, 0.6, 0.2)) +
  scale_x_continuous(breaks = seq(-2, 2, 1)) +
  labs(
    title = "Model-Implied Trajectory Class Probabilities across Generalized Trust",
    subtitle = "Standardized Generalized Trust score (holding all other covariates at reference levels and sample means)",
    x = "Standardized Generalized Trust (z-score)",
    y = "Predicted Class Probability"
  ) +
  theme_facet_pub()

# 2. Extraversion 4-Faceted Plot
p_ext_clean <- ggplot(ci_ext_t4_w, aes(x = z_extraversion, y = Mean, color = Class, fill = Class)) +
  geom_ribbon(aes(ymin = pmax(0, Low), ymax = pmin(1, High)), alpha = 0.22, color = NA) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ Class, ncol = 4) +
  scale_color_manual(values = palette_4_wrap) +
  scale_fill_manual(values = palette_4_wrap) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.70), breaks = seq(0, 0.6, 0.2)) +
  scale_x_continuous(breaks = seq(-2, 2, 1)) +
  labs(
    title = "Model-Implied Trajectory Class Probabilities across Extraversion",
    subtitle = "Standardized Extraversion score (holding all other covariates at reference levels and sample means)",
    x = "Standardized Extraversion (z-score)",
    y = "Predicted Class Probability"
  ) +
  theme_facet_pub()

# 3. Race & Ethnicity 4-Faceted Plot
p_race_clean <- ggplot(ci_race_plot_t4_w, aes(x = clean_race, y = Mean, color = Class)) +
  geom_pointrange(aes(ymin = pmax(0, Low), ymax = pmin(1, High)), size = 0.6, linewidth = 0.9) +
  facet_wrap(~ Class, ncol = 4) +
  scale_color_manual(values = palette_4_wrap) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.75), breaks = seq(0, 0.6, 0.2)) +
  labs(
    title = "Model-Implied Trajectory Class Probabilities across Race and Ethnicity",
    subtitle = "Adjusted predicted probabilities holding all other covariates at reference levels and sample means",
    x = "Racial/Ethnic Category",
    y = "Predicted Class Probability"
  ) +
  theme_facet_pub() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1, size = 8.5))

# Save standalone publication plots
ggsave("Plots/fig3_marginal_trust.png", p_trust_clean, width = 10, height = 3.6, dpi = 300)
ggsave("Plots/fig4_marginal_extraversion.png", p_ext_clean, width = 10, height = 3.6, dpi = 300)
ggsave("Plots/fig5_marginal_race.png", p_race_clean, width = 10, height = 4.0, dpi = 300)

ggsave("output/figures/fig3_marginal_trust.png", p_trust_clean, width = 10, height = 3.6, dpi = 300)
ggsave("output/figures/fig4_marginal_extraversion.png", p_ext_clean, width = 10, height = 3.6, dpi = 300)
ggsave("output/figures/fig5_marginal_race.png", p_race_clean, width = 10, height = 4.0, dpi = 300)

# Save compound 2-tier disposition plot for Figure 3
png("Plots/fig3_bivariate_marginal_effects.png", width = 10, height = 7.2, units = "in", res = 300)
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 1, heights = grid::unit(c(1, 1), "null"))))
print(p_trust_clean, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
print(p_ext_clean, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
dev.off()
file.copy("Plots/fig3_bivariate_marginal_effects.png", "output/figures/fig3_bivariate_marginal_effects.png", overwrite = TRUE)

cat("\n==> All 4-class Dunbar LCGA models, tables, and figures generated successfully!\n")

