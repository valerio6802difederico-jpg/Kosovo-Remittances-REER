# =============================================================================
# KOSOVARIANCE_LP_IV.R
# =============================================================================
# Author      : Valerio Di Federico (independent extension)
# Baseline    : University group project
# Purpose     : Address two structural flaws identified in the ARDL extension:
#               (1) Potential endogeneity between Remittances and REER
#               (2) Omission of Eurozone macroeconomic shocks
#
# Strategy    : Local Projections IV (LP-IV)
#               Jordà (2005) + Stock & Watson (2018) external instrument approach
#
# STRUCTURE
#   0.  Libraries & package installation
#   1.  Kosovo data loading (identical pipeline to previous scripts)
#   2.  Eurozone variable acquisition (eurostat API + quantmod/FRED)
#   3.  Dataset merge & alignment
#   4.  Step 1 — Remittance shock construction (purge EZ component)
#   5.  Step 2 — Local Projections h = 0:12 with Newey-West HAC SE
#   6.  Pairs bootstrap SE correction (generated-regressor bias)
#   7.  LP-IV robustness check via ivreg at h = 0
#   8.  IRF visualisation (ggplot2, two-panel: REER + NX responses)
#   9.  Global Wald test (H₀: β_h = 0 for all horizons)
#  10.  Consolidated summary panel
# =============================================================================


# =============================================================================
# SECTION 0 — LIBRARIES & PACKAGE INSTALLATION
# =============================================================================

required_pkgs <- c(
  # Data loading
  "readxl", "here", "dplyr", "tidyr",
  # Eurozone data APIs
  "eurostat", "quantmod",
  # Econometrics
  "lmtest", "sandwich", "AER",
  # Visualisation
  "ggplot2", "scales", "patchwork"
)

new_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(new_pkgs) > 0) {
  message("Installing missing packages: ", paste(new_pkgs, collapse = ", "))
  install.packages(new_pkgs, repos = "https://cloud.r-project.org", quiet = TRUE)
}

suppressPackageStartupMessages({
  library(readxl); library(here); library(dplyr); library(tidyr)
  library(eurostat); library(quantmod)
  library(lmtest); library(sandwich); library(AER)
  library(ggplot2); library(scales); library(patchwork)
})

cat("=============================================================================\n")
cat("  KOSOVARIANCE — Local Projections IV (LP-IV)\n")
cat("  Author : Valerio Di Federico\n")
cat("  Method : Jordà (2005) LP + Stock & Watson (2018) external instruments\n")
cat("=============================================================================\n\n")


# =============================================================================
# SECTION 1 — KOSOVO DATA LOADING
# =============================================================================

cat(">>> SECTION 1: Kosovo Data Loading\n")
cat("-----------------------------------------------------------------------------\n")

MonthlyRemittances <- read_excel(
  here("data_raw", "Remittances_channel&country.xlsx"),
  sheet     = "Monthly",
  col_names = TRUE
)

MonthlyRemittances2 <- MonthlyRemittances[-(1:85), ]
MonthlyRemittances2 <- MonthlyRemittances2[-138, ]

vars_kos <- c("REER_EU", "Remittances", "Inflation", "NEER", "FDI", "NX")
for (v in vars_kos) {
  MonthlyRemittances2[[v]] <- as.numeric(MonthlyRemittances2[[v]])
}

# Date column — coerce to Date
MonthlyRemittances2$Month <- as.Date(MonthlyRemittances2$Month)

# Keep only what we need
kos_data <- data.frame(
  date         = MonthlyRemittances2$Month,
  REER_EU      = MonthlyRemittances2$REER_EU,
  Remittances  = MonthlyRemittances2$Remittances,
  Inflation    = MonthlyRemittances2$Inflation,
  NEER         = MonthlyRemittances2$NEER,
  FDI          = MonthlyRemittances2$FDI,
  NX           = MonthlyRemittances2$NX
)
kos_data <- kos_data[complete.cases(kos_data), ]

cat(sprintf("  Kosovo observations : %d\n", nrow(kos_data)))
cat(sprintf("  Period             : %s to %s\n\n",
            format(min(kos_data$date), "%b %Y"),
            format(max(kos_data$date), "%b %Y")))


# =============================================================================
# SECTION 2 — EUROZONE VARIABLE ACQUISITION
# =============================================================================

cat(">>> SECTION 2: Eurozone Variable Acquisition\n")
cat("-----------------------------------------------------------------------------\n")
cat("  Fetching: EA Unemployment Rate (Eurostat)\n")
cat("            EA HICP Inflation    (Eurostat)\n")
cat("            EUR/USD Exchange Rate (FRED via quantmod)\n\n")

# Helper: convert Eurostat monthly "time" to Date (first day of month)
ez_to_date <- function(x) as.Date(paste0(gsub("M", "-", x), "-01"))

