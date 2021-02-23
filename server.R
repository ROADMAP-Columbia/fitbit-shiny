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
data <- read_excel("Data/Imputed_Fitbit_by_Minute.xlsx", col_names = T)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    sliderValues <- reactive({
        df <- data %>%
            mutate(Treatment         = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)])
        
        summary <- df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Steps), .groups = 'drop')
        
        fit <- gls(model       = Steps ~ Treatment, 
                   correlation = corAR1(form=~1),
                   subset      = which(Treatment != "Baseline"),
                   control     = list(singular.ok = TRUE),
                   na.action   = na.omit, 
                   data        = summary)
        
            data.frame(
                Output        = c("Total steps averaged during Usual Care",
                                  "Total steps averaged increased during Yoga",
                                  "Total steps averaged increased during Massage"),
                Estimate      = c(round(summary(fit)$tTable[, 1], 2)),
                `p-value`     = c("-", round(summary(fit)$tTable[-1, 4], 2)))
    })
    
    
    summ <- reactive({
        df <- data %>%
            mutate(Treatment        = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)]) 
        
         df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Steps_impute), 
                      HR      = median(`Heart Rate`, na.rm = T),
                      .groups = 'drop') %>%
            mutate(group      = 1)
        

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
                ggplot(data = summ(), aes(x = Date, y = Steps)) + 
                    geom_point() +
                    geom_line(aes(color = Treatment, group = 1)) +
                    theme_gdocs()))
        
    })
    
    output$plot1 <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Treatment, y = Steps, fill = Treatment)) + 
                    geom_boxplot() +
                    theme_gdocs()))
        
    })
    
    output$plot2 <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Treatment, y = HR, fill = Treatment)) + 
                    geom_boxplot() +
                    theme_gdocs()))
        
    })

})
