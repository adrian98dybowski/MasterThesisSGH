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
