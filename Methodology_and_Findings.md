# Kosovariance: Methodology and Key Findings

**Project:** Do Diaspora Remittances Appreciate Kosovo's Real Effective Exchange Rate?
**Authors:** Valerio Di Federico et al.
**Dataset:** 137 monthly observations, January 2014 – May 2025
**Software:** R 4.5.2

---

## 1. Research Question

This project empirically tests whether Kosovo's large diaspora remittance inflows trigger a **Dutch Disease** effect — defined as a significant appreciation of the Real Effective Exchange Rate (REER) — or whether the incoming foreign currency is instead absorbed through an **Import Leakage Channel** that immediately worsens the trade deficit without creating inflationary pressure on the domestic economy.

The distinction matters for policy: if Dutch Disease is active, policymakers should restrict or sterilise capital inflows; if the leakage channel dominates, the mandate shifts to productive investment policy (e.g. Diaspora Bonds) to retain liquidity domestically before it exits through imports.

---

## 2. Methodological Pipeline

The analysis follows a sequential, diagnostic-driven econometric pipeline. Each modelling choice is grounded in the results of the preceding step — no specification is imposed a priori.

### Step 1 — OLS Baseline and Identification of the "Optical Illusion"

We begin with a naive OLS regression of REER in levels on Remittances, Inflation, and NEER. The baseline yields a significant **negative** coefficient on remittances — a result we identify as an "Exchange Rate Optical Illusion" caused by non-stationarity, collinearity, and the absence of seasonal controls. This finding motivates the transition to a disciplined time-series specification.

### Step 2 — First-Difference ARX Specification with Seasonal Controls

We build an Autoregressive model with eXogenous controls (ARX) in first differences, incorporating three lags of REER (t−1, t−4, t−12) to capture autocorrelation dynamics and a full matrix of **monthly seasonal dummy variables** to isolate the true macroeconomic signal from the "Diaspora Pulse" seasonal pattern. First-differencing is motivated by the non-stationarity suspected from the OLS step, and later formally validated by ADF testing.

### Step 3 — Newey-West HAC Standard Errors and Serial Correlation Diagnostics

**Newey-West HAC standard errors** (Newey & West, 1987) are applied throughout to ensure valid inference under potential heteroskedasticity and autocorrelation. A **Breusch-Godfrey serial correlation test** (p = 0.412) confirms the absence of residual serial correlation in the ARX model. **Variance Inflation Factor (VIF)** diagnostics confirm no harmful multicollinearity among the regressors.

### Step 4 — Distributed Lag Leakage Model and Wald Test

A separate **Distributed Lag (DL) model** is specified with Net Exports (ΔNX) as the dependent variable, including contemporaneous and lagged remittance terms (t, t−1, t−12) alongside inflation, REER, and seasonal controls. A **Wald test** on the sum of all remittance coefficients tests the cumulative 12-month leakage effect.

### Step 5 — ADF Unit Root Testing

We formally establish the **integration order** of every variable using the Augmented Dickey-Fuller test (`urca::ur.df`, AIC lag selection, max 12 lags for monthly data), cross-checked with `tseries::adf.test()` p-values. Tests are run in levels (with trend) and first differences (with drift).

**Rationale:** The integration order determines which cointegration framework is valid. A mixed I(0)/I(1) dataset rules out the Johansen (1988) procedure and mandates the ARDL bounds approach.

### Step 6 — Heteroskedasticity Diagnostics

We apply the **Breusch-Pagan test** (studentized, `lmtest::bptest`) and the **White test** (`skedastic::white_lm`) to the ARX model residuals.

**Rationale:** These tests are diagnostic, not prescriptive — Newey-West HAC SEs are retained regardless, as they simultaneously address autocorrelation. The tests confirm whether heteroskedasticity is a genuine concern.

### Step 7 — ARDL Bounds Test (Primary Long-Run Cointegration)

We implement the **Pesaran, Shin & Smith (2001)** ARDL bounds testing procedure (`ARDL::auto_ardl`, `ARDL::bounds_f_test`, `ARDL::bounds_t_test`) on the variable levels.

**Why ARDL, not Johansen?** The ADF results reveal a mixed I(0)/I(1) structure. The Johansen procedure assumes all I(1). ARDL bounds testing is explicitly valid for any mixture of I(0) and I(1), making it the correct choice for this dataset.

