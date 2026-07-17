# Kosovariance: A Research Journey on Remittances, REER, and Kosovo's Macroeconomic Dynamics

**Original Report — Updated Edition**

---

> ### ⚠️ Academic Authorship Disclaimer
>
> **The original foundation, data mining pipeline, and baseline OLS settings for this study
> were developed collaboratively with my university colleagues Emanuele Pedroni and Andrea
> Tibiletti for a university Data Mining and Computational Statistics course project.**
>
> **The advanced time-series econometric upgrades — including the Augmented Dickey-Fuller
> (ADF) unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, the ARDL
> bounds testing procedure (Pesaran, Shin & Smith 2001), and the UECM long-run coefficient
> estimation — were implemented subsequently as an independent solo extension of that
> foundational collaborative work by Valerio Di Federico.**
>
> This document presents both layers of analysis. Sections 1–6 reflect the original
> collaborative university report. Sections 7–9 reflect the advanced independent extension.

---

**Authors (original university project):** Valerio Di Federico, Emanuele Pedroni, Andrea Tibiletti  
**Advanced extension (solo):** Valerio Di Federico  
**Course:** Data Mining and Computational Statistics  
**Dataset:** 137 monthly observations, January 2014 – May 2025

---

## Section 1 — Team Structure and Organization

### 1.1 Group Formation

The "Kosovariance" group project team consists of Valerio Di Federico, Emanuele Pedroni,
and Andrea Tibiletti. The group was formed based on a shared academic interest in
international macroeconomics and econometric analysis, as well as the complementary skills
each member brings to the project.

### 1.2 Task Assignment and Responsibilities

While the team collaborated closely throughout every phase of the research journey, we
maximized efficiency by trusting and leveraging the specific aptitudes of each member. We
distributed tasks dynamically, giving space to individual strengths — ranging from
proficiency in importing and managing raw Excel data, to advanced R programming and
econometrics, to the strategic ability to synthesize complex results into a cohesive global
narrative.

- **Data Engineering and Pre-processing:** Acquiring and selecting the raw datasets,
  cleaning data, handling missing values. This phase required subsetting the timeline to
  remove the initial highly incomplete 85 observations (pre-2014), ensuring a robust
  operational sample. Variables were transformed into first differences to achieve
  stationarity for the baseline models.

- **Econometric Modeling and Diagnostics:** Writing the core R scripts to test two competing
  macroeconomic hypotheses. Running baseline OLS models, identifying omitted variable bias,
  and iteratively building Autoregressive (ARX) and Distributed Lag (DL) models. Key
  diagnostics included Newey-West standard errors, Variance Inflation Factor (VIF) testing,
  and Breusch-Godfrey (BG) tests for serial correlation.

- **Data Visualization and Narrative Construction:** Translating complex regression outputs
  into an accessible academic narrative using `ggplot2`. Visualizations included "The
  Diaspora Pulse" (seasonal boxplot), "The Leakage Map" (quadrant scatterplot), and the
  "Exchange Rate Optical Illusion" (coefficient forest plot).

### 1.3 Organization and Collaboration

The team organized collaboration through weekly meetings to review statistical outputs and
maintain theoretical coherence. We established a dedicated GitHub repository integrated with
an RStudio Project environment. Git version control allowed all members to push
modifications, track changes, and work simultaneously on the same files.

---

## Section 2 — Project Rationale and Objective

### 2.1 The Economic Logic and Motivation

The fundamental logic behind this project stems from a desire to empirically test the
**Dutch Disease** theory in a uniquely structured economy. The classic Dutch Disease paradox
dictates that a massive influx of foreign currency can produce severe negative consequences
for a country's external competitiveness. When an economy experiences a boom in external
resources, the sudden increase in household disposable income generates a surge in demand
for domestic non-tradable goods (the "spending effect"). Consequently, domestic prices
inflate, the Real Effective Exchange Rate (REER) appreciates, and capital and labor shift
away from export-oriented sectors (the "resource movement effect").

Applied to the phenomenon of international migration, this theory suggests that massive
diaspora remittances can act as a persistent external shock, appreciating the REER and
eroding the competitiveness of the receiving country's tradable sector.

### 2.2 The Anomaly of Kosovo

Kosovo presents a fascinating macroeconomic anomaly. Remittances are a foundational pillar
of Kosovo's financial inflows, representing an indispensable mechanism for sustaining
household consumption, healthcare, and housing needs. However, only a marginal fraction of
these funds is channeled into productive investments or new business creation.

