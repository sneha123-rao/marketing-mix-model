install.packages(c("tidyverse", "forecast", "lmtest", "corrplot", "scales", "readr"))
library(tidyverse)
library(forecast)
# ============================================
# MARKETING MIX MODEL
# Sneha Ashok Rao | UCLA Quant Economics
# ============================================

# Load libraries
library(tidyverse)
library(forecast)
library(lmtest)
library(corrplot)
library(scales)

# Load the Advertising dataset
advertising <- read.csv("https://www.statlearning.com/s/Advertising.csv")

# Remove first column (row numbers)
advertising <- advertising[, -1]

# First look at the data
head(advertising)
str(advertising)
summary(advertising)

# ============================================
# STEP 1 — EXPLORATORY DATA ANALYSIS
# ============================================

# Check for missing values
cat("Missing values:", sum(is.na(advertising)), "\n")

# Distribution of Sales
ggplot(advertising, aes(x = sales)) +
  geom_histogram(fill = "#0ea5a0", color = "white", bins = 20) +
  labs(title = "Distribution of Sales",
       x = "Sales (units)",
       y = "Count") +
  theme_minimal()

# Save the plot
ggsave("sales_distribution.png", width = 8, height = 5, dpi = 150)
cat("Plot saved!")
# ============================================
# STEP 2 — CHANNEL vs SALES SCATTER PLOTS
# ============================================

# Reshape data for plotting
advertising_long <- advertising %>%
  pivot_longer(cols = c(TV,radio, newspaper),
               names_to = "Channel",
               values_to = "Spend")

# Plot each channel vs Sales
ggplot(advertising_long, aes(x = Spend, y = sales, color = Channel)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE) +
  facet_wrap(~Channel, scales = "free_x") +
  scale_color_manual(values = c("#0ea5a0", "#f0a500", "#e74c3c")) +
  labs(title = "Advertising Spend vs Sales by Channel",
       x = "Advertising Spend ($000s)",
       y = "Sales (units)") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("channel_vs_sales.png", width = 12, height = 5, dpi = 150)
cat("Plot saved!")

# ============================================
# STEP 3 — CORRELATION ANALYSIS
# ============================================

# Calculate correlations
cor_matrix <- cor(advertising)
print(round(cor_matrix, 3))

# Visualize correlation matrix
png("correlation_matrix.png", width = 800, height = 600, res = 150)
corrplot(cor_matrix,
         method = "color",
         type = "upper",
         addCoef.col = "black",
         tl.col = "black",
         col = colorRampPalette(c("#e74c3c", "white", "#0ea5a0"))(200),
         title = "Advertising Channel Correlation Matrix",
         mar = c(0,0,2,0))
dev.off()
cat("Correlation matrix saved!")

# ============================================
# STEP 4 — MARKETING MIX MODEL (REGRESSION)
# ============================================

# Build the full model
mmm_model <- lm(sales ~ TV + radio + newspaper, data = advertising)

# Model summary
summary(mmm_model)

# Check which channels are statistically significant
cat("\n=== MODEL INTERPRETATION ===\n")
cat("R-squared:", round(summary(mmm_model)$r.squared, 3), "\n")
cat("Adjusted R-squared:", round(summary(mmm_model)$adj.r.squared, 3), "\n")

# ============================================
# STEP 5 — MODEL DIAGNOSTICS & VISUALIZATION
# ============================================

# Actual vs Predicted
advertising$Predicted <- predict(mmm_model)
advertising$Residuals <- residuals(mmm_model)

# Plot actual vs predicted
ggplot(advertising, aes(x = Predicted, y = sales)) +
  geom_point(color = "#0ea5a0", alpha = 0.6) +
  geom_abline(intercept = 0, slope = 1, 
              color = "#e74c3c", linewidth = 1, linetype = "dashed") +
  labs(title = "Actual vs Predicted Sales",
       subtitle = "Marketing Mix Model — R² = 0.897",
       x = "Predicted Sales",
       y = "Actual Sales") +
  theme_minimal()

