# Kosovariance — Remittances, REER, and Kosovo's Macroeconomic Dynamics

![R Version](https://img.shields.io/badge/R-4.5.2-276DC3?style=flat-square&logo=r&logoColor=white)
![Methodology](https://img.shields.io/badge/Methodology-ARDL%20Bounds%20Test-4CAF50?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📄 Abstract

Kosovo is one of the world's most remittance-dependent economies, with diaspora transfers consistently exceeding 15% of GDP. This project empirically examines whether these massive inflows trigger a **Dutch Disease** effect — appreciating the Real Effective Exchange Rate (REER) and eroding export competitiveness — or whether they are instead absorbed through an **Import Leakage Channel** that widens the trade deficit without causing REER appreciation. Using 137 monthly observations (January 2014 – May 2025), an ARDL bounds-testing framework (Pesaran, Shin & Smith, 2001) reveals that remittances carry **no statistically significant long-run effect on the REER** (β = +0.012, p = 0.268), rejecting the Dutch Disease hypothesis. Instead, an estimated **86 cents of every diaspora dollar leak directly into imports** within the same month, with full neutralisation occurring within 12 months.

---

## ⚠️ Disclaimer

> **Attribution Notice**
>
> The original data pipeline, OLS baseline models, and visualisations were developed collaboratively with university colleagues as part of a university course project. The advanced time-series econometric layer — comprising ADF unit root testing, Breusch-Pagan and White heteroskedasticity diagnostics, ARDL bounds testing, and UECM long-run coefficient estimation — was designed and implemented subsequently by **Valerio Di Federico** as an independent solo extension of the joint baseline work.

---

## 🌍 Economic Background

### Dutch Disease Theory

The *Dutch Disease* hypothesis (Corden & Neary, 1982) posits that large foreign currency inflows — traditionally from natural resource exports, but equally applicable to remittances or aid — generate real exchange rate appreciation through two channels:

1. **Spending Effect**: Increased domestic demand for non-tradeable goods raises their relative prices, appreciating the real exchange rate.
2. **Resource Movement Effect**: Labour shifts toward the booming sector, raising wages and production costs across the economy.

A persistent REER appreciation undermines the competitiveness of domestic exporters and import-competing industries, potentially de-industrialising the economy.

### The Kosovo Anomaly

Kosovo presents a compelling natural experiment. Despite receiving some of the highest per-capita remittances globally, it maintains a **fully euroised economy** (no independent monetary policy), limiting the standard spending-effect transmission mechanism. This raises the question of whether the standard Dutch Disease logic applies, or whether the economy's structural openness — characterised by a chronically negative trade balance — acts as a pressure valve, absorbing inflows through import surges rather than price-level appreciation.

---

## ❓ Research Questions

1. Do remittance inflows cause a statistically significant appreciation of Kosovo's Real Effective Exchange Rate in the long run?
2. Is there a cointegrating relationship between the REER and its macroeconomic determinants (remittances, FDI, NEER, inflation) over the sample period?
3. Which variable is the dominant long-run driver of Kosovo's REER?
4. Does an Import Leakage Channel exist, and if so, what fraction of each diaspora dollar is absorbed by imports, and over what time horizon?

---

## 📊 Data Sources

| Source | Variable(s) | Frequency | Period |
|---|---|---|---|
| Kosovo Central Bank (BQK) | Remittances (EUR m), FDI (EUR m), Balance of Payments components | Monthly | Jan 2014 – May 2025 |
| IMF / World Bank | Real Effective Exchange Rate (REER), Nominal Effective Exchange Rate (NEER) | Monthly | Jan 2014 – May 2025 |
| Kosovo Tax Administration (ATK) | Consumer Price Index (CPI) / Inflation | Monthly | Jan 2014 – May 2025 |

- **Total observations:** 137 monthly observations after cleaning
- **Raw data format:** Excel (`.xlsx`), stored in `data_raw/` (16 files)

---

## 🔬 Methodology

The analysis follows a sequential econometric pipeline, ensuring each modelling choice is grounded in prior diagnostic results:

1. **OLS Baseline Regression** — Establish a naive linear relationship between REER and its potential drivers; identify specification issues.
2. **ADF Unit Root Testing** (`tseries`, `urca`) — Classify each series by integration order. *Result: REER_EU, Inflation, NEER, NX are I(1); Remittances and FDI are I(0).*
3. **Heteroskedasticity Diagnostics** — Breusch-Pagan test (`lmtest`) and White test (`skedastic`). *Result: No heteroskedasticity detected (BP p = 0.095; White p = 0.333).*
4. **HAC-Robust Standard Errors** — Newey-West (`sandwich`) SEs applied throughout to address potential serial correlation in monthly data.
5. **ARDL Bounds Test** (Pesaran, Shin & Smith, 2001) — Test for a long-run level relationship in a mixed I(0)/I(1) setting. *Result: F = 5.20 > upper I(1) bound of 3.79 at 5% → cointegration confirmed.*
6. **UECM Long-Run Coefficients** — Extract long-run multipliers from the Unrestricted Error Correction Model to identify the structural drivers of REER.
7. **ARDL Distributed Lag Leakage Model** — Estimate the dynamic pass-through of remittance shocks to net exports to quantify and time the Import Leakage Channel.

---

## 📈 Key Findings

1. **Mixed integration order confirmed:** REER, Inflation, NEER, and Net Exports are I(1); Remittances and FDI are I(0) — standard Johansen cointegration is infeasible, motivating the ARDL bounds approach.
2. **No heteroskedasticity:** Breusch-Pagan test (p = 0.095) and White test (p = 0.333) both fail to reject homoskedasticity; Newey-West HAC SEs applied as a precaution for serial correlation.
3. **Cointegration confirmed:** ARDL Bounds Test F-statistic = **5.20**, exceeding the upper I(1) critical bound of **3.79** at the 5% significance level (Pesaran et al., 2001), confirming a long-run equilibrium relationship.
4. **Dutch Disease rejected:** Long-run ARDL multiplier for Remittances on REER: **β = +0.012, p = 0.268** — statistically indistinguishable from zero. Remittances do **not** appreciably affect Kosovo's REER in the long run.
5. **NEER is the dominant REER driver:** Long-run coefficient on NEER: **β = 0.634, p < 0.001** — the nominal exchange rate is the primary structural anchor of the real exchange rate.
6. **Import Leakage Channel confirmed:** An estimated **86 cents of every diaspora dollar** flow directly into imports within the same month, consistent with Kosovo's consumption-oriented import structure.
7. **Full neutralisation within 12 months:** The import leakage effect is fully absorbed and neutralised over a 12-month horizon, leaving no permanent trade-balance deterioration.

---

## 🗂️ Repository Structure

```
Kosovo-Remittances-REER/
├── data_raw/                                # Raw Excel datasets (16 files)
├── report/
│   ├── Report.Rmd                           # Full academic R Markdown report
│   ├── Report.pdf                           # Compiled PDF report
│   ├── slides.Rmd                           # Presentation slides source
│   └── slides.pdf                           # Compiled slides
├── KOSOVARIANCE_Rscript.R                   # Original baseline OLS analysis
├── KOSOVARIANCE_Advanced_Econometrics.R     # Advanced time-series extension
├── Methodology_and_Findings.md              # Summary of econometric findings
├── Original_Report_Updated.md               # Updated academic report with disclaimer
└── README.md
```

---

## ▶️ How to Reproduce

### Prerequisites

- **R** ≥ 4.5.2 ([download](https://cran.r-project.org/))
- **RStudio** (recommended) or any R-compatible IDE
- The following R packages (install once):

```r
install.packages(c(
  "readxl", "here", "dplyr", "tseries", "urca",
  "ARDL", "lmtest", "sandwich", "skedastic",
  "ggplot2", "stargazer", "car"
))
```

### Steps

**1. Clone the repository**

```bash
git clone https://github.com/<your-username>/Kosovo-Remittances-REER.git
cd Kosovo-Remittances-REER
```

**2. Run the OLS baseline analysis**

```r
source("KOSOVARIANCE_Rscript.R")
```

This script loads the raw Excel files from `data_raw/`, merges and cleans the panel, and estimates the baseline OLS models with visualisations.

**3. Run the advanced econometric extension**

```r
source("KOSOVARIANCE_Advanced_Econometrics.R")
```

This script performs ADF unit root tests, heteroskedasticity diagnostics, ARDL bounds testing, UECM long-run estimation, and the distributed lag leakage model. All outputs (coefficient tables, test statistics) are printed to the console and optionally exported via `stargazer`.

**4. Compile the full academic report (optional)**

Open `report/Report.Rmd` in RStudio and knit to PDF:

```r
rmarkdown::render("report/Report.Rmd", output_format = "pdf_document")
```

> **Note:** A pre-compiled `report/Report.pdf` is included in the repository. Raw data files in `data_raw/` are required for the scripts to execute successfully.

---

## 📚 References

1. Corden, W. M., & Neary, J. P. (1982). Booming sector and de-industrialisation in a small open economy. *The Economic Journal*, 92(368), 825–848.
2. Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289–326.
3. Carare, A., et al. (2025). *Remittances and the Real Exchange Rate: Evidence from Developing Economies* (IMF Working Paper WP/25/122). International Monetary Fund.
4. Newey, W. K., & West, K. D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.
5. Breusch, T. S., & Pagan, A. R. (1979). A simple test for heteroscedasticity and random coefficient variation. *Econometrica*, 47(5), 1287–1294.
6. World Bank. (2024). *Migration and Development Brief 41: Remittances Remain Resilient*. Washington, D.C.: World Bank Group.

---

## 📝 License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute the code and written content with attribution.

---

*Kosovariance — Valerio Di Federico (university baseline with co-authors); advanced extension by Valerio Di Federico.*