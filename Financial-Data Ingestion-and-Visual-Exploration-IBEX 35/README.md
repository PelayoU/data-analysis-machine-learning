# Financial Data Ingestion and Visual Exploration (IBEX 35)

This project implements an automated quantitative analysis pipeline in R for the extraction, cleaning, transformation, and statistical analysis of Spanish financial assets (IBEX 35).

The primary objective is to evaluate historical performance, volatility, and correlation of key banking (Santander, BBVA) and insurance (Mapfre) assets against their benchmark, utilizing real-time market data.

![](attachments/Pasted%20image%2020260210022112.png)

## 🚀 Key Features

- **Automated ETL Pipeline:** Custom script designed to ingest historical OHLCV data from Yahoo Finance, bypassing legacy API limitations.
- **Robust Data Sanitation:** Implementation of Listwise Deletion for corrupted API packets and raw data anomalies.
- **Time-Series Imputation Strategy:** Application of Last Observation Carried Forward (LOCF) to handle non-trading days, ensuring continuity without introducing look-ahead bias.
- **Financial Metrics:** Computation of logarithmic returns, cumulative performance, and relative price normalization (Base 100).
- **Statistical Inference:** Estimation of Market Beta (\(\beta\)) and correlation matrices via linear regression models.

## 🧠 Methodology: Data Integrity & Imputation

A critical aspect of this project is the handling of missing data points (NAs) and non-trading days. A hybrid approach was chosen to balance statistical accuracy with financial realism:

### 1. Ingestion Layer: Listwise Deletion

During the initial ETL phase (`DescargaBBVA_MAPFRE.R`), raw data containing API errors or null packets are handled via **Listwise Deletion** (`na.omit`). This ensures that only complete, valid trading records enter the analytical pipeline.

### 2. Processing Layer: Forward Filling (LOCF)

To align time series of different assets (synchronizing holidays or trading halts), the pipeline utilizes **Last Observation Carried Forward (LOCF)** within the `cleanTradingData` module.

- **Rationale:** While statistical methods like Linear Interpolation or Brownian Bridges might preserve volatility structure better, they introduce **Look-Ahead Bias** (using future data to estimate past missing values).
- **Decision:** LOCF was selected as the industry-standard "conservative" approach for financial backtesting, assuming that the asset price remains constant when the market is closed, thus preventing unrealistic profit assumptions in simulation.


### Note:
"Basically, if a trading day (e.g., a Tuesday) contains corrupted data, the download script deletes that row entirely. Later, the processing algorithm compares the data against the standard calendar, notices that Tuesday is missing, and 'regenerates' the day by simply copying the data from Monday to fill the gap."


## 🛠️ Tech Stack

- **Language:** R (4.x)
- **Key Libraries:**
  - `quantmod`: Financial data ingestion and xts time-series management.
  - `ggplot2`: Advanced data visualization.
  - `reshape2`: Data manipulation and melting.
- **Environment:** RStudio.

## ⚙️ System Architecture

The project follows a modular architecture to ensure scalability:

| Module | Description |
|--------|-------------|
| `init.R` | Main orchestrator. Loads dependencies and initializes the environment. |
| `yahoodatatools.R` | Data Management Module. Contains local caching logic and the LOCF imputation algorithms. |
| `DescargaBBVA_MAPFRE.R` | Ingestion Module. Modernized data fetching script using `getSymbols` to resolve Yahoo API deprecation issues. |
| `financialFuns.R` | Quantitative Library. Core financial functions (log returns, relative pricing, volatilities). |
| `ExtraccionDatos.R` | Main Execution Script. Workflow execution and statistical analysis. |

## 📊 Analysis Results

### 1. Relative Performance Analysis (2011 - Present)

Adjusted close prices were normalized to compare the cumulative evolution of BBVA, Santander, and Mapfre against the IBEX 35 benchmark.

![](attachments/Pasted%20image%2020260210022112.png)

**Insight:** The analysis highlights a significant divergence in the banking sector (particularly BBVA) relative to the index in the recent period, outperforming the benchmark.

### 2. Correlation & Beta Analysis

Analyzed the relationship between daily asset returns and market returns using Scatter Plots and Linear Regression.
![](attachments/Pasted%20image%2020260210022257.png)

- **Santander vs. IBEX:** Exhibits a strong positive linear correlation (0.87) with a regression slope beta greater than 1. This indicates the asset acts as a high-beta stock, amplifying systematic market volatility.

![](attachments/Pasted%20image%2020260210022145.png)

- **Mapfre vs. IBEX:** Shows higher dispersion, indicating idiosyncratic risk factors independent of the systematic market trend.

![](attachments/Pasted%20image%2020260210022208.png)
## 🔧 Technical Challenge: API Deprecation

A key engineering challenge was the obsolescence of the original data extraction functions (`yahoo.readbydate`), which relied on deprecated Yahoo Finance endpoints.

**Implemented Solution:**

The ingestion layer was refactored by developing a middleware script (`DescargaBBVA_MAPFRE.R`) that integrates the `quantmod` library. This allowed for:

- Automated handling of session cookies and authentication tokens.
- Seamless transformation of xts objects into the standardized CSV format required by the legacy functions, ensuring backward compatibility.

## 📦 Installation & Usage

1. Clone the repository.
2. Open the project in RStudio.
3. Set the working directory:

```r
setwd("/path/to/your/project")
```

4. Run the pipeline:

```r
source("DescargaBBVA_MAPFRE.R") # Updates local database
source("ExtraccionDatos.R")     # Executes analysis
```
