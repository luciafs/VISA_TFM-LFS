
options(warn=-1)  # Evitamos que se muestren "warning messages"

######################### PACKAGES #########################

list.of.packages <- c("shiny","lubridate","ggplot2","plotrix","data.table",
                      "plotly","plyr","shinyjs","dplyr","RColorBrewer","readr")
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

######################### CREDENTIALS #########################

# Credentials for access
Logged = FALSE
my_username <- "a"
my_password <- "a"


######################### PREPROCESSING #########################

# Inicializacion de variables
delay_list = list()
delay_info = list()
dwell_info = list()
schedule = list()
stops_line = list()
headway_info = list()
punctuality_list = list()
headway_list = list()
distance = list()
cancel_info = list()

w = list.files("./Results/")
resumen = data.frame(matrix(NA,0,5))   # Creamos una matriz que aglutine la informacion de todos los databases que tenemos
k = 1  # Contador para ir rellenando cada fila de la matriz

for(x in w){
  y = list.files(paste0("./Results/",x))
  resumen = rbind(resumen, matrix(NA,length(y),5))
  for(z in y){
    delay_propagation_min = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/delay_propagation_min.csv"))),sep=";",header=T)

    delay_list[[paste(x,z)]] = delay_propagation_min[,-8]  # Quitamos la informacion del headway
    delay_list[[paste(x,z)]]$Time = as.character(delay_list[[paste(x,z)]]$Time)
    delay_list[[paste(x,z)]]$course = as.character(delay_list[[paste(x,z)]]$course)
    
    if(z == y[1]){
      stops_line[[x]] = unique(delay_list[[paste(x,z)]][,c(4,5)])
      stop1 = stops_line[[x]][which.min(stops_line[[x]]$Order),1]
      stop2 = stops_line[[x]][which.max(stops_line[[x]]$Order),1]
      dir1 = paste(stop1,"=>",stop2)
      dir2 = paste(stop2,"=>",stop1)
    } 
    
    resumen$V1[k] = x
    resumen$V2[k] = z
    resumen$V3[k] = paste(unique(delay_list[[paste(x,z)]]$course), collapse=", ")
    resumen$V4[k] = paste("From ",strftime(min(delay_list[[paste(x,z)]]$Time), format="%H:%M")," to ",strftime(max(delay_list[[paste(x,z)]]$Time), format="%H:%M"))
    if(file.exists(paste0("./Results/",x,"/",z,"/action_log.txt"))){
      resumen$V5[k] = "Yes"
    }else{
      resumen$V5[k] = "No"
    }
    k = k+1
    
    delay_info[[paste(x,z)]] = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/delay_info.csv"))),sep=";",header=F) 
    dwell_info[[paste(x,z)]] = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/dwell_info.csv"))),sep=";",header=F)
    schedule[[paste(x,z)]] = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/schedule.csv"))),sep=";",header=F)
    schedule[[paste(x,z)]]$V4 = as.POSIXct(schedule[[paste(x,z)]]$V4)
    schedule[[paste(x,z)]]$V5 = as.POSIXct(schedule[[paste(x,z)]]$V5)
    schedule[[paste(x,z)]]$V8 = as.POSIXct(schedule[[paste(x,z)]]$V8)
    schedule[[paste(x,z)]]$V9 = as.POSIXct(schedule[[paste(x,z)]]$V9)
    
    distance[[paste(x,z)]] = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/distance_propagator_min.csv"))),sep=";",header=T) 
    cancel_info[[paste(x,z)]] = fread(normalizePath(file.path(paste0("./Results/",x,"/",z,"/cancel_info.csv"))),sep=";",header=F)
    
    # Para mejorar: ESTO QUE VENGA HECHO
    delay_info[[paste(x,z)]]$V2 = gsub("Right",dir1,delay_info[[paste(x,z)]]$V2)
    delay_info[[paste(x,z)]]$V2 = gsub("Left",dir2,delay_info[[paste(x,z)]]$V2)
    dwell_info[[paste(x,z)]]$V2 = gsub("Right",dir1,dwell_info[[paste(x,z)]]$V2)
    dwell_info[[paste(x,z)]]$V2 = gsub("Left",dir2,dwell_info[[paste(x,z)]]$V2)
    schedule[[paste(x,z)]]$V3 = gsub("Right",dir1,schedule[[paste(x,z)]]$V3)
    schedule[[paste(x,z)]]$V3 = gsub("Left",dir2,schedule[[paste(x,z)]]$V3)
    
    punctuality_list[[paste(x,z)]] = delay_list[[paste(x,z)]][which(delay_list[[paste(x,z)]]$DatedVehicleJourneyRef != 0),]
    punctuality_list[[paste(x,z)]] = punctuality_list[[paste(x,z)]][punctuality_list[[paste(x,z)]]$Order==punctuality_list[[paste(x,z)]]$vehicle_stop,c("Time","delay")]
    freq_times = as.data.frame(table(punctuality_list[[paste(x,z)]]$Time))
    colnames(freq_times) = c("Time","Freq")
    punctuality_list[[paste(x,z)]] = merge(punctuality_list[[paste(x,z)]], freq_times, by = "Time", all = TRUE)
    
    headway_info[[paste(x,z)]] = delay_propagation_min[,-6]  # Quitamos informacion del delay
    headway_info[[paste(x,z)]]$headway = round(headway_info[[paste(x,z)]]$headway)  # ESTO QUE VENGA HECHO
    headway_list[[paste(x,z)]] = headway_info[[paste(x,z)]][which(headway_info[[paste(x,z)]]$DatedVehicleJourneyRef != 0),]
    headway_list[[paste(x,z)]] = headway_list[[paste(x,z)]][headway_list[[paste(x,z)]]$Order==headway_list[[paste(x,z)]]$vehicle_stop,c("Time","headway")]
    headway_info[[paste(x,z)]]$DatedVehicleJourneyRef  = gsub("Right",dir1,headway_info[[paste(x,z)]]$DatedVehicleJourneyRef)
    headway_info[[paste(x,z)]]$DatedVehicleJourneyRef  = gsub("Left",dir2,headway_info[[paste(x,z)]]$DatedVehicleJourneyRef)
    freq_times2 = as.data.frame(table(headway_list[[paste(x,z)]]$Time))
    colnames(freq_times2) = c("Time","Freq")
    headway_list[[paste(x,z)]] = merge(headway_list[[paste(x,z)]], freq_times2, by = "Time", all = TRUE)
  }
}

