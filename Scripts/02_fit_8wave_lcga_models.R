#' ---
#' title: "02_fit_8wave_lcga_models.R"
#' description: "Fit 8-Wave Poisson LCGA models, decompose functional layers, and generate Figures 1-3 and Tables 1-2"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(flexmix)
})

cat("==> [1/5] Loading 8-wave analytical data...\n")
deg_long_raw <- readRDS("data/processed/degree_trajectories_long.rds")
analytical_w18 <- readRDS("data/processed/degree_analytical_w18.rds")

deg8_long <- deg_long_raw %>%
  filter(wave_num <= 8, egoid %in% analytical_w18$egoid) %>%
  arrange(egoid, wave_num) %>%
  group_by(egoid) %>%
  mutate(seq_idx = row_number()) %>%
  ungroup()

# -------------------------------------------------------------------
# 1. Overall 8-Wave Functional Tie Decomposition (Table 1 & Figure 1)
# -------------------------------------------------------------------
cat("==> [2/5] Computing overall 8-wave functional tie decomposition...\n")
net_raw <- read_csv("data/raw/network_survey.csv", show_col_types = FALSE)

decomp_long <- net_raw %>%
  filter(!is.na(egoid), !is.na(wave)) %>%
  mutate(wave_num = as.integer(gsub("\\D", "", wave))) %>%
  filter(wave_num <= 8, egoid %in% analytical_w18$egoid) %>%
  group_by(egoid, wave_num) %>%
  summarize(
    total_degree   = n(),
    close_degree   = sum(close %in% c("EspeciallyClose", "MerelyClose"), na.rm = TRUE),
    daily_degree   = sum(freq == "Daily", na.rm = TRUE),
    support_degree = sum(supphang == TRUE | suppadv == TRUE | suppcomf == TRUE | suppfin == TRUE, na.rm = TRUE),
    .groups = "drop"
  )

decomp_summary <- decomp_long %>%
  group_by(wave_num) %>%
  summarize(
    n_egos = n(),
    Total_Mean = mean(total_degree),
    Total_SE   = sd(total_degree) / sqrt(n()),
    Close_Mean = mean(close_degree),
    Close_SE   = sd(close_degree) / sqrt(n()),
    Daily_Mean = mean(daily_degree),
    Daily_SE   = sd(daily_degree) / sqrt(n()),
    Support_Mean = mean(support_degree[support_degree > 0], na.rm = TRUE),
    Support_SE   = sd(support_degree[support_degree > 0], na.rm = TRUE) / sqrt(sum(support_degree > 0, na.rm = TRUE)),
    .groups = "drop"
  )

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("Plots", showWarnings = FALSE, recursive = TRUE)
dir.create("cache", showWarnings = FALSE, recursive = TRUE)

write.csv(decomp_summary, "output/tables/table1_decomposed_trajectory_means.csv", row.names = FALSE)

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

tab1_rows <- decomp_summary %>%
  mutate(
    Semester = wave_labels_full[as.character(wave_num)],
    N = as.character(n_egos),
    Total = paste0(sprintf("%.2f", Total_Mean), " (", sprintf("%.2f", Total_SE), ")"),
    Close = paste0(sprintf("%.2f", Close_Mean), " (", sprintf("%.2f", Close_SE), ")"),
    Daily = paste0(sprintf("%.2f", Daily_Mean), " (", sprintf("%.2f", Daily_SE), ")"),
    Support = ifelse(is.na(Support_Mean), "---", paste0(sprintf("%.2f", Support_Mean), " (", sprintf("%.2f", Support_SE), ")"))
  ) %>%
  select(Semester, N, Total, Close, Daily, Support)

md1 <- c(
  "| Academic Wave | Egos (N) | Total Degree (SE) | Close Ties (SE) | Daily Ties (SE) | Support Ties (SE) |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab1_rows, 1, function(r) {
    paste0("| ", r["Semester"], " | ", r["N"], " | ", r["Total"], " | ", r["Close"], " | ", r["Daily"], " | ", r["Support"], " |")
  })
)
writeLines(md1, "cache/table1_decomposed_trajectory_means.md")

