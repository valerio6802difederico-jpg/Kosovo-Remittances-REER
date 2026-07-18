# Kosovariance: Methodology and Key Findings

**Project:** Do Diaspora Remittances Appreciate Kosovo's Real Effective Exchange Rate?
**Authors:** Valerio Di Federico et al.
**Dataset:** 137 monthly observations, January 2014 – May 2025
**Software:** R 4.5.2

> **Author's Note:** The baseline data pipeline, static OLS specifications, first-difference ARX modelling, Distributed Lag estimation, and descriptive analysis were developed as part of a collaborative university course project. The formal econometric extension — comprising ADF unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing, UECM long-run estimation, and Local Projections IV — constitutes the independent analytical contribution of the primary author. Collaborating colleagues are not identified by name in this public release.

---

## 1. Research Question

This study examines empirically whether Kosovo's sustained diaspora remittance inflows generate a Dutch Disease effect — defined as a statistically significant appreciation of the Real Effective Exchange Rate (REER) — or whether the incoming foreign currency is instead absorbed through an import-demand channel that widens the trade deficit without producing measurable REER appreciation.

This distinction carries direct policy relevance. If the Dutch Disease mechanism is operative, the appropriate policy response involves managing or sterilising capital inflows to prevent competitiveness losses. If remittance inflows are instead absorbed through import expenditure without any REER effect, the policy mandate shifts toward structural measures aimed at retaining a greater share of diaspora liquidity within the domestic productive economy.

---

## 2. Methodological Pipeline

The analysis follows a sequential, diagnostic-driven econometric pipeline. Each modelling choice is determined by the results of the preceding step rather than imposed a priori.

### Step 1 — Static OLS in Levels

An initial OLS regression with REER in levels on Remittances, Inflation, and NEER provides a reference specification and illustrates the consequences of applying a static estimator to non-stationary macroeconomic time-series without seasonal controls. The resulting coefficient estimates are unreliable and serve to motivate the transition to a correctly specified dynamic model.

### Step 2 — First-Difference ARX Specification

The preferred short-run model is an Autoregressive specification with eXogenous controls (ARX), estimated in first differences. The specification includes three lags of REER (t−1, t−4, t−12) to capture autocorrelation dynamics, contemporaneous changes in the exogenous regressors, and a full matrix of monthly seasonal dummy variables to control for the pronounced intra-year cyclicality in remittance flows. First-differencing is motivated by standard practice for macroeconomic monthly series and later formally validated by ADF testing.

### Step 3 — Newey-West HAC Standard Errors and Serial Correlation Diagnostics

HAC-robust standard errors (Newey & West, 1987) are applied throughout all specifications to ensure valid inference under potential heteroskedasticity and autocorrelation. A Breusch-Godfrey serial correlation test (p = 0.412) confirms the absence of residual autocorrelation in the ARX model. Variance Inflation Factor diagnostics confirm no harmful multicollinearity among the regressors.

### Step 4 — Distributed Lag Model for Import Pass-Through

A Distributed Lag (DL) model with Net Exports (ΔNX) as the dependent variable estimates the contemporaneous and lagged import pass-through of remittance inflows, including terms at lags t, t−1, and t−12. A Wald test evaluates the null hypothesis that the sum of all remittance coefficients equals zero, providing a formal test of long-run trade balance neutrality.

### Step 5 — ADF Unit Root Testing

The integration order of each variable is formally established using the Augmented Dickey-Fuller test (`urca::ur.df`), with AIC-based lag selection (maximum 12 lags, appropriate for monthly data) and `tseries::adf.test()` p-values as a cross-check. Level specifications include a deterministic trend; first-difference specifications include a drift term.

**Rationale:** The integration order determines which cointegration framework is valid. A mixed I(0)/I(1) dataset precludes the Johansen (1988) procedure, which assumes all series are I(1), and mandates the ARDL bounds approach.

### Step 6 — Heteroskedasticity Diagnostics

The Breusch-Pagan test (studentized, `lmtest::bptest`) and the White test (`skedastic::white_lm`) are applied to the ARX model residuals. These tests are diagnostic: Newey-West HAC standard errors are retained regardless, as they address both heteroskedasticity and autocorrelation simultaneously.

### Step 7 — ARDL Bounds Test

The ARDL bounds test (Pesaran, Shin & Smith, 2001) is implemented using `ARDL::auto_ardl`, `ARDL::bounds_f_test`, and `ARDL::bounds_t_test`. It tests for the existence of a long-run level relationship among the variables by means of an F-test and t-test on the lagged level terms in an Unrestricted Error Correction Model (UECM). The procedure is valid for any combination of I(0) and I(1) variables.

