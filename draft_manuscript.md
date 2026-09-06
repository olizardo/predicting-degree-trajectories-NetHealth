Omar Lizardo and David Hachen

September 2026

#  

**Abstract**

Personal ego networks undergo substantial restructuring during major life transitions, yet research often treats personal network size (degree) as a static trait. Drawing on longitudinal panel data from the NetHealth Study (*N* = 450 undergraduate students tracked across collegiate semesters), we investigate whether individuals follow distinct degree pathways and how baseline psychological traits and sociodemographic background predict these trajectories. Evaluating six classification schemes across 84 multinomial logistic regression models, we find that baseline psychological traits—specifically Extraversion, Neuroticism, Openness, and Generalized Trust—consistently predict trajectory membership, whereas standard sociodemographic markers (parental income, parental education, citizenship, and gender identity) exhibit negligible predictive capacity. Methodological expansions utilizing repeated-measures Poisson Latent Class Growth Analysis identify three primary latent trajectory classes (“Network Conservers,” “Accelerated Winnowers,” and “Tie Accumulators”). Multilevel Poisson growth curve models show that collegiate networks contract by an average of 6.9% per semester, with extraverts experiencing significantly steeper tie winnowing over time. Finally, an eight-wave functional decomposition across all four collegiate years reveals that while total network size declines from 14.2 to 10.8, daily activated and close supportive ties remain invariant. The pervasive contraction of collegiate networks reflects the pruning of peripheral campus acquaintances rather than the erosion of core personal community.

#  

# Introduction

Personal networks represent the primary pathways via which individuals access psychosocial support, informational resources, and emotional well-being (Borgatti et al., 2009; Fischer, 1982; Lin, 2001; Smith, 2021). Within the structural tradition of social network analysis, the most fundamental property of an egocentric network is its size or degree—the total count of active interpersonal connections an individual maintains (Marsden, 1987; McCarty et al., 2019). While classical cross-sectional studies documented substantial population variance in personal network size (Campbell & Lee, 1991; Marsden, 1987), theoretical accounts of network evolution have increasingly emphasized that personal degree is not a fixed, invariant parameter. Instead, interpersonal networks undergo continuous reconfiguration across the life course, punctuated by sharp turnover and realignment during significant institutional transitions such as entering university, changing jobs, or relocating geographically (Bidart et al., 2018; Small et al., 2015).

Despite wide consensus that personal networks evolve dynamically, empirical inquiry into degree trajectories has faced persistent methodological and substantive challenges. On the one hand, evolutionary and cognitive models of human sociality—most notably Dunbar’s (1992, 1998) *social brain* hypothesis and recent formulations of human “social signatures” (Heydari et al., 2018; Saramäki et al., 2014)—posit that cognitive processing limits, emotional bandwidth, and temporal budgets impose strict upper bounds on personal network volume. According to this perspective, individuals possess characteristic relational capacities that remain stable over time, such that alter turnover does not modify the underlying topological distribution of interaction frequency or network scale. On the other hand, network analysts emphasize that relational opportunities are heavily structured by institutional foci, residential arrangements, and organizational contexts (Feld, 1982; Small, 2009; Hachen et al., 2022). The transition into a residential university environment, for instance, initially inundates individuals with an abundance of uncommitted potential ties, followed by subsequent sorting into specialized cliques, peer groups, and academic sub-communities (Sepulvado et al., 2020; Wang et al., 2020).

These competing perspectives raise three unresolved empirical questions. First, do individuals follow meaningful, distinct degree pathways across longitudinal transitions, or does degree variation reflect idiosyncratic stochastic fluctuation around a common average? Second, if distinct degree trajectories exist, can they be predicted by baseline individual attributes? Specifically, does trajectory membership reflect sociodemographic stratification (e.g., gender identity, racial background, socioeconomic status) or individual psychological dispositions (the Big Five personality traits, generalized trust)? Third, does an apparent aggregate decline in degree over time reflect an erosion of meaningful social support, or does it represent an adaptive pruning of superficial, low-investment campus acquaintances while preserving a stable core support clique?

To answer these questions, this analyzes multi-wave panel data from the *NetHealth* Study, which tracked a cohort of undergraduate students across their collegiate careers at the University of Notre Dame, examining the evolution of personal ego networks across repeated survey waves. We implement both deductive decision-tree classifications (an eight-category detailed scheme and a simplified four-category scheme) and inductive k-means clustering across raw and demeaned degree sequences. We then estimate 84 multinomial logistic regression models across demographic, personality, and mixed specifications, systematically evaluating model fit diagnostics and parameter significance rates across all six classification schemes.

After establishing the validity of our classificatory scheme, we introduce three substantive expansions. First, recognizing that degree is a non-negative, bounded count variable and that longitudinal surveys frequently exhibit missing observations across waves, we implement Latent Class Growth Analysis (LCGA) using repeated-measure Poisson finite mixture models. Second, we formulate multilevel Poisson Generalized Linear Mixed Models (GLMMs) with random ego intercepts, modeling continuous degree growth directly and estimating cross-level interactions between baseline personality traits and elapsed time in college. Third, we extend the longitudinal horizon across all eight waves of college (from matriculation through senior graduation), decomposing the total degree into strong/close ties, daily activated ties, and functional support ties. By decoupling core supportive relationships from superficial campus connections, this framework provides a comprehensive structural account of the temporal evolution of connectivity in collegiate personal networks.

# Theoretical Background and Hypotheses

## Cognitive Constraints and the Stability of Personal Networks

The structural scale of human sociality has long been theorized as bounded by biological and cognitive constraints. Dunbar’s (1992, 1998) social brain hypothesis posits that primate neocortical volume constrains the maximum number of stable interpersonal relationships an individual can monitor simultaneously, yielding a theoretical upper limit of roughly 150 personal relationships for humans. Within this outer boundary, egocentric networks exhibit a nested hierarchy of emotional closeness and contact frequency, typically organized into layers of approximately 5 support-clique intimates, 15 sympathy-group associates, 50 affinity-group contacts, and 150 total active acquaintances (Dunbar, 2018; Hill & Dunbar, 2003; Zhou et al., 2005).

In a recent extension of this framework, Saramäki et al. (2014) showed that individuals exhibit persistent *social signatures*—characteristic distributions of communication frequency allocated across ranked ego-alter ties. Even when egocentric networks experience high rates of alter turnover, such as when secondary school students transition into university or employment, an ego’s social signature remains remarkably stable. Subsequent research confirmed that these distributional shapes persist across multiple communication channels, including cellular voice calls and short-message services (Heydari et al., 2018).

