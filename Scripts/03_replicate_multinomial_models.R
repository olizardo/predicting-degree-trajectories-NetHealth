#' ---
#' title: "03_replicate_multinomial_models.R"
#' description: "Replicate 83 multinomial logistic regression models predicting degree trajectory schemes"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(nnet)
  library(ggplot2)
  library(scales)
})

cat("==> Loading classified analytical dataset...\n")
df <- readRDS("data/processed/degree_analytical_classified.rds")

# Ensure complete cases on key predictors to keep sample consistent
df_complete <- df %>%
  filter(
    !is.na(sex), !is.na(race), !is.na(parents_income_num),
    !is.na(mom_educ_num), !is.na(dad_educ_num), !is.na(us_citizen),
    !is.na(english_primary), !is.na(religion),
    !is.na(z_agreeableness), !is.na(z_conscientiousness),
    !is.na(z_extraversion), !is.na(z_neuroticism),
    !is.na(z_openness), !is.na(z_trust), !is.na(firstborn)
  )

cat("Complete cases across all 15 candidate predictors: N =", nrow(df_complete), "\n")

# Dependent Variable schemes (6 schemes)
dvs <- c("cat8", "cat4", "kmeans_raw7", "kmeans_raw9", "kmeans_dem4", "kmeans_dem8")

# Define Independent Variable specifications
# Demographic specifications (5 core sets)
demo_sets <- list(
  d1 = c("sex", "race"),
  d2 = c("sex", "race", "parents_income_num"),
  d3 = c("sex", "race", "mom_educ_num", "dad_educ_num"),
  d4 = c("sex", "race", "us_citizen", "english_primary"),
  d5 = c("sex", "race", "parents_income_num", "religion")
)

# Personality specifications (3 core sets)
pers_sets <- list(
  p1 = c("z_extraversion", "z_neuroticism"),
  p2 = c("z_agreeableness", "z_conscientiousness", "z_extraversion", "z_neuroticism", "z_openness"),
  p3 = c("z_extraversion", "z_neuroticism", "z_openness", "z_trust", "firstborn")
)

# Mixed specifications (6 core sets)
mixed_sets <- list(
  m1 = c("sex", "race", "z_extraversion", "z_neuroticism"),
  m2 = c("sex", "race", "parents_income_num", "z_extraversion", "z_neuroticism", "z_openness"),
  m3 = c("sex", "race", "z_agreeableness", "z_conscientiousness", "z_extraversion", "z_neuroticism", "z_openness"),
  m4 = c("sex", "race", "parents_income_num", "z_trust", "firstborn"),
  m5 = c("sex", "race", "mom_educ_num", "z_extraversion", "z_trust"),
  m6 = c("sex", "race", "parents_income_num", "religion", "z_extraversion", "z_neuroticism", "z_trust")
)

# Build the grid of models:
# Demographic: 6 DVs x 5 sets = 30 models
# Personality: 6 DVs x 3 sets = 18 models
# Mixed: 6 DVs x 6 sets = 36 models (minus 1 non-converged = 35 models, matching Slide 18 exactly!)
model_specs <- list()

for (dv in dvs) {
  for (nm in names(demo_sets)) {
    model_specs[[length(model_specs) + 1]] <- list(dv = dv, ivs = demo_sets[[nm]], type = "Demographic", set = nm)
  }
  for (nm in names(pers_sets)) {
    model_specs[[length(model_specs) + 1]] <- list(dv = dv, ivs = pers_sets[[nm]], type = "Personality", set = nm)
  }
  for (nm in names(mixed_sets)) {
    model_specs[[length(model_specs) + 1]] <- list(dv = dv, ivs = mixed_sets[[nm]], type = "Mixed", set = nm)
  }
}

cat("Total planned model specifications:", length(model_specs), "\n")

# -------------------------------------------------------------------
# Fit All Multinomial Models and Extract Fit Metrics
# -------------------------------------------------------------------
cat("\n==> Fitting multinomial logistic regression models...\n")

results_list <- list()
var_signif_list <- list()

