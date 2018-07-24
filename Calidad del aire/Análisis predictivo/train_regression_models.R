
#	Autor: Lucia Fernandez Sanchez                 
#	TFM Master Visual Analytics and Big Data     									
#	Universidad Internacional de La Rioja (UNIR)   									

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


#############
# FUNCTIONS #
#############
mae = function(x,y){
  mean(abs(x-y))
}

mape = function(x,y){
  mean(abs((x-y)/y))
}

#----------------------------------------------------------------------

# Importamos la prediccion de la serie temporal
estacion = 28079008   # Escuelas Aguirre
# estacion = 28079018   # Farolillo
# estacion = 28079024   # Casa de Campo

ts_ica_forecast = fread(paste0("prophet_diario_",estacion,".csv"))  
colnames(ts_ica_forecast) = c("timestamp","prophet")

# Importamos los datos meteorologicos
weather = fread("tiempo_horario.csv")
# Calculamos el timestamp a partir de las otras columnas
weather$timestamp = paste0(weather$anyo,"-",weather$mes,"-",weather$dia," ",weather$hora,":00:00")
  
# Eliminamos las muestras que no nos interesan
weather = weather[which(weather$timestamp>="2015-01-01 00:00:00" & weather$timestamp<="2018-04-30 21:00:00"),]
weather = weather[,-c("anyo","wdir","wdire","snow")]

# Hay horas con varias mediciones meteorologicas. Nos quedamos con la primera
if(any(duplicated(weather$timestamp))){
  weather = weather[-which(duplicated(weather$timestamp)),]
}

# Juntamos toda la informacion
input_data = merge(ts_ica_forecast, weather, "timestamp", all.x = TRUE)

# Importamos los datos reales de ICA
real_ica = fread(paste0("./Prophet/datos_ica_filtered_",estacion,".csv"))
input_data = merge(input_data, real_ica, "timestamp", all.x = TRUE)

# Solo tenemos informacion meteorologica de 7h a 20h. Eliminamos el resto de horas
input_data = input_data[complete.cases(input_data),]
input_data = input_data[-which(input_data$temp == ""),]
input_data = input_data[-which(input_data$presion == ""),]

# Creamos la variable artificial que marca los dias que han pasado desde la ultima vez que llovio
idx_rain = which(input_data$rain==1)
change_trend = diff(idx_rain)
days_from_last_rain = seq(440,(439+idx_rain[1]-1),1)
for(i in 1:length(change_trend)){
  days_from_last_rain = c(days_from_last_rain, seq(0,(change_trend[i]-1),1))
}
days_from_last_rain = c(days_from_last_rain, seq(0,(nrow(input_data)-idx_rain[length(idx_rain)]),1))
input_data$days_from_last_rain = days_from_last_rain

# Pasamos a formato numerico las columnas que nos interesan que figuren con este formato
input_data$mes = as.numeric(input_data$mes)
input_data$dia = as.numeric(input_data$dia)
input_data$hora = as.numeric(input_data$hora)
input_data$temp = as.numeric(input_data$temp)
input_data$hum = as.numeric(input_data$hum)
input_data$wspd = as.numeric(input_data$wspd)
input_data$presion = NULL
input_data$fog = NULL
input_data$rain = as.numeric(input_data$rain)

# Dividimos los conjuntos de train y test
train = input_data[which(input_data$timestamp<"2018-01-01 07:00:00"),-c("timestamp")]
test = input_data[which(input_data$timestamp>="2018-01-01 07:00:00"),]

#----------------------------------------------------------------------

#################
# Random Forest #
#################
# # Entrenamiento
# model.randomForest = randomForest(clean_ICA ~ prophet+mes+dia+hora+temp+hum+wspd+rain+days_from_last_rain,
#                                   data = train, ntree = 100)
# 
# valoracion.randomForest = as.matrix(predict(model.randomForest, train))
# 
# MAE.randomForest = mae(valoracion.randomForest, train$clean_ICA)
# MAPE.randomForest = mape(valoracion.randomForest, train$clean_ICA)
# 
# # Guardamos el modelo
# save(model.randomForest, file=paste0("./Modelos/RandomForest_",estacion,".rda"))

# Test
model = load(paste0("./Modelos/RandomForest_",estacion,".rda"))  #Loading Model
rf_forecast = predict(get(model), test[,-c("timestamp","clean_ICA")])

