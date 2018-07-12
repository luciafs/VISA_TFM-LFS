rm(list=ls())
graphics.off()

############
# PAQUETES #
############
list.of.packages <- c("forecast","tseries","zoo","data.table","ggplot2","TSA")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(forecast)
library(tseries)
library(zoo)
library(data.table)
library(ggplot2)
library(TSA)

# ------------------------------------------------------------
# Importamos el conjunto de datos sobre el que vamos a modelar el ARIMA
ica = fread("datos_ica.csv", sep = ",", header = T)

# ERROR: Estan duplicadas las fechas -> REVISAR
# Por el momento, para solucionarlo y seguir trabajando, eliminamos los duplicados
ica = ica[-which(duplicated(ica$timestamp)),] # BORRAR XXXXXXXXXXXXXXXXXXXXXXXXX

# Pasamos las fechas de caracter a fecha
ica$timestamp = as.POSIXct(ica$timestamp,format="%Y-%m-%d %H:%M:%S")

# Eliminamos toda la informacion que no necesitamos
ica_horario = ica[which(ica$timestamp >= "2013-01-01 00:00:00"), c("timestamp", "ICA")]

# Quitamos info erronea
ica_horario = ica_horario[which(ica_horario$timestamp < "2018-05-01 00:00:00"),] # BORRAR XXXXXXXXXXXXXXXXXXXXXXXXX

# Pintamos los datos para ver que pinta tienen
ggplot(ica_horario, aes(timestamp, ICA)) +
  geom_line() +
  scale_x_datetime("month") +
  ylab("ICA") + xlab("Date")

# Hacemos time series el conjunto de datos
ica_horario_ts = ts(ica_horario$ICA)

# Eliminamos los outliers y los missing values. replace.missing = TRUE linearly interpolates missing values
ica_horario$clean_ICA = tsclean(ica_horario_ts, replace.missing = T) # OPCION A)
# ica_horario$clean_ICA = na.approx(ica_horario_ts) # OPCION B)

# Pintamos los datos "limpiados" para ver que pinta tienen
ggplot(ica_horario, aes(timestamp, clean_ICA)) +
  geom_line() +
  scale_x_datetime("month") +
  ylab("ICA") + xlab("Date")

# Suavizamos la señal
ica_horario$ICA_ma = ma(ica_horario$clean_ICA, order = 7*24) 
ica_horario$ICA_ma60 = ma(ica_horario$clean_ICA, order = 60*24)

ggplot() +
  geom_line(data = ica_horario, aes(x = timestamp, y = clean_ICA, colour = "Counts")) +
  geom_line(data = ica_horario, aes(x = timestamp, y = ICA_ma, colour = "Weekly Moving Average"), size = 1.25) +
  geom_line(data = ica_horario, aes(x = timestamp, y = ICA_ma60, colour = "Monthly Moving Average"), size = 1.25) +
  scale_color_manual(values=c("black","blue","red")) +
  ylab('ICA')

# Comprobamos la estacionariedad de la onda
adf.test(na.omit(ica_horario$ICA_ma60), alternative = "stationary") # Augmented Dickey-Fuller (ADF) test. La hipotesis nula asume que la serie no es estacionaria

# Autocorrelaciones: manera visual de comprobar la estacionariedad de los datos y a escoger los parametros del ARIMA
# ACF: Autocorrelation function. Util para el modelo MA(q). 
# PACF: Partial autocorrelation function. Util para el modelo AR(p). 
acf(na.omit(ica_horario$ICA_ma60)) # Vemos que hay autocorrelaciones en la mayoria de los lags
pacf(na.omit(ica_horario$ICA_ma60)) # El PACF muestra varios "spikes"

# Corregimos los datos segun los resultados obtenidos
ica_horario_m60 = diff(na.omit(ica_horario$ICA_ma60), differences = 1)
plot(ica_horario_m60)
adf.test(ica_horario_m60, alternative = "stationary") # Podemos comprobar que ahora la onda es estacionaria (p valor < 0.05)
acf(ica_horario_m60)
pacf(ica_horario_m60)

