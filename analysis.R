# Wczytanie potrzebnych plików z danymi i połączenie ich w jedną tabelę

movies <- fread("data/movies.csv")
links <- fread("data/links.csv")
movies <- merge(movies, links, by = "movieId", all.x = TRUE)

# Usunięcie niepotrzebnych kolumn i edycja tych istotnych

movies[, tmdbId := NULL]
movies[, movieId := as.character(movieId)]
movies[, imdbId := as.character(imdbId)]
movies[, imdbId := fifelse(nchar(imdbId) == 7, sub("^", "tt", imdbId),
                           fifelse(nchar(imdbId) == 6, sub("^", "tt0", imdbId),
                                   fifelse(nchar(imdbId) == 5, sub("^", "tt00", imdbId), 
                                           fifelse(nchar(imdbId) == 4, sub("^", "tt000", imdbId), 
                                                   fifelse(nchar(imdbId) == 3, sub("^", "tt0000", imdbId),
                                                           fifelse(nchar(imdbId) == 2, sub("^", "tt00000", imdbId),
                                                                   fifelse(nchar(imdbId) == 1, sub("^", "tt000000", imdbId),
                                                                           as.character(0)))))))), .(imdbId)]

colnames(movies) <- c("movieID", "title", "genres", "imdbID")

# Wczytanie pliku danych z ocenami użytkowników  i jego edytowanie

ratings <- fread("data/ratings.csv")
ratings[, timestamp := NULL]
colnames(ratings) <- c("userID", "movieID", "rating")

# Etap łączenia danych z API do tabeli movies z danymi filmowymi

# Pobranie odpowiednich danych z API i zapisanie w formie pliku csv

if (file.exists("data/rapidapi.csv") == TRUE) {
  print("Dane z API wczytane")
  rapidapi <- fread("data/rapidapi.csv")
} else {
  print("Muszą zostać pobrane dane z API")
  
  rapidapi <- data.frame(matrix(ncol = 8, nrow = nrow(movies)))
  colnames(rapidapi) <- c("imdbID", "Plot", "Poster", "Description", "Movie_length", 
                          "Rating", "Release", "Trailer")
  movie_list <- c(movies$imdbID)
  
  for (i in 1:length(movie_list)) {
    url <- sprintf("https://data-imdb1.p.rapidapi.com/movie/id/%s/",
                   movie_list[i])
    
    response <- VERB("GET", url, add_headers(
      'rapidapi-host' = 'data-imdb1.p.rapidapi.com',
      'rapidapi-key' = 'd29ee17a3dmshacf1dad96b6fa27p150b6cjsn8d3f05896ed6'),
      content_type("application/octet-stream"))
    
    x <- httr::content(response, "parsed")
    if (length(x$results$plot) == 0 | length(x$results$banner) == 0
        | length(x$results$description) == 0 |length(x$results$movie_length) == 0 
        | length(x$results$rating) == 0 | length(x$results$release) == 0
        | length(x$results$trailer) == 0){
      x$results$plot <- NA
      x$results$banner <- NA
      x$results$description <- NA
      x$results$movie_length <- NA
      x$results$rating <- NA
      x$results$release <- NA
      x$results$trailer <- NA
    }
    
    rapidapi[i, 1] <- movie_list[i]
    rapidapi[i, 2] <- x$results$plot
    rapidapi[i, 3] <- x$results$banner
    rapidapi[i, 4] <- x$results$description
    rapidapi[i, 5] <- x$results$movie_length
    rapidapi[i, 6] <- x$results$rating
    rapidapi[i, 7] <- x$results$release
    rapidapi[i, 8] <- x$results$trailer
  }
  
  fwrite(rapidapi, "data/rapidapi.csv")
  rapidapi <- fread("data/rapidapi.csv")
}

# Połączenie danych z pliku movies.csv i danych z API i zapisanie ich do pliku movies_info

if (file.exists("data/movies_info.csv") == TRUE) {
  print("Informacje o filmach zostały wczytane")
  movies_info <- fread("data/movies_info.csv")
} else {
  print("Musiał zostać utworzony plik z danymi o filmach")

  movies$imdbID <- as.character(movies$imdbID)
  rapidapi$imdbID <- as.character(rapidapi$imdbID)
  movies_info <- merge(movies, rapidapi, by = "imdbID", all.x = TRUE)

  movies_info[, 'Ad' := paste("<div class = 'img-details' title = 'movie poster'
       onclick = 'Shiny.setInputValue(\"choosen_id\", ", imdbID, ");
                  Shiny.setInputValue(\"modal\", Math.random());'>
      <img src = ", Poster, " width = '200px' height = '200px'>
      </div>", sep = "")]

  movies_info <- subset(movies_info, select = c(imdbID, movieID, title, genres, Release, 
                                                Movie_length, Rating, Plot, Description, 
                                                Ad, Trailer, Poster))
  colnames(movies_info) <- c("imdbID", "movieID", "Title", "Genres", "Release", 
                             "Movie_length", "Rating", "Plot", "Description", 
                             "Poster", "Trailer", "Poster_link")

  fwrite(movies_info, "data/movies_info.csv")
  movies_info <- fread("data/movies_info.csv")
}