Furthermore, Kosovo is characterized by an extreme structural dependence on foreign imports.
This massive import reliance implies that the "spending effect" might not manifest as
domestic inflation, but rather as an immediate surge in the demand for foreign goods — a
phenomenon we defined as the **Import Leakage Channel**.

### 2.3 Main Objectives and Research Questions

The main objective of this project is to empirically distinguish between these two competing
macroeconomic mechanisms. We aim to answer the following core research questions:

1. Do diaspora remittances directed to Kosovo generate a traditional Dutch Disease effect by
   putting pressure on the domestic economy and directly appreciating the Real Effective
   Exchange Rate?

2. If remittances do not appreciate the REER, are these inflows instead absorbed through an
   alternative "Import Leakage Channel," thereby causing a direct, immediate worsening of
   Kosovo's commercial trade deficit?

---

## Section 3 — Theoretical Background and Literature Review

To guide our statistical models, we looked at existing economic literature to understand how
remittances usually affect an economy. The starting point for our hypothesis is the classic
Dutch Disease model described by **Corden and Neary (1982)**. This model explains how a
sudden inflow of foreign money can increase domestic spending, leading to inflation and
hurting the country's export competitiveness.

When applying this idea to remittances, the literature shows mixed results. **Guha (2013)**
noted that money sent from abroad changes how families consume goods, which can shift
resources between different sectors of the economy. Similarly, a working paper by **Acosta,
Lartey, and Mandelman (2007)** suggests that these inflows generally lead to real exchange
rate appreciation.

Looking at actual case studies, **Chowdhury and Rabbi (2014)** analyzed Bangladesh and found
evidence supporting the idea that workers' remittances do appreciate the real exchange rate
and reduce competitiveness. Expanding on this, **Polat and Rodríguez Andrés (2019)** looked
at a broader group of developing countries and concluded that while remittances can cause
Dutch Disease, the actual effects vary greatly depending on the specific characteristics of
the receiving country.

The main inspiration for our project comes from a **2025 IMF Working Paper by Carare et al.
(WP/25/122)**. This paper points out that in countries with a very high import-to-GDP ratio,
remittances do not significantly appreciate the REER. Instead, the extra money is mostly
spent on buying foreign goods rather than domestic ones. We used this specific IMF paper as
a theoretical benchmark to see if Kosovo's data followed this exact same pattern.

---

## Section 4 — Data Collection and Sources

### 4.1 Data Provenance and Time Horizon

To capture the immediate, short-term liquidity shocks associated with remittance inflows, we
utilized high-frequency **monthly data** rather than smoothed annual aggregates. The primary
dataset aggregated official macroeconomic indicators from the BQK (Kosovo Central Bank),
World Bank, and IMF databases.

The raw dataset spanned from December 2006 to June 2025. However, data for the most critical
variables — specifically Remittances and FDI — only started in January 2014. Because data
from 2007 to 2013 was entirely missing for these key metrics, we dropped the initial 85
observations, along with the final incomplete observation. This left a consistent working
sample of **137 monthly observations spanning January 2014 to May 2025**.

### 4.2 Key Variables and Summary Statistics

| Variable | Description | Mean | Std. Dev. | Min | Max |
|:---------|:------------|-----:|----------:|----:|----:|
| **REER_EU** | Real Effective Exchange Rate vs. EU | 106.41 | 1.35 | 103.79 | 109.64 |
| **Remittances** | Monthly diaspora inflows (USD million) | 80.06 | 24.96 | 41.57 | 141.95 |
| **Inflation** | Domestic CPI change (%) | 2.47 | 3.51 | −1.22 | 14.20 |
| **NEER** | Nominal Effective Exchange Rate | 104.83 | 2.86 | 100.85 | 110.70 |
| **FDI** | Monthly Foreign Direct Investment (USD million) | 36.38 | 27.35 | −65.61 | 102.67 |
| **NX** | Net Exports (Exports − Imports, USD million) | −292.20 | 106.79 | −561.56 | −109.34 |

### 4.3 Data Transformation Strategy

Macroeconomic time-series data is notoriously prone to non-stationarity, which can result in
spurious regression outputs. Our primary data transformation involved converting all
continuous variables into **first differences** (Δ X_t = X_t − X_{t-1}). This forces the
model to evaluate the impact of immediate monthly *shocks* rather than relying on underlying
long-term trends.

Furthermore, due to the severe seasonality of diaspora inflows, we introduced a matrix of
**monthly dummy variables** to isolate the true macroeconomic impact from routine cyclical
variance.

