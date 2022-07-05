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

pivot_data <- dcast(ratings, movieID~userID, fill = 0)

# Analiza eksploracyjna i usunięcie wartości odstających

movie_votes <- ratings[, (.N), .(movieID)]
user_votes <- ratings[, (.N), .(userID)]

movie_valid <- movie_votes[V1 >= 10]
movie_valid <- movie_valid[, V1 := NULL]
movie_valid_vector <- movie_valid$movieID

pivot_data <- pivot_data[movieID %in% movie_valid_vector]

# Przygotowanie danych do obliczenia metryki cosinusowej

data <- data.frame(pivot_data, row.names = 1, check.names = FALSE)
data <- t(as.matrix(data, byrow = TRUE))

# Obliczenie metryki cosinusowej. Jesli plik już istnieje w projekcie to zaczytywany jest 
# ten plik. Ograniczenie czasu wczytywania danych.

if (file.exists("data/cosine_metrics.rds") == TRUE) {
  cosine_metrics <- readRDS("data/cosine_metrics.rds")
  print("Plik z metrykami istnieje w projekcie i został zaczytany")
} else {
  cosine_metrics <- cosine(data)
  saveRDS(cosine_metrics, "data/cosine_metrics.rds")
  cosine_metrics <- readRDS("data/cosine_metrics.rds")
  print("Metryki musiały zostać policzone")
}

# Funkcja odpowiedzialna za znalezienie najbardziej podobnych filmów do filmu wybranego

create_recommendations <- function(movie_name) {
  # Znalezienie numeru id wybranego filmu
  movie <- dplyr::filter(movies, title == movie_name)
  movie <- as.character(movie$movieID)
  # Wzięcie kolumny z metrykami dla wybranego filmu i posortowanie metryk malejąco
  selected_movie_metrics <- cosine_metrics[, movie]
  selected_movie_metrics <- data.frame(metrics = selected_movie_metrics)
  selected_movie_metrics <- cbind(movieID = rownames(selected_movie_metrics), 
                                  selected_movie_metrics)
  setDT(selected_movie_metrics)
  setorder(selected_movie_metrics, -metrics)
  # Wzięcie 11 pierwszych sąsiadów i usunięcie pierwszego, bo to ten sam film
  neighbors <- head(selected_movie_metrics[ , 1], 11)
  neighbors <- neighbors[-1,]
  neighbors_vector <- neighbors$movieID
  setDT(movies)
  # Wzięcie podstawowych informacji o 10 najbliższych sąsiadach wybranego filmu
  table <- movies_info[movieID %in% neighbors_vector]
  setDT(table)
  selected_movie_metrics$movieID <- as.character(selected_movie_metrics$movieID)
  table$movieID <- as.character(table$movieID)
  table <- merge(table, selected_movie_metrics, by = "movieID", all.x = TRUE)
  setorder(table, -metrics)
  # Obliczenie odległości między filmami
  table[, distance := 1-metrics]
  # Drobne korekty kolumn
  table[, c("movieID", "Genres", "metrics") := NULL]
  table <- subset(table, select = c(imdbID, distance, Title, Plot, Poster))
  colnames(table) <- c("imdbID", "Distance", "Title", "Plot", "Poster")
  # Zwrócenie przygotowanej tabeli
  return(table)
}

#create_recommendations("Shawshank Redemption, The (1994)")

