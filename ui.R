fluidPage(
  tags$head(
    includeCSS("www/style.css"), 
  ), 
  useShinyjs(), 
  
  navbarPage("Movie Recommendation App", id = 'navbar',
             source("ui/tabs.R", local = TRUE)$value
  ),
  
  tags$hr(), 
  HTML("<footer align = 'right'>Adrian Dybowski</footer>")
)