colnames(resumen) = c("Line","Date","Available services","Time range","Log?")


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
  navbarPage("SIRI Data Analytics (v1.5)",
             tabPanel("INFO", icon = icon("info-circle"),
                      DT::dataTableOutput("info"),
                      h3("See action log"),
                      h5("Click on table to see the corresponding action log:"),
                      verbatimTextOutput("log")
             ),    
             tabPanel("Timetable analysis", icon = icon("gears"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            selectInput(inputId = "line",
                                        label = "Select a line:", 
                                        choices = list.files("./Results/"),
                                        selected = list.files("./Results/")[2]),
                            uiOutput("date"),
                            uiOutput("course"),
                            hr(),
                            h3("Schedule (Aimed vs. expected)"),
                            actionButton("select_course", "See graph",icon = icon("line-chart"), 
                                         style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                            hr(),
                            h3("Delay and dwell times"),
                            uiOutput("d_direction"),
                            actionButton("select_d_direction", "See graph", icon = icon("line-chart"), 
                                         style="color: #fff; background-color: #337ab7; border-color: #2e6da4")
                          ),
                          mainPanel(
                            plotlyOutput("image")
                          )
                        )
                      )
             ),
             tabPanel("Delay analysis", icon = icon("braille"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            selectInput(inputId = "line1",
                                        label = "Select a line:", 
                                        choices = list.files("./Results/"),
                                        selected = list.files("./Results/")[2]),
                            uiOutput("date1"),
                            uiOutput("course1"),
                            checkboxInput("allServices", "Select all services", FALSE),
                            hr(),
                            h5("NOTE: red points for delays higher than \"delay threshold\" and blue points for recovery times lower than \"recovery threshold\""),
                            uiOutput("delay_th"),
                            uiOutput("recovery_th"),
                            hr(),
                            h5("+INFO: click on points to get more information"),
                            br(),
                            DT::dataTableOutput("point_selection")
                          ),
                          mainPanel(
                            plotlyOutput("cluster_chart")
                          )
                        )
                      )
             ),
             tabPanel("Regulation analysis", icon = icon("play-circle"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            selectInput(inputId = "line_2",
                                        label = "Select a line:", 
                                        choices = list.files("./Results/"),
                                        selected = list.files("./Results/")[2]),
                            
                            uiOutput("date_2"),
                            hr(),
                            uiOutput("selected_time"),
                            hr(),
                            plotlyOutput("plot0")
                            # sliderInput("selected_time", "Time:",
                            #             min = uiOutput("minimo"), max = uiOutput("maximo"),
                            #             value = uiOutput("minimo"), timeFormat="%T", step=60,
                            #             animate = animationOptions(interval = 1000))
                            
                            # sliderInput("selected_time", "Time:",
                            #             min = as.POSIXct("2017-10-11 10:30:00", tz="Europe/Paris"), max = as.POSIXct("2017-10-11 15:40:00", tz="Europe/Paris"),
                            #             value = as.POSIXct("2017-10-11 10:30:00", tz="Europe/Paris"), timeFormat="%T", step=60,
                            #             animate = animationOptions(interval = 1000))
                          ),
                          mainPanel(
                            imageOutput("plot1"),
                            imageOutput("plot2")
                          )
                        )
                      )
             ),
             tabPanel("Statistical analysis", icon = icon("bar-chart-o"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            useShinyjs(),
                            selectInput(inputId = "line_3",
                                        label = "Select a line:", 
                                        choices = list.files("./Results/"),
                                        selected = list.files("./Results/")[2]),
                            
                            uiOutput("date_3"),
                            
                            selectInput(inputId = "statics",
                                        label = "Select delay/dwell:", 
                                        choices = c("Delay", "Dwell time"),
                                        selected = "Delay"),
                            actionButton("select_stop", "Refresh graph",style="color: #fff; background-color: #337ab7; border-color: #2e6da4",
                                         icon = icon("refresh")),
                            hr(),
                            h3("Analysis by stop"),
                            br(),
                            checkboxInput("allStops", "Select all stops", FALSE),
                            uiOutput("stop"),
                            hr(),
                            h5("+INFO: click on graphs to get more information"),
                            br(),
                            DT::dataTableOutput("selection")
                          ),
                          mainPanel(
                            plotlyOutput("image2"),
                            br(),
                            plotlyOutput("plot3")
                          )
                        )
                      )
             ),
             tabPanel("KPI: Punctuality", icon = icon("dashboard"),
                        fluidPage(
                          sidebarLayout(
                            sidebarPanel(
                              selectInput(inputId = "line_4",
                                          label = "Select a line:", 
                                          choices = list.files("./Results/"),
                                          selected = list.files("./Results/")[2]),
                              uiOutput("date_4"),
                              sliderInput("selected_seconds", "Delay less than 'x' seconds:",
                                          min =  0, max =  300,
                                          value = 20, step=1),
                              hr(),
                              h5("+INFO: hover over the upper graph to get more information"),
                              br(),
                              verbatimTextOutput("vehic"),
                              br(),
                              plotlyOutput("plot5")
                            ),
                            mainPanel(
                              plotlyOutput("plot4"),
                              br(),
                              br(),
                              plotlyOutput("heatmap")
                            )
                          )
                        )
             ),
             tabPanel("KPI: Regularity", icon = icon("hourglass-half"),
                        fluidPage(
                          sidebarLayout(
                            sidebarPanel(
                              selectInput(inputId = "line_5",
                                          label = "Select a line:", 
                                          choices = list.files("./Results/"),
                                          selected = list.files("./Results/")[2]),
                              uiOutput("date_5"),
                              sliderInput("selected_minutes", "Headway less than 'x' minutes:",
                                          min =  0, max =  30,
                                          value = 10, step=1),
                              hr(),
                              h5("+INFO: hover over the upper graph to get more information"),
                              br(),
                              verbatimTextOutput("vehic2"),
                              hr(),
                              h3("Analysis by stop"),
                              br(),
                              uiOutput("stop_reg"),
                              br(),
                              DT::dataTableOutput("reg_selection")
                            ),
                            mainPanel(
                              plotlyOutput("plot6"),
                              br(),
                              plotlyOutput("plot7")
                            )
                          )
                        )
             ),
             tabPanel("KPI: Reliability", icon = icon("road"),
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            selectInput(inputId = "line_6",
                                        label = "Select a line:", 
                                        choices = list.files("./Results/"),
                                        selected = list.files("./Results/")[2]),
                            uiOutput("date_6"),
                            hr(),
                            h5("+INFO: hover over the graph to get more information"),
                            br(),
                            verbatimTextOutput("kms"),
                            br(),
                            DT::dataTableOutput("cancel_table")
                          ),
                          mainPanel(
                            plotlyOutput("plot8"),
                            br(),
                            plotlyOutput("plot9")
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
  variable <- reactiveValues(delay_propagation = data.frame(), colors = data.frame())
  width_images = 1200
  height_images = 600
  
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
        div(class="outer",do.call(bootstrapPage,c(ui1())))
      })
    }
    
    if(USER$Logged == TRUE){
      output$page <- renderUI({
        div(class="outer",do.call(bootstrapPage,c(ui2())))
      })
      
      output$info <- DT::renderDataTable({
        DT::datatable(resumen, selection="single")
      }, options = list(pageLength = 8), rownames=F)
      
      output$log<- renderText({
        row = input$info_rows_selected
        if(file.exists(paste0("./Results/",resumen$Line[row],"/",resumen$Date[row],"/action_log.txt"))){
          read_file(paste0("./Results/",resumen$Line[row],"/",resumen$Date[row],"/action_log.txt"))
        }else{}
      })
      
      output$date <- renderUI({
        selectInput(inputId = "date",
                    label = "Select a database:", 
                    choices = resumen$Date[which(resumen$Line==input$line)],
                    selected = resumen$Date[which(resumen$Line==input$line)][1])
      })
      
      output$date1 <- renderUI({
        selectizeInput(inputId = "date1",
                       label = "Select the date you want to analyze:", 
                       choices = resumen$Date[which(resumen$Line==input$line1)],
                       selected = resumen$Date[which(resumen$Line==input$line1)][1])
      })
      
      output$date_2 <- renderUI({
        selectInput(inputId = "date_2",
                    label = "Select a database:", 
                    choices = resumen$Date[which(resumen$Line==input$line_2)],
                    selected = resumen$Date[which(resumen$Line==input$line_2)][1])
      })
      
      output$date_3 <- renderUI({
        selectizeInput(inputId = "date_3",
                       label = "Select all the databases you want to analyze:", 
                       choices = resumen$Date[which(resumen$Line==input$line_3)],
                       selected = resumen$Date[which(resumen$Line==input$line_3)][1],
                       multiple = TRUE)
      })
      
      output$date_4 <- renderUI({
        selectizeInput(inputId = "date_4",
                       label = "Select all the databases you want to analyze:", 
                       choices = resumen$Date[which(resumen$Line==input$line_4)],
                       selected = resumen$Date[which(resumen$Line==input$line_4)][1],
                       multiple = TRUE)
      })
      
      output$date_5 <- renderUI({
        selectizeInput(inputId = "date_5",
                       label = "Select all the databases you want to analyze:", 
                       choices = resumen$Date[which(resumen$Line==input$line_5 & nchar(resumen$`Available services`)>2)],
                       selected = resumen$Date[which(resumen$Line==input$line_5 & nchar(resumen$`Available services`)>2)][1],
                       multiple = TRUE)
      })
      
      output$date_6 <- renderUI({
        selectizeInput(inputId = "date_6",
                       label = "Select the date you want to analyze:", 
                       choices = resumen$Date[which(resumen$Line==input$line_6)],
                       selected = resumen$Date[which(resumen$Line==input$line_6)][1])
      })
      
      output$course <- renderUI({
        selectInput(inputId = "course",
                    label = "Select a service:", 
                    choices = unique(read.table(paste0("./Results/",input$line,"/",input$date,"/delay_info.csv"),header=F,sep=";")[,1]),
                    selected = unique(read.table(paste0("./Results/",input$line,"/",input$date,"/delay_info.csv"),header=F,sep=";")[,1])[1])
      })
      
      output$course1 <- renderUI({
        selectInput(inputId = "course1",
                    label = "Select a service:", 
                    choices = unique(read.table(paste0("./Results/",input$line1,"/",input$date1,"/delay_info.csv"),header=F,sep=";")[,1]),
                    selected = unique(read.table(paste0("./Results/",input$line1,"/",input$date1,"/delay_info.csv"),header=F,sep=";")[,1])[1])
      })
      

      observeEvent(input$select_course,{
        line = input$line
        date = input$date
        course = input$course
        sch = schedule[[paste(line, date)]]
        colnames(sch) = c("Course","StopName","DatedVehicleJourneyRef","OriginAimedTime","DestinationAimedTime",
                          "Order","VehicleAtStop","AimedTime","ExpectedTime","Status")
        pos = which(sch$Course == course)
        sch_c = sch[pos,]
        sch_c = sch_c[order(sch_c[,3],sch_c[,8],sch_c[,9]),]
        stops_sch = stops_line[[line]]
        
        output$image = renderPlotly({
          plot_ly(sch_c, x = ~AimedTime, y = ~reorder(StopName,Order),type = 'scatter', mode = 'lines', transforms = list(groups = ~OriginAimedTime),
                  color =~DatedVehicleJourneyRef, colors = rainbow(nrow(sch_c)+1) , line= list(width = 1)) %>%
            add_trace(x = ~ExpectedTime,transforms = list(groups = ~OriginAimedTime),
                      color =~DatedVehicleJourneyRef , line= list(width = 2, dash = "dash"), showlegend = FALSE) %>%
            layout(width = 1000, height = 700,margin = list(t=65, pad=0), 
                   title = paste0("\nAimed vs. Expected (",line,", Date: ",date,", Service: ",course,")"),
                   xaxis = list(title = " ",tickangle = 270),
                   yaxis = list(title = "Stop name", type = "category", range = c(0.8, nrow(stops_sch)+0.2),
                                categoryorder = "array", categoryarray = c("", stops_sch$StopName)),
                   hovermode = "closest")
        })
      })

      observeEvent(input$line,{
        stops = stops_line[[input$line]]
        stop1 = stops[which.min(stops$Order),1]
        stop2 = stops[which.max(stops$Order),1]
        
        output$d_direction <- renderUI({
          selectInput(inputId = "d_direction",
                      label = "Select a direction:", 
                      choices = c("Whole service", paste(stop1,"=>",stop2), paste(stop2,"=>",stop1)),
                      selected = "Whole service")
        })
      }) 
      
      observeEvent(input$select_d_direction,{
        line = input$line
        date = input$date
        course = input$course
        dir = input$d_direction
        
        stops = stops_line[[line]]
        delay = delay_info[[paste(line,date)]]
        colnames(delay) = c("Course","DatedVehicleJourneyRef","StopName","Order","AimedArrivalTime","delay","distance","cum_distance","cancellations")
        dwell = dwell_info[[paste(line,date)]]
        colnames(dwell) = c("Course","DatedVehicleJourneyRef","StopName","Order","ExpectedArrivalTime","ExpectedDepartureTime","dwell", "running")
          
        if(dir == "Whole service"){
          pos = which(delay$Course == course)
          delay_c = delay[pos,]
          pos = which(dwell$Course == course)
          dwell_c = dwell[pos,]
          output$image = renderPlotly({
            p1 = plot_ly(delay_c, x = ~reorder(StopName,Order), y = ~delay, type = "bar",
                         color =~DatedVehicleJourneyRef, colors = rainbow(nrow(delay_c)+1)) %>%
              layout(width = 1000, height = 700,margin = list(t=65, pad=0), 
                     title = paste0("\n",line,", Date: ",date,", Service: ",course),
                     xaxis = list(title="",type = "category", range = c(0, nrow(stops)+1),
                                  categoryorder = "array", categoryarray = c("",stops$StopName)), 
                     yaxis = list(title="Delay (Seconds)"),
                     hovermode = "closest")
            
            p2 = plot_ly(dwell_c, x = ~reorder(StopName,Order), y = ~dwell+5, type = "bar",
                         showlegend = F, color =~DatedVehicleJourneyRef, colors = rainbow(nrow(dwell_c)+1)) %>%
              layout(width = 1000, height = 700,margin = list(t=65, pad=0), title = paste0("\n",line,", Date: ",date,", Service: ",course),
                     xaxis = list(title="Stop name",type = "category", range = c(0, nrow(stops)+1),
                                  categoryorder = "array", categoryarray = c("",stops$StopName)),
                     yaxis = list(title="Dwell time (Seconds)"),
                     hovermode = "closest")
            
            subplot(p1,p2,nrows=2,titleX=T,titleY=T)
          })
        }else{
          pos = intersect(which(delay$Course == course),grep(dir,delay$DatedVehicleJourneyRef))
          delay_c = delay[pos,]
          pos = intersect(which(dwell$Course == course),grep(dir,dwell$DatedVehicleJourneyRef))
          dwell_c = dwell[pos,]
          output$image = renderPlotly({
            p1 = plot_ly(delay_c, x = ~reorder(StopName,Order), y = ~delay, legendgroup = ~DatedVehicleJourneyRef,
                         type = "bar", color =~DatedVehicleJourneyRef, colors = rainbow(nrow(delay_c)+1) ) %>%
              layout(width = 1000, height = 700,margin = list(t=65, pad=0),
                     xaxis = list(title="",type = "category", range = c(0, nrow(stops)+1),
                                  categoryorder = "array", categoryarray = c("",stops$StopName)),
                     yaxis = list(title="Delay (Seconds)"),
                     hovermode = "closest")
            
            p2 = plot_ly(dwell_c, x = ~reorder(StopName,Order), y = ~dwell+5, legendgroup = ~DatedVehicleJourneyRef,
                         showlegend = F, type = "bar", color =~DatedVehicleJourneyRef, colors = rainbow(nrow(dwell_c)+1)) %>%
              layout(width = 1000, height = 700,margin = list(t=65, pad=0),
                     title = paste0("\nDirection: ", dir," (",line,", Date: ",date,", Service: ",course,")"),
                     xaxis = list(title="Stop name",type = "category", range = c(0, nrow(stops)+1),
                                  categoryorder = "array", categoryarray = c("",stops$StopName)),
                     yaxis = list(title="Dwell time (Seconds)"),
                     hovermode = "closest")
            
            subplot(p1,p2,nrows=2,titleX=T,titleY=T)
          })
        }
      })
      
      observeEvent(input$line1,{
        observeEvent(input$date1,{
          observeEvent(input$course1,{
            x = input$line1
            z = input$date1
            
            if(!is.null(delay_info[[paste(x,z)]])){  # Para evitar el error en ese instante que pasamos de una fecha con una linea a otra fecha que no tiene esa linea
              observeEvent(input$allServices,{
                delay_info_clus = delay_info[[paste(x,z)]]
                colnames(delay_info_clus) = c("course","DatedVehicleJourneyRef","StopName","Order","Time","delay","distance","cum_distance","cancellations")
                if(input$allServices == F){  # Si no esta seleccionada la opcion "All services"...
                  delay_info_clus = delay_info_clus[which(delay_info_clus$course==input$course1),]
                }
                
                output$delay_th <- renderUI({
                  sliderInput("delay_th", "Delay threshold in seconds:",
                              min =  ifelse(max(delay_info_clus$delay)<1,max(delay_info_clus$delay),1), max = max(delay_info_clus$delay),
                              value = 0, step=1)
                })
                
                output$recovery_th <- renderUI({
                  sliderInput("recovery_th", "Recovery threshold in seconds:",
                              min =  ifelse(min(delay_info_clus$delay)<=0,min(delay_info_clus$delay),0), max = 0,
                              value = 0, step=-1)
                })
              
              observeEvent(input$delay_th,{
                observeEvent(input$recovery_th,{
                    sec_recovery_th = as.numeric(input$recovery_th)
                    sec_delay_th = as.numeric(input$delay_th)
                    
                    delay_info_clus$Time = as.POSIXct(delay_info_clus$Time)
                    delay_info_clus$clus_thr = 0
                    delay_info_clus$clus_thr[which(delay_info_clus$delay<=sec_recovery_th)] = 1
                    delay_info_clus$clus_thr[which(delay_info_clus$delay>sec_delay_th)] = 2
  
                    output$cluster_chart = renderPlotly({
                      plot_ly(delay_info_clus[which(delay_info_clus$clus_thr>0),], x = ~Time, y = ~StopName, type = "scatter",
                              mode = "markers", marker = list(size=7),
                              color=~clus_thr, colors=c("blue","red")) %>%
                        hide_colorbar() %>%
                        layout(width = 1000, height = 700, margin = list(t=65, pad=0), title = "Delay clusters",
                               xaxis = list(title = "", tickangle = 270,
                                            range = c(min(delay_info_clus$Time),max(delay_info_clus$Time))),
                               yaxis = list(title = "Stop name", range = c(0.8, nrow(stops_line[[x]])+0.2),
                                            categoryorder = "array", categoryarray = c("", stops_line[[x]]$StopName)),
                               hovermode = "closest", bargap = 0.1,
                               plot_bgcolor="transparent", paper_bgcolor="transparent")
                    })
                  })
                })
              
                output$point_selection <- DT::renderDataTable({
                  s <- event_data("plotly_click")
                  if (length(s) == 0) {
                  }else{
                    s = as.list(s)
                    delay_info_clus[which(delay_info_clus$Time==as.POSIXct(s$x) & delay_info_clus$StopName==s$y),
                                    c("DatedVehicleJourneyRef","StopName","Time","delay")]
                  }
                }, options = list(pageLength = 1), rownames=F)
              
              })
            }
          })
        })
      })
      
      
      observeEvent(input$date_2,{
        delay_propagation = delay_list[[paste(input$line_2,input$date_2)]]
        colors = data.frame(cbind("course"=unique(delay_propagation$course),"col"=sample(colours(),length(unique(delay_propagation$course)))))
        
        output$selected_time <- renderUI({
          sliderInput("selected_time", "Time:",
                      min =  as.POSIXct(delay_propagation$Time[1], tz="GMT"), max =  as.POSIXct(delay_propagation$Time[nrow(delay_propagation)], tz="GMT"),
                      value = as.POSIXct(delay_propagation$Time[1], tz="GMT"), timeFormat="%T", timezone="GMT", step=60)
        })
        variable$delay_propagation = delay_propagation
        variable$colors = colors
        
        delay_propagation_agg = delay_propagation[which(delay_propagation$Order==delay_propagation$vehicle_stop),c("Time","delay")]
        delay_propagation_agg = aggregate(delay~Time, data=delay_propagation_agg, max)
        delay_propagation_agg$Time = strftime(delay_propagation_agg$Time, format="%H:%M")

        output$plot0 = renderPlotly({
          plot_ly(delay_propagation_agg, x = ~Time, y = ~delay, type = "scatter", mode = "lines") %>%
            layout(margin = list(t=50, pad=0), title = paste0("\n Maximum delay"),
                   xaxis = list(title = "", tickangle = 270),
                   yaxis = list(title = "Time (Seconds)"),
                   hovermode = "FALSE", plot_bgcolor="transparent", paper_bgcolor="transparent")
        })
        
      })
      
      observeEvent(input$selected_time,{
        delay_propagation = variable$delay_propagation  
        colors = variable$colors
        time_selected = as.character(input$selected_time)
        
        print_data = delay_propagation[which(delay_propagation$Time==time_selected),]
        print_data = print_data[which(print_data$Order==print_data$vehicle_stop | print_data$vehicle_stop==0),]
        print_data$delay[which(print_data$vehicle_stop==0)] = 0
        
        # Eliminamos todas aquellas instancias que tienen vehicle_stop=0, salvo en los momentos en el que todo es igual a 0
        if(any(print_data$vehicle_stop!=0)==TRUE){
          print_data = print_data[which(print_data$vehicle_stop!="0"),]
        }
        
        # Nos aseguramos que estan todos los courses representados, para que en la leyenda salgan todos siempre
        for(i in unique(delay_propagation$course)){
          if(any(print_data$course==i)==FALSE){
            var1= data.frame(cbind(time_selected,i,0,delay_propagation$StopName[1],delay_propagation$vehicle_stop[1],0,0,""))
            # var1= data.frame(cbind(as.character(print_data$Time[1]),i,0,print_data$StopName[1],print_data$vehicle_stop[1],0,0,""))
            colnames(var1) = colnames(print_data)
            print_data = rbind(print_data,var1)  # Establecemos una parada por defecto ("ND")
          }
        }
        
        # Nos aseguramos que estan todos las paradas representadas, para que en el eje x salgan todas siempre
        for(i in as.character(unique(delay_propagation$StopName))){
          if(any(as.character(print_data$StopName)==i)==FALSE){
            var= data.frame(cbind(time_selected,as.character(print_data$course[1]),0,i,which(unique(delay_propagation$StopName)==i),0,0,""))
            colnames(var) = colnames(print_data)
            print_data = rbind(print_data,var)
          }
        }
        
        # Nos aseguramos de que las siguientes columnas tienen formato numerico (por alguna razon se cambia en el bucle anterior)
        print_data$Order = as.numeric(as.character(print_data$Order))
        print_data$delay = as.numeric(as.character(print_data$delay))
        print_data$vehicle_stop = as.numeric(as.character(print_data$vehicle_stop))
        
        # Establecemos un color para cada course
        for(i in as.character(colors$course)){
          print_data$col[which(print_data$course==i)] = as.character(colors$col[which(colors$course==i)])
        }
        
        print_data = print_data[order(print_data$Order),]
        print_data$course = factor(print_data$course)
        print_data$course = factor(print_data$course, levels = sort(as.numeric(levels(print_data$course))))
        print_data[which(print_data$direction == "")]$delay = NA
        print_data[which(print_data$vehicle_stop == 0)]$delay = NA
        output$plot1 = renderPlot({
          p_delay=
            ggplot(data=print_data, aes(x=reorder(StopName,Order), y=delay, group=col, fill=course)) +
            scale_y_continuous(limits = c(min(delay_propagation$delay),(max(delay_propagation$delay)+300))) +
            geom_bar(stat="identity",position="dodge",colour="black") +
            geom_text(aes(label=delay), position=position_dodge(width=0.9), vjust=-1) +
            geom_text(aes(label=direction, colour=course), position=position_dodge(width=0.9), vjust=-1.5,size = 8) +
            # scale_fill_manual( values = colors$col, drop = FALSE) +
            xlab("Stop name") + ylab("Time (Seconds)") + ggtitle("Delay at stop arrivals") +
            theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
                  axis.title = element_text(face="bold"),
                  axis.text.x = element_text(angle = 90))
          print(p_delay)
        },height=400)
        
        
        output$plot2 = renderPlot({
          p_delay_stops=
            ggplot(data=print_data, aes(x=reorder(course,as.numeric(course)), y=delay, group=course, fill=course)) +
            scale_y_continuous(limits = c(min(delay_propagation$delay),(max(delay_propagation$delay)+300))) +
            geom_bar(stat="identity",position="dodge",colour="black") +
            geom_text(aes(label=delay), position=position_dodge(width=0.9), vjust=-1) +
            # scale_fill_manual( values = colors$col, drop = FALSE) +
            xlab("Course") + ylab("Time (Seconds)") + ggtitle("Accumulated delay per course") +
            theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
                  axis.title = element_text(face="bold"))
          print(p_delay_stops)
        },height=300)
      })
      
      
      observeEvent(input$select_stop,{
        if(input$statics=="Delay"){
          for(m in 1:length(input$date_3)){
            if(m==1){
              delay = delay_info[[paste(input$line_3,input$date_3[m])]]
            }else{
              delay = rbind(delay,delay_info[[paste(input$line_3,input$date_3[m])]])
            }
          }
          colnames(delay) = c("course","DatedVehicleJourneyRef","StopName","Order","Time","delay","distance","cum_distance","cancellations")
          delay$delay = as.numeric(delay$delay)
          
          x1 <- list(title = "Stop")
          y1 <- list(title = "Delay time (Seconds)")
          output$image2 = renderPlotly({
            plot_ly(data = delay, x = reorder(delay$StopName,delay$Order), y = delay$delay, color = delay$StopName, type = "box") %>%
              layout(margin = list(t=65, pad=0), title = "\nDistribution of delay time per stop", xaxis = x1, yaxis = y1, hovermode = "FALSE")
          })
          
          x2 <- list(title = "Delay time (Seconds)")
          y2 <- list(title = "Number of services")
          observeEvent(input$allStops,{
            if(input$allStops == F){
              output$plot3 = renderPlotly({
                plot_ly(x = delay$delay[which(delay$StopName == input$stop)],type = "histogram") %>%
                  layout(margin = list(t=65, pad=0), title = paste0("\nDistribution of delay time for stop ",input$stop),xaxis = x2, yaxis = y2, hovermode = "FALSE")
              })
              
              output$stop <- renderUI({
                stops = stops_line[[input$line_3]]$StopName
                selectInput(inputId = "stop",
                            label = "Select only one stop:", 
                            choices = stops,
                            selected = stops[1])
              })
            }else{
              output$plot3 = renderPlotly({
                plot_ly(x = delay$delay,type = "histogram") %>%
                  layout(margin = list(t=65, pad=0), title = "\nDistribution of delay time for all the stops",xaxis = x2, yaxis = y2, hovermode = "FALSE")
              })
              
              disable("stop")
            }
            
            output$selection <- DT::renderDataTable({
              s <- event_data("plotly_click")
              if (length(s) == 0) {
              }else{
                s = as.list(s)
                if(typeof(s[[3]]) == "character"){  # Click en el boxplot
                  mediana = s[[4]][1]
                  q25 = max(s[[4]][which(s[[4]]<mediana)])
                  q75 = min(s[[4]][which(s[[4]]>mediana)])
                  minimo = min(s[[4]])
                  maximo = max(s[[4]])
                  resultados_box = data.frame(c(minimo,q25,mediana,q75,maximo))
                  resultados_box = cbind(c("Min", "Q25", "Q50 (Median)", "Q75", "Max"),resultados_box)
                  colnames(resultados_box) = c("Metrics","Value")
                  resultados_box
                }else{  # Click en el histograma
                  if(input$allStops == F){
                    aux = which(delay$StopName == input$stop)
                    delay_stop = delay[aux,]
                  }
                  else{
                    delay_stop = delay
                  }
                  indexes = c(sort(abs(delay_stop$delay - s[[3]]),index.return=T)$ix[1:s[[4]]])
                  delay_stop[indexes,c("DatedVehicleJourneyRef","Time","delay")] 
                }
              }
            }, options = list(pageLength = 10), rownames=F)
          })
        }
        
        if(input$statics=="Dwell time"){
          for(m in 1:length(input$date_3)){
            if(m==1){
              dwell = dwell_info[[paste(input$line_3,input$date_3[m])]]
            }else{
              dwell = rbind(dwell,dwell_info[[paste(input$line_3,input$date_3[m])]])
            }
          }
          
          dwell = dwell[complete.cases(dwell),]
          dwell = unique(dwell)
          colnames(dwell) = c("Course","DatedVehicleJourneyRef","Stop","Order","ExpectedArrivalTime","ExpectedDepartureTime","dwell","running")
          dwell$dwell = as.numeric(dwell$dwell)
          
          x <- list(title = "Stop")
          y <- list(title = "Dwell time (Seconds)")
          output$image2 = renderPlotly({
            plot_ly(data = dwell, x = reorder(dwell$Stop,dwell$Order), y = dwell$dwell, color = dwell$Stop, type = "box") %>%
              layout(margin = list(t=65, pad=0), title = "\nDistribution of dwell time per stop", xaxis = x, yaxis = y, hovermode = "FALSE")
          })
          
          x <- list(title = "Dwell time (Seconds)")
          y <- list(title = "Number of services")
          
          observeEvent(input$allStops,{
            if(input$allStops == F){
              output$plot3 = renderPlotly({
                plot_ly(x = dwell$dwell[which(dwell$Stop == input$stop)],type = "histogram") %>%
                  layout(margin = list(t=65, pad=0), title = paste0("\nDistribution of dwell time for stop ",input$stop),xaxis = x, yaxis = y, hovermode = "FALSE", bargap = 0.1)
              })
              
              output$stop <- renderUI({
                stops = stops_line[[input$line_3]]$StopName
                selectInput(inputId = "stop",
                            label = "Select only one stop:", 
                            choices = stops,
                            selected = stops[1])
              })
            }else{
              output$plot3 = renderPlotly({
                plot_ly(x = dwell$dwell,type = "histogram") %>%
                  layout(margin = list(t=65, pad=0), title = "\nDistribution of dwell time for all the stops",xaxis = x, yaxis = y, hovermode = "FALSE", bargap = 0.1)
              })
              
              disable("stop")
            }
            
            output$selection <- DT::renderDataTable({
              s <- event_data("plotly_click")
              if (length(s) == 0) {
              }else{
                s = as.list(s)
                if(typeof(s[[3]]) == "character"){  # Click en el boxplot
                  mediana = s[[4]][1]
                  q25 = max(s[[4]][which(s[[4]]<mediana)])
                  q75 = min(s[[4]][which(s[[4]]>mediana)])
                  minimo = min(s[[4]])
                  maximo = max(s[[4]])
                  resultados_box = data.frame(c(minimo,q25,mediana,q75,maximo))
                  resultados_box = cbind(c("Min", "Q25", "Q50 (Median)", "Q75", "Max"),resultados_box)
                  colnames(resultados_box) = c("Metrics","Value")
                  resultados_box
                }else{  # Click en el histograma
                  if(input$allStops == F){
                    aux = which(dwell$Stop == input$stop)
                    dwell_stop = dwell[aux,]
                  }
                  else{
                    dwell_stop = dwell
                  }
                  indexes = c(sort(abs(dwell_stop$dwell - s[[3]]),index.return=T)$ix[1:s[[4]]])
                  dwell_stop[indexes,c("DatedVehicleJourneyRef","ExpectedArrivalTime","dwell")] 
                }
              }
            }, options = list(pageLength = 10), rownames=F)
          })
        }
      })
      
      
      observeEvent(input$line_4,{
        observeEvent(input$date_4,{
          x = input$line_4
          z = input$date_4
          
          observeEvent(input$selected_seconds,{
            sec_selection = as.numeric(input$selected_seconds)
            for(n in 1:length(input$date_4)){
              if(n==1){
                punct_selection1 = punctuality_list[[paste(x,z[n])]]
              }else{
                punct_selection1 = rbind(punct_selection1,punctuality_list[[paste(x,z[n])]])
              }
            }
            
            punct_selection2 = punct_selection1[which(punct_selection1$delay<=sec_selection),]
            freq_times_punct = as.data.frame(table(punct_selection2$Time))
            
            if(nrow(freq_times_punct)>0){  # Para evitar el error en ese instante que pasamos de una fecha con una linea a otra fecha que no tiene esa linea
              colnames(freq_times_punct) = c("Time","Freq_punct")
              punct_selection1 = merge(punct_selection1, freq_times_punct, by = "Time", all = TRUE)
              punctuality = punct_selection1[which(duplicated(punct_selection1$Time)==F),]
              punctuality$Time = strftime(punctuality$Time, format="%H:%M")
              punctuality$delay[is.na(punctuality$delay)] = 0
              punctuality$Freq[is.na(punctuality$Freq)] = 0
              # Si se han seleccionado varias fechas, hay que agregar los datos de cada una, ya que pueden compartir horas
              punctuality = aggregate(punctuality[,c(2,3,4)], by=list(Time=punctuality$Time), FUN=sum)  
              punctuality$punct = punctuality$Freq_punct/punctuality$Freq  # Calculamos el KPI puntualidad
              punctuality$punct[is.na(punctuality$punct)] = 0
              
              output$plot4 = renderPlotly({
                plot_ly(punctuality, x = ~Time, y = ~punct, type = "scatter", mode = "lines") %>%
                  layout(margin = list(t=65, pad=0), title = paste0("\nService punctuality (trips delayed by less than ",sec_selection," seconds)"),
                         xaxis = list(title = "", range=c(min(punctuality$Time),max(punctuality$Time)),tickangle = 270),
                         yaxis = list(title = "Punctuality", range=c(0,1)),
                         hovermode = "FALSE")
              })
              
              
              output$vehic <- renderText({
                g <- event_data("plotly_hover")
                if (length(g) == 0  | length(g) != 4) {
                  paste(("Number of vehicles that meet the condition: 0"),("Total number of vehicles running: 0"),sep="\n")
                }else{
                  g = as.list(g)
                  paste((paste0("Number of vehicles that meet the condition: ",
                                punctuality$Freq_punct[which(punctuality$Time==g[[3]])])),
                        (paste0("Total number of vehicles running: ",
                                punctuality$Freq[which(punctuality$Time==g[[3]])])),sep="\n")
                }
              })
              
              
              output$plot5 = renderPlotly({
                f <- event_data("plotly_hover")
                cursor_data = punct_selection1[which(strftime(punct_selection1$Time, format="%H:%M")==f[[3]]),]
                x <- list(title = "Delay time (Seconds)")
                y <- list(title = "Number of vehicles")
                if(length(f) == 0  | length(f) != 4){
                  plot_ly(x = cursor_data$delay ,type = "histogram") %>%
                    layout(margin = list(t=65, pad=0), title = "Distribution of delay",xaxis = x, yaxis = y, hovermode = "FALSE", bargap = 0.1,
                           plot_bgcolor="transparent", paper_bgcolor="transparent")
                }else{
                  plot_ly(x = cursor_data$delay ,type = "histogram") %>%
                    layout(margin = list(t=65, pad=0), title = paste0("\nDistribution of delay at ",f[[3]]),xaxis = x, yaxis = y, hovermode = "FALSE", bargap = 0.1,
                           plot_bgcolor="transparent", paper_bgcolor="transparent")
                }
              })
              
            }
          })
          
          output$heatmap = renderPlotly({
            p_heat = list()
            for(n in 1:length(input$date_4)){
              if(n==1){
                plot_heat = delay_info[[paste(input$line_4,input$date_4[n])]]
              }else{
                plot_heat = rbind(plot_heat,delay_info[[paste(input$line_4,input$date_4[n])]])
              }
            }
            colnames(plot_heat) = c("course","DatedVehicleJourneyRef","StopName","Order","Time","delay","distance","cum_distance","cancellations")
            plot_heat$Time = as.POSIXct(strftime(plot_heat$Time, format="%H:%M:%S"),format="%H:%M:%S")
            # plot_heat$Time = strftime(plot_heat$Time, format="%H:%M:%S")
            plot_heat = plot_heat[order(plot_heat$Time),]
            plot_heat$Time = as.character(plot_heat$Time)
            plot_heat$course = as.numeric(plot_heat$course)
            
            for(j in sort(unique(plot_heat$course))){
              plot_heat1 = plot_heat[which(plot_heat$course==j),]
              heat_matrix = matrix(NA,1,length(unique(plot_heat1$Time)))
              colnames(heat_matrix) = unique(plot_heat1$Time)
              
              if(nrow(plot_heat1)>0){
                for(i in 1:nrow(plot_heat1)){
                  heat_matrix[1,plot_heat1$Time[i]] = plot_heat1$delay[i]
                }
                
                p_heat[[length(p_heat)+1]] = plot_ly(x = unique(plot_heat1$Time), y=paste0("Service ",j), z = heat_matrix, type="heatmap",
                                                     colors = colorRamp(c("green", "red")), zmin = 0, zmax = 300,
                                                     showscale = F)
              }
            }
            
            subplot(p_heat, nrows = length(p_heat), shareX = T) %>%
              layout(margin = list(t=65, pad=0), title = "\nDelay heatmap")
          })
          
          
          # output$selection2 <- DT::renderDataTable({
          #   g <- event_data("plotly_hover")
          #   if (length(g) == 0) {
          #   }else{
          #    g = as.list(g)
          #    data.frame(g)
          #   }
          # })
          
        })
      })
      
      
      observeEvent(input$line_5,{
        observeEvent(input$date_5,{
          x = input$line_5
          z = input$date_5
          
          observeEvent(input$selected_minutes,{
            
            min_selection = as.numeric(input$selected_minutes)
            for(n in 1:length(input$date_5)){
              if(n==1){
                reg_selection1 = headway_list[[paste(x,z[n])]]
              }else{
                reg_selection1 = rbind(reg_selection1,headway_list[[paste(x,z[n])]])
              }
            }
            
            output$stop_reg <- renderUI({
              stops = stops_line[[input$line_5]]$StopName
              selectInput(inputId = "stop_reg",
                          label = "Select only one stop:", 
                          choices = stops,
                          selected = stops[1])
            })
            
            reg_selection2 = reg_selection1[which(reg_selection1$headway<=min_selection),]
            freq_times_reg = as.data.frame(table(reg_selection2$Time))
            
            if(nrow(freq_times_reg)>0){  # Para evitar el error en ese instante que pasamos de una fecha con una linea a otra fecha que no tiene esa linea
              colnames(freq_times_reg) = c("Time","Freq_reg")
              reg_selection1 = merge(reg_selection1, freq_times_reg, by = "Time", all = TRUE)
              regularity = reg_selection1[which(duplicated(reg_selection1$Time)==F),]
              regularity$Time = strftime(regularity$Time, format="%H:%M")
              regularity$headway[is.na(regularity$headway)] = 0
              regularity$Freq[is.na(regularity$Freq)] = 0
              # Si se han seleccionado varias fechas, hay que agregar los datos de cada una, ya que pueden compartir horas
              regularity = aggregate(regularity[,c(2,3,4)], by=list(Time=regularity$Time), FUN=sum)  
              regularity$reg = regularity$Freq_reg/regularity$Freq  # Calculamos el KPI regularidad
              regularity$reg[is.na(regularity$reg)] = 0
              
              output$plot6 = renderPlotly({
                plot_ly(regularity, x = ~Time, y = ~reg, type = "scatter", mode = "lines") %>%
                  layout(margin = list(t=65, pad=0), title = paste0("\nService regularity (vehicles separated by less than ",min_selection," minutes)"),
                         xaxis = list(title = "", range=c(min(regularity$Time),max(regularity$Time)), tickangle = 270),
                         yaxis = list(title = "Regularity", range=c(0,1)),
                         hovermode = "FALSE")
              })
              
              output$vehic2 <- renderText({
                g <- event_data("plotly_hover")
                if (length(g) == 0  | length(g) != 4) {
                  paste(("Number of vehicles that meet the condition: 0"),("Total number of vehicles running: 0"),sep="\n")
                }else{
                  g = as.list(g)
                  paste((paste0("Number of vehicles that meet the condition: ",
                                regularity$Freq_reg[which(regularity$Time==g[[3]])])),
                        (paste0("Total number of vehicles running: ",
                                regularity$Freq[which(regularity$Time==g[[3]])])),sep="\n")
                }
              })
            }
          })
          
          
          observeEvent(input$stop_reg,{
            for(n in 1:length(input$date_5)){
              if(n==1){
                headway_stop = headway_info[[paste(x,z[n])]]
              }else{
                headway_stop = rbind(headway_stop,headway_info[[paste(x,z[n])]])
              }
            }
            headway_stop = headway_stop[headway_stop$Order==headway_stop$vehicle_stop,]
            headway_stop = headway_stop[-which(duplicated(headway_stop[,2:5])==TRUE),]
            
            x3 <- list(title = "Headway time (Seconds)")
            y3 <- list(title = "Number of services")
            output$plot7 = renderPlotly({
              plot_ly(x = headway_stop$headway[which(headway_stop$StopName == input$stop_reg)],type = "histogram") %>%
                layout(margin = list(t=65, pad=0), title = paste0("\nDistribution of headway time for stop ",input$stop_reg),xaxis = x3, yaxis = y3, hovermode = "FALSE")
            })
            
            output$reg_selection <- DT::renderDataTable({
              c <- event_data("plotly_click")
              if (length(c) == 0 | class(c[,3]) == "character") {
              }else{
                c = as.list(c)
                aux = which(headway_stop$StopName == input$stop_reg)
                headway_stop2 = headway_stop[aux,]
                indexes = c(sort(abs(headway_stop2$headway - c[[3]]),index.return=T)$ix[1:c[[4]]])
                headway_stop2[indexes,c("DatedVehicleJourneyRef","Time","headway")]
              }
            }, options = list(pageLength = 10), rownames=F)
            
          })
          
        })
      })
      
      
      observeEvent(input$line_6,{
        observeEvent(input$date_6,{
          x = input$line_6
          z = input$date_6

          if(!is.null(distance[[paste(x,z)]])){  # Para evitar el error en ese instante que pasamos de una fecha con una linea a otra fecha que no tiene esa linea
            reliability = distance[[paste(x,z)]]
            reliability$kpi = reliability$cum_distance / reliability$cancellations
            reliability$kpi[which(is.nan(reliability$kpi) | reliability$kpi==Inf)] = 0
            reliability$Time = strftime(reliability$Time, format="%H:%M")
            
            output$plot8 = renderPlotly({
              plot_ly(reliability, x = ~Time, y = ~kpi, type = "scatter", mode = "lines") %>%
                layout(margin = list(t=65, pad=0), title = "Service reliability (revenue distance per cancellation)",
                       xaxis = list(title = "", range=c(min(reliability$Time),max(reliability$Time)), tickangle = 270),
                       yaxis = list(title = "Distance per cancellation (m)"),
                       hovermode = "FALSE")
            })
  
            output$plot9 = renderPlotly({
              plot_ly(reliability, x = ~cum_distance, y = ~cancellations, type = "scatter", mode = "lines") %>%
                layout(margin = list(t=65, pad=0), title = "",
                       xaxis = list(title = "Revenue distance (m)", range=c(min(reliability$cum_distance),max(reliability$cum_distance))),
                       yaxis = list(title = "Number of cancellations"),
                       hovermode = "FALSE")
            })
            
            cancellations = cancel_info[[paste(x,z)]]
            colnames(cancellations) = c("Time","Direction","Vehicle","State")
            
            output$cancel_table <- DT::renderDataTable({
              cancellations
            }, options = list(pageLength = 10), rownames=F)
        }
          

        })
      })
      
      
    }
  })
  
})

runApp(list(ui = ui, server = server), launch.browser=TRUE)
