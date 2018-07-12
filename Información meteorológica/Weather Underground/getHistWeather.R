
################################################################
# Este script descarga el tiempo de cualquier dia especificado #
################################################################

setwd("C:/Users/Dani y Lucía/Desktop/PFM/Input data/Información meteorológica/_Weather Underground")

fecha_ini = "2004-01-05"
fecha_fin = "2004-01-31"
 
fechas = seq(as.Date(fecha_ini), as.Date(fecha_fin), "day")   # Obtenemos el listado de dias
fechas = gsub("-","",fechas)   # Formato que necesita la API

# Descarga simple:
# for(i in fechas){
#   url_json <- paste0("http://api.wunderground.com/api/0ad03edf984c5730/history_",i,"/q/ES/Madrid.json")
#   download.file(url_json, paste0("./Historico/",i,".json"))
#   Sys.sleep(10)
# }

i=1
while(i<=length(fechas)){
  # Key 1
  # url_json <- paste0("http://api.wunderground.com/api/0ad03edf984c5730/history_",fechas[i],"/q/ES/Madrid.json")
  # Key 2
  url_json <- paste0("http://api.wunderground.com/api/f348092e8d359806/history_",fechas[i],"/q/ES/Madrid.json")
  
  tryCatch({
    download.file(url_json, paste0("./Historico/",fechas[i],".json"))
    i=i+1
  },error = function(error_condition){
    Sys.sleep(10)   # Si algo falla, no incrementamos el contador para que vuelva a intentarlo tras de 20seg
  })
  
  Sys.sleep(10)
}

print(paste0(i-1," descargas de ",length(fechas)))  # Comprobacion final de que se han descargado todos los dias del año

