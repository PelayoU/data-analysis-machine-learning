
setwd("/Users/pelayo/Pruebas/Analisis de datos/RScripts_exploracion") #Le ponemos la ruta de nuestros scripts init.R financiaFuns.R...
source("init.R") #source es como cargar una libreria pero con scripts locales, en mi caso, init.R.
# Permite la modularidad. En lugar de tener un script ExtraccionDatos.R de 1000 líneas
#, el profesor ha separado las funciones auxiliares en archivos temáticos 
#(features.R para cálculos, yahoodatatools.R para descargas, etc.). Al hacer source, 
#esas funciones se cargan en la memoria (el Global Environment) y quedan disponibles para ser usadas.

#AL hacer source("init.R") se ejecutan todas las lineas de init.R
#init.R tiene un sapply que hace source a otros archivos..
##Es decir, al hacer source(init.R) no solo estoy ejecutando init.R, estoy ejectuando
#yahoodatatools.R, financialFuns.R, Source(features.R)


##En yahoodatatools.R hay unicamente funciones
##FinanialFuns.R tambien son solo funciones
##Features.R tambien son solo funciones.

#Es decir, con source("init.R") ejecuto todos los archivos que quiero


source("DescargaBBVA_MAPFRE.R")


bbva.df <- stockGetdata("BBVA.MC")
mapfre.df <- stockGetdata("MAP.MC")
santander.df <- stockGetdata("SAN.MC")
ibex <- stockGetdata("^IBEX")


# --- NOTAS SOBRE LA FUNCIÓN stockGetdata ---
# 1. GESTIÓN DE CACHÉ: Busca primero en 'data/' un archivo .xcsv procesado. 
#    Si no existe, lee el CSV de 'basedata/' y genera la versión limpia.
#
# 2. VALIDACIÓN DE TIPOS: Utiliza yahoo.colClasses() para asegurar que 'Date' sea fecha, 
#    'Volume' sea entero y los precios sean numéricos.
#
# 3. CURACIÓN TEMPORAL: Ejecuta cleanTradingData() para rellenar huecos en la serie 
#    (fines de semana o festivos) mediante el método de 'forwarding' (mantiene el 
#    último precio conocido).
#
# 4. NORMALIZACIÓN: Estandariza los nombres de las columnas para asegurar la 
#    compatibilidad con funciones como stepReturn() o relativePrice().




lastday <- tail(bbva.df$Date, 1)



bbva_sub.df <- stockSubset(bbva.df, "2011-01-01", lastday) #subset 
map_sub.df  <- stockSubset(mapfre.df, "2011-01-01", lastday)
santander.df <- stockSubset(santander.df, "2011-01-01", lastday)
ibex.df <- stockSubset(ibex, "2011-01-01", lastday)



print(head(santander.df))

psan <- ggplot(santander.df, aes(x=Date, y=Adj.Close)) + geom_line()
print(psan)


compare.df <- data.frame(date = ibex.df$Date,
                         ibex = relativePrice(ibex.df$Adj.Close),
                         san = relativePrice(santander.df$Adj.Close),
                         bbva = relativePrice(bbva_sub.df$Adj.Close))

print(head(compare.df))


comparePlot.df <- melt(compare.df, id=c("date"))
str(comparePlot.df)

pcomp <- ggplot(comparePlot.df, aes(x=date, y=value, colour=variable)) + geom_line() + 
       scale_color_manual(values=c("black","red","blue")) +
                            labs(title="Comparativa: IBEX (Negro), Santander (Rojo), BBVA (Azul)")
   


print(pcomp)









#------ EJERCICIO 3-CORRELACION Y RENDIMIENTOS ---

# 1. Calcular rendimientos diarios (Daily Returns)
# Usamos stepReturn de financialFuns.R, que calcula: (Pt / Pt-1) - 1


ret_bbva <- stepReturn(bbva_sub.df$Adj.Close)
ret_map  <- stepReturn(map_sub.df$Adj.Close)
ret_san  <- stepReturn(santander.df$Adj.Close)
ret_ibex <- stepReturn(ibex.df$Adj.Close)



# 2. Crear Dataframe de Rendimientos
# Nota: Los vectores de retorno tienen 1 elemento menos que los precios
df_corr <- data.frame(
  IBEX = ret_ibex,
  Santander = ret_san,
  Mapfre = ret_map
)

# 3. Gráfica 1: Dispersión IBEX vs SANTANDER

p_corr_san <- ggplot(df_corr, aes(x=IBEX, y=Santander)) + 
  geom_point(color="red", alpha=0.1) +  # Alpha bajo para ver la densidad de puntos
  geom_smooth(method="lm", color="black", se=FALSE) + # Línea de regresión lineal
  labs(title="Correlación Diaria: IBEX 35 vs Banco Santander",
       x="Rentabilidad IBEX", y="Rentabilidad Santander") +
  theme_minimal()

print(p_corr_san)
### Covarianza positiva, posiblemente coeficiente de correlacion muy alto.




# 4. Gráfica 2: Dispersión IBEX vs MAPFRE
p_corr_map <- ggplot(df_corr, aes(x=IBEX, y=Mapfre)) + 
  geom_point(color="blue", alpha=0.1) + 
  geom_smooth(method="lm", color="black", se=FALSE) +
  labs(title="Correlación Diaria: IBEX 35 vs Mapfre",
       x="Rentabilidad IBEX", y="Rentabilidad Mapfre") +
  theme_minimal()

print(p_corr_map)

##Igual, ovarianza positiva, parece que hay mas dispersion respecto a la recta de regresion, lo que significa un coeficiente de corerlacion menor


# 5. (Extra Estadístico) Matriz de Correlación Numérica
# Esto dará el coeficiente de Pearson exacto
cor_matrix <- cor(df_corr)
print("Matriz de Correlación:")
print(cor_matrix)

##efectivamente mapre tiene un coeficente de correlacion menor con el ibex que el santander.





