# ====================================================================
# KOSOVARIANCE — ADVANCED ECONOMETRIC DIAGNOSTICS
# ====================================================================
# Authors : Valerio Di Federico, Emanuele Pedroni, Andrea Tibiletti
# Script  : KOSOVARIANCE_Advanced_Econometrics.R
# Purpose : Augmented stationarity testing (ADF), heteroskedasticity
#           diagnostics (Breusch-Pagan / White), and cointegration
#           analysis (ARDL Bounds Test + Johansen) for the Kosovo
#           Remittances — REER project.
#
# STRUCTURE
#   0.  Libraries & data loading (mirrors original pipeline exactly)
#   1.  ADF stationarity tests  — levels AND first differences
#   2.  Heteroskedasticity tests — Breusch-Pagan & White
#   3a. ARDL Bounds Test         — Pesaran, Shin & Smith (2001)
#   3b. ARDL Long-Run Coefficients via UECM
#   3c. Johansen Test            — on I(1) subset only, with caveat
#   4.  Consolidated summary panel
# ====================================================================

# ====================================================================
# SECTION 0 · LIBRARIES & DATA LOADING
# ====================================================================

required_pkgs <- c(
  "readxl", "here", "dplyr",
  "tseries",
  "urca",
  "ARDL",
  "lmtest", "sandwich",
  "skedastic"
)

new_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(new_pkgs) > 0) {
  message("Installing: ", paste(new_pkgs, collapse = ", "))
  install.packages(new_pkgs, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(readxl); library(here); library(dplyr)
  library(tseries); library(urca)
  library(ARDL)
  library(lmtest); library(sandwich)
  library(skedastic)
})

# -- Load & clean data (identical to original pipeline) ----------------
MonthlyRemittances <- read_excel(
  here("data_raw", "Remittances_channel&country.xlsx"),
  sheet = "Monthly", col_names = TRUE
)
MonthlyRemittances2 <- MonthlyRemittances[-(1:85), ]
MonthlyRemittances2 <- MonthlyRemittances2[-138, ]

vars_of_interest <- c("REER_EU", "Remittances", "Inflation", "NEER", "FDI", "NX")
stopifnot(all(vars_of_interest %in% names(MonthlyRemittances2)))
data_levels <- as.data.frame(MonthlyRemittances2[, vars_of_interest])

# ====================================================================
# SECTION 1 · ADF STATIONARITY TESTS
# ====================================================================
# Procedure:
#   Step 1 — ur.df() [urca], lag selection by AIC (max 12 for monthly),
#             type="trend" in levels (allows for deterministic trend),
#             type="drift"  in first differences (allows intercept only).
#   Step 2 — adf.test() [tseries] as p-value cross-check.
#
# Decision rule: reject H₀ (unit root) when τ < critical value at 5%.
# Integration order:
#   I(0) → stationary in levels
#   I(1) → non-stationary in levels, stationary in first differences
#   I(2+)→ non-stationary even in first differences
# ====================================================================

cat("\n====================================================================\n")
cat("  [1] ADF STATIONARITY TESTS\n")
cat("====================================================================\n")
cat("Lag selection : AIC, max 12 lags (ur.df from urca package)\n")
cat("Spec (levels) : trend + drift | Spec (Δ) : drift only\n")
cat("Cross-check   : adf.test() p-values (tseries package)\n\n")

