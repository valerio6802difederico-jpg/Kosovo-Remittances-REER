# Kosovariance: Diaspora Remittances, the Real Effective Exchange Rate, and Kosovo's Macroeconomic Adjustment Mechanism

*Extended Academic Report*

---

**Authors:** Valerio Di Federico et al.
**Course:** Data Mining and Computational Statistics
**Dataset:** 137 monthly observations, January 2014 – May 2025
**Software:** R 4.5.2

> **Author's Note:** Sections 1–6, including the data pipeline, descriptive analysis, ARX specification, Distributed Lag estimation, and associated visualisations, were developed as part of a collaborative university course project. Section 7 — comprising formal ADF unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing, UECM long-run estimation, and Local Projections IV — constitutes the independent analytical extension of the primary author. Collaborating colleagues are not identified by name in this public release in accordance with their preference for anonymity.

---

## Section 1 — Project Organisation

### 1.1 Group Formation

The project team was formed around a shared academic interest in international macroeconomics and empirical econometric methods, combining complementary competencies in quantitative modelling, data management, and economic theory. The research programme expanded progressively as each analytical layer raised additional questions warranting further investigation.

### 1.2 Division of Labour

Research tasks were distributed across three parallel workstreams, with members contributing according to their respective competencies:

- **Data acquisition and pre-processing:** Collection and harmonisation of monthly time-series from the Kosovo Central Bank (BQK), IMF, World Bank, and Kosovo Tax Administration. The pre-2014 observations (n = 85) were excluded due to the complete absence of key series, and one anomalous terminal observation was removed, yielding a consistent sample of 137 observations.

- **Econometric modelling and diagnostics:** The quantitative analysis proceeded through successive layers of increasing rigour. Following an initial static OLS baseline, which identified a level-regression specification problem, the team estimated a first-difference Autoregressive model with eXogenous controls (ARX), incorporating lagged REER terms and a full matrix of monthly seasonal dummy variables to control for intra-year cyclicality in remittance flows. Newey-West HAC standard errors (Newey & West, 1987) were applied throughout. A Breusch-Godfrey serial correlation test (p = 0.412) confirmed the absence of residual autocorrelation, and Variance Inflation Factor diagnostics confirmed no harmful multicollinearity. A Distributed Lag (DL) model with Net Exports as the dependent variable estimated the contemporaneous and lagged import pass-through of remittance inflows. The analytical programme was subsequently extended through formal ADF unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing (Pesaran, Shin & Smith, 2001), UECM long-run coefficient estimation, and Local Projections IV (Jordà, 2005) with a pairs bootstrap SE correction.

- **Visualisation and reporting:** Construction of econometric figures using `ggplot2`, including a seasonal distribution plot of remittance inflows, a contemporaneous shock distribution chart for the import pass-through relationship, a coefficient comparison plot for the level versus differenced specifications, and the two-panel impulse response function plot from the LP-IV analysis.

### 1.3 Collaboration and Version Control

The team maintained a shared GitHub repository integrated with an RStudio Project environment. Git version control enabled parallel contributions, traceable version history, and full reproducibility of all results.

---

## Section 2 — Research Design and Objectives

### 2.1 Theoretical Motivation

The research motivation is grounded in the Dutch Disease hypothesis (Corden & Neary, 1982), which posits that sustained foreign currency inflows generate real exchange rate appreciation through two mechanisms. The spending effect arises when increased household disposable income raises domestic demand for non-tradeable goods, bidding up their relative price and appreciating the REER. The resource movement effect operates through factor market adjustment, as labour migrates toward the expanding sector, raising wages and production costs economy-wide. Applied to diaspora remittances, the hypothesis predicts that persistent large inflows will appreciate the REER and gradually erode the competitiveness of the tradeable sector.

### 2.2 The Kosovo Empirical Setting

