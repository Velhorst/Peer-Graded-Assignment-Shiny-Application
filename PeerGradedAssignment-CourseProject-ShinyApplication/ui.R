#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)


# Load data ---------------------------------------------------------------
# data directory
datadir <- "data"

# file containing tide stations locations
fn_data <- "rlr_annual/filelist.txt"
dataf <-file.path(datadir, fn_data)

# station data
stations <- read.table(dataf, sep = ";",
                       col.names = c('id', 'lat', 'lon', 'name', 'coastline_code', 'station_code', 'quality'),
                       strip.white = TRUE
)

# Select stations in the Netherlands
NL_coastline_code = 150
stations.NL  <-stations[which(stations$coastline_code==NL_coastline_code),]

RLRdata.NL <- read.csv("data/RLRdataNL.csv")

# Shiny User Interface  ------------------------------------------------------

# Define UI for application that shows sea level rise
shinyUI(fluidPage(

    # Application title
    titlePanel("Sea level rise in the Netherlands"),
    
    # fluidRow(

    # ),

    # drowpdown menu for selection of stations
    # checkboxes for predictions
    fluidRow(
        
        # Add documentation
        column(3,
               h2("Documentation"),
               h3("General overview"),
               h5("This shiny app shows measurements of the year-averaged sea level at multiple tidal stations in the Netherlands."),
               h5("The map at the right panel shows the station locations. The plot on the bottom shows the selected data and optionally predictions of the data."),
               h5("As sea level rise is possibly accelerating, multiple predicitons could be relevant."),
               
               h3("Usage"),
               h4("Select station"),
               h5("By selecting the station name in the dropdown-menu, the data of the requested station is selected."),
               h5("The selected station is colored green on the map."),
               
               h4("Select predictions"),
               h5("Three predictions of the selected data are available: a linear prediction, a quadratic predection and a broken linear prediction."),
               h5("The predictions can be hide and viewed using the checkboxes."),
               h5("The breakpoint of the broken linear prediction can be altered using a slider. The default is 1993."),
               
               h3("Data"),
               h5("The data originates from: "), uiOutput("dataurl")
        ),
        
        
        column(9,
               
            fluidRow(
                column(5,
                    h2("Interactive app"),
                    selectInput("stationname", "Tidal Station:", sort(stations.NL$name), selected=sort(stations.NL$name)[1]),
                    checkboxInput("showModelLin", "Linear Prediction", value = TRUE),
                    checkboxInput("showModelQdr", "Quadratic Prediction", value = TRUE),
                    checkboxInput("showModelBrk", "Broken Linear Prediction", value = TRUE),
                    conditionalPanel("input.showModelBrk",
                        sliderInput("year_break", "year of prediction breakpoint", 1900, 2000,
                                    value = 1993, step = 1)
                    )
                ),
                
                
                column(7,
                    # Map of station locations
                    leafletOutput("map", width="100%", height=400)
                ),
            ),
            
            fluidRow(
                column(12,
                    # Show a plot of the selected station
                    plotOutput("statPlot")
                )
            ),
        ),
    )
))
