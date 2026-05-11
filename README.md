# Cryptocurrency VAR Analysis Report 📈

## Overview

This project analyzes the monthly relationship between Ethereum (ETH) and Bitcoin (BTC) in 2025 using Vector Autoregression (VAR) modeling. The goal is to determine whether Bitcoin price movements Granger-cause Ethereum returns, how each cryptocurrency responds to shocks in the other, and how much of Ethereum's variation is explained by Bitcoin.

## Key Findings ✅

- Bitcoin and Ethereum show a strong positive co-movement in 2025.
- BTC has predictive power over ETH, and ETH also Granger-causes BTC.
- A positive BTC shock produces a short-lived ETH gain that fades after about 3 months.
- ETH is more volatile than BTC, and the VAR model had higher error for ETH than BTC.
- Forecast uncertainty is very high, which is expected for crypto returns.

## Data Summary 📊

- Source: Yahoo Finance via the `quantmod` package in R.
- Sample range for VAR model: January 2020 through December 2025.
- Monthly observations used for the 2025-only plots: February through December 2025 (11 observations).
- ETH mean monthly return: 3.95%, SD: 23.7%, range: -59.9% to +57.8%.
- BTC mean monthly return: 3.15%, SD: 17.95%, range: -47.4% to +39.1%.
- Correlation between ETH and BTC returns: 0.765.

## Methodology 🔧

### Data Preparation

- Download monthly closing prices for `ETH-USD` and `BTC-USD` using `quantmod::getSymbols`.
- Convert to monthly frequency with `to.monthly()`.
- Compute log returns via `diff(log(price)) * 100`.
- Merge ETH and BTC return series for VAR modeling.

### Stationarity Testing

- Apply Augmented Dickey-Fuller (ADF) tests on both return series using `tseries::adf.test()`.
- Confirm stationarity before model estimation.
- ETH showed a surprising non-stationary result in 2025 due to limited observations, so differencing was used to ensure stationarity.

### VAR Model Estimation

- Use `vars::VARselect()` to choose the optimal lag order based on BIC.
- Fit a bivariate VAR model with `vars::VAR()` using endogenous variables `ETH` and `BTC`.
- Examine coefficient estimates and interpret how past returns of one cryptocurrency predict the other.

### Causality and Dynamics

- Test bidirectional Granger causality with `vars::causality()`.
- Compute impulse response functions with `vars::irf()` to track shocks across 6 months.
- Perform forecast error variance decomposition with `vars::fevd()` to assess the influence of each series on the other.

### Forecasting and Error Metrics

- Generate 3-month ahead forecasts for ETH and BTC using the fitted VAR model.
- Evaluate forecast performance using MAE and RMSE from residuals.

## Detailed Models Used 🧠

### Vector Autoregression (VAR)

A VAR model is a multivariate time-series model in which each variable is regressed on lagged values of itself and the other variables in the system.

- Applied to ETH and BTC monthly log returns.
- Allows analysis of dynamic responses between the two cryptocurrencies.
- Supports impulse response and variance decomposition analysis.

### Granger Causality

Granger causality tests whether past values of one series contain useful information to forecast another series.

- Tested both `BTC -> ETH` and `ETH -> BTC`.
- Found evidence that both series have predictive power for the other.

### Impulse Response Analysis

Impulse response functions show how a one standard deviation shock to one cryptocurrency affects the other over time.

- A BTC shock leads to a peak ETH response around month 2.
- A ETH shock leads to a BTC response around month 1.
- Both responses fade near zero by month 3.

### Forecast Error Variance Decomposition

This analysis quantifies how much of each variable's forecast error variance is explained by shocks to itself versus shocks to the other variable.

- ETH is mostly explained by its own past movements.
- BTC shows a larger contribution from ETH shocks than expected.

## Code Outline 💻

### Core Packages

- `quantmod`
- `vars`
- `tseries`
- `urca`

### Example Code Blocks

#### Load and prepare data

```r
library(quantmod)
library(vars)
library(tseries)
library(urca)

getSymbols("ETH-USD", src = "yahoo", from = "2020-01-01", to = "2025-12-31")
getSymbols("BTC-USD", src = "yahoo", from = "2020-01-01", to = "2025-12-31")

eth_monthly <- to.monthly(Cl(`ETH-USD`), indexAt = "lastof")[, 4]
btc_monthly <- to.monthly(Cl(`BTC-USD`), indexAt = "lastof")[, 4]

eth_ret <- na.omit(diff(log(eth_monthly))) * 100
btc_ret <- na.omit(diff(log(btc_monthly))) * 100

var_data <- na.omit(merge(eth_ret, btc_ret))
colnames(var_data) <- c("ETH", "BTC")
var_data <- as.data.frame(var_data)
```

#### Select lag order and fit VAR

```r
lag_select <- VARselect(var_data, lag.max = 4, type = "const")
p_opt <- lag_select$selection["SC(n)"]
var_fit <- VAR(var_data, p = max(p_opt, 1), type = "const")
summary(var_fit)
```

#### Granger causality

```r
causality(var_fit, cause = "BTC")
causality(var_fit, cause = "ETH")
```

#### Impulse response and variance decomposition

```r
irf_btc_eth <- irf(var_fit, impulse = "BTC", response = "ETH", n.ahead = 6, boot = TRUE, ci = 0.95)
irf_eth_btc <- irf(var_fit, impulse = "ETH", response = "BTC", n.ahead = 6, boot = TRUE, ci = 0.95)
vd <- fevd(var_fit, n.ahead = 6)
```

#### Forecast and error metrics

```r
eth_forecast <- predict(var_fit, n.ahead = 3)
btc_forecast <- predict(var_fit, n.ahead = 3)

eth_residuals <- residuals(var_fit)[, "ETH"]
btc_residuals <- residuals(var_fit)[, "BTC"]

mae_eth <- mean(abs(eth_residuals))
rmse_eth <- sqrt(mean(eth_residuals^2))

mae_btc <- mean(abs(btc_residuals))
rmse_btc <- sqrt(mean(btc_residuals^2))
```

## Results Summary 📌

- VAR selected lag order 1 by BIC.
- BTC lag 1 coefficient for ETH was positive and significant.
- BTC Granger-causes ETH with strong evidence.
- ETH also Granger-causes BTC, indicating bidirectional influence.
- ETH MAE: 17.35%, RMSE: 22.06%.
- BTC MAE: 13.08%, RMSE: 16.86%.
- Forecast intervals are wide, showing large uncertainty.

## Conclusions 🧾

- BTC and ETH are tightly linked in 2025, moving together within the same month.
- The VAR model confirms a two-way relationship rather than one directional causality.
- Cryptocurrency forecasts should be treated with caution due to high volatility.
- A longer historical dataset would improve future analysis and model reliability.

## Future Work 🚀

- Expand the dataset beyond 2025 for more robust estimation.
- Explore longer-term dynamics and structural breaks.
- Compare VAR to other models such as VECM, GARCH, or machine learning approaches.
- Investigate whether macroeconomic or blockchain-specific variables improve forecast accuracy.

## References 📚

- Yahoo Finance via `quantmod` for ETH-USD and BTC-USD monthly data.
- R packages: `quantmod`, `vars`, `tseries`, `urca`.

---

> This README is written to accompany the detailed R Markdown analysis in `Project Report (Time Series).Rmd`.