Kosovo provides an empirically relevant setting for testing this hypothesis under atypical structural conditions. Remittances constitute a substantial share of national income, while the economy operates under full euroisation, precluding independent monetary adjustment. Simultaneously, Kosovo maintains chronic and substantial trade deficits, reflecting deep structural import dependence. These features suggest that remittance-induced demand shocks may be absorbed primarily through additional import expenditure rather than through domestic price-level adjustment, motivating the formal test of an import-demand absorption mechanism.

### 2.3 Research Questions

The study addresses the following empirical questions:

1. Do remittance inflows cause a statistically significant appreciation of Kosovo's REER in the short run and in the long run?
2. Is there a statistically confirmed cointegrating relationship between the REER and its macroeconomic determinants over the 2014–2025 period?
3. Which variable constitutes the dominant structural long-run driver of Kosovo's REER?
4. Is there a statistically significant contemporaneous pass-through from remittance inflows to import demand, and over what horizon does this effect dissipate?
5. Are the principal findings robust to potential endogeneity between remittances and the REER, and to the omission of Eurozone macroeconomic conditions?

---

## Section 3 — Literature Review

The starting point for the empirical hypotheses is the canonical Dutch Disease model of Corden and Neary (1982). Guha (2013) demonstrates that remittance inflows alter household consumption patterns in ways that shift resources between economic sectors. Acosta, Lartey, and Mandelman (2007) argue that remittance inflows generally produce real exchange rate appreciation in recipient economies. Chowdhury and Rabbi (2014) provide country-level evidence supporting this finding for Bangladesh. Polat and Rodríguez Andrés (2019) document substantial heterogeneity in the effect across developing economies, with country-specific structural characteristics moderating the degree of appreciation.

The principal theoretical and empirical benchmark for this study is the 2025 IMF Working Paper by Carare et al. (WP/25/122), which argues that in economies with high import-to-GDP ratios operating under fixed or heavily managed exchange rate regimes, remittance inflows do not produce statistically significant REER appreciation. Additional demand is directed toward foreign rather than domestic goods, suppressing any domestic price effect. This paper provides the direct motivation for the import-demand absorption hypothesis tested in this study.

---

## Section 4 — Data

### 4.1 Sources and Sample Construction

The analysis uses monthly macroeconomic data from the Kosovo Central Bank (BQK), the IMF, the World Bank, and the Kosovo Tax Administration. The raw dataset spanned December 2006 to June 2025. Key variables — specifically Remittances and FDI — are only available from January 2014, requiring the exclusion of 85 pre-sample observations. One additional anomalous terminal observation was removed. The final estimation sample comprises **137 monthly observations from January 2014 to May 2025**.

### 4.2 Variable Descriptions and Summary Statistics

| Variable | Description | Mean | Std. Dev. | Min | Max |
|:---------|:------------|-----:|----------:|----:|----:|
| **REER_EU** | Real Effective Exchange Rate (EU partners) | 106.41 | 1.35 | 103.79 | 109.64 |
| **Remittances** | Monthly diaspora inflows (USD million) | 80.06 | 24.96 | 41.57 | 141.95 |
| **Inflation** | Domestic CPI change (%) | 2.47 | 3.51 | −1.22 | 14.20 |
| **NEER** | Nominal Effective Exchange Rate | 104.83 | 2.86 | 100.85 | 110.70 |
| **FDI** | Monthly foreign direct investment (USD million) | 36.38 | 27.35 | −65.61 | 102.67 |
| **NX** | Net exports (USD million) | −292.20 | 106.79 | −561.56 | −109.34 |

### 4.3 Transformation Strategy

All continuous variables are transformed into first differences (Δ X_t = X_t − X_{t-1}) in the ARX and DL specifications, consistent with the standard practice of modelling stationary series and interpreting coefficients as the impact of contemporaneous changes rather than trending levels. This choice is formally validated by the ADF unit root tests in Section 7.2. Monthly seasonal dummy variables are included in all specifications to account for the pronounced intra-year cyclicality in remittance flows.

