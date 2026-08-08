library(bslib)
library(shinyjs)
library(shinyFiles)
library(shinyWidgets)

source("ui_qualidade.R")
source("ui_trimagem.R")

tema_intra <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  base_font = font_google("Lexend Deca")
)

ui <- fluidPage(
  
  theme = tema_intra,
  
  useShinyjs(),
  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "apresent.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "qualidade.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "trimagem.css")
  ),
  
  page_navbar(
    
    title = tags$span(
      tags$img(
        src = "logo-principal-sf.png",
        id = "logo-fixo",
        alt = "Logo da INTRA - Liga Acadêmica de Informática em Saúde"
      ),
      "INTRA",
      class = "titulo-app"
    ),
    
    nav_panel(
      "Qualidade",
      qualidadeUI("qualidade_id")
    ),
    
    nav_panel(
      "Trimagem",
      trimagemUI("trimagem_id")
    ),
    
    nav_spacer(),
    
    nav_item(
      input_dark_mode(id = "mode", mode = "light")
    ),
    
    id = "page"
  )
)