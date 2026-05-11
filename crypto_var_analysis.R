# ============================================================
# Cryptocurrency VAR Analysis: Ethereum vs Bitcoin (2025)
# Author: Zachary Wehlie
# Date: 2026-05-05
# Description: Vector Autoregression (VAR) modeling to analyze
#              the relationship between ETH and BTC monthly returns.
# ============================================================

# --- Libraries ---
library(quantmod)
library(vars)
library(tseries)
library(urca)


# ============================================================
# SECTION 1: Load Data (2025 only - for descriptive plots)
# ============================================================

getSymbols("ETH-USD", src = "yahoo", from = "2025-01-01", to = "2025-12-31")
getSymbols("BTC-USD", src = "yahoo", from = "2025-01-01", to = "2025-12-31")

# Monthly closing prices
eth_monthly <- to.monthly(Cl(`ETH-USD`), indexAt = "lastof")[, 4]
btc_monthly <- to.monthly(Cl(`BTC-USD`), indexAt = "lastof")[, 4]

# Log returns
eth_ret <- na.omit(diff(log(eth_monthly))) * 100
btc_ret <- na.omit(diff(log(btc_monthly))) * 100

colnames(eth_ret) <- "ETH"
colnames(btc_ret) <- "BTC"

cat("=== ETH Monthly Returns ===\n")
print(eth_ret)

cat("=== BTC Monthly Returns ===\n")
print(btc_ret)

cat("=== Summary: ETH ===\n")
print(summary(as.numeric(eth_ret)))

cat("=== Summary: BTC ===\n")
print(summary(as.numeric(btc_ret)))


# ============================================================
# SECTION 2: Prices and Returns Plot
# ============================================================

par(mfrow = c(2, 2))

plot(as.numeric(eth_monthly), main = "ETH Monthly Closing Price (2025)",
     ylab = "USD", col = "purple", lwd = 2, type = "l", xlab = "Month")

plot(as.numeric(btc_monthly), main = "BTC Monthly Closing Price (2025)",
     ylab = "USD", col = "darkorange", lwd = 2, type = "l", xlab = "Month")

plot(as.numeric(eth_ret), main = "ETH Monthly Log Returns (2025)",
     ylab = "%", col = "purple", lwd = 2, type = "l", xlab = "Month")
abline(h = 0, col = "red", lty = 2)

plot(as.numeric(btc_ret), main = "BTC Monthly Log Returns (2025)",
     ylab = "%", col = "darkorange", lwd = 2, type = "l", xlab = "Month")
abline(h = 0, col = "red", lty = 2)

par(mfrow = c(1, 1))


# ============================================================
# SECTION 3: Stationarity Testing (ADF Test)
# ============================================================

cat("=== ADF Tests ===\n")
adf_eth <- adf.test(as.numeric(eth_ret))
adf_btc <- adf.test(as.numeric(btc_ret))

cat("ETH -> p-value:", round(adf_eth$p.value, 4),
    ifelse(adf_eth$p.value < 0.05, "(Stationary)", "(Non-stationary)"), "\n")
cat("BTC -> p-value:", round(adf_btc$p.value, 4),
    ifelse(adf_btc$p.value < 0.05, "(Stationary)", "(Non-stationary)"), "\n")


# ============================================================
# SECTION 4: VAR Model (2020-2025 full dataset)
# ============================================================

getSymbols("ETH-USD", src = "yahoo", from = "2020-01-01", to = "2025-12-31")
getSymbols("BTC-USD", src = "yahoo", from = "2020-01-01", to = "2025-12-31")

eth_monthly <- to.monthly(Cl(`ETH-USD`), indexAt = "lastof")[, 4]
btc_monthly <- to.monthly(Cl(`BTC-USD`), indexAt = "lastof")[, 4]

eth_ret <- na.omit(diff(log(eth_monthly))) * 100
btc_ret <- na.omit(diff(log(btc_monthly))) * 100

# Combine for VAR
var_data <- na.omit(merge(eth_ret, btc_ret))
colnames(var_data) <- c("ETH", "BTC")
var_data <- as.data.frame(var_data)

# Lag selection using BIC
lag_select <- VARselect(var_data, lag.max = 4, type = "const")
cat("=== Lag Selection ===\n")
print(lag_select$selection)

# Fit VAR model
p_opt   <- lag_select$selection["SC(n)"]
var_fit <- VAR(var_data, p = max(p_opt, 1), type = "const")

cat("=== VAR Summary ===\n")
summary(var_fit)


# ============================================================
# SECTION 5: Granger Causality
# ============================================================

cat("=== Does BTC Granger-cause ETH? ===\n")
causality(var_fit, cause = "BTC")

cat("=== Does ETH Granger-cause BTC? ===\n")
causality(var_fit, cause = "ETH")


# ============================================================
# SECTION 6: Impulse Response Functions
# ============================================================

par(mfrow = c(1, 2))

irf_btc_eth <- irf(var_fit,
                   impulse  = "BTC",
                   response = "ETH",
                   n.ahead  = 6,
                   boot     = TRUE,
                   ci       = 0.95)
plot(irf_btc_eth, main = "ETH Response to BTC Shock")

irf_eth_btc <- irf(var_fit,
                   impulse  = "ETH",
                   response = "BTC",
                   n.ahead  = 6,
                   boot     = TRUE,
                   ci       = 0.95)
plot(irf_eth_btc, main = "BTC Response to ETH Shock")

par(mfrow = c(1, 1))


# ============================================================
# SECTION 7: Forecast Error Variance Decomposition (FEVD)
# ============================================================

vd <- fevd(var_fit, n.ahead = 6)
plot(vd, main = "Forecast Error Variance Decomposition")

cat("=== Variance Decomposition: ETH ===\n")
print(round(vd$ETH, 4))

cat("=== Variance Decomposition: BTC ===\n")
print(round(vd$BTC, 4))


# ============================================================
# SECTION 8: 3-Month Ahead Forecast
# ============================================================

eth_forecast <- predict(var_fit, n.ahead = 3)
plot(eth_forecast, main = "3-Month Ahead Forecast")

cat("=== 3-Month ETH Return Forecast ===\n")
print(eth_forecast$fcst$ETH)

cat("=== 3-Month BTC Return Forecast ===\n")
print(eth_forecast$fcst$BTC)


# ============================================================
# SECTION 9: Model Performance (MAE and RMSE)
# ============================================================

eth_residuals <- residuals(var_fit)[, "ETH"]
btc_residuals <- residuals(var_fit)[, "BTC"]

mae_eth  <- mean(abs(eth_residuals))
rmse_eth <- sqrt(mean(eth_residuals^2))

mae_btc  <- mean(abs(btc_residuals))
rmse_btc <- sqrt(mean(btc_residuals^2))

cat("=== ETH Forecast Performance ===\n")
cat("MAE:", round(mae_eth, 4), "\n")
cat("RMSE:", round(rmse_eth, 4), "\n\n")

cat("=== BTC Forecast Performance ===\n")
cat("MAE:", round(mae_btc, 4), "\n")
cat("RMSE:", round(rmse_btc, 4), "\n")
