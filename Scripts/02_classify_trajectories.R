#' ---
#' title: "02_classify_trajectories.R"
#' description: "Classify longitudinal degree trajectories via deductive logic and k-means clustering"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
})

cat("==> Loading prepared analytical dataset...\n")
analytical <- readRDS("data/processed/degree_analytical_w16.rds")
degree_long <- readRDS("data/processed/degree_trajectories_long.rds") %>%
  filter(wave_num <= 6, egoid %in% analytical$egoid) %>%
  arrange(egoid, wave_num) %>%
  group_by(egoid) %>%
  mutate(
    seq_idx = row_number(),
    deg_demeaned = degree - mean(degree)
  ) %>%
  ungroup()

# -------------------------------------------------------------------
# 1. Deductive Classification Scheme (8-Category & 4-Category)
# -------------------------------------------------------------------
cat("\n==> Implementing deductive classification decision tree...\n")

classify_ego_deductive <- function(y) {
  len <- length(y)
  diffs <- diff(y)
  range_y <- max(y) - min(y)
  sd_y <- sd(y)
  fit <- lm(y ~ seq_along(y))
  slope <- unname(coef(fit)[2])
  
  # Step 1: Flat (minimal variation or near-zero slope across all waves)
  if (range_y <= 2 || (range_y <= 3 && sd_y <= 1.2)) {
    return(list(cat8 = "Flat", cat4 = "Flat"))
  }
  
  # Step 2: Monotonic Increase (strictly non-decreasing, at least one increase)
  if (all(diffs >= 0) && any(diffs > 0)) {
    return(list(cat8 = "Monotonic Increase", cat4 = "Up"))
  }
  
  # Step 3: Monotonic Decrease (strictly non-increasing, at least one decrease)
  if (all(diffs <= 0) && any(diffs < 0)) {
    return(list(cat8 = "Monotonic Decrease", cat4 = "Down"))
  }
  
  # Step 4: Inverted U-Shape (rises to a single internal peak, then falls)
  peak <- which.max(y)
  if (peak > 1 && peak < len && all(diff(y[1:peak]) >= 0) && all(diff(y[peak:len]) <= 0)) {
    return(list(cat8 = "Inverted U-Shape", cat4 = "Mixed"))
  }
  
  # Step 5: U-Shape (falls to a single internal trough, then rises)
  trough <- which.min(y)
  if (trough > 1 && trough < len && all(diff(y[1:trough]) <= 0) && all(diff(y[trough:len]) >= 0)) {
    return(list(cat8 = "U-Shape", cat4 = "Mixed"))
  }
  
  # Step 6: Zig-Zag (alternating signs of changes)
  nz_diffs <- diffs[diffs != 0]
  if (length(nz_diffs) >= 3 && all(nz_diffs[-1] * nz_diffs[-length(nz_diffs)] < 0)) {
    return(list(cat8 = "Zig-Zag", cat4 = "Mixed"))
  }
  
  # Step 7 & 8: Trends based on overall linear progression
  if (slope > 0) {
    return(list(cat8 = "Upward Trend", cat4 = "Up"))
  } else if (slope < 0) {
    return(list(cat8 = "Downward Trend", cat4 = "Down"))
  } else {
    return(list(cat8 = "Flat", cat4 = "Flat"))
  }
}

ego_seqs <- degree_long %>%
  group_by(egoid) %>%
  summarize(
    y = list(degree),
    .groups = "drop"
  )

deductive_results <- lapply(ego_seqs$y, classify_ego_deductive)
ego_seqs$cat8 <- sapply(deductive_results, `[[`, "cat8")
ego_seqs$cat4 <- sapply(deductive_results, `[[`, "cat4")

cat("\nDeductive 8-Category Distribution (N = ", nrow(ego_seqs), "):\n", sep = "")
print(table(ego_seqs$cat8))

cat("\nDeductive 4-Category Distribution:\n")
print(table(ego_seqs$cat4))

# Set largest category as reference level (as in Slide 18)
cat8_levels <- c("Downward Trend", "Monotonic Decrease", "Zig-Zag", "Flat", "U-Shape", "Inverted U-Shape", "Upward Trend", "Monotonic Increase")
cat4_levels <- c("Down", "Mixed", "Up", "Flat")

ego_seqs$cat8 <- factor(ego_seqs$cat8, levels = cat8_levels)
ego_seqs$cat4 <- factor(ego_seqs$cat4, levels = cat4_levels)

# -------------------------------------------------------------------
# 2. Inductive k-Means Clustering Schemes
# -------------------------------------------------------------------
cat("\n==> Running k-means clustering across raw and demeaned sequences...\n")

