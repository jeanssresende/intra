library(shinyjs)
library(shinyWidgets)

qualidadeServer <- function(id, r_dir_path, r_resultado_qa) {
  
  moduleServer(id, function(input, output, session) {
    
    # =========================
    # Configurações reativas
    # =========================
    
    paleta_cores <- reactive({
      req(input$palette_choice)
      tolower(input$palette_choice)
    })
    
    # Arquivos utilizados na análise
    get_files_for_analysis <- reactive({
      
      # Prioriza arquivos enviados por upload
      if (!is.null(input$arquivos)) {
        return(normalizePath(input$arquivos$datapath))
      }
      
      dir_path <- r_dir_path()
      
      # Usa a pasta selecionada pelo usuário
      if (!is.null(dir_path) &&
          nzchar(dir_path) &&
          fs::dir_exists(dir_path)) {
        
        pattern_regex <- "\\.(fq|fastq|fa|fasta)(\\.gz)?$"
        
        return(fs::dir_ls(
          dir_path,
          regexp = pattern_regex,
          recurse = FALSE
        ))
      }
      
      NULL
    })
    
    # Nomes exibidos na interface
    nomes_arquivos <- reactive({
      fls <- get_files_for_analysis()
      req(fls)
      basename(fls)
    })
    
    # =========================
    # Seleção de diretório
    # =========================
    
    volumes <- c(Home = fs::path_home())
    
    if (fs::dir_exists("C:/")) {
      volumes["C:"] <- "C:/"
    }
    
    if (fs::dir_exists("D:/")) {
      volumes["D:"] <- "D:/"
    }
    
    shinyDirChoose(
      input,
      "diretorio",
      roots = volumes,
      session = session
    )
    
    observeEvent(input$diretorio, {
      
      path <- parseDirPath(volumes, input$diretorio)
      
      if (length(path) > 0) {
        r_dir_path(path)
      }
    })
    
    output$caminhoPasta <- renderText({
      req(r_dir_path())
      paste("Pasta selecionada:", r_dir_path())
    })
    
    # =========================
    # Execução do controle de qualidade
    # =========================
    
    observeEvent(input$run_analysis, {
      
      shinyjs::hide("run_analysis")
      shinyjs::show("loading_animation")
      
      shinyjs::html(
        session$ns("qa_output"),
        '<b style="color: black;">Controle de Qualidade em andamento...</b>'
      )
      
      shinyjs::delay(100, {
        
        fls <- get_files_for_analysis()
        
        if (is.null(fls) || length(fls) == 0) {
          
          showNotification(
            "Nenhum arquivo FASTQ encontrado!",
            type = "error"
          )
          
          shinyjs::show(session$ns("run_analysis"))
          shinyjs::hide(session$ns("loading_animation"))
          
          return()
        }
        
        tryCatch({
          
          qa_metricas <- measure_execution(
            "Controle de Qualidade",
            {
              suppressWarnings(
                qa(fls, type = "fastq")
              )
            }
          )
          
          print_metrics(qa_metricas)
          
          resultado <- qa_metricas$resultado
          
          # Salva o resultado para os gráficos e tabelas
          r_resultado_qa(resultado)
          
          # Exibe botões de download
          shinyjs::show("wrapper_download_ciclo")
          shinyjs::show("wrapper_download_media")
          shinyjs::show("wrapper_download_contagens")
          shinyjs::show("wrapper_download_ocorrencias")
          shinyjs::show("wrapper_download_adapters")
          
          shinyjs::html(
            "qa_output",
            paste0(
              '<b style="color: #31231a">Controle de Qualidade finalizado!</b><br>',
              'Tempo de execução: ', round(qa_metricas$tempo, 2), ' s<br>',
              'Pico de memória RAM: ', round(qa_metricas$ram, 2), ' MiB'
            )
          )
          
          showNotification(
            paste(length(fls), "arquivo(s) processado(s) com sucesso."),
            type = "message"
          )
          
          shinyjs::hide("loading_animation")
          shinyjs::show("run_analysis")
          
        }, error = function(e) {
          
          shinyjs::html(
            session$ns("qa_output"),
            paste0('<b style="color: #940e01">Erro: ', e$message, '</b>')
          )
          
          shinyjs::hide("loading_animation")
          shinyjs::show("run_analysis")
        })
      })
    })
    
    # =========================
    # Gráfico: qualidade por ciclo
    # =========================
    
    output$plot_qualidade_ciclo_est <- renderPlot({
      req(r_resultado_qa())
      plotCycleQuality(
        r_resultado_qa(),
        paleta_cores(),
        nomes_arquivos()
      )$p_estatico
    })
    
    output$download_plot_ciclo <- downloadHandler(
      
      filename = function() {
        paste0("qualidade_ciclo.", input$formato_download_ciclo)
      },
      
      content = function(file) {
        
        req(
          r_resultado_qa(),
          paleta_cores(),
          input$formato_download_ciclo
        )
        
        p <- plotCycleQuality(
          r_resultado_qa(),
          paleta_cores(),
          nomes_arquivos()
        )$p_estatico
        
        ggsave(
          filename = file,
          plot = p,
          width = 8,
          height = 6,
          device = input$formato_download_ciclo
        )
      }
    )
    
    # =========================
    # Gráfico: qualidade média
    # =========================
    
    output$plot_qualidade_media_est <- renderPlot({
      req(r_resultado_qa())
      readQualityScore(
        r_resultado_qa(),
        paleta_cores(),
        nomes_arquivos()
      )$p_estatico
    })
    
    output$download_plot_media <- downloadHandler(
      
      filename = function() {
        paste0("media.", input$formato_download_media)
      },
      
      content = function(file) {
        
        req(
          r_resultado_qa(),
          paleta_cores(),
          input$formato_download_media
        )
        
        p <- readQualityScore(
          r_resultado_qa(),
          paleta_cores(),
          nomes_arquivos()
        )$p_estatico
        
        ggsave(
          filename = file,
          plot = p,
          width = 8,
          height = 6,
          device = input$formato_download_media
        )
      }
    )
    
    # =========================
    # Gráfico: contagem de bases
    # =========================
    
    output$plot_contagens_est <- renderPlot({
      
      fls <- get_files_for_analysis()
      
      req(fls)
      
      plotNucleotideCount(
        fls,
        paleta_cores(),
        nomes_arquivos()
      )$p_estatico
    })
    
    output$download_plot_contagens <- downloadHandler(
      
      filename = function() {
        paste0("contagens.", input$formato_download_contagens)
      },
      
      content = function(file) {
        
        fls <- get_files_for_analysis()
        
        req(
          fls,
          paleta_cores(),
          input$formato_download_contagens
        )
        
        p <- plotNucleotideCount(
          fls,
          paleta_cores(),
          nomes_arquivos()
        )$p_estatico
        
        ggsave(
          filename = file,
          plot = p,
          width = 8,
          height = 6,
          device = input$formato_download_contagens
        )
      }
    )
    
    # =========================
    # Gráfico: ocorrências
    # =========================
    
    output$plot_ocorrencias_est <- renderPlot({
      req(r_resultado_qa())
      plotOcurrences(
        r_resultado_qa(),
        paleta_cores(),
        nomes_arquivos()
      )$p_estatico
    })
    
    output$download_plot_ocorrencias <- downloadHandler(
      
      filename = function() {
        paste0("ocorrencias.", input$formato_download_ocorrencias)
      },
      
      content = function(file) {
        
        req(
          r_resultado_qa(),
          paleta_cores(),
          input$formato_download_ocorrencias
        )
        
        p <- plotOcurrences(
          r_resultado_qa(),
          paleta_cores(),
          nomes_arquivos()
        )$p_estatico
        
        ggsave(
          filename = file,
          plot = p,
          width = 8,
          height = 6,
          device = input$formato_download_ocorrencias
        )
      }
    )
    
    # =========================
    # Tabela: sequências frequentes
    # =========================
    
    output$tabela_frequencias <- renderTable({
      
      req(r_resultado_qa())
      
      t <- freqSequences(r_resultado_qa())
      
      nomes <- nomes_arquivos()
      
      if (!is.null(nomes)) {
        
        t$Arquivo <- nomes[
          match(t$Arquivo, unique(t$Arquivo))
        ]
        
        t$Arquivo <- ifelse(
          duplicated(t$Arquivo),
          "",
          t$Arquivo
        )
      }
      
      rownames(t) <- NULL
      
      t
    })
    
    # =========================
    # Tabela: contaminação por adaptadores
    # =========================
    
    output$tabela_adapters <- renderTable({
      
      fls <- get_files_for_analysis()
      
      req(fls)
      
      t <- tableAdapterContamination(fls)
      
      nomes <- nomes_arquivos()
      
      if (!is.null(nomes)) {
        t$Arquivo <- nomes[
          match(t$Arquivo, unique(t$Arquivo))
        ]
      }
      
      rownames(t) <- NULL
      
      t
    })
    
  })
}