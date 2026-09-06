# Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks (NetHealth)

This project recreates, validates, and substantially expands the empirical research presented by **Matthew J. Chandler and David Hachen** (*"Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks"*, XXXVIII Sunbelt Conference, Utrecht, The Netherlands, June 28, 2018), conducted at the **Interdisciplinary Center for Network Science and Applications (iCeNSA)** at the University of Notre Dame as part of the **NetHealth Project** ([https://sites.nd.edu/nethealth/](https://sites.nd.edu/nethealth/)).

---

## Theoretical Overview & Original Research Design

The study investigates how personal ego network size (degree) changes over time across the college experience, whether students follow distinct, predictable degree trajectories, and the degree to which baseline social demographics and psychological traits (the Big Five personality traits, generalized trust, and birth order) predict these pathways.

### The Original 2018 Design (Chandler & Hachen 2018)
- **Dataset**: First 6 survey waves of the NetHealth study (August 2015 to December 2017), covering the matriculation through junior-year period.
- **Analytical Benchmark Sample ($N = 450$)**:
  - Egos with at least 3 completed ego network surveys across Waves 1–6.
  - Complete initial baseline attributes survey (Wave 1).
- **Dependent Variables (6 Trajectory Classification Schemes)**:
  1. *Deductive 8-Category Scheme*: A priori rule-based classification assigning trajectories to: `Flat`, `Monotonic Increase`, `Monotonic Decrease`, `Zig-Zag`, `Inverted-U Shape`, `U-Shape`, `Upward Trend`, and `Downward Trend`.
  2. *Deductive 4-Category Scheme*: Collapsed into `Flat`, `Mixed` (combining non-linear shapes), `Up`, and `Down`.
  3. *Inductive $k$-Means Clustering (Raw Trajectories)*: $k = 7$ and $k = 9$.
  4. *Inductive $k$-Means Clustering (Zeroed-on-Mean Trajectories)*: Demeaned by each ego's average degree, evaluated at $k = 4$ and $k = 8$.
- **Independent Variables (Wave 1 Baseline)**:
  - *Social Demographics*: Sex (`gender_1`), Race/Ethnicity (`race_1`), SES (Parents' Income, Mother's Education, Father's Education), Citizenship, Primary Language, Religion.
  - *Personality & Personal Attributes*: Big Five Inventory (Agreeableness, Conscientiousness, Extraversion, Neuroticism, Openness), Generalized Trust Scale, Birth Order.
- **Modeling Strategy**:
  - 84 Multinomial Logistic Regression (`mlogit`) models across combinations of Demographics ($n=30$), Personality ($n=18$), and Mixed specifications ($n=36$).
  - Reference category set to the largest/modal class.
- **Key 2018 Findings**:
  - Personality models consistently exhibited superior statistical fit over demographic models.
  - The Big Five traits (especially Extraversion, Neuroticism, and Openness), along with Race and Generalized Trust, had the strongest associations with degree trajectories.
  - Overall predictive accuracy was modest (pseudo-$R^2 \approx 0.02 - 0.08$), indicating that simple demographic categories cannot readily forecast relational trajectories.

---

## Analytical Expansions: Advancing the Science

To move beyond the limitations of heuristic decision trees and rigid Euclidean $k$-means, this revived project introduces three substantive methodological advances:

1. **Latent Class Growth Analysis (LCGA) with Poisson Mixtures (`flexmix`)**:
   - Instead of treating degree as continuous Gaussian variables and imputing missing waves with Euclidean distance, we estimate formal repeated-measures Poisson finite mixture models across $K = 1 \dots 5$ classes.
   - Accurately respects the bounded, non-negative integer count nature of ego degree ($D \in \{0, \dots, 25\}$).
   - BIC and AIC model selection identifies distinct latent trajectory types (*Network Conservers*, *Accelerated Winnowers*, and *Tie Accumulators*).

2. **Multilevel Mixed-Effects Degree Growth Models (`lme4::glmer`)**:
   - Rather than binning continuous histories into arbitrary discrete classes, we model degree growth directly in a multilevel Poisson framework with random ego intercepts:
     $$\log(\mathbb{E}[\text{Degree}_{it}]) = (\beta_0 + u_{0i}) + \beta_1 \text{Time}_t + \mathbf{X}_i \boldsymbol{\beta} + (\text{Personality}_i \times \text{Time}_t) \boldsymbol{\gamma}$$
   - **Empirical Discovery**: Baseline collegiate ego network size contracts by ~7% per survey wave on average ($\text{IRR} = 0.931, p < 0.001$). High baseline generalized trust significantly expands overall network size ($\text{IRR} = 1.065, p = 0.010$). Furthermore, extraverts exhibit a significantly steeper winnowing slope over time ($\text{IRR} = 0.986, p < 0.001$), shedding peripheral ties more rapidly than introverted peers.

3. **Full 8-Wave collegiate Trajectory Decomposition**:
   - Extends the temporal horizon across all 8 waves through senior-year graduation (August 2015 to May 2019).
   - Decomposes total degree into **Close Ties**, **Daily Activated Ties**, and **Support-Providing Ties** (emotional comfort, advice, companionship).
   - **Theoretical Implication**: While total degree contracts from 14.2 to 10.8 alters over college, **daily activated ties** (mean $\approx 5.5$) and **close/supportive ties** (mean $\approx 10.5$) remain remarkably stable, demonstrating that the observed downward trend represents the pruning of superficial, low-investment campus acquaintances rather than core supportive friendships.

---

## Repository Structure

```
├── Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks.pptx  # Original 2018 Sunbelt presentation
├── Social Signatures.pptx                                                           # 2019 follow-up presentation
├── renv.lock                                                                        # Locked reproducible package environment
├── data/
│   ├── raw/                                                                         # Symlinked raw survey microdata (.gitignored)
│   └── processed/                                                                   # Cleaned analytical datasets (.gitignored)
│       ├── degree_analytical_w16.rds                                                # Benchmark analytical cohort (N = 450)
│       ├── degree_analytical_classified.rds                                         # Analytical data with all 6 classification schemes
│       ├── degree_trajectories_long.rds                                             # Long ego-wave observations across college
│       ├── degree_wide_w16.rds                                                      # Wide degree matrix (Waves 1–6)
│       └── degree_wide_w18.rds                                                      # Wide degree matrix (Waves 1–8)
├── scripts/
│   ├── 01_prepare_trajectory_data.R                                                 # Data ingestion, degree aggregation, baseline IV harmonization
│   ├── 02_classify_trajectories.R                                                   # Deductive decision tree & k-means clustering (Figs 1–4)
│   ├── 03_replicate_multinomial_models.R                                            # 84 multinomial logit models & fit benchmarks (Figs 8–11)
│   ├── 04_expansion_latent_class_growth.R                                           # LCGA repeated-measure Poisson mixture models (Fig 5)
│   ├── 05_expansion_multilevel_growth.R                                             # Multilevel Poisson GLMMs & personality moderation (Fig 6)
│   └── 06_expansion_tie_decomposition.R                                             # 8-wave trajectory decomposition by closeness & support (Fig 7)
└── output/
    ├── figures/                                                                     # Publication-ready visualizations (300 DPI PNG)
    │   ├── fig1_8cat_logical_trajectories.png                                       # Deductive 8-category scheme spaghetti plots
    │   ├── fig2_4cat_simplified_trajectories.png                                    # Simplified 4-category scheme spaghetti plots
    │   ├── fig3_kmeans_demeaned_k4.png                                              # k-Means demeaned k=4 cluster trajectories
    │   ├── fig4_kmeans_elbow_curves.png                                             # k-Means WSS elbow curves across k = 1..10
    │   ├── fig5_lcga_optimal_trajectories.png                                       # LCGA latent class Poisson growth profiles
    │   ├── fig6_multilevel_predicted_trajectories.png                               # Multilevel GLMM predicted margins (Personality x Time)
    │   ├── fig7_decomposed_degree_trajectories.png                                  # 8-Wave decomposition: Total vs. Close vs. Daily vs. Support
    │   ├── fig8_chisq_pvalues_by_type.png                                           # Replication of Slide 19 boxplots (Chi-sq p-values)
    │   ├── fig9_pseudo_r2_by_type.png                                               # Replication of Slide 20 boxplots (Pseudo R-squared)
    │   ├── fig10_pseudo_r2_by_type_and_signif.png                                   # Replication of Slide 21 boxplots (R-squared by significance)
    │   └── fig11_variable_significance_rates.png                                    # Replication of Slide 22 barplot (Variable significance rates)
    └── tables/                                                                      # Formatted CSV summary tables
        ├── table1_multinomial_model_results.csv                                     # Fit statistics across all 84 multinomial models
        ├── table2_variable_significance_rates.csv                                   # Variable-level significance proportions (Slide 22)
        ├── table3_lcga_model_selection_fit.csv                                      # LCGA information criteria across K = 1..5
        ├── table4_multilevel_model_fit.csv                                          # GLMM hierarchy model comparison
        ├── table5_multilevel_glmm_estimates.csv                                     # Final Model 4 IRRs, 95% CIs, and p-values
        └── table6_decomposed_trajectory_means.csv                                   # Longitudinal means across Waves 1 to 8
```

---

## Reproducing the Analysis Pipeline

All analyses are managed via `renv`. To execute the complete pipeline sequentially from terminal:

```bash
# 1. Restore the locked package environment
Rscript -e 'renv::restore()'

# 2. Ingest data, build longitudinal degree sequences, and clean baseline covariates
Rscript scripts/01_prepare_trajectory_data.R

# 3. Classify trajectories (deductive rules and k-means) and render cluster figures
Rscript scripts/02_classify_trajectories.R

# 4. Replicate the 84 multinomial logistic regression models and benchmark plots
Rscript scripts/03_replicate_multinomial_models.R

# 5. Run Analytical Expansions
Rscript scripts/04_expansion_latent_class_growth.R
Rscript scripts/05_expansion_multilevel_growth.R
Rscript scripts/06_expansion_tie_decomposition.R
```

---

## Key Results Summary

### 1. Variable Significance Rates in Multinomial Models (Slide 22 Replication)
Across 84 multinomial logistic models predicting the 6 trajectory classification schemes:
- **Race**: Significant in 90.9% of specifications ($p < 0.05$).
- **Religion**: Significant in 58.3% of specifications.
- **Extraversion**: Significant in 56.3% of specifications.
- **Neuroticism**: Significant in 45.2% of specifications.
- **Trust**: Significant in 37.5% of specifications.
- **Openness**: Significant in 33.3% of specifications.
- **SES & Demographics**: Parents' Income (10.0%), Sex (6.1%), Citizenship (0.0%), and Father's Education (0.0%) demonstrated negligible predictive capacity.

### 2. Multilevel GLMM Estimates (Random Intercept Poisson Model)
- **Baseline Shrinkage**: Each elapsed college wave is associated with a 6.9% decrease in expected alter nominations ($\text{IRR} = 0.931, 95\%\text{ CI: } [0.923, 0.938], p < 0.001$).
- **Personality Moderation**: Extraverted students start with higher degree but experience significantly faster rates of network contraction ($\text{Time} \times \text{Extraversion IRR} = 0.986, p < 0.001$).
- **Generalized Trust**: Students with higher baseline trust maintain systematically larger networks throughout college ($\text{IRR} = 1.065, p = 0.010$).

---

## References

- Chandler, M. J., & Hachen, D. (2018). *Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks*. Sunbelt XXXVIII, International Network for Social Network Analysis (INSNA), Utrecht, Netherlands.
- Saramäki, J., Leicht, E. A., López, E., Roberts, S. G., Reed-Tsochas, F., & Dunbar, R. I. (2014). Persistence of social signatures in human communication. *Proceedings of the National Academy of Sciences*, 111(3), 942-947.
- Heydari, S., Roberts, S. G., Dunbar, R. I., & Saramäki, J. (2018). Multichannel social signatures and persistent features of ego networks. *Applied Network Science*, 3(1), 1-18.
