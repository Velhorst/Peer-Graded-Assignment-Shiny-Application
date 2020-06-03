#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(dplyr)
library(RColorBrewer)
set.seed(101)


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

# Load Sea Level Rise Data
RLRdata.NL <- read.csv("data/RLRdataNL.csv")


# Shiny server calculation ------------------------------------------------------

year_start = 1900
year_end = 2050

# Define server logic required to draw a histogram
shinyServer(function(input, output,session) {
    
    url <- a("The Permanent Service for Mean Sea Level", href="https://www.psmsl.org/")
    output$dataurl <- renderUI({
        tagList("", url)
    })
    
    # Map ---------------------------------------------------------------------
    output$map <- renderLeaflet({
        
        # Color by quality flag
        getColor <- function(stations.NL) {
            sapply(stations.NL$name, function(name) {
                if(name == input$stationname) {
                    "green"
                } else {
                    "red"
                } })
        }
        
        # Create icons using color
        icons <- awesomeIcons(
            icon = 'none',
            markerColor = getColor(stations.NL)
        )
        
        # Create map of stations
        stations.NL %>% 
        leaflet() %>% 
        setView(5, 52.5, zoom = 7) %>% # start view around North Sea
        addTiles() %>%
        addAwesomeMarkers(~lon, ~lat, icon=icons,
                          popup =stations.NL$name) # give station name on click
    })
    
    # Plot ---------------------------------------------------------------------
    output$statPlot <- renderPlot({
        
        # Select data
        statname <- input$stationname
        stationdata <- RLRdata.NL[which(statname == RLRdata.NL$name & RLRdata.NL$Year >year_start),]
        
        modelLin <- lm(NAP ~ Year, data = stationdata)
        
        stationdata$Yearsp <- ifelse(stationdata$Year - input$year_break > 0, stationdata$Year - input$year_break, 0)
        modelBrk <- lm(NAP ~ Yearsp + Year, data = stationdata)
        
        stationdata$Year2 <- stationdata$Year^2
        modelQdr <- lm(NAP ~ Year2 + Year, data = stationdata)
        
        # Plot all points in grey
        plot(RLRdata.NL$Year, RLRdata.NL$NAP,
             xlab = "Year", ylab = "Yearly average Water level [mm] above NAP", 
             # main = paste("Station: ", input$stationname),
             bty = "n", pch = 16,
             xlim = c(year_start, year_end), ylim = c(-300, 300),col="grey")
        # Plot selected points in black
        points(stationdata$Year, stationdata$NAP, pch=16 , col="black", bg="white", lwd=2)
        
        # Plot linear prediction
        if(input$showModelLin){
            abline(modelLin, col = "#E41A1C", lwd = 2)
        }
        
        # Plot quadratic prediction
        if(input$showModelQdr){
            years <-  year_start:year_end
            model3lines <- predict(modelQdr, newdata = data.frame(
                Year = years, Year2 = years^2
            ))
            lines(year_start:year_end, model3lines, col = "#4DAF4A", lwd = 2)
        }
        
        # Plot broken linear prediction
        if(input$showModelBrk){
            model2lines <- predict(modelBrk, newdata = data.frame(
                Year = year_start:year_end, Yearsp = ifelse(year_start:year_end - input$year_break > 0, 
                                                            year_start:year_end - input$year_break, 0)
            ))
            lines(year_start:year_end, model2lines, col = "#377EB8", lwd = 2)
        }
        

    })

})
