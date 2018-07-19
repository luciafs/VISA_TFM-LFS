
rm(list = ls())
graphics.off()

############
# PAQUETES #
############
list.of.packages <- c("data.table","ggplot2","lubridate","partykit","randomForest","robustbase","cvTools",
                      "RWeka","rJava","nnet","plotly")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages)

library(data.table)
library(ggplot2)
library(lubridate)
library(partykit)
library(randomForest)
library(robustbase)
library(cvTools)
library(RWeka)
library(rJava)
library(nnet)
library(plotly)

#----------------------------------------------------------------------

# Importamos la prediccion de la serie temporal
# estacion = 28079008   # Escuelas Aguirre
# estacion = 28079018   # Farolillo
estacion = 28079024   # Casa de Campo

ts_ica_forecast = fread(paste0("prophet_diario_",estacion,".csv"))  
colnames(ts_ica_forecast) = c("timestamp","prophet")

# Importamos los datos meteorologicos
weather = fread("../../Información meteorológica/Weather Underground/Forecast/forecast.csv")
# Calculamos el timestamp a partir de las otras columnas
weather$timestamp = paste0(weather$anyo,"-",weather$mes,"-",weather$dia," ",weather$hora,":00:00")
  
# Eliminamos las muestras que no nos interesan
weather = weather[,-c("anyo","wdir","wdire","presion","fog","snow")]

# Hay horas con varias mediciones meteorologicas. Nos quedamos con la primera
if(any(duplicated(weather$timestamp))){
  weather = weather[-which(duplicated(weather$timestamp)),]
}

# Juntamos toda la informacion
weather$timestamp = as.POSIXct(weather$timestamp)
ts_ica_forecast$timestamp = as.POSIXct(ts_ica_forecast$timestamp, format="%Y-%m-%d %H:%M:%S")
input_data = merge(ts_ica_forecast, weather, "timestamp", all.y = TRUE)

# Solo tenemos informacion meteorologica de 7h a 20h. Eliminamos el resto de horas
input_data = input_data[complete.cases(input_data),]
if(any(input_data$temp == "")){
  input_data = input_data[-which(input_data$temp == ""),]
}

# Creamos la variable artificial que marca los dias que han pasado desde la ultima vez que llovio
hist_weather = fread("../../Información meteorológica/Weather Underground/Preprocesado/tiempo_diario.csv")
idx_rain = which(hist_weather$rain==1)
days_from_last_rain = nrow(hist_weather)-idx_rain[length(idx_rain)]
fechas = unique(strptime(input_data$timestamp, "%Y-%m-%d"))
input_data$days_from_last_rain = NA
input_data$days_from_last_rain[which(strptime(input_data$timestamp, "%Y-%m-%d")==fechas[1])] = days_from_last_rain
for(i in 1:(length(fechas)-1)){
  if(any(input_data$rain[which(strptime(input_data$timestamp, "%Y-%m-%d")==fechas[i])])==1){
    input_data$days_from_last_rain[which(strptime(input_data$timestamp, "%Y-%m-%d")==fechas[i+1])] = 0
  }else{
    days_from_last_rain = days_from_last_rain+1
    input_data$days_from_last_rain[which(strptime(input_data$timestamp, "%Y-%m-%d")==fechas[i+1])] = days_from_last_rain
  }
}


# Pasamos a formato numerico las columnas que nos interesan que figuren con este formato
input_data$mes = as.numeric(input_data$mes)
input_data$dia = as.numeric(input_data$dia)
input_data$hora = as.numeric(input_data$hora)
input_data$temp = as.numeric(input_data$temp)
input_data$hum = as.numeric(input_data$hum)
input_data$wspd = as.numeric(input_data$wspd)
input_data$rain = as.numeric(input_data$rain)


#----------------------------------------------------------------------

if(estacion == 28079008){
  folder1 = "./Modelos/RandomForest_28079008.rda"
  folder2 = "./Resultados/Escuelas Aguirre_28079008/forecast.csv"
}else if(estacion == 28079018){
  folder1 = "./Modelos/RandomForest_28079018.rda"
  folder2 = "./Resultados/Farolillo_28079018/forecast.csv"
}else{
  folder1 = "./Modelos/M5P_28079024.rda"
  folder2 = "./Resultados/Casa de campo_28079024/forecast.csv"
}

model = load(folder1)  #Loading Model
forecast = data.frame("forecast" = predict(get(model), input_data[,-c("timestamp")]))
forecast$timestamp = input_data$timestamp

# Guardamos los resultados de los modelos
write.csv(forecast,folder2,row.names=F)