resultados = data.frame(cbind("Real"=test$clean_ICA, "RF"=rf_forecast))
correlation = cor(resultados$Real, resultados$RF) 
maeError = mae(resultados$Real, resultados$RF) 
mapeError = mape(resultados$Real, resultados$RF) 
resultados$timestamp = as.POSIXct(test$timestamp)
resultados = resultados[,c("timestamp","Real","RF")]   # Reordenamos las columnas

p <- plot_ly(resultados, x = ~timestamp, y = ~Real, name = 'Real', type = 'scatter', mode = 'lines',
             line = list(color = 'black', width = 0.5)) %>%
  add_trace(y = ~RF, name = 'Random Forest', mode = 'lines',line = list(color = 'red', width = 2))
p

# x11()
# plot(resultados$Real,resultados$timestamp,type="l",lwd=1.5,pch=20, xlab="Time", ylab="ICA")
# lines(resultados$RF,resultados$timestamp,type="l",col="red",lwd=2,pch=20)
# legend("topright",c("Real","Predicha"),lty=c(1,1),lwd=c(1.5,1.5),pch=c(20,20),col=c("black","red"))


#######
# M5P #
#######
# # Entrenamiento
# model.M5P = M5P(clean_ICA ~ prophet+mes+dia+hora+temp+hum+wspd+rain+days_from_last_rain, data = train)
# 
# valoracion.M5P = as.matrix(predict(model.M5P, train))
# 
# MAE.M5P = mae(valoracion.M5P, train$clean_ICA)
# MAPE.M5P = mape(valoracion.M5P, train$clean_ICA)
# 
# # Guardamos el modelo
# .jcache(model.M5P$classifier)
# save(model.M5P, file=paste0("./Modelos/M5P_",estacion,".rda"))

# Test
model = load(paste0("./Modelos/M5P_",estacion,".rda"))  #Loading Model
m5p_forecast = predict(get(model), test[,-c("timestamp","clean_ICA")])

resultados$M5P = m5p_forecast
correlation = cor(resultados$Real, resultados$M5P)  
maeError = mae(resultados$Real, resultados$M5P) 
mapeError = mape(resultados$Real, resultados$M5P)  

p <- plot_ly(resultados, x = ~timestamp, y = ~Real, name = 'Real', type = 'scatter', mode = 'lines',
             line = list(color = 'black', width = 0.5)) %>%
  add_trace(y = ~M5P, name = 'M5P', mode = 'lines',line = list(color = 'red', width = 2))
p

# plot(resultados$Real,type="l",lwd=1.5,pch=20, xlab="Time", ylab="ICA")
# lines(resultados$M5P,type="l",col="red",lwd=1.5,pch=20)
# legend("topright",c("Real","Predicha"),lty=c(1,1),lwd=c(1.5,1.5),pch=c(20,20),col=c("black","red"))


######
# NN #
######
# # Entrenamiento
# model.NN = nnet(clean_ICA ~ prophet+mes+dia+hora+temp+hum+wspd+rain+days_from_last_rain, data = train,
#                 size = 15, linout = TRUE, decay = 0.5, maxit = 5000)
# 
# valoracion.NN = as.matrix(predict(model.NN, train))
# 
# MAE.NN = mae(valoracion.NN, train$clean_ICA)
# MAPE.NN = mape(valoracion.NN, train$clean_ICA)
# 
# # Guardamos el modelo
# save(model.NN, file=paste0("./Modelos/NN_",estacion,".rda"))

# Test
model = load(paste0("./Modelos/NN_",estacion,".rda"))  #Loading Model
nn_forecast = predict(get(model), test[,-c("timestamp","clean_ICA")])

resultados$NN = nn_forecast
correlation = cor(resultados$Real, resultados$NN) 
maeError = mae(resultados$Real, resultados$NN)  
mapeError = mape(resultados$Real, resultados$NN)  
resultados$NN = as.numeric(resultados$NN)

p <- plot_ly(resultados, x = ~timestamp, y = ~Real, name = 'Real', type = 'scatter', mode = 'lines',
             line = list(color = 'black', width = 0.5)) %>%
  add_trace(y = ~NN, name = 'Neural Network', mode = 'lines',line = list(color = 'red', width = 2))
p

# plot(resultados$Real,type="l",lwd=1.5,pch=20, xlab="Time", ylab="ICA")
# lines(resultados$NN,type="l",col="red",lwd=1.5,pch=20)
# legend("topright",c("Real","Predicha"),lty=c(1,1),lwd=c(1.5,1.5),pch=c(20,20),col=c("black","red"))

#----------------------------------------------------------------------
# Guardamos los resultados de los modelos
write.csv(resultados,paste0("./Resultados/models_forecast_",estacion,".csv"),row.names=F)



