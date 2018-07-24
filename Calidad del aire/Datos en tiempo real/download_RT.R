
#	Autor: Lucia Fernandez Sanchez                 
#	TFM Master Visual Analytics and Big Data     									
#	Universidad Internacional de La Rioja (UNIR)   									

url_txt <- "http://www.mambiente.munimadrid.es/opendata/horario.txt"
download.file(url_txt, paste0("Datos/",Sys.Date(),".txt"))

url_csv <- "https://datos.madrid.es/egob/catalogo/212531-10515086-calidad-aire-tiempo-real.csv"
download.file(url_csv, paste0("Datos/",Sys.Date(),".csv"), method="libcurl")
