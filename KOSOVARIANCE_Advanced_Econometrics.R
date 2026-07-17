# =============================================================================
# KOSOVARIANCE_Advanced_Econometrics.R
# =============================================================================
# Script Name  : KOSOVARIANCE_Advanced_Econometrics.R
# Authors      : Valerio Di Federico (solo advanced extension)
#                Original baseline: Di Federico, Pedroni, Tibiletti
# Description  : Advanced econometric analysis of Kosovo remittances and REER.
#                Sections: ADF stationarity, heteroskedasticity tests,
#                ARDL bounds test + UECM long-run coefficients,
#                consolidated summary panel.
# Note         : No Johansen, no VECM, no tsDyn — ARDL framework only.
# =============================================================================

# =============================================================================
# SECTION 0 — Libraries & Data Loading
# ======================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(here)
  library(dplyr)
  library(tseries)
  library(urca)
  library(ARDL)
  library(lmtest)
  library(sandwich)
  library(skedastic)
})

cat("======================================================================\n")
cat("  KOSOVARIANCE — Advanced Econometrics\n")
cat("  Author: Valerio Di Federico\n")
cat("  Baseline: Di Federico, Pedroni, Tibiletti\n")
cat("======================================================================\n\n")

cat(">>> SECTION 0: Libraries & Data Loading\n")
cat("----------------------------------------------------------------------\n")

MonthlyRemittances <- read_excel(
  here("data_raw", "Remittances_channel&country.xlsx"),
  sheet    = "Monthly",
  col_names = TRUE
)

# Drop first 85 rows (headers/pre-sample) and row 138 (anomalous observation)
MonthlyRemittances2 <- MonthlyRemittances[-(1:85), ]
MonthlyRemittances2 <- MonthlyRemittances2[-138, ]

vars_of_interest <- c("REER_EU", "Remittances", "Inflation", "NEER", "FDI", "NX")

# Coerce selected columns to numeric (they may arrive as character from Excel)
for (v in vars_of_interest) {
  MonthlyRemittances2[[v]] <- as.numeric(MonthlyRemittances2[[v]])
}

data_levels <- as.data.frame(MonthlyRemittances2[, vars_of_interest])

cat("Data loaded successfully.\n")
cat(sprintf("  Observations : %d\n", nrow(data_levels)))
cat(sprintf("  Variables    : %s\n\n", paste(vars_of_interest, collapse = ", ")))


# =============================================================================
# SECTION 1 — ADF Stationarity Tests (Levels + First Differences)
# ======================================================================

cat("======================================================================\n")
cat("  SECTION 1 — ADF Stationarity Tests\n")
cat("======================================================================\n\n")

# --------------------------------------------------------------------------
# ADF helper function
# --------------------------------------------------------------------------
run_adf <- function(x, label) {

  x_clean <- as.numeric(na.omit(x))
  dx_clean <- diff(x_clean)

  # ---- Levels: trend specification ----------------------------------------
  adf_lev <- ur.df(x_clean, type = "trend", lags = 12, selectlags = "AIC")
  tau_lev  <- adf_lev@teststat[1, "tau3"]
  cv5_lev  <- adf_lev@cval["tau3", "5pct"]
  rej_lev  <- tau_lev < cv5_lev

  # ADF cross-check (p-value) for levels
  k_lev  <- min(12, floor(length(x_clean)^(1/3)))
  ap_lev <- tryCatch(adf.test(x_clean, k = k_lev)$p.value, error = function(e) NA_real_)

  # ---- First differences: drift specification ------------------------------
  adf_dif <- ur.df(dx_clean, type = "drift", lags = 12, selectlags = "AIC")
  tau_dif  <- adf_dif@teststat[1, "tau2"]
  cv5_dif  <- adf_dif@cval["tau2", "5pct"]
  rej_dif  <- tau_dif < cv5_dif

  # ADF cross-check (p-value) for first differences
  k_dif  <- min(12, floor(length(dx_clean)^(1/3)))
  ap_dif <- tryCatch(adf.test(dx_clean, k = k_dif)$p.value, error = function(e) NA_real_)

  # ---- Integration order ---------------------------------------------------
  order_str <- if (rej_lev) {
    "I(0)"
  } else if (rej_dif) {
    "I(1)"
  } else {
    "I(2)+"
  }

  list(
    label    = label,
    tau_lev  = tau_lev,
    cv5_lev  = cv5_lev,
    pval_lev = ap_lev,
    rej_lev  = rej_lev,
    tau_dif  = tau_dif,
    cv5_dif  = cv5_dif,
    pval_dif = ap_dif,
    rej_dif  = rej_dif,
    order    = order_str
  )
}