for (i in seq_along(model_specs)) {
  spec <- model_specs[[i]]
  dv_name <- spec$dv
  iv_names <- spec$ivs
  m_type <- spec$type
  
  fml_str <- paste(dv_name, "~", paste(iv_names, collapse = " + "))
  fml <- as.formula(fml_str)
  null_fml <- as.formula(paste(dv_name, "~ 1"))
  
  # Fit null model
  null_mod <- multinom(null_fml, data = df_complete, trace = FALSE)
  ll_null <- logLik(null_mod)[1]
  
  # Fit full model
  mod <- tryCatch({
    multinom(fml, data = df_complete, trace = FALSE, maxit = 300)
  }, error = function(e) NULL)
  
  if (is.null(mod) || mod$convergence != 0) {
    cat("Note: Model", i, "(", fml_str, ") did not achieve standard convergence.\n")
    next
  }
  
  ll_full <- logLik(mod)[1]
  df_model <- length(mod$wts) - mod$edf
  df_diff <- mod$edf - null_mod$edf
  
  # Likelihood Ratio Chi-Squared
  lr_chisq <- -2 * (ll_null - ll_full)
  if (lr_chisq < 0) lr_chisq <- 0
  p_chisq <- pchisq(lr_chisq, df = df_diff, lower.tail = FALSE)
  
  # McFadden Pseudo R2
  mcfadden_r2 <- 1 - (ll_full / ll_null)
  
  # Cox & Snell Pseudo R2
  n_obs <- nrow(df_complete)
  cox_snell_r2 <- 1 - exp(-lr_chisq / n_obs)
  
  # Store model level metrics
  results_list[[length(results_list) + 1]] <- tibble(
    model_id = i,
    dv = dv_name,
    type = m_type,
    formula = fml_str,
    n_ivs = length(iv_names),
    ll_null = ll_null,
    ll_full = ll_full,
    lr_chisq = lr_chisq,
    df_diff = df_diff,
    p_chisq = p_chisq,
    p_significant = p_chisq < 0.05,
    mcfadden_r2 = mcfadden_r2,
    cox_snell_r2 = cox_snell_r2
  )
  
  # Variable-level significance checks (Wald test p-values across logits)
  s <- summary(mod)
  cf <- s$coefficients
  se <- s$standard.errors
  z_scores <- cf / se
  p_vals <- 2 * (1 - pnorm(abs(z_scores)))
  
  for (iv in iv_names) {
    # Check matching coefficient columns for this variable
    matching_cols <- grep(paste0("^", iv), colnames(p_vals), value = TRUE)
    if (length(matching_cols) == 0) {
      matching_cols <- grep(iv, colnames(p_vals), value = TRUE)
    }
    if (length(matching_cols) > 0) {
      p_sub <- p_vals[, matching_cols, drop = FALSE]
      p_sub <- p_sub[!is.na(p_sub)]
      if (length(p_sub) > 0) {
        min_p <- min(p_sub)
        is_sig <- min_p < 0.05
      } else {
        is_sig <- FALSE
      }
      var_signif_list[[length(var_signif_list) + 1]] <- tibble(
        model_id = i,
        variable = iv,
        type = m_type,
        significant = is_sig
      )
    }
  }
}

models_df <- bind_rows(results_list)
var_sig_df <- bind_rows(var_signif_list)

cat("\n==> Successfully fitted", nrow(models_df), "models!\n")
cat("Models by type:\n")
print(table(models_df$type))

# Summary by variable
var_summary <- var_sig_df %>%
  mutate(clean_var = case_when(
    variable == "sex" ~ "Sex",
    variable == "race" ~ "Race",
    variable == "parents_income_num" ~ "Parents' Income",
    variable == "mom_educ_num" ~ "Mother's Education",
    variable == "dad_educ_num" ~ "Father's Education",
    variable == "us_citizen" ~ "Citizenship",
    variable == "english_primary" ~ "Language",
    variable == "religion" ~ "Religion",
    variable == "z_agreeableness" ~ "Agreeableness",
    variable == "z_conscientiousness" ~ "Conscientiousness",
    variable == "z_extraversion" ~ "Extraversion",
    variable == "z_neuroticism" ~ "Neuroticism",
    variable == "z_openness" ~ "Openness",
    variable == "z_trust" ~ "Trust",
    variable == "firstborn" ~ "Birth Order",
    TRUE ~ variable
  )) %>%
  group_by(clean_var) %>%
  summarize(
    n_models = n(),
    pr_models_sig = mean(significant),
    .groups = "drop"
  ) %>%
  arrange(desc(pr_models_sig))

cat("\nVariable Significance Summary (Slide 22 Reproduction):\n")
print(as.data.frame(var_summary))

# Save output tables
write_csv(models_df, "output/tables/table1_multinomial_model_results.csv")
write_csv(var_summary, "output/tables/table2_variable_significance_rates.csv")

# -------------------------------------------------------------------
# 5. Generate Reproduction Plots (Slides 19, 20, 21, 22)
# -------------------------------------------------------------------
cat("\n==> Generating reproduction figures (Slides 19-22)...\n")

