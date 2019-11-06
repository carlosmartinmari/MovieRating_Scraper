# install.packages("httr")

library(httr)
library(XML)
library(jsonlite)
library(rvest)
library(stringr)

##wordcloud de comentarios
library(tm)
library(wordcloud)
library(RColorBrewer)

main_scraper <- function(search_query = "aladdin", year = 1992){
  if(class(year) != "character" ) year <- as.character(year)
  
  # cat(paste0("Buscando: ", search_query, "con longitud ", length(search_query)))
  
  if(nchar(search_query) < 2 || is.na(search_query) || is.null(search_query)) {
    # cat("\ncontrol1")
    return(NULL)
  }
  search_query_FA <- gsub(" ", "+", search_query)
  cat(paste0("\nBuscando: ", search_query))
  
  
  # cat("Scrapeando FilmAffinity\n")
  df_FA_movie<- getFilmAffinityMovie(search_query_FA)
  # df_FA_movie_filtered <- subset(df_FA_movie,df_FA_movie$Year == "1992")
  df_FA_movie_filtered <- df_FA_movie[order(df_FA_movie$Rating_FA, decreasing = T)[1],]
  
  # nosquedamoslastresprimerasporsimplicidad
  
  # %20
  search_query <- gsub(" ", "%20", search_query)
  # cat("Scrapeando IMDB\n")
  df_imdb_movie <- getIMDBMovie(search_query = search_query)
  # df_imdb_movie <- subset(df_imdb_movie,df_imdb_movie[["Year_IMDB"]] == year)
  df_imdb_movie <- df_imdb_movie[order(df_imdb_movie[["Rating_IMDB"]], decreasing = T)[1],]
  
  df_FA_movie_filtered[["Rating_FA"]] <- df_FA_movie_filtered[["Rating_FA"]]
  # cat("Scraping realizado\n")
  output_df <- df_FA_movie_filtered
  
  output_df[["Rating_IMDB"]] <- df_imdb_movie[["Rating_IMDB"]]
  output_df[["URL_IMDB"]] <- df_imdb_movie[["URL_IMDB"]]
  
  # cat(output_df[["Title"]])
  # cat("\n")  
  # cat(output_df[["Year"]])
  # cat("\n")  
  # # cat(output_df[["Rating_FA"]])
  # cat("\n")
  
  return(output_df)
}


getIMDBMovie <- function(search_query = "aladdin", lim_movies = 5){
  search_query <- gsub(" ", "%20", search_query)
  lim_movies_seq <- seq(lim_movies)
  imdb_url_base <- c("https://www.imdb.com/find?q=",search_query,"&s=tt&ref_=fn_al_tt_mr")
  
  imdb_search <- GET(paste(imdb_url_base, collapse = ""))  
  content_html <- htmlParse(imdb_search)
  
  title_imdb <- trimws(unlist(xpathApply(content_html,
                                         "//td[@class='result_text']//a",
                                         xmlValue)))
  urls_imdb <- unname(sapply(xpathApply(content_html, "//td[@class='result_text']//a", xmlAttrs), "[", "href"))
  urls_imdb <- paste0("https://www.imdb.com",urls_imdb)
  # title_imdb <- title_imdb[nchar(title_imdb) > 1]
  year_imdb <- trimws(unlist(xpathApply(content_html,
                                         "//td[@class='result_text']",
                                         xmlValue)))
 
   # year_imdb < year_imdb[nchar(year_imdb) > 1]
  tv_series <- grepl("(TV Series)",year_imdb)
  tv_movie <- grepl("(TV Movie)",year_imdb)
  Video <- grepl("(Video)",year_imdb)
  Video_game <- grepl("(Video Game)",year_imdb)
  
  for(j in seq(length(year_imdb))){
    year_imdb[j] <-gsub(title_imdb[j],"",year_imdb[j])
    year_imdb[j] <- str_extract(year_imdb[j],"([0-9]+)")
  }
  
  if(length(year_imdb) < lim_movies) lim_movies <- length(year_imdb)
  
  rating_imdb <- getRatingIMDB(urls_imdb[1])
  for(j in 2:max(lim_movies_seq) ){
    if(j > lim_movies)
      {
      # cat(j)
      break
    } 
    rating_imdb <- c(rating_imdb,getRatingIMDB(urls_imdb[j]))
  }
  
  data.frame("Title_IMDB" = title_imdb[lim_movies_seq], "Year_IMDB" = year_imdb[lim_movies_seq],
             "Rating_IMDB" = rating_imdb[lim_movies_seq], "URL_IMDB" = urls_imdb[lim_movies_seq],
             stringsAsFactors=FALSE)
}