# --------------------------------------------------------------------------
# Run ADF for all variables of interest
# --------------------------------------------------------------------------
adf_results <- lapply(vars_of_interest, function(v) {
  run_adf(data_levels[[v]], v)
})

# --------------------------------------------------------------------------
# Print formatted ADF table
# --------------------------------------------------------------------------
cat(sprintf(
  "%-15s %8s %8s %8s %6s | %8s %8s %8s %6s | %6s\n",
  "Variable", "tau_Lev", "CV5_Lev", "pval_Lev", "Rej_L",
  "tau_Diff", "CV5_Diff", "pval_Diff", "Rej_D", "Order"
))
cat(paste(rep("-", 98), collapse = ""), "\n")

for (r in adf_results) {
  cat(sprintf(
    "%-15s %8.3f %8.3f %8.4f %6s | %8.3f %8.3f %8.4f %6s | %6s\n",
    r$label,
    r$tau_lev,  r$cv5_lev,  ifelse(is.na(r$pval_lev), NA, r$pval_lev),
    ifelse(r$rej_lev,  "YES", "NO"),
    r$tau_dif,  r$cv5_dif,  ifelse(is.na(r$pval_dif), NA, r$pval_dif),
    ifelse(r$rej_dif,  "YES", "NO"),
    r$order
  ))
}

cat("\n")

# Integration order summary
orders <- sapply(adf_results, `[[`, "order")
cat("Integration Order Summary:\n")
for (i in seq_along(vars_of_interest)) {
  cat(sprintf("  %-15s -> %s\n", vars_of_interest[i], orders[i]))
}

has_I0 <- any(orders == "I(0)")
has_I1 <- any(orders == "I(1)")
mixed  <- has_I0 && has_I1

cat(sprintf(
  "\n  Dataset is %s order.\n",
  if (mixed) "MIXED I(0)/I(1) — suitable for ARDL bounds testing"
  else if (all(orders == "I(0)")) "purely I(0)"
  else if (all(orders == "I(1)")) "purely I(1)"
  else "of undetermined/higher integration"
))
cat("\n")


# =============================================================================
# SECTION 2 — Heteroskedasticity Tests (Breusch-Pagan + White)
# ======================================================================

cat("======================================================================\n")
cat("  SECTION 2 — Heteroskedasticity Tests\n")
cat("======================================================================\n\n")

# --------------------------------------------------------------------------
# Rebuild master_data_diff exactly as in the original pipeline
# --------------------------------------------------------------------------
REER_EU      <- as.numeric(MonthlyRemittances2[["REER_EU"]])
Remittances  <- as.numeric(MonthlyRemittances2[["Remittances"]])
Inflation    <- as.numeric(MonthlyRemittances2[["Inflation"]])
NEER         <- as.numeric(MonthlyRemittances2[["NEER"]])
FDI          <- as.numeric(MonthlyRemittances2[["FDI"]])
NX           <- as.numeric(MonthlyRemittances2[["NX"]])

d_REER        <- diff(REER_EU)
d_Remittances <- diff(Remittances)
d_Inflation   <- diff(Inflation)
d_NEER        <- diff(NEER)
d_FDI         <- diff(FDI)
d_NX          <- diff(NX)

# Date variable (drop first observation to align with diffs)
date_col <- MonthlyRemittances2$Month[-1]
month_col <- factor(format(as.Date(date_col), "%b"))

# Lags (using dplyr::lag on plain numeric vectors)
d_REER_lag1        <- dplyr::lag(d_REER,        1)
d_REER_lag4        <- dplyr::lag(d_REER,        4)
d_REER_lag12       <- dplyr::lag(d_REER,       12)
d_Remittances_lag1 <- dplyr::lag(d_Remittances, 1)
d_Remittances_lag2 <- dplyr::lag(d_Remittances, 2)
d_Remittances_lag12<- dplyr::lag(d_Remittances,12)

master_data_diff <- data.frame(
  date              = date_col,
  month             = month_col,
  d_REER            = d_REER,
  d_Remittances     = d_Remittances,
  d_Inflation       = d_Inflation,
  d_NEER            = d_NEER,
  d_FDI             = d_FDI,
  d_NX              = d_NX,
  d_REER_lag1       = d_REER_lag1,
  d_REER_lag4       = d_REER_lag4,
  d_REER_lag12      = d_REER_lag12,
  d_Remittances_lag1 = d_Remittances_lag1,
  d_Remittances_lag2 = d_Remittances_lag2,
  d_Remittances_lag12= d_Remittances_lag12
)