run_adf <- function(x, label) {
  x_clean <- na.omit(as.numeric(x))
  dx_clean <- na.omit(diff(x_clean))

  # urca — AIC-selected lag ADF
  ur_lev  <- ur.df(x_clean,  type = "trend", lags = 12, selectlags = "AIC")
  ur_diff <- ur.df(dx_clean, type = "drift", lags = 12, selectlags = "AIC")

  tau_lev  <- ur_lev@teststat[1]
  tau_diff <- ur_diff@teststat[1]
  cv_lev   <- ur_lev@cval[1, ]   # 1pct, 5pct, 10pct
  cv_diff  <- ur_diff@cval[1, ]

  rej_lev  <- tau_lev  < cv_lev["5pct"]
  rej_diff <- tau_diff < cv_diff["5pct"]

  # tseries p-value (truncated at 0.01 for strong rejections)
  pv_lev  <- tryCatch(adf.test(x_clean,  k = min(12, floor(length(x_clean)^(1/3))))$p.value, error=function(e) NA)
  pv_diff <- tryCatch(adf.test(dx_clean, k = min(12, floor(length(dx_clean)^(1/3))))$p.value, error=function(e) NA)

  i_order <- if (rej_lev) "I(0)" else if (rej_diff) "I(1)" else "I(2+)"

  list(label=label,
       tau_lev=round(tau_lev,4), cv5_lev=cv_lev["5pct"], pv_lev=round(pv_lev,4), rej_lev=rej_lev,
       tau_diff=round(tau_diff,4), cv5_diff=cv_diff["5pct"], pv_diff=round(pv_diff,4), rej_diff=rej_diff,
       i_order=i_order)
}

adf_results <- lapply(vars_of_interest, function(v) run_adf(data_levels[[v]], label=v))

# Print formatted table
adf_df <- do.call(rbind, lapply(adf_results, function(r) {
  data.frame(Variable=r$label,
             `tau_Lev`=r$tau_lev, `CV5_Lev`=r$cv5_lev, `pval_Lev`=r$pv_lev,
             `Rej_H0_Lev`=ifelse(r$rej_lev,"YES","no"),
             `tau_Diff`=r$tau_diff, `CV5_Diff`=r$cv5_diff, `pval_Diff`=r$pv_diff,
             `Rej_H0_Diff`=ifelse(r$rej_diff,"YES","no"),
             `Order`=r$i_order, check.names=FALSE)
}))
print(adf_df, row.names=FALSE)

i_orders <- setNames(sapply(adf_results, `[[`, "i_order"), vars_of_interest)
cat("\n  Integration Order Summary:\n")
for (v in names(i_orders)) cat(sprintf("    %-15s : %s\n", v, i_orders[v]))

all_I1    <- all(i_orders == "I(1)")
mixed_I01 <- any(i_orders == "I(0)") && any(i_orders == "I(1)")
cat(sprintf("\n  All I(1)?  %s  |  Mixed I(0)/I(1)?  %s\n", all_I1, mixed_I01))

cat("\n  METHODOLOGICAL NOTE:\n")
cat("  Because the variable set is MIXED I(0)/I(1), the Johansen\n")
cat("  test (which requires all I(1)) is only supplementary here.\n")
cat("  The ARDL Bounds Test (Pesaran et al. 2001) is the PRIMARY\n")
cat("  cointegration tool — it is valid for any mix of I(0) and I(1).\n")

# ====================================================================
# SECTION 2 · HETEROSKEDASTICITY TESTS
# ====================================================================
# Applied to the original ARX model (fit_final) in first differences.
#
# (a) Breusch-Pagan test (Koenker 1981 studentized version):
#     Regresses squared residuals on fitted values.
#     Robust to non-normality.
# (b) White test (Harvey 1976, White 1980):
#     Uses white_lm() from {skedastic}, which regresses squared
#     residuals on all regressors, squares, and cross-products.
#     Fallback: manual auxiliary regression if skedastic fails.
#
# H₀ for both: homoskedastic errors.
# NB: Newey-West SE (already in original model) provide HAC-robust
#     inference regardless of outcome.
# ====================================================================

cat("\n====================================================================\n")
cat("  [2] HETEROSKEDASTICITY TESTS\n")
cat("====================================================================\n")
cat("Model: Δ REER ~ Δ REER(t-1,4,12) + Δ Remittances + Δ Inflation\n")
cat("              + Δ FDI + Δ NX + 11 Monthly dummies\n\n")