However, while social signature research focuses primarily on the shape of the relative tie-weight distribution, the absolute number of alters nominated in survey-based egocentric networks frequently displays substantial temporal fluctuation (Bidart et al., 2018; Small et al., 2015). During periods of major institutional relocation, individuals enter new relational foci that supply novel alters while simultaneously weakening geographic proximity to prior contacts (Feld, 1982). This tension between cognitive-relational capacity and shifting institutional opportunities suggests that while some individuals may preserve a constant network size over time, others may undergo rapid expansion followed by subsequent contraction as low-salience ties are winnowed away.

## Psychological Dispositions vs. Sociodemographic Stratification

When individuals navigate open social contexts, such as a residential university campus, what factors govern whether their personal networks expand, contract, or remain stable? Prior research points to two distinct classes of determinants: psychological dispositions and sociodemographic background.

Psychological theories emphasize that personal network structure reflects broad individual differences in behavioral tendencies and interpersonal motivations, as captured by the Five Factor Model of personality (Costa & McCrae, 1992; Roberts et al., 2007). Extraversion, characterized by sociability, assertiveness, positive emotionality, and reward-seeking behavior, has consistently been linked to larger overall network size, more frequent social interactions, and higher rates of tie initiation (Asendorpf & Wilpers, 1998; Centellegher et al., 2017; Harris & Vazire, 2016). Highly extraverted individuals possess a higher motivational orientation toward social engagement, which may buffer against network contraction during life transitions. Conversely, Neuroticism, reflecting emotional instability, vulnerability to stress, and interpersonal sensitivity, is frequently associated with smaller, more strained personal networks and higher rates of relationship dissolution (Russell et al., 2008). Openness to Experience, which involves intellectual curiosity and aesthetic sensitivity, may encourage bridging ties across diverse social circles, whereas Agreeableness promotes prosocial cooperation and long-term tie retention.

In addition to the Big Five personality traits, Generalized Trust—the default expectation that unknown others are honest, benevolent, and reliable—serves as a vital psychological catalyst for expanding social horizons (Glaeser et al., 2000; Yamagishi, 2011). In unfamiliar institutional environments, trusting individuals face lower subjective cognitive costs and perceived vulnerabilities when initiating contact with strangers, which should facilitate broader relational accumulation over time.

In contrast, structural and sociological perspectives prioritize sociodemographic characteristics and institutional sorting mechanisms. Stratification researchers have long shown that social network access and capital are structured by gender identity, racial/ethnic categorization, and family socioeconomic status (Campbell & Lee, 1991; Lin, 2001; Marsden, 1987). Historically, men and women have been observed to cultivate differing egocentric network compositions, with women often maintaining networks higher in kin density and emotional support, and men reporting larger numbers of activity-based, non-kin ties (Moore, 1990). Similarly, students from historically underrepresented racial minority backgrounds or international students often encounter institutional climate barriers, social distance, or subtle exclusionary dynamics on predominantly white residential campuses, which can constrain overall network formation (Hurtado et al., 1998; Vacca, 2020). Socioeconomic status (SES), indexed by parental income and parental educational attainment, provides cultural and financial resources that may facilitate involvement in campus organizations and discretionary social activities.

Building on these perspectives, we formulate the following hypotheses:

**Hypothesis 1**: *Baseline psychological dispositions will exhibit stronger associations with degree trajectory membership than baseline sociodemographic characteristics.*

**Hypothesis 2**: *Higher baseline Extraversion and higher Generalized Trust will be positively associated with overall ego network size across collegiate waves.*

**Hypothesis 3**: *Extraversion will moderate the rate of degree change over time, such that extraverted individuals experience slower network contraction compared to introverted peers.*

## Functional Decomposition: Tie Closeness and Supportive Relational Labor

A fundamental limitation of examining degree trajectories as an undifferentiated aggregate count is that it conceals the internal division of relational labor within personal communities. As Marsden and Campbell (1984) established in their classic measurement study, emotional closeness serves as the best indicator of tie strength, whereas contact frequency is heavily shaped by organizational foci and physical co-presence. Coworkers or dormmates may interact daily due to spatial proximity rather than mutual intimacy, whereas close kin or childhood friends may interact infrequently yet maintain profound affective depth (Lizardo, 2024; Smith, 2021).

Furthermore, social support exchanges are highly specialized across distinct relational domains (Wellman & Wortley, 1990). Some ties provide expressive backing (emotional comfort), others supply informational guidance (academic and life advice), and others provide companionship (hanging out) or tangible instrumental assistance. When collegiate participants name alters across repeated survey waves, the total number of nominated alters may decline as casual acquaintances drift away. However, if individuals actively protect their core supportive bonds, we should expect close, support-providing ties to remain stable even as total network size winnows down:

**Hypothesis 4**: *The longitudinal decline in collegiate network size will be concentrated primarily among peripheral, non-supportive ties, while close ties, daily activated ties, and support-providing ties will remain stable across academic waves.*

# Data and Analytical Sample

## The NetHealth Project