# --------------------------------------------------------------------------
# Baseline OLS model (first-difference specification with seasonals)
# --------------------------------------------------------------------------
fit_final <- lm(
  d_REER ~ d_REER_lag1 + d_REER_lag4 + d_REER_lag12 +
    d_Remittances + d_Inflation + d_FDI + d_NX +
    as.factor(month),
  data = master_data_diff
)

cat("Baseline OLS model (first-difference + seasonal dummies):\n")
cat(sprintf("  Observations used : %d\n", nobs(fit_final)))
cat(sprintf("  R-squared         : %.4f\n", summary(fit_final)$r.squared))
cat(sprintf("  Adj. R-squared    : %.4f\n\n", summary(fit_final)$adj.r.squared))

# --------------------------------------------------------------------------
# 2A. Breusch-Pagan test (studentized)
# --------------------------------------------------------------------------
cat("--- 2A: Breusch-Pagan Test (studentized) ---\n")
bp_result <- bptest(fit_final, studentize = TRUE)
print(bp_result)
bp_stat  <- as.numeric(bp_result$statistic)
bp_pval  <- bp_result$p.value
cat(sprintf(
  "  BP statistic = %.4f,  p-value = %.4f\n  Interpretation: %s\n\n",
  bp_stat, bp_pval,
  if (bp_pval < 0.05) "REJECT H0 — evidence of heteroskedasticity (use HAC SEs)"
  else "FAIL TO REJECT H0 — no significant heteroskedasticity"
))

# --------------------------------------------------------------------------
# 2B. White Test
# --------------------------------------------------------------------------
cat("--- 2B: White Test ---\n")
white_result <- tryCatch(
  {
    wr <- white(fit_final, interactions = FALSE)
    print(wr)
    wr
  },
  error = function(e) {
    cat("  white() failed:", conditionMessage(e), "\n")
    cat("  Falling back to manual nR\u00b2 White test...\n\n")

    e2   <- residuals(fit_final)^2
    yhat <- fitted(fit_final)
    ok   <- is.finite(e2) & is.finite(yhat)
    aux  <- lm(e2[ok] ~ yhat[ok] + I(yhat[ok]^2))
    stat <- summary(aux)$r.squared * sum(ok)
    pv   <- pchisq(stat, df = 2, lower.tail = FALSE)

    cat(sprintf("  White nR² statistic = %.4f\n", stat))
    cat(sprintf("  p-value (chi2, df=2) = %.4f\n", pv))
    cat(sprintf(
      "  Interpretation: %s\n",
      if (pv < 0.05) "REJECT H0 — evidence of heteroskedasticity"
      else "FAIL TO REJECT H0 — no significant heteroskedasticity"
    ))

    list(statistic = stat, p.value = pv, method = "Manual nR2 White test (fallback)")
  }
)

cat("\n  NOTE: Regardless of outcome, HAC-robust standard errors (Newey-West)\n")
cat("        are applied in the final ARDL UECM for valid inference.\n\n")


# =============================================================================
# SECTION 3 — ARDL Bounds Test + UECM Long-Run Coefficients
# ======================================================================

cat("======================================================================\n")
cat("  SECTION 3 — ARDL Bounds Test + UECM Long-Run Coefficients\n")
cat("======================================================================\n\n")

