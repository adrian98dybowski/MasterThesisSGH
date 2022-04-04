server <- function(input, output, session){
  
  USER_ENV <- pryr::where("session")
  
  # Wyświetlanie tabeli z wynikami każdorazowo po zmianie filmu w filtrze
  
  observeEvent(list(input$movie_name),{
  
  # Początek paska ładowania danych
    
  runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
  updateProgressBar(session = session, id = "progres", value = 20, title = "Start")  
    
  # Przygotowanie danych do tabeli
   
   # Wybranie filmu - funkcja z pliku pythonowego
   df <- create_recommendations(input$movie_name)
   df <- df[rev(rownames(df)),]
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
   df <- merge(df, rapidapi, by = "imdbID", all.x = TRUE)
   setorder(df, Position)
   
   df[, 'Info' := paste("<div class = 'img-details' title = 'show details'
       onclick = 'Shiny.setInputValue(\"choosen_id\", ", imdbID, ");
                  Shiny.setInputValue(\"initialize_modal\", Math.random());'>
      <img src = ", Poster, " width = '200px' height = '200px'>
      </div>", sep = "")]
   
   df[, c("imdbID", "Poster") := NULL]
   df <- subset(df, select = c(Position, Distance, Title, Plot, Info))
   colnames(df) <- c('Position', 'Distance', 'Title', 'Plot', 'Poster')
   
   updateProgressBar(session = session, id = "progres", value = 80, title = "Download data!!!")
   
   # Finalna tabela
   dataInside <- reactive({df})
  
  
  # Przygotowanie tabeli pokazywanej w aplikacji
   
  output$table <- renderDT({
            datatable(dataInside(),
            escape = F,
            class = 'cell-border stripe',
            selection = 'none',
            rownames = FALSE,
            options = list(dom = 'Blfrtip',
                           title = 'Ranking', 
                           pageLength = 10, 
                           searchHighlight = TRUE, 
                           scrollX = TRUE, 
                           lengthMenu = list(c(3, 5, -1), c('3', '5', '10')), 
                           autoWidth = FALSE, 
                           columnDefs = list(list(width = '50px', targets = 0),
                                             list(width = '50px', targets = 1),
                                             list(width = '300px', targets = 2),
                                             list(width = '400px', targets = 3),
                                             list(width = '300px', targets = 4))
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
} 
