# ============================================================================
# main.R — Clasificación Euro Stoxx 50: Rentabilidad positiva a 50 sesiones
# ============================================================================
# Master Fintech UC3M — Análisis de Datos en el Sector Financiero
# Autor: Pelayo Urzaiz
# ============================================================================
#
# Este script:
#   1. Descarga datos históricos del Euro Stoxx 50 desde Yahoo Finance
#   2. Calcula indicadores técnicos (tendencia, momentum, volatilidad)
#   3. Entrena 3 modelos de clasificación + clasificador aleatorio (baseline)
#   4. Evalúa mediante ventanas deslizantes acumulativas
#   5. Genera tablas de métricas y gráficas comparativas
#
# Ejecución:
#   cd eurostoxx50_clasificacion
#   Rscript main.R
#
# ============================================================================

# --- 0. SETUP ----------------------------------------------------------------

packages <- c("quantmod", "TTR", "rpart", "randomForest",
              "pROC", "ggplot2", "reshape2")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cran.r-project.org")
  library(pkg, character.only = TRUE)
}

set.seed(42)

local({
  args <- commandArgs(trailingOnly = FALSE)
  m    <- grep("--file=", args)
  if (length(m) > 0)
    setwd(dirname(normalizePath(sub("--file=", "", args[m]))))
})