---

## Section 5 — Descriptive Analysis

### 5.1 Intra-Year Cyclicality in Remittance Flows

The time-series plot of monthly remittances (2014–2025) reveals an upward trend in mean inflows and pronounced intra-year cyclical volatility. Seasonal decomposition and boxplot analysis indicate that inflow peaks are concentrated in the summer months (July–August) and the December holiday period, corresponding to periods of diaspora return migration. The seasonal amplitude is sufficiently large that any regression specification omitting monthly controls will confound the impact of remittances with predictable seasonal effects.

### 5.2 Unconditional Correlation between Remittances and Net Exports

The unconditional correlation between monthly remittances and net exports is approximately −0.91, indicating that periods of high diaspora inflows coincide strongly with periods of large trade deficits. This descriptive association is consistent with an import-demand absorption mechanism and motivates its formal econometric investigation in Section 6.3.

---

## Section 6 — ARX Specification and Import Pass-Through Estimation

### 6.1 Level-Regression Specification Bias

An initial static OLS regression in levels,

```
REER_EU_t = β₀ + β₁ Remittances_t + β₂ Inflation_t + β₃ NEER_t + ε_t
```

yields a statistically significant negative coefficient on Remittances (β = −0.047, p < 0.001). This result is inconsistent with the Dutch Disease hypothesis and arises from level-regression specification bias: applying OLS to non-stationary regressors with high inter-variable collinearity and without seasonal controls produces unreliable estimates. This specification serves as a reference point illustrating the consequences of model misspecification rather than as a substantive empirical finding.

### 6.2 First-Difference ARX Specification

The preferred short-run model is an ARX estimated in first differences:

```
Δ REER_t = β₀ + β₁ Δ REER_{t-1} + β₂ Δ REER_{t-4} + β₃ Δ REER_{t-12}
           + β₄ Δ Remittances_t + β₅ Δ Inflation_t + β₆ Δ FDI_t
           + β₇ Δ NX_t + Σ δ_m Month_m + ε_t
```

Newey-West HAC standard errors are applied throughout. The Breusch-Godfrey test (p = 0.412) confirms no residual serial correlation. VIF diagnostics confirm no harmful multicollinearity.

**Results:** The coefficient on Δ Remittances is 0.0029 (p = 0.525), not statistically different from zero. Domestic inflation is the principal short-run REER driver (coefficient 0.4202, p < 0.001).

| Diagnostic | Value |
|:-----------|------:|
| Adjusted R² | 0.6315 |
| Robust F-statistic | 47.91 (p < 0.001) |
| Breusch-Godfrey test | p = 0.412 |
| Δ Remittances coefficient | 0.0029 (p = 0.525) |
| Δ Inflation coefficient | 0.4202 (p < 0.001) |

### 6.3 Import Pass-Through Estimation (Distributed Lag Model)

To estimate the magnitude and duration of the import-demand effect, the following DL model is estimated with Net Exports as the dependent variable:

```
Δ NX_t = α₀ + α₁ Δ Remittances_t + α₂ Δ Remittances_{t-1}
         + α₃ Δ Remittances_{t-12} + α₄ Δ Inflation_t + α₅ Δ REER_t
         + Σ η_m Month_m + u_t
```

**Results:**

| Lag | Coefficient | p-value | Interpretation |
|:----|------------:|--------:|:---------------|
| Contemporaneous (t) | −0.860 | 0.008 | 0.86 unit import increase per unit remittance inflow |
| Lag 1 (t−1) | +0.412 | — | Partial reversal |
| Lag 12 (t−12) | +0.694 | — | Additional reversal at annual frequency |
| Cumulative (Wald test) | ≈ 0 | 0.633 | No permanent trade-balance effect |

Model performance: Adjusted R² = 0.747, Robust F = 118.21 (p < 0.001).

