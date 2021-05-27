#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(shiny)
library(bslib)
library(readxl)
library(nlme)
library(knitr)
library(DT)
library(ggplot2)
library(ggthemes)
library(plotly)



# Define UI for application that draws a histogram
shinyUI(fluidPage(
    theme = bs_theme(fg = "#00008B", bootswatch = "sketchy", 
                     bg = "#FFFFFF"),
    # Application title
    titlePanel("N-of-1 Trial Fitbit Data"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            
            selectInput('dataset', h5('Choose a patient:'), 
                        choices = c("Patient 1" = "1",
                                    "Patient 2" = "2", 
                                    "Patient 3" = "3", 
                                    "Patient 4" = "4", 
                                    "Patient 5" = "5", 
                                    "Patient 6" = "6", 
                                    "Patient 7" = "7", 
                                    "Patient 8" = "8",
                                    "Patient 9" = "9", 
                                    "Patient 10" = "10", 
                                    "Patient 11" = "11", 
                                    "Patient 12" = "12", 
                                    "Patient 13" = "13", 
                                    "Patient 14" = "14", 
                                    "Patient 15" = "15", 
                                    "Patient 16" = "16",
                                    "Patient 17" = "17", 
                                    "Patient 18" = "18",
                                    "Patient 19" = "19", 
                                    "Patient 20" = "20", 
                                    "Patient 21" = "21", 
                                    "Patient 22" = "22",
                                    "Patient 23" = "23", 
                                    "Patient 24" = "24",
                                    "Patient 25" = "25", 
                                    "Patient 26" = "26")),
            
            selectInput('impute', h5('Use imputed steps data?'), 
                        choices = c("No" = "0",
                                    "Yes" = "1")), 
            
            hr(),
            
            radioButtons('format', 'Document format', c('PDF', 'HTML', 'Word'),
                         inline = TRUE),
            
            downloadButton('downloadReport', label = "Download Report")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            h5("AR(1) model analysis with treatment effects"),
            dataTableOutput("values"),
            
            h5("Forest plot of treatment comparison"),
            plotlyOutput("fp"), 
            
            h5("Number of steps per day"),
            plotlyOutput("plot"), 
            
            h5("Distribution of total number of steps per day by treatment"),
            plotlyOutput("plot1"), 
            
            h5("Distribution of median heart rate by treatment"),
            plotlyOutput("plot2")
            
        )
    )
))
