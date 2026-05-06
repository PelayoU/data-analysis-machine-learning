if (!require("quantmod")) install.packages("quantmod")
library(quantmod)

# 1. Descargar el índice DAX30
getSymbols("^GDAXI", src = "yahoo", from = "2010-01-01")

dir.create("basedata", showWarnings = FALSE)

saveYahooCSV <- function(symbol_xts, name){
  df <- data.frame(Date = index(symbol_xts), coredata(symbol_xts))
  colnames(df) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adj.Close")
  
  # Orden requerido por yahoodatatools.R
  df <- df[, c("Date", "Open", "High", "Low", "Close", "Adj.Close", "Volume")]
  df <- na.omit(df)
  
  # FIX: Desactivar notación científica y forzar a integer el Volume 
  # para cumplir con la función yahoo.colClasses() del profesor.
  options(scipen = 999) 
  df$Volume <- as.integer(df$Volume)
  
  write.csv(df, paste0("basedata/", name, ".csv"), row.names = FALSE)
  print(paste("Actualizado:", name))
}

# 2. Guardar el archivo en basedata
# OJO: Al descargar "^GDAXI", quantmod crea por defecto el objeto quitando el caracter especial "^". 
# Por tanto, el objeto en memoria se llama GDAXI, pero queremos que el CSV se llame ^GDAXI.csv
saveYahooCSV(GDAXI, "^GDAXI")