# Implementation Plan: Replacing 3-Class Solution with 4-Class Solution

## Objective
Replace the three-class ($K = 3$) trivariate Latent Class Growth Analysis (LCGA) solution throughout the manuscript (`manuscript.tex`), analytical pipeline (`Scripts/02_fit_bivariate_trajectory_models.R`), figures (`Figure 2`, `Figure 3`), tables (`Table 3`), and cached outputs with the more balanced four-class ($K = 4$) solution.

---

## 1. Substantive & Mathematical Rationale for $K = 4$
- **Model Fit & Information Criteria**: Moving from $K = 3$ to $K = 4$ substantially improves statistical fit, reducing BIC by **814.5 points** (from 39,159.2 to 38,344.7) and AIC by **873.9 points** (from 38,989.4 to 38,115.5).
- **Exceptional Class Balance**: Rather than generating tiny, uninterpretable residual clusters, $K = 4$ produces an exceptionally balanced distribution across the collegiate cohort ($N = 457$ egos):
  1. **Extreme Peripheral Winnowers** ($n = 143, 31.3\%$): Periphery collapses precipitously by 88% to $< 0.5$ alters; core stabilizes at ~3.4 alters.
  2. **Moderate Winnowers / Shell-Oriented** ($n = 124, 27.1\%$): Periphery winnows moderately (to ~2.5 alters); Sympathy Shell (~3.5 alters) overtakes Support Clique (~2.0 alters).
  3. **Expansive Periphery Conservers** ($n = 97, 21.2\%$): Massive, stable personal community (~16–18 alters) sustained across all 8 waves; ~8 casual alters and ~6 active companions.
  4. **Clique Conservers** ($n = 93, 20.4\%$): Exceptionally dense core sustained throughout college (Support Clique ~6.0–7.4 alters, Sympathy Shell ~4.5–6.4 alters).
- **Structural Value**: $K = 4$ untangles two critical developmental dynamics obscured by $K = 3$:
  - Differentiates students who undergo **complete peripheral winnowing** (purging casual contacts down to zero) from **moderate winnowers** who shift their social center of gravity into weekly companions (Sympathy Shell).
  - Purifies true **Expansive Conservers** whose total network volume does not contract at all over four collegiate years.

---

## 2. Decoupled, 4-Faceted Visualization Strategy for Marginal Effects (Figure 3)
To eliminate visual "busyness" and prevent overlapping ribbons/curves from obscuring class contrasts, the marginal effects visualizations will be structured into clean **4-faceted panel strips** (`ncol = 4` sharing consistent class columns):

1. **Panel A: Generalized Trust (4 Facets)**
   - 4 horizontal facets (`facet_wrap(~ Class, ncol = 4)`), one for each trajectory class.
   - X-axis: Standardized Trust ($z \in [-2.5, 2.5]$).
   - Y-axis: Model-implied predicted probability (0%–75%), with clean median line and 95% simulation ribbon.
2. **Panel B: Extraversion (4 Facets)**
   - 4 horizontal facets (`facet_wrap(~ Class, ncol = 4)`), one for each trajectory class.
   - X-axis: Standardized Extraversion ($z \in [-2.5, 2.5]$).
   - Y-axis: Model-implied predicted probability (0%–75%), with clean median line and 95% simulation ribbon.
3. **Panel C: Race and Ethnicity (4 Facets)**
   - 4 horizontal facets (`facet_wrap(~ Class, ncol = 4)`), one for each trajectory class.
   - X-axis: Racial/Ethnic categories (White, Asian, Black, Hispanic, Other/Intl).
   - Y-axis: Adjusted predicted class probability with 95% confidence pointranges.

*Visual Advantage:* Column 1 displays the complete profile of Expansive Conservers; Column 2 displays Moderate Winnowers; Column 3 displays Extreme Winnowers; Column 4 displays Clique Conservers.

---

## 3. Step-by-Step Analytical Pipeline

### Step 1: Update LCGA Script (`Scripts/02_fit_bivariate_trajectory_models.R`)
1. **$K = 4$ Trajectory Estimation & Figure 2**:
   - Estimate `mod_triv4` using `flexmix(..., k = 4, model = triv_specs)`.
   - Calculate ego assignments, class labels, and wave-by-wave empirical means and standard errors for Tier 1 Support Clique, Tier 2 Sympathy Shell, and Tier 3 Periphery.
   - Render and save the 4-panel publication plot to `Plots/fig2_bivariate_lcga_trajectories.png` (and `output/figures/`).
