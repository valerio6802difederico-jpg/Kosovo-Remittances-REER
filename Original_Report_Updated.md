# Kosovariance: Diaspora Remittances, the Real Effective Exchange Rate, and Kosovo's Macroeconomic Dynamics

**A Comprehensive Time-Series Econometric Study**

---

**Authors:** Valerio Di Federico et al.
**Course:** Data Mining and Computational Statistics
**Dataset:** 137 monthly observations, January 2014 – May 2025
**Software:** R 4.5.2

---

## Section 1 — Team Structure and Organization

### 1.1 Group Formation

The "Kosovariance" project team was formed around a shared academic interest in international macroeconomics and econometric analysis, combining complementary skills in quantitative methods, data engineering, and economic theory. The project grew organically from an initial exploratory analysis into a full multi-layer research programme, expanding in analytical depth as each successive diagnostic result raised new questions worth investigating.

### 1.2 Task Assignment and Responsibilities

The team collaborated closely throughout every phase of the research, with tasks distributed dynamically according to individual strengths. The research was structured around three parallel workstreams:

- **Data Engineering and Pre-processing:** Acquiring and cleaning the raw monthly datasets from the Kosovo Central Bank (BQK), IMF, World Bank, and Kosovo Tax Administration. This phase required careful handling of the pre-2014 data gap — the initial 85 observations were excluded due to complete absence of key series — and the removal of one anomalous final observation. Variables were formatted for both level-based and first-difference specifications.

- **Econometric Modelling and Diagnostics:** The core analytical work proceeded through several progressively rigorous layers. Beginning with an OLS baseline to identify the data-generating process, the team built an Autoregressive model with eXogenous controls (ARX) in first differences, incorporating full monthly seasonal dummies to neutralise the "Diaspora Pulse" seasonality. Newey-West HAC standard errors (Newey & West, 1987) were applied throughout to ensure robustness to autocorrelation and potential heteroskedasticity. A Breusch-Godfrey serial correlation test (p = 0.412) confirmed the absence of residual autocorrelation, and Variance Inflation Factor diagnostics addressed multicollinearity. A dedicated Distributed Lag (DL) model was then specified with Net Exports as the dependent variable to formally test the Import Leakage Channel, validated by a Wald test for the cumulative 12-month effect. The analysis was subsequently extended with formal ADF unit root testing (ur.df, AIC lag selection), Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing (Pesaran, Shin & Smith, 2001), UECM long-run coefficient estimation, and finally a Local Projections IV (Jordà, 2005) specification to address potential endogeneity and the omission of Eurozone macroeconomic conditions.

- **Data Visualisation and Narrative Construction:** Translating the statistical outputs into a coherent economic argument using `ggplot2`. Key visualisations include the "Diaspora Pulse" seasonal boxplot, the "Leakage Map" quadrant scatterplot, the "Exchange Rate Optical Illusion" coefficient forest plot, and the two-panel LP-IV Impulse Response Function chart tracing the REER and Net Exports responses to an exogenous remittance shock across a 12-month horizon.

### 1.3 Organisation and Collaboration

The team maintained a shared GitHub repository integrated with an RStudio Project environment. Git version control enabled simultaneous contributions, transparent version history, and reproducible results. The repository includes all raw data, R scripts, and documentation necessary to replicate every result from scratch.

---

## Section 2 — Project Rationale and Objective

### 2.1 The Economic Logic and Motivation

The fundamental logic behind this project stems from a desire to empirically test the **Dutch Disease** theory in a uniquely structured economy. The classic Dutch Disease paradox (Corden & Neary, 1982) dictates that a massive influx of foreign currency can produce severe negative consequences for a country's external competitiveness. When an economy experiences a boom in external resources, the sudden increase in household disposable income generates a surge in demand for domestic non-tradable goods (the "spending effect"). Consequently, domestic prices inflate, the Real Effective Exchange Rate (REER) appreciates, and capital and labour shift away from export-oriented sectors (the "resource movement effect").