**Specification:** `REER_EU ~ Remittances + Inflation + NEER + FDI + NX` | Case III (unrestricted intercept, no deterministic trend) | Lag selection: AIC, maximum order 4.

### Step 8 — UECM Long-Run Coefficient Estimation

From the optimal ARDL model, we derive the **Unrestricted Error Correction Model (UECM)** to extract structural long-run multipliers for each regressor. These multipliers represent the equilibrium effect on REER_EU of a permanent one-unit change in each variable, along with the speed-of-adjustment parameter (δ).

### Step 9 — Local Projections IV (Endogeneity and Eurozone Correction)

We implement a **Local Projections IV (LP-IV)** framework (Jordà, 2005; Stock & Watson, 2018) to address two structural concerns: potential reverse causality between Remittances and REER, and the omission of Eurozone macroeconomic push-factors.

**Step 9a — Shock construction:** Remittances are regressed on own lags (1, 2, 12), Eurozone variables (EA unemployment rate, EUR/USD, EA HICP — from Eurostat and FRED), and Kosovo domestic controls. The OLS residual is the exogenous remittance shock, orthogonal to all observable push-factors.

**Step 9b — Local Projections:** For h = 0…12 months:
```
REER_{t+h} − REER_{t-1} = α_h + β_h · shock_t + Γ · controls_{t-1} + η_{t+h}
```
Newey-West HAC SEs (bandwidth = h+1). A **pairs bootstrap (B = 1,000)** corrects for generated-regressor bias from the two-step procedure.

---

## 3. Results

### 3.1 OLS Baseline — The Optical Illusion

**OLS (levels):** Remittances coefficient = −0.0472 (p < 0.001) — spuriously negative.
**ARX (first differences + seasonal dummies + NW-HAC):** Remittances coefficient = +0.0029 (p = 0.525) — effectively zero.

This dramatic sign reversal demonstrates that the entire apparent relationship in the OLS baseline was an artefact of non-stationarity and omitted seasonality, not a genuine macroeconomic channel.

### 3.2 ARX Model Performance

| Metric | Value |
|:-------|------:|
| Adjusted R² | 0.6315 |
| Robust F-statistic | 47.91 (p < 0.001) |
| Breusch-Godfrey (serial correlation) | p = 0.412 — not present |
| Δ Remittances coefficient | 0.0029 (p = 0.525) |
| Δ Inflation coefficient | 0.4202 (p < 0.001) |

### 3.3 Import Leakage Channel (Distributed Lag Model)

| Coefficient | Estimate | p-value | Interpretation |
|:------------|--------:|--------:|:---------------|
| Δ Remittances (contemporaneous) | −0.860 | 0.008 | 86 cents per dollar leak to imports instantly |
| Δ Remittances (lag 1) | +0.412 | — | Partial reversal begins |
| Δ Remittances (lag 12) | +0.694 | — | Further reversal at annual cycle |
| **Cumulative 12-month effect (Wald)** | **≈ 0** | **0.633** | **Fully neutralised** |

Model fit: Adj. R² = 0.747 | Robust F = 118.21 (p < 0.001)

### 3.4 Integration Orders (ADF Tests)

| Variable | τ (levels) | 5% CV | τ (Δ) | 5% CV | Order |
|:---------|----------:|------:|------:|------:|:------|
| REER_EU | −2.483 | −3.412 | −7.625 | −2.879 | **I(1)** |
| Remittances | −3.490 | −3.412 | −9.551 | −2.879 | **I(0)** |
| Inflation | −2.836 | −3.412 | −7.591 | −2.879 | **I(1)** |
| NEER | −2.419 | −3.412 | −8.285 | −2.879 | **I(1)** |
| FDI | −6.036 | −3.412 | −9.891 | −2.879 | **I(0)** |
| NX | −2.968 | −3.412 | −6.869 | −2.879 | **I(1)** |

**Mixed I(0)/I(1)** → ARDL bounds testing is the appropriate cointegration framework.

### 3.5 Heteroskedasticity Tests

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (df=19) | 27.40 | 0.095 | Fail to reject H₀ — homoskedastic |
| White test (nR²) | 2.20 | 0.333 | Fail to reject H₀ — homoskedastic |

