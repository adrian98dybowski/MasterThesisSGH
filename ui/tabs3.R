TABS3 <<- tabPanel("Rankings", 
                  div(class = 'filter-box', 
                      
                      div(class = "filter_divs", 
                          pickerInput(inputId = "genres", choices = GENRES, 
                                      multiple = FALSE, 
                                      options = list(`selected-text-format` = 
                                                       "count > 3", 
                                                     `live-search` = TRUE, 
                                                     `actions-box` = TRUE),
                                      selected = "Drama")
                      )),

                  hidden(progressBar(id = 'progres3', value = 0, size = "sm",
                                     status = "danger", striped = TRUE, title = "",
                                     range_value = NULL, unit_mark = "%",
                                     display_pct = TRUE))
                  ,

                  DTOutput("tableRankings")
)