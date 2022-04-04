# Potrzebne biblioteki

library(shiny) 
library(shinyWidgets) 
library(shinydashboard) 
library(shinyBS) 
library(shinyjs)
library(shinythemes)
library(data.table)
library(DT)
library(reticulate)
library(httr)


# Biblioteki pythonowe, które są potrzebne, aby działał plik .py

# py_install("sklearn", pip = TRUE)
# py_install("matplotlib")
# py_install("scipy")
# py_install("numpy")
# py_install("pandas")
# py_install("seaborn")


# Wczytanie potrzebnych funkcji

source_python('python_files/recommendations_function.py')


# Przygotowanie globalnej zmiennej do filtru filmów

data_1 <- data["movieID"]
data_2 <- movies[c('movieID', 'title')]
data_1 <- merge(data_1, data_2, by = "movieID", all.x = TRUE)

MOVIES_NAME <- data_1['title']
setorder(MOVIES_NAME)
colnames(MOVIES_NAME) <- 'Title'
MOVIES_NAME <<- MOVIES_NAME
