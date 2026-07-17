# Kosovariance: Methodology and Key Findings

**Project:** Do Diaspora Remittances Appreciate Kosovo's Real Effective Exchange Rate?  
**Author (advanced extension):** Valerio Di Federico  
**Baseline collaboration:** University group project  
**Dataset:** 137 monthly observations, January 2014 – May 2025  
**Software:** R 4.5.2

---

## 1. Research Question

This project empirically tests whether Kosovo's large diaspora remittance inflows trigger
a **Dutch Disease** effect — defined as a significant appreciation of the Real Effective
Exchange Rate (REER) — or whether the incoming foreign currency is instead absorbed through
an alternative **Import Leakage Channel** that immediately worsens the trade deficit without
creating inflationary pressure on the domestic economy.

The distinction matters for policy: if Dutch Disease is active, policymakers should restrict
capital inflows; if the leakage channel dominates, the mandate shifts to productive
investment policy (e.g. Diaspora Bonds) to retain the liquidity domestically.

---

## 2. Methodological Pipeline

The analysis follows a rigorous, sequential time-series econometric pipeline:

### Step 1 — Unit Root Testing (ADF)
We first establish the **integration order** of every variable using the Augmented
Dickey-Fuller test (`urca::ur.df`, lag selection via AIC, max 12 lags for monthly data),
with a `tseries::adf.test()` p-value cross-check. We test in levels (with trend + drift)
and first differences (drift only).

**Rationale:** Knowing whether variables are I(0) or I(1) determines which cointegration
framework is valid. Applying OLS in levels to non-stationary data produces spurious
regressions.

### Step 2 — Heteroskedasticity Diagnostics
We apply:
- **Breusch-Pagan test** (Koenker 1981, studentized) on the baseline ARX model
- **White test** (White 1980) via `skedastic::white_lm`

**Rationale:** Even if errors are homoskedastic, Newey-West HAC standard errors are
retained throughout (they simultaneously address autocorrelation). These tests are
diagnostic, not prescriptive.

### Step 3 — ARDL Bounds Test (Primary Cointegration)
We implement the **Pesaran, Shin & Smith (2001)** ARDL bounds testing procedure
(`ARDL::auto_ardl`, `ARDL::bounds_f_test`, `ARDL::bounds_t_test`).

**Why ARDL, not Johansen?** The ADF results reveal a **mixed I(0)/I(1)** integration
structure (see Section 3). The Johansen (1988) procedure assumes all variables are I(1).
ARDL bounds testing is explicitly valid for any mixture of I(0) and I(1) variables, making
it the methodologically correct choice for this dataset.

**Lag selection:** Automatic via AIC, maximum order 4 (appropriate for monthly frequency).  
**Model:** `REER_EU ~ Remittances + Inflation + NEER + FDI + NX`  
**Case III:** Unrestricted intercept, no deterministic trend.

### Step 4 — UECM Long-Run Coefficient Estimation
From the optimal ARDL model, we derive the **Unrestricted Error Correction Model (UECM)**
to extract the structural long-run multipliers for each regressor. These multipliers
represent the equilibrium effect on REER_EU of a permanent one-unit change in each variable.

### Step 5 — Leakage Channel Model (Distributed Lag)
A distributed lag model tests whether Remittance shocks explain the Trade Deficit (ΔNX),
establishing the Import Leakage Channel as the operative mechanism.

---

## 3. Results

### 3.1 Integration Orders (ADF Tests)

| Variable | τ statistic (levels) | 5% Critical Value | Integration Order |
|:---------|--------------------:|------------------:|:-----------------|
| REER_EU | −2.483 | −3.412 | **I(1)** |
| Remittances | −3.490 | −3.412 | **I(0)** |
| Inflation | −2.836 | −3.412 | **I(1)** |
| NEER | −2.419 | −3.412 | **I(1)** |
| FDI | −6.036 | −3.412 | **I(0)** |
| NX | −2.968 | −3.412 | **I(1)** |

The dataset is **mixed I(0)/I(1)**, validating the use of ARDL bounds testing.

**Economic interpretation:** Remittances being I(0) is consistent with their seasonal,
mean-reverting nature (the "Diaspora Pulse" — massive summer and December spikes that
revert to baseline). REER and NEER, as persistent price-index levels, are correctly I(1).

### 3.2 Heteroskedasticity Tests (on baseline ARX model)

| Test | Statistic | p-value | Conclusion |
|:-----|----------:|--------:|:-----------|
| Breusch-Pagan (df=19) | 27.40 | 0.095 | Fail to reject H₀ — homoskedastic |
| White test | 2.20 | 0.333 | Fail to reject H₀ — homoskedastic |

Errors are homoskedastic. Newey-West HAC standard errors are retained as a conservative
precaution against any autocorrelation, confirmed by the Breusch-Godfrey test in the
baseline script.

### 3.3 ARDL Bounds Test Results

**Optimal ARDL model (AIC):** ARDL(2, 0, 0, 0, 2, 4) — for (REER_EU, Remittances,
Inflation, NEER, FDI, NX) respectively.