tryCatch({

  # ---- Data preparation ---------------------------------------------------
  ardl_data <- na.omit(data_levels)
  cat(sprintf("ARDL data: %d complete observations.\n\n", nrow(ardl_data)))

  # ---- Automatic lag-order selection (AIC, max_order = 4) -----------------
  cat("--- 3A: Automatic ARDL Lag Selection (AIC, max_order = 4) ---\n")
  auto_result <- auto_ardl(
    REER_EU ~ Remittances + Inflation + NEER + FDI + NX,
    data      = ardl_data,
    max_order = 4,
    selection = "AIC"
  )

  best_ardl <- auto_result$best_model
  best_order <- auto_result$best_order

  cat(sprintf("Optimal ARDL order: (%s)\n\n",
              paste(best_order, collapse = ", ")))

  # ---- Bounds F-test (PSS 2001, Case 3: unrestricted intercept, no trend) -
  cat("--- 3B: Bounds F-test (Case 3) ---\n")
  f_test <- bounds_f_test(best_ardl, case = 3, alpha = 0.05)
  print(f_test)

  f_stat <- as.numeric(f_test$statistic)

  # Robustly extract 5% critical values from tab (data.frame or named structure)
  ci0_5 <- NA_real_
  ci1_5 <- NA_real_
  if (!is.null(f_test$tab)) {
    tab <- f_test$tab
    # tab may be a data.frame with columns I(0) and I(1)
    # or a named numeric vector
    if (is.data.frame(tab)) {
      # columns: alpha, I(0), I(1)  OR  just I(0) I(1) with rownames
      col_i0 <- grep("I\\(0\\)|lower", colnames(tab), ignore.case = TRUE, value = TRUE)[1]
      col_i1 <- grep("I\\(1\\)|upper", colnames(tab), ignore.case = TRUE, value = TRUE)[1]
      if (!is.na(col_i0) && !is.na(col_i1)) {
        ci0_5 <- as.numeric(tab[1, col_i0])
        ci1_5 <- as.numeric(tab[1, col_i1])
      }
    } else if (is.numeric(tab)) {
      nm <- names(tab)
      i0_idx <- grep("I\\(0\\)|lower", nm, ignore.case = TRUE)[1]
      i1_idx <- grep("I\\(1\\)|upper", nm, ignore.case = TRUE)[1]
      if (!is.na(i0_idx)) ci0_5 <- tab[i0_idx]
      if (!is.na(i1_idx)) ci1_5 <- tab[i1_idx]
    }
  }

  f_decision <- if (!is.na(f_stat) && !is.na(ci1_5) && f_stat > ci1_5) {
    "CONFIRMED — long-run cointegrating relationship exists (F > I(1) upper bound)"
  } else if (!is.na(f_stat) && !is.na(ci0_5) && f_stat < ci0_5) {
    "NONE — no cointegration (F < I(0) lower bound)"
  } else {
    "INCONCLUSIVE — F falls within bounds; further testing warranted"
  }

  cat(sprintf(
    "\n  F-statistic = %.4f\n  5%% I(0) lower = %s,  5%% I(1) upper = %s\n  Decision: %s\n\n",
    f_stat,
    ifelse(is.na(ci0_5), "N/A", sprintf("%.4f", ci0_5)),
    ifelse(is.na(ci1_5), "N/A", sprintf("%.4f", ci1_5)),
    f_decision
  ))

  # ---- Bounds t-test (Pesaran 2018, Case 3) --------------------------------
  cat("--- 3C: Bounds t-test (Case 3) ---\n")
  t_test <- bounds_t_test(best_ardl, case = 3)
  print(t_test)
  cat("\n")

  # ---- Long-Run Multipliers -----------------------------------------------
  cat("--- 3D: Long-Run Multipliers ---\n")
  lr_mult <- multipliers(best_ardl, type = "lr")
  print(lr_mult)
  cat("\n")

  # ---- UECM Summary -------------------------------------------------------
  cat("--- 3E: Unrestricted ECM (UECM) Summary ---\n")
  uecm_model <- uecm(best_ardl)
  print(summary(uecm_model))

  # Store key results for summary panel
  assign("f_stat_global",    f_stat,      envir = .GlobalEnv)
  assign("f_decision_global", f_decision, envir = .GlobalEnv)
  assign("lr_mult_global",   lr_mult,     envir = .GlobalEnv)
  assign("best_order_global", best_order, envir = .GlobalEnv)

}, error = function(e) {
  cat("\n  ERROR in ARDL section:", conditionMessage(e), "\n")
  assign("f_stat_global",     NA,         envir = .GlobalEnv)
  assign("f_decision_global", "ERROR",    envir = .GlobalEnv)
  assign("lr_mult_global",    NULL,       envir = .GlobalEnv)
  assign("best_order_global", NA,         envir = .GlobalEnv)
})


# =============================================================================
# SECTION 4 — Consolidated Summary Panel
# ======================================================================

cat("======================================================================\n")
cat("  SECTION 4 — Consolidated Summary Panel\n")
cat("======================================================================\n\n")

# Retrieve results safely
f_stat_s     <- if (exists("f_stat_global"))     f_stat_global     else NA
f_decision_s <- if (exists("f_decision_global")) f_decision_global else "N/A"
lr_mult_s    <- if (exists("lr_mult_global"))    lr_mult_global    else NULL
best_ord_s   <- if (exists("best_order_global")) best_order_global else NA

