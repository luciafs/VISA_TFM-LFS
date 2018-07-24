
rm(list = ls())
options(warn=-1)  # Evitamos que se muestren "warning messages"

######################### PACKAGES #########################

list.of.packages <- c("shiny","lubridate","ggplot2","plotrix","data.table","plotly",
                      "plyr","shinyjs","dplyr","RColorBrewer","readr","forecast","markdown","knitr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(shiny)
library(lubridate)
library(ggplot2)
library(plotrix)
library(data.table)
library(RColorBrewer)
library(plotly)
library(plyr)
library(dplyr)
library(shinyjs)
library(readr)
library(forecast)
library(markdown)
library(knitr)

######################### CREDENTIALS #########################

# Credentials for access
Logged = FALSE
my_username <- "a"
my_password <- "a"


######################### PREPROCESSING #########################

# Inicializacion de variables:
#-----------------------------
# hist_ica = fread("../Calidad del aire/Preprocesado/Datos/datos_ica.csv",stringsAsFactors = F)
# # Filtrado:
# hist_ica = hist_ica[which(hist_ica$cod_est==28079024 | hist_ica$cod_est==28079008 | hist_ica$cod_est==28079018),]
# # Pasamos las fechas de caracter a fecha
# hist_ica$timestamp = as.POSIXct(hist_ica$timestamp, format = "%Y-%m-%d %H:%M:%S")
# # Quitamos info erronea
# # hist_ica = hist_ica[which(hist_ica$timestamp < "2018-05-01 00:00:00"),]
# # Nos quedamos con los años que nos interesan
# hist_ica = hist_ica[which(hist_ica$timestamp >= "2011-01-01 00:00:00"),]
# # Eliminamos los outliers y los missing values. replace.missing = TRUE linearly interpolates missing values
# hist_ica$clean_ICA = tsclean(hist_ica$ICA, replace.missing = T)
# # Suavizamos la señal
# hist_ica$ICA_ma = ma(hist_ica$clean_ICA, order = 7*24)
# hist_ica$ICA_ma60 = ma(hist_ica$clean_ICA, order = 60 * 24)
# # Quitamos las variables que no nos interesan
# hist_ica$i_SO2 = NULL
# hist_ica$i_CO = NULL
# hist_ica$i_NO2 = NULL
# hist_ica$i_PM10 = NULL
# hist_ica$i_O3 = NULL
# hist_ica$dia = NULL
# hist_ica$hora = NULL
# hist_ica$mes = NULL
# hist_ica$SO2 = tsclean(hist_ica$SO2, replace.missing = T)
# hist_ica$SO2_ma = ma(hist_ica$SO2, order = 60*24)
# hist_ica$CO = tsclean(hist_ica$CO, replace.missing = T)
# hist_ica$CO_ma = ma(hist_ica$CO, order = 60*24)
# hist_ica$NO2 = tsclean(hist_ica$NO2, replace.missing = T)
# hist_ica$NO2_ma = ma(hist_ica$NO2, order = 60*24)
# hist_ica$PM10 = tsclean(hist_ica$PM10, replace.missing = T)
# hist_ica$PM10_ma = ma(hist_ica$PM10, order = 60*24)
# hist_ica$O3 = tsclean(hist_ica$O3, replace.missing = T)
# hist_ica$O3_ma = ma(hist_ica$O3, order = 60*24)
# # Guardamos los resultados
# write.csv(hist_ica,"../Calidad del aire/Preprocesado/Datos/datos_ica_visualizacion.csv",row.names=F)

hist_ica = as.data.frame(fread("../Calidad del aire/Preprocesado/Datos/datos_ica_visualizacion.csv",stringsAsFactors = F))
hist_ica$timestamp = as.POSIXct(hist_ica$timestamp)

# weather = fread("../Información meteorológica/Weather Underground/Preprocesado/tiempo_horario.csv",stringsAsFactors = F)
# # Calculamos el timestamp a partir de las otras columnas
# weather$timestamp = paste0(weather$anyo,"-",weather$mes,"-",weather$dia," ",weather$hora,":00:00")
# # Eliminamos las muestras que no nos interesan
# weather = weather[which(weather$timestamp>="2011-01-01 00:00:00"),]
# # Hay horas con varias mediciones meteorologicas. Nos quedamos con la primera
# weather = weather[-which(duplicated(weather$timestamp)),]
# weather$temp = as.numeric(weather$temp)
# weather$temp = tsclean(weather$temp, replace.missing = T)
# weather$temp_ma = ma(weather$temp, order = 60*24)
# weather$hum = as.numeric(weather$hum)
# weather$hum = tsclean(weather$hum, replace.missing = T)
# weather$hum_ma = ma(weather$hum, order = 60*24)
# weather$presion= as.numeric(weather$presion)
# weather$presion = tsclean(weather$presion, replace.missing = T)
# weather$presion_ma = ma(weather$presion, order = 60*24)
# weather$rain = as.numeric(weather$rain)
# # weather$rain = tsclean(weather$rain, replace.missing = T)
# weather$rain_ma = ma(weather$rain, order = 60*24)
# write.csv(weather,"../Información meteorológica/Weather Underground/Preprocesado/tiempo_horario_visualizacion.csv",row.names=F)

hist_tiempo = as.data.frame(fread("../Información meteorológica/Weather Underground/Preprocesado/tiempo_horario_visualizacion.csv",stringsAsFactors = F))
hist_tiempo$timestamp = as.POSIXct(hist_tiempo$timestamp)
 

forecast_anyo_28079024 = fread("../Calidad del aire/Análisis predictivo/Prophet/Forecast anual/Casa de campo_28079024/prophet_anual_28079024.csv",stringsAsFactors = F)
forecast_anyo_28079024$ds = as.POSIXct(forecast_anyo_28079024$ds)
forecast_anyo_28079024 = forecast_anyo_28079024[which(forecast_anyo_28079024$ds >= "2018-01-01"),]
forecast_anyo_28079008 = fread("../Calidad del aire/Análisis predictivo/Prophet/Forecast anual/Escuelas Aguirre_28079008/prophet_anual_28079008.csv",stringsAsFactors = F)
forecast_anyo_28079008$ds = as.POSIXct(forecast_anyo_28079008$ds)
forecast_anyo_28079008 = forecast_anyo_28079008[which(forecast_anyo_28079008$ds >= "2018-01-01"),]
forecast_anyo_28079018 = fread("../Calidad del aire/Análisis predictivo/Prophet/Forecast anual/Farolillo_28079018/prophet_anual_28079018.csv",stringsAsFactors = F)
forecast_anyo_28079018$ds = as.POSIXct(forecast_anyo_28079018$ds)
forecast_anyo_28079018 = forecast_anyo_28079018[which(forecast_anyo_28079018$ds >= "2018-01-01"),]

######################### USER INTERFACE (UI) #########################

ui1 <- function(){
  tagList(
    div(id = "login",
        wellPanel(textInput("userName", "Username"),
                  passwordInput("passwd", "Password"),
                  br(),actionButton("Login", "Log in"))),
    tags$style(type="text/css", "#login {font-size:10px;   text-align: left;position:absolute;top: 40%;left: 50%;margin-top: -100px;margin-left: -150px;}")
  )}

ui2 <- function(){
  navbarPage("VISA - Análisis de la calidad del aire",
             tabPanel("INFO", icon = icon("info-circle"),
                      fluidRow(
                        includeMarkdown("info.md")
                      )
             ),    
             tabPanel("Información histórica", icon = icon("hourglass-half"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                             selectInput(inputId = "estacion_historico",
                                        label = "Selecciona una estación de control:", 
                                        choices = c("Casa de Campo (S)",
                                                    "Escuelas Aguirre (UT)",
                                                    "Farolillo (UF)"),
                                        selected = "Casa de Campo (S)"),
                            hr(),
                            radioButtons("periodo_seleccionado", "Periodo de análisis:",
                                         c("Todos los años" = "todos",
                                           "Un año en particular" = "año_particular"),
                                         selected = "todos"),
                            uiOutput(outputId = "años"),
                            hr(),
                            radioButtons("hist_variable", "Variable de análisis para contrastar con el ICA:",
                                         c("Contaminantes" = "hist_cont",
                                           "Condiciones meteorológicas" = "hist_tiempo"),
                                         selected = "hist_cont"),
                            uiOutput(outputId = "variable"),
                            hr(),
                            radioButtons("hist_representacion", "Tipo de representación",
                                         c("Evolución" = "hist_med",
                                           "Histograma" = "hist_hist")),
                            hr(),
                            h5("NOTA: Los gráficos pueden tardar algunos segundos en cargar debido al alto volumen de datos representado")
                          ),
                          mainPanel(
                            plotlyOutput("plot_ica"),
                            plotlyOutput("plot_variable")
                          )
                        )
                      )
             ),
             tabPanel("Predicción del ICA ", icon = icon("equalizer", lib = "glyphicon"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            h4("Estación de control:"),
                            selectInput(inputId = "estacion_prediccion",
                                        label = "Selecciona una estación en particular:", 
                                        choices = c("Casa de Campo (S)",
                                                    "Escuelas Aguirre (UT)",
                                                    "Farolillo (UF)"),
                                        selected = "Casa de Campo (S)"),
                            hr(),
                            h4("Predicción precisa (modelo reforzado):"),
                            radioButtons("forecast_reforzado", "",
                                         c("24 horas" = "forecast_24",
                                           "7 dias" = "forecast_7")),
                            hr(),
                            h4("Predicción estimada (serie temporal):"),
                            checkboxInput("forecast_año", "Año completo", FALSE)
                          ),
                          mainPanel(
                            plotlyOutput("plot_forecast"),
                            plotlyOutput("plot_forecast_anyo")
                          )
                        )
                      )
             )
  )
}

