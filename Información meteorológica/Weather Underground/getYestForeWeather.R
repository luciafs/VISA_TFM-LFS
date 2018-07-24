
#	Autor: Lucia Fernandez Sanchez                 
#	TFM Master Visual Analytics and Big Data     									
#	Universidad Internacional de La Rioja (UNIR)  

# Deshabilitamos la notacion cientifica
options(scipen=999)

# Paquetes
library("rjson")

#----------------------------------------------

# Descarga del tiempo de ayer
fecha_ayer = fechas = gsub("-","",Sys.Date()-1)
url_ayer <- paste0("http://api.wunderground.com/api/0ad03edf984c5730/history_",fecha_ayer,"/q/ES/Madrid.json")
download.file(url_ayer, paste0("./Historico/",fecha_ayer,".json"))

# Obtenemos los nombres de los ficheros que vamos a parsear
names = list.files("./Historico/",pattern="*.json")

# Inicializamos una variable donde se almacenaran los resultados
resultados_horarios = data.frame(matrix(0,1,13))
colnames(resultados_horarios) = c("anyo","mes","dia","hora","temp","hum","wspd","wdir","wdire","presion",
                                  "fog","rain","snow")

resultados_diarios = data.frame(matrix(0,1,15))
colnames(resultados_diarios) = c("anyo","mes","dia","temp","maxtemp","mintemp","hum","wspd","wdir","wdire","presion",
                                 "precip","fog","rain","snow")

for(i in names){
  tryCatch({
    # Leemos el fichero
    json_data <- fromJSON(paste(readLines(paste0("./Historico/",i)), collapse=""))
    
    # Creamos una matriz auxiliar para almacenar los resultados horarios
    results_aux = data.frame(matrix(NA, length(json_data$history$observations), 13))
    colnames(results_aux) = c("anyo","mes","dia","hora","temp","hum","wspd","wdir","wdire","presion",
                              "fog","rain","snow")
    
    for(j in 1:nrow(results_aux)){
      results_aux$anyo[j] = json_data$history$observations[[j]]$date$year
      results_aux$mes[j] = json_data$history$observations[[j]]$date$mon
      results_aux$dia[j] = json_data$history$observations[[j]]$date$mday
      results_aux$hora[j] = json_data$history$observations[[j]]$date$hour
      results_aux$temp[j] = json_data$history$observations[[j]]$tempm
      results_aux$hum[j] = json_data$history$observations[[j]]$hum
      results_aux$wspd[j] = json_data$history$observations[[j]]$wspdm
      results_aux$wdir[j] = json_data$history$observations[[j]]$wdird
      results_aux$wdire[j] = json_data$history$observations[[j]]$wdire
      results_aux$presion[j] = json_data$history$observations[[j]]$pressurem
      results_aux$fog[j] = json_data$history$observations[[j]]$fog
      results_aux$rain[j] = json_data$history$observations[[j]]$rain
      results_aux$snow[j] = json_data$history$observations[[j]]$snow
    }
    
    resultados_horarios = rbind(resultados_horarios, results_aux)
    
    # Creamos una matriz auxiliar para almacenar los resultados diarios
    results_aux = data.frame(matrix(NA, 1, 15))
    colnames(results_aux) = c("anyo","mes","dia","temp","maxtemp","mintemp","hum","wspd","wdir",
                              "wdire","presion","precip","fog","rain","snow")
    
    results_aux$anyo = json_data$history$dailysummary[[1]]$date$year
    results_aux$mes = json_data$history$dailysummary[[1]]$date$mon
    results_aux$dia = json_data$history$dailysummary[[1]]$date$mday
    results_aux$temp = json_data$history$dailysummary[[1]]$meantempm
    results_aux$maxtemp = json_data$history$dailysummary[[1]]$maxtempm
    results_aux$mintemp = json_data$history$dailysummary[[1]]$mintempm
    results_aux$hum = json_data$history$dailysummary[[1]]$humidity
    results_aux$wspd = json_data$history$dailysummary[[1]]$meanwindspdm
    results_aux$wdir = json_data$history$dailysummary[[1]]$meanwdird
    results_aux$wdire = json_data$history$dailysummary[[1]]$meanwdire
    results_aux$presion = json_data$history$dailysummary[[1]]$meanpressurem
    results_aux$precip = json_data$history$dailysummary[[1]]$precipm
    results_aux$fog = json_data$history$dailysummary[[1]]$fog
    results_aux$rain = json_data$history$dailysummary[[1]]$rain
    results_aux$snow = json_data$history$dailysummary[[1]]$snow
    resultados_diarios = rbind(resultados_diarios, results_aux)
    
  },error = function(error_condition){
    print(paste0("ERROR en fichero: ",i))
  })
}

