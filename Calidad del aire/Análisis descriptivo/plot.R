
# Fijamos el directorio de trabajo
setwd("C:/Users/Dani y Lucía/Desktop/PFM/Input data/Calidad del aire/Análisis descriptivo")

# Deshabilitamos la notacion cientifica
options(scipen=999)

# Paquetes
library(data.table)
library(ggplot2)
library(plotly)
library(dplyr)
library(zoo)
library(plotrix)

# ---------------------------------------------------------------------------

# Importamos los datos 
datos = fread("../Preprocesado/Datos/datos_ica.csv")

########################################
# Calculamos valores agregados del ICA #
########################################

# Curva anual
ICA_diario = data.frame(matrix(NA,1,3))
colnames(ICA_diario) = c("dia","ICA","anyo")

for(i in seq(2001,2018,1)){
  ICA_diario = rbind(ICA_diario,
                     cbind(aggregate(ICA ~ dia, data = datos[which(datos$anyo==i),], FUN = max),"anyo"=i))
}
ICA_diario = ICA_diario[2:nrow(ICA_diario),]
ICA_diario$dia = as.numeric(ICA_diario$dia)
ICA_diario = ICA_diario[-which(ICA_diario$dia==366),]  # Quitamos el dia bisiesto para que no haya problemas al agregar

# Calculamos la media anual
ICA_med_anual = aggregate(ICA_diario,by=list(ICA_diario$anyo), mean)[,c("ICA","anyo")]
plot_ly(x = ICA_med_anual$anyo, y = ICA_med_anual$ICA, type = "bar")

# Suavizado
suavizado = 30
ICA_diario_smooth = data.frame(matrix(NA,1,2))

for(i in seq(2001,2018,1)){
  smooth = cbind("X1"= c(rep(NA,suavizado-1),
                         rollapply(ICA_diario$ICA[which(ICA_diario$anyo==i)], width = suavizado,
                                   FUN = mean, align = "left")),
                 "X2"=i)
  # Rellenamos los huecos que faltan al principio con la media de los dias anteriores
  for(j in (suavizado-1):1){
    smooth[j,1] = mean(ICA_diario$ICA[which(ICA_diario$anyo==i)][1:j])
  }
  
  ICA_diario_smooth = rbind(ICA_diario_smooth, smooth)
}

ICA_diario_smooth = ICA_diario_smooth[2:nrow(ICA_diario_smooth),]
colnames(ICA_diario_smooth) = c("ICA","anyo")

# Opcion a)
ICA_diario_smooth %>%
  group_by(anyo) %>%
  plot_ly(x = ~dia, y = ~ICA, type="scatter", mode="lines", color = ~anyo)

# Opcion b)
p <- plot_ly(x = ICA_diario_smooth$dia[which(ICA_diario_smooth$anyo=="2001")],
             y = ICA_diario_smooth$ICA[which(ICA_diario_smooth$anyo=="2001")], type="scatter", mode="lines")
for(i in seq(2002,2018,1)){
  p <- add_trace(p, x = ICA_diario_smooth$dia[which(ICA_diario_smooth$anyo==i)],
                 y = ICA_diario_smooth$ICA[which(ICA_diario_smooth$anyo==i)], type="scatter", mode="lines")
}
p

# Agrupamos por grupos de 3 años
ICA_diario_agg = data.frame(matrix(NA,1,3))
colnames(ICA_diario_agg) = c("dia","ICA","anyo")
for(i in seq(2001,2016,3)){
  ICA_diario_agg = rbind(ICA_diario_agg,
                         cbind("dia"=seq(1,365,1),
                               "ICA"=apply(cbind(ICA_diario$ICA[which(ICA_diario$anyo==i)],
                                                 ICA_diario$ICA[which(ICA_diario$anyo==i+1)],
                                                 ICA_diario$ICA[which(ICA_diario$anyo==i+2)]), 1, mean),
                               "anyo"=paste0(i,"-",i+2)))
}

ICA_diario_agg = ICA_diario_agg[2:nrow(ICA_diario_agg),]
ICA_diario_agg$ICA = as.numeric(ICA_diario_agg$ICA)

# Suavizado
suavizado = 30
ICA_diario_agg_smooth = data.frame(matrix(NA,1,2))

for(i in unique(ICA_diario_agg$anyo)){
  smooth = cbind("X1"= c(rep(NA,suavizado-1),
                         rollapply(ICA_diario_agg$ICA[which(ICA_diario_agg$anyo==i)], width = suavizado,
                                   FUN = mean, align = "left")),
                 "X2"=i)
  # Rellenamos los huecos que faltan al principio con la media de los dias anteriores
  for(j in (suavizado-1):1){
    smooth[j,1] = mean(ICA_diario_agg$ICA[which(ICA_diario_agg$anyo==i)][1:j])
  }
  
  ICA_diario_agg_smooth = rbind(ICA_diario_agg_smooth, smooth)
}

ICA_diario_agg_smooth = ICA_diario_agg_smooth[2:nrow(ICA_diario_agg_smooth),]
colnames(ICA_diario_agg_smooth) = c("ICA","anyo")
ICA_diario_agg_smooth$dia = ICA_diario_agg$dia
for(i in 1:nrow(ICA_diario_agg_smooth)){
  ICA_diario_agg_smooth$ICA2[i] = as.numeric(ICA_diario_agg_smooth$ICA[i])
}
ICA_diario_agg_smooth$ICA = NULL
colnames(ICA_diario_agg_smooth)[3] = "ICA"
ICA_diario_agg_smooth$dia = as.numeric(ICA_diario_agg_smooth$dia)

# Opcion a)
ICA_diario_agg_smooth %>%
  group_by(anyo) %>%
  plot_ly(x = ~dia, y = ~ICA, type="scatter", mode="lines", color = ~anyo)

##########################################
# Curva diaria
