server <- function(input, output, session){
  
  USER_ENV <- pryr::where("session")
  
  output$table <- renderDT({
    df <- create_recommendations(input$movie_name)
    df <- data.frame(df)
    #df <- subset(df, select = -c(imdbID) )
            datatable(df,
            escape = F,
            class = 'cell-border stripe',
            #extensions = c('Buttons', 'Scroller'),
            selection = 'none',
            rownames = FALSE,
            options = list(dom = 'Blfrtip',
                           title = 'Ranking', 
                           pageLength = 10, 
                           searchHighlight = TRUE, 
                           scrollX = TRUE, 
                           lengthMenu = list(c(3, 5, -1), c('3', '5', '10')), 
                           autoWidth = TRUE, 
                           columnDefs = list(list(width = '100px', targets = 1), 
                                             list(width = '400px', targets = 2)) 
            )) %>%
            formatRound(c("Distance"), digits = 2)

  }, server = FALSE
  )
  
}