# Prepare raw matrix with LOCF for clustering
wide_raw <- degree_long %>%
  select(egoid, seq_idx, degree) %>%
  pivot_wider(names_from = seq_idx, values_from = degree, names_prefix = "s")

# LOCF imputation for clustering matrix
raw_mat <- as.matrix(wide_raw[, -1])
for (i in 1:nrow(raw_mat)) {
  vals <- raw_mat[i, ]
  for (j in 2:length(vals)) {
    if (is.na(vals[j])) vals[j] <- vals[j - 1]
  }
  raw_mat[i, ] <- vals
}

# Prepare demeaned matrix (centered on ego mean, missing padded with 0)
wide_dem <- degree_long %>%
  select(egoid, seq_idx, deg_demeaned) %>%
  pivot_wider(names_from = seq_idx, values_from = deg_demeaned, names_prefix = "s", values_fill = 0)
dem_mat <- as.matrix(wide_dem[, -1])

# Elbow search across k = 1..10 (Slide 9: iterate to evaluate mean distance)
cat("Computing within-cluster sum of squares across k = 1..10...\n")
set.seed(20180628)
wss_raw <- numeric(10)
wss_dem <- numeric(10)
for (k in 1:10) {
  km_r <- kmeans(raw_mat, centers = k, nstart = 50, iter.max = 100)
  km_d <- kmeans(dem_mat, centers = k, nstart = 50, iter.max = 100)
  wss_raw[k] <- km_r$tot.withinss / nrow(raw_mat)
  wss_dem[k] <- km_d$tot.withinss / nrow(dem_mat)
}

elbow_df <- tibble(
  k = 1:10,
  raw_mean_dist = sqrt(wss_raw),
  dem_mean_dist = sqrt(wss_dem)
)

# Run specific target k-means models (Raw: k=7, k=9; Demeaned: k=4, k=8)
set.seed(2018)
km_raw7 <- kmeans(raw_mat, centers = 7, nstart = 100, iter.max = 100)
km_raw9 <- kmeans(raw_mat, centers = 9, nstart = 100, iter.max = 100)
km_dem4 <- kmeans(dem_mat, centers = 4, nstart = 100, iter.max = 100)
km_dem8 <- kmeans(dem_mat, centers = 8, nstart = 100, iter.max = 100)

# Helper function to order clusters by size descending (modal cluster is ref)
reorder_clusters <- function(cl) {
  tab <- sort(table(cl), decreasing = TRUE)
  new_levels <- names(tab)
  factor(cl, levels = new_levels, labels = paste0("Cluster ", seq_along(new_levels)))
}

kmeans_df <- tibble(
  egoid = wide_raw$egoid,
  kmeans_raw7 = reorder_clusters(km_raw7$cluster),
  kmeans_raw9 = reorder_clusters(km_raw9$cluster),
  kmeans_dem4 = reorder_clusters(km_dem4$cluster),
  kmeans_dem8 = reorder_clusters(km_dem8$cluster)
)

# -------------------------------------------------------------------
# 3. Merge All Classification Schemes with Analytical Dataset
# -------------------------------------------------------------------
analytical_classified <- analytical %>%
  inner_join(ego_seqs %>% select(egoid, cat8, cat4), by = "egoid") %>%
  inner_join(kmeans_df, by = "egoid")

saveRDS(analytical_classified, "data/processed/degree_analytical_classified.rds")
write_csv(analytical_classified, "data/processed/degree_analytical_classified.csv")
cat("\n==> Saved fully classified dataset to data/processed/degree_analytical_classified.rds\n")

# -------------------------------------------------------------------
# 4. Generate Reproduction Figures (Slides 9-15)
# -------------------------------------------------------------------
cat("\n==> Generating publication-grade reproduction plots...\n")

plot_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA),
    legend.position = "none"
  )

# Long plotting dataframe
plot_long <- degree_long %>%
  inner_join(analytical_classified %>% select(egoid, cat8, cat4, kmeans_raw7, kmeans_raw9, kmeans_dem4, kmeans_dem8), by = "egoid")

# Fig 1: Deductive 8-Category Scheme (Slide 10)
cat8_counts <- plot_long %>%
  group_by(cat8) %>%
  summarize(n_egos = n_distinct(egoid), .groups = "drop") %>%
  mutate(facet_label = paste0(cat8, " (n = ", n_egos, ")"))

plot_long_cat8 <- plot_long %>%
  left_join(cat8_counts, by = "cat8")