# Eliminamos la primera fila de las matrices resultantes
resultados_horarios = resultados_horarios[2:nrow(resultados_horarios),]
resultados_diarios = resultados_diarios[2:nrow(resultados_diarios),]

# Sustituimos los valores -9999 y -999 por NA
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-9999", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-9999.0", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-999", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-999.0", NA)
resultados_diarios = replace(resultados_diarios, resultados_diarios == "-9999", NA)
resultados_diarios = replace(resultados_diarios, resultados_diarios == "-9999.0", NA)
resultados_diarios = replace(resultados_diarios, resultados_diarios == "-999", NA)
resultados_diarios = replace(resultados_diarios, resultados_diarios == "-999.0", NA)

# Guardamos los resultados
write.table(resultados_horarios, "./Preprocesado/tiempo_horario.csv", append = TRUE, row.names = F, col.names=F)
write.table(resultados_diarios, "./Preprocesado/tiempo_diario.csv", append = TRUE, row.names = F, col.names=F)

# Movemos los ficheros a la carpeta "Parsed"
for(i in names){
  file.copy(paste0("./Historico/",i), paste0("./Historico/Parsed/",i))
  file.remove(paste0("./Historico/",i))
}


#----------------------------------------------

# Descarga de la prediccion para los proximos 10 dias
url_forecast <- "http://api.wunderground.com/api/0ad03edf984c5730/hourly10day/q/ES/Madrid.json"
download.file(url_forecast, paste0("./Forecast/forecast.json"))

# Obtenemos el nombre del fichero que vamos a parsear
names = list.files("./Forecast/",pattern="*.json")

# Inicializamos una variable donde se almacenaran los resultados
resultados_horarios = data.frame(matrix(0,1,13))
colnames(resultados_horarios) = c("anyo","mes","dia","hora","temp","hum","wspd","wdir","wdire","presion",
                                  "fog","rain","snow")

for(i in names){
  tryCatch({
    # Leemos el fichero
    json_data <- fromJSON(paste(readLines(paste0("./Forecast/",i)), collapse=""))
    
    # Creamos una matriz auxiliar para almacenar los resultados horarios
    results_aux = data.frame(matrix(NA, length(json_data$hourly_forecast), 13))
    colnames(results_aux) = c("anyo","mes","dia","hora","temp","hum","wspd","wdir","wdire","presion",
                              "fog","rain","snow")
    
    for(j in 1:length(json_data$hourly_forecast)){
      results_aux$anyo[j] = json_data$hourly_forecast[[j]]$FCTTIME$year
      results_aux$mes[j] = json_data$hourly_forecast[[j]]$FCTTIME$mon
      results_aux$dia[j] = json_data$hourly_forecast[[j]]$FCTTIME$mday
      results_aux$hora[j] = json_data$hourly_forecast[[j]]$FCTTIME$hour
      results_aux$temp[j] = json_data$hourly_forecast[[j]]$temp$metric
      results_aux$hum[j] = json_data$hourly_forecast[[j]]$humidity
      results_aux$wspd[j] = json_data$hourly_forecast[[j]]$wspd$metric
      results_aux$wdir[j] = json_data$hourly_forecast[[j]]$wdir$degrees
      results_aux$wdire[j] = json_data$hourly_forecast[[j]]$wdir$dir
      results_aux$presion[j] = NA   # No lo tenemos en el forecast
      results_aux$fog[j] = NA   # No lo tenemos en el forecast
      results_aux$rain[j] = if(as.numeric(json_data$hourly_forecast[[j]]$qpf$metric)>0){1}else{0}
      results_aux$snow[j] = json_data$hourly_forecast[[j]]$snow$metric
    }
    
    resultados_horarios = rbind(resultados_horarios, results_aux)
    
  },error = function(error_condition){
    print(paste0("ERROR en fichero: ",i))
  })
}

# Eliminamos la primera fila de la matriz resultante
resultados_horarios = resultados_horarios[2:nrow(resultados_horarios),]

# Sustituimos los valores -9999 y -999 por NA
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-9999", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-9999.0", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-999", NA)
resultados_horarios = replace(resultados_horarios, resultados_horarios == "-999.0", NA)

# Guardamos los resultados
write.table(resultados_horarios, "./Forecast/forecast.csv",sep=",", row.names = F)
file.remove("./Forecast/forecast.json")
