# ====================================================================
# LIBRARIES
# ====================================================================
library(readxl)
library(here)
library(corrplot)
library(ggplot2)
library(zoo)
library(car)
library(dplyr)
library(lmtest)
library(car)
library(sandwich)
library(latex2exp)
library(tidyr)
library(scales)
library(stargazer)

# ====================================================================
# DATA LOADING & CLEANING
# ====================================================================
MonthlyRemittances <- read_excel(here("data_raw", "Remittances_channel&country.xlsx"), sheet = "Monthly", col_names = TRUE)
View(MonthlyRemittances)

MonthlyRemittances2 <- MonthlyRemittances[-(1:85), ]
corrplot(cor(MonthlyRemittances2[-1]))
MonthlyRemittances2 <- MonthlyRemittances2[-138, ]

ggplot(MonthlyRemittances2, aes(x = Month, y = Remittances)) +
  geom_line(color = "#2C3E50", linewidth = 1) +  # refined dark blue
  scale_y_continuous(labels = comma) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%Y",
    expand = expansion(mult = c(0.01, 0.02))
  ) +
  labs(
    title = "Monthly Remittances",
    subtitle = "Temporal Evolution of Remittance Flows",
    x = NULL,
    y = "Remittances (USD)",
    caption = "Source: Your dataset"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.title.y = element_text(face = "bold"),
    axis.text.x = element_text(size = 10),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    plot.caption = element_text(size = 9, hjust = 0)
  )

# ====================================================================
# ECONOMETRIC MODELING
# ====================================================================

# --- First Model ---
fit <- lm(REER_EU ~ Remittances + Inflation + NEER, data = MonthlyRemittances2)
summary(fit)

# --- Second Model (Quadratic Effect) ---
# negative coefficient for remittances, they are associated with a reduction in the exchange rate
# Inflation e NEER move up the REER
# adding a quadratic effect
MonthlyRemittances2$Remittances_c <- MonthlyRemittances2$Remittances - mean(MonthlyRemittances2$Remittances, na.rm = TRUE)

fit2 <- lm(
  REER_EU ~ Remittances_c + I(Remittances_c^2) + Inflation + NEER,
  data = MonthlyRemittances2
)

summary(fit2)
vif(fit2)

# --- Adding FDI to the quadratic model ---
fit3 <- lm(REER_EU ~ Remittances + I(Remittances^2) + Inflation + NEER + FDI, data = MonthlyRemittances2)
summary(fit3)

# --- Adding Exports to the quadratic ---
fit4 <- lm(REER_EU ~ Remittances + I(Remittances^2) + Inflation + NEER + FDI + Exports, data = MonthlyRemittances2)
summary(fit4)

# --- Adding NX ---
fit5 <- lm(REER_EU ~ Remittances + I(Remittances^2) + Inflation + NEER + FDI + NX, data = MonthlyRemittances2)
summary(fit5)

# --- VIF Checks ---
vif(fit)   # base model
vif(fit2)  # quadratic model
vif(fit3)  # quadratic + FDI
vif(fit4)  # quadratic + FDI + Exports
vif(fit5)  # quadratic + FDI + NX

# ====================================================================
# LAGGED MODELS
# ====================================================================
MonthlyRemittances2 <- MonthlyRemittances2 %>%
  mutate(
    rem_lag1 = lag(Remittances, 1),
    rem_lag2 = lag(Remittances, 2),
    rem_lag3 = lag(Remittances, 3)
  )
data_lagged <- na.omit(MonthlyRemittances2)

# --- 1 Period Lag ---
fit_lag1 <- glm(
  REER_EU ~ rem_lag1 + Inflation + NEER, 
  data = data_lagged, 
  family = gaussian
)

summary(fit_lag1)
par(mfrow = c(2, 3))
plot(fit_lag1)

# --- Distributed Lag ---
fit_dist_lag <- lm(REER_EU ~ Remittances + rem_lag1 + rem_lag2 + Inflation + NEER, data = data_lagged)
summary(fit_dist_lag)

# --- Comparison: Base models vs. Lagged models ---
AIC(fit) 
AIC(fit2) 
AIC(fit3) 
AIC(fit_lag1) 
AIC(fit4) 
AIC(fit5) 
AIC(fit_dist_lag) # best model

# ====================================================================
# DIFFERENCE MODELS
# ====================================================================
master_data_diff <- data.frame(
  d_REER = diff(MonthlyRemittances2$REER_EU),
  d_Remittances = diff(MonthlyRemittances2$Remittances),
  d_Inflation = diff(MonthlyRemittances2$Inflation),
  d_NEER = diff(MonthlyRemittances2$NEER),
  d_FDI = diff(MonthlyRemittances2$FDI),
  d_NX = diff(MonthlyRemittances2$NX),
  d_REERTotal = diff(MonthlyRemittances2$REER_Total),
  d_REERCEFTA = diff(MonthlyRemittances2$REER_CEFTA)
)