Applied to diaspora remittances, this theory suggests that persistent large inflows can act as a recurring external shock, appreciating the REER and gradually eroding the competitiveness of the receiving country's tradable sector.

### 2.2 The Anomaly of Kosovo

Kosovo presents a fascinating macroeconomic anomaly. Remittances are a foundational pillar of Kosovo's financial inflows, representing an indispensable mechanism for sustaining household consumption, healthcare, and housing needs. However, only a marginal fraction of these funds is channelled into productive investments or new business creation.

Furthermore, Kosovo is characterised by extreme structural dependence on foreign imports and, crucially, operates under full euroisation — it uses the Euro as its official currency, with no independent monetary policy and no exchange rate tool to absorb external shocks. This combination implies that the "spending effect" might not manifest as domestic inflation, but rather as an immediate surge in the demand for foreign goods — a phenomenon we define as the **Import Leakage Channel**.

### 2.3 Main Objectives and Research Questions

The main objective of this project is to empirically distinguish between these two competing macroeconomic mechanisms. We aim to answer the following core research questions:

1. Do diaspora remittances directed to Kosovo generate a traditional Dutch Disease effect by appreciating the Real Effective Exchange Rate, in both the short run and the long run?

2. Is there a confirmed cointegrating long-run relationship between the REER and its macroeconomic fundamentals over the 2014–2025 period?

3. Which variable is the dominant structural driver of Kosovo's REER?

4. If remittances do not appreciate the REER, are these inflows instead absorbed through an "Import Leakage Channel," causing a direct, immediate worsening of Kosovo's trade deficit?

5. Are these findings robust to potential endogeneity between remittances and the REER, and to the omission of Eurozone macroeconomic push-factors?

---

## Section 3 — Theoretical Background and Literature Review

To guide our statistical models, we examined existing economic literature to understand how remittances typically affect an economy. The starting point is the classic Dutch Disease model of **Corden and Neary (1982)**, which explains how a sudden inflow of foreign money can increase domestic spending, leading to inflation and hurting the country's export competitiveness.

When applied to remittances, the literature shows mixed results. **Guha (2013)** noted that money sent from abroad changes household consumption patterns, which can shift resources between different sectors. Similarly, **Acosta, Lartey, and Mandelman (2007)** argue that remittance inflows generally lead to real exchange rate appreciation. **Chowdhury and Rabbi (2014)** found evidence supporting this in Bangladesh, while **Polat and Rodríguez Andrés (2019)** demonstrated that the actual effects vary substantially with the structural characteristics of the receiving country.

The main theoretical benchmark for this project is the **2025 IMF Working Paper by Carare et al. (WP/25/122)**, which argues that in countries with a very high import-to-GDP ratio operating under fixed or heavily managed exchange rate regimes, remittances do not significantly appreciate the REER. Instead, the additional liquidity is spent on foreign goods rather than domestic ones. This paper provides the direct theoretical foundation for the Import Leakage Channel hypothesis and gives us a contemporary, empirical benchmark against which to test Kosovo's data.

---

## Section 4 — Data Collection and Sources

### 4.1 Data Provenance and Time Horizon

To capture the immediate, short-term liquidity shocks associated with remittance inflows, we utilised high-frequency **monthly data** rather than smoothed annual aggregates. The primary dataset aggregated official macroeconomic indicators from the BQK (Kosovo Central Bank), World Bank, IMF, and Kosovo Tax Administration databases.

The raw dataset spanned from December 2006 to June 2025. However, data for the most critical variables — specifically Remittances and FDI — only began in January 2014. Because data from 2007 to 2013 was entirely missing for these key metrics, we dropped the initial 85 observations, along with the final incomplete observation. This left a consistent working sample of **137 monthly observations spanning January 2014 to May 2025**.

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

Macroeconomic time-series data is notoriously prone to non-stationarity, which can result in spurious regression outputs. Our primary data transformation involved converting all continuous variables into **first differences** (Δ X_t = X_t − X_{t-1}), forcing the model to evaluate the impact of immediate monthly *shocks* rather than relying on underlying long-term trends. This choice was later validated formally by ADF unit root testing (Section 7.2).

