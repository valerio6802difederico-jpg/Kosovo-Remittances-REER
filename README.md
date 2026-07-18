# Kosovariance — Remittances, REER, and Kosovo's Macroeconomic Dynamics

![R Version](https://img.shields.io/badge/R-4.5.2-276DC3?style=flat-square&logo=r&logoColor=white)
![Methodology](https://img.shields.io/badge/Methodology-ARDL%20%7C%20LP--IV-4CAF50?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## Abstract

Kosovo is among the most remittance-dependent economies in Europe, with diaspora transfers consistently representing more than 15 per cent of GDP. This study examines empirically whether these inflows generate a Dutch Disease effect — a statistically significant appreciation of the Real Effective Exchange Rate (REER) — or whether they are absorbed through an import-demand channel that widens the trade deficit without appreciating the REER. Using 137 monthly observations spanning January 2014 to May 2025, the analysis proceeds through a sequential econometric pipeline: a first-difference Autoregressive model with eXogenous controls (ARX) and Newey-West HAC standard errors establishes the short-run picture; ARDL bounds testing (Pesaran, Shin & Smith, 2001) establishes the long-run cointegrating relationship; and a Local Projections IV framework (Jordà, 2005) addresses potential endogeneity and the omission of Eurozone macroeconomic conditions. Across all three specifications, the coefficient on remittances in the REER equation is statistically indistinguishable from zero. A contemporaneous import propensity of approximately 0.86 per unit of remittance inflow is estimated from a Distributed Lag model, with full neutralisation of the trade-balance effect within twelve months.

> **Author's Note:** The baseline data pipeline, initial OLS specifications, descriptive analysis, ARX modelling, and Distributed Lag leakage estimation were developed as part of a collaborative university course project. The formal econometric extension — comprising ADF unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing, UECM long-run coefficient estimation, and Local Projections IV — constitutes the independent analytical contribution of the primary author. Collaborating colleagues are not individually named in this public release.

---

## Economic Background

### Dutch Disease Theory

The Dutch Disease hypothesis (Corden & Neary, 1982) posits that a sustained increase in foreign currency inflows generates real exchange rate appreciation through two transmission channels:

1. **The Spending Effect:** Increased domestic demand for non-tradeable goods raises their relative price, appreciating the real exchange rate.
2. **The Resource Movement Effect:** Labour reallocates toward the expanding sector, increasing wages and production costs economy-wide.

Persistent REER appreciation reduces the price competitiveness of domestic exporters and import-competing industries.

### The Kosovo Case

Kosovo provides a relevant empirical setting for testing this hypothesis. The economy operates under full euroisation, with no independent monetary policy instrument and no exchange rate adjustment mechanism. It is simultaneously characterised by structural import dependence, reflected in a chronically negative trade balance. These structural features suggest that remittance-induced demand shocks may be absorbed primarily through additional import expenditure rather than through domestic price adjustment — a hypothesis that motivates the empirical design of this study.

---

## Research Questions

1. Do remittance inflows cause a statistically significant appreciation of Kosovo's Real Effective Exchange Rate in the short run and in the long run?
2. Is there a statistically confirmed cointegrating relationship between the REER and its macroeconomic determinants over the 2014–2025 sample period?
3. Which variable constitutes the dominant structural long-run driver of Kosovo's REER?
4. Is there a statistically significant contemporaneous pass-through from remittance inflows to import demand, and over what horizon does the effect dissipate?
5. Are the main findings robust to potential endogeneity between remittances and the REER, and to the omission of Eurozone macroeconomic conditions?

---

## Data Sources

| Source | Variable(s) | Frequency | Period |
|---|---|---|---|
| Kosovo Central Bank (BQK) | Remittances (USD m), FDI (USD m), Balance of Payments components | Monthly | Jan 2014 – May 2025 |
| IMF / World Bank | Real Effective Exchange Rate (REER), Nominal Effective Exchange Rate (NEER) | Monthly | Jan 2014 – May 2025 |
| Kosovo Tax Administration (ATK) | Consumer Price Index / Inflation | Monthly | Jan 2014 – May 2025 |
| Eurostat / FRED | EA Unemployment Rate, EA HICP, EUR/USD exchange rate | Monthly | Jan 2014 – May 2025 |

**Total observations:** 137 monthly observations after cleaning. The initial 85 pre-2014 observations were excluded due to complete absence of key series; one anomalous terminal observation was also removed.

---

## Methodology

The analysis follows a sequential, diagnostic-driven pipeline in which each modelling choice is determined by the results of the preceding step.

1. **Static OLS in levels** — Provides a reference specification and identifies sources of estimation bias arising from non-stationarity and omitted seasonality.

2. **First-difference ARX specification** — Models ΔREER as a function of own lags (t−1, t−4, t−12), contemporaneous changes in exogenous regressors, and a full matrix of monthly seasonal dummy variables to control for intra-year cyclicality in remittance flows.

3. **Newey-West HAC standard errors and serial correlation diagnostics** — HAC-robust standard errors (Newey & West, 1987) are applied throughout. A Breusch-Godfrey test (p = 0.412) confirms the absence of residual serial correlation. Variance Inflation Factor diagnostics confirm no harmful collinearity.

4. **Distributed Lag model for import demand** — A DL specification with Net Exports as the dependent variable estimates the contemporaneous and lagged pass-through of remittance inflows to the trade balance. A Wald test evaluates the cumulative twelve-month effect.

5. **ADF unit root testing** (`urca`, `tseries`) — Classifies each variable by integration order using the Augmented Dickey-Fuller test with AIC lag selection. *Result: mixed I(0)/I(1) dataset.*

6. **Heteroskedasticity diagnostics** — Breusch-Pagan and White tests applied to ARX residuals. *Result: homoskedasticity not rejected at the 5% level.*

7. **ARDL bounds test** (Pesaran, Shin & Smith, 2001) — Tests for a long-run level relationship in the mixed I(0)/I(1) setting, which precludes the Johansen procedure. *Result: F = 5.20 exceeds the upper I(1) critical bound of 3.79 at the 5% level.*

8. **UECM long-run coefficients** — Extracts structural long-run multipliers and the speed-of-adjustment parameter from the Unrestricted Error Correction Model.

9. **Local Projections IV** (Jordà, 2005; Stock & Watson, 2018) — Constructs an exogenous remittance shock by removing the Eurozone push-factor component via OLS residualisation, then estimates horizon-specific projections (h = 0,...,12) with Newey-West HAC standard errors and a 1,000-replication pairs bootstrap to correct for generated-regressor bias.

---

## Key Findings

1. **Level-regression specification bias identified:** The static OLS estimator in levels yields a spurious negative coefficient on remittances, attributable to non-stationarity and omitted seasonality. First-differencing with seasonal controls eliminates this bias entirely.

2. **No short-run REER effect of remittances:** In the ARX specification, the coefficient on ΔRemittances is 0.0029 (p = 0.525), not statistically different from zero. Domestic inflation is the dominant short-run REER driver (coefficient 0.4202, p < 0.001).

3. **Contemporaneous import pass-through confirmed:** A contemporaneous coefficient of −0.860 (p = 0.008) in the Distributed Lag model indicates that approximately 86 per cent of a unit remittance inflow is absorbed by import demand within the same month. The cumulative twelve-month effect is statistically indistinguishable from zero (Wald test p = 0.633).

4. **Mixed integration order:** REER, Inflation, NEER, and NX are I(1); Remittances and FDI are I(0). This precludes Johansen cointegration and supports the ARDL bounds approach.

5. **Long-run cointegration confirmed:** The ARDL Bounds Test F-statistic (5.20) exceeds the upper I(1) critical bound (3.79) at the 5% significance level, establishing a statistically significant long-run equilibrium relationship.

6. **No long-run REER effect of remittances:** The UECM long-run multiplier for Remittances is β = +0.012 (p = 0.268), not statistically significant. The Dutch Disease hypothesis is not supported in the long-run equilibrium.

7. **NEER is the dominant long-run REER driver:** The NEER long-run multiplier is β = 0.634 (p < 0.001), reflecting nominal exchange rate pass-through from the euroised monetary regime.

8. **Robustness across specifications:** The LP-IV framework yields a statistically insignificant REER response at all 13 estimated horizons (joint bootstrap p-value = 0.831). The Wu-Hausman test fails to reject exogeneity (p = 0.304), confirming that the ARX and ARDL estimates are not subject to endogeneity bias. The contemporaneous import pass-through is confirmed (β = −0.59 at h = 0). Results are consistent across all three methodological layers.

---

## Repository Structure

```
Kosovo-Remittances-REER/
├── data_raw/                                  # Raw Excel datasets
├── report/
│   ├── Report.Rmd                             # Full academic R Markdown report
│   └── Report.pdf                             # Compiled PDF report
├── KOSOVARIANCE_Rscript.R                     # Baseline OLS and ARX/DL analysis
├── KOSOVARIANCE_Advanced_Econometrics.R       # ADF, heteroskedasticity, ARDL, UECM
├── KOSOVARIANCE_LP_IV.R                       # Local Projections IV with bootstrap
├── KOSOVARIANCE_LP_IV_IRF.png                 # Impulse response function plots
├── Methodology_and_Findings.md                # Detailed methods and results summary
├── Original_Report_Updated.md                 # Extended academic report
└── README.md
```

---

## Reproduction Instructions

### Prerequisites

- **R** ≥ 4.5.2 ([CRAN](https://cran.r-project.org/))
- Required packages:

```r
install.packages(c(
  "readxl", "here", "dplyr", "tidyr", "tseries", "urca",
  "ARDL", "lmtest", "sandwich", "skedastic", "AER",
  "eurostat", "quantmod", "ggplot2", "patchwork",
  "stargazer", "car", "corrplot", "zoo", "scales"
))
```

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/valerio6802difederico-jpg/Kosovo-Remittances-REER.git
cd Kosovo-Remittances-REER
```

**2. Baseline OLS and ARX/DL analysis**
```r
source("KOSOVARIANCE_Rscript.R")
```
Loads and cleans raw data, estimates the static OLS baseline, the first-difference ARX model with Newey-West standard errors and Breusch-Godfrey diagnostics, and the Distributed Lag import pass-through model with Wald test.

**3. Unit root testing, heteroskedasticity diagnostics, ARDL bounds test, UECM**
```r
source("KOSOVARIANCE_Advanced_Econometrics.R")
```
Performs ADF tests, Breusch-Pagan and White diagnostics, ARDL bounds testing, and UECM long-run coefficient estimation. Results are printed to the console in formatted tables.

**4. Local Projections IV**
```r
source("KOSOVARIANCE_LP_IV.R")
```
Requires internet access to retrieve Eurozone variables via Eurostat and FRED APIs; a fallback AR-residual mode operates offline. Runs horizon-specific projections with 1,000-replication pairs bootstrap and saves `KOSOVARIANCE_LP_IV_IRF.png`.

**5. Compile the academic report (optional)**
```r
rmarkdown::render("report/Report.Rmd", output_format = "pdf_document")
```
A pre-compiled `report/Report.pdf` is included. Raw data files in `data_raw/` are required for all scripts.

---

## References

1. Corden, W. M., & Neary, J. P. (1982). Booming sector and de-industrialisation in a small open economy. *The Economic Journal*, 92(368), 825–848.
2. Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.
3. Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.
4. Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How do remittances affect the real exchange rate? An empirical investigation* (IMF Working Paper WP/25/122). International Monetary Fund.
5. Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.
6. Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper 2007-8a). Federal Reserve Bank of Atlanta.
7. Chowdhury, M. B., & Rabbi, F. (2014). Workers' remittances and Dutch disease in Bangladesh. *Journal of International Trade & Economic Development*, 23(4), 455–475.
8. White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.

---

## License

This project is licensed under the **MIT License**. Use, modification, and redistribution are permitted with attribution.

---

*Kosovariance — Valerio Di Federico. Data Mining and Computational Statistics research project.*