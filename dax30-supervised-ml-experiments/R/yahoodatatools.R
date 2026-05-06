# Author: Tomas de la Rosa
# Description: Data loading and processing from Yahoo Finance

# Trading info is complete from the day before
yahoo.lastday <- function(){
  Sys.Date()
}


asset.filename <- function(ticker, base=FALSE)
{ if (base){
    return(paste("basedata/",ticker,".csv", sep=""))
  }else{
  return(paste("data/",ticker,".xcsv", sep=""))
  }
}

yahoo.readbydate <-function(ticker, start.date, end.date=yahoo.lastday()){
  
  end.date <- as.character(end.date)
  # Split the start and end dates to be used in the ULR later on
 
  splt <- unlist(strsplit(start.date, "-"))
  a <- as.character(as.numeric(splt[2])-1)
  b <- splt[3]
  c <- splt[1]

  splt <- unlist(strsplit(end.date, "-"))
  d <- as.character(as.numeric(splt[2])-1)
  e <- splt[3]
  f <- splt[1]

  # Create the two out of the three basic components for the URL loading
  urlbase <- "https://chart.finance.yahoo.com/table.csv?s="
  url <- paste(urlbase,ticker,"&a=", a, "&b=", b, "&c=", c, "&d=", d, "&e=", e, "&f=", f, "&g=d&ignore=.csv", sep="")
  #print(url)
  #yahootempfile <- paste("data/",ticker, ".temp", sep = "")
  #download.file(url,yahootempfile, method = "curl", quiet = T)
  
  yahoodata <- read.csv(url)
  
  yahoodata.fwd <- yahoodata[rev(rownames(yahoodata)),]
  yahoodata.fwd$Date <- as.Date(yahoodata.fwd$Date)
  yahoodata.fwd
}



yahoo.readcomplete <- function(ticker){
  urlbase <- "https://chart.finance.yahoo.com/table.csv?s="
  url <- paste(urlbase,ticker,sep="")
  yahoodata <- read.csv(url)
  yahoodata.fwd <- yahoodata[rev(rownames(yahoodata)),]
  yahoodata.fwd$Date <- as.Date(yahoodata.fwd$Date)
  #write.csv(yahoodata.fwd, file=paste("data/",ticker,".ycsv", sep=""), row.names=FALSE)
  yahoodata.fwd
}


yahoo.readbymonth <- function(ticker){
  urlbase <- "https://chart.finance.yahoo.com/table.csv?g=m&s="
  url <- paste(urlbase,ticker,sep="")
  
  yahootempfile <- paste("data/",ticker, ".temp", sep = "")
  download.file(url,yahootempfile, method = "curl", quiet = T)
  yahoodata <- read.csv(yahootempfile)
  
  yahoodata.fwd <- yahoodata[rev(rownames(yahoodata)),]
  yahoodata.fwd$Date <- as.Date(yahoodata.fwd$Date)
  #write.csv(yahoodata.fwd, file=paste("data/",ticker,".ycsv", sep=""), row.names=FALSE)
  yahoodata.fwd
}



  
# days from monday to friday
# Ex call: tradingdates('2016-01-02',Sys.Date())
tradingdates <- function(start.date, end.date=yahoo.lastday()){
  all.dates <- seq(as.Date(start.date), as.Date(end.date), by="day")
  all.dates <- subset(all.dates, as.POSIXlt(all.dates)$wday != 0 & 
                                 as.POSIXlt(all.dates)$wday != 6)
  all.dates.char <- as.matrix(as.character(all.dates))
  all.dates.char
}

# Fills trading data forwarding values of previous dates
# At the end, dataframe contains data of all trading dates.
cleanTradingData <-function(trading.data, end.date=yahoo.lastday()){
  firstdate <-trading.data$Date[1]
  alldates <- as.Date(tradingdates(firstdate))
  
  cleandf <- rbind(trading.data[1,])
  
  if (length(alldates) > 1){
    trade.anterior <- trading.data[1,]
    for (i in 2:length(alldates))
    {
      tradedata <- trading.data[trading.data$Date == alldates[i],]
      #print(paste("Matching...", i))
      #print(tradedata)
      if (nrow(tradedata) == 1){
        cleandf <- rbind(cleandf, tradedata)
        trade.anterior <- tradedata
      
      } else {
        print(paste("Forwarding..", as.character(trade.anterior$Date[1])))
        trade.anterior$Volume[1] <- 0
        trade.anterior$Date[1] <- alldates[i]
        cleandf <- rbind(cleandf,trade.anterior)
      }
      
    }
  }
  
  cleandf
  
}
  
stockCheckErrors <- function(Ticker,ErrThr=0.10){
  stock.df <- assetGetdata(Ticker)
  ndays <- length(stock.df$Date)
  err.df <- data.frame(Date = stock.df$Date[2:ndays],Ret = stepReturn(stock.df$Adj.Close))
  founderrors <- err.df[ which(err.df$Ret > ErrThr | err.df$Ret < (-ErrThr)),]
  return(founderrors)
}


stockGetdata <- function(vticker){
  ticker <- toupper(vticker)
  filename <- asset.filename(ticker)
  if (file.exists(filename))
  {
    asset.Data <- read.csv(filename)
    asset.Data$Date <- as.Date(asset.Data$Date)
    
    return (asset.Data)
  } else {
    basefilename = asset.filename(ticker,TRUE)
    print(basefilename)
    if (file.exists(basefilename)){
        print(paste("Incorporating new asset to local database:",ticker))
      asset.newdata <- read.csv(basefilename, colClasses = yahoo.colClasses(),na.strings = 'null')
      asset.newdata$Date <- as.Date(asset.newdata$Date)
      
      asset.completeData <- cleanTradingData(asset.newdata)
      write.csv(asset.completeData, filename, row.names = F)
      return(asset.completeData)
    }else{
      print(paste("Stock data not found in database:",ticker))
    }
  
  }
}

yahoo.colClasses <- function(){
  # Date  Open  High  Low Close Adjusted.Close Volume 
  c("Date","numeric","numeric", "numeric","numeric","numeric","integer")
}

emptyYahooDF <- function(){
  df <- data.frame(Date = as.Date(character(0)),
                   Open = numeric(0),
                   High = numeric(0),
                   Low = numeric(0),
                   Close = numeric(0),
                   Volume = integer(0),
                   Adj.Close = numeric(0))
  df
  
  
}


# Subset stock data by start and end dates
stockSubset <- function (stock.df, startDate, endDate){
  substock.df <- stock.df[stock.df$Date >= as.Date(startDate) & 
                            stock.df$Date <= as.Date(endDate),]
  substock.df
}


