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
histo_pelis$Acty_Date <- as.Date(histo_pelis$Acty_Date)
setkey(histo_pelis,"Title")

histo_busquedas <- read.csv("./data/histo_busquedas.csv", stringsAsFactors = F)
histo_busquedas$X <- NULL
histo_busquedas <- as.data.table(histo_busquedas)
histo_busquedas$Acty_Date <- as.Date(histo_busquedas$Acty_Date)
setkey(histo_busquedas,"Search")

histo_reviews <- read.csv("./data/comentarios_peli.csv", stringsAsFactors = F)
histo_reviews$X <- NULL

# Define UI for application that draws a histogram
ui <- fluidPage(

  tags$head(tags$style(
    type="text/css",
    "#ReviewsWD img{
            width: 39em;
            display: block;
            margin-left: auto;
            margin-right: auto;
        }"
  ))
  ,
   # Application title
   titlePanel(
     # "¿Qué peli quieres ver esta noche?"
     tags$div( #style = "width: 100%,",
       tags$img(
         style= "display: block;
         margin-left: auto;
         margin-right: auto;
         # width: 40%;
         ",
         src = "logo.png")
     )
     ),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        searchInput(
          inputId = "search", label = "Busca el título de la película que quieras ver",
          placeholder = "Search",
          btnSearch = icon("search"),
          btnReset = icon("remove"),
          width = "500px"
        ),
        br(),
        br(),
        p("Plataforma programada 100% en R-Shiny por Carlos Martín."),
        p("Si quieres contactarme, agrégame a mi linkedin."),
        a(href="https://www.linkedin.com/in/carlos-mart%C3%ADn-mar%C3%AD-766ab827/",img(src = "linkedin_logo.png", 
              style= "height: 2em")),     
        br(),
        p("Revisa y colabora con el código original en github"),
        a(href="https://github.com/carlosmartinmari/MovieRating_Scraper",img(src = "github_logo.png", 
                                                                                        style= "height: 2em"))
        #ver codigo en github https://github.com/carlosmartinmari/MovieRating_Scraper
      ),
      
      mainPanel(
        tags$div( 
          style = "display:block;width: 550px;height:60em;allign: center;float:left;background-color:#f5f5f5;border:1px solid #e3e3e3;border-radius: 4px;border-shadow: inset 0 1px 1px rgba(0,0,0,.05)",
           tags$div(style = "display:block;width: 100%;height:25em;",
             uiOutput("Poster")
             )
            ,
          tags$div(style = "display:block;height:30em;",
            plotOutput("ReviewsWD", height="100%", width = "550px")
          )
        ) 
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
       if(nchar(search_query) > 1 ){ 
         search_query <- histo_busquedas[search_query,][["Result"]]
         if(is.na(search_query)) search_query <- {input$search}
         
         df_peli <- histo_pelis[search_query,][1,]
         
         cat(paste0("Buscando: ", search_query, "\n"))

         if( is.na(df_peli$Rating_FA) | (as.Date(df_peli$Acty_Date) - Sys.Date() )> 180 ){
           cat("\nEmpezando proceso de scraping")
           df_peli <- main_scraper(search_query)
           src <- df_peli[["Poster"]][1]
           df_peli <- as.data.table(df_peli)
           if(!is.na(df_peli$Rating_FA)){ 
             cat(paste0("\nSaving historic file \n"))
             df_peli$Acty_Date <- Sys.Date()
             histo_pelis <<- rbind(histo_pelis, df_peli)
             write.csv(histo_pelis,"./data/datos_peli.csv")
           }
         }

       
         histo_busquedas <<- rbind(histo_busquedas,
                                   data.table("Search" = search_query, "Result"=df_peli$Title[1],
                                              "Acty_Date" = Sys.Date()) )  
         cat(paste0("\nSaving activity file \n"))
         write.csv(histo_busquedas,"./data/histo_busquedas.csv")
         
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
         style = "width: 100%;allign: center;background-color:##f5f5f5;float:left",
         tags$div(style = "background-color:#f5f5f5; width: 100%;height: 1em; allign:center;float:left;padding=40px"),
         tags$div(style = "background-color:#f5f5f5; width: 5%;height: 20em; allign:center;float:left;padding=40px"),
         tags$div(style="background-color:#f5f5f5; width: 35%;height: 20em; allign:center;float:left;padding=40px",
            tags$img(style="height: 18em", src = gsub("small.jpg","med.jpg",df_peli[["Poster"]][1]))
         ),
         tags$div(style = "background-color:#f5f5f5; width: 5%;height: 20em; allign:center;float:left;padding=40px"),
         tags$div(style="background-color:#f5f5f5; width: 55%;height: 12em; allign:center;float:left;padding=40px",
           tags$h2(df_peli[["Title"]][1]),
           tags$h4(df_peli[["Year"]][1])
           ),
         tags$div(style="background-color:#f5f5f5; width: 55%;height: 8em; allign:center;float:left;padding=40px",
                  tags$h5(
                          tags$img(
                            style= "
                            width: 1.2em;
                            height: 1.2em
                            ",
                            src = "filmaffinity_logo.png"),
                          paste0(df_peli[["Rating_FA"]][1],"/10")
                          ),
                  tags$h5(
                          tags$img(
                            style= "
                            width: 1.2em;
                            height: 1.2em
                            ",
                            src = "imdb_logo.png"),
                          paste0(df_peli[["Rating_IMDB"]][1],"/10"))
         ),
         tags$div(style = "background-color:#f5f5f5; width: 100%;height: 1em; allign:center;float:left;padding=40px")
       )
      }
     }
  )
     
     output$ReviewsWD <- renderPlot({
       search_query <- {input$search}
       
       if(nchar(search_query) > 1){
         cat("Haciendo wordcloud\n")
         
         histo_busquedas <- as.data.table(histo_busquedas)
         setkey(histo_busquedas,"Search")  
         
         search_query <- histo_busquedas[search_query,][["Result"]][1]
         
         if(is.na(search_query)) return() #search_query <- {input$search}
         
         histo_pelis <- as.data.table(histo_pelis)
         setkey(histo_pelis,"Title")
         
         df_peli <- histo_pelis[search_query,][1,]
         
         cat(paste0("Leyendo reviews de: ", search_query," en ", df_peli[["Url"]]))
         
         reviews <- getPeopleReviews_FA(df_peli[["Url"]])
         
         reviews$inclusionDate <- Sys.Date()
         reviews$Title <-  df_peli[["Title"]]
         reviews$Url <- df_peli[["Url"]]
         
         histo_reviews <- rbind(reviews,histo_reviews)
         write.csv(reviews, "./data/comentarios_peli.csv")
         
         cat("\nHaciendo la nube de palabras")
         # wordcloud2(getWordcloud(reviews$Detalle)[1:20,], size=0.5,backgroundColor="#f5f5f5")
         # 
         wordcloud (getWordcloud(reviews$Detalle), scale=c(6,0.2), max.words=30, 
                    random.order=FALSE, rot.per=0.35, use.r.layout=FALSE, colors=brewer.pal(8, "Dark2"))
       }

       
     })
     
}

# Run the application 
shinyApp(ui = ui, server = server)