# Plot Figure 1: 8-Wave Decomposed Trajectories
plot_decomp <- bind_rows(
  decomp_summary %>% select(wave_num, Mean = Total_Mean, SE = Total_SE) %>% mutate(Metric = "Total Ego Network Size"),
  decomp_summary %>% select(wave_num, Mean = Close_Mean, SE = Close_SE) %>% mutate(Metric = "Close / Strong Ties"),
  decomp_summary %>% select(wave_num, Mean = Daily_Mean, SE = Daily_SE) %>% mutate(Metric = "Daily Activated Ties"),
  decomp_summary %>% filter(!is.na(Support_Mean)) %>% select(wave_num, Mean = Support_Mean, SE = Support_SE) %>% mutate(Metric = "Support-Providing Ties")
) %>%
  mutate(
    Metric = factor(Metric, levels = c("Total Ego Network Size", "Close / Strong Ties", "Support-Providing Ties", "Daily Activated Ties"))
  )

p_fig1 <- ggplot(plot_decomp, aes(x = wave_num, y = Mean, color = Metric, shape = Metric, fill = Metric)) +
  geom_ribbon(aes(ymin = Mean - 1.96 * SE, ymax = Mean + 1.96 * SE), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh Fall", "W2\nFrosh Spr", "W3\nSoph Fall", "W4\nSoph Spr",
               "W5\nJun Fall", "W6\nJun Spr", "W7\nSen Fall", "W8\nSen Spr")
  ) +
  scale_y_continuous(breaks = seq(0, 16, 2), limits = c(0, 16.5)) +
  scale_color_manual(values = c(
    "Total Ego Network Size"   = "#1f77b4",
    "Close / Strong Ties"      = "#2ca02c",
    "Support-Providing Ties"   = "#ff7f0e",
    "Daily Activated Ties"     = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Total Ego Network Size"   = "#1f77b4",
    "Close / Strong Ties"      = "#2ca02c",
    "Support-Providing Ties"   = "#ff7f0e",
    "Daily Activated Ties"     = "#d62728"
  )) +
  scale_shape_manual(values = c(16, 17, 15, 3)) +
  labs(
    title = "Collegiate Ego Network Evolution: Decomposing Degree Trajectories Across 8 Waves",
    subtitle = "Comparing Total Network Size against Affective Closeness, Contact Frequency, and Support Ties (N = 457 Egos)",
    x = "College Academic Wave",
    y = "Average Degree (Alters Nominated)",
    color = "Relational Dimension",
    shape = "Relational Dimension",
    fill  = "Relational Dimension"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig1_decomposed_degree_trajectories.png", p_fig1, width = 10, height = 6, dpi = 300)
ggsave("output/figures/fig1_decomposed_degree_trajectories.png", p_fig1, width = 10, height = 6, dpi = 300)

# -------------------------------------------------------------------
# 2. Fit 8-Wave Poisson LCGA Models (K = 1..5) (Table 2)
# -------------------------------------------------------------------
cat("==> [3/5] Estimating repeated-measures Poisson mixture models for K = 1..5 across 8 waves...\n")

fit_lcga <- function(k) {
  set.seed(2026 + k)
  if (k == 1) {
    mod <- glm(degree ~ wave_num + I(wave_num^2), data = deg8_long, family = poisson)
    ll <- logLik(mod)[1]
    n_params <- length(coef(mod))
    aic <- AIC(mod)
    bic <- BIC(mod)
    post_df <- tibble(egoid = unique(deg8_long$egoid), class = factor(1))
  } else {
    mod <- flexmix(
      degree ~ wave_num + I(wave_num^2) | egoid,
      data = deg8_long,
      k = k,
      model = FLXMRglm(family = "poisson"),
      control = list(iter.max = 200, minprior = 0.05)
    )
    ll <- logLik(mod)[1]
    aic <- AIC(mod)
    bic <- BIC(mod)
    n_params <- mod@df
    ego_clusts <- clusters(mod)
    ego_post_df <- tibble(
      egoid = deg8_long$egoid,
      clust = ego_clusts
    ) %>%
      group_by(egoid) %>%
      summarize(class = factor(names(which.max(table(clust)))), .groups = "drop")
    post_df <- ego_post_df
  }
  list(k = k, model = mod, ll = ll, aic = aic, bic = bic, n_params = n_params, assignments = post_df)
}

lcga_results <- list()
fit_stats <- list()

for (k in 1:5) {
  cat("   Fitting K =", k, "...\n")
  res <- fit_lcga(k)
  lcga_results[[k]] <- res
  fit_stats[[k]] <- tibble(
    K = k,
    LogLik = res$ll,
    n_params = res$n_params,
    AIC = res$aic,
    BIC = res$bic
  )
}

fit_table <- bind_rows(fit_stats) %>%
  mutate(delta_BIC = BIC - min(BIC))

write.csv(fit_table, "output/tables/table2_lcga_model_selection.csv", row.names = FALSE)

tab2_rows <- fit_table %>%
  mutate(
    Classes = paste0("K = ", K),
    LogLik = sprintf("%.1f", LogLik),
    Par = as.character(n_params),
    AIC = sprintf("%.1f", AIC),
    BIC = sprintf("%.1f", BIC),
    delta_BIC = sprintf("%.1f", delta_BIC)
  ) %>%
  select(Classes, LogLik, Par, AIC, BIC, delta_BIC)

md2 <- c(
  "| Latent Classes | Log-Likelihood | Par | AIC | BIC | ΔBIC |",
  "|:---|:---:|:---:|:---:|:---:|:---:|",
  apply(tab2_rows, 1, function(r) {
    paste0("| ", r["Classes"], " | ", r["LogLik"], " | ", r["Par"], " | ", r["AIC"], " | ", r["BIC"], " | ", r["delta_BIC"], " |")
  })
)
writeLines(md2, "cache/table2_lcga_model_selection.md")

# -------------------------------------------------------------------
# 3. 8-Wave Optimal 3-Class Trajectory Profiles (Figure 2)
# -------------------------------------------------------------------
cat("==> [4/5] Generating 8-wave LCGA trajectory profile plot (Figure 2)...\n")
res3 <- lcga_results[[3]]
ego_assignments_3 <- res3$assignments

# Class 1 = Conservers, Class 3 = Moderate Winnowers, Class 2 = Accelerated Winnowers
class_labels_3 <- c(
  "1" = "Network Conservers (n = 131; 28.7%)",
  "3" = "Moderate Winnowers (n = 182; 39.8%)",
  "2" = "Accelerated Winnowers (n = 144; 31.5%)"
)

analytical_w18_classified <- analytical_w18 %>%
  inner_join(ego_assignments_3, by = "egoid") %>%
  mutate(
    trajectory_class = factor(
      class_labels_3[as.character(class)],
      levels = c(
        "Network Conservers (n = 131; 28.7%)",
        "Moderate Winnowers (n = 182; 39.8%)",
        "Accelerated Winnowers (n = 144; 31.5%)"
      )
    ),
    trajectory_name = factor(
      case_when(
        class == "1" ~ "Network Conservers",
        class == "3" ~ "Moderate Winnowers",
        class == "2" ~ "Accelerated Winnowers"
      ),
      levels = c("Moderate Winnowers", "Network Conservers", "Accelerated Winnowers") # Moderate Winnowers is ref
    )
  )

saveRDS(analytical_w18_classified, "data/processed/degree_analytical_w18_classified.rds")
write.csv(analytical_w18_classified, "data/processed/degree_analytical_w18_classified.csv", row.names = FALSE)

plot_lcga_3 <- deg8_long %>%
  inner_join(analytical_w18_classified %>% select(egoid, trajectory_class), by = "egoid")

class_means_3 <- plot_lcga_3 %>%
  group_by(trajectory_class, wave_num) %>%
  summarize(
    mean_degree = mean(degree),
    se_degree = sd(degree) / sqrt(n()),
    .groups = "drop"
  )

p_fig2 <- ggplot() +
  geom_line(data = plot_lcga_3, aes(x = wave_num, y = degree, group = egoid), 
            alpha = 0.15, color = "grey40", linewidth = 0.4) +
  geom_ribbon(data = class_means_3, aes(x = wave_num, ymin = mean_degree - 1.96 * se_degree, 
                                      ymax = mean_degree + 1.96 * se_degree),
              fill = "#e05638", alpha = 0.25) +
  geom_line(data = class_means_3, aes(x = wave_num, y = mean_degree), 
            color = "#c02812", linewidth = 1.3) +
  geom_point(data = class_means_3, aes(x = wave_num, y = mean_degree), 
             color = "#c02812", size = 2.5) +
  facet_wrap(~ trajectory_class, ncol = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh", "W2\nFrosh", "W3\nSoph", "W4\nSoph",
               "W5\nJun", "W6\nJun", "W7\nSen", "W8\nSen")
  ) +
  scale_y_continuous(breaks = seq(0, 25, 5), limits = c(0, 26)) +
  labs(
    title = "Latent Class Growth Analysis (LCGA) of Collegiate Degree Trajectories Across 8 Waves (K = 3)",
    subtitle = "Repeated-measure Poisson finite mixture model tracking students from matriculation to graduation (N = 457)",
    x = "College Academic Wave (Fall 2015 to Spring 2019)",
    y = "Ego Degree (Count of Nominated Alters)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 10),
    panel.border = element_rect(color = "grey80", fill = NA)
  )