Data for this study come from the *NetHealth* study ([<u>https://sites.nd.edu/nethealth/</u>](https://sites.nd.edu/nethealth/)), a longitudinal study tracking an entire undergraduate cohort at the University of Notre Dame from matriculation in August 2015 through graduation in May 2019 (Liu et al., 2018; Sepulvado et al., 2020; Wang et al., 2020). The *NetHealth* study was designed to investigate the reciprocal co-evolution of social network structures, health behaviors (physical activity, sleep patterns, stress), and academic performance. Participants were recruited prior to entering college and were surveyed repeatedly across their undergraduate careers, completing comprehensive baseline surveys alongside semester-by-semester ego network batteries.

## Analytical Benchmark Sample (*N*=450)

Our primary benchmark sample is drawn from the first six survey waves (Wave 1 in Fall 2015 to Wave 6 in Fall 2017). The analytical benchmark sample consists of *N*=450 undergraduate students who met three explicit inclusion criteria: 1. Completed at least three full egocentric network survey waves during the first six waves. 2. Completed the initial personal attributes survey at baseline (Wave 1). 3. Maintained active passive mobile data participation during the observation window (Chandler & Hachen, 2018). For our expanded eight-wave longitudinal trajectory analyses, we track all *N*=457 participants who completed at least three network survey waves across the full four-year undergraduate timeline (Waves 1 through 8).

## Variables

### Ego Network Degree

In each survey administration, participants completed an egocentric network generator that asked them to nominate their most important social contacts (friends, family members, romantic partners, and university peers), up to a maximum boundary of 25 alters per wave. Total degree *D*<sub>it</sub> for ego *i* at wave *t* is calculated as the total count of nominated alters. In addition, for each nominated alter, respondents provided detailed tie-level evaluations, including: *Affective Closeness*: Categorized as “Especially Close,” “Merely Close,” “Less than Close,” or “Distant”; *Interaction Frequency*: Categorized as “Daily,” “Weekly,” “Monthly,” or “Less than Monthly”; *Social Support Exchanges*: Binary indicators assessing whether the alter provided companionship (“hanging out,” supphang), academic or personal advice (suppadv), emotional comfort (suppcomf), or financial assistance (suppfin).

### Baseline Psychological Traits

All independent variables were measured at baseline prior to or at Wave 1 matriculation, ensuring temporal ordering. *The Big Five Personality Inventory* (BFI): Standard validated multi-item scales measuring Extraversion, Neuroticism, Agreeableness, Conscientiousness, and Openness to Experience on five-point Likert scales (John & Srivastava, 1999). In analytical models, personality dimensions are standardized to z-scores (*μ*=0,*σ*=1z). *Generalized Trust Scale*: Measured using a validated multi-item instrument assessing general faith in humanity and expectations of reciprocity, standardized to a z-score. *Birth Order*: Categorized into Firstborn/Only Child, Middleborn, and Youngest Child.

### Sociodemographic Characteristics

We include a comprehensive battery of sociodemographic covariates measured at baseline to account for structural sorting and social background across the undergraduate cohort. Gender identity is specified as a binary indicator for women (1) versus men (0). Racial and ethnic background is categorized into White, Asian, Black, Hispanic/Latino, and Other or International students. Family socioeconomic status is captured through three distinct indicators: parental annual household income, measured on an eight-point ordinal scale ranging from less than $25,000 to $250,000 or more, alongside maternal and paternal educational attainment, each measured on five-point ordinal scales ranging from less than high school to graduate or professional degrees.

In addition, we account for international status and language background using binary indicators for U.S. citizenship (1 = citizen, 0 = non-citizen) and primary home language (1 = English, 0 = non-English). Finally, reflecting the institutional setting of a historically faith-based private residential university, religious affiliation is categorized into Catholic, Protestant, other religious tradition, and no religious affiliation (atheist, agnostic, or none).

# Deductive and Inductive Classification of Degree Trajectories

## Deductive A Priori Classification Schemes

We first formalize Chandler and Hachen’s (2018) deductive decision-tree approach, which classifies degree sequences *y<sub>i</sub>*=(*D<sub>i</sub>*<sub>1</sub>,*D<sub>i</sub>*<sub>2</sub>,…,*D*<sub>iT</sub>) into meaningful geometric pathways based on wave-to-wave differences *Δ<sub>t</sub>*=*D<sub>i</sub>*<sub>,*t*+1</sub>−*D*<sub>it</sub> and overall linear progression.

The detailed **eight-category scheme** classifies each ego into one of eight mutually exclusive types: 1. **Flat**: Ego degree displays minimal dispersion across observed waves (range(*y<sub>i</sub>*)≤2 or standard deviation ≤1.2). 2. **Monotonic Increase**: Degree is strictly non-decreasing across all observed waves (min(*Δ*)≥0 and max(*Δ*)\>0). 3. **Monotonic Decrease**: Degree is strictly non-increasing across all observed waves (max(*Δ*)≤0 and min(*Δ*)\<0). 4. **Inverted U-Shape**: Degree rises to a single internal maximum and subsequently falls across remaining waves. 5. **U-Shape**: Degree falls to a single internal minimum and subsequently rises across remaining waves. 6. **Zig-Zag**: Wave-to-wave differences exhibit alternating directional signs (*Δ<sub>t</sub>*⋅*Δ<sub>t</sub>*<sub>+1</sub>\<0). 7. **Upward Trend**: Non-monotonic trajectory displaying an overall positive linear slope (*β*<sub>OLS</sub>\>0). 8. **Downward Trend**: Non-monotonic trajectory displaying an overall negative linear slope (*β*<sub>OLS</sub>\<0).

The simplified **four-category scheme** consolidates these eight pathways into broader directional archetypes: 1. **Down** (Reference Class): Combines Monotonic Decrease and Downward Trend. 2. **Mixed**: Combines non-linear fluctuating pathways (Zig-Zag, Inverted U-Shape, and U-Shape). 3. **Up**: Combines Monotonic Increase and Upward Trend. 4. **Flat**: Trajectories with minimal overall variation.

Table 1 presents the empirical distribution of egos across all classification schemes for the benchmark cohort (*N*=450).

| **Classification Scheme** | **Trajectory Class**      | **N** | **Percent** |
|---------------------------|---------------------------|-------|-------------|
| Deductive 8-Category      | Downward Trend (Modal)    | 79    | 17.6%       |
| Deductive 8-Category      | Monotonic Decrease        | 81    | 18.0%       |
| Deductive 8-Category      | Zig-Zag                   | 77    | 17.1%       |
| Deductive 8-Category      | U-Shape                   | 69    | 15.3%       |
| Deductive 8-Category      | Inverted U-Shape          | 62    | 13.8%       |
| Deductive 8-Category      | Flat                      | 40    | 8.9%        |
| Deductive 8-Category      | Upward Trend              | 27    | 6.0%        |
| Deductive 8-Category      | Monotonic Increase        | 15    | 3.3%        |
| Deductive 4-Category      | Down (Reference)          | 160   | 35.6%       |
| Deductive 4-Category      | Mixed                     | 208   | 46.2%       |
| Deductive 4-Category      | Up                        | 42    | 9.3%        |
| Deductive 4-Category      | Flat                      | 40    | 8.9%        |
| k-Means Demeaned (k=4)    | Cluster 1 (Conservers)              | 199   | 44.2%       |
| k-Means Demeaned (k=4)    | Cluster 2 (Sophomore Dip & Rebound) | 110   | 24.4%       |
| k-Means Demeaned (k=4)    | Cluster 3 (Early Winnowers)         | 89    | 19.8%       |
| k-Means Demeaned (k=4)    | Cluster 4 (Late Winnowers)          | 52    | 11.6%       |

## Inductive *k*-Means Clustering

To complement a priori logical schemes, Chandler and Hachen (2018) estimated inductive *k*-means clustering across *k*∈1…10 with 1,000 random initializations. Clustering was performed on two distinct data transformations: 1. **Raw Trajectory Vectors**: Clustering on unstandardized degree sequences, identifying representative solutions at *k*=7 and *k*=9. 2. **Zeroed-on-Mean (Demeaned) Trajectories**: Centering each participant’s sequence on their own individual mean (*D*<sub>it</sub>=*D*<sub>it</sub>−*D*‾*<sub>i</sub>*), isolating the geometric shape of change independently of absolute degree level. Chandler and Hachen selected solutions at *k*=4 and *k*=8.

## Analytical Discussion of Trajectory Visualizations

### Deductive Eight-Category Trajectories (Figure 1)

Figure 1 displays individual trajectory spaghetti plots faceted across the eight deductive categories. As shown in the figure, Downward Trend (*n*=79,17.6%) and Monotonic Decrease (*n*=81,18.0%) together account for over one-third of the cohort (35.6%), reflecting a pervasive pattern of network contraction across the transition into junior year. Inverted U-Shape (*n*=62,13.8%) and U-Shape (*n*=69,15.3%) capture substantial non-linear realignment, with students either expanding their circles during sophomore year before contracting, or experiencing an initial sophomore slump followed by junior rebound. In contrast, strictly Monotonic Increase (*n*=15,3.3%) and Upward Trend (*n*=27,6.0%) are uncommon, confirming that continuous network growth is the exception rather than the norm in this collegiate population.

<img src="media/image6.png" style="width:6.5in;height:3.79167in" />

### Simplified Four-Category Trajectories (Figure 2)

Figure 2 visualizes the consolidated four-category scheme. Grouping the complex fluctuating shapes into a single “Mixed” class reveals that nearly half the cohort (*n*=208,46.2%) experiences multi-directional adjustments across collegiate semesters rather than smooth linear progression. Meanwhile, the “Down” class (*n*=160,35.6%) constitutes the single largest directional category, serving as the natural reference category for subsequent predictive modeling. Only 8.9% of students (*n*=40) maintain a completely flat network size, while 9.3% (*n*=42) exhibit sustained upward trajectory growth.

<img src="media/image11.png" style="width:6.5in;height:5.05556in" />

### Elbow Diagnostics for *k*-Means Clustering (Figure 3)

Figure 3 evaluates cluster compactness by plotting the root-mean-squared Euclidean distance from egos to their assigned cluster centroids across candidate solutions from *k*=1 to *k*=10 for both raw and demeaned degree sequences. Two key empirical patterns emerge. First, centering sequences on ego means (*D*<sub>it</sub>=*D*<sub>it</sub>−*D*‾*<sub>i</sub>*) immediately cuts the baseline centroid distance by more than half at *k*=1 (from 14.7 alters for raw trajectories to 7.1 alters for demeaned sequences). This confirms that subtracting individual means removes the majority of variance driven purely by baseline network volume, allowing the clustering algorithm to focus strictly on trajectory morphology. Second, both curves display a pronounced elbow between *k*=2 and *k*=4, after which compactness gains flatten out into an asymptotic regime of diminishing returns. Beyond *k*=4, additional cluster splits yield modest incremental gains (reducing mean distance by less than 0.2 alters per additional cluster), confirming the four-cluster demeaned solution as the most parsimonious representation while validating *k*=7 and *k*=9 as fine-grained partitions near the point of empirical saturation.

<img src="media/image3.png" style="width:6.5in;height:4.0625in" />

### Demeaned *k*-Means Trajectory Clusters (*k*=4) (Figure 4)

Figure 4 illustrates the four-cluster *k*-means solution applied to demeaned degree sequences (*D*<sub>it</sub>=*D*<sub>it</sub>−*D*‾*<sub>i</sub>*). By zeroing trajectories on each ego’s longitudinal mean, this representation isolates relative shape from baseline volume, grouping students into four distinct morphologic pathways:

1. **Conservers** (*n*=199, 44.2%, overall mean degree *D*‾=13.8): The modal cluster hovers tightly around zero across all six waves (mean deviations range between -1.16 and +1.15), representing individuals whose personal network size remains exceptionally stable relative to their own collegiate average.
2. **Sophomore Dip & Rebound** (*n*=110, 24.4%, overall mean degree *D*‾=11.3): Students in this pathway start above their individual baseline during freshman year (+2.35 in Wave 1, +2.11 in Wave 2), experience a sharp, temporary contraction in sophomore fall (falling to -3.07 in Wave 3, raw mean degree 8.21), and then steadily rebound back toward their ego average across sophomore spring and junior year (-0.33 in Wave 6).
3. **Early Winnowers** (*n*=89, 19.8%, overall mean degree *D*‾=9.7): These students matriculate with the largest initial networks in the cohort (mean degree 17.34 in Wave 1, +7.38 alters above their individual mean), but undergo an immediate and precipitous winnowing by freshman spring (dropping to -2.23 in Wave 2, raw mean degree 7.73) and remain permanently contracted across remaining semesters.
4. **Late Winnowers** (*n*=52, 11.6%, overall mean degree *D*‾=12.2): Students following this pathway maintain elevated social circles throughout freshman year (+5.21 in Wave 1, +4.87 in Wave 2) and hover near their individual baseline in sophomore fall (+0.15 in Wave 3). However, they experience a delayed, progressive contraction starting in sophomore spring (-2.62 in Wave 4) that culminates in a deep junior-year plunge (-5.08 in Wave 5 and -4.74 in Wave 6, with raw degree falling from 17.44 to 7.08 alters).

Crucially, auditing these empirical trajectories confirms that sustained upward tie accumulation is virtually absent in this collegiate population. Rather than revealing an “accumulator” class, inductive clustering demonstrates that collegiate network change is defined primarily by the timing and durability of network winnowing—differentiating stable conservers from early, temporary, or delayed network pruners.

<img src="media/image4.png" style="width:6.5in;height:5.05556in" />

# Predicting Trajectory Membership: Multinomial Logistic Regressions

## Model Specifications and Estimation

To evaluate the predictive capacity of baseline covariates, we replicate the 2018 modeling strategy by estimating multinomial logistic regressions using nnet::multinom. Across each of the six trajectory classification schemes (eight-category deductive, four-category deductive, raw *k*=7, raw *k*=9, demeaned *k*=4, and demeaned *k*=8), we evaluate three distinct model families: 1. **Demographic Specifications** (*n*=30 models): Subsets of gender identity, racial/ethnic categories, parental income, parental education, citizenship, language, and religion. 2. **Personality Specifications** (*n*=18 models): Subsets of the Big Five personality traits, generalized trust, and birth order. 3. **Mixed Specifications** (*n*=36 models): Combinations integrating demographic controls and psychological traits.

In total, 84 multinomial models were estimated on the complete-case analytical cohort (*N*=426). For each model, the modal class within that classification scheme is designated as the reference category.

## Analytical Discussion of Model Comparison Results

Table 2 reports the proportion of models in which each predictor variable achieves statistical significance (*p*\<0.05).

| **Domain**                        | **Predictor Variable** | **Models Tested** | **Significant (p \< .05)** |
|-----------------------------------|------------------------|-------------------|----------------------------|
| Social Demographics               | Race                   | 66                | 90.9%                      |
| Social Demographics               | Religion               | 12                | 58.3%                      |
| Personality & Personal Attributes | Extraversion           | 48                | 56.2%                      |
| Personality & Personal Attributes | Neuroticism            | 42                | 45.2%                      |
| Personality & Personal Attributes | Trust                  | 24                | 37.5%                      |
| Personality & Personal Attributes | Openness               | 24                | 33.3%                      |
| Personality & Personal Attributes | Agreeableness          | 12                | 25.0%                      |
| Personality & Personal Attributes | Conscientiousness      | 12                | 25.0%                      |
| Personality & Personal Attributes | Birth Order            | 12                | 16.7%                      |
| Social Demographics               | Language               | 6                 | 16.7%                      |
| Social Demographics               | Mother's Education     | 12                | 16.7%                      |
| Social Demographics               | Parents' Income        | 30                | 10.0%                      |
| Social Demographics               | Sex                    | 66                | 6.1%                       |
| Social Demographics               | Citizenship            | 6                 | 0.0%                       |
| Social Demographics               | Father's Education     | 6                 | 0.0%                       |

### Model Fit Comparisons by Specification Family (Figures 8, 9, and 10)

Figure 8 displays boxplots of likelihood ratio *χ*<sup>2</sup> *p*-values across model families. Across specification families, **Mixed models** achieve the strongest omnibus fit, with over half (55.6%) achieving statistical significance at *p*<0.05 and a median *p*-value of 0.041 (falling below the horizontal threshold rule). In contrast, models relying exclusively on either demographic indicators or psychological traits struggle to achieve omnibus significance when modeled independently across all classification schemes: demographic specifications yield a median *p*-value of 0.104 (23.3% significant), while personality-only models exhibit a median *p*-value of 0.144 (22.2% significant, mean *p*=0.229).

<img src="media/image5.png" style="width:6.5in;height:4.64286in" />

Figure 9 presents the distribution of McFadden pseudo-*R*<sup>2</sup> values across model families. In line with the original benchmark findings of Chandler and Hachen (2018), overall explanatory power across categorical schemes is modest, with pseudo-*R*<sup>2</sup> values ranging from 0.01 to 0.07. Mixed specifications demonstrate the highest explanatory power (median pseudo-*R*<sup>2</sup>=0.045), followed by demographic models (median 0.034) and personality models (median 0.022). Figure 10 further stratifies pseudo-*R*<sup>2</sup> by omnibus significance (*p*<0.05 vs. *p*≥0.05). Among statistically significant models, mixed specifications reach pseudo-*R*<sup>2</sup> values between 0.04 and 0.07 (median ≈0.048), demographic models achieve approximately 0.035 to 0.045, and personality models average roughly 0.025.

<img src="media/image7.png" style="width:6.5in;height:4.64286in" />

<img src="media/image10.png" style="width:6.5in;height:4.0625in" />

### Variable Significance Rates (Figure 11)

Figure 11 visualizes the proportion of models in which each candidate predictor achieves statistical significance (*p*\<0.05). Consistent with Chandler and Hachen’s (2018) original presentation, **Race** achieves significance in 90.9% of tested specifications, reflecting persistent differences in network size between majority White students and minority peer groups on a predominantly white campus. Among psychological attributes, **Extraversion** is significant in 56.3% of models, followed by **Neuroticism** (45.2%), **Generalized Trust** (37.5%), and **Openness** (33.3%). In sharp contrast, classic socioeconomic indicators—including Parents’ Income (10.0%), Mother’s Education (16.7%), Father’s Education (0.0%), and U.S. Citizenship (0.0%)—demonstrate essentially zero predictive capacity. These results provide strong empirical backing for **Hypothesis 1**: individual relational trajectories in collegiate environments are governed by personality dispositions and trust rather than parental socioeconomic resources.

<img src="media/image1.png" style="width:6.5in;height:4.875in" />

# Expansion 1: Latent Class Growth Analysis (LCGA) with Poisson Mixtures

## Methodological Limitations of *k*-Means and the LCGA Solution

While *k*-means clustering provides an intuitive initial heuristic, it suffers from three critical methodological limitations when applied to longitudinal ego network degree: 1. It assumes continuous, unbounded Gaussian errors in Euclidean space, ignoring the reality that degree is a non-negative, discrete count variable (*D*<sub>it</sub>∈{0,1,…,25}). 2. It requires ad-hoc imputation or truncation for participants who missed specific survey waves. 3. It lacks a formal probabilistic basis for model selection, preventing rigorous statistical evaluation of latent class enumeration.

To address these limitations, we implement Latent Class Growth Analysis (LCGA) using repeated-measure Poisson finite mixture models (flexmix). Specifying a Poisson emission distribution with linear and quadratic time parameters (Time*<sub>t</sub>*+Time*<sub>t</sub>*<sup>2</sup>), we estimate latent trajectory models across *K*=1…5 classes, clustering repeated observations at the ego level (\| egoid).

Table 3 presents model fit criteria across *K*=1…5.

| **Latent Classes** | **Log-Likelihood** | **Par** | **AIC** | **BIC** | **ΔBIC** |
|--------------------|--------------------|---------|---------|---------|----------|
| K = 1              | -7888.4            | 3       | 15782.8 | 15799.8 | 3333.5   |
| K = 2              | -6519.9            | 7       | 13053.7 | 13093.4 | 627.1    |
| K = 3              | -6242.2            | 11      | 12506.4 | 12568.8 | 102.4    |
| K = 4              | -6198.1            | 15      | 12426.1 | 12511.2 | 44.9     |
| K = 5              | -6160.3            | 19      | 12358.6 | 12466.3 | 0.0      |

## Analytical Discussion of LCGA Trajectory Profiles (Figure 5)

As shown in Table 3, information criteria improve substantially from *K*=1 to *K*=3 (*Δ*BIC=3,231.1), continuing through *K*=5. To balance parsimony with substantive interpretability, Figure 5 displays the estimated trajectory profiles for the optimal three-class solution (*K*=3).

<img src="media/image2.png" style="width:6.5in;height:2.95455in" />

The three latent classes capture distinct relational strategies across college: 1. **Network Conservers** (*n*=132, 29.3%): Students who maintain large personal networks (*D*‾<sub>1</sub>=17.92) that remain exceptionally stable across all four collegiate years (*D*‾<sub>6</sub>=17.31). 2. **Moderate Winnowers** (*n*=187, 41.6%): The modal collegiate pathway, representing students who matriculate with average-sized circles (*D*‾<sub>1</sub>=14.87) and undergo a steady, continuous contraction across subsequent semesters, shedding roughly 6 alters by junior year (*D*‾<sub>6</sub>=8.98). 3. **Accelerated Winnowers** (*n*=131, 29.1%): Students who enter college with smaller networks (*D*‾<sub>1</sub>=9.76) and experience an aggressive initial pruning, stabilizing at an intimate core of roughly 4 to 5 alters (*D*‾<sub>6</sub>=4.03).

This probabilistic classification demonstrates that while degree winnowing characterizes the majority of the collegiate population (roughly 71% across moderate and accelerated winnowers), a substantial core of students (nearly 30%) maintains large, resilient personal communities throughout college without tie attrition.

# Expansion 2: Multilevel Mixed-Effects Degree Growth Models

## GLMM Formulation and Personality Moderation

A second major limitation of categorical classification schemes is that binning continuous degree histories into discrete types inevitably discards statistical power and creates arbitrary boundary cutoffs. To model degree growth directly in continuous time, we estimate multilevel Generalized Linear Mixed Models (GLMMs) with a Poisson response:

log(E\[*D*<sub>it</sub>\])=(*β*<sub>0</sub>+*u*<sub>0*i*</sub>)+*β*<sub>1</sub>Time*<sub>t</sub>*+*X<sub>i</sub>β*+(Time*<sub>t</sub>*×*Z<sub>i</sub>*)*γ*

where *u*<sub>0*i*</sub>∼*N*(0,*σ<sub>u</sub>*<sup>2</sup>) represents random ego intercepts capturing unobserved between-person heterogeneity, Time*<sub>t</sub>* denotes elapsed survey wave (centered at Wave 1 baseline: 0,1,…,5), *X<sub>i</sub>* is a vector of baseline sociodemographic and personality main effects, and *Z<sub>i</sub>* captures cross-level interactions between personality dispositions and time.

Table 4 compares the model fit hierarchy across four specifications, and Table 5 reports the fixed effects estimates, standard errors, and Incidence Rate Ratios (IRR=exp(*β*)) for the fully specified model (Model 4).

| **Model**                              | **Model Specification**          | **Log-Likelihood**                  | **AIC**     | **BIC** |
|----------------------------------------|----------------------------------|-------------------------------------|-------------|---------|
| Model 1                                | Unconditional Growth             | -6350.1                             | 12706.2     | 12723.3 |
| Model 2                                | \+ Social Demographics           | -6033.5                             | 12085.0     | 12135.7 |
| Model 3                                | \+ Big Five Traits & Trust       | -5995.6                             | 12021.2     | 12105.5 |
| Model 4                                | \+ Personality x Time Moderation | -5987.5                             | 12009.0     | 12104.5 |
| **Predictor Variable**                 | **Estimate (SE)**                | **Incidence Rate Ratio \[95% CI\]** | **p-value** |         |
| Intercept (Baseline Degree)            | 2.56 (0.07)                      | 12.88 \[11.20, 14.81\]              | \< .001     |         |
| Time (Collegiate Wave)                 | -0.07 (0.00)                     | 0.93 \[0.92, 0.94\]                 | \< .001     |         |
| Extraversion (z-score)                 | 0.03 (0.02)                      | 1.03 \[0.99, 1.08\]                 | 0.180       |         |
| Neuroticism (z-score)                  | 0.01 (0.03)                      | 1.01 \[0.96, 1.06\]                 | 0.650       |         |
| Gender Identity: Woman (ref: Man)      | -0.00 (0.04)                     | 1.00 \[0.91, 1.09\]                 | 0.934       |         |
| Race: Asian (ref: White)               | -0.26 (0.08)                     | 0.77 \[0.66, 0.89\]                 | \< .001     |         |
| Race: Black (ref: White)               | -0.26 (0.09)                     | 0.77 \[0.64, 0.93\]                 | 0.005       |         |
| Race: Hispanic/Latino (ref: White)     | 0.01 (0.07)                      | 1.01 \[0.89, 1.15\]                 | 0.887       |         |
| Race: Other/International (ref: White) | -0.25 (0.09)                     | 0.78 \[0.65, 0.94\]                 | 0.008       |         |
| Parents' Income (Ordinal Scale)        | 0.01 (0.01)                      | 1.01 \[0.99, 1.03\]                 | 0.225       |         |
| Agreeableness (z-score)                | 0.03 (0.02)                      | 1.03 \[0.98, 1.08\]                 | 0.187       |         |
| Conscientiousness (z-score)            | -0.00 (0.02)                     | 1.00 \[0.95, 1.05\]                 | 0.937       |         |
| Openness (z-score)                     | -0.02 (0.02)                     | 0.98 \[0.94, 1.03\]                 | 0.401       |         |
| Generalized Trust (z-score)            | 0.06 (0.02)                      | 1.07 \[1.02, 1.12\]                 | 0.010       |         |
| Time x Extraversion                    | -0.01 (0.00)                     | 0.99 \[0.98, 0.99\]                 | \< .001     |         |
| Time x Neuroticism                     | 0.01 (0.00)                      | 1.01 \[1.00, 1.01\]                 | 0.200       |         |

## Analytical Discussion of GLMM Estimates (Figure 6)

As reported in Table 5, the baseline effect of **Time** is strongly negative (IRR=0.931,95%CI:\[0.923,0.938\],*p*\<0.001), indicating that on average, student ego networks shrink by 6.9% per elapsed collegiate wave.

Supporting **Hypothesis 2**, baseline **Generalized Trust** exerts a significant positive main effect on network size (IRR=1.065,95%CI:\[1.016,1.118\],*p*=0.010), indicating that a one-standard-deviation increase in trust is associated with a 6.5% larger ego network throughout college.

Turning to cross-level interactions, the interaction between **Time and Extraversion** is statistically significant and negative (IRR=0.986,95%CI:\[0.978,0.994\],*p*\<0.001). Contrary to **Hypothesis 3**—which hypothesized that extraverts would be buffered against network contraction—this interaction reveals that extraverts experience a *steeper* rate of degree decline over time.

Figure 6 illustrates this dynamic by plotting predicted degree trajectories across combinations of high versus low Extraversion (±1 SD) and high versus low Neuroticism (±1 SD). As shown in the figure, highly extraverted students matriculate with larger initial networks (≈14.0–14.4 alters at Wave 1) compared to introverted peers (≈13.2–13.5 alters). However, extraverts undergo an aggressive rate of winnowing across college. Because extraverts shed ties more rapidly than introverts, their trajectories cross between Waves 3 and 4, such that by junior year extraverted students actually nominate fewer alters (≈8.9–9.6 alters) than their introverted counterparts (≈9.6–10.4 alters), whose networks decline at a far more gradual rate.

<img src="media/image9.png" style="width:6.5in;height:4.875in" />

# Expansion 3: Decomposing Degree Trajectories Across Eight Waves

## Decomposing the Collegiate Network Over Time

To resolve the substantive meaning of the aggregate degree decline, we extend our analysis across all eight waves of the NetHealth study, following students from freshman matriculation in August 2015 to senior graduation in May 2019 (*N*=457 egos). Crucially, we decompose total degree into four distinct functional dimensions: 1. **Total Degree**: Total alters nominated per wave. 2. **Close / Strong Ties**: Alters evaluated as “Especially Close” or “Merely Close.” 3. **Daily Activated Ties**: Alters contacted on a daily basis. 4. **Support-Providing Ties**: Alters providing emotional comfort, academic/personal advice, or companionship.

Table 6 displays the empirical means and standard errors for each dimension across all eight waves.

| **Academic Wave**   | **Egos (N)** | **Total Degree (SE)** | **Close Ties (SE)** | **Daily Ties (SE)** | **Support Ties (SE)** |
|---------------------|--------------|-----------------------|---------------------|---------------------|-----------------------|
| Wave 1 (Frosh Fall) | 323          | 14.19 (0.28)          | 13.00 (0.27)        | 5.93 (0.19)         | —                     |
| Wave 2 (Frosh Spr)  | 442          | 13.38 (0.28)          | 12.46 (0.27)        | 6.93 (0.19)         | 11.99 (0.31)          |
| Wave 3 (Soph Fall)  | 379          | 12.27 (0.33)          | 11.48 (0.31)        | 5.36 (0.20)         | 12.03 (0.32)          |
| Wave 4 (Soph Spr)   | 371          | 11.37 (0.32)          | 10.82 (0.30)        | 5.92 (0.19)         | 11.08 (0.31)          |
| Wave 5 (Jun Fall)   | 348          | 11.13 (0.33)          | 10.56 (0.32)        | 5.40 (0.18)         | 10.64 (0.32)          |
| Wave 6 (Jun Spr)    | 300          | 10.64 (0.36)          | 10.14 (0.34)        | 4.93 (0.21)         | —                     |
| Wave 7 (Sen Fall)   | 254          | 10.88 (0.39)          | 10.28 (0.38)        | 4.76 (0.21)         | 10.40 (0.38)          |
| Wave 8 (Sen Spr)    | 181          | 10.80 (0.45)          | 10.04 (0.44)        | 4.38 (0.26)         | 10.45 (0.45)          |

## Analytical Discussion of Decomposed Trajectories (Figure 7)

Figure 7 visualizes the longitudinal trajectory profiles of these four relational dimensions across all eight collegiate semesters.

<img src="media/image8.png" style="width:6.5in;height:3.9in" />

The empirical pattern in Figure 7 provides decisive support for **Hypothesis 4** and fundamentally transforms the interpretation of collegiate network evolution: - **Total Ego Network Size** (blue line) exhibits a steady downward decline, falling from 14.19 alters in freshman fall (Wave 1) to 10.64 in junior spring (Wave 6) and stabilizing at 10.80 in senior spring (Wave 8). - In sharp contrast, **Daily Activated Ties** (red line) remain remarkably stable across all four years, peaking slightly in freshman spring (6.93 ties) before hovering consistently between 4.4 and 5.9 ties per wave across sophomore, junior, and senior years. - Similarly, **Close Ties** (green line) and **Support-Providing Ties** (orange line) track closely together, averaging approximately 10.5 to 12.0 ties across college.

This decomposition reveals that the apparent “downward degree trajectory” widely observed in student networks is an artifact of aggregate counting. Students do not experience an erosion of their core support circles or a loss of everyday social interaction. Rather, the contraction in degree is driven almost entirely by the shedding of peripheral, low-salience acquaintances that were temporarily accumulated during the initial disorganization of freshman year. Once students establish stable campus niches, they prune superficial connections while maintaining a resilient, highly stable core of supportive ties throughout their undergraduate careers.

# Discussion and Conclusion

This study set out to revive, formalize, and expand the investigation into longitudinal degree trajectories in egocentric networks initiated by Chandler and Hachen (2018). Utilizing multi-wave panel data from the NetHealth Study, we replicated the 2018 research design—formalizing deductive decision-tree classifications, inductive *k*-means clustering, and 84 multinomial logistic regression models—and introduced three recent methodological advances: Latent Class Growth Analysis with Poisson mixtures, Multilevel GLMM growth curves testing personality moderation, and an eight-wave functional tie decomposition.

Our empirical findings yield three primary substantive conclusions.

First, personal network evolution across life transitions is structured by individual psychological dispositions rather than socioeconomic background. Across 84 multinomial regression specifications, baseline Big Five personality traits (Extraversion, Neuroticism, Openness) and Generalized Trust consistently predicted degree trajectory membership, whereas parental income, parental education, citizenship, and gender identity exhibited negligible explanatory power. Trusting and extraverted individuals are predisposed to initiate broader networks, whereas neuroticism introduces relational friction that accelerates tie winnowing.

Second, the assumption that extraversion buffers against network shrinkage is disconfirmed by continuous growth modeling. Multilevel Poisson GLMMs revealed that highly extraverted students experience a significantly faster rate of degree contraction over time (Time×ExtraversionIRR=0.986,*p*\<0.001). Extraverts cast a wide net upon entering an unfamiliar institution, accumulating a large volume of casual ties that are subsequently winnowed as temporal and cognitive costs mount.

Third, decomposing degree trajectories across all four years of college resolves the long-standing paradox between Dunbar’s cognitive constraints and life-course network turnover. While total network degree shrinks by roughly 25% between freshman matriculation and senior graduation, this decline is confined to peripheral campus acquaintances. The volume of daily activated ties (roughly 5 alters, matching Dunbar’s support clique) and close, support-providing ties (roughly 10–12 alters, matching the sympathy group) remains exceptionally stable across four years.

These findings suggest that personal communities are organized through a deliberate functional division of relational labor. Rather than reflecting an undifferentiated gradient of tie loss, longitudinal degree trajectories represent an adaptive process through which individuals prune non-essential ties to conserve cognitive and emotional bandwidth for their core supportive bonds.

Future research should build on these insights by linking degree trajectory classes directly to passive sensor streams (e.g., continuous Fitbit physical activity and sleep metrics) and investigating whether the timing of peripheral tie pruning moderates post-graduate psychological well-being and career placement.

# References

-   Asendorpf, J. B., & Wilpers, S. (1998). Personality effects on social relationships. *Journal of Personality and Social Psychology*, 74(6), 1531–1544. https://doi.org/10.1037/0022-3514.74.6.1531

-   Bidart, C., Degenne, A., & Grossetti, M. (2018). Personal networks typologies: A review of analytical approaches. *Social Networks*, 54, 29–38. https://doi.org/10.1016/j.socnet.2018.01.006

-   Borgatti, S. P., Mehra, A., Brass, D. J., & Labianca, G. (2009). Network analysis in the social sciences. *Science*, 323(5916), 892–895. https://doi.org/10.1126/science.1165821

-   Campbell, K. E., & Lee, B. A. (1991). Name generators in surveys of personal networks. *Social Networks*, 13(3), 203–221. https://doi.org/10.1016/0378-8733(91)90007-F

-   Centellegher, S., López, E., Saramäki, J., & Lepri, B. (2017). Personality traits and ego-network dynamics. *PLOS ONE*, 12(3), e0173110. https://doi.org/10.1371/journal.pone.0173110

-   Chandler, M. J., & Hachen, D. (2018). *Classifying and Predicting Degree Trajectories in Longitudinal Ego Networks*. Sunbelt XXXVIII, International Network for Social Network Analysis (INSNA), Utrecht, Netherlands.

-   Costa, P. T., & McCrae, R. R. (1992). Four ways five factors are basic. *Personality and Individual Differences*, 13(6), 653–665. https://doi.org/10.1016/0191-8869(92)90236-I

-   Dunbar, R. I. (1992). Neocortex size as a constraint on group size in primates. *Journal of Human Evolution*, 22(6), 469–493. https://doi.org/10.1016/0047-2484(92)90081-J

-   Dunbar, R. I. (1998). The social brain hypothesis. *Evolutionary Anthropology*, 6(5), 178–190. https://doi.org/10.1002/(SICI)1520-6505(1998)6:5\<178::AID-EVAN5\>3.0.CO;2-8

-   Dunbar, R. I. (2018). The anatomy of friendship. *Trends in Cognitive Sciences*, 22(1), 32–51. https://doi.org/10.1016/j.tics.2017.10.004

-   Feld, S. L. (1982). Social structural determinants of similarity among associates. *American Sociological Review*, 47(6), 797–801. https://doi.org/10.2307/2095213

-   Fischer, C. S. (1982). *To dwell among friends: Personal networks in town and city*. University of Chicago Press.

-   Glaeser, E. L., Laibson, D. I., Scheinkman, J. A., & Soutter, C. L. (2000). Measuring trust. *The Quarterly Journal of Economics*, 115(3), 811–846. https://doi.org/10.1162/003355300554926

-   Granovetter, M. S. (1973). The strength of weak ties. *American Journal of Sociology*, 78(6), 1360–1380. https://doi.org/10.1086/225469

-   Harris, K., & Vazire, S. (2016). On friendship development and the Big Five personality traits. *Social and Personality Psychology Compass*, 10(11), 647–667. https://doi.org/10.1111/spc3.12287

-   Heydari, S., Roberts, S. G., Dunbar, R. I., & Saramäki, J. (2018). Multichannel social signatures and persistent features of ego networks. *Applied Network Science*, 3(1), 1–18. https://doi.org/10.1007/s41109-018-0065-4

-   Hill, R. A., & Dunbar, R. I. (2003). Social network size in humans. *Human Nature*, 14(1), 53–72. https://doi.org/10.1007/s12110-003-1016-y

-   Hurtado, S., Milem, J., Clayton-Pedersen, A., & Allen, W. (1998). Enhancing campus climates for racial/ethnic diversity: Educational policy and practice. *The Review of Higher Education*, 21(3), 279–302. https://doi.org/10.1353/rhe.1998.0003

-   John, O. P., & Srivastava, S. (1999). The Big Five trait taxonomy: History, measurement, and theoretical perspectives. In L. A. Pervin & O. P. John (Eds.), *Handbook of personality: Theory and research* (pp. 102–138). Guilford Press.

-   Lin, N. (2001). *Social capital: A theory of social structure and action*. Cambridge University Press. https://doi.org/10.1017/CBO9780511815447

-   Liu, S., Hachen, D., Lizardo, O., Poellabauer, C., Striegel, A., & Milenković, T. (2018). Network analysis of the NetHealth data: Exploring co-evolution of individuals’ social network positions and physical activities. *Applied Network Science*, 3(1), 45. https://doi.org/10.1007/s41109-018-0103-2

-   Lizardo, O. (2024). Multi-frame relational sociology: Decoupling roles, sentiments, interactions, and exchanges in egocentric networks. *Sociological Theory*, 42(1), 1–28.

-   Marsden, P. V. (1987). Core discussion networks of Americans. *American Sociological Review*, 52(1), 122–131. https://doi.org/10.2307/2095397

-   Marsden, P. V., & Campbell, K. E. (1984). Measuring tie strength. *Social Forces*, 63(2), 482–501. https://doi.org/10.1093/sf/63.2.482

-   McCarty, C., Lubbers, M. J., Vacca, R., & Molina, J. L. (2019). *Conducting personal network research: A practical guide*. Guilford Press.

-   Moore, G. (1990). Structural determinants of men’s and women’s personal networks. *American Sociological Review*, 55(5), 726–735. https://doi.org/10.2307/2095868

-   Roberts, B. W., Kuncel, N. R., Shiner, R., Caspi, A., & Goldberg, L. R. (2007). The power of personality: The comparative validity of personality traits, socioeconomic status, and cognitive ability for predicting important life outcomes. *Perspectives on Psychological Science*, 2(4), 313–345. https://doi.org/10.1111/j.1745-6916.2007.00047.x

-   Russell, D. W., Booth, B., Reed, D., & Laughlin, P. R. (2008). Personality, social networks, and loneliness in later life. *Journal of Gerontology: Psychological Sciences*, 63(5), P313–P322. https://doi.org/10.1093/geronb/63.5.P313

-   Saramäki, J., Leicht, E. A., López, E., Roberts, S. G., Reed-Tsochas, F., & Dunbar, R. I. (2014). Persistence of social signatures in human communication. *Proceedings of the National Academy of Sciences*, 111(3), 942–947. https://doi.org/10.1073/pnas.1308540110

-   Sepulvado, B., Wood, M., Wang, C., Fridmanski, E., Chandler, M., Lizardo, O., & Hachen, D. (2020). Predicting homophily and social network connectivity from dyadic behavioral similarity trajectory clusters. *Social Science Computer Review*, 40(1), 186–205. https://doi.org/10.1177/0894439320923123

-   Small, M. L. (2009). *Unanticipated gains: Origins of network inequality in everyday life*. Oxford University Press. https://doi.org/10.1093/acprof:oso/9780195384352.001.0001

-   Small, M. L., Pamphile, V. D., & McMahan, P. (2015). How stable is the core discussion network? *Social Networks*, 40, 90–102. https://doi.org/10.1016/j.socnet.2014.09.001

-   Smith, J. A. (2021). *Social networks and social support*. In B. L. Pescosolido et al. (Eds.), *Handbook of the sociology of mental health* (pp. 215–234). Springer.

-   Vacca, R. (2020). Structure in personal networks: Constructing and comparing typologies. *Network Science*, 8(2), 245–269. https://doi.org/10.1017/nws.2020.4

-   Wang, C., Lizardo, O., & Hachen, D. S. (2020). Neither influence nor selection: Examining co-evolution of political orientation and social networks in the NetSense and NetHealth studies. *PLOS ONE*, 15(5), e0233458. https://doi.org/10.1371/journal.pone.0233458

-   Wellman, B., & Wortley, S. (1990). Different strokes from different folks: Community ties and social support. *American Journal of Sociology*, 96(3), 558–588. https://doi.org/10.1086/229572

-   Yamagishi, T. (2011). *Trust: The evolutionary game of mind and society*. Springer. https://doi.org/10.1007/978-4-431-53936-0

-   Zhou, W. X., Sornette, D., Hill, R. A., & Dunbar, R. I. (2005). Discrete hierarchical organization of social group sizes. *Proceedings of the Royal Society B: Biological Sciences*, 272(1561), 439–444. https://doi.org/10.1098/rspb.2004.2970
