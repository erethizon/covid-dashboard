#building my covid app following the shiny tutorial
#set up the app
library(shiny) #required
library(leaflet) #mapping spatial data
library(rgdal) #working with spatial data
library(RSocrata)#for pulling public health data
library(tidyverse)
library(config)#for keeping config file private
library(htmltools) #for tweaking map labels

#pull in shapefile
counties<-readOGR("NYS_Civil_Boundaries_SHP/no_co_counties.shp", layer = "Counties")

#PULL IN PUBLICH HEALTH DATA

nys<-config::get("nys_healthdata") #may need to adjust path

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

#join health data to shapefile
noco_ll@data<-left_join(noco_ll@data, no_covid, by = c("NAME" = "county"))

#now set up map labels

labels<-sprintf(
  "<strong>%s</strong><br/>%g cases.",
  noco_ll$NAME, noco_ll$cumulative_number_of_positives) %>% lapply(htmltools::HTML)


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
                              "Herkimer",
                              "Lewis"),
                  selected = "St. Lawrence")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map view", leafletOutput("covid_map"))
      )
    )
  )
)

#define server logic ----
server<-function(input, output) {
ouptput$covid_map<- renderLeaflet({
  leaflet() %>% addTiles() %>%
    setView(lng = -75.05, lat = 44.05, zoom = 7) %>%
    addPolygons(
      data = noco_ll,
      weight = 5,
      col = 'red',
      highlight = highlightOptions(#highlight lets you mouse over a county and have it change color
        weight = 5,
        color = "orange",
        bringToFront = T),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto")
    )

})
}

# Run the app ----
shinyApp(ui = ui, server = server)