---

## Section 5 — Qualitative and Descriptive Analysis

### 5.1 The Diaspora Pulse

The most prominent qualitative finding is the phenomenon we identify as the **"Diaspora
Pulse"**. Plotting the historical evolution of remittances (2014–2025) reveals a clear,
upward structural growth trend, but more importantly, it showcases violent, cyclical
intra-year volatility.

Boxplot analyses of the monthly inflows demonstrate massive, statistically significant spikes
predominantly concentrated around the **summer months (July and August)** and the **winter
holidays (December)**. These spikes perfectly correlate with periods of mass diaspora return
to Kosovo. The seasonal amplitude is so pronounced that it renders any econometric model
without seasonal controls fundamentally misspecified.

### 5.2 The Baseline Correlation

A preliminary correlation matrix generated during the diagnostic phase revealed an
exceptionally strong negative correlation (approximately **−0.91**) between remittances and
Net Exports. This implies that months characterized by the highest influx of diaspora
liquidity are almost perfectly synchronized with the months experiencing the most severe
trade deficits.

While this descriptive statistic does not inherently prove causality, it provided the vital
qualitative justification to formally test the Import Leakage Channel. A correlation of this
magnitude, if confirmed by the regression models, would represent a near-mechanical
pass-through from diaspora liquidity to import demand.

---

## Section 6 — Quantitative Analysis: Baseline OLS and ARX Models

*(Original collaborative analysis — see Section 7 for the advanced solo extension)*

### 6.1 The Flawed Baseline: The Exchange Rate Optical Illusion

To test the primary hypothesis of the Domestic Pressure Channel, we estimated a standard OLS
regression in levels:

```
REER_EU_t = β₀ + β₁ Remittances_t + β₂ Inflation_t + β₃ NEER_t + ε_t
```

At first glance, this baseline model yielded a highly significant **negative** coefficient
for remittances (Estimate: −0.0472, p < 0.001). This paradoxically suggested that higher
remittances were associated with real depreciation — contradicting traditional Dutch Disease
mechanics.

However, this result is an "optical illusion." Relying on static OLS for non-stationary
macroeconomic time-series ignores deep collinearity between macro variables and completely
fails to isolate the seasonal "Diaspora Pulse."

### 6.2 Time-Series Discipline: Rejecting the REER Channel

To uncover the true causal mechanics, we transitioned to a heavily disciplined
**Autoregressive specification with exogenous controls (ARX)** modeled in first differences:

```
Δ REER_t = β₀ + β₁ Δ REER_{t-1} + β₂ Δ REER_{t-4} + β₃ Δ REER_{t-12}
           + β₄ Δ Remittances_t + β₅ Δ Inflation_t + β₆ Δ FDI_t
           + β₇ Δ NX_t + Σ δ_m Month_m + ε_t
```

Standard errors were adjusted using the **Newey-West procedure** to control for
heteroskedasticity and autocorrelation. The Breusch-Godfrey test yielded p = 0.412,
confirming the absence of residual serial correlation.

**Results:** Once structural dynamics, seasonality, and robust errors were applied, the
direct effect of remittances on the REER **completely vanished**. The coefficient for Δ
Remittances plummeted to 0.0029 with a highly insignificant p-value of 0.525. Instead,
monthly inflation (Δ Inflation, coefficient 0.4202, p < 0.001) emerged as the dominant
driver of exchange rate variance.

- **Adjusted R²:** 0.6315  
- **Robust F-statistic:** 47.91 (p < 0.001)  
- **Breusch-Godfrey test:** p = 0.412 (no serial correlation)

### 6.3 Proving the Import Leakage Channel

Having established that diaspora liquidity does not inflate the REER, we shifted the
dependent variable to test the indirect pathway. We built a **Distributed Lag (DL) model**:

```
Δ NX_t = α₀ + α₁ Δ Remittances_t + α₂ Δ Remittances_{t-1}
         + α₃ Δ Remittances_{t-12} + α₄ Δ Inflation_t + α₅ Δ REER_t
         + Σ η_m Month_m + u_t
```

**Results — Three distinct phases:**

1. **Immediate Leakage (contemporaneous):** α₁ = −0.860 (p = 0.008). For every dollar of
   diaspora money entering Kosovo, **86 cents instantly leaks out** to finance foreign
   imports in the exact same month.

2. **Positive pull-backs:** α₂ = +0.412 (t+1) and α₃ = +0.694 (t+12) indicate partial
   reversal of the deficit shock over subsequent months.

