TABS2 <<- tabPanel("Movie Info", 
                   div(class = 'filter-box', 
                       
                       div(class = "filter_divs", 
                           pickerInput(inputId = "movie_name2", choices = MOVIES_NAME, 
                                       multiple = FALSE, 
                                       options = list(`selected-text-format` = 
                                                        "count > 3", 
                                                      `live-search` = TRUE, 
                                                      `actions-box` = TRUE),
                                       selected = "Shawshank Redemption, The (1994)")
                       )),
                   
                   hidden(progressBar(id = 'progres2', value = 0, size = "sm", 
                                      status = "danger", striped = TRUE, title = "", 
                                      range_value = NULL, unit_mark = "%", 
                                      display_pct = TRUE)),
                   
                   
                   uiOutput("table2a"),
                   uiOutput("table2b"),
                   box(uiOutput("table2c")),
                   box(uiOutput("table2d"))
) 