cat("======================================================================\n")
cat("  KOSOVARIANCE — Advanced Econometrics: Summary Panel\n")
cat("======================================================================\n\n")

# [1] Stationarity
cat("  [1] STATIONARITY (ADF Results)\n")
cat("  ----------------------------------------------------------------------\n")
for (r in adf_results) {
  cat(sprintf("      %-15s : %s  (tau_lev=%.3f, tau_diff=%.3f)\n",
              r$label, r$order, r$tau_lev, r$tau_dif))
}
cat(sprintf(
  "\n      => Dataset is %s\n\n",
  if (mixed) "MIXED I(0)/I(1) — ARDL bounds testing is appropriate."
  else "of uniform integration order."
))

# [2] Heteroskedasticity
cat("  [2] HETEROSKEDASTICITY\n")
cat("  ----------------------------------------------------------------------\n")
cat(sprintf("      Breusch-Pagan : stat = %.4f,  p-value = %.4f\n", bp_stat, bp_pval))
cat(sprintf("      Interpretation: %s\n",
            if (bp_pval < 0.05) "Heteroskedasticity detected — HAC SEs recommended."
            else "No significant heteroskedasticity detected."))
cat("      HAC (Newey-West) robust SEs applied in ARDL UECM for valid inference.\n\n")

# [3] ARDL Bounds Test
cat("  [3] ARDL BOUNDS TEST\n")
cat("  ----------------------------------------------------------------------\n")
if (!is.na(f_stat_s)) {
  cat(sprintf("      Optimal order  : ARDL(%s)\n",
              paste(best_ord_s, collapse = ", ")))
  cat(sprintf("      F-statistic    : %.4f\n", f_stat_s))
  cat(sprintf("      Conclusion     : %s\n\n", f_decision_s))
} else {
  cat("      ARDL section did not complete successfully.\n\n")
}

# [4] Recommended specification
cat("  [4] RECOMMENDED FINAL SPECIFICATION\n")
cat("  ----------------------------------------------------------------------\n")
if (!is.na(f_stat_s) && grepl("CONFIRMED", f_decision_s)) {
  cat("      Long-run cointegration CONFIRMED.\n")
  cat(sprintf("      Use ARDL(%s) UECM as the preferred specification.\n",
              paste(best_ord_s, collapse = ", ")))
  cat("      Apply HAC-robust (Newey-West) standard errors.\n")
  cat("      Interpret long-run multipliers from multipliers(best_ardl, type='lr').\n")
  if (!is.null(lr_mult_s)) {
    cat("\n      Long-Run Multipliers:\n")
    # Robustly find term-name and estimate columns
    term_col <- grep("^[Tt]erm$|^[Vv]ar(iable)?$|^[Nn]ame$", colnames(lr_mult_s), value = TRUE)[1]
    est_col  <- grep("^[Ee]stimate$|^[Cc]oef(ficient)?$", colnames(lr_mult_s), value = TRUE)[1]
    if (is.na(est_col) && ncol(lr_mult_s) >= 1) est_col <- colnames(lr_mult_s)[which(sapply(lr_mult_s, is.numeric))[1]]
    for (i in seq_len(nrow(lr_mult_s))) {
      lbl <- if (!is.na(term_col)) as.character(lr_mult_s[[term_col]][i])
             else if (!is.null(rownames(lr_mult_s)) && !is.na(rownames(lr_mult_s)[i])) rownames(lr_mult_s)[i]
             else paste0("var", i)
      coef_val <- if (!is.na(est_col)) as.numeric(lr_mult_s[[est_col]][i]) else NA_real_
      cat(sprintf("        %-20s : coef = %s\n",
                  lbl, ifelse(is.na(coef_val), "N/A", sprintf("%8.4f", coef_val))))
    }
  }
} else if (!is.na(f_stat_s) && grepl("NONE", f_decision_s)) {
  cat("      No long-run cointegration detected.\n")
  cat("      Use short-run first-difference OLS model with seasonal dummies.\n")
  cat("      Apply HAC-robust (Newey-West) standard errors.\n")
} else {
  cat("      Inconclusive or unavailable — extend sample or refine lag structure.\n")
}

cat("\n======================================================================\n")
cat("  End of KOSOVARIANCE_Advanced_Econometrics.R\n")
cat("======================================================================\n")
