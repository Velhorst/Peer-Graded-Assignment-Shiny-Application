#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(RColorBrewer)
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


# # locate sea level data
# rlrdata_fp <- function(id){
#     # return file path of the sea level data
#     file.path(datadir,'rlr_annual/data', sprintf("%d.rlrdata",id))
# }
# rlrinfo_fp <- function(id){
#     # return file path of the local reference level info
#     file.path(datadir,'rlr_annual/RLR_info', sprintf("%d.txt",id))
# }
# 
# rlr_correction_df <- function(id){
#     # return dataframe containing the RLR correction of a given station (identified by id)
#     # correction information is obtained from the rlr info file
#     # The dataframe contains three columns: year_start, year_end, and correction [mm]
#     
#     fp <- rlrinfo_fp(id)
#     linestr <- readLines(con <- file(fp))
#     close(con)
#     records <- strsplit(linestr,split="<br>")
#     words <- sapply(records, strsplit,split=" ")
#     
#     correction_df <- data.frame()
#     for(ix in 1:length(words)){
#         if(words[[ix]][1]=="Add"){
#             if('onwards' %in% words[[ix]]){
#                 year_start <- as.integer(words[[ix]][6])
#                 year_end <- as.integer(format(Sys.Date(), "%Y"))
#                 correction <- as.numeric(strsplit(words[[ix]][2], "m")[1])*1000. # convert to mm
#             } else {
#                 years = strsplit(words[[ix]][6], "-")
#                 year_start <- as.integer(years[[1]][1])
#                 year_end <- as.integer(years[[1]][2])
#                 correction <- as.numeric(strsplit(words[[ix]][2], "m")[1])*1000. # convert to mm
#             }
#             df_tmp = data.frame("year_start"= year_start,
#                                 "year_end"= year_end,
#                                 "correction"= correction)
#             correction_df <- rbind(correction_df,df_tmp)
#         }
#     }
#     correction_df
# }
# 
# getCorrection <- function(year, correction_df) {
#     # return the correction of a given year, based on the correction dataframe
#     tmp <- correction_df %>%
#         filter(year <= year_end, year >= year_start)
#     return(tmp$correction)
# }
# 
# # NAP_convert
# rlr2nap <- function(df, id){
#     # Add a column "NAP" [mmm] to the sea level dataframe df
#     # NAP  is the national reference level in the Netherlands
#     # Conversion from RLR to NAP is based on RLR-info of a given station (identified by id)
#     correction_df <- rlr_correction_df(id)
#     RLR_correction <- sapply(as.vector(df$Year), getCorrection, correction_df)
#     return(mutate(df, NAP = RLR - RLR_correction))
# }
# 
# 
# # Create dataframe of all annual dutch sea levels
# # select station id's
# NLids = stations.NL$id
# # loop through all stations and merge data into one dataframe
# RLRdata.NL = data.frame()
# for(id in NLids){
#     station <- stations.NL[which(id==stations.NL$id),]
#     
#     df_tmp <- read.table(rlrdata_fp(id), sep =";", col.names= c("Year", "RLR", "Quality", "NUll")) %>% 
#         merge(station) %>% # add station information to dataframe
#         rlr2nap(id) # Add NAPto dataframe
#     
#     RLRdata.NL <- rbind(RLRdata.NL,df_tmp)
# }
# write.csv(RLRdata.NL, "data/RLRdataNL.csv")

RLRdata.NL <- read.csv("data/RLRdataNL.csv")

# server calculation ------------------------------------------------------

year_start = 1900
year_end = 2050
year_break = 1993

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

        
    output$statPlot <- renderPlot({
        
        statname <- input$stationname
        stationdata <- RLRdata.NL[which(statname == RLRdata.NL$name & RLRdata.NL$Year >year_start),]
        
        modelLin <- lm(NAP ~ Year, data = stationdata)
        
        stationdata$Yearsp <- ifelse(stationdata$Year - year_break > 0, stationdata$Year - year_break, 0)
        modelBrk <- lm(NAP ~ Yearsp + Year, data = stationdata)
        
        stationdata$Year2 <- stationdata$Year^2
        modelQdr <- lm(NAP ~ Year2 + Year, data = stationdata)
        
        
        plot(RLRdata.NL$Year, RLRdata.NL$NAP,
             xlab = "Year", ylab = "Water level [mm] above NAP", 
             main = paste("Station: ", input$stationname),
             bty = "n", pch = 16,
             xlim = c(year_start, year_end), ylim = c(-300, 300),col="grey")
        
        points(stationdata$Year, stationdata$NAP, pch=16 , col="black", bg="white", lwd=2)
        
        
        if(input$showModelLin){
            abline(modelLin, col = "#E41A1C", lwd = 2)
        }
        
        
        if(input$showModelBrk){
            model2lines <- predict(modelBrk, newdata = data.frame(
                Year = year_start:year_end, Yearsp = ifelse(year_start:year_end - year_break > 0, 
                                                            year_start:year_end - year_break, 0)
            ))
            lines(year_start:year_end, model2lines, col = "#377EB8", lwd = 2)
        }
        
        
        if(input$showModelQdr){
            years <-  year_start:year_end
            model3lines <- predict(modelQdr, newdata = data.frame(
                Year = years, Year2 = years^2
            ))
            lines(year_start:year_end, model3lines, col = "#4DAF4A", lwd = 2)
        }

    })

})
