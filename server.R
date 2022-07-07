server <- function(input, output, session){
  
  USER_ENV <- pryr::where("session")
  
  ####################################  RECOMMENDER  ####################################    
  
  # Wyświetlanie tabeli z wynikami każdorazowo po zmianie filmu w filtrze
  
  observeEvent(list(input$movie_name),{
    
    # Początek paska ładowania danych
    
    runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
    updateProgressBar(session = session, id = "progres", value = 20, title = "Start")  
    
    # Przygotowanie danych do tabeli wizualizującej efekty modelu
    
    # Wybranie filmu
    df <- create_recommendations(input$movie_name)
    df$Position <- 1:10
    setDT(df)
    
    updateProgressBar(session = session, id = "progres", value = 50, title = "Proccesing ...")
    
    # Sortowanie i usunięcie niepotrzebnych kolumn
    
    setorder(df, Position)
    main_table <- subset(df, select = c(Position, Distance, Title, Plot, Poster))
    
    updateProgressBar(session = session, id = "progres", value = 80, title = "Download data!!!")
    
    # Finalna tabela
    
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
    
    # Dane do akładki drugiej
    
    df2 <- movies_info[Title == input$movie_name2]
    df2[, Poster := NULL]
    df2[, 'Poster' := paste("<div class = 'img-details' title = 'movie poster'
       onclick = 'Shiny.setInputValue(\"choosen_id\", ", imdbID, ");
                  Shiny.setInputValue(\"modal\", Math.random());'>
      <img src = ", Poster_link, " width = '500px' height = '600px'>
      </div>", sep = "")]
    
    updateProgressBar(session = session, id = "progres2", value = 50, title = "Proccesing ...")
    
    # Przygotowanie paska z podstawowymi danymi o filmie
    
    info_table <- subset(df2, select = c("Title", "Rating", "Release", "Movie_length",
                                         "Genres"))
    colnames(info_table) <- c("Title", "General rating", "Release", "Length (minutes)", 
                              "Genres")
    info_table <- info_table %>% 
      kbl("html", align = 'c') %>%
      column_spec(1:4, border_right = T) %>%
      kable_styling(fixed_thead = F,
                    full_width = T, font_size = 16, 
                    position = 'center', 
                    html_font = 'Cambria')
    
    # Przygotowanie miejsca, gdzie można klinkąć w link do obejrzenia trailera
    
    trailer_table <- data.frame(Trailer = "Watch trailer")
    trailer_table <- trailer_table %>%
      kbl() %>%
      kable_paper(full_width = T) %>%
      column_spec(1, color = "Blue", 
                  link = as.vector(as.character(df2$Trailer))) %>%
      kable_styling(fixed_thead = F, full_width = F, 
                    position = 'center',
                    font_size = 16, html_font = 'Cambria')
    
    # Przygotowanie miejsca pod opis filmu
    
    description_table <- subset(df2, select = c("Description"))
    description_table <- description_table %>%
      kbl(booktabs = T) %>%
      kable_paper(full_width = F) %>%
      column_spec(1, italic = TRUE) %>%
      kable_styling(fixed_thead = F, full_width = F, 
                    position = 'left',
                    font_size = 20, html_font = 'Cambria')
    
    # Przygotowanie plakatu filmu
    
    poster_table <- data.frame(Poster = "")
    poster_table <- poster_table %>%
      kbl(booktabs = T) %>%
      kable_paper(full_width = F, position = 'right') %>%
      column_spec(1, image = as.vector(as.character(df2$Poster)))
    
    
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
  
  
  ####################################  Rankings  ####################################
  
  observeEvent(list(input$genres),{
    
    # Początek paska ładowania danych
    
    runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
    updateProgressBar(session = session, id = "progres3", value = 20, title = "Start")
    
    # Dane do zakładki trzeciej - filtrowanie na podstawie wybranego rodzaju filmu
    
    df3 <- movies_info
    df3 <- df3[grepl(input$genres, Genres, fixed = TRUE) == TRUE]

    genres_table <- subset(df3, select = c("Title", "Rating", "Poster"))
    genres_table <- genres_table[is.na(Rating) == FALSE]
    setorder(genres_table, -Rating)
    
    updateProgressBar(session = session, id = "progres3", value = 80, title = "Download data!!!")
    
    # Finalna tabela
    
    dataInsideRankings <- reactive({genres_table})
    
    # Przygotowanie tabeli pokazywanej w aplikacji
    
    output$tableRankings <- renderDT({
      datatable(dataInsideRankings(),
                escape = F,
                class = 'cell-border stripe',
                selection = 'none',
                rownames = FALSE,
                options = list(dom = 'Blfrtip',
                               title = 'Rankings', 
                               pageLength = 10, 
                               searchHighlight = TRUE, 
                               scrollX = TRUE, 
                               lengthMenu = list(c(3, 5, -1), c('3', '5', '10')), 
                               autoWidth = FALSE, 
                               columnDefs = list(list(width = '300px', targets = 0),
                                                 list(width = '100px', targets = 1),
                                                 list(width = '250px', targets = 2))
                ))
      
    }, server = FALSE
    )
    
    # Koniec paska ładowania danych
    
    updateProgressBar(session = session, id = "progres3", value = 100, title = "Done!!!")
    
    # Ukrycie paska ładowania danych
    
    shinyjs::delay(1 * 1000, {
      runjs(code = "$('.progress-group').addClass('shinyjs-hide')")
      updateProgressBar(session = session, id = "progres", value = 0, title = "")
    })
    
  })
  
} 