3. **Long-Term Neutrality:** A formal Wald test on the cumulative 12-month effect yields
   p = 0.633 — proving the initial deficit shock **completely neutralises** over one year.

- **Adjusted R²:** 0.747  
- **Robust F-statistic:** 118.21 (p < 0.001)

---

## Section 7 — Advanced Time-Series Extension (Solo Independent Work)

> **Note:** This section represents the sole independent contribution of Valerio Di Federico,
> developed after the conclusion of the university project.

### 7.1 Motivation for the Extension

The original collaborative analysis, while econometrically sound in its short-run
specification, left an important gap: it did not formally test the **integration order** of
the variables (relying implicitly on the first-differencing transformation), did not run
formal **heteroskedasticity diagnostics**, and did not establish a confirmed **long-run
cointegrating relationship** via a formal test. Establishing cointegration would elevate the
finding from "no short-run effect" to "no long-run equilibrium effect" — a much stronger
claim.

### 7.2 ADF Unit Root Testing

Using `urca::ur.df()` with AIC lag selection (max 12 lags) and `tseries::adf.test()` as a
cross-check, we tested all six variables in levels and first differences.

| Variable | τ (Levels) | 5% CV | p-val (Levels) | τ (Δ) | 5% CV | p-val (Δ) | Order |
|:---------|----------:|------:|---------------:|------:|------:|----------:|:------|
| REER_EU | −2.483 | −3.412 | 0.382 | −7.625 | −2.879 | <0.01 | I(1) |
| Remittances | −3.490 | −3.412 | 0.049 | −9.551 | −2.879 | <0.01 | I(0) |
| Inflation | −2.836 | −3.412 | 0.210 | −7.591 | −2.879 | <0.01 | I(1) |
| NEER | −2.419 | −3.412 | 0.409 | −8.285 | −2.879 | <0.01 | I(1) |
| FDI | −6.036 | −3.412 | <0.01 | −9.891 | −2.879 | <0.01 | I(0) |
| NX | −2.968 | −3.412 | 0.160 | −6.869 | −2.879 | <0.01 | I(1) |

**Finding:** The dataset is **mixed I(0)/I(1)**. Remittances and FDI are stationary in
levels (I(0)); REER_EU, Inflation, NEER, and NX are I(1). This critical result rules out
the Johansen (1988) procedure as a primary tool (which assumes all I(1)) and mandates the
use of the ARDL bounds test.

The I(0) classification of Remittances is economically intuitive: diaspora inflows are a
mean-reverting flow variable — they spike seasonally (the Diaspora Pulse) and revert to
trend within the same fiscal year. They do not accumulate into a persistent, non-stationary
level.

### 7.3 Heteroskedasticity Diagnostics

Applied to the original `fit_final` ARX model:

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (χ², df=19) | 27.40 | 0.095 | Fail to reject H₀ — homoskedastic |
| White test (nR²) | 2.20 | 0.333 | Fail to reject H₀ — homoskedastic |

Both tests fail to detect heteroskedasticity at 5% significance. The Newey-West HAC
correction applied in the original model was precautionary; the errors are well-behaved.

### 7.4 ARDL Bounds Test (Pesaran, Shin & Smith 2001)

The ARDL bounds test is the methodologically appropriate cointegration framework for a mixed
I(0)/I(1) dataset. It tests whether a long-run levels relationship exists among the variables
via an F-test on the lagged level terms in the Unrestricted Error Correction Model (UECM).

**Optimal ARDL order (AIC):** ARDL(2, 0, 0, 0, 2, 4) for (REER_EU, Remittances, Inflation,
NEER, FDI, NX).

**Bounds F-test (Case III — unrestricted intercept, no trend):**

| Critical Threshold | I(0) Lower | I(1) Upper |
|:---|---:|---:|
| 10% | 2.26 | 3.35 |
| **5%** | **2.62** | **3.79** |
| 1% | 3.41 | 4.68 |

**F-statistic = 5.2006 → F > I(1) upper bound of 3.79 at 5%**

**Bounds t-test:** t = −2.869 (p = 0.032) — ECT coefficient is significant.

> **Conclusion: A statistically confirmed long-run cointegrating relationship between
> Kosovo's REER and its macroeconomic fundamentals is established at the 5% significance
> level.**

### 7.5 Long-Run UECM Coefficients