ggsave("Plots/fig2_lcga_8wave_trajectories.png", p_fig2, width = 11, height = 5, dpi = 300)
ggsave("output/figures/fig2_lcga_8wave_trajectories.png", p_fig2, width = 11, height = 5, dpi = 300)

# -------------------------------------------------------------------
# 4. Functional Tie Decomposition Stratified by LCGA Class (Figure 3)
# -------------------------------------------------------------------
cat("==> [5/5] Generating functional tie profiles stratified by LCGA class (Figure 3)...\n")

decomp_by_class <- decomp_long %>%
  inner_join(analytical_w18_classified %>% select(egoid, trajectory_class), by = "egoid") %>%
  group_by(trajectory_class, wave_num) %>%
  summarize(
    n = n(),
    Total_Mean = mean(total_degree),
    Total_SE   = sd(total_degree) / sqrt(n()),
    Close_Mean = mean(close_degree),
    Close_SE   = sd(close_degree) / sqrt(n()),
    Daily_Mean = mean(daily_degree),
    Daily_SE   = sd(daily_degree) / sqrt(n()),
    Support_Mean = mean(support_degree[support_degree > 0], na.rm = TRUE),
    Support_SE   = sd(support_degree[support_degree > 0], na.rm = TRUE) / sqrt(sum(support_degree > 0, na.rm = TRUE)),
    .groups = "drop"
  )

