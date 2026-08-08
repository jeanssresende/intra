library(shiny)
library(shinyjs)
library(shinyWidgets)

source("scripts/carrega_funcoes.R")
source("scripts/metrics.R")
source("server_qualidade.R")
source("server_trimagem.R")

apresentacao_html <- HTML(
  paste(
    readLines("www/apresentacao.html", encoding = "UTF-8"),
    collapse = "\n"
  )
)

mostrar_apresentacao <- function() {
  showModal(
    modalDialog(
      title = NULL,
      apresentacao_html,
      size = "l",
      easyClose = FALSE,
      footer = actionButton(
        "btn_iniciar",
        "Iniciar",
        class = "btn-primary"
      )
    )
  )
}

server <- function(input, output, session) {
  
  mostrar_apresentacao()
  
  observeEvent(input$btn_iniciar, {
    removeModal()
  })
  
  # Diretório selecionado pelo usuário
  r_dir_path <- reactiveVal(NULL)
  
  # Resultado da análise de qualidade compartilhado entre módulos
  r_resultado_qa <- reactiveVal(NULL)
  
  qualidadeServer("qualidade_id", r_dir_path, r_resultado_qa)
  
  trimagemServer("trimagem_id")
  
  observeEvent(input$mode, {
    if (identical(input$mode, "dark")) {
      addCssClass(id = "page", class = "dark-mode")
    } else {
      removeCssClass(id = "page", class = "dark-mode")
    }
  })
}