The results indicate a contemporaneous import propensity of 0.86, consistent with the hypothesis that remittance inflows are rapidly absorbed by import demand. The cumulative twelve-month effect is statistically indistinguishable from zero, indicating no permanent deterioration of the trade balance.

---

## Section 7 — Formal Stationarity, Cointegration, and Robustness Analysis

### 7.1 Rationale for the Extended Econometric Programme

The ARX analysis established the short-run relationship with confidence but left two questions open. First, the integration orders of the variables had not been formally established — the decision to first-difference was based on standard practice rather than a statistical test. Second, the existence of a long-run cointegrating equilibrium had not been formally tested. Establishing cointegration is substantively important: it elevates the empirical claim from the absence of a short-run effect to the absence of a long-run equilibrium relationship, a stronger and more policy-relevant conclusion.

Additionally, two potential sources of misspecification in the ARDL specification are addressed: (i) the possibility of reverse causality from the REER to remittances (rational diaspora senders may adjust the volume of transfers in response to changes in purchasing power at home), and (ii) the omission of Eurozone macroeconomic conditions, which affect the income and labour market position of diaspora households and therefore the supply of remittances.

### 7.2 ADF Unit Root Testing

Integration orders are estimated using the Augmented Dickey-Fuller test (`urca::ur.df`, AIC lag selection, maximum 12 lags), with `tseries::adf.test()` p-values as a cross-check. Level specifications include a deterministic trend; first-difference specifications include a drift term.

| Variable | τ (levels) | 5% CV | p (levels) | τ (Δ) | 5% CV | p (Δ) | Order |
|:---------|----------:|------:|-----------:|------:|------:|------:|:------|
| REER_EU | −2.483 | −3.412 | 0.382 | −7.625 | −2.879 | <0.01 | I(1) |
| Remittances | −3.490 | −3.412 | 0.049 | −9.551 | −2.879 | <0.01 | I(0) |
| Inflation | −2.836 | −3.412 | 0.210 | −7.591 | −2.879 | <0.01 | I(1) |
| NEER | −2.419 | −3.412 | 0.409 | −8.285 | −2.879 | <0.01 | I(1) |
| FDI | −6.036 | −3.412 | <0.01 | −9.891 | −2.879 | <0.01 | I(0) |
| NX | −2.968 | −3.412 | 0.160 | −6.869 | −2.879 | <0.01 | I(1) |

**Finding:** The dataset exhibits a mixed I(0)/I(1) integration structure. Remittances and FDI are stationary in levels; REER, Inflation, NEER, and NX contain unit roots. This mixed structure precludes the Johansen (1988) cointegration procedure and necessitates the ARDL bounds approach.

The I(0) classification of Remittances is consistent with the economic interpretation of diaspora inflows as a mean-reverting flow variable driven by seasonal return migration patterns, without accumulation into a persistent non-stationary level.

### 7.3 Heteroskedasticity Diagnostics

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (χ², df = 19) | 27.40 | 0.095 | Fail to reject H₀ of homoskedasticity |
| White test (nR²) | 2.20 | 0.333 | Fail to reject H₀ of homoskedasticity |

Neither test rejects homoskedasticity at the 5% significance level. The Newey-West HAC correction applied throughout is therefore a precautionary measure against potential autocorrelation in the monthly series rather than a response to detected heteroskedasticity.

### 7.4 ARDL Bounds Test

**Specification:** `REER_EU ~ Remittances + Inflation + NEER + FDI + NX` | Case III (unrestricted intercept, no deterministic trend) | Lag order selected by AIC, maximum order 4.

**Optimal model:** ARDL(2, 0, 0, 0, 2, 4).

**Bounds F-test (Case III):**

| Significance level | I(0) lower bound | I(1) upper bound |
|:---|---:|---:|
| 10% | 2.26 | 3.35 |
| **5%** | **2.62** | **3.79** |
| 1% | 3.41 | 4.68 |