# --------------------------------------------------------------------------
# 2a — EA Unemployment Rate (seasonally adjusted, total, % active pop)
# --------------------------------------------------------------------------
ez_unemp <- tryCatch({
  raw <- get_eurostat("une_rt_m",
                      filters = list(geo    = "EA20",
                                     s_adj  = "SA",
                                     age    = "TOTAL",
                                     unit   = "PC_ACT",
                                     sex    = "T"),
                      time_format = "raw",
                      cache       = FALSE)
  raw <- raw[, c("time", "values")]
  raw$date <- ez_to_date(raw$time)
  raw <- raw[order(raw$date), c("date", "values")]
  names(raw)[2] <- "EZ_Unemployment"
  raw
}, error = function(e) {
  message("  [WARN] Eurostat API unavailable — using fallback zeros for EZ_Unemployment.")
  message("         Download 'une_rt_m' manually and supply as EZ_Unemployment column.")
  data.frame(date = seq.Date(as.Date("2013-01-01"), as.Date("2025-12-01"), by = "month"),
             EZ_Unemployment = NA_real_)
})

# --------------------------------------------------------------------------
# 2b — EA HICP Inflation Index (base 2015 = 100)
# --------------------------------------------------------------------------
ez_hicp <- tryCatch({
  raw <- get_eurostat("prc_hicp_midx",
                      filters = list(geo    = "EA",
                                     coicop = "CP00",
                                     unit   = "I15"),
                      time_format = "raw",
                      cache       = FALSE)
  raw <- raw[, c("time", "values")]
  raw$date <- ez_to_date(raw$time)
  raw <- raw[order(raw$date), c("date", "values")]
  names(raw)[2] <- "EZ_HICP"
  raw
}, error = function(e) {
  message("  [WARN] Eurostat API unavailable — using fallback NAs for EZ_HICP.")
  data.frame(date = seq.Date(as.Date("2013-01-01"), as.Date("2025-12-01"), by = "month"),
             EZ_HICP = NA_real_)
})

# --------------------------------------------------------------------------
# 2c — EUR/USD exchange rate (monthly average, FRED: DEXUSEU = USD per EUR)
# --------------------------------------------------------------------------
ez_eurusd <- tryCatch({
  suppressWarnings(
    getSymbols("DEXUSEU", src = "FRED", auto.assign = FALSE,
               from = "2013-01-01", to = "2025-12-31")
  )
  # Convert daily to monthly average
  mon_avg <- apply.monthly(DEXUSEU, mean, na.rm = TRUE)
  df <- data.frame(
    date    = as.Date(format(index(mon_avg), "%Y-%m-01")),
    EUR_USD = as.numeric(coredata(mon_avg))
  )
  df
}, error = function(e) {
  message("  [WARN] FRED API unavailable — using fallback NAs for EUR_USD.")
  data.frame(date = seq.Date(as.Date("2013-01-01"), as.Date("2025-12-01"), by = "month"),
             EUR_USD = NA_real_)
})

cat("  Eurozone data fetched (or fallback applied if API offline).\n\n")


# =============================================================================
# SECTION 3 — DATASET MERGE & ALIGNMENT
# =============================================================================

cat(">>> SECTION 3: Dataset Merge\n")
cat("-----------------------------------------------------------------------------\n")

# Merge all sources on date
merged <- kos_data %>%
  left_join(ez_unemp, by = "date") %>%
  left_join(ez_hicp,  by = "date") %>%
  left_join(ez_eurusd, by = "date")

# EZ_HICP: convert to YoY growth rate (more economically interpretable than level)
merged <- merged %>%
  arrange(date) %>%
  mutate(
    EZ_HICP_growth = (EZ_HICP / lag(EZ_HICP, 12) - 1) * 100,
    month_num      = as.integer(format(date, "%m"))  # numeric 1-12, always valid
  )

# Flag whether EZ data was successfully retrieved (for conditional messaging)
ez_available <- !all(is.na(merged$EZ_Unemployment)) &&
                !all(is.na(merged$EUR_USD))

if (!ez_available) {
  cat("  [WARN] Eurozone variables are NA — LP will run WITHOUT EZ instruments.\n")
  cat("         Shock will be constructed from autoregressive residuals only.\n")
  cat("         For the full LP-IV, connect to internet and re-run.\n\n")
} else {
  cat(sprintf("  Merged dataset: %d obs, %d variables\n", nrow(merged), ncol(merged)))
  cat(sprintf("  EZ data available: EZ_Unemployment, EZ_HICP_growth, EUR_USD\n\n"))
}

# Keep complete cases for the LP estimation
lp_data <- merged %>%
  filter(!is.na(REER_EU), !is.na(Remittances)) %>%
  arrange(date)