**Specification:** `REER_EU ~ Remittances + Inflation + NEER + FDI + NX` | Case III (unrestricted intercept, no deterministic trend) | Lag order selected by AIC, maximum order 4.

### Step 8 — UECM Long-Run Coefficient Estimation

From the optimal ARDL model, the UECM is derived to extract structural long-run multipliers for each regressor and the speed-of-adjustment parameter (δ). The long-run multipliers represent the equilibrium change in REER associated with a permanent unit change in each variable.

### Step 9 — Local Projections IV

A Local Projections IV (LP-IV) framework (Jordà, 2005; Stock & Watson, 2018) addresses two potential sources of misspecification: reverse causality from the REER to remittances, and the omission of Eurozone macroeconomic push-factors affecting remittance supply.

**Step 9a — Shock construction:** An exogenous remittance shock is obtained by regressing Remittances on its own lags (1, 2, 12 months), Eurozone variables (EA unemployment rate, EUR/USD exchange rate, EA HICP — retrieved programmatically via `eurostat` and `quantmod`), and Kosovo domestic controls. The OLS residual is orthogonal to all observable push-factor variation.

**Step 9b — Horizon-specific regressions (h = 0,...,12):**
```
REER_{t+h} − REER_{t-1} = α_h + β_h · shock_t + Γ · controls_{t-1} + η_{t+h}
```
Newey-West HAC standard errors with bandwidth h + 1. A pairs bootstrap (B = 1,000 replications) corrects for the generated-regressor bias arising from the two-step construction of the shock variable.

---

## 3. Results

### 3.1 Level-Regression Specification Bias

**Static OLS (levels):** Remittances coefficient = −0.0472 (p < 0.001).

**ARX (first differences, seasonal controls, Newey-West HAC):** Remittances coefficient = +0.0029 (p = 0.525).

The sign reversal from negative to statistically zero demonstrates that the level-regression estimate was entirely attributable to non-stationarity and omitted seasonality, not to a genuine structural relationship between remittances and the REER.

### 3.2 ARX Model — Selected Results

| Diagnostic | Value |
|:-----------|------:|
| Adjusted R² | 0.6315 |
| Robust F-statistic | 47.91 (p < 0.001) |
| Breusch-Godfrey (serial correlation) | p = 0.412 — not detected |
| Δ Remittances coefficient | 0.0029 (p = 0.525) |
| Δ Inflation coefficient | 0.4202 (p < 0.001) |

### 3.3 Distributed Lag Model — Import Pass-Through

| Lag structure | Coefficient | p-value |
|:--------------|------------:|--------:|
| Δ Remittances (contemporaneous, t) | −0.860 | 0.008 |
| Δ Remittances (t−1) | +0.412 | — |
| Δ Remittances (t−12) | +0.694 | — |
| Cumulative effect (Wald test) | ≈ 0 | 0.633 |

Model performance: Adjusted R² = 0.747, Robust F = 118.21 (p < 0.001).

A contemporaneous import propensity of 0.86 is estimated, declining and reversing over subsequent months. The cumulative twelve-month effect is not statistically different from zero, indicating no permanent trade-balance deterioration.

### 3.4 Integration Orders (ADF Tests)

| Variable | τ (levels) | 5% CV | τ (Δ) | 5% CV | Integration order |
|:---------|----------:|------:|------:|------:|:-----------------:|
| REER_EU | −2.483 | −3.412 | −7.625 | −2.879 | I(1) |
| Remittances | −3.490 | −3.412 | −9.551 | −2.879 | I(0) |
| Inflation | −2.836 | −3.412 | −7.591 | −2.879 | I(1) |
| NEER | −2.419 | −3.412 | −8.285 | −2.879 | I(1) |
| FDI | −6.036 | −3.412 | −9.891 | −2.879 | I(0) |
| NX | −2.968 | −3.412 | −6.869 | −2.879 | I(1) |

**Finding:** Mixed I(0)/I(1) integration structure. The Johansen procedure is precluded; ARDL bounds testing is the appropriate framework.

### 3.5 Heteroskedasticity Diagnostics

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (χ², df = 19) | 27.40 | 0.095 | Fail to reject H₀ of homoskedasticity |
| White test (nR²) | 2.20 | 0.333 | Fail to reject H₀ of homoskedasticity |

### 3.6 ARDL Bounds Test

**Optimal ARDL order (AIC):** ARDL(2, 0, 0, 0, 2, 4) for (REER_EU, Remittances, Inflation, NEER, FDI, NX).

| Significance level | I(0) lower | I(1) upper |
|:---|---:|---:|
| 10% | 2.26 | 3.35 |
| **5%** | **2.62** | **3.79** |
| 1% | 3.41 | 4.68 |

