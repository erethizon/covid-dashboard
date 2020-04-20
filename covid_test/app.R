#building my covid app following the shiny tutorial
#set up the app
library(shiny) #required
library(leaflet) #mapping spatial data
library(rgdal) #working with spatial data
library(RSocrata)#for pulling public health data
library(tidyverse)
library(config)#for keeping config file private
library(htmltools) #for tweaking map labels

#BUILD REACTIVE VERSION without map
#pull in shapefile

#PULL IN PUBLICH HEALTH DATA

nys<-config::get("/Users/ebar/Dropbox/R/covid-dashboard/nys_healthdata") #may need to adjust path

#pull the data
covidData<-read.socrata(
  "https://health.data.ny.gov/resource/xdss-u53e.csv",
  app_token = nys$token,
  email     = nys$email,
  password  = nys$pwd
)
#subset to focal counties
our_counties<-c("Clinton", "Essex", "Franklin", "Hamilton", "Herkimer", "Lewis", "St. Lawrence", "Jefferson")
noco_covid<-covidData %>% filter(county %in% our_counties)

#extract most recent data
no_covid<-noco_covid %>% group_by(county) %>%
  arrange(desc(test_date)) %>% slice(1)

#set population variable
population<-c(80695,37300,50293,4434,61833,111755,26447,108047)
pop_size<-rep(population, (length(noco_covid$county)/8))

noco_covid$pop_size<-pop_size
noco_covid$cases_per_1000<-(noco_covid$cumulative_number_of_positives/noco_covid$pop_size)*1000
noco_covid$tests_per_1000<-(noco_covid$cumulative_number_of_tests/noco_covid$pop_size)*1000

#color variable for plots
colors<-c('#ffffe5','#f7fcb9','#d9f0a3','#addd8e','#78c679','#41ab5d','#238443','#005a32')



#build ui ----
ui<-fluidPage(

  titlePanel("North Country Covid Mapper"),

  sidebarLayout(
    sidebarPanel(
      helpText("This application will help you visualize covid data in the North Country"),
      selectInput("variable", "Choose the data to display",
                  choices = c("Total cases",
                              "Cases per 1000 residents",
                              "Total tests",
                              "Tests per 1000 residents"
                              ),
                  selected = "Total cases")
     ),

    mainPanel(
      tabsetPanel(
        tabPanel("Plot view",
                 plotOutput("cases_county")),
        tabPanel("Table view", tableOutput("cases_by_table"))

    )
  )
)
)

#define server logic ----
server<-function(input, output) {

  output$cases_county<-renderPlot({
    data<-switch(input$variable,
    "Total cases" = noco_covid$cumulative_number_of_positives,
    "Cases per 1000 residents" = noco_covid$cases_per_1000,
    "Total tests" = noco_covid$cumulative_number_of_tests,
    "Tests per 1000 residents" = noco_covid $tests_per_1000)

ylabs<-switch(input$variable,
    "Total cases" = "Cumulative number of cases",
    "Cases per 1000 residents" = "Cases per 1000 residents",
    "Total tests" = "Cumulative number of tests",
    "Tests per 1000 residents" = "Tests per 1000 residents")

    ggplot(noco_covid, aes(test_date, data, group = county, color = county))+
      geom_line()+
      geom_point()+
      scale_color_manual(values = colors)+
      labs(x = "Date", y = ylabs)
  })
  output$cases_by_table<-renderTable({
    my_data<-switch(input$variable,
                 "Total cases" = noco_covid$cumulative_number_of_positives,
                 "Cases per 1000 residents" = noco_covid$cases_per_1000,
                 "Total tests" = noco_covid$cumulative_number_of_tests,
                 "Tests per 1000 residents" = noco_covid $tests_per_1000)

  })
}

# Run the app ----
shinyApp(ui = ui, server = server)