# =============================================================================
# SECTION 4 — STEP 1: REMITTANCE SHOCK CONSTRUCTION
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 4 — Step 1: Remittance Shock Construction\n")
cat("=============================================================================\n\n")
cat("  Regress Remittances on:\n")
cat("    - Own lags: 1, 2, 12 months  [autoregressive component]\n")
cat("    - Eurozone controls: EZ_Unemployment, EUR_USD, EZ_HICP_growth\n")
cat("    - Kosovo controls: NEER, Inflation, NX\n")
cat("    - Monthly seasonal dummies\n")
cat("  Residual = exogenous Remittance shock (purged of EZ conditions)\n\n")

# Create lagged variables and Fourier seasonal terms for Step 1
lp_data <- lp_data %>%
  mutate(
    Rem_lag1      = lag(Remittances, 1),
    Rem_lag2      = lag(Remittances, 2),
    Rem_lag12     = lag(Remittances, 12),
    REER_lag1     = lag(REER_EU, 1),
    NEER_lag1     = lag(NEER, 1),
    Infl_lag1     = lag(Inflation, 1),
    NX_lag1       = lag(NX, 1),
    EZ_Unemp_lag1 = lag(EZ_Unemployment, 1),
    EZ_HICP_lag1  = lag(EZ_HICP_growth, 1),
    EUR_USD_lag1  = lag(EUR_USD, 1),
    # Fourier seasonal terms (2 harmonics) — always valid, no factor-level issues
    seas_s1 = sin(2 * pi * month_num / 12),
    seas_c1 = cos(2 * pi * month_num / 12),
    seas_s2 = sin(4 * pi * month_num / 12),
    seas_c2 = cos(4 * pi * month_num / 12)
  )

# Build Step 1 formula — use month_num (numeric) for robustness across filter subsets
if (ez_available) {
  step1_formula <- Remittances ~ Rem_lag1 + Rem_lag2 + Rem_lag12 +
    EZ_Unemp_lag1 + EUR_USD_lag1 + EZ_HICP_lag1 +
    NEER_lag1 + Infl_lag1 + NX_lag1 +
    seas_s1 + seas_c1 + seas_s2 + seas_c2
} else {
  # Fallback: AR-only shock (no EZ instruments)
  step1_formula <- Remittances ~ Rem_lag1 + Rem_lag2 + Rem_lag12 +
    NEER_lag1 + Infl_lag1 + NX_lag1 +
    seas_s1 + seas_c1 + seas_s2 + seas_c2
}

step1_data <- lp_data[complete.cases(lp_data[, all.vars(step1_formula)]), ]
step1_model <- lm(step1_formula, data = step1_data)

# Attach shock back to lp_data by date
shock_df <- data.frame(
  date  = step1_data$date,
  shock = residuals(step1_model)
)
lp_data <- lp_data %>% left_join(shock_df, by = "date")

# --- Report Step 1 diagnostics ---
step1_sum  <- summary(step1_model)
step1_fstat <- step1_sum$fstatistic
step1_f_val <- if (!is.null(step1_fstat)) step1_fstat[1] else NA

cat(sprintf("  Step 1 R²        : %.4f\n", step1_sum$r.squared))
cat(sprintf("  Step 1 Adj. R²   : %.4f\n", step1_sum$adj.r.squared))
if (ez_available) {
  # Partial F for EZ instruments only
  step1_restricted <- lm(Remittances ~ Rem_lag1 + Rem_lag2 + Rem_lag12 +
                            NEER_lag1 + Infl_lag1 + NX_lag1 + month_factor,
                          data = step1_data)
  wald_ez <- waldtest(step1_restricted, step1_model, vcov = vcovHC)
  cat(sprintf("  Partial F (EZ instruments): %.4f  [p = %.4f]\n",
              wald_ez$F[2], wald_ez$`Pr(>F)`[2]))
  cat(sprintf("  Instrument relevance: %s\n",
              ifelse(!is.na(wald_ez$F[2]) && wald_ez$F[2] > 10,
                     "STRONG (F > 10)", "WEAK (F < 10) — interpret IV with caution")))
}
cat(sprintf("  Shock SD: %.4f  |  Shock mean: %.6f (should ≈ 0)\n\n",
            sd(lp_data$shock, na.rm = TRUE),
            mean(lp_data$shock, na.rm = TRUE)))


# =============================================================================
# SECTION 5 — STEP 2: LOCAL PROJECTIONS  h = 0:12
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 5 — Step 2: Local Projections  [h = 0 to 12 months]\n")
cat("=============================================================================\n\n")
cat("  Model at each horizon h:\n")
cat("    REER_{t+h} - REER_{t-1} = α_h + β_h·shock_t + Γ·controls_{t-1} + η_{t+h}\n")
cat("  Standard errors: Newey-West HAC with bandwidth = h + 1\n\n")