Errors are homoskedastic. Newey-West correction is precautionary.

### 3.6 ARDL Bounds Test

**Optimal model:** ARDL(2, 0, 0, 0, 2, 4) for (REER_EU, Remittances, Inflation, NEER, FDI, NX)

| Test | Statistic | I(0) 5% | I(1) 5% | Decision |
|:-----|----------:|--------:|--------:|:---------|
| Bounds F-test | **5.2006** | 2.62 | 3.79 | **Cointegration CONFIRMED** |
| Bounds t-test | −2.869 | — | — | ECT significant |

### 3.7 Long-Run Multipliers (UECM)

| Variable | β | SE | p-value | Significant? |
|:---------|--:|---:|--------:|:------------|
| **NEER** | +0.6341 | 0.1110 | <0.001 | ✅ |
| **NX** | +0.0024 | 0.0008 | 0.005 | ✅ |
| **Remittances** | +0.0119 | 0.0106 | 0.268 | ❌ |
| FDI | −0.0016 | 0.0012 | 0.187 | ❌ |
| Inflation | +0.0160 | 0.0608 | 0.793 | ❌ |

**Speed of adjustment:** δ = −0.389 (p = 0.005) | UECM Adj. R² = 0.504

### 3.8 LP-IV Results

| Metric | REER | NX (Leakage) |
|:-------|:-----|:-------------|
| Significant horizons (90% bootstrap CI) | **0 / 13** | **1 / 13** (h=0 only) |
| Peak response | β = −0.005 at h=11 | β = −0.59 at h=0 |
| Joint bootstrap p-value | 0.831 | — |
| Wu-Hausman endogeneity test | p = 0.304 — **not detected** | — |
| Sargan overidentification | p = 0.632 — **instruments valid** | — |

---

## 4. Core Economic Conclusions

### Dutch Disease: Rejected at Every Methodological Layer

| Method | Remittances → REER | Verdict |
|:-------|:-------------------|:--------|
| ARX (short-run) | β = 0.003, p = 0.525 | ❌ Rejected |
| ARDL UECM (long-run) | β = 0.012, p = 0.268 | ❌ Rejected |
| LP-IV (all horizons) | 0/13 significant | ❌ Rejected |

The dominant long-run force shaping Kosovo's REER is the **Nominal Effective Exchange Rate** (β = 0.634, p < 0.001) — mechanical exchange rate pass-through from euroisation, not diaspora inflows.

### Import Leakage Channel: Confirmed

For every dollar of diaspora money entering Kosovo, **86 cents immediately exits** to finance foreign imports. This shock fully neutralises over a 12-month horizon (Wald test p = 0.633). Kosovo operates as a **pass-through economy**: diaspora liquidity enters, is spent on foreign goods, and exits — without leaving a macroeconomic footprint on the REER.

These findings directly validate the 2025 IMF Working Paper by Carare et al. (WP/25/122), which argues that in heavily import-dependent euroized economies, structural import reliance acts as a natural pressure release valve.

---

## 5. Policy Implications

Because 86% of each remittance dollar leaks into imports, the policy mandate should be to **capture remittances before they leak**, not to restrict inflows:

1. **Diaspora Bonds** — formalised instruments to channel private diaspora transfers into domestic productive investment
2. **Import-substitution industrial policy** — develop domestic value chains for goods currently purchased from diaspora spending
3. **Remittance-linked savings products** — incentivise local business creation over consumption spending

---

## 6. Limitations

- Informal remittances (cash carried by returning diaspora) are unobservable in official data
- Sector-level pricing data would allow cleaner tradable/non-tradable decomposition
- Real interest rate dynamics are excluded from the current specification
- Sample length (T=137) limits power for very long lag structures
- LP-IV instrument relevance (partial F=6.40) is marginally below the strong-instrument threshold; the Wu-Hausman non-rejection renders this practically moot

---

## 7. References

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How Do Remittances Affect the Real Exchange Rate?* (IMF Working Paper WP/25/122). International Monetary Fund.

Corden, W. M., & Neary, J. P. (1982). Booming Sector and De-Industrialisation in a Small Open Economy. *The Economic Journal*, 92(368), 825–848.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper 2007-8a). Federal Reserve Bank of Atlanta.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
