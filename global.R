# Potrzebne biblioteki

library(shiny) 
library(shinyWidgets) 
library(shinydashboard) 
library(shinyBS) 
library(shinyjs)
library(shinythemes)
library(data.table)
library(DT)
library(lsa)
library(class)
library(dplyr)
library(kableExtra)
library(httr)
library(stringr)
library(tm)
library(corpus)


# Biblioteki pythonowe, które są potrzebne, aby działał plik .py

# py_install("sklearn", pip = TRUE)
# py_install("matplotlib")
# py_install("scipy")
# py_install("numpy")
# py_install("pandas")
# py_install("seaborn")


# Wczytanie potrzebnych funkcji

#source_python('python_files/recommendations_function.py')
source("model.R")

# Wczytanie finalnego pliku z danymi filmowymi

if (file.exists("data/rapidapi.csv") == TRUE & file.exists("data/movies_info.csv") == TRUE) 
  {
    rapidapi <<- fread("data/rapidapi.csv")
    movies_info <<- fread("data/movies_info.csv")
  } else { 
    source("analysis.R")
  }

# Przygotowanie globalnej zmiennej do filtru filmów

data_1 <- pivot_data$movieID
data_1 <- data.frame(movieID = data_1)
data_2 <- movies[, c('movieID', 'title')]
data_1 <- merge(data_1, data_2, by = "movieID", all.x = TRUE)

MOVIES_NAME <- data_1['title']
setorder(MOVIES_NAME)
colnames(MOVIES_NAME) <- 'Title'
MOVIES_NAME <<- MOVIES_NAME

# Przygotowanie globalnej zmiennej do filtru gatunków filmów

genres <- movies$genres
genres <- gsub('\\|', ' ', genres)
corpus <- Corpus(VectorSource(genres))
results <- term_stats(corpus, ngrams = 1)
GENRES <- sort(head(results$term, 19))
GENRES <- str_to_title(GENRES)
GENRES <<- GENRES
