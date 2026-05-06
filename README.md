# Data Analysis & Machine Learning


Three financial-data analytics projects in **R**, building from descriptive statistics to predictive modelling. The work was developed during my **MSc in Financial Sector Technologies (UC3M)**, in the *Análisis de Datos en el Sector Financiero* course.

The three projects share a common data-acquisition layer (`quantmod` + a custom CSV cache + LOCF imputation), and progress in scope and ambition: from a single-asset descriptive analysis on the IBEX 35, through a paired supervised-learning experiment on the DAX 30, to a sliding-window evaluation of three classifiers vs a randomised baseline on the Euro Stoxx 50.

---

## Project index

| Project | Stack | Focus |
| :--- | :--- | :--- |
| **[ibex35-data-ingestion-and-visual-exploration](./ibex35-data-ingestion-and-visual-exploration)** | R · `quantmod` · `xts` · `ggplot2` | Modular ETL pipeline for the IBEX 35 + BBVA / Santander / Mapfre. LOCF imputation without look-ahead bias, Beta and correlation analysis via OLS regression, four pre-rendered figures showing relative performance and high-beta vs idiosyncratic-risk profiles. |
| **[dax30-supervised-ml-experiments](./dax30-supervised-ml-experiments)** | R · `FNN` · `caret` · `rpart` · `e1071` | Two paired experiments on the DAX 30: (1) **KNN regression** of the 30-session forward return over six technical indicators with leakage-safe scaling; (2) **`caret`-based classification** of the 65-session direction with k-NN, decision tree and Naïve Bayes head-to-head. |
| **[eurostoxx50-classification-sliding-windows](./eurostoxx50-classification-sliding-windows)** | R · `randomForest` · `rpart` · `pROC` · Quarto | Final practice: predict Euro Stoxx 50 50-session direction using logistic regression, CART and Random Forest. Evaluated on **expanding sliding windows** with a 50-run randomised baseline. Honest negative result — no model beats random by more than 1 % on accuracy / F1. The discipline that makes that conclusion trustworthy is the substance. |

---

## Areas of focus

- **R-based ETL** — `quantmod` ingestion, local CSV cache, LOCF imputation that preserves the trading calendar without reaching into the future.
- **Descriptive statistics on financial time series** — log returns, base-100 normalisation, OLS-derived market beta, correlation matrices.
- **Supervised ML** — KNN regression, k-NN / decision tree / Naïve Bayes classification via `caret`'s unified API, ensemble methods (Random Forest), feature importance.
- **Backtest discipline** — strict sliding-window evaluation, randomised baseline, multi-metric scoring (accuracy / precision / recall / F1 / AUC), no global hyperparameter leakage.
- **Reproducibility** — Quarto / R Markdown reports, versioned CSV outputs, idempotent main scripts.

---

## Author

**Pelayo Urzaiz**

- BSc in Applied Statistics — Universidad Complutense de Madrid (UCM)
- MSc in Financial Technologies (FinTech) — Universidad Carlos III de Madrid (UC3M)
- MSc in Quantitative Finance — Universidad Nacional de Educación a Distancia (UNED)

[LinkedIn Profile](https://www.linkedin.com/in/pelayourzaiz/)
