TABS <<- tabPanel("Ranking", 
                  div(class = 'filter-box', 

                      div(class = "filter_divs", 
                          pickerInput(inputId = "movie_name", choices = MOVIES_NAME, multiple = FALSE, 
                                      options = list(`selected-text-format` = "count > 3", `live-search` = TRUE, 
                                                     `actions-box` = TRUE))
                      )),

                  DTOutput("table")
                                        
) 