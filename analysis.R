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


# Analiza eksploracyjna danych

# summary(rapidapi)
# summary(movies_info)

# Zliczenie ocen dla każdego filmu, ocen każdego użytkownika i częstości każdej oceny w zbiorze

movie_votes <- ratings[, .(counts = .N), .(movieID)]
user_votes <- ratings[, .(counts = .N), .(userID)]

ratings_counts <- ratings[, .(counts = .N), .(rating)]
setorder(ratings_counts, rating)
ratings_counts[, sum := sum(counts)]
ratings_counts[, proportion := counts/sum]

# Sprawdzenie ile razy dany gatunek został przypisany do filmu

genres <- movies$genres
genres <- gsub('\\|', ' ', genres)
corpus <- Corpus(VectorSource(genres))
results <- term_stats(corpus, ngrams = 1)
results <- head(results, 19)

# Wykres kołowy z częstościami każdej unikalnej oceny

pie_chart <- ggplot(ratings_counts, aes(x = "", y = proportion, fill = as.character(rating)))+
  geom_bar(stat="identity", width=1, color="white") +
  coord_polar("y", start=0) +
  theme_void() +
  scale_fill_brewer(palette="Set3") +
  labs(fill = "Rating")

# Histogramy dotyczące ile ocen mają filmy

histogram_movie_votes_1 <- ggplot(movie_votes, aes(x = counts)) +
                           geom_histogram(fill = "blue", colour = "black", bins = 5) +
                           xlab("Numbers of ratings") +
                           ylab("Numbers of movies")+
                           theme_classic()

histogram_movie_votes_2 <- ggplot(movie_votes[counts < 50], aes(x = counts)) +
                           geom_histogram(fill = "red", colour = "black", bins = 5) +
                           xlab("Numbers of ratings") +
                           ylab("Numbers of movies")+
                           theme_classic()

histogram_movie_votes_3 <- ggplot(movie_votes[counts < 10], aes(x = counts)) +
                           geom_histogram(fill = "green", colour = "black", bins = 9) +
                           xlab("Numbers of ratings") +
                           ylab("Numbers of movies")+
                           theme_classic()

# Histogramy dotyczące ile ocen filmów ma każdy użytkownik

histogram_user_votes_1 <- ggplot(user_votes, aes(x = counts)) +
                          geom_histogram(fill = "blue", colour = "black", bins = 5) +
                          xlab("Numbers of ratings") +
                          ylab("Numbers of users")+
                          theme_classic()

histogram_user_votes_2 <- ggplot(user_votes[counts < 500], aes(x = counts)) +
                          geom_histogram(fill = "red", colour = "black", bins = 5) +
                          xlab("Numbers of ratings") +
                          ylab("Numbers of users")+
                          theme_classic()

histogram_user_votes_3 <- ggplot(user_votes[counts < 100], aes(x = counts)) +
                          geom_histogram(fill = "green", colour = "black", bins = 9) +
                          xlab("Numbers of ratings") +
                          ylab("Numbers of users")+
                          theme_classic()

# Wykres słupkowy dla gatunków filmów

bar_genres <- ggplot(results, aes(x = reorder(term, - count), y = count)) +
              geom_bar(stat="identity", fill = "blue")+
              xlab("Genre") +
              ylab("Numbers of occurence in movies")+
              theme_classic() +
              theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# Wykresy punktowe obrazujące oceny filmów i oceny użytowników

scatterplot_movies <- ggplot(movie_votes, aes(x = movieID, y = counts)) +
                      geom_point(colour = "green")+
                      xlab("Movie ID") +
                      ylab("Number of users votes on the movie")+
                      theme_classic() +
                      geom_hline(yintercept = 20, colour = "red")

scatterplot_users <- ggplot(user_votes, aes(x = userID, y = counts)) +
                     geom_point(colour = "orange")+
                     xlab("User ID") +
                     ylab("Number of user votes")+
                     theme_classic() +
                     geom_hline(yintercept = 20, colour = "blue")