| Variable | Long-Run β | Std. Error | p-value | Significant? |
|:---------|----------:|----------:|--------:|:------------|
| **NEER** | **+0.6341** | 0.1110 | **<0.001** | Yes |
| **NX** | **+0.0024** | 0.0008 | **0.005** | Yes |
| **Remittances** | **+0.0119** | 0.0106 | **0.268** | **No** |
| FDI | −0.0016 | 0.0012 | 0.187 | No |
| Inflation | +0.0160 | 0.0608 | 0.793 | No |

**Speed of adjustment:** δ = −0.389 (p = 0.005), meaning ~39% of any REER deviation from
the long-run equilibrium is corrected each month — consistent with Kosovo's highly managed,
euroized monetary regime.

**UECM model fit:** R² = 0.564, Adj. R² = 0.504, F(13, 92) = 9.48, p < 2.2×10⁻¹⁶

---

## Section 8 — Conclusions and Final Considerations

### 8.1 Summary of Macroeconomic Findings

The "Kosovariance" project provides a **definitive empirical answer** to its core research
question: **Kosovo does not suffer from Dutch Disease**.

This conclusion is established at two distinct levels of econometric rigor:

1. **Short-run (original ARX model):** Once seasonal controls, autocorrelation correction
   (Newey-West), and first-difference transformation are applied, remittances have no
   statistically significant short-run effect on the REER (coefficient = 0.0029, p = 0.525).

2. **Long-run (ARDL UECM extension):** Even after confirming a statistically significant
   cointegrating relationship among the macro variables (F = 5.20, p = 0.043), the long-run
   equilibrium multiplier for remittances is **β = +0.012, p = 0.268** — statistically
   indistinguishable from zero.

The dominant long-run force shaping Kosovo's REER is the **Nominal Effective Exchange Rate**
(β = 0.634, p < 0.001) — reflecting mechanical exchange rate pass-through, not diaspora
inflows.

Instead, the Kosovar economy operates as a **"pass-through" system dominated by the Import
Leakage Channel**: diaspora liquidity enters as a seasonal shock and immediately exits to
finance foreign imports (86 cents per dollar in the same month), fully neutralising over a
12-month cyclical horizon.

### 8.2 Alignment with Contemporary Literature

Our quantitative findings directly validate the **2025 IMF Working Paper by Carare et al.**
(WP/25/122), which asserts an exception to the Dutch Disease rule: in heavily import-dependent
economies operating under fixed or highly stabilised exchange rate regimes (like Kosovo's
euroized environment), the structural reliance on foreign goods acts as a pressure release
valve, naturally neutralising any potential REER appreciation.

### 8.3 Limitations of the Study

- Informal remittances (cash physically carried by returning diaspora) are unobservable in
  official Central Bank data and likely amplify the seasonal Diaspora Pulse
- Integration of granular, sector-specific pricing data could provide deeper clarity
- Real interest rate dynamics are not included in the current specification
- Sample length (137 observations) limits statistical power for very long lag structures

### 8.4 Macroeconomic Policy Implications

Because **86% of incoming diaspora liquidity instantly exits the country**, the policy
mandate must shift away from restricting capital inflows toward aggressive foundational
industrial policy:

- **Diaspora Bonds** — formalized instruments to capture private transfers before they leak
  into foreign consumption
- **Import-substitution industrial policy** — develop domestic value chains for goods
  currently imported from diaspora spending
- **Remittance-linked savings and investment products** — incentivise business creation over
  consumption spending

---

## Appendix — References

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch
disease* (Working Paper No. 2007-8a). Federal Reserve Bank of Atlanta.

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How Do Remittances Affect
the Real Exchange Rate? An Empirical Investigation* (IMF Working Paper WP/25/122).
Washington, DC: International Monetary Fund.

Chowdhury, M. B., & Rabbi, F. (2014). Workers' remittances and Dutch disease in Bangladesh.
*The Journal of International Trade & Economic Development*, 23(4), 455–475.

Corden, W. M., & Neary, J. P. (1982). Booming Sector and De-Industrialisation in a Small
Open Economy. *The Economic Journal*, 92(368), 825–848.

Guha, P. (2013). Macroeconomic effects of international remittances: The case of developing
economies. *Economic Modelling*, 33, 292–305.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and
autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis
of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Polat, B., & Rodríguez Andrés, A. (2019). Do emigrants' remittances cause Dutch Disease? A
developing countries case study. *The Economic and Labour Relations Review*, 30(1), 59–76.

UNDP and GERMIN. (2023). *Kosovo Diaspora and its Role Amidst Multiple Crises*. Pristina:
United Nations Development Programme in Kosovo and GERMIN.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct
test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