dir.create("data",    showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

N_FWD       <- 50        # horizonte de predicción (sesiones)
YEAR_START  <- 2010      # primer año del modelo
MIN_TRAIN   <- 3         # años mínimos de entrenamiento
N_RAND_RUNS <- 50        # repeticiones del clasificador aleatorio

# --- 1. DESCARGA DE DATOS ----------------------------------------------------

cat("=== 1. Datos ===\n")
raw_file <- "data/eurostoxx50_raw.rds"

if (file.exists(raw_file)) {
  cat("  Cargando datos locales...\n")
  stoxx <- readRDS(raw_file)
} else {
  cat("  Descargando Euro Stoxx 50 (^STOXX50E) desde Yahoo Finance...\n")
  stoxx_xts <- getSymbols("^STOXX50E", src = "yahoo",
                          from = "2009-01-01", auto.assign = FALSE)
  stoxx <- data.frame(
    Date      = index(stoxx_xts),
    Open      = as.numeric(Op(stoxx_xts)),
    High      = as.numeric(Hi(stoxx_xts)),
    Low       = as.numeric(Lo(stoxx_xts)),
    Close     = as.numeric(Cl(stoxx_xts)),
    Volume    = as.numeric(Vo(stoxx_xts)),
    Adj.Close = as.numeric(Ad(stoxx_xts))
  )
  stoxx <- stoxx[complete.cases(stoxx[, c("Open","High","Low","Close","Adj.Close")]), ]
  rownames(stoxx) <- NULL
  saveRDS(stoxx, raw_file)
  cat("  Guardado en", raw_file, "\n")
}

cat("  Registros:", nrow(stoxx),
    "| Rango:", as.character(min(stoxx$Date)),
    "—", as.character(max(stoxx$Date)), "\n")

# --- 2. VARIABLE OBJETIVO ----------------------------------------------------

cat("\n=== 2. Variable objetivo ===\n")

stoxx$ret_1d <- c(NA, diff(log(stoxx$Adj.Close)))

nr <- nrow(stoxx)
stoxx$ret_50d_fwd <- c(
  stoxx$Adj.Close[(N_FWD + 1):nr] / stoxx$Adj.Close[1:(nr - N_FWD)] - 1,
  rep(NA, N_FWD)
)

stoxx$y <- ifelse(stoxx$ret_50d_fwd > 0, 1, 0)

cat("  Positivos:", sum(stoxx$y == 1, na.rm = TRUE),
    "| Negativos:", sum(stoxx$y == 0, na.rm = TRUE), "\n")

# --- 3. INGENIERÍA DE CARACTERÍSTICAS ----------------------------------------

cat("\n=== 3. Características ===\n")

build_features <- function(df) {
  price <- df$Adj.Close
  high  <- df$High
  low   <- df$Low
  cls   <- df$Close
  ret   <- df$ret_1d
  n     <- nrow(df)

  # ---- Tendencia ----
  df$SMA10_dev <- price / SMA(price, n = 10) - 1
  df$SMA50_dev <- price / SMA(price, n = 50) - 1
  df$EMA20_dev <- price / EMA(price, n = 20) - 1

  df$slope_20 <- NA_real_
  for (i in 20:n) {
    win <- price[(i - 19):i]
    df$slope_20[i] <- coef(lm(win ~ seq_along(win)))[2] / mean(win)
  }

  # ---- Momentum ----
  df$RSI_14 <- RSI(price, n = 14)
  df$ROC_10 <- ROC(price, n = 10, type = "discrete") * 100
  df$ROC_20 <- ROC(price, n = 20, type = "discrete") * 100

  hlc_mat   <- cbind(High = high, Low = low, Close = cls)
  stoch_res <- stoch(hlc_mat, nFastK = 14, nFastD = 3, nSlowD = 3)
  df$Stoch_K <- as.numeric(stoch_res[, "fastK"]) * 100

  # ---- Volatilidad ----
  df$vol_20 <- runSD(ret, n = 20)
  df$vol_50 <- runSD(ret, n = 50)

  prev_cls <- c(NA, cls[-n])
  tr <- pmax(high - low,
             abs(high - prev_cls),
             abs(low  - prev_cls), na.rm = TRUE)
  df$ATR_14 <- SMA(tr, n = 14) / price

  # ---- Retornos pasados ----
  df$ret_5d  <- ROC(price, n = 5,  type = "discrete")
  df$ret_20d <- ROC(price, n = 20, type = "discrete")

  return(df)
}

stoxx <- build_features(stoxx)

feature_cols <- c("SMA10_dev", "SMA50_dev", "EMA20_dev", "slope_20",
                  "RSI_14", "ROC_10", "ROC_20", "Stoch_K",
                  "vol_20", "vol_50", "ATR_14",
                  "ret_5d", "ret_20d")

df_model <- stoxx[, c("Date", "y", feature_cols)]
df_model <- df_model[complete.cases(df_model), ]
df_model$year <- as.numeric(format(df_model$Date, "%Y"))
df_model <- df_model[df_model$year >= YEAR_START, ]
rownames(df_model) <- NULL

cat("  Dataset:", nrow(df_model), "obs x", length(feature_cols), "features\n")
cat("  Proporción positivos:", round(mean(df_model$y), 4), "\n")
saveRDS(df_model, "data/eurostoxx50_features.rds")

# --- 4. FUNCIONES DE MODELOS -------------------------------------------------

train_and_predict <- function(model_type, X_train, y_train, X_test) {
  train_df <- data.frame(y = factor(y_train, levels = c(0, 1)), X_train)
  test_df  <- data.frame(X_test)

  if (model_type == "Logistic") {
    suppressWarnings({
      fit <- glm(y ~ ., data = train_df, family = binomial)
    })
    probs <- predict(fit, newdata = test_df, type = "response")
    probs <- pmin(pmax(as.numeric(probs), 1e-4), 1 - 1e-4)

  } else if (model_type == "DecisionTree") {
    fit <- rpart(y ~ ., data = train_df, method = "class",
                 control = rpart.control(cp = 0.005, minsplit = 30))
    probs <- as.numeric(predict(fit, newdata = test_df, type = "prob")[, "1"])

  } else if (model_type == "RandomForest") {
    fit <- randomForest(y ~ ., data = train_df, ntree = 500, importance = TRUE)
    probs <- as.numeric(predict(fit, newdata = test_df, type = "prob")[, "1"])
  }

  list(probs = probs, model = fit)
}

compute_metrics <- function(y_true, probs, threshold = 0.5) {
  preds <- as.integer(probs >= threshold)
  tp <- sum(preds == 1 & y_true == 1)
  fp <- sum(preds == 1 & y_true == 0)
  fn <- sum(preds == 0 & y_true == 1)
  tn <- sum(preds == 0 & y_true == 0)

  acc  <- (tp + tn) / length(y_true)
  prec <- if ((tp + fp) > 0) tp / (tp + fp) else 0
  rec  <- if ((tp + fn) > 0) tp / (tp + fn) else 0
  f1   <- if ((prec + rec) > 0) 2 * prec * rec / (prec + rec) else 0

  auc_val <- tryCatch({
    as.numeric(pROC::auc(pROC::roc(y_true, probs, quiet = TRUE)))
  }, error = function(e) NA_real_)

  data.frame(Accuracy = acc, Precision = prec, Recall = rec, F1 = f1, AUC = auc_val)
}

random_classifier_metrics <- function(y_train, y_test, n_rep = N_RAND_RUNS) {
  p_hat <- mean(y_train)
  mat   <- matrix(0, nrow = n_rep, ncol = 4,
                  dimnames = list(NULL, c("Accuracy","Precision","Recall","F1")))

  for (r in seq_len(n_rep)) {
    rp <- sample(c(0L, 1L), length(y_test), replace = TRUE,
                 prob = c(1 - p_hat, p_hat))
    tp <- sum(rp == 1 & y_test == 1)
    fp <- sum(rp == 1 & y_test == 0)
    fn <- sum(rp == 0 & y_test == 1)
    tn <- sum(rp == 0 & y_test == 0)
    mat[r, "Accuracy"]  <- (tp + tn) / length(y_test)
    pr <- if ((tp + fp) > 0) tp / (tp + fp) else 0
    re <- if ((tp + fn) > 0) tp / (tp + fn) else 0
    mat[r, "Precision"] <- pr
    mat[r, "Recall"]    <- re
    mat[r, "F1"]        <- if ((pr + re) > 0) 2 * pr * re / (pr + re) else 0
  }

  avg <- colMeans(mat)
  data.frame(Accuracy  = avg["Accuracy"],  Precision = avg["Precision"],
             Recall    = avg["Recall"],    F1        = avg["F1"],
             AUC       = 0.5)
}

# --- 5. VALIDACIÓN CON VENTANAS DESLIZANTES ----------------------------------

cat("\n=== 5. Ventanas deslizantes ===\n")

years      <- sort(unique(df_model$year))
test_years <- years[years >= (YEAR_START + MIN_TRAIN)]

cat("  Entrenamiento desde:", YEAR_START, "\n")
cat("  Años de test:", paste(test_years, collapse = ", "), "\n")
cat("  Iteraciones:", length(test_years), "\n\n")

model_types   <- c("Logistic", "DecisionTree", "RandomForest")
all_metrics   <- data.frame()
all_preds     <- data.frame()
last_rf_model <- NULL

for (ty in test_years) {
  cat("  [", ty, "] Train", YEAR_START, "-", ty - 1, "| Test", ty, "\n")

  idx_tr <- df_model$year < ty
  idx_te <- df_model$year == ty

  if (sum(idx_te) < 20) {
    cat("    Pocas obs de test (", sum(idx_te), "), saltando.\n")
    next
  }

  X_tr <- df_model[idx_tr, feature_cols]
  y_tr <- df_model$y[idx_tr]
  X_te <- df_model[idx_te, feature_cols]
  y_te <- df_model$y[idx_te]

  cat("    n_train=", nrow(X_tr), " n_test=", nrow(X_te),
      " p(+)_tr=", round(mean(y_tr), 3),
      " p(+)_te=", round(mean(y_te), 3), "\n")

  for (mt in model_types) {
    res <- tryCatch(
      train_and_predict(mt, X_tr, y_tr, X_te),
      error = function(e) {
        cat("    WARN", mt, ":", conditionMessage(e), "\n")
        list(probs = rep(mean(y_tr), nrow(X_te)), model = NULL)
      }
    )

    m <- compute_metrics(y_te, res$probs)
    all_metrics <- rbind(all_metrics, data.frame(
      test_year = ty, model = mt,
      n_train = nrow(X_tr), n_test = nrow(X_te),
      p_pos_train = mean(y_tr), p_pos_test = mean(y_te),
      m, stringsAsFactors = FALSE
    ))

    all_preds <- rbind(all_preds, data.frame(
      Date = df_model$Date[idx_te], test_year = ty, model = mt,
      y_true = y_te, prob = res$probs,
      y_pred = as.integer(res$probs >= 0.5)
    ))

    if (mt == "RandomForest") last_rf_model <- res$model
  }

  # Clasificador aleatorio
  rm_m <- random_classifier_metrics(y_tr, y_te)
  all_metrics <- rbind(all_metrics, data.frame(
    test_year = ty, model = "Random",
    n_train = nrow(X_tr), n_test = nrow(X_te),
    p_pos_train = mean(y_tr), p_pos_test = mean(y_te),
    rm_m, stringsAsFactors = FALSE
  ))

  p_hat <- mean(y_tr)
  rnd_pred <- sample(c(0L, 1L), nrow(X_te), replace = TRUE,
                     prob = c(1 - p_hat, p_hat))
  all_preds <- rbind(all_preds, data.frame(
    Date = df_model$Date[idx_te], test_year = ty, model = "Random",
    y_true = y_te, prob = p_hat, y_pred = rnd_pred
  ))
}

write.csv(all_metrics, "results/metrics_windowed.csv", row.names = FALSE)
write.csv(all_preds,   "results/predictions_all.csv",  row.names = FALSE)

if (!is.null(last_rf_model))
  saveRDS(importance(last_rf_model), "results/rf_importance.rds")

# --- 6. AGREGACIÓN Y VISUALIZACIÓN -------------------------------------------

cat("\n=== 6. Resultados ===\n")

agg_mean <- aggregate(cbind(Accuracy, Precision, Recall, F1, AUC) ~ model,
                      data = all_metrics, FUN = mean, na.rm = TRUE)
agg_sd   <- aggregate(cbind(Accuracy, Precision, Recall, F1, AUC) ~ model,
                      data = all_metrics, FUN = sd,   na.rm = TRUE)
colnames(agg_sd)[-1] <- paste0(colnames(agg_sd)[-1], "_sd")

summary_tbl <- merge(agg_mean, agg_sd, by = "model")
summary_tbl <- summary_tbl[order(-summary_tbl$AUC), ]

cat("\n  Métricas medias por modelo:\n")
print_tbl <- summary_tbl
print_tbl[, -1] <- round(print_tbl[, -1], 4)
print(print_tbl)
write.csv(summary_tbl, "results/metrics_summary.csv", row.names = FALSE)

# ---- Paleta de colores ----
model_colors <- c(Logistic     = "#2196F3",
                  DecisionTree = "#4CAF50",
                  RandomForest = "#FF5722",
                  Random       = "#9E9E9E")

theme_set(theme_minimal(base_size = 13))

# Fig 1: Accuracy por año
p1 <- ggplot(all_metrics, aes(test_year, Accuracy, color = model, group = model)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2.3) +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = unique(all_metrics$test_year)) +
  labs(title = "Accuracy por año de test",
       x = "Año de test", y = "Accuracy", color = "Modelo")
