# Kosovariance — Remittances, REER, and Kosovo's Macroeconomic Dynamics

![R Version](https://img.shields.io/badge/R-4.5.2-276DC3?style=flat-square&logo=r&logoColor=white)
![Methodology](https://img.shields.io/badge/Methodology-ARDL%20%7C%20LP--IV-4CAF50?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📄 Abstract

Kosovo is one of the world's most remittance-dependent economies, with diaspora transfers consistently exceeding 15% of GDP. This project empirically examines whether these massive inflows trigger a **Dutch Disease** effect — appreciating the Real Effective Exchange Rate (REER) and eroding export competitiveness — or whether they are instead absorbed through an **Import Leakage Channel** that widens the trade deficit without causing REER appreciation. Using 137 monthly observations (January 2014 – May 2025), the analysis progresses through a rigorous econometric pipeline: from first-difference ARX models with Newey-West robust standard errors, through ARDL bounds-testing (Pesaran, Shin & Smith, 2001), to Local Projections IV (Jordà, 2005) correcting for potential endogeneity and Eurozone omission. All three methodological layers converge on the same conclusion: remittances carry **no statistically significant effect on the REER** at any horizon. Instead, an estimated **86 cents of every diaspora dollar leak directly into imports** within the same month, with full neutralisation occurring within 12 months.

---

## 🌍 Economic Background

### Dutch Disease Theory

The *Dutch Disease* hypothesis (Corden & Neary, 1982) posits that large foreign currency inflows generate real exchange rate appreciation through two channels:

1. **Spending Effect**: Increased domestic demand for non-tradeable goods raises their relative prices, appreciating the real exchange rate.
2. **Resource Movement Effect**: Labour shifts toward the booming sector, raising wages and production costs economy-wide.

A persistent REER appreciation undermines the competitiveness of domestic exporters and import-competing industries, potentially de-industrialising the economy.

### The Kosovo Anomaly

Kosovo presents a compelling natural experiment. Despite receiving some of the highest per-capita remittances globally, it maintains a **fully euroised economy** with no independent monetary policy, limiting the standard spending-effect transmission mechanism. The economy is also characterised by structural import dependence — a chronically negative trade balance — raising the question of whether incoming diaspora liquidity simply exits immediately through foreign purchases rather than creating any domestic inflationary pressure.

---

## ❓ Research Questions

1. Do remittance inflows cause a statistically significant appreciation of Kosovo's Real Effective Exchange Rate — in both the short run and the long run?
2. Is there a confirmed cointegrating relationship between the REER and its macroeconomic fundamentals over the 2014–2025 period?
3. Which variable is the dominant long-run structural driver of Kosovo's REER?
4. Does an Import Leakage Channel exist? What fraction of each diaspora dollar is absorbed by imports, and over what time horizon does the effect neutralise?
5. Are these findings robust to potential endogeneity between remittances and the REER, and to the omission of Eurozone macroeconomic conditions?

---

## 📊 Data Sources

| Source | Variable(s) | Frequency | Period |
|---|---|---|---|
| Kosovo Central Bank (BQK) | Remittances (USD m), FDI (USD m), Balance of Payments | Monthly | Jan 2014 – May 2025 |
| IMF / World Bank | Real Effective Exchange Rate (REER), Nominal Effective Exchange Rate (NEER) | Monthly | Jan 2014 – May 2025 |
| Kosovo Tax Administration (ATK) | Consumer Price Index / Inflation | Monthly | Jan 2014 – May 2025 |
| Eurostat / FRED | EA Unemployment Rate, EA HICP, EUR/USD Rate | Monthly | Jan 2014 – May 2025 |

- **Total observations:** 137 monthly observations after cleaning (initial 85 pre-2014 obs and one anomalous row removed)
- **Raw data format:** Excel (`.xlsx`), stored in `data_raw/`

---

## 🔬 Methodology

The analysis follows a sequential, diagnostic-driven econometric pipeline. Each modelling choice is justified by the results of the preceding step — no specification is imposed a priori.

1. **OLS Baseline** — Estimate a naive level regression of REER on its candidate drivers. Identify the "Exchange Rate Optical Illusion": a spurious negative coefficient on remittances caused by non-stationarity and omitted seasonality.

2. **First-Difference ARX Specification** — Transition to an Autoregressive model with eXogenous controls in first differences (Δ), adding lags of REER (t−1, t−4, t−12) and a full matrix of monthly seasonal dummies to isolate the true macroeconomic signal from the "Diaspora Pulse" seasonal pattern.

3. **Newey-West HAC Standard Errors** — Apply heteroskedasticity- and autocorrelation-consistent (HAC) standard errors throughout, confirmed as appropriate by a Breusch-Godfrey serial correlation test (p = 0.412) and VIF multicollinearity diagnostics.

4. **Distributed Lag Leakage Model** — Shift the dependent variable to Net Exports (ΔNX) to test the Import Leakage Channel directly. Estimate a DL model with contemporaneous and lagged remittances; apply a Wald test for the cumulative 12-month effect.

5. **ADF Unit Root Testing** (`urca`, `tseries`) — Formally classify each variable by integration order using the Augmented Dickey-Fuller test with AIC lag selection. *Result: mixed I(0)/I(1) dataset.*

6. **Heteroskedasticity Diagnostics** — Apply Breusch-Pagan and White tests to the ARX residuals. *Result: no heteroskedasticity detected at 5%.*

7. **ARDL Bounds Test** (Pesaran, Shin & Smith, 2001) — Test for a long-run level relationship in the mixed I(0)/I(1) setting, which rules out the Johansen procedure. *Result: F = 5.20 > upper I(1) bound of 3.79 at 5% → cointegration confirmed.*

8. **UECM Long-Run Coefficients** — Extract structural long-run multipliers and the speed-of-adjustment parameter from the Unrestricted Error Correction Model.

9. **Local Projections IV** (Jordà, 2005; Stock & Watson, 2018) — Address potential endogeneity and Eurozone omission. Construct an exogenous remittance shock (purged of Eurozone push-factors via OLS residual), then run horizon-by-horizon projections (h = 0…12 months) with Newey-West HAC SEs and 1,000-replication pairs bootstrap to correct generated-regressor bias.

---

## 📈 Key Findings

1. **"Exchange Rate Optical Illusion" identified:** Naive OLS in levels produces a spurious significant negative coefficient on remittances — an artefact of non-stationarity and omitted seasonality, not a structural relationship.

2. **Dutch Disease rejected in the short run:** After first-differencing, seasonal controls, and Newey-West HAC robust errors, the coefficient on ΔRemittances becomes 0.0029 (p = 0.525) — statistically indistinguishable from zero.

3. **Import Leakage Channel confirmed:** An estimated **86 cents of every diaspora dollar** flow directly into imports within the same month (DL coefficient: −0.860, p = 0.008). The effect fully neutralises within 12 months (cumulative Wald test p = 0.633).

4. **Mixed integration order:** REER, Inflation, NEER, and NX are I(1); Remittances and FDI are I(0) — precluding Johansen cointegration and mandating the ARDL bounds approach.

5. **Cointegration confirmed:** ARDL Bounds Test F-statistic = **5.20**, exceeding the upper I(1) critical bound of **3.79** at the 5% level, confirming a long-run equilibrium relationship exists among the variables.

6. **Dutch Disease rejected in the long run:** Long-run ARDL multiplier for Remittances: **β = +0.012, p = 0.268** — statistically zero even in the long-run equilibrium.

7. **NEER is the dominant REER driver:** Long-run coefficient on NEER: **β = 0.634, p < 0.001** — nominal exchange rate pass-through, not diaspora inflows, anchors Kosovo's real exchange rate.

8. **LP-IV confirms robustness:** After correcting for potential endogeneity (Wu-Hausman p = 0.304 — endogeneity not detected) and Eurozone omission, **0 out of 13 horizons** show a significant REER response. The leakage channel is confirmed at h = 0 (β = −0.59, significant). Dutch Disease is **triply rejected** across all methodological layers.

---

## 🗂️ Repository Structure

```
Kosovo-Remittances-REER/
├── data_raw/                                  # Raw Excel datasets
├── report/
│   ├── Report.Rmd                             # Full academic R Markdown report
│   └── Report.pdf                             # Compiled PDF report
├── KOSOVARIANCE_Rscript.R                     # OLS baseline and ARX/DL analysis
├── KOSOVARIANCE_Advanced_Econometrics.R       # ADF, heteroskedasticity, ARDL, UECM
├── KOSOVARIANCE_LP_IV.R                       # Local Projections IV with bootstrap
├── KOSOVARIANCE_LP_IV_IRF.png                 # Two-panel impulse response plot
├── Methodology_and_Findings.md                # Detailed methods and results summary
├── Original_Report_Updated.md                 # Full academic report (extended version)
└── README.md
```

---

## ▶️ How to Reproduce

### Prerequisites

- **R** ≥ 4.5.2 ([download](https://cran.r-project.org/))
- **RStudio** (recommended)
- Install packages (run once):

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

**2. Run the baseline ARX and leakage channel analysis**
```r
source("KOSOVARIANCE_Rscript.R")
```
Loads and cleans raw Excel data, estimates the OLS baseline, identifies the optical illusion, runs the first-difference ARX model with Newey-West SEs and Breusch-Godfrey diagnostics, and estimates the Distributed Lag leakage model with Wald test.

**3. Run the formal unit root and long-run cointegration analysis**
```r
source("KOSOVARIANCE_Advanced_Econometrics.R")
```
Performs ADF unit root tests, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing, and UECM long-run coefficient estimation. All results printed to console in formatted tables.

**4. Run the LP-IV endogeneity and robustness analysis**
```r
source("KOSOVARIANCE_LP_IV.R")
```
Fetches Eurozone variables (requires internet; falls back to AR-residual mode offline), constructs the exogenous remittance shock, runs Local Projections at h = 0…12, applies 1,000-rep pairs bootstrap, and saves `KOSOVARIANCE_LP_IV_IRF.png`.

**5. Compile the academic report (optional)**
```r
rmarkdown::render("report/Report.Rmd", output_format = "pdf_document")
```
> A pre-compiled `report/Report.pdf` is included. Raw data files in `data_raw/` are required for scripts to run.

---

## 📚 References

1. Corden, W. M., & Neary, J. P. (1982). Booming sector and de-industrialisation in a small open economy. *The Economic Journal*, 92(368), 825–848.
2. Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.
3. Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161–182.
4. Carare, A., Celis, J. P., Hadzi-Vaskov, M., & Morito, Y. (2025). *How Do Remittances Affect the Real Exchange Rate?* (IMF Working Paper WP/25/122). International Monetary Fund.
5. Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.
6. Acosta, P. A., Lartey, E. K. K., & Mandelman, F. S. (2007). *Remittances and the Dutch disease* (Working Paper 2007-8a). Federal Reserve Bank of Atlanta.
7. Chowdhury, M. B., & Rabbi, F. (2014). Workers' remittances and Dutch disease in Bangladesh. *Journal of International Trade & Economic Development*, 23(4), 455–475.
8. White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838.

---

## 📝 License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute the code and written content with attribution.

---

*Kosovariance — Valerio Di Federico. Developed as part of a Data Mining and Computational Statistics research project.*