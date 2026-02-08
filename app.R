library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(ggplot2)

source("R/euclidean_distance.R")
source("R/find_class.R")
source("R/dataset.R")

ui <- page_fillable(
  padding = 0,
  layout_sidebar(
    border = FALSE,
    sidebar = sidebar(
      title = "Inputs",
      numericInput("k", "Number of neighbors", min = 1, max = 200, step = 2,
                   value = 7),
      numericInput("x", "Feature x of observation", min = -100, max = 100,
                   step = 0.1, value = 4),
      numericInput("y", "Feature y of observation", min = -100, max = 100,
                   step = 0.1, value = 4),
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
  # Coordinates of the new observation
  observation <- reactive({
    c(input$x, input$y)
  })
  
  # Append the distances to the dataset
  data <- reactive({
    df["distances"] <- euclidean_distance(df, observation())
    df
  })
  
  # Arranges the data() in ascending order of distances and keeps the first
  # input$k rows: Finds k nearest neighbors
  data_nn <- reactive({
    data() |> 
      slice_min(order_by = distances, n = input$k)
  })
  
  # Class of the new observation
  class <- reactive({
    find_class(data(), input$k)
  })
  
  output$outcome <- renderText({
    paste0("The observation belongs to class ", class(), ".")
  })
  
  # Plot the dataset. In addition plot distances, as line segments, from the
  # new observation to the k nearest neighbors.
  output$plot <- renderPlotly({
    ggplotly(
      ggplot() +
        geom_point(data = data(), aes(x, y, colour = class)) +
        geom_segment(
          data = data_nn(),
          aes(x = x, y = y, xend = observation()[1], yend = observation()[2]),
          linetype = "dotted",
          linewidth = 0.3
        ) +
        geom_point(aes(x = observation()[1], y = observation()[2]), size = 2),
      width = 800,
      height = 600,
    )
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