ggsave("figures/accuracy_temporal.png", p1, width = 10, height = 5.5, dpi = 150)

# Fig 2: AUC por año
auc_data <- all_metrics[!is.na(all_metrics$AUC), ]
p2 <- ggplot(auc_data, aes(test_year, AUC, color = model, group = model)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2.3) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey50") +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = unique(auc_data$test_year)) +
  labs(title = "AUC-ROC por año de test",
       x = "Año de test", y = "AUC", color = "Modelo")
ggsave("figures/auc_temporal.png", p2, width = 10, height = 5.5, dpi = 150)

# Fig 3: Barplot métricas agregadas
metrics_long <- melt(agg_mean, id.vars = "model",
                     variable.name = "Metric", value.name = "Value")
p3 <- ggplot(metrics_long, aes(model, Value, fill = model)) +
  geom_col() +
  facet_wrap(~ Metric, scales = "free_y", nrow = 1) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Métricas agregadas por modelo", x = "", y = "") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1),
        legend.position = "none")
ggsave("figures/metrics_barplot.png", p3, width = 13, height = 5, dpi = 150)

# Fig 4: Importancia de variables (Random Forest)
if (file.exists("results/rf_importance.rds")) {
  imp    <- readRDS("results/rf_importance.rds")
  imp_df <- data.frame(Variable   = rownames(imp),
                       Importance = imp[, "MeanDecreaseGini"])
  imp_df <- imp_df[order(imp_df$Importance), ]
  imp_df$Variable <- factor(imp_df$Variable, levels = imp_df$Variable)

  p4 <- ggplot(imp_df, aes(Variable, Importance)) +
    geom_col(fill = "steelblue") + coord_flip() +
    labs(title = "Importancia de variables — Random Forest (última ventana)",
         x = "", y = "Mean Decrease Gini")
  ggsave("figures/rf_importance.png", p4, width = 8, height = 5.5, dpi = 150)
}

# Fig 5: F1 por año
p5 <- ggplot(all_metrics, aes(test_year, F1, color = model, group = model)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2.3) +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = unique(all_metrics$test_year)) +
  labs(title = "F1-Score por año de test",
       x = "Año de test", y = "F1", color = "Modelo")
ggsave("figures/f1_temporal.png", p5, width = 10, height = 5.5, dpi = 150)

cat("\n========================================\n")
cat(" EJECUCIÓN COMPLETADA\n")
cat("  Métricas  -> results/\n")
cat("  Figuras   -> figures/\n")
cat("========================================\n")