**F-statistic = 5.2006** — exceeds the 5% I(1) upper bound.
**Bounds t-statistic:** t = −2.869 (p = 0.032).

A statistically significant long-run cointegrating relationship is established at the 5% significance level.

### 3.7 UECM Long-Run Multipliers

| Variable | Long-run β | Std. Error | p-value | Significant at 5%? |
|:---------|----------:|----------:|--------:|:-----------------:|
| **NEER** | +0.6341 | 0.1110 | <0.001 | Yes |
| **NX** | +0.0024 | 0.0008 | 0.005 | Yes |
| Remittances | +0.0119 | 0.0106 | 0.268 | No |
| FDI | −0.0016 | 0.0012 | 0.187 | No |
| Inflation | +0.0160 | 0.0608 | 0.793 | No |

**Speed of adjustment:** δ = −0.389 (p = 0.005). UECM model: R² = 0.564, Adj. R² = 0.504, F(13, 92) = 9.48, p < 2.2×10⁻¹⁶.

The long-run remittance multiplier (β = +0.012, p = 0.268) is not statistically significant. The NEER is the dominant structural long-run determinant of the REER.

### 3.8 LP-IV Results

| Metric | REER response | NX (import pass-through) |
|:-------|:-------------|:------------------------|
| Horizons significant at 90% bootstrap CI | 0 / 13 | 1 / 13 (h = 0 only) |
| Peak point estimate | β = −0.005 at h = 11 | β = −0.59 at h = 0 |
| Joint bootstrap p-value | 0.831 | — |
| Wu-Hausman endogeneity test | p = 0.304 — not rejected | — |
| Sargan overidentification test | p = 0.632 — not rejected | — |

---

## 4. Conclusions

### 4.1 Dutch Disease Hypothesis

The Dutch Disease hypothesis is not supported by the data across any of the three specifications:

| Specification | Remittances → REER | Statistical conclusion |
|:--------------|:-------------------|:----------------------|
| ARX (short-run) | β = 0.003, p = 0.525 | Not significant |
| ARDL UECM (long-run) | β = 0.012, p = 0.268 | Not significant |
| LP-IV (h = 0,...,12) | 0 / 13 horizons significant | Not significant at any horizon |

The results are robust across specifications, robust to endogeneity correction (Wu-Hausman p = 0.304), and robust to the inclusion of Eurozone push-factor controls. The dominant structural long-run determinant of Kosovo's REER is the Nominal Effective Exchange Rate (β = 0.634, p < 0.001), consistent with the mechanical pass-through expected under full euroisation.

### 4.2 Import-Demand Absorption Mechanism

A contemporaneous import propensity of 0.86 is estimated (DL model, p = 0.008; LP-IV at h = 0: β = −0.59). The trade-balance effect dissipates within twelve months (Wald test p = 0.633). The empirical evidence is consistent with a structural import-absorption mechanism in which remittance-induced demand shocks are directed toward foreign goods rather than domestic non-tradeables, preventing any domestic price effect from accumulating.

These results are consistent with the predictions of Carare et al. (2025) for import-dependent euroised economies operating under fixed exchange rate arrangements.

### 4.3 Limitations

- Informal remittance transfers are not captured in official data and may affect the measured magnitude of intra-year cyclical volatility.
- Sector-level price data would permit a more precise decomposition of tradeable and non-tradeable price responses to remittance shocks.
- Real interest rate dynamics are not incorporated.
- The partial F-statistic for Eurozone instruments in the LP-IV first stage (F = 6.40) falls marginally below the conventional strong-instrument threshold of 10, though the Wu-Hausman non-rejection renders this of limited practical consequence.

---

## 5. Policy Implications

Given the absence of a Dutch Disease effect and the evidence of a high contemporaneous import propensity, the relevant policy question is how to retain a greater share of remittance inflows within the domestic productive economy. Relevant policy instruments include:

1. Formalised diaspora investment instruments, such as diaspora bonds or dedicated domestic savings accounts, designed to direct private transfers into domestic capital formation rather than import consumption.
2. Structural industrial policy to develop domestic production capacity in goods categories currently financed by diaspora household expenditure.
3. Financial products linking remittance receipt to business formation and investment.

---

## 6. References

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How do remittances affect the real exchange rate? An empirical investigation* (IMF Working Paper WP/25/122). Washington, DC: International Monetary Fund.

Corden, W. M., & Neary, J. P. (1982). Booming sector and de-industrialisation in a small open economy. *The Economic Journal*, 92(368), 825–848.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper 2007-8a). Federal Reserve Bank of Atlanta.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