fit_diff <- glm(
  d_REER ~ d_Remittances + d_Inflation + d_NEER, 
  data = master_data_diff, 
  family = gaussian
)
summary(fit_diff)

fit_diff2 <- glm(
  d_REER ~ d_Remittances + d_Inflation + d_FDI + d_NX, 
  data = master_data_diff, 
  family = gaussian
)
summary(fit_diff2)

# --- Autocorrelation Test ---
bgtest(fit_diff)
bgtest(fit_diff2)

# --- Check for Reverse Causality ---
grangertest(REER_EU ~ Remittances, order = 1, data = MonthlyRemittances2)
grangertest(Remittances ~ REER_EU, order = 1, data = MonthlyRemittances2)

# ====================================================================
# SEASONALITY ADJUSTMENTS & ROBUST STD. ERRORS
# ====================================================================

# --- Adjustment for seasonality ---
master_data_diff <- master_data_diff %>%
  mutate(
    date = MonthlyRemittances2$Month[-1],
    month = factor(format(as.Date(date), "%b"))  # Jan, Feb, ...
  )

fit_seasonal <- lm(d_REER ~ d_Remittances + d_Inflation + d_FDI + d_NX + month, data = master_data_diff)
coeftest(fit_seasonal, vcov = NeweyWest(fit_seasonal))
summary(fit_seasonal)
AIC(fit_seasonal)

# --- Addition of lag REER ---
master_data_diff <- master_data_diff %>%
  mutate(
    d_REER_lag1 = lag(d_REER, 1),
    d_REER_lag4 = lag(d_REER, 4),
    d_REER_lag12 = lag(d_REER, 12),
    d_REERTotal_lag1 = lag(d_REERTotal, 1),
    d_REERTotal_lag4 = lag(d_REERTotal, 4),
    d_REERTotal_lag12 = lag(d_REERTotal, 12),
    d_REERCEFTA_lag1 = lag(d_REERCEFTA, 1),
    d_REERCEFTA_lag4 = lag(d_REERCEFTA, 4),
    d_REERCEFTA_lag12 = lag(d_REERCEFTA, 12),
    d_Remittances_lag1 = lag(d_Remittances, 1),
    d_Remittances_lag2 = lag(d_Remittances, 2),
    d_Remittances_lag12 = lag(d_Remittances, 12)
  )

fit_final <- lm(
  d_REER ~ d_REER_lag1 + d_REER_lag4 + d_REER_lag12 + 
    d_Remittances + d_Inflation + d_FDI + d_NX + as.factor(month), 
  data = master_data_diff
)
summary(fit_final)

robust_fit <- coeftest(fit_final, vcov = NeweyWest(fit_final))
print(robust_fit)
AIC(fit_final)
bgtest(fit_final, order = 12)
acf(residuals(fit_final))

# --- Run the robust Wald test (equivalent to a robust F-test) ---
robust_f_test <- waldtest(fit_final, vcov = NeweyWest(fit_final))

# Extract the robust F-value and its p-value
rob_f_value <- robust_f_test$F[2]
rob_f_pvalue <- robust_f_test$`Pr(>F)`[2]

# Print the robust metrics
cat("Robust F-statistic:", rob_f_value, "| p-value:", rob_f_pvalue, "\n")

# 1. Save the summary object
sum_fit <- summary(fit_final)

# 2. Extract the R-squared values
r_squared <- sum_fit$r.squared
adj_r_squared <- sum_fit$adj.r.squared

# 3. Extract the standard OLS F-statistic
# Note: R stores the F-statistic, numerator degrees of freedom, 
# and denominator degrees of freedom as a vector of three numbers.
f_stat_values <- sum_fit$fstatistic
f_value <- f_stat_values[1]

# 4. Calculate the standard F-statistic p-value 
# (R doesn't store the p-value directly; you have to calculate it from the F-stat)
f_pvalue <- pf(f_stat_values[1], f_stat_values[2], f_stat_values[3], lower.tail = FALSE)

# Print the standard metrics
cat("Multiple R-squared:", r_squared, "\n")
cat("Adjusted R-squared:", adj_r_squared, "\n")
cat("OLS F-statistic:", f_value, "| p-value:", f_pvalue, "\n")

# --- Quarterly Seasonality ---
master_data_diff <- master_data_diff %>%
  mutate(
    date = MonthlyRemittances2$Month[-1],
    quarter = factor(
      paste0("Q", lubridate::quarter(as.Date(date))),
      levels = c("Q1", "Q2", "Q3", "Q4")
    )
  )

