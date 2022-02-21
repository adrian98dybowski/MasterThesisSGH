server <- function(input, output, session){
  
  USER_ENV <- pryr::where("session")
  
  # Wyświetlanie tabeli z wynikami każdorazowo po zmianie filmu w filtrze
  
  observeEvent(list(input$movie_name),{
  
  # Początek paska ładowania danych
    
  runjs(code = "$('.progress-group').removeClass('shinyjs-hide')")
  updateProgressBar(session = session, id = "progres", value = 20, title = "Proccesing ...")  
    
  # Przygotowanie danych do tabeli
  
   df <- create_recommendations(input$movie_name)
   df <- df[rev(rownames(df)),]
   df$Position <- 1:10
   df <- subset(df, select = c(Position, imdbID, Title, Distance))
   dataInside <- reactive({df})
  
  # Przygotowanie tabeli 
   
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
                           columnDefs = list(list(width = '100px', targets = 0),
                                             list(width = '100px', targets = 1),
                                             list(width = '300px', targets = 2),
                                             list(width = '100px', targets = 3))
            )) %>%
            formatRound(c("Distance"), digits = 2)

  }, server = FALSE
  )
  
  # Koniec paska ładowania danych
  
  updateProgressBar(session = session, id = "paths_progres", value = 70, title = "Download data!!!")
  updateProgressBar(session = session, id = "progres", value = 100, title = "Done!!!")
  
  # Ukrycie paska ładowania danych
  
  shinyjs::delay(1 * 1000, {
    runjs(code = "$('.progress-group').addClass('shinyjs-hide')")
    updateProgressBar(session = session, id = "progres", value = 0, title = "")
  })
  
  })
}

