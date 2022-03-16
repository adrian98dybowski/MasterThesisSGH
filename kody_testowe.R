library(reticulate)
source_python('python_files/recommendations_function.py')
df <- create_recommendations("Braveheart (1995)")
#df <- df[rev(rownames(df)),]
df$Position <- 1:10
df <- subset(df, select = c(Position, imdbID, Title, Distance))
df$imdbID

output_rapidapi <- data.frame(matrix(ncol = 3, nrow = 10))
colnames(output_rapidapi) <- c("imdbID", "Plot", "Poster")
library(httr)

kod <- c(df$imdbID)

for (i in 1:length(kod)) {
  
url <- sprintf("https://imdb-internet-movie-database-unofficial.p.rapidapi.com/film/%s", kod[i])

response <- VERB("GET", url, add_headers('rapidapi-host' = 'imdb-internet-movie-database-unofficial.p.rapidapi.com', 'rapidapi-key' = 'a14d8ff0a5msh03678641c7a531fp124ed5jsnb2337e7b2a4f'), content_type("application/octet-stream"))

x <- content(response, "parsed")
output_rapidapi[i, 1] <- x$id
output_rapidapi[i, 2] <- x$plot
output_rapidapi[i, 3] <- x$poster
}
output_rapidapi

df <- merge(df, output_rapidapi, by = "imdbID", all.x = TRUE)
setorder(df, Position)


# DRUGIE API

df <- create_recommendations("Lion King, The (1994)")
df <- df[rev(rownames(df)),]
df$Position <- 1:10
setDT(df)

rapidapi <- data.frame(matrix(ncol = 3, nrow = 10))
colnames(rapidapi) <- c("imdbID", "Plot", "Poster")
movie_list <- c(df$imdbID)


for (i in 1:length(movie_list)) {
  url <- sprintf("https://data-imdb1.p.rapidapi.com/movie/id/%s/",
                 movie_list[i])
  
  response <- VERB("GET", url, add_headers(
    'rapidapi-host' = 'data-imdb1.p.rapidapi.com', 
    'rapidapi-key' = 'd29ee17a3dmshacf1dad96b6fa27p150b6cjsn8d3f05896ed6'), 
    content_type("application/octet-stream"))
  
  x <- content(response, "parsed")
  rapidapi[i, 1] <- movie_list[i]
  rapidapi[i, 2] <- x$results$plot
  rapidapi[i, 3] <- x$results$banner
}

rapidapi
movie_list
rapidapi$imdbID


# for (i in 1:length(movie_list)) {
#   url <- sprintf("https://data-imdb1.p.rapidapi.com/movie/id/%s/",
#                  movie_list[i])
# 
#   response <- VERB("GET", url, add_headers(
#   'rapidapi-host' = 'data-imdb1.p.rapidapi.com',
#   'rapidapi-key' = 'd29ee17a3dmshacf1dad96b6fa27p150b6cjsn8d3f05896ed6'),
#   content_type("application/octet-stream"))
# 
#   x <- content(response, "parsed")
#   rapidapi[i, 1] <- movie_list[i]
#   rapidapi[i, 2] <- x$results$plot
#   rapidapi[i, 3] <- x$results$banner
# }

for (i in 1:length(movie_list)) {
  url <- sprintf(
    "https://imdb-internet-movie-database-unofficial.p.rapidapi.com/film/%s",
    movie_list[i])
  
  response <- VERB("GET", url, add_headers(
    'rapidapi-host' = 'imdb-internet-movie-database-unofficial.p.rapidapi.com',
    'rapidapi-key' = 'a14d8ff0a5msh03678641c7a531fp124ed5jsnb2337e7b2a4f'),
    content_type("application/octet-stream"))
  
  x <- content(response, "parsed")
  rapidapi[i, 1] <- x$id
  rapidapi[i, 2] <- x$plot
  rapidapi[i, 3] <- x$poster
}



df <- create_recommendations("Lion King, The (1994)")
df <- df[rev(rownames(df)),]
df$Position <- 1:10
setDT(df)

# Pobranie danych z api internetowego
rapidapi <- data.frame(matrix(ncol = 3, nrow = 10))
colnames(rapidapi) <- c("imdbID", "Plot", "Poster")
movie_list <- c(df$imdbID)

for (i in 1:length(movie_list)) {
  url <- sprintf("https://data-imdb1.p.rapidapi.com/movie/id/%s/",
                 movie_list[i])
  
  response <- VERB("GET", url, add_headers(
    'rapidapi-host' = 'data-imdb1.p.rapidapi.com',
    'rapidapi-key' = 'd29ee17a3dmshacf1dad96b6fa27p150b6cjsn8d3f05896ed6'),
    content_type("application/octet-stream"))
  
  x <- content(response, "parsed")
  if (length(x$results$plot) == 0 | length(x$results$banner) == 0){
    x$results$plot <- NA
    x$results$banner <- NA
  }
  rapidapi[i, 1] <- movie_list[i]
  rapidapi[i, 2] <- x$results$plot
  rapidapi[i, 3] <- x$results$banner
}
rapidapi