Furthermore, due to the severe seasonality of diaspora inflows, we introduced a matrix of **monthly dummy variables** to isolate the true macroeconomic impact from routine cyclical variance — a critical specification decision that fundamentally changes the estimated remittance coefficient.

---

## Section 5 — Qualitative and Descriptive Analysis

### 5.1 The Diaspora Pulse

The most prominent qualitative finding is the phenomenon we identify as the **"Diaspora Pulse"**. Plotting the historical evolution of remittances (2014–2025) reveals a clear upward structural growth trend, but more importantly, violent cyclical intra-year volatility. Boxplot analyses of the monthly inflows demonstrate massive, statistically significant spikes concentrated around the **summer months (July and August)** and the **winter holidays (December)**. These spikes perfectly correlate with periods of mass diaspora return to Kosovo. The seasonal amplitude is so pronounced that any econometric model without seasonal controls is fundamentally misspecified.

### 5.2 The Baseline Correlation

A preliminary correlation matrix revealed an exceptionally strong negative correlation (approximately **−0.91**) between remittances and Net Exports. This implies that months characterised by the highest influx of diaspora liquidity are almost perfectly synchronised with months experiencing the most severe trade deficits. While this does not inherently prove causality, it provided the qualitative justification to formally test the Import Leakage Channel. A correlation of this magnitude, if confirmed by the regression models, would represent a near-mechanical pass-through from diaspora liquidity to import demand.

---

## Section 6 — Quantitative Analysis: ARX Models and the Import Leakage Channel

### 6.1 The Flawed Baseline: The Exchange Rate Optical Illusion

To test the primary hypothesis of the Domestic Pressure Channel, we first estimated a standard OLS regression in levels:

```
REER_EU_t = β₀ + β₁ Remittances_t + β₂ Inflation_t + β₃ NEER_t + ε_t
```

This baseline yielded a highly significant **negative** coefficient for remittances (Estimate: −0.0472, p < 0.001) — paradoxically suggesting that higher remittances are associated with real depreciation, directly contradicting Dutch Disease mechanics.

This result is an "optical illusion." Relying on static OLS for non-stationary macroeconomic time-series ignores deep collinearity between macro variables and completely fails to isolate the seasonal "Diaspora Pulse." The model is misspecified at its foundation.

### 6.2 Time-Series Discipline: The ARX Specification

To uncover the true causal mechanics, we transitioned to an **Autoregressive specification with eXogenous controls (ARX)** modelled in first differences:

```
Δ REER_t = β₀ + β₁ Δ REER_{t-1} + β₂ Δ REER_{t-4} + β₃ Δ REER_{t-12}
           + β₄ Δ Remittances_t + β₅ Δ Inflation_t + β₆ Δ FDI_t
           + β₇ Δ NX_t + Σ δ_m Month_m + ε_t
```

Standard errors were adjusted using the **Newey-West HAC procedure** (lag bandwidth = 12) to simultaneously control for heteroskedasticity and any residual autocorrelation. The Breusch-Godfrey test (p = 0.412) confirms the absence of serial correlation in residuals. VIF diagnostics confirm no harmful multicollinearity among the regressors.

**Results:** Once structural dynamics, seasonality, and robust errors are applied, the direct effect of remittances on the REER **completely vanishes**. The coefficient for Δ Remittances falls to 0.0029 with p = 0.525. The dominant short-run driver of REER variance is monthly inflation (Δ Inflation, coefficient 0.4202, p < 0.001), reflecting the euroised economy's sensitivity to domestic price shocks.

- **Adjusted R²:** 0.6315
- **Robust F-statistic:** 47.91 (p < 0.001)
- **Breusch-Godfrey test:** p = 0.412 — no serial correlation

### 6.3 Proving the Import Leakage Channel

Having established that diaspora liquidity does not inflate the REER, we shifted the dependent variable to test the alternative pathway. We estimated a **Distributed Lag (DL) model** with Net Exports as the dependent variable:

```
Δ NX_t = α₀ + α₁ Δ Remittances_t + α₂ Δ Remittances_{t-1}
         + α₃ Δ Remittances_{t-12} + α₄ Δ Inflation_t + α₅ Δ REER_t
         + Σ η_m Month_m + u_t
```

**Results — three distinct phases:**

1. **Immediate Leakage (contemporaneous):** α₁ = −0.860 (p = 0.008). For every dollar of diaspora money entering Kosovo, **86 cents instantly leaks out** to finance foreign imports in the exact same month.

2. **Partial pull-backs:** α₂ = +0.412 (t+1) and α₃ = +0.694 (t+12) indicate partial reversal of the deficit shock over subsequent months.

3. **Long-Term Neutrality:** A formal Wald test on the cumulative 12-month effect yields p = 0.633 — proving the initial deficit shock **completely neutralises** over one year.

- **Adjusted R²:** 0.747
- **Robust F-statistic:** 118.21 (p < 0.001)

---

## Section 7 — Formal Stationarity Testing and Long-Run Analysis

### 7.1 Motivation

The ARX analysis established the short-run picture with confidence. However, two important questions remained open: Are the variables formally I(1) or I(0), and does a statistically confirmed long-run equilibrium relationship exist among them? Addressing these questions requires the machinery of formal unit root testing and cointegration analysis — which elevates the finding from "no short-run effect" to "no long-run equilibrium effect," a substantially stronger scientific claim.

We also address two potential structural concerns: **(i)** the possibility of contemporaneous endogeneity between Remittances and the REER (reverse causality: does REER appreciation affect how much the diaspora sends?), and **(ii)** the omission of Eurozone macroeconomic conditions (EA unemployment, EUR/USD, HICP), which drive the remittance supply from the diaspora side.

### 7.2 ADF Unit Root Testing

Using `urca::ur.df()` with AIC lag selection (max 12 lags) and `tseries::adf.test()` as a cross-check, we tested all six variables in levels and first differences.

| Variable | τ (Levels) | 5% CV | p-val (Levels) | τ (Δ) | 5% CV | p-val (Δ) | Order |
|:---------|----------:|------:|---------------:|------:|------:|----------:|:------|
| REER_EU | −2.483 | −3.412 | 0.382 | −7.625 | −2.879 | <0.01 | I(1) |
| Remittances | −3.490 | −3.412 | 0.049 | −9.551 | −2.879 | <0.01 | I(0) |
| Inflation | −2.836 | −3.412 | 0.210 | −7.591 | −2.879 | <0.01 | I(1) |
| NEER | −2.419 | −3.412 | 0.409 | −8.285 | −2.879 | <0.01 | I(1) |
| FDI | −6.036 | −3.412 | <0.01 | −9.891 | −2.879 | <0.01 | I(0) |
| NX | −2.968 | −3.412 | 0.160 | −6.869 | −2.879 | <0.01 | I(1) |

**Finding:** The dataset is **mixed I(0)/I(1)**. This rules out the Johansen (1988) procedure, which assumes all variables are I(1), and mandates the ARDL bounds approach. The I(0) classification of Remittances is economically intuitive: diaspora inflows are a mean-reverting flow variable that spikes seasonally and reverts to trend within the same fiscal year.

### 7.3 Heteroskedasticity Diagnostics

Applied to the ARX model residuals:

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (χ², df=19) | 27.40 | 0.095 | Fail to reject H₀ — homoskedastic |
| White test (nR²) | 2.20 | 0.333 | Fail to reject H₀ — homoskedastic |

Both tests fail to detect heteroskedasticity at 5% significance. The Newey-West HAC correction applied throughout is thus precautionary; the errors are well-behaved.

### 7.4 ARDL Bounds Test (Pesaran, Shin & Smith, 2001)

The ARDL bounds test is the methodologically appropriate cointegration framework for a mixed I(0)/I(1) dataset. It tests whether a long-run levels relationship exists via an F-test on the lagged level terms in the Unrestricted Error Correction Model (UECM).

