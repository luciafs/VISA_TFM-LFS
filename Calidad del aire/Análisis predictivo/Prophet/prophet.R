#----------------------------------------------------------#
#		Autor: Lucia Fernandez Sanchez                         #
#		TFM -Master Visual Analytics and Big Data		           #									
#		Universidad Internacional de La Rioja (UNIR)	         #											
#----------------------------------------------------------#


#----------------------------------------------------------#
# https://facebook.github.io/prophet/docs/quick_start.html #
#----------------------------------------------------------#

rm(list = ls())
graphics.off()

############
# PAQUETES #
############
list.of.packages <- c("prophet", "dplyr", "RCurl","tseries","zoo","data.table","ggplot2","forecast")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages)

library(prophet)
library(dplyr)
library(RCurl)
library(tseries)
library(zoo)
library(data.table)
library(ggplot2)
library(forecast)

#----------------------------------------------------------------------
# Importamos el conjunto de datos sobre el que vamos a modelar la serie
ica = fread("datos_ica.csv", sep = ",", header = T)

# Tenemos informacion de 24 estaciones de control. Vamos a analizar alguna en particular
# estacion = 28079008  # Escuelas Aguirre (UT)
# estacion = 28079018  # Farolillo (UF)
estacion = 28079024  # Casa de Campo (S)

if(estacion == 28079008){
  folder = "Escuelas Aguirre_28079008"
}else if(estacion == 28079018){
  folder = "Farolillo_28079018"
}else{
  folder = "Casa de campo_28079024"
}

ica = ica[which(ica$cod_est==estacion),]

# Pasamos las fechas de caracter a fecha
ica$timestamp = as.POSIXct(ica$timestamp, format = "%Y-%m-%d %H:%M:%S")

# Quitamos la info que no nos interese
# ica = ica[which(ica$timestamp < "2018-05-01 00:00:00"),] 

# Nos quedamos con los años que nos interesan
ica_horario = ica[which(ica$timestamp >= "2011-01-01 00:00:00"), c("timestamp", "ICA","weekday")]

# Eliminamos los outliers y los missing values. replace.missing = TRUE linearly interpolates missing values
ica_horario$clean_ICA = tsclean(ica_horario$ICA, replace.missing = T) # OPCION A)
# ica_horario$clean_ICA = na.approx(ica_horario$ICA) # OPCION B)

# Pintamos los datos "limpiados" para ver que pinta tienen
ggplot(ica_horario, aes(timestamp, clean_ICA)) +
  geom_line() +
  scale_x_datetime("Date") +
  ylab("ICA") + xlab("Date")

# Suavizamos la señal
ica_horario$ICA_ma = ma(ica_horario$clean_ICA, order = 7*24) 
ica_horario$ICA_ma60 = ma(ica_horario$clean_ICA, order = 60 * 24)

ggplot() +
  geom_line(data = ica_horario, aes(x = timestamp, y = clean_ICA, colour = "ICA (raw data)")) +
  geom_line(data = ica_horario, aes(x = timestamp, y = ICA_ma, colour = "Weekly Moving Average"), size = 1.25) +
  geom_line(data = ica_horario, aes(x = timestamp, y = ICA_ma60, colour = "Monthly Moving Average"), size = 1.25) +
  scale_color_manual(values=c("black","blue","red")) +
  ylab('ICA')


###################################################################################
# Forecast anual

# Nos quedamos con los años 2011-2016 para entrenar y 2017-2018 para validar
ica_horario_train = ica_horario[which(ica_horario$timestamp < "2017-01-01 00:00:00"),]
train = ica_horario_train[, c("timestamp", "ICA_ma60")]
colnames(train) = c("ds", "y")

ica_horario_test = ica_horario[which(ica_horario$timestamp >= "2017-01-01 00:00:00"),]
test = ica_horario_test[, c("timestamp", "ICA_ma60")]

# Modeling holidays
saturday <- data_frame(
  holiday = 'saturday',
  ds = ica_horario_train$timestamp[which(ica_horario_train$weekday=="sábado")],
  lower_window = 0,
  upper_window = 1)

sunday <- data_frame(
  holiday = 'sunday',
    ds = ica_horario_train$timestamp[which(ica_horario_train$weekday=="domingo")],
  lower_window = 0,
  upper_window = 1)

holidays = rbind(saturday, sunday)

# Change yearly by monthly seasonality
#m = prophet(yearly.seasonality = FALSE)
#m = add_seasonality(m, name = "monthly", period = 30.5, fourier.order = 5)
#m = fit.prophet(m, train_line)

# Call the function prophet to fit the model
m = prophet(train, holidays = holidays, interval.width = 0.8) # If we want to adjust holidays prior scale, change holidays.prior.scale parameter
# m = prophet(train, interval.width = 0.8) 

# Guardamos el modelo que acabamos de entrenar
# save(m, file=paste0("./Forecast anual/",folder,"/prophet_anual_",estacion,".rda"))
# Importamos modelo
load(file=paste0("./Forecast anual/",folder,"/prophet_anual_",estacion,".rda"))

future <- make_future_dataframe(m, periods = nrow(test), freq = 3600)  # Los dias que tenemos de test, con frecuencia horaria

# Forecast
forecast <- predict(m, future)
forecast$real = ica_horario$ICA_ma60
write.csv(forecast[,c("ds","yhat","real")],paste0("./Forecast anual/",folder,"/prophet_anual_",estacion,".csv"),row.names=F)
plot(m, forecast)

plot(train, type = "l", lty = 2, ylim = c(min(train$y, forecast$yhat, na.rm = T), max(train$y, forecast$yhat, na.rm = T)), main="Train")
lines(forecast$ds, forecast$yhat, type = "l", col = "red")

