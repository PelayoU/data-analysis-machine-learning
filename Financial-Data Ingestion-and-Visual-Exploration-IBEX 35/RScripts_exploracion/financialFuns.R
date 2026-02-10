# Analisis de Datos
# Master Finctech UC3m
#
# Author: Tomas de la Rosa


# Compute the return for each tick in the serie
stepReturn <- function (priceVector){
  l <- length(priceVector)
  
  returns <- priceVector[2:l]/priceVector[1:l-1] - 1
  returns
}

# Computes the total return from a serie of prices
totalReturn <- function (priceVector){
  l <- length(priceVector)
  priceVector[l]/priceVector[1] - 1
}

# Total return from a serie of tick returns
serieReturn <- function (returnVector){
  prod(returnVector + 1) - 1
}

# Computes the relative price to compare with other series.
relativePrice <- function(priceVector){
  relVector <- priceVector/priceVector[1]
  return(relVector)
}


