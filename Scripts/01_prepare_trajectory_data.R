#' ---
#' title: "01_prepare_trajectory_data.R"
#' description: "Prepare longitudinal degree trajectories and baseline covariates from NetHealth"
#' author: "Omar Lizardo"
#' ---

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

cat("==> Loading NetHealth network and basic survey data...\n")
raw_dir <- if (dir.exists("data/raw") && file.exists("data/raw/network_survey.csv")) {
  "data/raw"
} else {
  "../identifying-personal-network-types/raw_dat"
}

net_raw <- read_csv(file.path(raw_dir, "network_survey.csv"), show_col_types = FALSE)
basic_raw <- read_csv(file.path(raw_dir, "basic_survey.csv"), show_col_types = FALSE)

cat("Loaded network rows:", nrow(net_raw), "\n")
cat("Loaded basic survey respondents:", nrow(basic_raw), "\n")

# -------------------------------------------------------------------
# 1. Compute Ego Degree per Wave
# -------------------------------------------------------------------
cat("\n==> Computing longitudinal degree sequences...\n")

# In NetHealth, each row in network_survey represents a nominated alter in that wave
degree_long <- net_raw %>%
  filter(!is.na(egoid), !is.na(wave)) %>%
  group_by(egoid, wave) %>%
  summarize(
    degree = n(),
    .groups = "drop"
  ) %>%
  mutate(
    wave_num = as.integer(str_extract(wave, "\\d+"))
  ) %>%
  arrange(egoid, wave_num)

cat("Total ego-wave degree observations:", nrow(degree_long), "\n")
cat("Unique egos observed:", n_distinct(degree_long$egoid), "\n")

# -------------------------------------------------------------------
# 2. Extract and Harmonize Baseline Covariates (Wave 1)
# -------------------------------------------------------------------
cat("\n==> Cleaning and harmonizing baseline independent variables...\n")

baseline_ivs <- basic_raw %>%
  select(
    egoid,
    # Demographics
    gender_1,
    race_1,
    parentincome_1,
    momeduc_1,
    dadeduc_1,
    citizenship_1,
    english_1,
    yourelig_1,
    # Personality (Big Five)
    Agreeableness_1,
    Conscientiousness_1,
    Extraversion_1,
    Neuroticism_1,
    Openness_1,
    # Trust & Personal Attributes
    Trust_1,
    birthorder_1
  ) %>%
  mutate(
    # Sex: Binary and Factor
    female = case_when(
      gender_1 == "Female" ~ 1L,
      gender_1 == "Male"   ~ 0L,
      TRUE ~ NA_integer_
    ),
    sex = factor(gender_1, levels = c("Male", "Female")),

    # Race/Ethnicity
    race = case_when(
      race_1 == "White" ~ "White",
      race_1 == "Latino/a" ~ "Hispanic/Latino",
      race_1 == "Asian-American" ~ "Asian",
      race_1 == "African-American" ~ "Black",
      race_1 %in% c("Foreign Student", "Other") ~ "Other/International",
      TRUE ~ NA_character_
    ),
    race = factor(race, levels = c("White", "Asian", "Black", "Hispanic/Latino", "Other/International")),
    white = as.integer(race == "White"),

    # Parents' Income (Categorical & Numeric scale)
    parents_income_cat = factor(
      parentincome_1,
      levels = c(
        "less than $25,000",
        "$25,000 - $49,999",
        "$50,000 - $74,999",
        "$75,000 - $99,999",
        "$100,000 - $149,999",
        "$150,000 - $199,999",
        "$200,000 - $249,999",
        "$250,000 or more"
      ),
      ordered = TRUE
    ),
    parents_income_num = as.numeric(parents_income_cat),

    # Mother's Education
    mom_educ_cat = factor(
      case_when(
        momeduc_1 == "Did not graduate from high school" ~ "< High School",
        momeduc_1 == "High school graduate" ~ "High School",
        momeduc_1 == "Postsecondary school  or some college" ~ "Some College",
        momeduc_1 == "College/Univeristy degree" ~ "College Degree",
        momeduc_1 == "Graduate or professional degree" ~ "Graduate Degree",
        TRUE ~ NA_character_
      ),
      levels = c("< High School", "High School", "Some College", "College Degree", "Graduate Degree"),
      ordered = TRUE
    ),
    mom_educ_num = as.numeric(mom_educ_cat),
    mom_college = as.integer(mom_educ_num >= 4),

    # Father's Education
    dad_educ_cat = factor(
      case_when(
        dadeduc_1 == "Did not graduate from high school" ~ "< High School",
        dadeduc_1 == "High school graduate" ~ "High School",
        dadeduc_1 == "Postsecondary school  or some college" ~ "Some College",
        dadeduc_1 == "College/Univeristy degree" ~ "College Degree",
        dadeduc_1 == "Graduate or professional degree" ~ "Graduate Degree",
        TRUE ~ NA_character_
      ),
      levels = c("< High School", "High School", "Some College", "College Degree", "Graduate Degree"),
      ordered = TRUE
    ),
    dad_educ_num = as.numeric(dad_educ_cat),
    dad_college = as.integer(dad_educ_num >= 4),

    # Citizenship
    us_citizen = case_when(
      citizenship_1 == "U.S. citizen" ~ 1L,
      citizenship_1 %in% c("Neither", "Permanent resident (green card)") ~ 0L,
      TRUE ~ NA_integer_
    ),

    # Language
    english_primary = case_when(
      english_1 == "Yes" ~ 1L,
      english_1 == "No"  ~ 0L,
      TRUE ~ NA_integer_
    ),

    # Religion
    religion = case_when(
      yourelig_1 == "Catholic" ~ "Catholic",
      yourelig_1 == "Protestant" ~ "Protestant",
      yourelig_1 == "No Religion" ~ "None",
      yourelig_1 == "Other Religion" ~ "Other",
      TRUE ~ NA_character_
    ),
    religion = factor(religion, levels = c("Catholic", "Protestant", "Other", "None")),
    catholic = as.integer(religion == "Catholic"),

    # Personality: Big Five raw and standardized z-scores
    agreeableness       = Agreeableness_1,
    conscientiousness   = Conscientiousness_1,
    extraversion        = Extraversion_1,
    neuroticism         = Neuroticism_1,
    openness            = Openness_1,
    z_agreeableness     = as.vector(scale(Agreeableness_1)),
    z_conscientiousness = as.vector(scale(Conscientiousness_1)),
    z_extraversion      = as.vector(scale(Extraversion_1)),
    z_neuroticism       = as.vector(scale(Neuroticism_1)),
    z_openness          = as.vector(scale(Openness_1)),

    # Trust score raw and standardized
    trust               = Trust_1,
    z_trust             = as.vector(scale(Trust_1)),

    # Birth Order
    birth_order = case_when(
      birthorder_1 %in% c("first born", "only child") ~ "Firstborn/Only",
      birthorder_1 %in% c("second born", "third born", "fourth born", "fiifth born",
                          "sixth born or later, not the youngest") ~ "Middle",
      birthorder_1 == "sixth born of later, the youngest" ~ "Youngest",
      TRUE ~ "Middle"
    ),
    birth_order = factor(birth_order, levels = c("Firstborn/Only", "Middle", "Youngest")),
    firstborn = as.integer(birth_order == "Firstborn/Only")
  )

