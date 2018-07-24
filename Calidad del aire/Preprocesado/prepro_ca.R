
#	Autor: Lucia Fernandez Sanchez                 
#	TFM Master Visual Analytics and Big Data     									
#	Universidad Internacional de La Rioja (UNIR)   									

# Deshabilitamos la notacion cientifica
options(scipen=999)

# Paquetes
library(tidyr)
library(lubridate)
library(filesstrings)
library(data.table)
library(zoo)

getSeason <- function(dates) {
  WS <- as.Date("2000-12-21", format = "%Y-%m-%d") # Winter Solstice
  SE <- as.Date("2000-03-21",  format = "%Y-%m-%d") # Spring Equinox
  SS <- as.Date("2000-06-21",  format = "%Y-%m-%d") # Summer Solstice
  FE <- as.Date("2000-09-21",  format = "%Y-%m-%d") # Fall Equinox
  
  # Convert dates from any year to 2012 dates
  d <- as.Date(strftime(dates, format="2000-%m-%d"))
  
  ifelse (d >= WS | d < SE, "Invierno",
          ifelse (d >= SE & d < SS, "Primavera",
                  ifelse (d >= SS & d < FE, "Verano", "Otoño")))
}

# ---------------------------------------------------------------------------

anio = 2018

# Obtenemos los nombres de los ficheros que vamos a parsear
folder = paste0("Anio",anio)
names = list.files("../Datos en tiempo real/Datos/",pattern="*.txt")
codigos_interes = data.frame("cod_params"=c("01","06","08","09","10","14"),
                             "cod_names"=c("SO2","CO","NO2","PM2.5","PM10","O3"))

# Inicializamos una variable donde se almacenaran los resultados
resultados = matrix(0,1,32)
colnames(resultados) = c("cod_est","cod_params","cod_names","cod_ta","cod_pa","anio","mes","dia","H1","H2",
                         "H3","H4","H5","H6","H7","H8","H9","H10","H11","H12","H13","H14","H15","H16","H17","H18","H19","H20","H21","H22","H23","H24")

# Los vamos parseando uno a uno y el resultado lo almacenamos en un archivo referente al año
for(i in names){
  # Leemos el fichero
  file = data.frame(read.table(paste0("../Datos en tiempo real/Datos/",i)))
  # Eliminamos las comas (en caso de que las haya)
  file$V1 = gsub(",","",file$V1)
  
  # Parseamos el contenido
  if(substr(file[1,1],15,16)!=20){
    # Parseo 1 (hasta septiembre de 2017, inclusive, expresan el año con 2 digitos):
    file = file %>% separate(V1, c("cod_est","cod_params","cod_ta","cod_pa","anio","mes","dia","H1","H2",
                                   "H3","H4","H5","H6","H7","H8","H9","H10","H11","H12","H13","H14","H15","H16","H17","H18","H19","H20","H21","H22","H23","H24"),
                             sep = c(8,10,12,14,16,18,20,26,32,38,44,50,56,62,68,74,80,86,92,98,104,110,
                                     116,122,128,134,140,146,152,158), remove = T)
  }else{
    # Parseo 2 (a partir de octubre de 2017 expresan el año con 4 digitos):
    file = file %>% separate(V1, c("cod_est","cod_params","cod_ta","cod_pa","anio_rm","anio","mes","dia","H1","H2",
                                   "H3","H4","H5","H6","H7","H8","H9","H10","H11","H12","H13","H14","H15","H16","H17","H18","H19","H20","H21","H22","H23","H24"),
                             sep = c(8,10,12,14,16,18,20,22,28,34,40,46,52,58,64,70,76,82,88,94,100,106,112,
                                     118,124,130,136,142,148,154,160), remove = T)
    file$anio_rm = NULL   # Eliminamos la columna anio_rm
  }
  
  # Nos quedamos solo con los codigos de interes
  file = file[which(file$cod_params %in% codigos_interes$cod_params),]
  # Creamos una columna con los nombres de los codigos y reordenamos la posicion
  file = merge(file, codigos_interes, by = "cod_params", all.x = TRUE)
  file = file[,c(1,2,32,3:31)]
  # Eliminamos las muestras que no esten validadas (N)
  for(j in c("H1","H2","H3","H4","H5","H6","H7","H8","H9","H10","H11","H12",
             "H13","H14","H15","H16","H17","H18","H19","H20","H21","H22","H23","H24")){
    file[which(grepl("N", file[,j])==T),j] = NA
    # Eliminamos las V, ya que todos los valores numericos que quedan estan validados
    file[,j] = gsub("V","",file[,j])
    # Forzamos el formato numerico de los valores
    file[,j] = as.numeric(file[,j])
  }
  # Apendamos el resultado
  resultados = rbind(resultados, file)
  
  # Movemos el fichero parseado a la carpeta "Parseados"
  file.move(paste0("../Datos en tiempo real/Datos/",i), "../Datos en tiempo real/Datos/Parseados/")
}

# Eliminamos la primera fila
resultados = resultados[2:nrow(resultados),]
# Pasamos a formato numerico los datos de mes y dia
resultados$mes = as.numeric(resultados$mes)
resultados$dia = as.numeric(resultados$dia)
# Calculamos el date
resultados$date = as.POSIXct(paste0(anio,"-",resultados$mes,"-",resultados$dia))