plot(test, type = "l", lty = 2, ylim = c(min(test$ICA_ma60, forecast$yhat, na.rm = T), max(test$ICA_ma60, forecast$yhat, na.rm = T)), main = "Test")
lines(forecast$ds, forecast$yhat, type = "l", col = "red")

# Calculamos el mse y el mae
resultados = data.frame(cbind(as.character(forecast$ds), forecast$yhat))
colnames(resultados) = colnames(test)
resultados$timestamp = as.POSIXct(resultados$timestamp, format = "%Y-%m-%d %H:%M:%S")
test2 = merge(test, resultados, by = "timestamp", all.x = TRUE)
test2 = test2[1:10919,]  # Nos quedamos con aquellas instancias de las que tenemos informacion
error = as.numeric(test2$ICA_ma60.x) - as.numeric(as.character(test2$ICA_ma60.y))
mse = sqrt(mean(error ^ 2))
mae = mean(abs(error))
write.csv(test2,"./Forecast anual/",folder,"/Training/forecast_anual_test.csv",row.names=F)

# Plot trend, weekly seasonality and yearly seasonality
# plot_forecast_component(forecast, "trend") # By separate
prophet_plot_components(m, forecast)  # All together


###################################################################################
# Forecast diario

# Nos quedamos con los años 2015-2017 para entrenar y 2018 para validar
ica_horario_train = ica_horario[which(ica_horario$timestamp >= "2015-01-01 00:00:00" & ica_horario$timestamp < "2018-01-01 00:00:00"),]
train = ica_horario_train[, c("timestamp", "clean_ICA")]

ica_horario_test = ica_horario[which(ica_horario$timestamp >= "2018-01-01 00:00:00"),]
test = ica_horario_test[, c("timestamp", "clean_ICA")]

# Guardamos train y test
write.csv(rbind(train,test),paste0("datos_ica_filtered_",estacion,".csv"),row.names=F)

colnames(train) = c("ds", "y")

# Modeling holidays
saturday <- data_frame(
  holiday = 'saturday',
  ds = ica_horario_train$timestamp[which(ica_horario_train$weekday=="sábado")],
  lower_window = 0,
  upper_window = 1)

sunday <- data_frame(
  holiday = 'sunday',
  ds = ica_horario_train$timestamp[which(ica_horario_train$weekday=="domingo")],
  lower_window = 0,
  upper_window = 1)

holidays = rbind(saturday, sunday)

# Call the function prophet to fit the model
# Change yearly by monthly seasonality
# m = prophet(yearly.seasonality = FALSE, holidays = holidays, interval.width = 0.8)
# m = add_seasonality(m, name = "monthly", period = 30.5, fourier.order = 5)
# m = fit.prophet(m, train)
m = prophet(train, holidays = holidays, interval.width = 0.8) # If we want to adjust holidays prior scale, change holidays.prior.scale parameter
# m = prophet(train, interval.width = 0.8)

# Guardamos el modelo que acabamos de entrenar
# save(m, file=paste0("./Forecast diario/",folder,"/prophet_diario_weekend_",estacion,".rda"))
# Importamos modelo
load(file=paste0("./Forecast diario/",folder,"/prophet_diario_weekend_",estacion,".rda"))

future <- make_future_dataframe(m, periods = nrow(test), freq = 3600)  # Los dias que tenemos de test, con frecuencia horaria

# Forecast
forecast <- predict(m, future)
write.csv(forecast[,c("ds","yhat")],paste0("./Forecast diario/",folder,"/prophet_diario_",estacion,".csv"),row.names=F)
plot(m, forecast)

plot(train, type = "l", lty = 2, ylim = c(min(train$y, forecast$yhat, na.rm = T), max(train$y, forecast$yhat, na.rm = T)), main="Train")
lines(forecast$ds, forecast$yhat, type = "l", col = "red")

plot(test, type = "l", lty = 2, ylim = c(min(test$clean_ICA, forecast$yhat, na.rm = T), max(test$clean_ICA, forecast$yhat, na.rm = T)), main = "Test")
lines(forecast$ds, forecast$yhat, type = "l", col = "red", lwd=1.5)

# Hacemos un zoom de dos meses
plot(test[(nrow(test)-1440):nrow(test)], type = "l", lty = 2, ylim = c(min(test$clean_ICA, forecast$yhat, na.rm = T), max(test$clean_ICA, forecast$yhat, na.rm = T)), main = "Test")
lines(forecast$ds[(nrow(forecast)-1438):nrow(forecast)], forecast$yhat[(nrow(forecast)-1438):nrow(forecast)], type = "l", col = "red", lwd=2)

# Calculamos el mse y el mae
resultados = data.frame(cbind(as.character(forecast$ds), forecast$yhat))
colnames(resultados) = colnames(test)
resultados$timestamp = as.POSIXct(resultados$timestamp, format = "%Y-%m-%d %H:%M:%S")
test2 = merge(test, resultados, by = "timestamp", all.x = TRUE)
test2 = test2[1:2877,]  # Nos quedamos con aquellas instancias de las que tenemos informacion
error = as.numeric(test2$clean_ICA.x) - as.numeric(as.character(test2$clean_ICA.y))
mse = sqrt(mean(error ^ 2,na.rm=T))
mae = mean(abs(error),na.rm=T)
write.csv(test2,"./Forecast diario/",folder,"/Training/forecast_diario_test.csv",row.names=F)

# Plot trend, weekly seasonality and yearly seasonality
# plot_forecast_component(forecast, "trend") # By separate
prophet_plot_components(m, forecast)  # All together