getRatingIMDB <- function(imdb_url){
  
  imdb_url_Get <- GET(imdb_url)
  imdb_url_html <- htmlParse(imdb_url_Get)
  
  rating_imdb <- trimws(unlist(xpathApply(imdb_url_html,
                                        "//span[@itemprop='ratingValue']",
                                        xmlValue)))
  
  return(rating_imdb)
}
  
getFilmAffinityMovie <- function(search_query = "aladdin"){
  ### cuando las películas sólo tienen un resultado, el otro enlace puede dar problemas
  
  url_base <- "https://www.filmaffinity.com/es/advsearch.php?stext="
  
  FA_search <- GET(paste0(url_base, search_query))   
  
  content_html <- htmlParse(FA_search, encoding = "utf-8")
  
  title_movie_FA <- trimws(unlist(xpathApply(content_html, "//div[contains(@class,'mc-title')]//a", xmlValue)))
  urls_movie_FA <- unname(sapply(xpathApply(content_html, "//div[contains(@class,'mc-title')]//a", xmlAttrs), "[", "href"))
  poster_movie_FA <- unname(sapply(xpathApply(content_html, "//div[contains(@class,'mc-poster')]//a//img", xmlAttrs), "[", "src"))
  
  year_movie_FA <- unlist(xpathApply(content_html, "//div[contains(@class,'mc-title')]", xmlValue))
  #extraemos de ahí el año y quitamos paréntesis
  year_movie_FA <-  str_extract(year_movie_FA,"(\\([0-9]{4}\\))")
  year_movie_FA <- str_extract("blade runner 2010 (2015)","([0-9]{4})+")
  
  rating_movie_FA <- unlist(xpathApply(content_html, "//div[contains(@class,'avgrat-box')]", xmlValue))
  rating_movie_FA[rating_movie_FA == "--"] <- NA
  rating_movie_FA <- as.numeric(sub(",",".", rating_movie_FA))
  
  
  list_of_movies_FA <- data.frame("Title" = title_movie_FA,"Rating_FA" = rating_movie_FA, 
                                  "Year" = year_movie_FA, "Poster" = poster_movie_FA, 
                                  "Url" = urls_movie_FA,stringsAsFactors=FALSE)
  
  return(list_of_movies_FA)
}

getFilmAffinityMovie_old <- function(search_query = "aladdin"){
  url_base <- "https://www.filmaffinity.com/es/search.php?stype=title&stext="
  # search_query <- "aladdin"
  
  FA_search <- GET(paste0(url_base, search_query))            
  
  # content(test)
  # 
  # contenido <- read_html(test)
  # 
  # 
  # contenido <- read_html(test)
  # 
  # html_nodes(contenido,"a")
  
  content_html <- htmlParse(FA_search)
  #a[contains(@class,'user')]
  urls_movie_FA <- unname(sapply(xpathApply(content_html, "//div[contains(@class,'mc-title')]//a", xmlAttrs), "[", "href"))
  poster_movie_FA <- unname(sapply(xpathApply(content_html, "//div[contains(@class,'mc-poster')]//a//img", xmlAttrs), "[", "src"))
  title_movie_FA <- trimws(unlist(xpathApply(content_html, "//div[contains(@class,'mc-title')]//a", xmlValue)))
  
  year_movie_FA <- unlist(xpathApply(content_html, "//div[contains(@class,'ye-w')]", xmlValue))
  rating_movie_FA <- unlist(xpathApply(content_html, "//div[contains(@class,'avgrat-box')]", xmlValue))
  rating_movie_FA[rating_movie_FA == "--"] <- NA
  rating_movie_FA <- as.numeric(sub(",",".", rating_movie_FA))
  # rating_movie_FA <- tryCatch(as.numeric(sub(",", ".", rating_movie_FA, fixed = TRUE)), error=function(e) {return(NULL)}, warning = function(w) {})
  
  list_of_movies_FA <- data.frame("Title" = title_movie_FA,"Rating_FA" = rating_movie_FA, 
                                  "Year" = year_movie_FA, "Poster" = poster_movie_FA, 
                                  "Url" = urls_movie_FA,stringsAsFactors=FALSE)
  
  return(list_of_movies_FA)
}

