#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# install.packages("rsconnect")
library(shiny)
library(shinyWidgets)
source("./Scrape_Engine.R")
library(data.table)

histo_pelis <- read.csv("./data/datos_peli.csv", stringsAsFactors = F)
histo_pelis$X <- NULL
histo_pelis <- as.data.table(histo_pelis)
setkey(histo_pelis,"Title")

histo_busquedas <- read.csv("./data/histo_busquedas.csv", stringsAsFactors = F)
histo_busquedas$X <- NULL
histo_busquedas <- as.data.table(histo_busquedas)
setkey(histo_busquedas,"Search")

# Define UI for application that draws a histogram
ui <- fluidPage(
   tags$div( #style = "width: 100%,",
     tags$img(
       style= "display: block;
               margin-left: auto;
               margin-right: auto;
              # width: 40%;
       ",
       src = "logo.png")
     ),
   # Application title
   titlePanel("¿Qué peli quieres ver esta noche?"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        searchInput(
          inputId = "search", label = "Pon una peli",
          placeholder = "Search",
          btnSearch = icon("search"),
          btnReset = icon("remove"),
          width = "500px"
        )
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         # plotOutput("distPlot")
        # textOutput("Title")
        # ,
        # textOutput("Rating")
        # ,
        # htmlOutput("Título")
        uiOutput("Poster")
      )
   )
)



# Define server logic required to draw a histogram
server <- function(input, output) {
  # df_peli <- main_scraper({input$search})
  # 
  # df_peli <- reactive({
  #   
  #     # {input$search}
  #     input$search
  #     # ...but not for anything else
  #     isolate({
  #       withProgress({
  #         setProgress(message = "Gathering tweets...")
  #         main_scraper({input$search})
  #       })
  #     })
  # })
  # src <- reactive({ 
  #   search_query
  #   
  #   withpr
  #   })
     output$Poster <- renderUI({
       search_query <- {input$search}
       
       search_query <- histo_busquedas[search_query,][["Result"]]
       if(is.na(search_query)) search_query <- {input$search}
       
       df_peli <- histo_pelis[search_query,]
       
       cat(paste0("Buscando: ", search_query, "\n"))
       
       if(nchar(search_query) > 1){ 
         cat("\nEmpezando proceso de scraping")
         df_peli <- main_scraper(search_query)
         src <- df_peli[["Poster"]][1]
         df_peli <- as.data.table(df_peli)
         if(!is.na(df_peli$Rating_FA)){ 
           histo_pelis <- rbind(histo_pelis, df_peli)
           write.csv(histo_pelis,"./data/datos_peli.csv")

           histo_busquedas <- rbind(histo_busquedas,
                                    data.table("Search" = search_query, "Result"=df_peli$Title[1])
                                    )
           write.csv(histo_busquedas,"./data/histo_busquedas.csv")
           }
       

       # <div style="width: 340px;allign: center;background-color:#c1c1e1;float:left">
       #   <div  style="background-color:lightblue; width: 100%;height: 15px; allign:center;float:left;padding=40px">
       #   </div>
       #   <div  style="background-color:lightblue; width: 5%;height: 240px; allign:center;float:left;padding=40px">
       #   </div>
       #   <div  style="background-color:lightblue; width: 45%;height: 240px; allign:center;float:left;padding=40px">
       #   <img src = "https://pics.filmaffinity.com/shrek-903764423-msmall.jpg"> </img>
       #   </div>
       #   <div  style="background-color:lightblue; width: 5%;height: 240px; allign:center;float:left;padding=40px">
       #   </div>
       #   <div  style="background-color:lightblue; width: 45%;height: 120px; allign:center;float:left;padding=40px">
       #   <h1>
       #   Aladdin
       # </h1>
       #   </div>
       #   <div  style="background-color:lightblue; width: 45%;height: 120px; allign:center;float:left;padding=40px">
       #   <h3>
       #   (1992)
       # </h3>
       #   </div>
       #   </div>
       tags$div( 
         style = "width: 340px;allign: center;background-color:##f5f5f5;float:left",
         tags$div(style = "background-color:#f5f5f5; width: 100%;height: 15px; allign:center;float:left;padding=40px"),
         tags$div(style = "background-color:#f5f5f5; width: 5%;height: 240px; allign:center;float:left;padding=40px"),
         tags$div(style="background-color:#f5f5f5; width: 45%;height: 240px; allign:center;float:left;padding=40px",
            tags$img(src = df_peli[["Poster"]][1])
         ),
         tags$div(style = "background-color:#f5f5f5; width: 5%;height: 240px; allign:center;float:left;padding=40px"),
         tags$div(style="background-color:#f5f5f5; width: 45%;height: 120px; allign:center;float:left;padding=40px",
           tags$h2(df_peli[["Title"]][1]),
           tags$h4(df_peli[["Year"]][1])
           ),
         tags$div(style="background-color:#f5f5f5; width: 45%;height: 120px; allign:center;float:left;padding=40px",
                  tags$h5(paste0(df_peli[["Rating_FA"]][1],"/10 (Film Affinity)")),
                  tags$h5(paste0(df_peli[["Rating_IMDB"]][1],"/10 (IMDB)"))
         )
       )
       
     # }
       }
     }
  )
     output$Title <- renderText(
       {
         search_query <- {input$search}
         search_query <- histo_busquedas[search_query,][["Result"]]
         if(is.na(search_query)) search_query <- {input$search}
         
         histo_pelis[search_query,][["Title"]]
         # search_query <- {input$search}
         # 
         # histo_pelis <- read.csv("./data/datos_peli.csv", stringsAsFactors = F)
         # 
         # if(length(intersect(histo_pelis[["Title"]],search_query)) > 0) 
         #   df_peli <- subset(histo_pelis, histo_pelis[["Title"]] == search_query)
         # else{
         #   df_peli <- main_scraper(search_query)
         #   histo_pelis <- rbind(histo_pelis,df_peli)
         #   write.csv(df_peli,"./data/datos_peli.csv")
         # }
         # df_peli[["Title"]]
       })
     output$Rating <- renderText(
       {
         search_query <- {input$search}
         search_query <- histo_busquedas[search_query,][["Result"]]
         if(is.na(search_query)) search_query <- {input$search}
         
         cat(paste(histo_pelis[search_query,], collapse= " - "))
         if(nchar(search_query) > 1)
           out_str <- paste0("Rating: ",histo_pelis[search_query,][["Rating_FA"]],"/10")
         else 
           search_query
         # search_query <- {input$search}
         # 
         # histo_pelis <- read.csv("./data/datos_peli.csv", stringsAsFactors = F)
         # 
         # if(length(intersect(histo_pelis[["Title"]],search_query)) > 0) 
         #   df_peli <- subset(histo_pelis, histo_pelis[["Title"]] == search_query)
         # else{
         #   df_peli <- main_scraper(search_query)
         #   histo_pelis <- rbind(histo_pelis,df_peli)
         #   write.csv(df_peli,"./data/datos_peli.csv")
         # }
         # df_peli[["Title"]]
       })
}

# Run the application 
shinyApp(ui = ui, server = server)

