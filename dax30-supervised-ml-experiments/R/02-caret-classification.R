# =============================================================================
# 02-caret-classification.R — DAX30: classify next 65 sessions as UP / DOWN
# =============================================================================
# Three classifiers via caret's unified API:
#   1) k-NN (the "reproduce the classroom example" baseline)
#   2) Decision tree (rpart)
#   3) Naïve Bayes
#
# Each is fit on the same feature set (Rent10, Rent65, Mavg30) and used to
# score three new instances at the end of the script.
#
# Run from this directory: cd to the R/ folder of the project before sourcing.
# =============================================================================

source("init.R")

# Cargar librería caret (meta-paquete para ML)
if (!require("caret")) install.packages("caret", dependencies = TRUE)
library(caret)

# -----------------------------------------------------------------------------
# 1. DATOS DAX30 Y PREPROCESO (como en clase)
# -----------------------------------------------------------------------------
# Los datos del DAX30 están en data/^GDAXI.xcsv
ticker_dax <- "^GDAXI"
dax.df <- stockGetdata(ticker_dax)

if (is.null(dax.df)) {
  stop("No se pudo cargar el DAX. Comprueba que existe data/^GDAXI.xcsv")
}

# Subconjunto desde 2013 como en el ejemplo de la presentación
dax_sub.df <- stockSubset(dax.df, "2013-01-01", yahoo.lastday())

# Variable objetivo: rendimiento a 65 días (clase UP/DOWN)
Y65 <- fwdReturns(dax_sub.df$Adj.Close, 65)
daxY65 <- factor(Y65 > 0, labels = c("DOWN", "UP"))

# Atributos: Rent10, Rent65, Mavg30 (desviación respecto a media móvil 30)
# Mavg30 = precio / MA30 - 1 (como en la tabla de la presentación)
Mavg30 <- dax_sub.df$Adj.Close / movingAverage(dax_sub.df$Adj.Close, 30) - 1

daxFeatures <- data.frame(
  Rent10  = backReturns(dax_sub.df$Adj.Close, 10),
  Rent65  = backReturns(dax_sub.df$Adj.Close, 65),
  Mavg30  = Mavg30,
  daxY    = daxY65
)

daxExamples <- na.omit(daxFeatures)
cat("Dimensiones del conjunto de entrenamiento:", dim(daxExamples), "\n")
cat("Clases daxY:\n"); print(table(daxExamples$daxY))

# -----------------------------------------------------------------------------
# 2. REPRODUCIR EJEMPLO k-NN (presentación)
# -----------------------------------------------------------------------------
ctrl <- trainControl(method = "none", repeats = 1)
knnFit <- train(daxY ~ ., data = daxExamples,
                method = "knn",
                trControl = ctrl,
                preProcess = c("center", "scale"),
                tuneGrid = data.frame(k = 6))

cat("\n--- Modelo k-NN (k=6) ---\n")
print(knnFit)

# -----------------------------------------------------------------------------
# 3. EJERCICIO 1: Otro algoritmo visto en clase (caret)
# Algoritmos vistos: k-NN, Árboles de decisión, Naive Bayes, Bagging, RF, etc.
# Entrenamos un Árbol de Decisión (rpart) y Naive Bayes (nb)
# -----------------------------------------------------------------------------

# 3.1 Árbol de decisión (rpart) - parámetros por defecto suelen bastar
# Opcional: tuneGrid con cp (complejidad) si se quiere afinar
cat("\n--- Entrenando Árbol de Decisión (rpart) ---\n")
rpartFit <- train(daxY ~ ., data = daxExamples,
                  method = "rpart",
                  trControl = ctrl,
                  tuneGrid = data.frame(cp = 0.02))  # cp controla la poda
print(rpartFit)

# 3.2 Naive Bayes (nb) - algoritmo bayesiano visto en clase
cat("\n--- Entrenando Naive Bayes (nb) ---\n")
nbFit <- train(daxY ~ ., data = daxExamples,
               method = "nb",
               trControl = ctrl)
print(nbFit)

# -----------------------------------------------------------------------------
# 4. EJERCICIO 2: Tres instancias nuevas y predicciones
# -----------------------------------------------------------------------------
# Construimos 3 instancias con valores para Rent10, Rent65, Mavg30
# (daxY no se usa en predicción, es la variable a predecir)
newInstances <- data.frame(
  Rent10 = c(-0.13,  0.02, -0.05),
  Rent65 = c(-0.08,  0.04,  0.01),
  Mavg30 = c(-0.01,  0.02, -0.015)
)
rownames(newInstances) <- c("Instancia_1", "Instancia_2", "Instancia_3")

cat("\n--- Tres instancias nuevas ---\n")
print(newInstances)

# Predicciones con cada modelo
cat("\n--- Predicciones k-NN ---\n")
pred_knn <- predict(knnFit, newdata = newInstances)
print(pred_knn)
cat("Probabilidades (k-NN):\n")
print(predict(knnFit, newdata = newInstances, type = "prob"))

cat("\n--- Predicciones Árbol de Decisión ---\n")
pred_rpart <- predict(rpartFit, newdata = newInstances)
print(pred_rpart)
cat("Probabilidades (rpart):\n")
print(predict(rpartFit, newdata = newInstances, type = "prob"))

cat("\n--- Predicciones Naive Bayes ---\n")
pred_nb <- predict(nbFit, newdata = newInstances)
print(pred_nb)
cat("Probabilidades (nb):\n")
print(predict(nbFit, newdata = newInstances, type = "prob"))

# Resumen en tabla
cat("\n--- Resumen de predicciones (clase) ---\n")
resumen <- data.frame(
  Instancia = rownames(newInstances),
  kNN = as.character(pred_knn),
  Arbol = as.character(pred_rpart),
  NaiveBayes = as.character(pred_nb)
)
print(resumen)