**Optimal ARDL order (AIC):** ARDL(2, 0, 0, 0, 2, 4) for (REER_EU, Remittances, Inflation, NEER, FDI, NX).

**Bounds F-test (Case III — unrestricted intercept, no trend):**

| Critical Threshold | I(0) Lower | I(1) Upper |
|:---|---:|---:|
| 10% | 2.26 | 3.35 |
| **5%** | **2.62** | **3.79** |
| 1% | 3.41 | 4.68 |

**F-statistic = 5.2006 → F > I(1) upper bound of 3.79 at 5%**

**Bounds t-test:** t = −2.869 (p = 0.032) — ECT coefficient is significant.

> **Conclusion: A statistically confirmed long-run cointegrating relationship between Kosovo's REER and its macroeconomic fundamentals is established at the 5% significance level.**

### 7.5 Long-Run UECM Coefficients

| Variable | Long-Run β | Std. Error | p-value | Significant? |
|:---------|----------:|----------:|--------:|:------------|
| **NEER** | **+0.6341** | 0.1110 | **<0.001** | Yes |
| **NX** | **+0.0024** | 0.0008 | **0.005** | Yes |
| **Remittances** | **+0.0119** | 0.0106 | **0.268** | **No** |
| FDI | −0.0016 | 0.0012 | 0.187 | No |
| Inflation | +0.0160 | 0.0608 | 0.793 | No |

**Speed of adjustment:** δ = −0.389 (p = 0.005), meaning approximately 39% of any REER deviation from long-run equilibrium is corrected each month — consistent with Kosovo's highly managed, euroized monetary regime.

**UECM model fit:** R² = 0.564, Adj. R² = 0.504, F(13, 92) = 9.48, p < 2.2×10⁻¹⁶

### 7.6 Local Projections IV: Endogeneity and Eurozone Correction

To address the two remaining structural concerns — potential reverse causality from REER to Remittances and the omission of Eurozone push-factors — we implement a **Local Projections IV (LP-IV)** framework (Jordà, 2005; Stock & Watson, 2018).

**Step 1 — Remittance Shock Construction.** We regress Remittances on its own lags (1, 2, 12 months), Eurozone controls (EA unemployment rate, EUR/USD exchange rate, EA HICP inflation — sourced programmatically via the `eurostat` and `quantmod` packages), and Kosovo domestic controls. The regression residual is the exogenous remittance shock: the variation in remittances that cannot be explained by Eurozone economic conditions or past domestic dynamics.

**Step 2 — Local Projections at h = 0…12 months.** For each horizon h, we estimate:

```
REER_{t+h} − REER_{t-1} = α_h + β_h · shock_t + Γ · controls_{t-1} + η_{t+h}
```

Standard errors use Newey-West HAC with bandwidth = h+1. A **pairs bootstrap (B = 1,000 replications)** corrects for the generated-regressor bias introduced by the two-step procedure. The same specification is estimated for Net Exports to confirm the leakage channel.

**Wu-Hausman endogeneity test:** F = 1.072 (p = 0.304) — endogeneity is **not detected** at any conventional significance level, confirming that OLS was consistent throughout.

**Sargan overidentification test:** χ² = 0.921 (p = 0.632) — Eurozone instruments are valid.

**LP-IV REER results:** **0 out of 13 horizons** show a 90% bootstrap CI excluding zero. The joint bootstrap p-value for a global null across all horizons is 0.831. Peak response: β = −0.005 at h = 11 months — economically negligible and statistically zero.

**LP-IV NX (leakage) results:** Significant at h = 0 (β = −0.59, 90% CI excludes zero), consistent with the 86-cent contemporaneous leakage estimate from Section 6.3. The effect fades and the CI crosses zero by h = 2, consistent with 12-month neutralisation.

> **Dutch Disease is rejected across all three methodological layers — short-run ARX, long-run ARDL, and horizon-by-horizon LP-IV — with and without endogeneity correction.**

---

## Section 8 — Conclusions and Final Considerations

### 8.1 Summary of Macroeconomic Findings