2. **Re-estimate Endogenous Concomitant Models (Table 3)** for $K = 4$:
   - Update `fit_triv_conc()` to estimate with `k = 4` across all 11 model specifications on complete cases ($N = 432$, 2,451 obs):
     - Model 0: Empty Baseline ($K = 4$)
     - Model 1a: Family SES (Parents' Income, Mother's College)
     - Model 1b: Gender Identity
     - Model 1c: Religious Affiliation (Catholic, Other, None)
     - Model 1d: Race/Ethnicity
     - Model 1e: All Sociodemographics
     - Model 2a: Generalized Trust Only
     - Model 2b: Extraversion Only
     - Model 2c: Big Five Personality Traits
     - Model 2d: All Dispositions (Big Five + Trust)
     - Model 3: Full Multivariable Model
   - Compute degrees of freedom, AIC, BIC, LRT $\chi^2$ relative to Model 0, and $p$-values.
   - Serialize updated Table 3 to `cache/table3_bivariate_concomitant_model_comparison.md` and `output/tables/table3_bivariate_concomitant_model_comparison.csv`.
3. **Re-estimate Marginal Effects & Predicted Class Probabilities (Figure 3)** for $K = 4$:
   - Extract the 4-class multinomial coefficients and covariance matrix from the full concomitant model (Model 3 with $K = 4$).
   - Generate 1,000 posterior simulation draws via `MASS::mvrnorm`.
   - Predict model-implied class probabilities with 95% simulation envelopes across Trust, Extraversion, and Race.
   - Implement the split 4-faceted layout for Trust, Extraversion, and Race.
   - Render and save the updated Figure 3 to `Plots/fig3_bivariate_marginal_effects.png` (and `output/figures/`).

### Step 2: Execute Analytical Updates & Verify Artifacts
- Run the estimation script in R to produce all updated numerical outputs, markdown tables, and publication PNGs.
- Inspect the exact LRT statistics, AIC/BIC rankings, and marginal probability trajectories.

### Step 3: Revise LaTeX Manuscript (`manuscript.tex`)
1. **Abstract**:
   - Update the trajectory description from three to four classes, highlighting the balance across the four developmental pathways.
2. **Section 4.1 (Model Selection & Table 2)**:
   - Reframe the model selection narrative: While $K = 2$ and $K = 3$ provide substantial initial elbows, $K = 4$ provides the optimal balance of fit ($\Delta\text{BIC} = -814.5$ over $K = 3$) and substantive differentiation, yielding four well-populated, conceptually distinct archetypes.
3. **Section 4.2 (Trivariate Latent Trajectory Profiles & Figure 2)**:
   - Update Figure 2 caption to $K = 4$.
   - Rewrite the trajectory profile walk-through with exact statistics for the four classes:
     - Expansive Periphery Conservers ($n = 97, 21.2\%$)
     - Moderate Winnowers / Shell-Oriented ($n = 124, 27.1\%$)
     - Extreme Peripheral Winnowers ($n = 143, 31.3\%$)
     - Clique Conservers ($n = 93, 20.4\%$)
4. **Section 5 (Predicting Trajectory Group Membership & Table 3)**:
   - Update the Table 3 LaTeX table with the new $K = 4$ model fit statistics (LL, Par, AIC, BIC, LRT $\chi^2$, $p$-values).
   - Update the text walking through block tests and comparing demographic vs. dispositional predictors.
5. **Section 5.1 (Marginal Predicted Probabilities & Figure 3)**:
   - Update the Figure 3 caption and walk-through text to describe how Generalized Trust, Extraversion, and Race/Ethnicity predict membership across the four classes using the clean 4-faceted panels.
6. **Section 6 (Discussion)**:
   - Update `Summary of Key Results` to walk through the 4-class architecture.
   - Update `Limitations and Suggestions for Future Work` regarding higher-order mixture classes ($K \ge 5$).
   - Update `Implications: The Adaptive Architecture of Personal Communities` to interpret how Dunbar cognitive layers accommodate extreme vs. moderate winnowing and expansive sociality.

### Step 4: Synchronize Documentation & Git Remotes
- Update `draft_manuscript.md` and `AGENTS.md` with the new 4-class asset taxonomy and empirical results.
- Commit all changes with Conventional Commits (`feat: replace 3-class with 4-class trivariate LCGA solution`).
- Push commits to `origin` (GitHub) and `overleaf` Git endpoint.

---

## 4. Verification & Safety Safeguards
- **Zero Local PDF Compilation**: As mandated by project guidelines, do not run `pdflatex` locally; Overleaf handles all PDF compilation.
- **Verification of LaTeX Code**: Ensure clean LaTeX syntax, proper math mode escaping, and valid table formatting.
- **Reproducibility**: Ensure `Scripts/02_fit_bivariate_trajectory_models.R` can run from start to finish with `set.seed(2026)` and generate all assets without errors.