**F-statistic = 5.2006** — exceeds the I(1) upper bound at the 5% level.

**Bounds t-test:** t = −2.869 (p = 0.032) — the error correction term is statistically significant.

**Conclusion:** A statistically significant long-run cointegrating relationship between Kosovo's REER and its macroeconomic determinants is established at the 5% significance level.

### 7.5 UECM Long-Run Coefficient Estimates

| Variable | Long-run β | Std. Error | p-value | Statistically significant? |
|:---------|----------:|----------:|--------:|:--------------------------|
| **NEER** | +0.6341 | 0.1110 | <0.001 | Yes |
| **NX** | +0.0024 | 0.0008 | 0.005 | Yes |
| **Remittances** | +0.0119 | 0.0106 | 0.268 | No |
| FDI | −0.0016 | 0.0012 | 0.187 | No |
| Inflation | +0.0160 | 0.0608 | 0.793 | No |

**Speed-of-adjustment parameter:** δ = −0.389 (p = 0.005), indicating that approximately 39% of any REER deviation from long-run equilibrium is corrected within one month.

**Model fit:** R² = 0.564, Adj. R² = 0.504, F(13, 92) = 9.48, p < 2.2×10⁻¹⁶.

The NEER is the dominant structural long-run driver of the REER, consistent with the mechanical nominal-to-real exchange rate pass-through expected in a euroised economy. The long-run multiplier on Remittances (β = +0.012, p = 0.268) is not statistically different from zero. Even within a confirmed cointegrating long-run equilibrium, remittances do not constitute a statistically significant determinant of the REER.

### 7.6 Local Projections IV: Endogeneity and Omitted Variable Correction

**Framework.** A Local Projections IV (LP-IV) specification (Jordà, 2005; Stock & Watson, 2018) addresses the two residual specification concerns: potential reverse causality from REER to Remittances, and the omission of Eurozone macroeconomic conditions.

**Step 1 — Remittance shock construction.** Remittances are regressed on own lags (1, 2, 12 months), Eurozone variables (EA unemployment rate, EUR/USD exchange rate, EA HICP inflation), and Kosovo domestic controls. The OLS residual constitutes the exogenous remittance shock: the component of remittance variation orthogonal to all observable push-factor conditions.

**Step 2 — Horizon-specific projections (h = 0,...,12).** For each horizon h:

```
REER_{t+h} − REER_{t-1} = α_h + β_h · shock_t + Γ · controls_{t-1} + η_{t+h}
```

Newey-West HAC standard errors with bandwidth equal to h + 1. A pairs bootstrap (B = 1,000 replications) corrects for the generated-regressor bias introduced by the two-step procedure. The same specification is estimated for Net Exports to validate the import pass-through finding.

**Diagnostic tests:**

- Wu-Hausman endogeneity test: F = 1.072, p = 0.304 — the null of exogeneity is not rejected. The ARX and ARDL estimates are not subject to endogeneity bias.
- Sargan overidentification test: χ² = 0.921, p = 0.632 — the exclusion restrictions are not rejected.

**REER results:** The REER impulse response is statistically insignificant at all 13 estimated horizons. The joint bootstrap p-value for a global null of zero response is 0.831. The peak point estimate is β = −0.005 at h = 11 months, which is economically negligible.

**NX (import pass-through) results:** The NX response is statistically significant at h = 0 (β = −0.59, 90% bootstrap CI excludes zero), consistent with the 0.86 contemporaneous import propensity estimated in the DL model. The response becomes statistically indistinguishable from zero by h = 2, consistent with the twelve-month neutralisation finding.

**Summary:** The LP-IV results confirm that the ARX and ARDL findings are robust to potential endogeneity and to Eurozone omission. The Dutch Disease hypothesis is not supported at any estimated horizon, and the Wu-Hausman test confirms that OLS-based estimates were not biased.

---

## Section 8 — Conclusions

### 8.1 Summary of Findings

