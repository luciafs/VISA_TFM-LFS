
#	Autor: Lucia Fernandez Sanchez                 
#	TFM Master Visual Analytics and Big Data     									
#	Universidad Internacional de La Rioja (UNIR)   									

datos = read.csv("./Anio2017/oct17.csv",sep=";")
datos = datos[,-seq(10,56,2)]
x11()
idx = which(datos$MAGNITUD==6)
# plot(as.numeric(datos[idx[1],9:32]),type="l",ylim=c(min(datos[idx,9:32]),max(datos[idx,9:32])))
plot(as.numeric(datos[idx[1],9:32]),type="l",ylim=c(min(datos[idx,9:32]),3))
for(i in idx){
  lines(as.numeric(datos[i,9:32]),type="l")
}
lines(apply(datos[idx,9:32],2,mean),type="l",col="red",lwd="2")