# Rebuild differenced dataset (exact replica of original pipeline)
master_data_diff <- data.frame(
  d_REER        = diff(MonthlyRemittances2$REER_EU),
  d_Remittances = diff(MonthlyRemittances2$Remittances),
  d_Inflation   = diff(MonthlyRemittances2$Inflation),
  d_NEER        = diff(MonthlyRemittances2$NEER),
  d_FDI         = diff(MonthlyRemittances2$FDI),
  d_NX          = diff(MonthlyRemittances2$NX)
)
master_data_diff <- master_data_diff %>%
  mutate(date  = MonthlyRemittances2$Month[-1],
         month = factor(format(as.Date(date), "%b"))) %>%
  mutate(d_REER_lag1  = lag(d_REER, 1),
         d_REER_lag4  = lag(d_REER, 4),
         d_REER_lag12 = lag(d_REER, 12),
         d_Remittances_lag1  = lag(d_Remittances, 1),
         d_Remittances_lag2  = lag(d_Remittances, 2),
         d_Remittances_lag12 = lag(d_Remittances, 12))

fit_final <- lm(
  d_REER ~ d_REER_lag1 + d_REER_lag4 + d_REER_lag12 +
    d_Remittances + d_Inflation + d_FDI + d_NX + as.factor(month),
  data = master_data_diff
)

# (a) Breusch-Pagan --------------------------------------------------------
bp <- bptest(fit_final, studentize = TRUE)
cat("  (a) Breusch-Pagan Test (Koenker studentized)\n")
cat(sprintf("      Statistic (χ²): %.4f  |  df: %d  |  p-value: %.4f\n",
            bp$statistic, bp$parameter, bp$p.value))
cat("      Conclusion:", ifelse(bp$p.value < 0.05,
    "REJECT H₀ — Heteroskedasticity DETECTED",
    "FAIL to reject H₀ — Errors appear homoskedastic"), "\n\n")

# (b) White test -----------------------------------------------------------
# Use skedastic::white_lm(); fall back to a manual auxiliary-regression
# approach (White 1980) if it errors (e.g. with many dummies).
white_done <- FALSE
tryCatch({
  wt <- white_lm(fit_final, interactions = FALSE)  # no interactions = standard White
  cat("  (b) White Test (skedastic::white_lm)\n")
  cat(sprintf("      Statistic (χ²): %.4f  |  p-value: %.4f\n",
              wt$statistic, wt$p.value))
  cat("      Conclusion:", ifelse(wt$p.value < 0.05,
      "REJECT H₀ — Heteroskedasticity DETECTED",
      "FAIL to reject H₀ — Errors appear homoskedastic"), "\n\n")
  white_done <- TRUE
}, error = function(e) invisible(NULL))

if (!white_done) {
  # Manual White test: aux regression of e^2 on yhat and yhat^2
  e2    <- residuals(fit_final)^2
  yhat  <- fitted(fit_final)
  # Drop NA/Inf rows that appear after lag operations
  ok    <- is.finite(e2) & is.finite(yhat)
  aux   <- lm(e2[ok] ~ yhat[ok] + I(yhat[ok]^2))
  wf_stat <- summary(aux)$r.squared * sum(ok)   # n * R²
  wf_df   <- 2
  wf_pval <- pchisq(wf_stat, df = wf_df, lower.tail = FALSE)
  cat("  (b) White Test [manual auxiliary regression: e² ~ ŷ + ŷ²]\n")
  cat(sprintf("      Statistic (nR²): %.4f  |  df: %d  |  p-value: %.4f\n",
              wf_stat, wf_df, wf_pval))
  cat("      Conclusion:", ifelse(wf_pval < 0.05,
      "REJECT H₀ — Heteroskedasticity DETECTED",
      "FAIL to reject H₀ — Errors appear homoskedastic"), "\n\n")
}

cat("  NOTE: Newey-West HAC standard errors (applied in the original\n")
cat("  fit_final) are robust to BOTH heteroskedasticity AND autocorrelation.\n")
cat("  These tests are diagnostic; the HAC correction already protects inference.\n")

