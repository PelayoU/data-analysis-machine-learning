# Analisis de Datos
# Master Finctech UC3m
#
# Author: Tomas de la Rosa


# Computes the return to 'gap' days ahead
fwdReturns <- function(priceVector, gap){
  l <- length(priceVector)
  returns <- priceVector[(gap+1):l]/priceVector[1:(l-gap)] - 1
  
  returns[(l-gap+1):l] <- rep(NA_real_, gap)
  return(returns)
}

# Computes the returns from 'gap' days to present
backReturns <- function(priceVector, gap){
  l <- length(priceVector)
  returns <- priceVector[(gap+1):l]/priceVector[1:(l-gap)] - 1
  
  serierets <- c(rep(NA_real_, gap), returns)
  return(serierets)
  
}


# Computes the Simple moving average
# <prices> is matrix with price colum vectors
# <n> the size of the sliding window
movingAverage <- function(prices, n){
  ticks <- length(prices)
  ma <- rep(NA_real_, times=ticks)
  
  for (i in n:ticks){
    slidewindow <- prices[(i - n + 1):i]
    ma[i] <- mean(slidewindow)
  }
  return(ma)
  
}


SMA_dev <- function (prices, n){
  MA <- movingAverage(prices, n)
  ma_dev <- prices/MA - 1
  return(ma_dev)
}