| Test | Statistic | I(0) lower 5% | I(1) upper 5% | Decision |
|:-----|----------:|--------------:|--------------:|:---------|
| Bounds F-test | **5.2006** | 2.62 | 3.79 | **F > upper bound → Cointegration CONFIRMED** |
| Bounds t-test | −2.869 | −2.86 | −1.99 | ECT significant → Error-correction confirmed |

> **A statistically significant long-run cointegrating relationship between Kosovo's REER
> and its macroeconomic fundamentals is confirmed at the 5% significance level.**

### 3.4 Long-Run Multipliers (UECM)

| Variable | Long-Run β | Std. Error | p-value | Significant? |
|:---------|----------:|----------:|--------:|:------------|
| **NEER** | **+0.6341** | 0.1110 | **<0.001** | ✅ Yes |
| **NX** | **+0.0024** | 0.0008 | **0.005** | ✅ Yes |
| **Remittances** | +0.0119 | 0.0106 | **0.268** | ❌ **No** |
| FDI | −0.0016 | 0.0012 | 0.187 | ❌ No |
| Inflation | +0.0160 | 0.0608 | 0.793 | ❌ No |

**Speed of adjustment (ECT):** δ = −0.389 (p = 0.005)

UECM model fit: R² = 0.564, Adj. R² = 0.504, F(13, 92) = 9.48, p < 2.2×10⁻¹⁶

### 3.5 Leakage Channel (Baseline Distributed Lag Model)

From the original ARX Distributed Lag model (Δ NX ~ Δ Remittances + Δ Remittances_{t-1}
+ Δ Remittances_{t-12} + controls + monthly dummies):

| Coefficient | Estimate | Std. Error (NW) | p-value |
|:------------|--------:|----------------:|--------:|
| Δ Remittances (contemporaneous) | −0.860 | — | 0.008 |
| Δ Remittances (lag 1) | +0.412 | — | — |
| Δ Remittances (lag 12) | +0.694 | — | — |
| **Cumulative 12-month effect** | **≈ 0** | — | **0.633** |

Model fit: Adj. R² = 0.747, Robust F = 118.21 (p < 0.001)

---

## 4. Core Economic Conclusion

### The Dutch Disease Hypothesis Is Rejected

The long-run ARDL multiplier for remittances is **β = +0.012, p = 0.268** — statistically
indistinguishable from zero. Even after establishing a confirmed cointegrating equilibrium
(ARDL Bounds F = 5.20, p = 0.043), **remittances play no role in that equilibrium**.

The dominant long-run force shaping Kosovo's REER is the **Nominal Effective Exchange Rate**
(β = 0.634, p < 0.001) — reflecting mechanical exchange rate pass-through from Kosovo's
euroized monetary regime, not diaspora inflows.

### The Import Leakage Channel Is Confirmed

The mechanism by which remittances fail to appreciate the REER is the **Import Leakage
Channel**: for every dollar of diaspora money entering Kosovo in any given month, **86 cents
immediately exits the domestic economy** to finance foreign imports, preventing any domestic
price pressure from building. This shock fully neutralises over a 12-month horizon (cumulative
Wald test p = 0.633).

Kosovo operates as a **pass-through economy**: diaspora liquidity enters, is spent on foreign
goods, and exits — without leaving a domestic macroeconomic footprint in the REER.

### Alignment with Contemporary Literature

These findings directly validate the 2025 IMF Working Paper by Carare et al. (WP/25/122),
which argues that in heavily import-dependent economies operating under fixed or stabilised
exchange rate regimes, structural import reliance acts as a pressure release valve that
naturally neutralises Dutch Disease appreciation.

---

## 5. Policy Implications

Because **86% of each remittance dollar leaks into imports**, the policy mandate should not
be to restrict capital inflows (Dutch Disease fear is empirically unwarranted), but to
**capture remittances before they leak**:

1. **Diaspora Bonds** — formalized instruments to channel private diaspora transfers into
   domestic productive investment
2. **Import-substitution industrial policy** — develop domestic value chains for goods
   currently imported from the diaspora spending
3. **Remittance-linked savings products** — incentivise local business creation over
   consumption

---

## 6. Limitations

- **Informal remittances** (cash physically carried by returning diaspora) are unobservable
  in official Central Bank data; these likely amplify the Diaspora Pulse
- **Sector-level price data** would allow cleaner decomposition between tradable and
  non-tradable inflation
- **Real interest rate dynamics** are not included, which could explain additional
  short-run REER movements
- Sample length (137 observations) limits the statistical power of some lag structures

---

## 7. References

Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How Do Remittances
Affect the Real Exchange Rate? An Empirical Investigation* (IMF Working Paper WP/25/122).
Washington, DC: International Monetary Fund.

Corden, W. M., & Neary, J. P. (1982). Booming Sector and De-Industrialisation in a Small
Open Economy. *The Economic Journal*, 92(368), 825–848.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis
of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.

Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch
disease* (Working Paper No. 2007-8a). Federal Reserve Bank of Atlanta.

Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity
and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.

White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct
test for heteroskedasticity. *Econometrica*, 48(4), 817–838.
