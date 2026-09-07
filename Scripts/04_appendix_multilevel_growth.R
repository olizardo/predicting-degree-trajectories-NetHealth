#' ---
#' title: "04_appendix_multilevel_growth.R"
#' description: "Appendix: Multilevel Poisson Growth Curve GLMMs Across 8 Waves"
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

cat("==> Loading analytical longitudinal dataset across 8 waves...\n")
analytical <- readRDS("data/processed/degree_analytical_w18.rds")
degree_long <- readRDS("data/processed/degree_trajectories_long.rds") %>%
  filter(wave_num <= 8, egoid %in% analytical$egoid) %>%
  inner_join(
    analytical %>% select(
      egoid, female, race, parents_income_num,
      z_extraversion, z_neuroticism, z_agreeableness,
      z_conscientiousness, z_openness, z_trust
    ),
    by = "egoid"
  ) %>%
  mutate(time = wave_num - 1) # time = 0, 1, 2, ..., 7

cat("Analytical observations:", nrow(degree_long), "across", n_distinct(degree_long$egoid), "egos\n")

ctrl <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 100000))

# -------------------------------------------------------------------
# Fit Multilevel Poisson GLMM Hierarchy (Models 1 - 4)
# -------------------------------------------------------------------
cat("\nFitting Model 1: Unconditional Random Intercept Growth Model...\n")
m1 <- glmer(degree ~ time + (1 | egoid), data = degree_long, family = poisson, control = ctrl)

cat("Fitting Model 2: Adding Social Demographics...\n")
m2 <- glmer(degree ~ time + female + race + parents_income_num + (1 | egoid), data = degree_long, family = poisson, control = ctrl)

cat("Fitting Model 3: Adding Big Five Personality & Trust...\n")
m3 <- glmer(
  degree ~ time + female + race + parents_income_num +
    z_extraversion + z_neuroticism + z_agreeableness + z_conscientiousness + z_openness + z_trust +
    (1 | egoid),
  data = degree_long,
  family = poisson,
  control = ctrl
)

cat("Fitting Model 4: Cross-Level Trajectory Moderation (Personality x Time)...\n")
m4 <- glmer(
  degree ~ time * z_extraversion + time * z_neuroticism +
    female + race + parents_income_num +
    z_agreeableness + z_conscientiousness + z_openness + z_trust +
    (1 | egoid),
  data = degree_long,
  family = poisson,
  control = ctrl
)

# Model comparison summary
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

write.csv(glance_tab, "output/tables/tableA1_multilevel_model_fit.csv", row.names = FALSE)
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
    IRR = exp(estimate),
    conf.low.irr = exp(estimate - 1.96 * std.error),
    conf.high.irr = exp(estimate + 1.96 * std.error),
    p_format = case_when(
      p.value < 0.001 ~ "< .001",
      TRUE ~ sprintf("%.3f", p.value)
    )
  )

write.csv(tidy_m4, "output/tables/tableA1_multilevel_glmm_estimates.csv", row.names = FALSE)

clean_terms <- c(
  "(Intercept)"             = "Intercept (Baseline Degree)",
  "time"                    = "Time (Elapsed Collegiate Waves 0-7)",
  "z_extraversion"          = "Extraversion (z-score)",
  "z_neuroticism"           = "Neuroticism (z-score)",
  "female"                  = "Gender Identity: Woman (ref: Man)",
  "raceAsian"               = "Race: Asian (ref: White)",
  "raceBlack"               = "Race: Black (ref: White)",
  "raceHispanic/Latino"     = "Race: Hispanic/Latino (ref: White)",
  "raceOther/International" = "Race: Other/International (ref: White)",
  "parents_income_num"      = "Parents' Income (Ordinal Scale)",
  "z_agreeableness"         = "Agreeableness (z-score)",
  "z_conscientiousness"     = "Conscientiousness (z-score)",
  "z_openness"              = "Openness (z-score)",
  "z_trust"                 = "Generalized Trust (z-score)",
  "time:z_extraversion"     = "Time x Extraversion",
  "time:z_neuroticism"      = "Time x Neuroticism"
)

