# DAX 30 — Supervised ML Experiments


Two short, focused supervised-learning experiments on the **DAX 30** index (`^GDAXI`), using the same data-acquisition layer and feature toolbox developed in the IBEX 35 project. The pair is the natural progression from descriptive analysis (Beta, correlation) to **predictive modelling**:

| # | Experiment | Task | Algorithms |
| :--- | :--- | :--- | :--- |
| 01 | KNN regression — 30-session forward return | Continuous regression | k-NN with `FNN::knn.reg`, k = 5 |
| 02 | Caret classification — 65-session direction | Binary classification (UP / DOWN) | k-NN, decision tree (rpart), Naïve Bayes — all via `caret` |

The two scripts are deliberately small (the original course practices), but together they cover the canonical building blocks of a quant ML workflow: technical-indicator features, train/test discipline, scaling, multi-model comparison and inference on out-of-sample instances.

---

## Tech stack

| Area | Choice |
| :--- | :--- |
| Language | R 4.x |
| Data | Yahoo Finance — `^GDAXI` via `quantmod::getSymbols` |
| Indicators | Custom helpers in `features.R` (SMA / EMA / Stochastic / past returns / forward returns) |
| ML — Experiment 01 | `FNN::knn.reg` (KNN regression) |
| ML — Experiment 02 | `caret` (k-NN, `rpart`, Naïve Bayes) |
| Visualisation | base R (`pairs`) |

---

## Project layout

```
dax30-supervised-ml-experiments/
├── R/
│   ├── basedata/
│   │   └── ^GDAXI.csv                  # Raw daily DAX dump
│   ├── init.R                          # Orchestrator: source-fan-out
│   ├── yahoodatatools.R                # CSV cache + LOCF imputation + column normalisation
│   ├── DescargaGDAXI.R                 # quantmod::getSymbols wrapper for ^GDAXI
│   ├── financialFuns.R                 # Log returns, relative pricing, volatilities
│   ├── features.R                      # Technical indicators + forward / backward returns
│   ├── 01-knn-regression.R             # Experiment 01 — KNN regression
│   └── 02-caret-classification.R       # Experiment 02 — caret classification (3 models)
└── README.md
```

The `R/` folder is intentionally self-contained: a copy of the auxiliary scripts (`init.R`, `yahoodatatools.R`, `features.R`, `financialFuns.R`) sits inside the project so it builds and runs without reaching into a sibling project.

---

## Experiment 01 — KNN regression

[`R/01-knn-regression.R`](R/01-knn-regression.R)

### Question

> *"Given today's snapshot of technical indicators, what is the expected log return of the DAX over the next 30 trading sessions?"*

### Pipeline

1. **Data.** `^GDAXI` cached locally from Yahoo Finance, sub-set from 2011-01-01 onwards.
2. **Target.** `Fwd30_Ret = fwdReturns(Adj.Close, 30)` — the 30-session forward log return at every date.
3. **Features (six).**
   - `SMA14`, `SMA50` — deviation from the simple moving average over 14 and 50 sessions.
   - `EMA14`, `EMA50` — deviation from the exponential moving average over the same windows.
   - `Stoch14`, `Stoch30` — stochastic oscillator over 14 and 30 sessions.
4. **Cleaning.** `na.omit()` to drop the warm-up rows (the indicators have a look-back, the target has a 30-session look-ahead, both produce NAs at the boundaries).
5. **Scaling.** Z-score normalisation (`scale()`) of the training matrix; the **mean and stdev are captured** so the inference instance is scaled with the *same* moments — no data leakage.
6. **Model.** `FNN::knn.reg` with `k = 5`. The point estimate is the mean of the five nearest historical states' forward returns.
7. **Inference.** The most recent row (where the target is still NA) is scaled with the train moments and fed into the trained KNN to produce a forecast.

### Why these choices

- **KNN** is intentionally non-parametric: the prediction is *literally* "what happened on average to the five most similar states in history". That's a strong narrative for a financial audience — it's pattern matching, not opaque optimisation.
- Holding `mu_train` and `sd_train` aside instead of scaling everything together is the small detail that prevents look-ahead bias when the scoring instance is only available *after* the training window ends.

### How to run

```r
setwd("R")
source("01-knn-regression.R")
```

The script prints the predicted 30-day return for the latest available DAX state.

---

## Experiment 02 — Caret classification (UP vs DOWN)

[`R/02-caret-classification.R`](R/02-caret-classification.R)

### Question

> *"Will the DAX be higher 65 sessions from now than it is today? Yes or no."*

### Pipeline

1. **Data.** `^GDAXI`, sub-set from 2013-01-01 onwards.
2. **Target.** `daxY65 = factor(fwdReturns(Adj.Close, 65) > 0, labels = c("DOWN", "UP"))`.
3. **Features (three).**
   - `Rent10` — past 10-session log return.
   - `Rent65` — past 65-session log return.
   - `Mavg30` — deviation from the 30-session moving average (`Adj.Close / MA30 - 1`).
4. **Cleaning.** `na.omit()` for the warm-up + look-ahead boundary rows.
5. **Models, all via `caret::train`** (unified API; same data, same control object):
   - **k-NN**, `k = 6`, with `center` / `scale` preprocessing.
   - **Decision tree (`rpart`)**, complexity parameter `cp = 0.02`.
   - **Naïve Bayes (`nb`)** with default kernel.
6. **Inference.** Three hand-crafted instances (mild bear, mild bull, neutral) are scored by all three models. The script prints both the predicted class and the class probabilities.

### What this experiment is for

It is the smallest possible head-to-head between three different inductive biases on the same financial dataset:

- KNN — local averaging in feature space.
- Decision tree — axis-aligned partitioning (interpretable rules).
- Naïve Bayes — independent-feature Gaussian densities.

When the three models agree on a new instance, that's a soft signal. When they disagree, the disagreement itself is informative: each captures a different geometric assumption about the feature space.

### How to run

```r
setwd("R")
source("02-caret-classification.R")
```

The script prints the model-by-model prediction table for the three new instances.

---

## What the two experiments share

Both experiments lean on:

- The **same feature toolbox** (`features.R`) — technical indicators and look-back / look-ahead returns.
- The **same data layer** (`yahoodatatools.R`) with LOCF imputation and the calendar-alignment trick documented in the [IBEX 35 project](../ibex35-data-ingestion-and-visual-exploration).
- The **same hygiene rules** — `na.omit()` to drop warm-up rows, train-derived scaling moments applied to the scoring instance.

That shared infrastructure is the point: by the time the [Euro Stoxx 50 final project](../eurostoxx50-classification-sliding-windows) adds sliding-window evaluation, ensemble methods and feature importance, the data layer and feature toolbox are the same code that ran here.

---

## Reference

Implementation of the supervised-learning practices of *Análisis de Datos en el Sector Financiero*, MU Tecnologías del Sector Financiero (UC3M, 2025/2026) — the bridge between the descriptive IBEX 35 work and the Euro Stoxx 50 final project.