fit_seasonal_q <- lm(d_REER ~ d_Remittances + d_Inflation + d_FDI + d_NX + quarter, data = master_data_diff)
coeftest(fit_seasonal_q, vcov = NeweyWest(fit_seasonal_q))
summary(fit_seasonal_q)
AIC(fit_seasonal_q)

fit_seasonal_q2 <- lm(d_REER ~ d_REER_lag1 + d_REER_lag12 + d_Remittances + d_Inflation + d_FDI + d_NX + quarter, data = master_data_diff)
summary(fit_seasonal_q2)
coeftest(fit_seasonal_q2, vcov = NeweyWest(fit_seasonal_q2))

# coefficient in the first model is negative but become positive if we add seasonality 
# for quarter instead we go back to the previous result
# does it make sense? 
# we should try using seasons instead of months for the dummies
# doing it we found the same negative relation but now the coeff is less significative 

# ====================================================================
# TEST FOR LEAKAGE
# ====================================================================
# Do Remittances drive a worsening Trade Balance (NX)?
# If d_Remittances significantly decreases d_NX, it explains why REER doesn't appreciate.

fit_leakage <- lm(d_NX ~ d_Remittances + d_Inflation + d_REER + month, data = master_data_diff)
summary(fit_leakage)
coeftest(fit_leakage, vcov = NeweyWest(fit_leakage))
acf(residuals(fit_leakage))
bg_test_12 <- bgtest(fit_leakage, order = 12)
print(bg_test_12)

fit_leakage2 <- lm(d_NX ~ d_Remittances + d_Remittances_lag1 + d_Remittances_lag12 + d_Inflation + d_REER + month, data = master_data_diff)
summary(fit_leakage2)
coeftest(fit_leakage2, vcov = NeweyWest(fit_leakage2))
acf(residuals(fit_leakage2))
vif(fit_leakage2)

# --- F test for remittances coefficients ---
linearHypothesis(fit_leakage2, "d_Remittances + d_Remittances_lag1 + d_Remittances_lag12 = 0")

# --- Total effect of remittances on NX ---
coefs <- coef(fit_leakage2)
total_effect <- coefs["d_Remittances"] + coefs["d_Remittances_lag1"] + coefs["d_Remittances_lag12"]
View(total_effect)

robust_f_test <- waldtest(fit_leakage2, vcov = NeweyWest(fit_leakage2))

# Extract the robust F-value and its p-value
rob_f_value <- robust_f_test$F[2]
rob_f_pvalue <- robust_f_test$`Pr(>F)`[2]

# Print the robust metrics
cat("Robust F-statistic:", rob_f_value, "| p-value:", rob_f_pvalue, "\n")

# ====================================================================
# MODEL COMPARISONS
# ====================================================================
stargazer(
  fit_seasonal, fit_leakage, 
  type = "text", 
  column.labels = c("Quarterly", "Monthly"),
  intercept.bottom = FALSE
)

stargazer(
  fit_seasonal_q2, fit_final, 
  type = "text", 
  column.labels = c("Quarterly", "Monthly"),
  intercept.bottom = FALSE
)

# ====================================================================
# GRAPHS & VISUALIZATIONS
# ====================================================================

# --- 1. THE DIASPORA PULSE (Seasonality Boxplot) ---
# Create a proper ordered month factor first
MonthlyRemittances2$Month_Name <- factor(
  format(MonthlyRemittances2$Month, "%b"), 
  levels = c("gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic")
)

ggplot(MonthlyRemittances2, aes(x = Month_Name, y = Remittances)) +
  geom_boxplot(fill = "#BDC3C7", color = "#2C3E50", outlier.color = "#E74C3C") +
  labs(
    title = "The Diaspora Pulse",
    subtitle = "Seasonal Spikes in Remittance Inflows",
    x = "Month",
    y = "Remittances (USD)"
  ) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# --- 2. LEAKAGE OVER TIME (Levels Line Chart) ---
data_plot <- MonthlyRemittances2 %>%
  mutate(Trade_Deficit = -NX) %>% 
  select(Month, Remittances, Trade_Deficit) %>%
  pivot_longer(
    cols = c(Remittances, Trade_Deficit), 
    names_to = "Variable", 
    values_to = "Value"
  )

data_plot$Variable <- factor(
  data_plot$Variable, 
  levels = c("Remittances", "Trade_Deficit"),
  labels = c("Remittances", "Trade Deficit (-NX)")
)