#----------------------------------------------------
# Reordenamos los resultados
resultados2 = data.frame(matrix(NA,
                                length(unique(resultados$cod_est))*length(seq(as.POSIXct(paste0(resultados$date[1]," 00:00:00")),
                                                                              as.POSIXct(paste0(resultados$date[nrow(resultados)]," 23:00:00")), by="hour")),
                                8))

colnames(resultados2) = c("timestamp","cod_est","SO2","CO","NO2","PM2.5","PM10","O3")
resultados2$timestamp = rep(seq(as.POSIXct(paste0(resultados$date[1]," 00:00:00")),
                                as.POSIXct(paste0(resultados$date[nrow(resultados)]," 23:00:00")), by="hour"),
                            times = length(unique(resultados$cod_est)))
resultados2$cod_est = rep(unique(resultados$cod_est),
                          each=length(seq(as.POSIXct(paste0(resultados$date[1]," 00:00:00")),
                                          as.POSIXct(paste0(resultados$date[nrow(resultados)]," 23:00:00")), by="hour")))

# Bucle que vaya completando la tabla anterior
for(i in 1:nrow(resultados2)){
  fecha = resultados2[i,1]
  estacion = resultados2[i,2]
  
  # Buscamos que instancia de resultados coincide con los datos de entrada
  idx = which(resultados$cod_est == estacion &
                resultados$anio == substr(year(fecha),3,4) &
                resultados$mes == month(fecha) &
                resultados$dia == day(fecha))
  
  # Si coincide alguno, guardamos los resultados correspondientes a la hora de entrada
  if(length(idx)!=0){
    resultados2[i,3:8] = merge(codigos_interes,
                               resultados[idx,c("cod_params",paste0("H",hour(fecha)+1))],
                               by = "cod_params", all.x = TRUE)[,3]
  }
}

# Eliminamos la columna de datos del PM2.5
resultados2$PM2.5 = NULL

#----------------------------------------------------
# Calculamos el ICA
resultados3 = cbind(resultados2, matrix(NA,nrow(resultados2),8))
colnames(resultados3) = c(colnames(resultados2),"i_SO2","i_CO","i_NO2","i_PM10","i_O3","ICA","Cont","Etiqueta")

# Calculamos los factores de calculo del ICA
resultados3$i_SO2 = 0.286*resultados3$SO2
resultados3$i_NO2 = 0.5*resultados3$NO2
resultados3$i_PM10 = 0.67*resultados3$PM10
resultados3$i_O3 = 0.556*resultados3$O3

for(i in unique(resultados3$cod_est)){
  idx = which(resultados3$cod_est==i)
  resultados3$i_CO[(idx[1]+8):idx[length(idx)]] = 10*rollapply(resultados3$CO[idx], width = 8, by = 1,
                                                        FUN = mean, align = "right")
}

# Calculamos el ICA
resultados3$ICA = apply(resultados3[,c(8:12)], 1, max, na.rm=T)
resultados3$ICA[which(resultados3$ICA==-Inf)] = NA

# Calculamos el contaminante principal
resultados3$Cont = apply(resultados3[,c(8:12)], 1, which.max)
resultados3$Cont[which(resultados3$Cont=="integer(0)")] = NA
resultados3$Cont = gsub(2,"CO",resultados3$Cont)
resultados3$Cont = gsub(1,"SO2",resultados3$Cont)
resultados3$Cont = gsub(3,"NO2",resultados3$Cont)
resultados3$Cont = gsub(4,"PM10",resultados3$Cont)
resultados3$Cont = gsub(5,"O3",resultados3$Cont)

# Asignamos etiquetas lingüísticas
# resultados3$Etiqueta[which(resultados3$ICA<75)] = "Buena"
# resultados3$Etiqueta[which(resultados3$ICA>=75 & resultados3$ICA<100)] = "Aceptable"
# resultados3$Etiqueta[which(resultados3$ICA>=100 & resultados3$ICA<150)] = "Mala"
# resultados3$Etiqueta[which(resultados3$ICA>=150)] = "Muy mala"

resultados3$Etiqueta[which(resultados3$ICA<50)] = "Buena"
resultados3$Etiqueta[which(resultados3$ICA>=50 & resultados3$ICA<100)] = "Aceptable"
resultados3$Etiqueta[which(resultados3$ICA>=100 & resultados3$ICA<150)] = "Mala"
resultados3$Etiqueta[which(resultados3$ICA>=150)] = "Muy mala"

# Calculamos unas columnas extra necesarias para los plots agregados
resultados3$anyo = format(as.POSIXct(resultados3$timestamp), "%Y")
resultados3$dia = format(as.POSIXct(resultados3$timestamp), "%j")
resultados3$hora = format(as.POSIXct(resultados3$timestamp), "%H")
resultados3$mes = format(as.POSIXct(resultados3$timestamp), "%m")
resultados3$weekday = weekdays(as.POSIXct(resultados3$timestamp))
# resultados3$num_weekday = as.POSIXlt(resultados3$timestamp)$wday  # Formato numero
resultados3$season = getSeason(as.POSIXct(resultados3$timestamp))

# Apendamos los resultados en el fichero del año
write.table(resultados3, paste0("./Datos/",folder,".csv"), sep=",", append = TRUE, row.names = F, col.names = F)

#----------------------------------------------------
resultados3 = resultados3[which(resultados3$cod_est=="28079008" |
                                resultados3$cod_est=="28079018" |
                                resultados3$cod_est=="28079024"),]

write.table(resultados3, "./Datos/datos_ica.csv", sep=",", append = TRUE, row.names = F, col.names = F)

