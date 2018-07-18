
# Deshabilitamos la notacion cientifica
options(scipen=999)

# Paquetes
library(data.table)
library(zoo)

getSeason <- function(dates) {
  WS <- as.Date("2000-12-21", format = "%Y-%m-%d") # Winter Solstice
  SE <- as.Date("2000-03-21",  format = "%Y-%m-%d") # Spring Equinox
  SS <- as.Date("2000-06-21",  format = "%Y-%m-%d") # Summer Solstice
  FE <- as.Date("2000-09-21",  format = "%Y-%m-%d") # Fall Equinox
  
  # Convert dates from any year to 2012 dates
  d <- as.Date(strftime(dates, format="2000-%m-%d"))
  
  ifelse (d >= WS & d < SE, "Invierno",
          ifelse (d >= SE & d < SS, "Primavera",
                  ifelse (d >= SS & d < FE, "Verano", "Otoño")))
}

# ---------------------------------------------------------------------------

for(anio in seq(2001,2018,1)){
  print(anio)
  
  # Importamos los datos 
  datos = fread(paste0("./Datos/Anio",anio,".csv"))
  datos2 = cbind(datos, matrix(NA,nrow(datos),8))
  colnames(datos2) = c(colnames(datos),"i_SO2","i_CO","i_NO2","i_PM10","i_O3","ICA","Cont","Etiqueta")
  
  # Calculamos los factores de calculo del ICA
  datos2$i_SO2 = 0.286*datos2$SO2
  datos2$i_NO2 = 0.5*datos2$NO2
  datos2$i_PM10 = 0.67*datos2$PM10
  datos2$i_O3 = 0.556*datos2$O3
  
  for(i in unique(datos2$cod_est)){
    idx = which(datos2$cod_est==i)
    datos2$i_CO[idx[1]+8:idx[length(idx)]] = 10*rollapply(datos2$CO[idx], width = 8, by = 1,
                                                          FUN = mean, align = "right")
  }
  
  # Calculamos el ICA
  datos2$ICA = apply(datos2[,c(8:12)], 1, max, na.rm=T)
  datos2$ICA[which(datos2$ICA==-Inf)] = NA
  
  # Calculamos el contaminante principal
  datos2$Cont = apply(datos2[,c(8:12)], 1, which.max)
  datos2$Cont[which(datos2$Cont=="integer(0)")] = NA
  datos2$Cont = gsub(2,"CO",datos2$Cont)
  datos2$Cont = gsub(1,"SO2",datos2$Cont)
  datos2$Cont = gsub(3,"NO2",datos2$Cont)
  datos2$Cont = gsub(4,"PM10",datos2$Cont)
  datos2$Cont = gsub(5,"O3",datos2$Cont)
  
  # Asignamos etiquetas lingüísticas
  # datos2$Etiqueta[which(datos2$ICA<75)] = "Buena"
  # datos2$Etiqueta[which(datos2$ICA>=75 & datos2$ICA<100)] = "Aceptable"
  # datos2$Etiqueta[which(datos2$ICA>=100 & datos2$ICA<150)] = "Mala"
  # datos2$Etiqueta[which(datos2$ICA>=150)] = "Muy mala"
  
  datos2$Etiqueta[which(datos2$ICA<50)] = "Buena"
  datos2$Etiqueta[which(datos2$ICA>=50 & datos2$ICA<100)] = "Aceptable"
  datos2$Etiqueta[which(datos2$ICA>=100 & datos2$ICA<150)] = "Mala"
  datos2$Etiqueta[which(datos2$ICA>=150)] = "Muy mala"
  
  # Calculamos unas columnas extra necesarias para los plots agregados
  datos2$anyo = format(as.POSIXct(datos2$timestamp), "%Y")
  datos2$dia = format(as.POSIXct(datos2$timestamp), "%j")
  datos2$hora = format(as.POSIXct(datos2$timestamp), "%H")
  datos2$mes = format(as.POSIXct(datos2$timestamp), "%m")
  datos2$weekday = weekdays(as.POSIXct(datos2$timestamp))
  # datos2$num_weekday = as.POSIXlt(datos2$timestamp)$wday  # Formato numero
  datos2$season = getSeason(as.POSIXct(datos2$timestamp))
  
  # Almacenamos los resultados
  write.csv(datos2, paste0("Datos/Anio",anio,".csv"), row.names = F)
}