ggplot(data_plot, aes(x = Month, y = Value, color = Variable)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("Remittances" = "#2980B9", "Trade Deficit (-NX)" = "#E74C3C")) +
  labs(
    title = "The Leakage Effect: Remittances and Imports over Time",
    subtitle = "Every remittance inflow immediately finances the trade deficit",
    x = "Year",
    y = "Value (USD)",
    color = "" 
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

# --- 3. SHOCK AND ABSORPTION (Faceted Version) ---
ggplot(data_diff_plot, aes(x = as.Date(date), y = Value, color = Variable)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 0.5) +
  scale_color_manual(values = c(
    "Remittances Change (Δ)" = "#2980B9", 
    "Trade Deficit Change (Δ)" = "#E74C3C"
  )) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  facet_grid(Variable ~ ., scales = "free_y") +
  labs(
    title = "Shock and Absorption: Remittances vs. Imports",
    subtitle = "Comparison of monthly changes (independent Y scales)",
    x = "Year",
    y = "Monthly Change (USD)",
    color = "" 
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none", 
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 11) 
  )

# --- 4. THE OPTICAL ILLUSION (Coefficient Forest Plot) ---
coef_data <- data.frame(
  Model = factor(
    c("1. Base (Differences Only)", "2. Seasonal (Quarters)", "3. Final (Months + REER Lags)"),
    levels = c("3. Final (Months + REER Lags)", "2. Seasonal (Quarters)", "1. Base (Differences Only)")
  ), 
  Estimate = c(-0.0137, -0.0105, 0.0030),
  SE = c(0.0036, 0.0034, 0.0039)
)

coef_data <- coef_data %>%
  mutate(
    CI_lower = Estimate - 1.96 * SE,
    CI_upper = Estimate + 1.96 * SE
  )

ggplot(coef_data, aes(x = Estimate, y = Model)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#E74C3C", linewidth = 1) +
  geom_pointrange(
    aes(xmin = CI_lower, xmax = CI_upper), 
    color = "#2C3E50", size = 1, linewidth = 1.2
  ) +
  labs(
    title = "The Exchange Rate Optical Illusion",
    subtitle = "Adding structural controls neutralizes the impact of remittances on the REER",
    x = "Estimated Coefficient (Impact of Remittances on REER)",
    y = ""
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold", size = 12),
    panel.grid.minor = element_blank()
  )

# --- 5. HISTORICAL REMITTANCE FLOWS (Area + Loess Plot) ---
ggplot(MonthlyRemittances2, aes(x = Month, y = Remittances)) +
  geom_area(fill = "#3498DB", alpha = 0.15) +
  geom_line(color = "#2C3E50", linewidth = 1) +
  geom_smooth(
    method = "loess", span = 0.3, color = "#E74C3C", 
    linetype = "dashed", fill = "#FADBD8", alpha = 0.4, size = 0.8
  ) +
  scale_y_continuous(labels = comma) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Evolution of Monthly Remittance Flows",
    subtitle = "Historical dynamics and growth trend (2014 - 2025)",
    x = NULL, 
    y = "Remittances (USD)", 
    caption = "Data elaboration: Kosovariance Project"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, color = "#2C3E50"),
    plot.subtitle = element_text(size = 13, color = "#7F8C8D", margin = margin(b = 15)),
    axis.text = element_text(color = "#34495E"),
    axis.title.y = element_text(face = "bold", color = "#2C3E50", margin = margin(r = 12)),
    panel.grid.major.y = element_line(color = "#BDC3C7", linewidth = 0.4, linetype = "dotted"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(), 
    plot.caption = element_text(hjust = 0, color = "#95A5A6", size = 10, face = "italic", margin = margin(t = 15))
  )

# --- 6. THE LEAKAGE MAP (Quadrant Scatterplot) ---
quadrant_data <- master_data_diff %>%
  mutate(
    d_Trade_Deficit = -d_NX, 
    Quadrant = case_when(
      d_Remittances > 0 & d_Trade_Deficit > 0 ~ "Pure Leakage (Remittances ↑, Deficit ↑)",
      d_Remittances < 0 & d_Trade_Deficit < 0 ~ "Contraction (Remittances ↓, Deficit ↓)",
      TRUE ~ "Anomalous/Neutral Behavior"
    )
  ) %>%
  select(d_Remittances, d_Trade_Deficit, Quadrant) %>%
  na.omit()

ggplot(quadrant_data, aes(x = d_Remittances, y = d_Trade_Deficit, color = Quadrant)) +
  geom_point(size = 3.5, alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.8) +
  scale_color_manual(values = c(
    "Pure Leakage (Remittances ↑, Deficit ↑)" = "#E74C3C",  
    "Contraction (Remittances ↓, Deficit ↓)" = "#2980B9",   
    "Anomalous/Neutral Behavior" = "#BDC3C7"          
  )) +
  labs(
    title = "The Leakage Map: Where Do the Shocks Go?",
    subtitle = "Data concentration proves excess remittances directly finance the deficit",
    x = "Remittance Shock (Δ USD)",
    y = "Trade Deficit Shock (Δ USD)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(face = "bold")
  )