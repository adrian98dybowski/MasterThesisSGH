server <- function(input, output, session){
  
  USER_ENV <- pryr::where("session")
  
####################################  RECOMMENDER  ####################################    
  
  # Wyświetlanie tabeli z wynikami każdorazowo po zmianie filmu w filtrze
  
  observeEvent(list(input$movie_name),{
  
  # Początek paska ładowania danych
    
  #runjs(code = "$('#modal_details_table').modal('hide')")  
  runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
  updateProgressBar(session = session, id = "progres", value = 20, title = "Start")  
    
  # Przygotowanie danych do tabeli
   
   # Wybranie filmu - funkcja z pliku pythonowego
   df <- create_recommendations(input$movie_name)
   #df <- df[rev(rownames(df)),]
   df$Position <- 1:10
   setDT(df)
   
  updateProgressBar(session = session, id = "progres", value = 50, title = "Proccesing ...")
   
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
   
   # Połączenie danych z tabeli rekomendowanych filmów z danymi z tabeli api
   df$imdbID <- as.character(df$imdbID)
   rapidapi$imdbID <- as.character(rapidapi$imdbID)
   df <- merge(df, rapidapi, by = "imdbID", all.x = TRUE)
   setorder(df, Position)
   
   df[, 'Ad' := paste("<div class = 'img-details' title = 'movie poster'
       onclick = 'Shiny.setInputValue(\"choosen_id\", ", imdbID, ");
                  Shiny.setInputValue(\"modal\", Math.random());'>
      <img src = ", Poster, " width = '200px' height = '200px'>
      </div>", sep = "")]
   
   df[, c("imdbID", "Poster") := NULL]
   
   main_table <- subset(df, select = c(Position, Distance, Title, Plot, Ad))
   colnames(main_table) <- c('Position', 'Distance', 'Title', 'Plot', 'Poster')
   
   updateProgressBar(session = session, id = "progres", value = 80, title = "Download data!!!")
   
   # Finalne tabele
   dataInsideMain <- reactive({main_table})
  
  # Przygotowanie tabeli pokazywanej w aplikacji
   
  output$tableMain <- renderDT({
            datatable(dataInsideMain(),
            escape = F,
            class = 'cell-border stripe',
            selection = 'none',
            rownames = FALSE,
            options = list(dom = 'Blfrtip',
                           title = 'Recommender', 
                           pageLength = 10, 
                           searchHighlight = TRUE, 
                           scrollX = TRUE, 
                           lengthMenu = list(c(3, 5, -1), c('3', '5', '10')), 
                           autoWidth = FALSE, 
                           columnDefs = list(list(width = '50px', targets = 0),
                                             list(width = '50px', targets = 1),
                                             list(width = '300px', targets = 2),
                                             list(width = '500px', targets = 3),
                                             list(width = '250px', targets = 4))
            )) %>%
            formatRound(c("Distance"), digits = 2)

  }, server = FALSE
  )
  
  # Koniec paska ładowania danych
  
  updateProgressBar(session = session, id = "progres", value = 100, title = "Done!!!")
  
  # Ukrycie paska ładowania danych
  
  shinyjs::delay(1 * 1000, {
    runjs(code = "$('.progress-group').addClass('shinyjs-hide')")
    updateProgressBar(session = session, id = "progres", value = 0, title = "")
  })
  })
  
  
  
####################################  Movie Info  ####################################
  
  observeEvent(list(input$movie_name2),{
     
     # Początek paska ładowania danych
     
     runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
     updateProgressBar(session = session, id = "progres2", value = 20, title = "Start")
     
     
     df2 <- movies[title == input$movie_name2]
     #df2 <- movies[title == "Shawshank Redemption, The (1994)"]
     #df2[, genres := strsplit(genres, split = '\\|')]
     #df2[, genres := gsub(',', ' ', genres)]
     
     updateProgressBar(session = session, id = "progres2", value = 50, title = "Proccesing ...")
     
     # Pobranie danych z api internetowego
     rapidapi2 <- data.frame(matrix(ncol = 7, nrow = 1))
     colnames(rapidapi2) <- c("imdbID", "description", "movie_length", "rating", "release", 
                              "banner", "trailer")
     
     url <- sprintf("https://data-imdb1.p.rapidapi.com/movie/id/%s/",
                       df2$imdbID)
        
     response <- VERB("GET", url, add_headers(
           'rapidapi-host' = 'data-imdb1.p.rapidapi.com',
           'rapidapi-key' = 'd29ee17a3dmshacf1dad96b6fa27p150b6cjsn8d3f05896ed6'),
           content_type("application/octet-stream"))
        
     x2 <- content(response, "parsed")
     if (length(x2$results$description) == 0 |length(x2$results$movie_length) == 0 
         | length(x2$results$rating) == 0 | length(x2$results$release) == 0
         | length(x2$results$banner) == 0 | length(x2$results$trailer) == 0){
         x2$results$description <- NA
         x2$results$movie_length <- NA
         x2$results$rating <- NA
         x2$results$release <- NA
         x2$results$banner <- NA
         x2$results$trailer <- NA
     }
     
     rapidapi2[, 1] <- df2$imdbID
     rapidapi2[, 2] <- x2$results$description
     rapidapi2[, 3] <- x2$results$movie_length
     rapidapi2[, 4] <- x2$results$rating
     rapidapi2[, 5] <- x2$results$release
     rapidapi2[, 6] <- x2$results$banner
     rapidapi2[, 7] <- x2$results$trailer
     
     df2$imdbID <- as.character(df2$imdbID)
     rapidapi2$imdbID <- as.character(rapidapi2$imdbID)
     df2 <- merge(df2, rapidapi2, by = "imdbID", all.x = TRUE)
     
     df2[, 'Ad' := paste("<div class = 'img-details' title = 'movie poster'
       onclick = 'Shiny.setInputValue(\"choosen_id\", ", imdbID, ");
                  Shiny.setInputValue(\"modal\", Math.random());'>
      <img src = ", banner, " width = '500px' height = '600px'>
      </div>", sep = "")]
     
     info_table <- subset(df2, select = c("title", "rating", "release", "movie_length",
                                          "genres"))
     colnames(info_table) <- c("Title", "General rating", "Release", "Length (minutes)", 
                               "Genre")
     info_table <- info_table %>% 
                   kbl("html", align = 'c') %>%
                   column_spec(1:4, border_right = T) %>%
                   kable_styling(fixed_thead = F,
                                 full_width = T, font_size = 16, 
                                 position = 'center', 
                                 html_font = 'Cambria')
     
     trailer_table <- data.frame(Trailer = "Watch trailer")
     trailer_table <- trailer_table %>%
                      kbl() %>%
                      kable_paper(full_width = T) %>%
                      column_spec(1, color = "Blue", 
                                  link = as.vector(as.character(df2$trailer))) %>%
                      kable_styling(fixed_thead = F, full_width = F, 
                                    position = 'center',
                                    font_size = 16, html_font = 'Cambria')
     
     
     description_table <- subset(df2, select = c("description"))
     colnames(description_table) <- "Description"
     description_table <- description_table %>%
       kbl(booktabs = T) %>%
       kable_paper(full_width = F) %>%
       column_spec(1, italic = TRUE) %>%
       kable_styling(fixed_thead = F, full_width = F, 
                     position = 'left',
                     font_size = 20, html_font = 'Cambria')
     
     poster_table <- data.frame(Poster = "")
     poster_table <- poster_table %>%
                     kbl(booktabs = T) %>%
                     kable_paper(full_width = F, position = 'right') %>%
                     column_spec(1, image = as.vector(as.character(df2$Ad)))
     
     
     # Przygotowanie tabel pokazywanych w aplikacji
     
     output$table2a <- renderUI({
        HTML(info_table)
     })
     
     output$table2b <- renderUI({
       HTML(trailer_table)
     })
     
     output$table2c <- renderUI({
       HTML(description_table)
     })
     
     output$table2d <- renderUI({
       HTML(poster_table)
     })
     
     # Koniec paska ładowania danych
     
     updateProgressBar(session = session, id = "progres2", value = 100, title = "Done!!!")
     
     # Ukrycie paska ładowania danych
     
     shinyjs::delay(1 * 1000, {
        runjs(code = "$('.progress-group').addClass('shinyjs-hide')")
        updateProgressBar(session = session, id = "progres2", value = 0, title = "")
     })
  })

} 
