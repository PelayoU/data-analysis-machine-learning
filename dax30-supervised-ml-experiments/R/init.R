# Analisis de Datos
# Master Finctech UC3m
#
# Author: Tomas de la Rosa

# Load the initial libraries
library(ggplot2)
library(reshape2)


# Load the R scripts needed for the course
sourceFiles <- c("yahoodatatools.R","financialFuns.R","features.R")
sapply(sourceFiles,source,.GlobalEnv) #sapply es una funcion de la familia apply, toma un vector o lista y aplica una funcion a cada uno de sus elementos.

#Esto hace source(yahoodatatools.R)
#Source(financialFuns.R)
#Source(features.R)




#El comando se desglosa así:
  
# Primer argumento (sourceFiles): Es el vector sobre el que iterar. Contiene los nombres de los tres archivos.
# Segundo argumento (source): Es la función que se va a ejecutar por cada elemento del vector anterior.
# Tercer argumento (.GlobalEnv): Son los argumentos adicionales que se pasan a la función source. 
# En este caso, se está pasando .GlobalEnv al parámetro local de la función source. 
# Esto fuerza a que las funciones se carguen en el entorno global, asegurando que estén disponibles para todo el proyecto.


