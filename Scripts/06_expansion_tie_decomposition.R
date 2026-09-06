#' ---
#' title: "06_expansion_tie_decomposition.R"
#' description: "Expansion 3: Decomposing Longitudinal Trajectories by Tie Closeness, Contact Frequency, and Social Support"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
})

cat("==> Loading raw network ties and analytical egos...\n")
raw_dir <- if (dir.exists("data/raw") && file.exists("data/raw/network_survey.csv")) {
  "data/raw"
} else {
  "../identifying-personal-network-types/raw_dat"
}

net_raw <- read_csv(file.path(raw_dir, "network_survey.csv"), show_col_types = FALSE)

# Compute decomposed degree counts per ego per wave across all 8 waves
decomp_long <- net_raw %>%
  filter(!is.na(egoid), !is.na(wave)) %>%
  mutate(
    wave_num = as.integer(gsub("\\D", "", wave))
  ) %>%
  filter(wave_num <= 8) %>%
  group_by(egoid, wave, wave_num) %>%
  summarize(
    total_degree    = n(),
    close_degree    = sum(close %in% c("EspeciallyClose", "MerelyClose"), na.rm = TRUE),
    casual_degree   = sum(close %in% c("LessThanClose", "Distant"), na.rm = TRUE),
    daily_degree    = sum(freq == "Daily", na.rm = TRUE),
    support_degree  = sum(supphang == TRUE | suppadv == TRUE | suppcomf == TRUE | suppfin == TRUE, na.rm = TRUE),
    express_degree  = sum(suppadv == TRUE | suppcomf == TRUE, na.rm = TRUE),
    .groups = "drop"
  )

# Keep egos who participated in >= 3 waves across college
college_egos <- decomp_long %>%
  group_by(egoid) %>%
  filter(n() >= 3) %>%
  pull(egoid) %>%
  unique()

decomp_sample <- decomp_long %>%
  filter(egoid %in% college_egos)

cat("Analytical longitudinal sample:", n_distinct(decomp_sample$egoid), "egos across Waves 1–8\n")

# Calculate mean and standard errors across waves
decomp_summary <- decomp_sample %>%
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

write_csv(decomp_summary, "output/tables/table6_decomposed_trajectory_means.csv")
cat("\nDecomposed Degree Trajectory Means Across College (Waves 1 to 8):\n")
print(as.data.frame(decomp_summary))

# Reshape for multi-line plotting
plot_decomp <- bind_rows(
  decomp_summary %>% select(wave_num, Mean = Total_Mean, SE = Total_SE) %>% mutate(Metric = "Total Ego Network Size"),
  decomp_summary %>% select(wave_num, Mean = Close_Mean, SE = Close_SE) %>% mutate(Metric = "Close / Strong Ties"),
  decomp_summary %>% select(wave_num, Mean = Daily_Mean, SE = Daily_SE) %>% mutate(Metric = "Daily Activated Ties"),
  decomp_summary %>% filter(!is.na(Support_Mean)) %>% select(wave_num, Mean = Support_Mean, SE = Support_SE) %>% mutate(Metric = "Support-Providing Ties")
) %>%
  mutate(
    Metric = factor(Metric, levels = c("Total Ego Network Size", "Close / Strong Ties", "Support-Providing Ties", "Daily Activated Ties")),
    semester = factor(
      wave_num,
      levels = 1:8,
      labels = c("W1 (Frosh Fall)", "W2 (Frosh Spr)", "W3 (Soph Fall)", "W4 (Soph Spr)",
                 "W5 (Jun Fall)", "W6 (Jun Spr)", "W7 (Sen Fall)", "W8 (Sen Spr)")
    )
  )

p_decomp <- ggplot(plot_decomp, aes(x = wave_num, y = Mean, color = Metric, shape = Metric, fill = Metric)) +
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
    "Total Ego Network Size" = "#1f77b4",
    "Close / Strong Ties"    = "#2ca02c",
    "Support-Providing Ties" = "#ff7f0e",
    "Daily Activated Ties"   = "#d62728"
  )) +
  scale_fill_manual(values = c(
    "Total Ego Network Size" = "#1f77b4",
    "Close / Strong Ties"    = "#2ca02c",
    "Support-Providing Ties" = "#ff7f0e",
    "Daily Activated Ties"   = "#d62728"
  )) +
  labs(
    title = "Collegiate Ego Network Evolution: Decomposing Degree Trajectories Across 8 Waves",
    subtitle = "Comparing Total Network Size against Affective Closeness, Contact Frequency, and Support Ties (N = 450+ Egos)",
    x = "College Academic Wave",
    y = "Average Degree (Alters Nominated)",
    color = "Relational Dimension",
    shape = "Relational Dimension",
    fill = "Relational Dimension"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA)
  )

ggsave("output/figures/fig7_decomposed_degree_trajectories.png", p_decomp, width = 10, height = 6, dpi = 300)

cat("\n==> Script 06 (Expansion: Tie Decomposition) completed successfully!\n")
