# Online Appendix: Continuous Multilevel Poisson Growth Curve Models
### Supplementary Materials for "Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks"

# Appendix: Multilevel Growth Models

To verify that the discrete trajectory classes identified by LCGA reflect underlying continuous growth dynamics, we estimate multilevel Generalized Linear Mixed Models (GLMMs) with a Poisson response across all eight waves:
log(E[*D*<sub>it</sub>]) = (β<sub>0</sub> + *u*<sub>0i</sub>) + β<sub>1</sub> Time<sub>it</sub> + **X**<sub>i</sub> **β** + (Time<sub>it</sub> × **Z**<sub>i</sub>) **γ**

where *u*<sub>0i</sub> ∼ *N*(0, σ<sub>u</sub><sup>2</sup>) represents random ego intercepts capturing unobserved between-person heterogeneity, Time<sub>it</sub> ∈ {0, 1, …, 7} denotes elapsed semester centered at Wave 1 baseline, **X**<sub>i</sub> is a vector of baseline sociodemographic and personality main effects, and **Z**<sub>i</sub> captures cross-level interactions between focal personality traits (Extraversion and Neuroticism) and elapsed time.

Table A1 presents the model comparison fit hierarchy (Models 1–4) and the fully specified fixed effects estimates (Model 4).

| Predictor Variable | Estimate (SE) | Incidence Rate Ratio [95% CI] | p-value |
|:---|:---:|:---:|:---:|
| Intercept (Baseline Degree) | 2.53 (0.07) | 12.55 [10.90, 14.44] | < .001 |
| Time (Elapsed Collegiate Waves 0-7) | -0.06 (0.00) | 0.95 [0.94, 0.95] | < .001 |
| Extraversion (z-score) | 0.02 (0.02) | 1.02 [0.97, 1.07] | 0.501 |
| Neuroticism (z-score) | 0.01 (0.03) | 1.01 [0.96, 1.07] | 0.609 |
| Gender Identity: Woman (ref: Man) | 0.01 (0.04) | 1.01 [0.92, 1.10] | 0.836 |
| Race: Asian (ref: White) | -0.28 (0.08) | 0.76 [0.65, 0.88] | < .001 |
| Race: Black (ref: White) | -0.25 (0.09) | 0.78 [0.65, 0.94] | 0.008 |
| Race: Hispanic/Latino (ref: White) | 0.02 (0.07) | 1.02 [0.89, 1.16] | 0.773 |
| Race: Other/International (ref: White) | -0.24 (0.09) | 0.79 [0.66, 0.95] | 0.011 |
| Parents' Income (Ordinal Scale) | 0.01 (0.01) | 1.01 [0.99, 1.03] | 0.325 |
| Agreeableness (z-score) | 0.04 (0.02) | 1.04 [0.99, 1.09] | 0.140 |
| Conscientiousness (z-score) | 0.00 (0.02) | 1.00 [0.96, 1.05] | 0.965 |
| Openness (z-score) | -0.02 (0.02) | 0.98 [0.94, 1.03] | 0.442 |
| Generalized Trust (z-score) | 0.07 (0.02) | 1.07 [1.02, 1.12] | 0.006 |
| Time x Extraversion | -0.01 (0.00) | 0.99 [0.99, 1.00] | 0.032 |
| Time x Neuroticism | 0.00 (0.00) | 1.01 [1.00, 1.01] | 0.101 |

Figure A1 visualizes the predicted degree trajectories across combinations of high versus low Extraversion (±1 SD) and high versus low Neuroticism (±1 SD).

<img src="Plots/figA1_multilevel_predicted_trajectories.png" style="width:6.5in;" />

The continuous growth estimates directly corroborate our primary mixture findings. On average, student ego networks contract by 5.5% per elapsed collegiate wave (IRR=0.945, *p*<0.001). Baseline Generalized Trust exerts a significant positive main effect on network scale (IRR=1.071, *p*=0.006), confirming that trusting students sustain larger personal communities throughout college. Furthermore, the interaction between Time and Extraversion is statistically significant and negative (IRR=0.994, *p*=0.032). As shown in Figure A1, extraverted students enter college with larger initial networks (≈13.4–13.8 alters at Wave 1 vs. ≈12.9–13.3 for introverts) but undergo a faster rate of winnowing, crossing below their introverted peers by senior year (≈8.3–9.2 alters vs. ≈8.8–9.7 alters).

---
