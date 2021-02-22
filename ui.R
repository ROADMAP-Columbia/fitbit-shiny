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
    theme = bs_theme(version = 4, bootswatch = "minty"),
    # Application title
    titlePanel("N-of-1 Trial Fitbit Data"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput('dataset', h5('Choose a dataset:'), 
                        choices = c("Patient 1" = "1",
                                    "Patient 2" = "2", 
                                    "Patient 3" = "3", 
                                    "Patient 4" = "4", 
                                    "Patient 5" = "5")),
            
            # Copy the line below to make a set of radio buttons
            radioButtons('impute', label = h5('Use imputed data?'),
                         choices = list("Yes" = "1", "No" = "0"), 
                         selected = "0")
            
            
        ),

        # Show a plot of the generated distribution
        mainPanel(
            h5("AR(1) model analysis with treatment effects"),
            dataTableOutput("values"),
            
            h5("Number of steps per day"),
            plotlyOutput("plot"), 
            
            h5("Distribution of total number of steps per day by treatment"),
            plotlyOutput("plot1"), 
            
            h5("Distribution of median heart rate by treatment"),
            plotlyOutput("plot2")
            
        )
    )
))