ui = (htmlOutput("page"))


######################### SERVER #########################

server = (function (input, output, session) {
  
  USER <- reactiveValues(Logged = Logged)
  # Aqui se declaran las variables globales
  width_images = 1200
  height_images = 600
  
  # Esperando el login...
  observe({
    if(USER$Logged == FALSE) {
      if (!is.null(input$Login)) {
        if (input$Login > 0) {
          Username <- isolate(input$userName)
          Password <- isolate(input$passwd)
          Id.username <- which(my_username == Username)
          Id.password <- which(my_password == Password)
          if (length(Id.username) > 0 & length(Id.password) > 0) {
            if (Id.username == Id.password) {
              USER$Logged <- TRUE
            } 
          }
        } 
      }
    }
  })
  
  observe({
    if(USER$Logged == FALSE) {
      output$page <- renderUI({
        div(class="outer",do.call(bootstrapPage,c(ui1())))  # Pantalla de login
      })
    }
    
    # Si se ha producido un login correcto:
    if(USER$Logged == TRUE){
      output$page <- renderUI({
        div(class="outer",do.call(bootstrapPage,c(ui2())))  # Pantalla de la aplicación
      }) 
      
      
      # Contenido de la aplicacion:
      #----------------------------
      
      observeEvent(input$hist_variable,{
        # Desplegable listado contaminantes
        if(input$hist_variable == "hist_cont"){
          output$variable <- renderUI({
            selectInput(inputId = "sel_contaminante",
                        label = "Selecciona un contaminante en particular:", 
                        choices = c("SO2", "CO", "NO2", "PM10", "O3"),
                        selected = "SO2", multiple=FALSE)
          })
        }
        
        # Desplegable listado condiciones climatologicas
        if(input$hist_variable == "hist_tiempo"){
          output$variable <- renderUI({
            selectInput(inputId = "sel_meteorologia",
                        label = "Selecciona un agente meteorológico en particular:", 
                        choices = c("Temperatura" = "temp", "Humedad" = "hum", "Presión" = "presion", "Lluvia" = "rain"),
                        selected = "temp", multiple=FALSE)
          })
        }
      })
      
      # Desplegable listado de años
      output$años <- renderUI({
        if(input$periodo_seleccionado == "año_particular"){
          selectInput(inputId = "años",
                      label = "Selecciona un año en particular:", 
                      choices = seq(2018,2001,-1),
                      selected = 2018, multiple=FALSE)
        }else{
          return(NULL)
        }
      })
      
      # Historico
      #-----------------------------------------
      observeEvent(input$periodo_seleccionado,{
        observeEvent(input$hist_variable,{
          observeEvent(input$estacion_historico,{
            observeEvent(input$hist_representacion,{

                if(input$estacion_historico == "Casa de Campo (S)"){
                  est_hist = "Casa de campo_28079024"
                  est_hist_code = 28079024
                }
                if(input$estacion_historico == "Escuelas Aguirre (UT)"){
                  est_hist = "Escuelas Aguirre_28079008"
                  est_hist_code = 28079008
                }
                if(input$estacion_historico == "Farolillo (UF)"){
                  est_hist = "Farolillo_28079018"
                  est_hist_code = 28079018
                }
                
                #######
                # ICA #
                #######
                if(input$periodo_seleccionado == "todos"){   # Todos los años
                  hist_ica_plot = hist_ica[which(hist_ica$cod_est==est_hist_code),
                                           c("timestamp","anyo","clean_ICA","ICA_ma","ICA_ma60")]
                  
                  if(input$hist_representacion == "hist_med"){   # Curva media
                    output$plot_ica = renderPlotly({
                      plot_ly(hist_ica_plot, x = ~timestamp, y = ~clean_ICA, type = "scatter", mode = "lines", 
                              name = "Raw data", color = I('black')) %>%
                        add_trace(y = ~ICA_ma, mode = 'lines', name = "Media móvil semanal",
                                  color = I('blue')) %>%
                        add_trace(y = ~ICA_ma60, mode = 'lines', name = "Media móvil mensual",
                                  color = I('red')) %>%
                        add_trace(x = c(hist_ica_plot$timestamp[1],hist_ica_plot$timestamp[nrow(hist_ica_plot)]),
                                  y = 50, mode = 'lines', name = " ", color = I('green'),
                                  line = list(dash = 'dash'), showlegend = FALSE) %>%
                        add_trace(x = c(hist_ica_plot$timestamp[1],hist_ica_plot$timestamp[nrow(hist_ica_plot)]),
                                  y = 100, mode = 'lines', name = " ", color = I('orange'),
                                  line = list(dash = 'dash'), showlegend = FALSE) %>%
                        add_trace(x = c(hist_ica_plot$timestamp[1],hist_ica_plot$timestamp[nrow(hist_ica_plot)]),
                                  y = 150, mode = 'lines', name = " ", color = I('red'),
                                  line = list(dash = 'dash'), showlegend = FALSE) %>%
                        layout(margin = list(t=65, b=65, pad=0),
                               title = paste0("\nEvolución histórica del ICA desde 2011 (zona ",input$estacion_historico,")"),
                               xaxis = list(title = "", tickangle = 315),
                               yaxis = list(title = "ICA", range = c(0,160)),
                               hovermode = "FALSE",
                               legend = list(x = 0.75, y = 1))
                    })
                  }
                  if(input$hist_representacion == "hist_hist"){   # Histograma
                    hist_ica_hist = aggregate(hist_ica_plot$clean_ICA, by = list(hist_ica_plot$anyo), mean, na.rm=T)
                    colnames(hist_ica_hist) = c("timestamp","clean_ICA")
                    output$plot_ica = renderPlotly({
                      plot_ly(hist_ica_hist, x = ~timestamp, y = ~clean_ICA, type = "bar") %>%
                        layout(margin = list(t=65, pad=0),
                               title = paste0("\nEvolución histórica del ICA agregado desde 2011 (zona ",input$estacion_historico,")"),
                               xaxis = list(title = "", tickangle = 315),
                               yaxis = list(title = "ICA"),
                               hovermode = "FALSE")
                    })
                  }
                }else{   # Un año en particular
                  observeEvent(input$años,{
                    if(!is.null(input$años)){
                      hist_ica_plot = hist_ica[which(hist_ica$cod_est==est_hist_code & hist_ica$anyo==input$años),
                                               c("timestamp","anyo","clean_ICA","Etiqueta","ICA_ma","ICA_ma60")]
                      
                      if(input$hist_representacion == "hist_med"){   # Curva media
                        output$plot_ica = renderPlotly({
                          plot_ly(hist_ica_plot, x = ~timestamp, y = ~clean_ICA, type = "scatter", mode = "lines",
                                  name = "ICA", color = I('black')) %>%
                            add_trace(y = ~ICA_ma, mode = 'lines', name = "Media móvil semanal",
                                      color = I('blue')) %>%
                            add_trace(y = ~ICA_ma60, mode = 'lines', name = "Media móvil mensual",
                                      color = I('red')) %>%
                            layout(margin = list(t=65, b=65, pad=0),
                                   title = paste0("\nEvolución histórica del ICA en el año ",input$años," (zona ",input$estacion_historico,")"),
                                   xaxis = list(title = "", tickangle = 315),
                                   yaxis = list(title = "ICA", range = c(0,max(hist_ica_plot$clean_ICA)*1.2)),
                                   hovermode = "FALSE",
                                   legend = list(x = 0.75, y = 1))
                        })
                      }
                      if(input$hist_representacion == "hist_hist"){   # Histograma
                        hist_ica_hist = data.frame(table(hist_ica_plot$Etiqueta))
                        colnames(hist_ica_hist) = c("Etiquetas","Porcentaje")
                        etiquetas = data.frame("Etiquetas"=c("Muy mala","Mala","Aceptable","Buena"))
                        hist_ica_hist = merge(hist_ica_hist,etiquetas,by="Etiquetas",all.y=T)
                        if(any(is.na(hist_ica_hist$Porcentaje))){
                          hist_ica_hist$Porcentaje[which(is.na(hist_ica_hist$Porcentaje))]=0
                        }
                        hist_ica_hist$Etiquetas = factor(hist_ica_hist$Etiquetas,levels(hist_ica_hist$Etiquetas)[c(4,3,1,2)])
                        hist_ica_hist$Porcentaje = (hist_ica_hist$Porcentaje/sum(hist_ica_hist$Porcentaje))*100
                        
                        output$plot_ica = renderPlotly({
                          plot_ly(hist_ica_hist, x = ~Etiquetas, y = ~Porcentaje, type = 'bar', 
                                  text = round(hist_ica_hist$Porcentaje), textposition = 'auto') %>%
                            layout(margin = list(t=65, pad=0),
                                   title = paste0("\nEvolución histórica del ICA en el año ",input$años," (zona ",input$estacion_historico,")"),
                                   xaxis = list(title = "Etiqueta ICA"),
                                   yaxis = list(title = "Porcentaje de horas"),
                                   hovermode = "FALSE")
                        })
                      }
                    }
                  })
                }
                
                
                ################
                # CONTAMINANTE #
                ################
                if(input$hist_variable == "hist_cont"){   
                  observeEvent(input$sel_contaminante,{
                    if(!is.null(input$sel_contaminante)){

                      if(input$sel_contaminante == "SO2"){
                        cont_units = "ug/m3"
                      }else if(input$sel_contaminante == "CO"){
                        cont_units = "mg/m3"
                      }else if(input$sel_contaminante == "NO2"){
                        cont_units = "ug/m3"
                      }else if(input$sel_contaminante == "PM10"){
                        cont_units = "ug/m3"
                      }else{
                        cont_units = "ug/m3"
                      }
                      
                      col_sel_contaminante = as.numeric(which(colnames(hist_ica)==input$sel_contaminante))
                      col_sel_contaminante_ma = as.numeric(which(colnames(hist_ica)==paste0(input$sel_contaminante,"_ma")))
  
                      if(input$periodo_seleccionado == "todos"){   # Todos los años
                        hist_cont_plot = hist_ica[which(hist_ica$cod_est==est_hist_code),c(1,11,col_sel_contaminante,col_sel_contaminante_ma)]
                        colnames(hist_cont_plot) = c("timestamp","anyo","contaminante","contaminante_ma")
    
                        if(input$hist_representacion == "hist_med"){   # Curva media
                          output$plot_variable = renderPlotly({
                            plot_ly(hist_cont_plot, x = ~timestamp, y = ~contaminante, type = "scatter", mode = "lines",
                                    name = "Raw data", color = I('black')) %>%
                              add_trace(y = ~contaminante_ma, mode = 'lines', name = "Media móvil mensual",
                                        color = I('red')) %>%
                              layout(margin = list(t=65, pad=0),
                                     title = paste0("\nEvolución histórica del ",input$sel_contaminante," desde 2011 (zona ",input$estacion_historico,")"),
                                     xaxis = list(title = "", tickangle = 315),
                                     yaxis = list(title = paste(input$sel_contaminante,cont_units)),
                                     hovermode = "FALSE",
                                     legend = list(x = 0.75, y = 1))
                          })
                        }
                        if(input$hist_representacion == "hist_hist"){   # Histograma
                          hist_cont_hist = aggregate(hist_cont_plot$contaminante, by = list(hist_cont_plot$anyo), mean, na.rm=T)
                          colnames(hist_cont_hist) = c("timestamp","contaminante")
                          output$plot_variable = renderPlotly({
                            plot_ly(hist_cont_hist, x = ~timestamp, y = ~contaminante, type = "bar") %>%
                              layout(margin = list(t=65, pad=0),
                                     title = paste0("\nValores medios del ",input$sel_contaminante," desde 2011 (zona ",input$estacion_historico,")"),
                                     xaxis = list(title = "", tickangle = 315),
                                     yaxis = list(title = paste(input$sel_contaminante,cont_units)),
                                     hovermode = "FALSE")
                          })
                        }
                      }else{   # Un año en particular
                        observeEvent(input$años,{
                          if(!is.null(input$años)){
                            hist_cont_plot = hist_ica[which(hist_ica$cod_est==est_hist_code & hist_ica$anyo==input$años),
                                                      c(1,11,col_sel_contaminante,col_sel_contaminante_ma)]
                            colnames(hist_cont_plot) = c("timestamp","anyo","contaminante","contaminante_ma")
    
                            if(input$hist_representacion == "hist_med"){   # Curva media
                              output$plot_variable = renderPlotly({
                                plot_ly(hist_cont_plot, x = ~timestamp, y = ~contaminante, type = "scatter", mode = "lines",
                                        name = "Raw data", color = I('black')) %>%
                                  add_trace(y = ~contaminante_ma, mode = 'lines', name = "Media móvil mensual",
                                            color = I('red')) %>%
                                  layout(margin = list(t=65, b=65, pad=0),
                                         title = paste0("\nEvolución histórica del ",input$sel_contaminante," en el año ",input$años," (zona ",input$estacion_historico,")"),
                                         xaxis = list(title = "", tickangle = 315),
                                         yaxis = list(title = paste(input$sel_contaminante,cont_units)),
                                         hovermode = "FALSE",
                                         legend = list(x = 0.75, y = 1))
                              })
                            }
                            if(input$hist_representacion == "hist_hist"){   # Histograma
                              hist_cont_hist = aggregate(hist_cont_plot$contaminante, by = list(hist_cont_plot$anyo), mean, na.rm=T)
                              colnames(hist_cont_hist) = c("timestamp","contaminante")
                              output$plot_variable = renderPlotly({
                                plot_ly(hist_cont_hist, x = ~timestamp, y = ~contaminante, type = "bar") %>%
                                  layout(margin = list(t=65, pad=0),
                                         title = paste0("\nValor medio del ",input$sel_contaminante," en el año ",input$años," (zona ",input$estacion_historico,")"),
                                         xaxis = list(title = "", tickangle = 315),
                                         yaxis = list(title = paste(input$sel_contaminante,cont_units)),
                                         hovermode = "FALSE")
                              })
                            }
                          }
                        })
                      }
                    }
                  })
                }
                
                ########################
                # DATOS METEOROLOGICOS #
                ########################
                if(input$hist_variable == "hist_tiempo"){   
                  observeEvent(input$sel_meteorologia,{
                    if(!is.null(input$sel_meteorologia)){
                      
                      if(input$sel_meteorologia == "temp"){
                        meteo_label = "Temperatura"
                        meteo_units = "(ºC)"
                      }else if(input$sel_meteorologia == "hum"){
                        meteo_label = "Humedad"
                        meteo_units = "(%)"
                      }else if(input$sel_meteorologia == "presion"){
                        meteo_label = "Presión"
                        meteo_units = "(mBar)"
                      }else{
                        meteo_label = "Lluvia"
                        meteo_units = "(Si(1)/No(0))"
                      }
                      
                      if(input$periodo_seleccionado == "todos"){   # Todos los años
                        if(input$sel_meteorologia == "temp"){
                          hist_tiempo_plot = hist_tiempo[, c("timestamp","anyo",input$sel_meteorologia,"temp_ma")]
                        }else if(input$sel_meteorologia == "hum"){
                          hist_tiempo_plot = hist_tiempo[, c("timestamp","anyo",input$sel_meteorologia,"hum_ma")]
                        }else if(input$sel_meteorologia == "presion"){
                          hist_tiempo_plot = hist_tiempo[, c("timestamp","anyo",input$sel_meteorologia,"presion_ma")]
                        }else{
                          hist_tiempo_plot = hist_tiempo[, c("timestamp","anyo",input$sel_meteorologia,"rain_ma")]
                        }
                       
                        colnames(hist_tiempo_plot) = c("timestamp","anyo","meteorologia","meteorologia_ma")
                        hist_tiempo_plot$meteorologia = as.numeric(hist_tiempo_plot$meteorologia)
                        
                        if(input$hist_representacion == "hist_med"){   # Curva media
                          output$plot_variable = renderPlotly({
                            plot_ly(hist_tiempo_plot, x = ~timestamp, y = ~meteorologia, type = "scatter", mode = "lines",
                                    name = "Raw data", color = I('black')) %>%
                              add_trace(y = ~meteorologia_ma, mode = 'lines', name = "Media móvil mensual",
                                        color = I('red')) %>%
                              layout(margin = list(t=65, b=65, pad=0),
                                     title = paste0("\n ",meteo_label," desde el año 2011"),
                                     xaxis = list(title = "", tickangle = 315),
                                     yaxis = list(title = paste(meteo_label,meteo_units)),
                                     hovermode = "FALSE",
                                     legend = list(x = 0.75, y = 1))
                          })
                        }
                        if(input$hist_representacion == "hist_hist"){   # Histograma
                          hist_meteo_hist = aggregate(hist_tiempo_plot$meteorologia, by = list(hist_tiempo_plot$anyo), mean, na.rm=T)
                          colnames(hist_meteo_hist) = c("timestamp","meteorologia")
                          output$plot_variable = renderPlotly({
                            plot_ly(hist_meteo_hist, x = ~timestamp, y = ~meteorologia, type = "bar") %>%
                              layout(margin = list(t=65, pad=0),
                                     title = paste0("\n",meteo_label," media desde el año 2011"),
                                     xaxis = list(title = "", tickangle = 315),
                                     yaxis = list(title = paste(meteo_label,meteo_units)),
                                     hovermode = "FALSE")
                          })
                        }
                      }else{   # Un año en particular
                        observeEvent(input$años,{
                          if(!is.null(input$años)){
                            if(input$sel_meteorologia == "temp"){
                              hist_tiempo_plot = hist_tiempo[which(hist_tiempo$anyo == input$años), c("timestamp","anyo",input$sel_meteorologia,"temp_ma")]
                            }else if(input$sel_meteorologia == "hum"){
                              hist_tiempo_plot = hist_tiempo[which(hist_tiempo$anyo == input$años), c("timestamp","anyo",input$sel_meteorologia,"hum_ma")]
                            }else if(input$sel_meteorologia == "presion"){
                              hist_tiempo_plot = hist_tiempo[which(hist_tiempo$anyo == input$años), c("timestamp","anyo",input$sel_meteorologia,"presion_ma")]
                            }else{
                              hist_tiempo_plot = hist_tiempo[which(hist_tiempo$anyo == input$años), c("timestamp","anyo",input$sel_meteorologia,"rain_ma")]
                            }
                            
                            colnames(hist_tiempo_plot) = c("timestamp","anyo","meteorologia","meteorologia_ma")
                            hist_tiempo_plot$meteorologia = as.numeric(hist_tiempo_plot$meteorologia)
                            
                            if(input$hist_representacion == "hist_med"){   # Curva media
                              output$plot_variable = renderPlotly({
                                plot_ly(hist_tiempo_plot, x = ~timestamp, y = ~meteorologia, type = "scatter", mode = "lines",
                                        name = "Raw data", color = I('black')) %>%
                                  add_trace(y = ~meteorologia_ma, mode = 'lines', name = "Media móvil mensual",
                                            color = I('red')) %>%
                                  layout(margin = list(t=65, b=65, pad=0),
                                         title = paste0("\n ",meteo_label," en el año ",input$años),
                                         xaxis = list(title = "", tickangle = 315),
                                         yaxis = list(title = paste(meteo_label,meteo_units)),
                                         hovermode = "FALSE",
                                         legend = list(x = 0.75, y = 1))
                              })
                            }
                            if(input$hist_representacion == "hist_hist"){   # Histograma
                              hist_meteo_hist = aggregate(hist_tiempo_plot$meteorologia, by = list(hist_tiempo_plot$anyo), mean, na.rm=T)
                              colnames(hist_meteo_hist) = c("timestamp","meteorologia")
                              output$plot_variable = renderPlotly({
                                plot_ly(hist_meteo_hist, x = ~timestamp, y = ~meteorologia, type = "bar") %>%
                                  layout(margin = list(t=65, pad=0),
                                         title = paste0("\n",meteo_label," media del año ",input$años),
                                         xaxis = list(title = "", tickangle = 315),
                                         yaxis = list(title = paste(meteo_label,meteo_units)),
                                         hovermode = "FALSE")
                              })
                            }
                          }
                        })
                      }
                    }
                  })
                }
                
            })  # input$hist_representacion
          })  # input$estacion_historico
        })  # input$hist_variable
      })  # input$periodo_seleccionado
      

      # Prediccion:
      #-----------------------------------------
      
      observeEvent(input$forecast_año,{
        observeEvent(input$forecast_reforzado,{
          observeEvent(input$estacion_prediccion,{
            if(input$estacion_prediccion == "Escuelas Aguirre (UT)"){
              est_pred = "Escuelas Aguirre_28079008"
              est_pred_code = 28079008
            }else if(input$estacion_prediccion == "Farolillo (UF)"){
              est_pred = "Farolillo_28079018"
              est_pred_code = 28079018
            }else{
              est_pred = "Casa de campo_28079024"
              est_pred_code = 28079024
            }
            
            forecast = fread(paste0("../Calidad del aire/Análisis predictivo/Resultados/",est_pred,"/forecast.csv"))
          
            # Plot prediccion anual
            if(input$forecast_año==TRUE){   
                if(est_pred_code == 28079024){
                  output$plot_forecast_anyo = renderPlotly({
                    plot_ly(forecast_anyo_28079024, x = ~ds, y = ~yhat, type = "scatter", mode = "lines",
                            name = "Predicción", legend=F) %>%
                      # add_trace(y = ~real, mode = 'lines', name = "Realidad", color = I('red'),
                                # line = list(dash = 'dash')) %>%
                      layout(margin = list(t=20, b=65, pad=0),
                             title = "\nPredicción del ICA para el resto del año (zona Casa de Campo (S))",
                             xaxis = list(title = "", tickangle = 315),
                             yaxis = list(title = "ICA", range = c(0,max(forecast_anyo_28079024$yhat)*1.5)),
                             hovermode = "FALSE")
                             # legend = list(x = 0.75, y = 1))
                  })
                }
                if(est_pred_code == 28079008){
                  output$plot_forecast_anyo = renderPlotly({
                    plot_ly(forecast_anyo_28079008, x = ~ds, y = ~yhat, type = "scatter", mode = "lines",
                            name = "Predicción", legend=F) %>%
                      # add_trace(y = ~real, mode = 'lines', name = "Realidad", color = I('red'),
                                # line = list(dash = 'dash')) %>%
                      layout(margin = list(t=20, b=65, pad=0),
                             title = "\nPredicción del ICA para el resto del año (zona Escuelas Aguirre (UT))",
                             xaxis = list(title = "", tickangle = 315),
                             yaxis = list(title = "ICA", range = c(0,max(forecast_anyo_28079008$yhat)*1.5)),
                             hovermode = "FALSE")
                             # legend = list(x = 0.75, y = 1))
                  })
                }
                if(est_pred_code == 28079018){
                  output$plot_forecast_anyo = renderPlotly({
                    plot_ly(forecast_anyo_28079018, x = ~ds, y = ~yhat, type = "scatter", mode = "lines",
                            name = "Predicción", legend=F) %>%
                      # add_trace(y = ~real, mode = 'lines', name = "Realidad", color = I('red'),
                                # line = list(dash = 'dash')) %>%
                      layout(margin = list(t=20, b=65, pad=0),
                             title = "\nPredicción del ICA para el resto del año (zona Farolillo (UF))",
                             xaxis = list(title = "", tickangle = 315),
                             yaxis = list(title = "ICA", range = c(0,max(forecast_anyo_28079018$yhat)*1.5)),
                             hovermode = "FALSE")
                            # legend = list(x = 0.75, y = 1))
                  })
                }
            }else{
              output$plot_forecast_anyo = renderPlotly({
                return(NULL)
              })
            }
            
            # Prediccion precisa
            if(input$forecast_reforzado == "forecast_24"){   # Prediccion 24h
              if(any(which(forecast$timestamp < Sys.time()))){
                forecast = forecast[-which(forecast$timestamp < Sys.time()),]
              }
              forecast = forecast[1:24,]
              forecast$timestamp = as.POSIXct(forecast$timestamp)
              
              output$plot_forecast = renderPlotly({
                plot_ly(forecast, x = ~timestamp, y = ~forecast, type = "scatter", mode = "lines") %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 50, mode = 'lines', name = " ", color = I('green'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 100, mode = 'lines', name = " ", color = I('orange'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 150, mode = 'lines', name = " ", color = I('red'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  layout(margin = list(t=65, b=100, pad=0),
                         title = paste0("\nPredicción del ICA para las próximas 24 horas (zona ",input$estacion_prediccion,")"),
                         xaxis = list(title = "", tickangle = 315),
                         yaxis = list(title = "ICA", range = c(0,160)),
                         hovermode = "FALSE")
              })
            }
            if(input$forecast_reforzado == "forecast_7"){   # Prediccion 7d
              forecast = forecast[1:(7*24),]
              forecast$timestamp = as.POSIXct(forecast$timestamp)
              
              output$plot_forecast = renderPlotly({
                plot_ly(forecast, x = ~timestamp, y = ~forecast, type = "scatter", mode = "lines") %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 50, mode = 'lines', name = " ", color = I('green'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 100, mode = 'lines', name = " ", color = I('orange'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  add_trace(x = c(forecast$timestamp[1],forecast$timestamp[nrow(forecast)]),
                            y = 150, mode = 'lines', name = " ", color = I('red'),
                            line = list(dash = 'dash'), showlegend = FALSE) %>%
                  layout(margin = list(t=65, b=100, pad=0),
                         title = paste0("\nPredicción del ICA medio para los próximos 7 días  (zona ",input$estacion_prediccion,")"),
                         xaxis = list(title = "", tickangle = 315),
                         yaxis = list(title = "ICA", range = c(0,160)),
                         hovermode = "FALSE")
              })
            }
            
          })  # input$estacion_prediccion
        })  # input$forecast_reforzado
      })  # input$forecast_año
      

    }  # USER$Logged
  })
})

runApp(list(ui = ui, server = server), launch.browser=TRUE)