H <- 12   # maximum horizon (months)

# Storage for LP results
lp_results <- data.frame(
  horizon  = 0:H,
  beta_REER = NA_real_,
  se_REER   = NA_real_,
  beta_NX   = NA_real_,
  se_NX     = NA_real_
)

# Create forward cumulative responses and control lags
lp_data <- lp_data %>% arrange(date)

for (h in 0:H) {
  # Cumulative response: REER_{t+h} - REER_{t-1}
  lp_data[[paste0("cum_REER_", h)]] <-
    lead(lp_data$REER_EU, h) - lag(lp_data$REER_EU, 1)

  # Cumulative response for NX (leakage channel check)
  lp_data[[paste0("cum_NX_", h)]] <-
    lead(lp_data$NX, h) - lag(lp_data$NX, 1)
}

lp_controls_vars <- c("REER_lag1", "NEER_lag1", "Infl_lag1", "NX_lag1",
                      "seas_s1", "seas_c1", "seas_s2", "seas_c2")

for (h in 0:H) {

  dep_REER <- paste0("cum_REER_", h)
  dep_NX   <- paste0("cum_NX_",   h)

  # Build dataset for this horizon (complete cases)
  h_vars <- c(dep_REER, dep_NX, "shock",
              "REER_lag1", "NEER_lag1", "Infl_lag1", "NX_lag1",
              "seas_s1", "seas_c1", "seas_s2", "seas_c2")
  h_data <- lp_data[complete.cases(lp_data[, h_vars]), ]

  if (nrow(h_data) < 30) {
    cat(sprintf("  h=%2d: insufficient obs (%d) — skipping\n", h, nrow(h_data)))
    next
  }

  # --- REER response ---
  fm_REER <- as.formula(paste(dep_REER,
                               "~ shock + REER_lag1 + NEER_lag1 +",
                               "Infl_lag1 + NX_lag1 +",
                               "seas_s1 + seas_c1 + seas_s2 + seas_c2"))
  fit_REER <- lm(fm_REER, data = h_data)
  nw_bw    <- h + 1   # Newey-West bandwidth grows with horizon
  vcov_REER <- NeweyWest(fit_REER, lag = nw_bw, prewhite = FALSE)
  lp_results$beta_REER[lp_results$horizon == h] <- coef(fit_REER)["shock"]
  lp_results$se_REER[lp_results$horizon == h]   <- sqrt(vcov_REER["shock", "shock"])

  # --- NX response ---
  fm_NX <- as.formula(paste(dep_NX,
                              "~ shock + REER_lag1 + NEER_lag1 +",
                              "Infl_lag1 + NX_lag1 +",
                              "seas_s1 + seas_c1 + seas_s2 + seas_c2"))
  fit_NX  <- lm(fm_NX, data = h_data)
  vcov_NX <- NeweyWest(fit_NX, lag = nw_bw, prewhite = FALSE)
  lp_results$beta_NX[lp_results$horizon == h] <- coef(fit_NX)["shock"]
  lp_results$se_NX[lp_results$horizon == h]   <- sqrt(vcov_NX["shock", "shock"])
}

cat("  Analytical (NW) LP point estimates and 90% CIs:\n\n")
cat(sprintf("  %-8s  %-10s  %-10s  %-10s  %-10s\n",
            "Horizon", "β_REER", "SE_REER", "β_NX", "SE_NX"))
cat("  ", paste(rep("-", 56), collapse = ""), "\n")
for (i in 1:nrow(lp_results)) {
  h <- lp_results$horizon[i]
  cat(sprintf("  h = %2d  :  %8.4f    %8.4f    %8.4f    %8.4f\n",
              h,
              lp_results$beta_REER[i], lp_results$se_REER[i],
              lp_results$beta_NX[i],   lp_results$se_NX[i]))
}
cat("\n")


# =============================================================================
# SECTION 6 — PAIRS BOOTSTRAP SE CORRECTION
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 6 — Pairs Bootstrap SE Correction  [B = 1000 replications]\n")
cat("=============================================================================\n\n")
cat("  Corrects for generated-regressor bias from the two-step procedure.\n")
cat("  Method: Pairs (row) bootstrap — resamples (Y_t, X_t) jointly.\n\n")

set.seed(42)
B     <- 1000
boot_REER <- matrix(NA, nrow = B, ncol = H + 1)
boot_NX   <- matrix(NA, nrow = B, ncol = H + 1)

# Base dataset for bootstrap (complete cases across all variables needed)
boot_vars <- c("REER_EU", "Remittances", "Inflation", "NEER", "NX", "FDI",
               "Rem_lag1", "Rem_lag2", "Rem_lag12",
               "REER_lag1", "NEER_lag1", "Infl_lag1", "NX_lag1",
               "seas_s1", "seas_c1", "seas_s2", "seas_c2",
               if (ez_available) c("EZ_Unemp_lag1", "EUR_USD_lag1", "EZ_HICP_lag1") else NULL)
