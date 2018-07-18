

library(data.table)
datos = fread("Anio2001.csv")

for(anio in seq(2002,2018,1)){
  print(anio)
  datos_new = fread(paste0("Anio",anio,".csv"))
  datos = rbind(datos, datos_new)
}

# Vamos a quedarnos unicamente con el estudio de 3 estaciones de control, 1 por cada tipo:
# UT (urbana de trafico): 8; Escuelas Aguirre; Entre C/ Alcalá y C/ O' Donell 
# UF (urbana de fondo): 18; Farolillo; Calle Farolillo - C/Ervigio
# S (suburbana): 24;	Casa de Campo; Casa de Campo (Terminal del Teleférico)
# ATENCION: Las anteriores son las unicas estaciones que recogen mediciones de todos los contaminantes de interes
# y ademas desde el año 2001

datos = datos[which(datos$cod_est=="28079008" |
                    datos$cod_est=="28079018" |
                    datos$cod_est=="28079024"),]

# Guardamos los resultados
write.csv(datos, "datos_ica.csv", row.names = F)
