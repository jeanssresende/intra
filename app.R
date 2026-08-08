library(shiny)

# Pacotes
library(ShortRead)
library(ggplot2)
library(fs)
library(scales)
library(plotly)
library(viridis)
library(shinyjs)
library(shinyWidgets)

# Limite de upload (100 GB)
options(shiny.maxRequestSize = 100 * 1024^3)

# Carrega interface e servidor
source("ui.R")
source("server.R")

# Cria o aplicativo
shinyApp(ui = ui, server = server)