
rm(list = ls())
options(warn=-1)  # Evitamos que se muestren "warning messages"

######################### PACKAGES #########################

list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(data.table)

hist_ica = as.data.frame(fread("../../Calidad del aire/Preprocesado/Datos/datos_ica_visualizacion.csv",stringsAsFactors = F))
hist_ica$timestamp = as.POSIXct(hist_ica$timestamp)

año = 2018
# estacion = 28079008 # Escuelas Aguirre
# estacion = 28079018 # Farolillo
estacion = 28079024 # Casa de Campo

aux = hist_ica[which(hist_ica$timestamp>=paste0(año,"-01-01 00:00:00") & hist_ica$timestamp<=paste0(año,"-12-31 23:00:00") &
                     hist_ica$cod_est == estacion), "Etiqueta"]
table(aux)