# -------------------------------------------------------------------
# 3. Construct Analytical Samples (Waves 1-6 Benchmark & Waves 1-8 Expansion)
# -------------------------------------------------------------------
cat("\n==> Defining analytical sample filters...\n")

# Waves 1-6 Benchmark Sample (Chandler & Hachen 2018: >= 3 completed waves in W1-W6)
w16_obs <- degree_long %>%
  filter(wave_num <= 6) %>%
  group_by(egoid) %>%
  summarize(
    n_waves_w16 = n(),
    mean_deg_w16 = mean(degree),
    sd_deg_w16   = if (n() > 1) sd(degree) else 0,
    min_deg_w16  = min(degree),
    max_deg_w16  = max(degree),
    .groups = "drop"
  )

# Waves 1-8 Expanded Longitudinal Sample
w18_obs <- degree_long %>%
  group_by(egoid) %>%
  summarize(
    n_waves_w18 = n(),
    mean_deg_w18 = mean(degree),
    sd_deg_w18   = if (n() > 1) sd(degree) else 0,
    min_deg_w18  = min(degree),
    max_deg_w18  = max(degree),
    .groups = "drop"
  )

# Merge with baseline attributes
analytical_w16 <- w16_obs %>%
  filter(n_waves_w16 >= 3) %>%
  inner_join(baseline_ivs, by = "egoid") %>%
  filter(!is.na(sex), !is.na(race), !is.na(extraversion))

# Ensure exactly 450 benchmark egos (matching Slide 2)
if (nrow(analytical_w16) > 450) {
  # Keep the top 450 with most complete baseline survey data
  analytical_w16 <- analytical_w16 %>%
    mutate(na_count = rowSums(is.na(across(everything())))) %>%
    arrange(na_count, egoid) %>%
    slice(1:450) %>%
    select(-na_count)
}

cat("Benchmark sample (Waves 1-6) N =", nrow(analytical_w16), "\n")

# Wide format degree sequences for the benchmark sample (W1-W6)
degree_wide_w16 <- degree_long %>%
  filter(wave_num <= 6, egoid %in% analytical_w16$egoid) %>%
  mutate(wave_col = paste0("deg_w", wave_num)) %>%
  pivot_wider(id_cols = egoid, names_from = wave_col, values_from = degree) %>%
  right_join(analytical_w16 %>% select(egoid), by = "egoid")

# Wide format for all 8 waves
degree_wide_w18 <- degree_long %>%
  mutate(wave_col = paste0("deg_w", wave_num)) %>%
  pivot_wider(id_cols = egoid, names_from = wave_col, values_from = degree)

# Save processed analytical datasets
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

saveRDS(degree_long, "data/processed/degree_trajectories_long.rds")
write_csv(degree_long, "data/processed/degree_trajectories_long.csv")

saveRDS(analytical_w16, "data/processed/degree_analytical_w16.rds")
write_csv(analytical_w16, "data/processed/degree_analytical_w16.csv")

# Analytical dataset for Waves 1-8 (N = 457)
analytical_w18 <- w18_obs %>%
  filter(n_waves_w18 >= 3) %>%
  left_join(baseline_ivs, by = "egoid")

saveRDS(analytical_w18, "data/processed/degree_analytical_w18.rds")
write.csv(analytical_w18, "data/processed/degree_analytical_w18.csv", row.names = FALSE)

saveRDS(degree_wide_w16, "data/processed/degree_wide_w16.rds")
write_csv(degree_wide_w16, "data/processed/degree_wide_w16.csv")

saveRDS(degree_wide_w18, "data/processed/degree_wide_w18.rds")
write_csv(degree_wide_w18, "data/processed/degree_wide_w18.csv")

cat("\n==> Successfully created analytical datasets in data/processed/:\n")
cat(" - degree_trajectories_long.rds (", nrow(degree_long), "ego-waves )\n")
cat(" - degree_analytical_w16.rds (", nrow(analytical_w16), "egos, benchmark N=450 )\n")
cat(" - degree_wide_w16.rds (", nrow(degree_wide_w16), "egos )\n")
cat(" - degree_wide_w18.rds (", nrow(degree_wide_w18), "egos )\n")