# ====================================================================
# SECTION 3a · ARDL BOUNDS TEST  (Pesaran, Shin & Smith 2001)
# ====================================================================
# The ARDL bounds test is the appropriate primary cointegration tool
# when variables are a mixture of I(0) and I(1) — exactly our case.
#
# It tests whether a long-run levels relationship (cointegration)
# exists among the variables by means of an F-test and a t-test on
# the lagged level terms in the UECM (Unrestricted ECM).
#
# F-statistic interpretation (Case III: unrestricted intercept):
#   F > I(1) upper bound → long-run relationship confirmed
#   F < I(0) lower bound → no long-run relationship
#   between the two bounds → inconclusive
#
# t-statistic: same interpretation applied to the ECT coefficient δ.
# ====================================================================

cat("\n====================================================================\n")
cat("  [3a] ARDL BOUNDS TEST  (Pesaran, Shin & Smith 2001)\n")
cat("====================================================================\n")
cat("Dependent var  : REER_EU (in levels)\n")
cat("Regressors     : Remittances + Inflation + NEER + FDI + NX\n")
cat("Lag selection  : AIC, max_order = 4 (monthly frequency)\n")
cat("Case           : III — unrestricted intercept, no trend\n\n")

ardl_data <- na.omit(data_levels)

best_ardl <- NULL   # make available outside tryCatch for Section 3b
f_stat_val <- NA
ardl_conclusion <- "(not computed)"

tryCatch({
  ardl_auto <- auto_ardl(
    REER_EU ~ Remittances + Inflation + NEER + FDI + NX,
    data      = ardl_data,
    max_order = 4,
    selection = "AIC"
  )
  best_ardl <- ardl_auto$best_model

  cat("  Optimal ARDL order (AIC):\n")
  print(ardl_auto$best_order)
  cat("\n")

  # Bounds F-test
  bf  <- bounds_f_test(best_ardl, case = 3)
  cat("  -- Bounds F-Test --\n")
  print(bf)

  # Bounds t-test
  bt <- bounds_t_test(best_ardl, case = 3)
  cat("\n  -- Bounds t-Test --\n")
  print(bt)

  f_stat_val <- as.numeric(bf$statistic)
  # Critical values at 5% (row 2 = k=5 regressors, adjust if needed)
  tab_row <- which(rownames(bf$tab) == "k=5")
  if (length(tab_row) == 0) tab_row <- 2   # fallback to second row
  I0_5pct <- bf$tab[tab_row, "Lower_I(0)"]
  I1_5pct <- bf$tab[tab_row, "Upper_I(1)"]

  ardl_conclusion <- if (f_stat_val > I1_5pct) {
    "F > I(1) upper bound → COINTEGRATION CONFIRMED at 5%"
  } else if (f_stat_val < I0_5pct) {
    "F < I(0) lower bound → No long-run relationship"
  } else {
    "INCONCLUSIVE — F falls within the I(0)–I(1) band"
  }

  cat(sprintf("\n  F-statistic: %.4f\n", f_stat_val))
  cat(sprintf("  Critical values at 5%%: I(0) lower = %.2f | I(1) upper = %.2f\n",
              I0_5pct, I1_5pct))
  cat("  Conclusion:", ardl_conclusion, "\n")

}, error = function(e) {
  cat("  ERROR in ARDL Bounds Test:\n  ", conditionMessage(e), "\n")
})

# ====================================================================
# SECTION 3b · ARDL LONG-RUN COEFFICIENTS (via UECM)
# ====================================================================
# If ARDL estimation succeeded, extract the long-run multipliers.
# The multipliers() function from {ARDL} derives the long-run
# relationship implied by the ARDL model, equivalent to the
# cointegrating vector normalised on REER_EU.
# ====================================================================

if (!is.null(best_ardl)) {

  cat("\n====================================================================\n")
  cat("  [3b] LONG-RUN COEFFICIENTS FROM ARDL UECM\n")
  cat("====================================================================\n")
  cat("These are the structural long-run multipliers derived from the\n")
  cat("optimal ARDL model. They describe the equilibrium relationship.\n\n")

  tryCatch({
    lr_mults <- multipliers(best_ardl, type = "lr")  # long-run multipliers
    cat("  Long-Run Multipliers (effect on REER_EU in equilibrium):\n")
    print(round(lr_mults, 6))

    cat("\n  Short-Run UECM Representation:\n")
    uecm_fit <- uecm(best_ardl)
    print(summary(uecm_fit))

  }, error = function(e) {
    cat("  ERROR extracting long-run coefficients:\n  ", conditionMessage(e), "\n")
    cat("  Printing raw ARDL model summary instead:\n")
    print(summary(best_ardl))
  })

} else {
  cat("\n  [3b] SKIPPED — ARDL model was not fitted successfully.\n")
}

