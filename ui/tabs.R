TABS <<- tabPanel("Ranking", 
                  div(class = 'filter-box', 

                      div(class = "filter_divs", 
                          pickerInput(inputId = "movie_name", choices = MOVIES_NAME, multiple = FALSE, 
                                      options = list(`selected-text-format` = "count > 3", `live-search` = TRUE, 
                                                     `actions-box` = TRUE),
                                      selected = "Lion King, The (1994)")
                      )),
                  
                  hidden(progressBar(id = 'progres', value = 0, size = "sm", status = "danger", striped = TRUE, 
                                     title = "", range_value = NULL, unit_mark = "%", display_pct = TRUE)),

                  DTOutput("table")
                                        
) 