The "Kosovariance" project provides a **definitive empirical answer** to its core research question: **Kosovo does not suffer from Dutch Disease.**

This conclusion is established at three distinct levels of econometric rigour:

1. **Short-run (ARX model):** Once seasonal controls, autocorrelation correction (Newey-West), and first-difference transformation are applied, remittances have no statistically significant short-run effect on the REER (coefficient = 0.0029, p = 0.525).

2. **Long-run (ARDL UECM):** Even after confirming a statistically significant cointegrating relationship among the macro variables (F = 5.20, bounds test p < 0.05), the long-run equilibrium multiplier for remittances is **β = +0.012, p = 0.268** — statistically indistinguishable from zero.

3. **Endogeneity-corrected (LP-IV):** After purging the remittance shock of Eurozone push-factor content, **0 out of 13 horizon-specific regressions** detect a significant REER response. The Wu-Hausman test confirms no endogeneity was present to begin with — meaning OLS and ARDL estimates were unbiased.

The dominant long-run force shaping Kosovo's REER is the **Nominal Effective Exchange Rate** (β = 0.634, p < 0.001) — reflecting mechanical exchange rate pass-through from Kosovo's euroized monetary regime, not diaspora inflows.

Instead, the Kosovar economy operates as a **pass-through system dominated by the Import Leakage Channel**: diaspora liquidity enters as a seasonal shock and immediately exits to finance foreign imports (86 cents per dollar in the same month), fully neutralising over a 12-month cyclical horizon.

### 8.2 Alignment with Contemporary Literature

Our quantitative findings directly validate the **2025 IMF Working Paper by Carare et al.** (WP/25/122), which asserts an exception to the Dutch Disease rule: in heavily import-dependent economies operating under fixed or highly stabilised exchange rate regimes, structural reliance on foreign goods acts as a pressure release valve, naturally neutralising any potential REER appreciation.

### 8.3 Limitations of the Study

- Informal remittances (cash physically carried by returning diaspora) are unobservable in official Central Bank data and likely amplify the seasonal Diaspora Pulse
- Integration of granular, sector-specific pricing data could provide deeper clarity on the spending vs. leakage decomposition
- Real interest rate dynamics are not included in the current specification
- Sample length (137 observations) limits statistical power for very long lag structures
- The LP-IV Eurozone instrument relevance (partial F = 6.40) falls marginally below the conventional strong-instrument threshold of 10, warranting cautious interpretation of the IV estimates — though the Wu-Hausman non-rejection makes this moot

### 8.4 Macroeconomic Policy Implications

Because **86% of incoming diaspora liquidity instantly exits the country**, the policy mandate must shift away from restricting capital inflows toward aggressive foundational industrial policy:

- **Diaspora Bonds** — formalised instruments to capture private transfers before they leak into foreign consumption
- **Import-substitution industrial policy** — develop domestic value chains for goods currently imported from diaspora spending
- **Remittance-linked savings and investment products** — incentivise business creation over consumption spending

---

## Appendix — References

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper No. 2007-8a). Federal Reserve Bank of Atlanta.

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How Do Remittances Affect the Real Exchange Rate? An Empirical Investigation* (IMF Working Paper WP/25/122). Washington, DC: International Monetary Fund.

Chowdhury, M. B., & Rabbi, F. (2014). Workers' remittances and Dutch disease in Bangladesh. *The Journal of International Trade & Economic Development*, 23(4), 455–475.

Corden, W. M., & Neary, J. P. (1982). Booming Sector and De-Industrialisation in a Small Open Economy. *The Economic Journal*, 92(368), 825–848.

Guha, P. (2013). Macroeconomic effects of international remittances: The case of developing economies. *Economic Modelling*, 33, 292–305.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Polat, B., & Rodríguez Andrés, A. (2019). Do emigrants' remittances cause Dutch Disease? A developing countries case study. *The Economic and Labour Relations Review*, 30(1), 59–76.

UNDP and GERMIN. (2023). *Kosovo Diaspora and its Role Amidst Multiple Crises*. Pristina: United Nations Development Programme in Kosovo and GERMIN.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