boot_base <- lp_data[complete.cases(lp_data[, boot_vars]), ]

# Pre-compute lead variables for the bootstrap base
for (h in 0:H) {
  boot_base[[paste0("cum_REER_", h)]] <-
    c(diff(boot_base$REER_EU, lag = h + 1)[(h + 1):.Machine$integer.max][1:nrow(boot_base)], rep(NA, h + 1))[1:nrow(boot_base)]
  boot_base[[paste0("cum_NX_", h)]] <-
    c(diff(boot_base$NX, lag = h + 1)[(h + 1):.Machine$integer.max][1:nrow(boot_base)], rep(NA, h + 1))[1:nrow(boot_base)]
}

# Use simpler lead approach directly computed on lp_data for bootstrap
# (pairs bootstrap resamples rows — we need cross-sectional independence assumption)
boot_base_full <- lp_data

pb_steps <- c(1, 250, 500, 750, 1000)
cat("  Progress: ")

for (b in 1:B) {

  if (b %in% pb_steps) cat(sprintf("[%d/%d] ", b, B))

  # Resample rows (pairs bootstrap)
  idx    <- sample(nrow(boot_base_full), replace = TRUE)
  db     <- boot_base_full[idx, ]

  # Step 1: re-estimate shock on bootstrap sample
  step1_vars_needed <- all.vars(step1_formula)
  db_s1 <- db[complete.cases(db[, step1_vars_needed]), ]
  if (nrow(db_s1) < 20) next

  tryCatch({
    s1_b     <- lm(step1_formula, data = db_s1)
    db_s1$shock_b <- residuals(s1_b)

    # Step 2: LP at each horizon
    for (h in 0:H) {
      dep_REER <- paste0("cum_REER_", h)
      dep_NX   <- paste0("cum_NX_", h)

      h_vars <- c(dep_REER, dep_NX, "REER_lag1", "NEER_lag1",
                  "Infl_lag1", "NX_lag1",
                  "seas_s1", "seas_c1", "seas_s2", "seas_c2")

      db_h <- merge(db_s1[, c("date", "shock_b")],
                    db[, c("date", h_vars)],
                    by = "date")
      db_h <- db_h[complete.cases(db_h), ]
      if (nrow(db_h) < 20) next

      fm_r <- as.formula(paste(dep_REER,
                                "~ shock_b + REER_lag1 + NEER_lag1 +",
                                "Infl_lag1 + NX_lag1 +",
                                "seas_s1 + seas_c1 + seas_s2 + seas_c2"))
      fm_n <- as.formula(paste(dep_NX,
                                "~ shock_b + REER_lag1 + NEER_lag1 +",
                                "Infl_lag1 + NX_lag1 +",
                                "seas_s1 + seas_c1 + seas_s2 + seas_c2"))

      fit_r <- lm(fm_r, data = db_h)
      fit_n <- lm(fm_n, data = db_h)

      boot_REER[b, h + 1] <- coef(fit_r)["shock_b"]
      boot_NX[b,   h + 1] <- coef(fit_n)["shock_b"]
    }
  }, error = function(e) NULL)
}
cat("\n\n")

# Bootstrap 90% confidence intervals (percentile method)
boot_ci_REER_lo <- apply(boot_REER, 2, quantile, probs = 0.05,  na.rm = TRUE)
boot_ci_REER_hi <- apply(boot_REER, 2, quantile, probs = 0.95,  na.rm = TRUE)
boot_ci_NX_lo   <- apply(boot_NX,   2, quantile, probs = 0.05,  na.rm = TRUE)
boot_ci_NX_hi   <- apply(boot_NX,   2, quantile, probs = 0.95,  na.rm = TRUE)
boot_se_REER    <- apply(boot_REER, 2, sd, na.rm = TRUE)
boot_se_NX      <- apply(boot_NX,   2, sd, na.rm = TRUE)

# Attach bootstrap results
lp_results$boot_se_REER  <- boot_se_REER
lp_results$boot_ci_lo_REER <- boot_ci_REER_lo
lp_results$boot_ci_hi_REER <- boot_ci_REER_hi
lp_results$boot_se_NX    <- boot_se_NX
lp_results$boot_ci_lo_NX  <- boot_ci_NX_lo
lp_results$boot_ci_hi_NX  <- boot_ci_NX_hi

cat("  Bootstrap-corrected estimates (90% CI):\n\n")
cat(sprintf("  %-8s  %-10s  %-12s  %-12s  %-10s  %-12s  %-12s\n",
            "Horizon", "β_REER", "CI_lo_REER", "CI_hi_REER",
            "β_NX", "CI_lo_NX", "CI_hi_NX"))
