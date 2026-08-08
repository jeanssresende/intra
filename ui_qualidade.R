library(shiny)
library(shinyjs)
library(shinyWidgets)
library(bslib)

qualidadeUI <- function(id) {
  
  ns <- NS(id)
  
  sidebarLayout(
    
    # =========================================================
    # SIDEBAR
    # =========================================================
    sidebarPanel(
      width = 4,
      class = "sidebar-custom",
      
      card(
        card_header(tags$b("Passo 1 • Selecionar arquivos")),
        
        p(
          "Escolha um ou mais arquivos FASTQ/FASTA ou selecione uma pasta contendo os arquivos da análise."
        ),
        
        shinyDirButton(
          ns("diretorio"),
          "Adicionar uma pasta",
          "Selecionar",
          class = "botao-diretorio btn btn-light w-100"
        ),
        
        tags$br(),
        tags$br(),
        
        tags$strong("Adicionar arquivo(s)"),
        
        fileInput(
          ns("arquivos"),
          label = NULL,
          multiple = TRUE,
          accept = c(
            ".fasta", ".fa",
            ".fastq", ".fq",
            "text/plain"
          )
        ),
        
        div(
          style = "margin-top:10px;",
          textOutput(ns("caminhoPasta"))
        )
      ),
      
      br(),
      
      card(
        card_header(tags$b("Passo 2 • Configurações")),
        
        selectInput(
          ns("palette_choice"),
          "Paleta de cores",
          choices = c(
            "viridis", "magma", "plasma", "rocket",
            "cividis", "inferno", "turbo", "mako"
          ),
          selected = "viridis",
          selectize = FALSE
        )
      ),
      
      br(),
      
      card(
        card_header(tags$b("Passo 3 • Executar análise")),
        
        p(
          "Clique no botão abaixo para iniciar o controle de qualidade dos arquivos selecionados."
        ),
        
        div(
          id = ns("loading_animation"),
          class = "loading_animation"
        ),
        
        actionButton(
          ns("run_analysis"),
          "Iniciar análise de qualidade",
          class = "btnQA-custom w-100"
        )
      )
    ),
    
    # =========================================================
    # PAINEL PRINCIPAL
    # =========================================================
    mainPanel(
      width = 8,
      
      card(
        full_screen = TRUE,
        
        card_header(
          tags$span(icon("chart-line"), " Resultados do Controle de Qualidade")
        ),
        
        navset_pill(
          
          nav_panel(
            "Qualidade por Ciclo",
            
            plotOutput(
              ns("plot_qualidade_ciclo_est"),
              width = "100%",
              height = "520px"
            ),
            
            ui_download_plot(ns, "ciclo")
          ),
          
          nav_panel(
            "Qualidade Média",
            
            plotOutput(
              ns("plot_qualidade_media_est"),
              width = "100%",
              height = "520px"
            ),
            
            ui_download_plot(ns, "media")
          ),
          
          nav_panel(
            "Contagem de Bases",
            
            plotOutput(
              ns("plot_contagens_est"),
              width = "100%",
              height = "520px"
            ),
            
            ui_download_plot(ns, "contagens")
          ),
          
          nav_panel(
            "Distribuição Cumulativa de Leituras",
            
            plotOutput(
              ns("plot_ocorrencias_est"),
              width = "100%",
              height = "520px"
            ),
            
            ui_download_plot(ns, "ocorrencias")
          ),
          
          nav_panel(
            "Sequências Frequentes",
            
            div(
              style = "overflow-x:auto;",
              tableOutput(ns("tabela_frequencias"))
            )
          ),
          
          nav_panel(
            "Contaminação por Adaptadores",
            
            div(
              style = "overflow-x:auto;",
              tableOutput(ns("tabela_adapters"))
            )
          )
        )
      ),
      
      br(),
      
      card(
        card_header(
          tags$span(icon("info-circle"), " Status da Análise")
        ),
        
        div(
          id = ns("qa_output"),
          style = "padding:12px; min-height:60px;",
          "Nenhuma análise executada."
        )
      )
    )
  )
}

# =============================================================
# COMPONENTE DE DOWNLOAD
# =============================================================
ui_download_plot <- function(ns, plot_name) {
  
  shinyjs::hidden(
    
    div(
      id = ns(paste0("wrapper_download_", plot_name)),
      class = "download-box",
      
      fluidRow(
        
        column(
          width = 6,
          
          selectInput(
            ns(paste0("formato_download_", plot_name)),
            "Formato",
            choices = c("png", "pdf", "jpeg", "svg"),
            selected = "pdf"
          )
        ),
        
        column(
          width = 6,
          
          div(
            style = "margin-top:25px;",
            
            downloadButton(
              ns(paste0("download_plot_", plot_name)),
              "Baixar gráfico",
              class = "btn btn-success w-100"
            )
          )
        )
      )
    )
  )
}