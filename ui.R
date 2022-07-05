fluidPage(
  tags$head(
    includeCSS("www/style.css"), 
  ), 
  useShinyjs(), 
  
  navbarPage("MovieR App", id = 'navbar',
             source("ui/tabs.R", local = TRUE)$value,
             source("ui/tabs2.R", local = TRUE)$value,
             source("ui/tabs3.R", local = TRUE)$value
  ),
  
  tags$hr(), 
  HTML("<footer align = 'right'>Adrian Dybowski</footer>")
)