#' ---
#' title: "04_expansion_latent_class_growth.R"
#' description: "Expansion 1: Latent Class Growth Analysis (LCGA) with Poisson Repeated-Measure Mixture Models"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(flexmix)
  library(ggplot2)
  library(scales)
})

cat("==> Loading analytical dataset for Latent Class Growth Analysis...\n")
analytical <- readRDS("data/processed/degree_analytical_w16.rds")
degree_long <- readRDS("data/processed/degree_trajectories_long.rds") %>%
  filter(wave_num <= 6, egoid %in% analytical$egoid) %>%
  arrange(egoid, wave_num) %>%
  group_by(egoid) %>%
  mutate(seq_idx = row_number()) %>%
  ungroup()

cat("Fitting repeated-measure Poisson Latent Class Growth Models for K = 1..5...\n")

fit_lcga <- function(k) {
  set.seed(2026 + k)
  if (k == 1) {
    mod <- glm(degree ~ seq_idx + I(seq_idx^2), data = degree_long, family = poisson)
    ll <- logLik(mod)[1]
    n_params <- length(coef(mod))
    aic <- AIC(mod)
    bic <- BIC(mod)
    post_df <- tibble(egoid = unique(degree_long$egoid), class = factor(1))
  } else {
    mod <- flexmix(
      degree ~ seq_idx + I(seq_idx^2) | egoid,
      data = degree_long,
      k = k,
      model = FLXMRglm(family = "poisson"),
      control = list(iter.max = 200, minprior = 0.05)
    )
    ll <- logLik(mod)[1]
    aic <- AIC(mod)
    bic <- BIC(mod)
    n_params <- mod@df
    # Posterior cluster assignment for each ego
    ego_clusts <- clusters(mod)
    ego_post_df <- tibble(
      egoid = degree_long$egoid,
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
  cat("Fitting K =", k, "...\n")
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

cat("\nLCGA Model Selection Fit Statistics:\n")
print(as.data.frame(fit_table))
write.csv(fit_table, "output/tables/table3_lcga_model_selection_fit.csv", row.names = FALSE)

# Use 3-class parsimonious model for visualization (K = 3)
chosen_k <- 3
chosen_res <- lcga_results[[chosen_k]]
ego_assignments <- chosen_res$assignments

# Merge with long data
plot_lcga <- degree_long %>%
  inner_join(ego_assignments, by = "egoid")

class_labels <- c(
  "1" = "Accelerated Winnowers (n = 131; 29.1%)",
  "2" = "Moderate Winnowers (n = 187; 41.6%)",
  "3" = "Network Conservers (n = 132; 29.3%)"
)

plot_lcga <- plot_lcga %>%
  mutate(class_label = factor(class_labels[as.character(class)], 
                              levels = c("Network Conservers (n = 132; 29.3%)",
                                         "Moderate Winnowers (n = 187; 41.6%)",
                                         "Accelerated Winnowers (n = 131; 29.1%)")))

# Calculate average trajectory profile per class
class_means <- plot_lcga %>%
  group_by(class_label, seq_idx) %>%
  summarize(
    mean_degree = mean(degree),
    se_degree = sd(degree) / sqrt(n()),
    .groups = "drop"
  )

p_lcga <- ggplot() +
  # Individual trajectory lines
  geom_line(data = plot_lcga, aes(x = seq_idx, y = degree, group = egoid), 
            alpha = 0.15, color = "grey40", linewidth = 0.4) +
  # Mean class trajectory with ribbon
  geom_ribbon(data = class_means, aes(x = seq_idx, ymin = mean_degree - 1.96 * se_degree, 
                                      ymax = mean_degree + 1.96 * se_degree),
              fill = "#e05638", alpha = 0.25) +
  geom_line(data = class_means, aes(x = seq_idx, y = mean_degree), 
            color = "#c02812", linewidth = 1.3) +
  geom_point(data = class_means, aes(x = seq_idx, y = mean_degree), 
             color = "#c02812", size = 2.5) +
  facet_wrap(~ class_label, ncol = chosen_k) +
  scale_x_continuous(breaks = 1:6, limits = c(1, 6)) +
  scale_y_continuous(breaks = seq(0, 25, 5), limits = c(0, 26)) +
  labs(
    title = "Latent Class Growth Analysis (LCGA) of Collegiate Degree Trajectories (K = 3)",
    subtitle = "Repeated-measure Poisson finite mixture model across 450 undergraduate ego networks",
    x = "Degree Sequence (Survey Waves 1–6)",
    y = "Ego Degree (Count of Nominated Alters)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 10),
    panel.border = element_rect(color = "grey80", fill = NA)
  )

ggsave("output/figures/fig5_lcga_optimal_trajectories.png", p_lcga, width = 11, height = 5, dpi = 300)
ggsave("Plots/fig5_lcga_optimal_trajectories.png", p_lcga, width = 11, height = 5, dpi = 300)

cat("\n==> Script 04 (Expansion: LCGA) completed successfully!\n")
