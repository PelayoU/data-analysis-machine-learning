# =============================================================================
# 01-knn-regression.R — DAX30: predict 30-session forward return with KNN
# =============================================================================
# Run from this directory: cd to the R/ folder of the project before sourcing.
# (no hard-coded setwd — keeps the script portable.)
# =============================================================================

source("init.R")
source("DescargaGDAXI.R")

#prueba para ver si funciona global enviroment con un dataframe de prueba

df <- data.frame(fecha=1:10, valor=rnorm(10))
print(df)

ticker_dax <- "^GDAXI"
dax.df <- stockGetdata(ticker_dax)

lastday <- tail(dax.df$Date, 1)
dax_sub.df <- stockSubset(dax.df, "2011-01-01", lastday)
print(head(dax_sub.df))



# 3. Cálculo de la variable objetivo (Target: Rendimiento a 30 días)
# Utilizamos fwdReturns de features.R
target_fwd30 <- fwdReturns(dax_sub.df$Adj.Close, 30)

# 4. Extracción de Características
# Implementamos 6 características combinando indicadores y ventanas temporales
feat_SMA14_dev <- SMA_dev(dax_sub.df$Adj.Close, 14)
feat_SMA50_dev <- SMA_dev(dax_sub.df$Adj.Close, 50)

feat_EMA14_dev <- EMA_dev(dax_sub.df$Adj.Close, 14)
feat_EMA50_dev <- EMA_dev(dax_sub.df$Adj.Close, 50)

feat_Stoch14 <- stochasticOscillator(dax_sub.df$Adj.Close, dax_sub.df$High, dax_sub.df$Low, 14)
feat_Stoch30 <- stochasticOscillator(dax_sub.df$Adj.Close, dax_sub.df$High, dax_sub.df$Low, 30)

# Construcción del data frame 
df_features <- data.frame(
  Fwd30_Ret = target_fwd30,
  SMA14     = feat_SMA14_dev,
  SMA50     = feat_SMA50_dev,
  EMA14     = feat_EMA14_dev,
  EMA50     = feat_EMA50_dev,
  Stoch14   = feat_Stoch14,
  Stoch30   = feat_Stoch30
)

# Eliminamos valores NA generados por el lookback de los indicadores y el lookahead del target
df_model <- na.omit(df_features)

# Matriz de correlación cruzada
print("Generando matriz de dispersión (Pairs)...")
pairs(df_model, 
      main = "Matriz de Correlación: DAX30 Features vs Fwd30",
      pch = 20, col = rgb(0, 0, 0, alpha = 0.1))



## KNN

if (!require("FNN")) install.packages("FNN")
library(FNN)

# Separamos las características (X) y el vector objetivo (Y)
X_train <- df_model[, c("SMA14", "SMA50", "EMA14", "EMA50", "Stoch14", "Stoch30")]
Y_train <- df_model$Fwd30_Ret

# 7.1 Escalado riguroso (Z-score) del conjunto de entrenamiento
X_train_scaled <- scale(X_train)

# Almacenamos los momentos muestrales para transformar futuros datos sin data leakage
mu_train <- attr(X_train_scaled, "scaled:center")
sd_train <- attr(X_train_scaled, "scaled:scale")

# 7.2 Preparación de la "Nueva Instancia" (Inferencia)
# Extraemos el último día disponible de df_features (donde Fwd30_Ret es NA)
nueva_instancia <- tail(df_features, 1)
X_nueva <- nueva_instancia[, c("SMA14", "SMA50", "EMA14", "EMA50", "Stoch14", "Stoch30")]

# Escalamos la nueva instancia proyectándola sobre la distribución del conjunto de entrenamiento
X_nueva_scaled <- scale(X_nueva, center = mu_train, scale = sd_train)

# 7.3 Entrenamiento e Inferencia con KNN (k = 5 vecinos)
modelo_knn <- knn.reg(train = X_train_scaled, 
                      test = X_nueva_scaled, 
                      y = Y_train, 
                      k = 5)

print("--- PREDICCIÓN CON KNN ---")
print(paste("Basado en los 5 estados de mercado históricos más similares (distancia euclidiana),"))
print(paste("el rendimiento esperado a 30 días para el DAX30 es:", round(modelo_knn$pred, 4)))














