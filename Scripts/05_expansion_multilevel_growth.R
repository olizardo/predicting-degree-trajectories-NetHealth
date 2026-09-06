#' ---
#' title: "05_expansion_multilevel_growth.R"
#' description: "Expansion 2: Multilevel Poisson Growth Curve GLMMs Testing Personality Moderation"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lme4)
  library(ggplot2)
  library(scales)
})

cat("==> Loading analytical longitudinal dataset...\n")
analytical <- readRDS("data/processed/degree_analytical_w16.rds")
degree_long <- readRDS("data/processed/degree_trajectories_long.rds") %>%
  filter(wave_num <= 6, egoid %in% analytical$egoid) %>%
  inner_join(analytical %>% select(egoid, sex, race, parents_income_num,
                                   z_extraversion, z_neuroticism, z_agreeableness,
                                   z_conscientiousness, z_openness, z_trust), by = "egoid") %>%
  mutate(
    time = wave_num - 1 # Center time at Wave 1 baseline (time = 0, 1, 2, 3, 4, 5)
  )

cat("Analytical observations:", nrow(degree_long), "across", n_distinct(degree_long$egoid), "egos\n")

# -------------------------------------------------------------------
# Fit Multilevel Poisson GLMM Hierarchy
# -------------------------------------------------------------------
cat("\nFitting Model 1: Unconditional Random Intercept Growth Model...\n")
m1 <- glmer(degree ~ time + (1 | egoid), data = degree_long, family = poisson)

cat("Fitting Model 2: Adding Demographics...\n")
m2 <- glmer(degree ~ time + sex + race + parents_income_num + (1 | egoid), data = degree_long, family = poisson)

cat("Fitting Model 3: Adding Big Five Personality & Trust...\n")
m3 <- glmer(
  degree ~ time + sex + race + parents_income_num +
    z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust +
    (1 | egoid),
  data = degree_long,
  family = poisson
)

cat("Fitting Model 4: Cross-Level Trajectory Moderation (Personality x Time)...\n")
m4 <- glmer(
  degree ~ time * z_extraversion + time * z_neuroticism +
    sex + race + parents_income_num +
    z_agreeableness + z_conscientiousness + z_openness + z_trust +
    (1 | egoid),
  data = degree_long,
  family = poisson
)

# Compile model comparison summary
glance_tab <- tibble(
  Model = paste0("Model ", 1:4),
  Description = c(
    "Unconditional Growth",
    "+ Social Demographics",
    "+ Big Five Traits & Trust",
    "+ Personality x Time Moderation"
  ),
  LogLik = c(logLik(m1)[1], logLik(m2)[1], logLik(m3)[1], logLik(m4)[1]),
  AIC = c(AIC(m1), AIC(m2), AIC(m3), AIC(m4)),
  BIC = c(BIC(m1), BIC(m2), BIC(m3), BIC(m4))
)
cat("\nModel Comparison Fit Table:\n")
print(as.data.frame(glance_tab))

# Extract tidy coefficients for Model 4
cf_mat <- summary(m4)$coefficients
tidy_m4 <- tibble(
  term = rownames(cf_mat),
  estimate = cf_mat[, "Estimate"],
  std.error = cf_mat[, "Std. Error"],
  statistic = cf_mat[, "z value"],
  p.value = cf_mat[, "Pr(>|z|)"]
) %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error,
    IRR = exp(estimate),
    conf.low.irr = exp(conf.low),
    conf.high.irr = exp(conf.high),
    p_format = ifelse(p.value < 0.001, "< .001", sprintf("%.3f", p.value))
  ) %>%
  select(term, estimate, std.error, statistic, p.value, p_format, IRR, conf.low.irr, conf.high.irr)

cat("\nModel 4 Fixed Effects (Incidence Rate Ratios):\n")
print(as.data.frame(tidy_m4 %>% select(term, IRR, conf.low.irr, conf.high.irr, p_format)))

write_csv(glance_tab, "output/tables/table4_multilevel_model_fit.csv")
write_csv(tidy_m4, "output/tables/table5_multilevel_glmm_estimates.csv")

# -------------------------------------------------------------------
# Visualize Predicted Degree Trajectories by Personality Profiles
# -------------------------------------------------------------------
cat("\n==> Generating predicted trajectory margins plot...\n")

# Construct prediction grid for Extraversion (+/- 1 SD) and Neuroticism (+/- 1 SD)
pred_grid <- expand_grid(
  time = 0:5,
  z_extraversion = c(-1, 1),
  z_neuroticism = c(-1, 1),
  sex = factor("Female", levels = levels(degree_long$sex)),
  race = factor("White", levels = levels(degree_long$race)),
  parents_income_num = mean(degree_long$parents_income_num, na.rm = TRUE),
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0,
  z_trust = 0
) %>%
  mutate(
    Extraversion = factor(ifelse(z_extraversion == 1, "High Extraversion (+1 SD)", "Low Extraversion (-1 SD)")),
    Neuroticism = factor(ifelse(z_neuroticism == 1, "High Neuroticism (+1 SD)", "Low Neuroticism (-1 SD)")),
    wave_num = time + 1
  )

pred_grid$pred_deg <- predict(m4, newdata = pred_grid, re.form = NA, type = "response")

p_pred <- ggplot(pred_grid, aes(x = wave_num, y = pred_deg, color = Extraversion, linetype = Neuroticism)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 1:6, limits = c(1, 6)) +
  scale_y_continuous(limits = c(6, 18), breaks = seq(6, 18, 2)) +
  scale_color_manual(values = c("High Extraversion (+1 SD)" = "#1f77b4", "Low Extraversion (-1 SD)" = "#e05638")) +
  scale_linetype_manual(values = c("High Neuroticism (+1 SD)" = "dashed", "Low Neuroticism (-1 SD)" = "solid")) +
  labs(
    title = "Predicted Ego Degree Growth Trajectories by Personality Profiles",
    subtitle = "Population-level marginal predictions from Multilevel Poisson GLMM across Waves 1–6",
    x = "Survey Wave (Wave 1 Matriculation to Wave 6 Fall Junior)",
    y = "Predicted Expected Degree (Ego Network Size)",
    color = "Extraversion",
    linetype = "Neuroticism"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey30"),
    legend.position = "bottom",
    legend.box = "vertical",
    panel.border = element_rect(color = "grey80", fill = NA)
  )

ggsave("output/figures/fig6_multilevel_predicted_trajectories.png", p_pred, width = 8, height = 6, dpi = 300)

cat("\n==> Script 05 (Expansion: Multilevel GLMM) completed successfully!\n")