ggsave("actual_vs_predicted.png", width = 8, height = 6, dpi = 150)

# ROI comparison chart
roi_data <- data.frame(
  Channel = c("TV", "radio", "newspaper"),
  Coefficient = c(0.045, 0.1885, -0.001037),
  Significant = c("Yes", "Yes", "No")
)

ggplot(roi_data, aes(x = reorder(Channel, Coefficient), 
                     y = Coefficient, 
                     fill = Significant)) +
  geom_col(width = 0.5) +
  scale_fill_manual(values = c("Yes" = "#0ea5a0", "No" = "#e74c3c")) +
  labs(title = "Marketing ROI by Channel",
       subtitle = "Units sold per $1,000 additional spend",
       x = "Advertising Channel",
       y = "Incremental Sales per $1,000 Spend",
       fill = "Statistically Significant") +
  theme_minimal() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray")

ggsave("roi_by_channel.png", width = 8, height = 6, dpi = 150)
cat("Plots saved!")

# ============================================
# STEP 6 — TIME SERIES & FORECASTING (ARIMA)
# ============================================

# Convert Sales to time series object
sales_ts <- ts(advertising$sales, frequency = 12)

# Plot the time series
autoplot(sales_ts) +
  labs(title = "Sales Time Series",
       x = "Time Period",
       y = "sales (units)") +
  theme_minimal() +
  geom_line(color = "#0ea5a0", linewidth = 1)

ggsave("sales_timeseries.png", width = 10, height = 5, dpi = 150)

# Fit ARIMA model automatically
arima_model <- auto.arima(sales_ts)
cat("\nBest ARIMA model selected:\n")
print(arima_model)

# Forecast next 12 periods
sales_forecast <- forecast(arima_model, h = 12)

# Plot forecast
autoplot(sales_forecast) +
  labs(title = "Sales Forecast — Next 12 Periods (ARIMA)",
       subtitle = "Shaded areas show 80% and 95% confidence intervals",
       x = "Time Period",
       y = "Sales (units)") +
  theme_minimal()

ggsave("sales_forecast.png", width = 10, height = 6, dpi = 150)
cat("Forecast plots saved!")

# ============================================
# STEP 7 — BUSINESS SUMMARY OUTPUT
# ============================================

cat("================================================\n")
cat("   MARKETING MIX MODEL — EXECUTIVE SUMMARY\n")
cat("================================================\n\n")

cat("DATASET: 200 markets | 3 advertising channels\n\n")

cat("MODEL PERFORMANCE:\n")
cat("  R-squared:        0.897 (89.7% variance explained)\n")
cat("  Adj. R-squared:   0.896\n\n")

cat("CHANNEL ROI (incremental sales per $1,000 spend):\n")
cat("  TV:               +0.045 units *** (significant)\n")
cat("  Radio:            +0.189 units *** (significant)\n")
cat("  Newspaper:        -0.001 units    (NOT significant)\n\n")

cat("KEY FINDINGS:\n")
cat("  1. TV has strongest correlation with sales (r = 0.782)\n")
cat("  2. Radio delivers highest ROI per dollar spent (0.189)\n")
cat("  3. Newspaper spend shows no significant sales impact\n")
cat("  4. Combined channels explain 89.7% of sales variation\n\n")

cat("BUSINESS RECOMMENDATIONS:\n")
cat("  1. Reallocate newspaper budget to Radio — highest ROI\n")
cat("  2. Maintain TV investment — strong brand awareness driver\n")
cat("  3. Optimal mix: Heavy Radio + Strong TV + Zero Newspaper\n\n")

cat("ARIMA FORECAST:\n")
cat("  Model selected: ARIMA(0,0,0) — white noise process\n")
cat("  Interpretation: Sales variation driven by ad spend\n")
cat("  levels, not temporal patterns — regression model\n")
cat("  is more appropriate for this cross-sectional data\n")
cat("================================================\n")