p_cat8 <- ggplot(plot_long_cat8, aes(x = seq_idx, y = degree, group = egoid, color = factor(egoid %% 8))) +
  geom_line(alpha = 0.45, linewidth = 0.6) +
  facet_wrap(~ facet_label, ncol = 4) +
  scale_x_continuous(breaks = 1:6, limits = c(1, 6)) +
  scale_y_continuous(limits = c(0, 26), breaks = seq(0, 25, 5)) +
  labs(
    title = "Degree Trajectories Classified by A Priori Logic",
    subtitle = "(n = 450)",
    x = "Degree Sequence",
    y = "Degree"
  ) +
  plot_theme

ggsave("output/figures/fig1_8cat_logical_trajectories.png", p_cat8, width = 12, height = 7, dpi = 300)

# Fig 2: Deductive 4-Category Simplified Scheme (Slide 11)
cat4_counts <- plot_long %>%
  group_by(cat4) %>%
  summarize(n_egos = n_distinct(egoid), .groups = "drop") %>%
  mutate(facet_label = paste0(cat4, " (n = ", n_egos, ")"))

plot_long_cat4 <- plot_long %>%
  left_join(cat4_counts, by = "cat4")

p_cat4 <- ggplot(plot_long_cat4, aes(x = seq_idx, y = degree, group = egoid, color = factor(egoid %% 8))) +
  geom_line(alpha = 0.45, linewidth = 0.6) +
  facet_wrap(~ facet_label, ncol = 2) +
  scale_x_continuous(breaks = 1:6, limits = c(1, 6)) +
  scale_y_continuous(limits = c(0, 26), breaks = seq(0, 25, 5)) +
  labs(
    title = "Degree Trajectories Classified by Simplified A Priori Logic",
    subtitle = "(n = 450)",
    x = "Degree Sequence",
    y = "Degree"
  ) +
  plot_theme

ggsave("output/figures/fig2_4cat_simplified_trajectories.png", p_cat4, width = 9, height = 7, dpi = 300)

# Fig 3: k-Means Demeaned k=4 (Slide 14)
dem4_counts <- plot_long %>%
  group_by(kmeans_dem4) %>%
  summarize(
    n_egos = n_distinct(egoid),
    mean_deg = mean(degree),
    .groups = "drop"
  ) %>%
  mutate(facet_label = paste0(kmeans_dem4, " (n = ", n_egos, "; d_mean = ", round(mean_deg, 1), ")"))

plot_long_dem4 <- plot_long %>%
  left_join(dem4_counts, by = "kmeans_dem4")

p_dem4 <- ggplot(plot_long_dem4, aes(x = seq_idx, y = deg_demeaned, group = egoid, color = factor(egoid %% 8))) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_line(alpha = 0.45, linewidth = 0.6) +
  facet_wrap(~ facet_label, ncol = 2) +
  scale_x_continuous(breaks = 1:6, limits = c(1, 6)) +
  scale_y_continuous(limits = c(-16, 16), breaks = seq(-15, 15, 5)) +
  labs(
    title = "Degree Trajectories Classified by k-Means Clustering",
    subtitle = "Zeroed on Ego's Mean Degree (n = 450 ; k = 4)",
    x = "Degree Sequence",
    y = "Degree (Centered on Ego Mean)"
  ) +
  plot_theme

ggsave("output/figures/fig3_kmeans_demeaned_k4.png", p_dem4, width = 9, height = 7, dpi = 300)

# Fig 4: k-Means Elbow Evaluation (Slide 9)
p_elbow <- ggplot(elbow_df, aes(x = k)) +
  geom_line(aes(y = raw_mean_dist, color = "Raw Trajectories"), linewidth = 1) +
  geom_point(aes(y = raw_mean_dist, color = "Raw Trajectories"), size = 2.5) +
  geom_line(aes(y = dem_mean_dist, color = "Demeaned Trajectories"), linewidth = 1, linetype = "dashed") +
  geom_point(aes(y = dem_mean_dist, color = "Demeaned Trajectories"), size = 2.5) +
  scale_x_continuous(breaks = 1:10) +
  scale_color_manual(values = c("Raw Trajectories" = "#1f77b4", "Demeaned Trajectories" = "#ff7f0e")) +
  labs(
    title = "Mean Distance from Cluster Centroids Across k (Elbow Analysis)",
    subtitle = "NetHealth Ego Network Degree Trajectories (n = 450)",
    x = "Number of Clusters (k)",
    y = "Mean Distance to Centroid",
    color = "Scheme"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom"
  )

ggsave("output/figures/fig4_kmeans_elbow_curves.png", p_elbow, width = 8, height = 5, dpi = 300)

cat("\n==> Script 02 completed successfully!\n")
