# --- DescargaBBVA_MAPFRE.R ACTUALIZADO ---
if (!require("quantmod")) install.packages("quantmod")
library(quantmod)

# 1. Descargar TODOS los activos necesarios
getSymbols("BBVA.MC", src = "yahoo", from = "2010-01-01")
getSymbols("MAP.MC", src = "yahoo", from = "2010-01-01")
getSymbols("SAN.MC", src = "yahoo", from = "2010-01-01") # Nuevo
getSymbols("^IBEX", src = "yahoo", from = "2010-01-01")   # Nuevo

dir.create("basedata", showWarnings = FALSE)

saveYahooCSV <- function(symbol_xts, name){
  df <- data.frame(Date = index(symbol_xts), coredata(symbol_xts))
  # Ajustamos nombres genéricos para evitar prefijos tipo SAN.MC.Open
  colnames(df) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adj.Close")
  
  # Orden requerido por yahoodatatools.R
  df <- df[, c("Date", "Open", "High", "Low", "Close", "Adj.Close", "Volume")]
  df <- na.omit(df)
  
  write.csv(df, paste0("basedata/", name, ".csv"), row.names = FALSE)
  print(paste("Actualizado:", name))
}

# 2. Guardar los 4 archivos en basedata
saveYahooCSV(BBVA.MC, "BBVA.MC")
saveYahooCSV(MAP.MC, "MAP.MC")
saveYahooCSV(SAN.MC, "SAN.MC")
saveYahooCSV(IBEX, "^IBEX") # Ojo: el nombre del archivo debe ser ^IBEX.csv