The study provides consistent empirical evidence against the Dutch Disease hypothesis for Kosovo across three methodological specifications:

1. **Short-run (ARX):** Following first-differencing, seasonal controls, and Newey-West HAC correction, the remittance coefficient in the REER equation is 0.0029 (p = 0.525).

2. **Long-run (ARDL UECM):** Conditional on a confirmed cointegrating equilibrium (Bounds F = 5.20, exceeding the 5% upper bound of 3.79), the long-run multiplier on Remittances is β = +0.012 (p = 0.268).

3. **Endogeneity-corrected (LP-IV):** After removing the Eurozone push-factor component from remittance variation, the REER response is statistically insignificant at all 13 estimated horizons (joint bootstrap p = 0.831), with no detected endogeneity (Wu-Hausman p = 0.304).

The dominant structural long-run determinant of the REER is the NEER (β = 0.634, p < 0.001), reflecting nominal-to-real exchange rate pass-through arising from full euroisation.

The import pass-through analysis indicates a contemporaneous marginal import propensity of 0.86 per unit of remittance inflow (p = 0.008 in the DL model; β = −0.59 at h = 0 in the LP-IV). The effect dissipates within twelve months, with a cumulative Wald test p-value of 0.633. The empirical evidence is consistent with a structural import-absorption mechanism: remittance inflows stimulate import demand contemporaneously but produce no durable effect on either the trade balance or the REER.

These findings are consistent with the theoretical predictions of Carare et al. (2025) for highly import-dependent euroised economies, in which structural import reliance dissipates demand-side pressure before domestic prices are affected.

### 8.2 Limitations

- Informal remittance transfers (currency transported directly by returning diaspora members) are not captured by official Central Bank data and may amplify intra-year cyclical volatility in actual inflows.
- Sector-level price data would permit a more precise decomposition of tradeable and non-tradeable inflation responses.
- Real interest rate dynamics are not incorporated in the current model.
- The sample length of 137 observations constrains the statistical power of long-lag specifications.
- The partial F-statistic for Eurozone instruments in the LP-IV first stage (F = 6.40) falls marginally below the conventional strong-instrument threshold of 10. This concern is substantially mitigated by the Wu-Hausman test result, which indicates that instrumentation was not required in practice.

### 8.3 Policy Implications

The absence of a Dutch Disease effect implies that restricting remittance inflows on competitiveness grounds is not warranted by the empirical evidence. Given that a large share of each remittance unit is directed to import expenditure, the appropriate policy objective is to increase the fraction of inflows retained in the domestic economy through productive channels, including:

- Formalised diaspora investment instruments (diaspora bonds or dedicated savings accounts) to channel private transfers into domestic capital formation.
- Structural policies to develop import-substituting domestic production capacity in goods categories currently financed by diaspora spending.
- Financial products linking remittance flows to small business formation and investment.

---

## References

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper No. 2007-8a). Federal Reserve Bank of Atlanta.

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How do remittances affect the real exchange rate? An empirical investigation* (IMF Working Paper WP/25/122). Washington, DC: International Monetary Fund.

Chowdhury, M. B., & Rabbi, F. (2014). Workers' remittances and Dutch disease in Bangladesh. *The Journal of International Trade & Economic Development*, 23(4), 455–475.

Corden, W. M., & Neary, J. P. (1982). Booming sector and de-industrialisation in a small open economy. *The Economic Journal*, 92(368), 825–848.

Guha, P. (2013). Macroeconomic effects of international remittances: The case of developing economies. *Economic Modelling*, 33, 292–305.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Polat, B., & Rodríguez Andrés, A. (2019). Do emigrants' remittances cause Dutch Disease? A developing countries case study. *The Economic and Labour Relations Review*, 30(1), 59–76.

UNDP and GERMIN. (2023). *Kosovo diaspora and its role amidst multiple crises*. Pristina: United Nations Development Programme.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
