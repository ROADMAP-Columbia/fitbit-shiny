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
library(knitr)
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
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)]) %>%
            mutate(Impute            = as.numeric(input$impute)) %>%
            mutate(Final_Steps       = ifelse(Impute == 1, Steps_impute, Steps))
        
        summary <- df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Final_Steps), .groups = 'drop')
        
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
    
    fp <- reactive({
        df <- data %>%
            mutate(Treatment         = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)]) %>%
            mutate(Impute            = as.numeric(input$impute)) %>%
            mutate(Final_Steps       = ifelse(Impute == 1, Steps_impute, Steps))
        
        summary <- df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Final_Steps), .groups = 'drop')
        
        fit1 <- gls(Steps ~ Treatment, correlation = corAR1(form=~1), data = summary,
                    control = list(singular.ok = TRUE), na.action = na.omit, 
                    subset = which(Treatment != "Baseline"))
        
        df <- df %>%
            mutate(Treatment = factor(Treatment, levels = c("Baseline", "Yoga", "Massage", "Usual Care")))
        
        summary <- df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Steps), .groups = 'drop')
        
        fit2 <- gls(Steps ~ Treatment, correlation = corAR1(form=~1), data = summary,
                    control = list(singular.ok = TRUE), na.action = na.omit, 
                    subset = which(Treatment != "Baseline"))
        
        
        fp <- data.frame(label = c("Yoga vs Usual Care", "Massage vs Usual Care", "Massage vs Yoga"), 
                         mean  = c(intervals(fit1)$coef[2, 2],  intervals(fit1)$coef[3, 2],  intervals(fit2)$coef[2, 2]), 
                         lower = c(intervals(fit1)$coef[2, 1], intervals(fit1)$coef[3, 1], intervals(fit2)$coef[2, 1]), 
                         upper = c(intervals(fit1)$coef[2, 3], intervals(fit1)$coef[3, 3], intervals(fit2)$coef[2, 3]))
        
    })
    
    summ <- reactive({
        df <- data %>%
            mutate(Treatment        = factor(Treatment, levels = c("Baseline", "Usual Care", "Yoga", "Massage"))) %>%
            filter(`Participant ID` == unique(`Participant ID`)[as.numeric(input$dataset)]) %>%
            mutate(Impute            = as.numeric(input$impute)) %>%
            mutate(Final_Steps       = ifelse(Impute == 1, Steps_impute, Steps))
        
         df %>%
            group_by(Date, Treatment) %>% 
            filter(Treatment != "Baseline") %>%
            summarise(Steps   = sum(Final_Steps), 
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
    
    output$fp <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = fp(), aes(x     = label, 
                                        y     = mean, 
                                        ymin  = lower, 
                                        ymax  = upper)) +
                    geom_pointrange() + 
                    geom_hline(yintercept = 0, lty = 2) +  # add a dotted line at x=1 after flip
                    coord_flip() + # flip coordinates (puts labels on y axis)
                    xlab("") + ylab("Mean difference (95% CI)")  +
                    theme_gdocs()))
        
    })
    
    output$plot <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Date, y = Steps)) + 
                    geom_point() +
                    ylab("Total Steps")  +
                    geom_line(aes(color = Treatment, group = 1)) +
                    theme_gdocs()))
        
    })
    
    output$plot1 <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Treatment, y = Steps, fill = Treatment)) + 
                    geom_boxplot() +
                    ylab("Total Steps (per day)")  +
                    theme_gdocs()))
        
    })
    
    output$plot2 <- renderPlotly({
        print(
            ggplotly(
                ggplot(data = summ(), aes(x = Treatment, y = HR, fill = Treatment)) + 
                    geom_boxplot() +
                    ylab("Median Heart Rate")  +
                    theme_gdocs()))
        
    })
    
    output$downloadReport <- downloadHandler(
        filename = function() {
            paste('my-report', sep = '.', switch(
                input$format, PDF = 'pdf', HTML = 'html', Word = 'docx'
            ))
        },
        
        content = function(file) {
            src <- normalizePath('report.Rmd')
            
            owd <- setwd(tempdir())
            on.exit(setwd(owd))
            file.copy(src, 'report.Rmd', overwrite = TRUE)
            
            library(rmarkdown)
            out <- render('report.Rmd', switch(
                input$format,
                PDF = pdf_document(), HTML = html_document(), Word = word_document()
            ))
            file.rename(out, file)
        }
    )

})