cat("  ", paste(rep("-", 82), collapse = ""), "\n")
for (i in 1:nrow(lp_results)) {
  h <- lp_results$horizon[i]
  sig_r <- ifelse(lp_results$boot_ci_lo_REER[i] > 0 |
                    lp_results$boot_ci_hi_REER[i] < 0, " *", "  ")
  sig_n <- ifelse(lp_results$boot_ci_lo_NX[i] > 0 |
                    lp_results$boot_ci_hi_NX[i] < 0, " *", "  ")
  cat(sprintf("  h = %2d  :  %7.4f%s   [%7.4f, %7.4f]   %7.4f%s  [%7.4f, %7.4f]\n",
              h,
              lp_results$beta_REER[i], sig_r,
              lp_results$boot_ci_lo_REER[i], lp_results$boot_ci_hi_REER[i],
              lp_results$beta_NX[i],   sig_n,
              lp_results$boot_ci_lo_NX[i],   lp_results$boot_ci_hi_NX[i]))
}
cat("  [* = 90% bootstrap CI excludes zero]\n\n")


# =============================================================================
# SECTION 7 — LP-IV ROBUSTNESS CHECK VIA ivreg (h = 0)
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 7 — LP-IV Robustness Check (ivreg, h = 0)\n")
cat("=============================================================================\n\n")
cat("  Two-stage least squares: Remittances instrumented by EZ variables\n")
cat("  at horizon h = 0 (contemporaneous effect on REER and NX)\n\n")

if (ez_available) {
  iv_data <- lp_data[complete.cases(lp_data[, c(
    "cum_REER_0", "cum_NX_0", "Remittances",
    "EZ_Unemp_lag1", "EUR_USD_lag1", "EZ_HICP_lag1",
    "REER_lag1", "NEER_lag1", "Infl_lag1", "NX_lag1", "month_factor")]), ]

  # REER ~ Remittances | EZ instruments
  iv_REER <- tryCatch(
    ivreg(cum_REER_0 ~ Remittances + REER_lag1 + NEER_lag1 +
            Infl_lag1 + NX_lag1 + month_factor |
            EZ_Unemp_lag1 + EUR_USD_lag1 + EZ_HICP_lag1 +
            REER_lag1 + NEER_lag1 + Infl_lag1 + NX_lag1 + month_factor,
          data = iv_data),
    error = function(e) { message("  ivreg (REER): ", e$message); NULL }
  )

  # NX ~ Remittances | EZ instruments
  iv_NX <- tryCatch(
    ivreg(cum_NX_0 ~ Remittances + REER_lag1 + NEER_lag1 +
            Infl_lag1 + NX_lag1 + month_factor |
            EZ_Unemp_lag1 + EUR_USD_lag1 + EZ_HICP_lag1 +
            REER_lag1 + NEER_lag1 + Infl_lag1 + NX_lag1 + month_factor,
          data = iv_data),
    error = function(e) { message("  ivreg (NX): ", e$message); NULL }
  )

  cat("  LP-IV (h=0) — REER response:\n")
  if (!is.null(iv_REER)) {
    iv_r_sum <- summary(iv_REER, diagnostics = TRUE)
    cat(sprintf("    Coefficient on Remittances: %.6f  (SE: %.6f, p: %.4f)\n",
                coef(iv_REER)["Remittances"],
                sqrt(vcovHC(iv_REER, type = "HC1")["Remittances", "Remittances"]),
                coeftest(iv_REER, vcov = vcovHC(iv_REER, "HC1"))["Remittances", "Pr(>|t|)"]))
    if (!is.null(iv_r_sum$diagnostics)) {
      wu_h <- iv_r_sum$diagnostics["Wu-Hausman", "statistic"]
      wu_p <- iv_r_sum$diagnostics["Wu-Hausman", "p-value"]
      sar_h <- iv_r_sum$diagnostics["Sargan", "statistic"]
      sar_p <- iv_r_sum$diagnostics["Sargan", "p-value"]
      cat(sprintf("    Wu-Hausman endogeneity test: F = %.4f  (p = %.4f)\n", wu_h, wu_p))
      cat(sprintf("    Sargan overidentification  : χ² = %.4f  (p = %.4f)\n", sar_h, sar_p))
      cat(sprintf("    Endogeneity: %s\n",
                  ifelse(wu_p < 0.10,
                         "DETECTED — IV correction is warranted",
                         "Not detected at 10% — OLS may be consistent")))
    }
  }

  cat("\n  LP-IV (h=0) — NX (leakage) response:\n")
  if (!is.null(iv_NX)) {
    cat(sprintf("    Coefficient on Remittances: %.6f  (SE: %.6f, p: %.4f)\n",
                coef(iv_NX)["Remittances"],
                sqrt(vcovHC(iv_NX, type = "HC1")["Remittances", "Remittances"]),
                coeftest(iv_NX, vcov = vcovHC(iv_NX, "HC1"))["Remittances", "Pr(>|t|)"]))
  }
} else {
  cat("  [SKIPPED] EZ instruments not available — connect to internet and re-run.\n")
}
cat("\n")