plot_decomp_by_class <- bind_rows(
  decomp_by_class %>% select(trajectory_class, wave_num, Mean = Total_Mean, SE = Total_SE) %>% mutate(Metric = "Total Degree"),
  decomp_by_class %>% select(trajectory_class, wave_num, Mean = Close_Mean, SE = Close_SE) %>% mutate(Metric = "Close Ties"),
  decomp_by_class %>% select(trajectory_class, wave_num, Mean = Daily_Mean, SE = Daily_SE) %>% mutate(Metric = "Daily Activated Ties"),
  decomp_by_class %>% filter(!is.na(Support_Mean)) %>% select(trajectory_class, wave_num, Mean = Support_Mean, SE = Support_SE) %>% mutate(Metric = "Support-Providing Ties")
) %>%
  mutate(
    Metric = factor(Metric, levels = c("Total Degree", "Close Ties", "Support-Providing Ties", "Daily Activated Ties"))
  )

p_fig3 <- ggplot(plot_decomp_by_class, aes(x = wave_num, y = Mean, color = Metric, shape = Metric, fill = Metric)) +
  geom_ribbon(aes(ymin = Mean - 1.96 * SE, ymax = Mean + 1.96 * SE), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  facet_wrap(~ trajectory_class, ncol = 3) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8")
  ) +
  scale_y_continuous(breaks = seq(0, 20, 4), limits = c(0, 21)) +
  scale_color_manual(values = c(
    "Total Degree"             = "#1f77b4",
    "Close Ties"               = "#2ca02c",
    "Support-Providing Ties"   = "#ff7f0e",
    "Daily Activated Ties"     = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Total Degree"             = "#1f77b4",
    "Close Ties"               = "#2ca02c",
    "Support-Providing Ties"   = "#ff7f0e",
    "Daily Activated Ties"     = "#d62728"
  )) +
  scale_shape_manual(values = c(16, 17, 15, 3)) +
  labs(
    title = "Functional Tie Decomposition Stratified by Latent Trajectory Class Across 8 Waves",
    subtitle = "Comparing Evolution of Total Degree, Strong Ties, Daily Ties, and Support Ties within Each Trajectory Type",
    x = "College Academic Wave",
    y = "Average Ties Nominated",
    color = "Relational Layer",
    shape = "Relational Layer",
    fill  = "Relational Layer"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 10),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    panel.border = element_rect(color = "grey80", fill = NA),
    panel.grid.minor = element_blank()
  )

ggsave("Plots/fig3_lcga_functional_profiles.png", p_fig3, width = 11, height = 5.5, dpi = 300)
ggsave("output/figures/fig3_lcga_functional_profiles.png", p_fig3, width = 11, height = 5.5, dpi = 300)

cat("\n==> Script 02 completed successfully! Generated Figures 1, 2, 3 and Tables 1, 2.\n")
