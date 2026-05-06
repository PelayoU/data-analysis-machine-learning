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





#-------- Practica 3------------- 


expMovingAverage <- function(prices, n) {
  ticks <- length(prices)
  ema <- rep(NA_real_, times = ticks)
  alpha <- 2 / (n + 1)
  
  ema[n] <- mean(prices[1:n])
  
  if (ticks > n) {
    for (i in (n + 1):ticks) {
      ema[i] <- prices[i] * alpha + ema[i - 1] * (1 - alpha)
    }
  }
  return(ema)
}



EMA_dev <- function(prices, n) {
  EMA <- expMovingAverage(prices, n)
  ema_dev <- prices / EMA - 1
  return(ema_dev)
}


stochasticOscillator <- function(close, high, low, n) {
  ticks <- length(close)
  stoch <- rep(NA_real_, times = ticks)
  
  for (i in n:ticks) {
    window_high <- max(high[(i - n + 1):i], na.rm = TRUE)
    window_low <- min(low[(i - n + 1):i], na.rm = TRUE)
    
    if (window_high != window_low) {
      stoch[i] <- (close[i] - window_low) / (window_high - window_low) * 100
    } else {
      stoch[i] <- 0
    }
  }
  return(stoch)
}