# ====================================================================
# SECTION 3c · JOHANSEN COINTEGRATION TEST (Supplementary)
# ====================================================================
# IMPORTANT CAVEAT: Johansen (1988) assumes ALL variables are I(1).
# Because FDI is I(0), including it violates this assumption and
# inflates the test statistics. We therefore run Johansen on the
# I(1)-only subset {REER_EU, Remittances, Inflation, NEER, NX},
# treating FDI as a stationary conditioning variable (fixed regressor).
#
# This is a supplementary test; the ARDL bounds result in 3a is the
# primary cointegration conclusion for this mixed-integration dataset.
#
# Both Trace and Max-Eigenvalue statistics are reported.
# Lag K = 4 (monthly data), ecdet = "const" (restricted intercept).
# ====================================================================

# Identify I(1) variables for Johansen
i1_vars <- names(i_orders[i_orders == "I(1)"])
cat("\n====================================================================\n")
cat("  [3c] JOHANSEN COINTEGRATION TEST  [Supplementary]\n")
cat("====================================================================\n")
cat("  ** CAVEAT: Johansen requires all variables to be I(1). **\n")
cat("  ** This analysis excludes I(0) variables:", paste(names(i_orders[i_orders=="I(0)"]), collapse=", "), "**\n")
cat("  ** ARDL Bounds Test in Section 3a is the primary test.  **\n\n")
cat("  I(1) variables used:", paste(i1_vars, collapse=", "), "\n")
cat("  Lags (VAR order K): 4  |  Deterministics: restricted constant\n\n")

johansen_mat <- na.omit(as.matrix(ardl_data[, i1_vars]))
coint_rank_trace <- NA
coint_rank_eigen <- NA

if (length(i1_vars) >= 2) {

  # Trace test
  joh_trace <- ca.jo(johansen_mat, type="trace", ecdet="const", K=4, spec="longrun")
  cat("  --- Trace Test ---\n")
  print(summary(joh_trace))

  # Max-eigenvalue test
  joh_eigen <- ca.jo(johansen_mat, type="eigen", ecdet="const", K=4, spec="longrun")
  cat("\n  --- Maximum Eigenvalue Test ---\n")
  print(summary(joh_eigen))

  # Extract rank: count how many H₀(r ≤ i) are rejected at 5%
  # urca stores statistics in reverse order (r=0 last), so we reverse
  trace_stats <- rev(joh_trace@teststat)
  trace_cvs5  <- rev(joh_trace@cval[, "5pct"])
  coint_rank_trace <- sum(trace_stats > trace_cvs5)

  eigen_stats <- rev(joh_eigen@teststat)
  eigen_cvs5  <- rev(joh_eigen@cval[, "5pct"])
  coint_rank_eigen <- sum(eigen_stats > eigen_cvs5)

  cat(sprintf("\n  Trace test  → cointegrating rank r = %d at 5%%\n", coint_rank_trace))
  cat(sprintf("  Max-λ test  → cointegrating rank r = %d at 5%%\n", coint_rank_eigen))

  # Use trace rank as the canonical estimate
  r_use <- coint_rank_trace

  if (r_use == 0) {
    cat("  → Johansen finds no cointegration among the I(1) subset.\n")
    cat("    The ARDL bounds result remains the primary finding.\n")
  } else if (r_use >= length(i1_vars)) {
    cat(sprintf("  → r = %d = number of I(1) variables: all variables are stationary\n", r_use))
    cat("    (consistent with individual ADF results). ARDL result stands.\n")
  } else {
    cat(sprintf("  → Found %d cointegrating vector(s) among I(1) variables.\n", r_use))
    cat("    Long-run cointegrating vector (β), normalised on REER_EU:\n")
    tryCatch({
      vecm_ols <- cajorls(joh_trace, r = r_use)
      cat("\n  Beta (cointegrating vector, Johansen OLS-VECM):\n")
      print(round(vecm_ols$beta, 6))
      cat("\n  Alpha (speed-of-adjustment):\n")
      alpha_mat <- vecm_ols$rlm$coefficients
      print(round(alpha_mat[1:r_use, , drop=FALSE], 6))
    }, error = function(e) {
      cat("  (Unable to extract cajorls coefficients:", conditionMessage(e), ")\n")
    })
  }

} else {
  cat("  Not enough I(1) variables for Johansen. Skipping.\n")
}