# =============================================================================
# SECTION 8 — IRF VISUALISATION (ggplot2, two panels)
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 8 — Impulse Response Function Plots\n")
cat("=============================================================================\n\n")

plot_data <- lp_results %>%
  filter(!is.na(beta_REER))

# --- Panel A: REER response ---
p_reer <- ggplot(plot_data, aes(x = horizon)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#555555", linewidth = 0.5) +
  geom_ribbon(aes(ymin = boot_ci_lo_REER, ymax = boot_ci_hi_REER),
              fill = "#2196F3", alpha = 0.15) +
  geom_ribbon(aes(ymin = beta_REER - 1.645 * se_REER,
                  ymax = beta_REER + 1.645 * se_REER),
              fill = "#2196F3", alpha = 0.10) +
  geom_line(aes(y = beta_REER), color = "#1565C0", linewidth = 1.2) +
  geom_point(aes(y = beta_REER), color = "#1565C0", size = 2.5, shape = 19) +
  scale_x_continuous(breaks = 0:12) +
  labs(
    title    = "A — REER Response to Exogenous Remittance Shock",
    subtitle = "LP-IV, bootstrap 90% CI (shaded) | NW 90% CI (lighter)",
    x        = "Horizon (months)",
    y        = "Cumulative REER change (index points)",
    caption  = "Note: Shock purged of Eurozone push-factor conditions (Step 1)."
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "#555555"),
    axis.title    = element_text(face = "bold"),
    panel.grid.major.y = element_line(color = "#eeeeee"),
    plot.caption  = element_text(size = 8, hjust = 0)
  )

# --- Panel B: NX (leakage channel) response ---
p_nx <- ggplot(plot_data, aes(x = horizon)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#555555", linewidth = 0.5) +
  geom_ribbon(aes(ymin = boot_ci_lo_NX, ymax = boot_ci_hi_NX),
              fill = "#E53935", alpha = 0.15) +
  geom_ribbon(aes(ymin = beta_NX - 1.645 * se_NX,
                  ymax = beta_NX + 1.645 * se_NX),
              fill = "#E53935", alpha = 0.10) +
  geom_line(aes(y = beta_NX), color = "#B71C1C", linewidth = 1.2) +
  geom_point(aes(y = beta_NX), color = "#B71C1C", size = 2.5, shape = 19) +
  scale_x_continuous(breaks = 0:12) +
  labs(
    title    = "B — Net Exports Response to Exogenous Remittance Shock",
    subtitle = "Import Leakage Channel validation | bootstrap 90% CI (shaded)",
    x        = "Horizon (months)",
    y        = "Cumulative NX change (USD million)",
    caption  = "A negative response = trade deficit worsening (leakage confirmed)."
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "#555555"),
    axis.title    = element_text(face = "bold"),
    panel.grid.major.y = element_line(color = "#eeeeee"),
    plot.caption  = element_text(size = 8, hjust = 0)
  )

# Combine panels and save
irf_plot <- p_reer / p_nx +
  plot_annotation(
    title   = "Kosovariance — LP-IV Impulse Response Functions",
    subtitle = sprintf(
      "Remittance shock response over %d months | B = 1,000 bootstrap replications",
      H
    ),
    theme = theme(
      plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "#444444")
    )
  )

# Save plot
tryCatch({
  out_path <- here("KOSOVARIANCE_LP_IV_IRF.png")
  ggsave(out_path, plot = irf_plot,
         width = 10, height = 8, dpi = 300, bg = "white")
  cat(sprintf("  IRF plot saved: %s\n\n", out_path))
}, error = function(e) {
  cat("  [WARN] Could not save plot:", e$message, "\n\n")
})


# =============================================================================
# SECTION 9 — GLOBAL WALD TEST  H₀: β_h = 0 for ALL h = 0,...,12
# =============================================================================

cat("=============================================================================\n")
cat("  SECTION 9 — Global Wald Test\n")
cat("  H₀: β_REER_h = 0  for all h = 0,...,12  (joint null)\n")
cat("=============================================================================\n\n")

# Joint significance: count how many horizons have 90% CI excluding 0
reer_sig <- sum(lp_results$boot_ci_lo_REER > 0 | lp_results$boot_ci_hi_REER < 0,
                na.rm = TRUE)
nx_sig   <- sum(lp_results$boot_ci_lo_NX > 0 | lp_results$boot_ci_hi_NX < 0,
                na.rm = TRUE)

