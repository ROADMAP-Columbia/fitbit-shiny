#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
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


#list all the files
temp = list.files(pattern = "CLBP*")
df <- read_excel("Data/Imputed_Fitbit_by_Minute.xlsx", col_names = T)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    sliderValues <- reactive({
        df <- read_excel("Data/Imputed_Fitbit_by_Minute.xlsx", col_names = T) %>%
            mutate(Treatment        = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)])
        
        summary <- df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps = sum(Steps))
        
        fit <- gls(Steps ~ Treatment, correlation = corAR1(form=~1),
                   subset = which(Treatment != "Baseline"),
                   control = list(singular.ok = TRUE),
                   na.action = na.omit, data = summary)
        
            data.frame(
                Output = c("Total steps averaged during Usual Care",
                           "Total steps averaged increased during Yoga",
                           "Total steps averaged increased during Massage"),
                Estimate = c(round(summary(fit)$tTable[, 1], 2)),
                pvalue     = c("-", round(summary(fit)$tTable[-1, 4], 2)))
    })
    
    
    summ <- reactive({
        df <- read_excel("Data/Imputed_Fitbit_by_Minute.xlsx", col_names = T) %>%
            mutate(Treatment        = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)])
        
         df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps = sum(Steps_impute))
        

    })
    
    summ1 <- reactive({
        df <- read_excel("Data/Imputed_Fitbit_by_Minute.xlsx", col_names = T) %>%
            mutate(Treatment        = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)])
        
        df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps = sum(Steps_impute)) %>%
            group_by(Treatment) %>% 
            summarise(Steps = mean(Steps))
        
    })
    
    
    # Show the values in an HTML table ----
    output$values <- renderDataTable({
        sliderValues() 
    }, extensions = 'Buttons', 
    options = list(
        initComplete = JS(
            "function(settings, json) {",
            "$(this.api().table().header()).css({'background-color': '#000', 'color': '#fff'});",
            "}"),
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel', 'pdf', 'print')), rownames= FALSE)
    
    output$plot <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Date, y = Steps, color = Treatment)) + 
                    geom_path(aes(group = 1)) +
                    geom_point() +
                    theme_gdocs()))
        
    })
    
    output$plot1 <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ1(), aes(x = Treatment, y = Steps, fill = Treatment)) + 
                    geom_bar(stat="identity") +
                    theme_gdocs()))
        
    })

})