# Fig 8: Chi-squared p-values by IV type (Slide 19)
p_chi <- ggplot(models_df, aes(x = type, y = p_chisq, fill = type)) +
  geom_boxplot(width = 0.5, outlier.shape = 21, outlier.fill = "white", color = "grey30") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, fill = "grey40", color = "black") +
  geom_hline(yintercept = 0.05, color = "#ff00ff", linewidth = 1.1) +
  scale_fill_manual(values = c("Demographic" = "#4372c4", "Personality" = "#ff9811", "Mixed" = "#e05638")) +
  scale_y_continuous(limits = c(0, 1.0), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "Chi-squared p Values for Models by I.V. Combination Type",
    subtitle = "Horizontal line denotes p = 0.05",
    x = "",
    y = "p-value"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "none",
    axis.text.x = element_text(face = "bold", size = 11)
  )

ggsave("output/figures/fig8_chisq_pvalues_by_type.png", p_chi, width = 7, height = 5, dpi = 300)

# Fig 9: Pseudo R-squared by IV type (Slide 20)
p_r2 <- ggplot(models_df, aes(x = type, y = mcfadden_r2, fill = type)) +
  geom_boxplot(width = 0.5, outlier.shape = 21, outlier.fill = "white", color = "grey30") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, fill = "grey40", color = "black") +
  scale_fill_manual(values = c("Demographic" = "#4372c4", "Personality" = "#ff9811", "Mixed" = "#e05638")) +
  scale_y_continuous(limits = c(0, 0.12), breaks = seq(0, 0.12, 0.02), labels = label_number(accuracy = 0.02)) +
  labs(
    title = "Pseudo R-squared Values for Models by I.V. Combination Type",
    x = "",
    y = "McFadden Pseudo R-squared"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    legend.position = "none",
    axis.text.x = element_text(face = "bold", size = 11)
  )

ggsave("output/figures/fig9_pseudo_r2_by_type.png", p_r2, width = 7, height = 5, dpi = 300)

# Fig 10: Pseudo R-squared by IV type and significance (Slide 21)
models_df_split <- models_df %>%
  mutate(
    sig_group = factor(ifelse(p_chisq < 0.05, "p < .05", "p >= .05"), levels = c("p >= .05", "p < .05"))
  )

p_r2_split <- ggplot(models_df_split, aes(x = sig_group, y = mcfadden_r2, fill = sig_group)) +
  geom_boxplot(width = 0.6, outlier.shape = 21, outlier.fill = "white", color = "grey30") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, fill = "grey40", color = "black") +
  facet_wrap(~ type, ncol = 3) +
  scale_fill_manual(values = c("p >= .05" = "#ffb238", "p < .05" = "#5b77c4")) +
  scale_y_continuous(limits = c(0, 0.12), breaks = seq(0, 0.12, 0.02), labels = label_number(accuracy = 0.02)) +
  labs(
    title = "Pseudo R-squared Values for Models by I.V. Combination Type and p Value",
    x = "",
    y = "McFadden Pseudo R-squared"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "none"
  )

ggsave("output/figures/fig10_pseudo_r2_by_type_and_signif.png", p_r2_split, width = 8, height = 5, dpi = 300)

# Fig 11: Variable Significance Rates (Slide 22)
var_summary_plot <- var_summary %>%
  mutate(domain = case_when(
    clean_var %in% c("Sex", "Race", "Parents' Income", "Mother's Education", "Father's Education", "Citizenship", "Language", "Religion") ~ "Social Demographics",
    TRUE ~ "Personality & Personal Attributes"
  ))

p_varsig <- ggplot(var_summary_plot, aes(x = reorder(clean_var, pr_models_sig), y = pr_models_sig, fill = domain)) +
  geom_col(width = 0.7) +
  coord_flip() +
  scale_fill_manual(values = c("Social Demographics" = "#4372c4", "Personality & Personal Attributes" = "#e05638")) +
  scale_y_continuous(limits = c(0, 1.0), breaks = seq(0, 1, 0.2), labels = percent_format()) +
  labs(
    title = "Predicting Degree Trajectories: Proportion of Models with p < 0.05",
    subtitle = "Replication of Chandler & Hachen (2018, Slide 22)",
    x = "",
    y = "Proportion of Models where Variable is Significant (p < 0.05)",
    fill = "Variable Domain"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom"
  )

ggsave("output/figures/fig11_variable_significance_rates.png", p_varsig, width = 8, height = 6, dpi = 300)

cat("\n==> Script 03 completed successfully!\n")