tabA1_rows <- tidy_m4 %>%
  mutate(
    Variable = recode(term, !!!clean_terms),
    Est_SE   = paste0(sprintf("%.2f", estimate), " (", sprintf("%.2f", std.error), ")"),
    IRR_CI   = paste0(sprintf("%.2f", IRR), " [", sprintf("%.2f", conf.low.irr), ", ", sprintf("%.2f", conf.high.irr), "]"),
    p_val    = p_format
  ) %>%
  select(Variable, Est_SE, IRR_CI, p_val)

mdA1 <- c(
  "| Predictor Variable | Estimate (SE) | Incidence Rate Ratio [95% CI] | p-value |",
  "|:---|:---:|:---:|:---:|",
  apply(tabA1_rows, 1, function(r) {
    paste0("| ", r["Variable"], " | ", r["Est_SE"], " | ", r["IRR_CI"], " | ", r["p_val"], " |")
  })
)
writeLines(mdA1, "cache/tableA1_multilevel_glmm_estimates.md")
cat("==> Exported Table A1 to cache/tableA1_multilevel_glmm_estimates.md\n")

# -------------------------------------------------------------------
# Figure A1: Predicted Ego Degree Growth Trajectories Across 8 Waves
# -------------------------------------------------------------------
cat("==> Generating publication-grade predicted trajectory plot across 8 waves (Figure A1)...\n")

pred_grid <- expand_grid(
  time = 0:7,
  z_extraversion = c(-1, 1),
  z_neuroticism = c(-1, 1),
  female = 0.5,
  race = "White",
  parents_income_num = mean(analytical$parents_income_num, na.rm = TRUE),
  z_agreeableness = 0,
  z_conscientiousness = 0,
  z_openness = 0,
  z_trust = 0
)

# Predict population-level expectations (re.form = NA)
pred_grid$pred_log <- predict(m4, newdata = pred_grid, re.form = NA)
pred_grid$pred_degree <- exp(pred_grid$pred_log)

pred_grid <- pred_grid %>%
  mutate(
    wave_num = time + 1,
    Extraversion = factor(z_extraversion, levels = c(1, -1), labels = c("High Extraversion (+1 SD)", "Low Extraversion (-1 SD)")),
    Neuroticism  = factor(z_neuroticism, levels = c(1, -1), labels = c("High Neuroticism (+1 SD)", "Low Neuroticism (-1 SD)")),
    profile = paste(Extraversion, Neuroticism, sep = " / ")
  )

p_figA1 <- ggplot(pred_grid, aes(x = wave_num, y = pred_degree, color = Extraversion, linetype = Neuroticism, group = profile)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 2.8) +
  scale_x_continuous(
    breaks = 1:8,
    labels = c("W1\nFrosh", "W2\nFrosh", "W3\nSoph", "W4\nSoph",
               "W5\nJun", "W6\nJun", "W7\nSen", "W8\nSen")
  ) +
  scale_y_continuous(limits = c(5, 17), breaks = seq(6, 16, 2)) +
  scale_color_manual(values = c("High Extraversion (+1 SD)" = "#1f77b4", "Low Extraversion (-1 SD)" = "#d62728")) +
  scale_linetype_manual(values = c("High Neuroticism (+1 SD)" = "dashed", "Low Neuroticism (-1 SD)" = "solid")) +
  labs(
    title = "Predicted Ego Degree Growth Trajectories by Personality Profiles (Waves 1–8)",
    subtitle = "Population-level marginal predictions from Multilevel Poisson GLMM (Model 4; N = 433)",
    x = "College Academic Wave",
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
    panel.border = element_rect(color = "grey80", fill = NA),
    panel.grid.minor = element_blank()
  )

ggsave("Plots/figA1_multilevel_predicted_trajectories.png", p_figA1, width = 9, height = 6.5, dpi = 300)
ggsave("output/figures/figA1_multilevel_predicted_trajectories.png", p_figA1, width = 9, height = 6.5, dpi = 300)

cat("\n==> Script 04 (Appendix Multilevel GLMM) completed successfully! Generated Table A1 and Figure A1.\n")
