library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(ggplot2)

source("R/euclidean_distance.R")
source("R/find_class.R")
source("R/dataset.R")

# Initial new observation and initial number of NN
new_obs <- c(4, 4)
init_k <- 7

# Initial table of NN
df_nn <- df |> 
  mutate(distances = euclidean_distance(df, new_obs)) |>
  slice_min(order_by = distances, n = init_k)

ui <- page_fillable(
  padding = 0,
  layout_sidebar(
    border = FALSE,
    sidebar = sidebar(
      title = "Inputs",
      numericInput("k", "Number of neighbors", min = 1, max = 200, step = 2,
                   value = init_k),
      numericInput("x", "Feature x of observation", min = -100, max = 100,
                   step = 0.1, value = 4),
      numericInput("y", "Feature y of observation", min = -100, max = 100,
                   step = 0.1, value = 4)
    ),
    layout_columns(
      card(
        card_header(class = "bg-dark", "Nearest Neigbors Plot"),
        plotlyOutput("plot"),
      ),
      card(
        card_header(class = "bg-dark", "Class and nearest neighbors table"),
        card_body(
          min_height = 250,
          tableOutput("class_count"),
          textOutput("outcome"),
          tableOutput("nn")
        )
      ),
      col_widths = c(8, 4),
      max_height = 800
    )
  )
)

server <- function(input, output, session) {

  # Features of the new observation
  observation <- reactive({
    c(input$x, input$y)
  })
  
  # Arranges in ascending order of distances and keeps the first
  # input$k rows: Finds input$k NN
  data_nn <- reactive({
    d <- df |> 
      mutate(distances = euclidean_distance(df, observation())) |> 
      slice_min(order_by = distances, n = input$k)
    d
  })
  
  # Class of the new observation
  class <- reactive({
    find_class(data_nn(), input$k)
  })
  
  output$outcome <- renderText({
    paste0("The observation belongs to ", class(), ".")
  })
  
  # Plot the training dataset. In addition plot distances, as line segments, 
  # from the new observation to the k nearest neighbors. All data passed to
  # plotting functions are static. Passing static data, was my solution to 
  # preserve the zoom level when restyling some of the traces.
  output$plot <- renderPlotly({
    plot_ly(df) |>
      add_markers(x = ~x, y = ~y, symbol = ~class, symbols = c('x', 'o')) |>
      add_markers(
        x = 4, 
        y = 4,
        color = I("black"), 
        name = "New observation"
      ) |>
      add_segments(
        x = ~df_nn$x,
        xend = 4,
        y = ~df_nn$y,
        yend = 4,
        color = I("black"),
        linetype = I("dotted"),
        line = list(width = 1),
        name = "Distances to NN"
      )
  })
  
  # Certain elements inside this observer are vibe-coded
  observeEvent(c(input$x, input$y, input$k), {
    
    # Restyle new observation
    plotlyProxy("plot", session) |>
      plotlyProxyInvoke(
        "restyle", 
        list(
          x = list(list(input$x)), 
          y = list(list(input$y))
        ), 
      2)
    
    # Build interleaved segment vectors for trace index 3 (vibe-coded)
    nn <- data_nn()
    obs_x <- input$x
    obs_y <- input$y
    
    # Each segment: [x_start, x_end, NA, ...] (vibe-coded)
    seg_x <- as.list(c(rbind(nn$x, rep(obs_x, nrow(nn)), NA)))
    seg_y <- as.list(c(rbind(nn$y, rep(obs_y, nrow(nn)), NA)))
    
    # Restyle segments (vibe-coded)
    plotlyProxy("plot", session) |>
      plotlyProxyInvoke(
        "restyle", 
        list(
          x = list(seg_x),
          y = list(seg_y)
        ), 
      3)
  })
  
  # Table of k nearest neighbors
  output$nn <- renderTable({
    data_nn() |> 
      rename(Class = class, Distance = distances)
  })
  
  # Class count table
  output$class_count <- renderTable({
    data_nn() |> 
      count(class) |> 
      rename(Class = class, Count = n)
  })
}

shinyApp(ui, server)