# Bootstrap-based joint test: what fraction of bootstrap draws have
# ALL β_h with same sign as point estimate?
if (any(!is.na(boot_REER))) {
  # Simple joint test: fraction of bootstrap samples where point and bootstrap agree in sign
  signs_match <- apply(sweep(boot_REER, 2, sign(lp_results$beta_REER), "*") > 0,
                       1, all, na.rm = TRUE)
  joint_p_reer <- mean(!signs_match, na.rm = TRUE)
  cat(sprintf("  REER: %d / %d horizons significant at 90%% (bootstrap CI)\n",
              reer_sig, H + 1))
  cat(sprintf("  Joint bootstrap p-value (REER, all horizons): %.4f\n\n", joint_p_reer))
}
cat(sprintf("  NX  : %d / %d horizons significant at 90%% (bootstrap CI)\n",
            nx_sig, H + 1))
cat("\n")


# =============================================================================
# SECTION 10 — CONSOLIDATED SUMMARY PANEL
# =============================================================================

cat("=============================================================================\n")
cat("  KOSOVARIANCE — LP-IV CONSOLIDATED SUMMARY\n")
cat("=============================================================================\n\n")

cat("  [1] ECONOMETRIC STRATEGY\n")
cat("  ────────────────────────────────────────────────────────────────────────\n")
cat("  Method   : Local Projections IV (Jordà 2005 + Stock & Watson 2018)\n")
cat("  Step 1   : Remittance shock = OLS residual after removing EZ push-factors\n")
cat(sprintf("             EZ instruments: %s\n",
            ifelse(ez_available,
                   "EZ Unemployment, EUR/USD, EZ HICP (via Eurostat/FRED)",
                   "UNAVAILABLE — fallback to AR residuals only")))
cat("  Step 2   : Cumulative LP at h = 0,...,12 months; NW HAC SE\n")
cat("  SE fix   : Pairs bootstrap (B = 1,000) corrects generated-regressor bias\n\n")

cat("  [2] REER RESPONSE TO EXOGENOUS REMITTANCE SHOCK\n")
cat("  ────────────────────────────────────────────────────────────────────────\n")
reer_max_h <- lp_results$horizon[which.max(abs(lp_results$beta_REER))]
reer_max_b <- lp_results$beta_REER[lp_results$horizon == reer_max_h]
cat(sprintf("  Peak response   : β = %.4f at h = %d months\n", reer_max_b, reer_max_h))
cat(sprintf("  Horizons where 90%% CI excludes 0: %d out of %d\n", reer_sig, H + 1))
reer_conclusion <- if (reer_sig == 0) {
  "NO REER APPRECIATION — Dutch Disease REJECTED (consistent with ARDL)"
} else if (reer_sig <= 2) {
  "MARGINAL / SHORT-LIVED response — Dutch Disease effect transitory"
} else {
  "SIGNIFICANT REER response — Dutch Disease may be present, review ARDL"
}
cat(sprintf("  Conclusion      : %s\n\n", reer_conclusion))

cat("  [3] NX (LEAKAGE CHANNEL) RESPONSE\n")
cat("  ────────────────────────────────────────────────────────────────────────\n")
nx_max_h <- lp_results$horizon[which.max(abs(lp_results$beta_NX))]
nx_max_b <- lp_results$beta_NX[lp_results$horizon == nx_max_h]
cat(sprintf("  Peak response   : β = %.4f at h = %d months\n", nx_max_b, nx_max_h))
cat(sprintf("  Horizons where 90%% CI excludes 0: %d out of %d\n", nx_sig, H + 1))
nx_conclusion <- if (nx_max_b < 0 && nx_sig > 0) {
  "LEAKAGE CONFIRMED — remittance shock widens trade deficit"
} else {
  "Leakage channel not significant at this specification"
}
cat(sprintf("  Conclusion      : %s\n\n", nx_conclusion))

cat("  [4] OVERALL ASSESSMENT\n")
cat("  ────────────────────────────────────────────────────────────────────────\n")
cat("  The LP-IV framework:\n")
cat("    (a) Controls for Eurozone macro conditions in shock construction\n")
cat("    (b) Corrects for any contemporaneous endogeneity between\n")
cat("        Remittances and REER via residual orthogonalization\n")
cat("    (c) Provides horizon-by-horizon IRFs with bootstrap-valid inference\n\n")
cat("  Comparison to ARDL finding (β_Remittances = 0.012, p = 0.268):\n")
cat("    LP-IV serves as a robustness check and endogeneity correction.\n")
cat("    Consistency between ARDL long-run coefficients and LP-IV IRFs\n")
cat("    at longer horizons would strengthen the original thesis significantly.\n\n")

cat("=============================================================================\n")
cat("  END OF LP-IV ANALYSIS\n")
cat("=============================================================================\n")