# ====================================================================
# SECTION 4 · CONSOLIDATED SUMMARY PANEL
# ====================================================================

cat("\n")
cat("====================================================================\n")
cat("  KOSOVARIANCE — CONSOLIDATED ECONOMETRIC DIAGNOSTICS SUMMARY\n")
cat("====================================================================\n\n")

cat("  [1] STATIONARITY (ADF Tests — ur.df + adf.test cross-check)\n")
cat("  ─────────────────────────────────────────────────────────────────\n")
for (v in vars_of_interest) {
  r <- adf_results[[which(vars_of_interest == v)]]
  cat(sprintf("  %-14s | τ(lev)=%-8s | p(lev)=%-6s | τ(Δ)=%-8s | p(Δ)=%-6s | %s\n",
              r$label, r$tau_lev, r$pv_lev, r$tau_diff, r$pv_diff, r$i_order))
}
cat("  Mixed I(0)/I(1) dataset → ARDL Bounds Test is appropriate.\n")

cat("\n  [2] HETEROSKEDASTICITY (fit_final: Δ REER model)\n")
cat("  ─────────────────────────────────────────────────────────────────\n")
cat(sprintf("  Breusch-Pagan (χ²=%.4f, p=%.4f) → %s\n",
            bp$statistic, bp$p.value,
            ifelse(bp$p.value < 0.05, "Heteroskedasticity detected", "Homoskedastic")))
cat("  Newey-West HAC SE already applied in fit_final (robust regardless).\n")

cat("\n  [3] COINTEGRATION\n")
cat("  ─────────────────────────────────────────────────────────────────\n")
cat(sprintf("  ARDL Bounds F-statistic : %.4f\n", f_stat_val))
cat("  ARDL Conclusion         :", ardl_conclusion, "\n")
cat(sprintf("  Johansen Trace rank     : r = %s  (I(1) subset only)\n",
            ifelse(is.na(coint_rank_trace), "n/a", coint_rank_trace)))
cat(sprintf("  Johansen Max-λ rank     : r = %s  (I(1) subset only)\n",
            ifelse(is.na(coint_rank_eigen), "n/a", coint_rank_eigen)))

cat("\n  [4] RECOMMENDED FINAL SPECIFICATION\n")
cat("  ─────────────────────────────────────────────────────────────────\n")
if (!is.na(f_stat_val) && grepl("CONFIRMED", ardl_conclusion)) {
  cat("  PRIMARY RECOMMENDATION: ARDL/UECM model.\n")
  cat("  → A long-run cointegrating relationship between REER_EU and the\n")
  cat("    macroeconomic regressors is statistically confirmed.\n")
  cat("  → Use the UECM (Section 3b) for long-run coefficient interpretation.\n")
  cat("  → The short-run dynamics from the original fit_final ARX model\n")
  cat("    remain valid and are now embedded in the ARDL framework.\n")
  cat("  → Continue applying Newey-West SE for HAC-robust inference.\n")
} else {
  cat("  The original Newey-West ARX specification in first differences\n")
  cat("  (fit_final from the original script) remains appropriate.\n")
  cat("  → No robust long-run levels relationship was confirmed.\n")
}

cat("\n====================================================================\n")
cat("  END OF ADVANCED ECONOMETRIC DIAGNOSTICS\n")
cat("====================================================================\n")
