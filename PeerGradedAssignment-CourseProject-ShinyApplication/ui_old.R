#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
set.seed(101)


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

# Define UI for application that shows sea level rise
shinyUI(fluidPage(

    # Application title
    titlePanel("Sea level rise in the Netherlands"),

    # drowpdown menu for selection of stations
    # checkboxes for predictions
    sidebarLayout(
        sidebarPanel(
            selectInput("stationname", "Tidal Station:", stations.NL$name, selected=stations.NL$name[1]),
            checkboxInput("showModelLin", "Show/Hide Linear prediction", value = TRUE),
            checkboxInput("showModelBrk", "Show/Hide Linear prediction broken in 1993", value = TRUE),
            checkboxInput("showModelQdr", "Show/Hide Quadratic prediction", value = TRUE)
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("statPlot")
        )
    )
))