# Descomponemos los datos. Podemos encontrar tres tipos de componentes: estacional, tendencia y ciclica
# Componente estacional: refleja las fluctuaciones de los datos debido a los ciclos del calendario
# Componente tendencia: la tendencia puede ser ascendente o descendente
# Componente ciclica: se refiere a el incremento o descenso de patrones que no son estacionales

# Determinamos la frecuencia de la señal utilizando la transformada de Fourier
PGram = periodogram(ica_horario_m60)
PGramAsDataFrame = data.frame(freq=PGram$freq, spec=PGram$spec)
order = PGramAsDataFrame[order(-PGramAsDataFrame$spec),]
top2 = head(order, 2)
TimePeriod = 1/top2[2,1]
TimePeriod2 = 1/top2[1,1]

# freq = 24*30   # Observaciones mensuales
ica_horario_freq = ts(ica_horario_m60, frequency = TimePeriod)
decomp = decompose(ica_horario_freq)  # Opcion 1
# decomp = stl(ica_horario_freq, s.window = "periodic")  # Opcion 2
plot(decomp)
deseasonal = seasadj(decomp)  # Elimina la componente estacional
plot(deseasonal)

acf(deseasonal)
pacf(deseasonal)

# Ajuste del modelo ARIMA. El paquete forecast() nos permite configurar el modelo con la funcion arima() o generar automaticamente
# y de forma optima los parametros p, d, q con la funcion auto.arima(). Esta funcion auto.arima() juega con distintas combinaciones
# de estos parametros de manera que se optimice el critero de ajuste.
fit = auto.arima(na.omit(ica_horario$ICA_ma60))
fit2 = arima(na.omit(ica_horario$ICA_ma60), order = c(2,1,25))
fcast = forecast(fit2, h=24*30*6)

ica_arima<-stats::arima(deseasonal, order=c(2,1,0))
fcast = forecast(ica_arima, h=24*30*6)


fit = auto.arima(deseasonal, seasonal = TRUE)
tsdisplay(residuals(fit), lag.max = 45, main = 'Model Residuals') # Spikes altos en el lag 24

fit2 = arima(deseasonal, order = c(2,1,25))
tsdisplay(residuals(fit2), lag.max = 45, main = 'Model Residuals') # Spikes altos en el lag 24


# Evaluate and iterate
fcast = forecast(fit2, h = 24*30*6)  # Forecast
plot(fcast)

# Comprobamos la bondad del modelo reservando un conjunto de datos para validarlo
id_train = length(deseasonal) - (24*30*2)
hold = window(ts(deseasonal), start = id_train)
fit_no_holdout = auto.arima(ts(deseasonal[-c(id_train:length(deseasonal))]), seasonal = FALSE)
fcast_no_holdout = forecast(fit_no_holdout, h = (length(deseasonal) - id_train))
plot(fcast_no_holdout)
lines(ts(deseasonal))

# Calculamos el mse y el mae
error = hold - fcast_no_holdout$mean
mse = sqrt(mean(error ^ 2))
mae = mean(abs(error))

## Si queremos mejorar el modelo podemos incorporar la componente estacional que obtuvimos antes
#fit_w_seasonality = arima(ts(deseasonal), order = c(2, 1, 25), seasonal = list(order = c(1, 0, 0)))
#fcast_w_seasonality = forecast(fit_w_seasonality, h = (length(deseasonal) - id_train))
#plot(fcast_w_seasonality)
#lines(ts(deseasonal))

#error_w_seasonality = hold - fcast_w_seasonality$mean
#mse_w_seasonality = sqrt(mean(error_w_seasonality ^ 2))
#mae_w_seasonality = mean(abs(error_w_seasonality))

## Almacenamos los resultados
#results = list()
#results$actual = hold
#results$predicted = fcast_w_seasonality$mean

