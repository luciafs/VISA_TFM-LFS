
# Este script descarga el tiempo del dia de ayer y la prediccion para los siguientes 10 dias

fecha_ayer = fechas = gsub("-","",Sys.Date()-1)

url_ayer <- paste0("http://api.wunderground.com/api/0ad03edf984c5730/history_",fecha_ayer,"/q/ES/Madrid.json")
download.file(url_ayer, paste0("./Historico/",fecha_ayer,".json"))

url_forecast <- "http://api.wunderground.com/api/0ad03edf984c5730/hourly10day/q/ES/Madrid.json"
download.file(url_forecast, paste0("./Forecast/forecast.json"))