getFAMovieDetails <- function(film_url){
  # film_url <- "https://www.filmaffinity.com/es/film800220.html"
  
  FA_movie_details <- GET(film_url)
  mv_dets_html <- htmlParse(FA_movie_details)
  #//dl[@class='movie-info']//dd[1]
  originaltitle_movie_FA <- unlist(xpathApply(mv_dets_html, "//dl[@class='movie-info']//dd[1]", xmlValue))
  originaltitle_movie_FA <- trimws(gsub("\n","",originaltitle_movie_FA))
  duration_movie_FA <- unlist(xpathApply(mv_dets_html, "//dd[contains(@itemprop,'duration')]", xmlValue))
  sinopsis_movie_FA <- unlist(xpathApply(mv_dets_html, "//dd[contains(@itemprop,'description')]", xmlValue))
  
  pro_reviews_FA <- unlist(xpathApply(mv_dets_html, "//div[contains(@itemprop,'reviewBody')]", xmlValue))
  
  link_people_reviews_FA <- unname(sapply(xpathApply(mv_dets_html, "//div[contains(@id,'movie-reviews-box')]//a[1]", xmlAttrs), "[", "href"))
}
  
getPeopleReviews_FA <- function(film_url){
  #review-text1
  #user-reviews-movie-rating
  FA_movie_details <- GET(film_url)
  mv_dets_html <- htmlParse(FA_movie_details)
  link_people_reviews_FA <- unname(sapply(xpathApply(mv_dets_html, "//div[contains(@id,'movie-reviews-box')]//a[1]", xmlAttrs), "[", "href"))
  
  
  # reviews_url <- "https://www.filmaffinity.com/es/reviews/1/800220.html"
  FA_reviews_details <- GET(link_people_reviews_FA)
  mv_reviews_html <- htmlParse(FA_reviews_details, encoding = "utf-8")
    
  review_rating_FA <- unlist(xpathApply(mv_reviews_html, "//div[@class='user-reviews-movie-rating']", xmlValue))
  review_rating_FA <- trimws(gsub("\n","",gsub("\r","",review_rating_FA)))
  rev_text_FA <- unlist(xpathApply(mv_reviews_html, "//div[@class='review-text1']", xmlValue))
  
  ## mejoras: incluir el paginado -> //div[@class='pager'][1]//a
  
  return(data.frame("Rating" = review_rating_FA, "Detalle" = rev_text_FA,stringsAsFactors=FALSE))
}


#### wordcloud


getWordcloud <- function(vectorofwords){
  vectorofwords <- iconv(vectorofwords, from="UTF-8",to = "ASCII//TRANSLIT")
  
  mycorpus <- Corpus(VectorSource(vectorofwords))
  
  mycorpus<-tm_map(mycorpus,removePunctuation)
  mycorpus<-tm_map(mycorpus,stripWhitespace)
  
  mycorpus<-tm_map(mycorpus,tolower)
  
  mycorpus<-tm_map(mycorpus,removeNumbers)
  
  ownstopwords <- c("mas","ser","tan","vez","ademas","aun","ver","pelicula","peliculas",
                    "pues","cine","crea","filme","film","hoy","aqui","tal","serie","series",
                    "tambien","solo")
  
  mycorpus<-tm_map(mycorpus,removeWords, c(stopwords("spanish"),ownstopwords))
  
  # tdm_wc<-TermDocumentMatrix (mycorpus) #Creates a TDM
  # 
  # tdm_wc_matrix <-as.matrix(tdm_wc) #Convert this into a matrix format
  # 
  # v <- sort(rowSums(tdm_wc_matrix), decreasing = TRUE) #Gives you the frequencies for every word
  # 
  # df_freqs <- data.frame("word" = names(v), "freq" = v)
  # 
  return(mycorpus)
  # wordcloud2(df_freqs, size=1.6,backgroundColor="#f5f5f5")
  # Summary(v)
  # wordcloud (mycorpus, scale=c(5,0.5), max.words=20, random.order=FALSE, rot.per=0.35, use.r.layout=FALSE, colors=brewer.pal(8, "Dark2"))
}

