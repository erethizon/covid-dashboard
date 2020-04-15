#building my covid app following the shiny tutorial
library(shiny)
#build ui ----
ui<-fluidPage(
  titlePanel("North Country Covid Mapper"),
  sidebarLayout(
    sidebarPanel(
      helpText("This application will help you visualize covid data in the North Country"),
      selectInput("county", "Choose the focal county",
                  choices = c("Jefferson",
                              "St. Lawrence",
                              "Franklin",
                              "Clinton",
                              "Essex",
                              "Hamilton",
                              "Lewis"),
                  selected = "St. Lawrence")
    ),
    mainPanel()
  )
)

#define server logic ----
server<-function(input, output) {

}

# Run the app ----
shinyApp(ui = ui, server = server)