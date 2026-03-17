# =======================================================
# EDUCATION INEQUALITY: FINAL SUBMISSION DASHBOARD
# Author: Patel Dhruv vasantkumar | MDS202524 | dhruvvp.mds2025@cmi.ac.in
# =======================================================

library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(DT)
library(RColorBrewer)
library(maps)
library(mapproj)

# --- 1. DATA PRE-PROCESSING ---
tryCatch({
  df <- read.csv("education_inequality.csv")
  names(df) <- tolower(names(df))
  
  # Smart Renaming to ensure code safety
  names(df)[grep("test_score", names(df))] <- "avg_test_score_percent"
  names(df)[grep("funding", names(df))] <- "funding_per_student_usd"
  names(df)[grep("teacher_ratio", names(df))] <- "student_teacher_ratio"
  names(df)[grep("low_income", names(df))] <- "percent_low_income"
  names(df)[grep("minority", names(df))] <- "percent_minority"
  names(df)[grep("internet", names(df))] <- "internet_access_percent"
  names(df)[grep("dropout", names(df))] <- "dropout_rate_percent"
  names(df)[grep("type", names(df))] <- "school_type"
  names(df)[grep("state", names(df))] <- "state"
  
  # Ensure Factors
  if("school_type" %in% names(df)) df$school_type <- as.factor(df$school_type)
  
  # State Aggregation for Map
  state_summary <- df %>%
    group_by(state) %>%
    summarise(
      avg_score = mean(avg_test_score_percent, na.rm=TRUE),
      school_count = n()
    ) %>%
    mutate(region = tolower(state))
  
}, error = function(e) {
  stop("CRITICAL ERROR: Please upload 'education_inequality.csv'.")
})

# --- 2. UI DESIGN ---
ui <- dashboardPage(
  title = "Education Data Analysis",
  skin = "blue",
  
  dashboardHeader(title = span(icon("chart-area"), " Education Data Analysis")),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("home")),
      menuItem("Data Description", tabName = "data_desc", icon = icon("table")),
      menuItem("Visualizations", icon = icon("chart-bar"), startExpanded = TRUE,
               menuSubItem("Geospatial Map", tabName = "viz_map"),
               menuSubItem("School Type Analysis", tabName = "viz_type"),
               menuSubItem("Financial Impact", tabName = "viz_finance"),
               menuSubItem("Socioeconomic Factors", tabName = "viz_socio"),
               menuSubItem("Correlation Matrix", tabName = "viz_corr")
      ),
      menuItem("Conclusion", tabName = "conclusion", icon = icon("file-alt"))
    ),
    hr(),
    div(style="padding: 15px;",
        h5("Global Filter", style="color:#b8c7ce; font-weight:bold;"),
        selectInput("school_filter", "Filter Type:",
                    choices = c("All Schools", as.character(unique(df$school_type))),
                    selected = "All Schools")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML('
            .content-wrapper {background-color: #ecf0f5;}
            .box-title {font-family: "Georgia", serif; font-weight: bold; font-size: 18px;}
            p {font-family: "Helvetica Neue", Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #333;}
            h2 {font-family: "Georgia", serif; font-weight: bold; color: #2c3e50;}
            li {font-size: 15px; margin-bottom: 8px;}
        '))),
    
    tabItems(
      # --- TAB 1: INTRODUCTION (Detailed) ---
      tabItem(tabName = "intro",
              fluidRow(box(width = 12, status = "primary", solidHeader = TRUE,
                           p(strong("Author:"), " Patel Dhruv vasantkumar | MDS202524 | dhruvvp.mds2025@cmi.ac.in"),
                           p(strong("Guide:"), " Prof. Sourish Das"),
                           p(strong("Course:"), " Visualization"),
                           h2("Analyzing Inequality in US Education"), 
                           tags$hr(),
                           p("Education is universally recognized as the bedrock of social mobility and economic development. However, the United States education system often faces scrutiny regarding equitable resource allocation. The debate centers on a fundamental question: Does increased financial investment ('Funding per Student') directly result in superior academic outcomes, or do structural factors like class size and socioeconomic background play a more dominant role?"),
                           p("This project, developed as part of the MSc Data Science curriculum at Chennai Mathematical Institute (CMI), leverages the 'Education Inequality' dataset to empirically test these hypotheses. By analyzing data from 1,000 schools across diverse states, we aim to separate statistical signal from noise and identify the true drivers of student success."),
                           p("Using advanced visualization techniques in R, this dashboard provides a multidimensional view of the educational landscape. We explore the 'Efficiency Gap' between Public, Private, and Charter schools, map geospatial performance clusters, and quantify the correlation between poverty levels and test scores."),
                           br(),
                           h4("Research Objectives:"),
                           tags$ul(
                             tags$li("To visualize geospatial disparities in educational performance across US states."), 
                             tags$li("To compare the resource-to-outcome efficiency of Public, Private, and Charter schools."),
                             tags$li("To statistically quantify the impact of funding, class size, and internet access on student grades.")),
                           br()
                           ))
      ),
      
      # --- TAB 2: DATA DESCRIPTION (Detailed Dictionary) ---
      tabItem(tabName = "data_desc",
              fluidRow(box(width = 12, title = "Data Dictionary & Attribute Overview", status = "info", solidHeader = TRUE,
                           p("The analysis is based on a dataset of 1,000 schools. Below is a detailed description of the variables used."),
                           tags$table(class = "table table-striped table-bordered",
                                      tags$thead(tags$tr(tags$th("Attribute Name"), tags$th("Data Type"), tags$th("Detailed Description"))),
                                      tags$tbody(
                                        tags$tr(tags$td("id"), tags$td("Integer"), tags$td("Unique identifier for each school entry.")),
                                        tags$tr(tags$td("school_name"), tags$td("String"), tags$td("Name of the school (synthetically generated).")),
                                        tags$tr(tags$td("state"), tags$td("Categorical"), tags$td("U.S. state where the school is located.")),
                                        tags$tr(tags$td("school_type"), tags$td("Categorical"), tags$td("Type of institution: Public, Private, or Charter.")),
                                        tags$tr(tags$td("grade_level"), tags$td("Categorical"), tags$td("Primary level served by the school: Elementary, Middle, or High.")),
                                        tags$tr(tags$td("funding_per_student_usd"), tags$td("Numeric"), tags$td("Annual funding per student in U.S. dollars.")),
                                        tags$tr(tags$td("avg_test_score_percent"), tags$td("Numeric"), tags$td("Average student performance score (0–100%).")),
                                        tags$tr(tags$td("student_teacher_ratio"), tags$td("Numeric"), tags$td("Average number of students per teacher.")),
                                        tags$tr(tags$td("percent_low_income"), tags$td("Numeric"), tags$td("Percentage of students from low-income households.")),
                                        tags$tr(tags$td("percent_minority"), tags$td("Numeric"), tags$td("Percentage of students from minority backgrounds.")),
                                        tags$tr(tags$td("internet_access_percent"), tags$td("Numeric"), tags$td("Percentage of students with internet access at school.")),
                                        tags$tr(tags$td("dropout_rate_percent"), tags$td("Numeric"), tags$td("Annual dropout rate among students (as a percentage)."))
                                      ))
              )),
              fluidRow(box(width = 12, title = "Raw Data Explorer", status = "primary", 
                           p("Use the search bar on the right to find specific schools or filter columns."),
                           DTOutput("raw_table")))
      ),
      
      # --- TAB 3: MAP ---
      tabItem(tabName = "viz_map",
              h2("Geospatial Analysis"),
              fluidRow(box(width = 9, height = "600px", title = "US Average Scores by State", status = "primary", solidHeader = TRUE,
                           plotlyOutput("map_plot", height = "540px")),
                       box(width = 3, title = "Top Performing States", status = "warning", 
                           p("This table ranks states based on the aggregated average test score of all schools within their jurisdiction."),
                           tableOutput("state_rank_table")))
      ),
      
      # --- TAB 4: SCHOOL TYPE (Histogram Restored) ---
      tabItem(tabName = "viz_type",
              h2("School Type Structure Analysis"),
              fluidRow(
                box(width = 6, title = "School Type Composition", status = "warning", solidHeader = TRUE,
                    plotlyOutput("pie_plot_type", height = "350px"),
                    p("This chart shows the proportion of schools in the dataset belonging to each category.")),
                
                box(width = 6, title = "Frequency Distribution", status = "info", solidHeader = TRUE,
                    plotlyOutput("hist_plot", height = "350px"),
                    p("The histogram visualizes the frequency distribution of test scores. Note the overlapping areas which indicate performance similarities."))
              ),
              fluidRow(
                box(width = 12, title = "Score Distribution Comparison", status = "success", solidHeader = TRUE,
                    plotlyOutput("box_plot_type", height = "400px"),
                    p("The Box Plot provides a statistical summary (Median, Quartiles). this plot reveals that Private schools, Charter schools, and Public schools have nearly identical median scores."))
              )
      ),
      
      # --- TAB 5: FINANCE (Three Lines Fixed) ---
      tabItem(tabName = "viz_finance",
              h2("Financial Impact Analysis"),
              fluidRow(
                box(width = 9, title = "Funding vs. Scores Scatter Plot", status = "primary", solidHeader = TRUE,
                    plotlyOutput("scatter_finance", height = "500px")),
                
                box(width = 3, title = "Insight: The 'Three Lines'", status = "warning",
                    h4("Trend Analysis"),
                    p("This scatter plot includes three distinct regression lines, one for each school type."),
                    tags$ul(
                      tags$li("If lines are parallel, the effect of funding is similar across types."),
                      tags$li("A steeper slope indicates a higher 'Return on Investment' for that school type."),
                      tags$li("Notice how the lines are relatively flat, suggesting global inelasticity.")
                    ))
              )
      ),
      
      # --- TAB 6: SOCIOECONOMIC ---
      tabItem(tabName = "viz_socio",
              h2("Socioeconomic Factors"),
              fluidRow(
                box(width = 6, title = "Income vs. Score", status = "danger", solidHeader = TRUE,
                    plotlyOutput("scatter_income", height = "400px"),
                    p("Investigating the link between poverty levels and academic performance.")),
                
                box(width = 6, title = "Dropout Density", status = "primary", solidHeader = TRUE,
                    plotlyOutput("density_dropout", height = "400px"),
                    p("A density plot showing the distribution of dropout rates. Higher peaks indicate where most schools are clustered."))
              )
      ),
      
      # --- TAB 7: CORRELATION (Numbers Added) ---
      tabItem(tabName = "viz_corr",
              h2("Statistical Correlation Matrix"),
              fluidRow(
                box(width = 9, title = "Pearson Correlation Heatmap", status = "primary", solidHeader = TRUE,
                    plotlyOutput("heatmap_plot", height = "600px")),
                
                box(width = 3, title = "Legend & Interpretation", status = "info",
                    tags$ul(
                      tags$li(span("Blue (+1.0)", style="color:blue; font-weight:bold;"), ": Strong Positive Correlation"),
                      tags$li(span("White (0.0)", style="color:gray; font-weight:bold; border:1px solid #ccc;"), ": No Relationship"),
                      tags$li(span("Red (-1.0)", style="color:red; font-weight:bold;"), ": Strong Negative Correlation")
                    ),
                    br(),
                    p("Note: The text numbers inside each box represent the exact correlation coefficient (r). A value of 0.02 is statistically negligible."))
              )
      ),
      
      # --- TAB 8: CONCLUSION (Detailed) ---
      tabItem(tabName = "conclusion",
              fluidRow(box(width = 12, status = "success", solidHeader = TRUE,
                           h2("Final Conclusions & Recommendations"), tags$hr(),
                           
                           h4("1. Summary of Findings"),
                           p("The comprehensive analysis of the Education Inequality dataset yields three critical insights:"),
                           tags$ul(
                             tags$li(strong("Funding Inelasticity:"), " Contrary to the hypothesis that 'money buys grades,' our Financial Impact Analysis reveals a flat regression slope across all three school types. This suggests that simply increasing the 'funding_per_student_usd' without structural reform has a negligible impact on 'avg_test_score_percent'."),
                             tags$li(strong("The Private School Anomaly:"), " While the global trend is flat, the Box Plot Analysis indicates that Private schools maintain a consistently higher median score and lower variance. This suggests that Private schools are more effective at mitigating the risk of low performance, likely due to selection mechanisms."),
                             tags$li(strong("Weak Socioeconomic Signal:"), " Surprisingly, variables like 'percent_low_income' showed a weaker-than-expected negative correlation with test scores in this specific dataset. This points to a high-variance environment where some low-income schools are successfully outperforming expectations.")
                           ),
                           
                           br(),
                           h4("2. Policy Implications"),
                           p("Based on these data-driven findings, stakeholders should pivot from 'Blanket Funding' strategies to 'Targeted Structural' interventions. Since raw funding shows diminishing returns, investments should instead focus on reducing the 'student_teacher_ratio' and improving 'internet_access_percent', which act as structural enablers."),
                           
                           br(),
                           h4("3. Limitations & Future Scope"),
                           p("It is important to note that this analysis is based on a snapshot dataset of 1,000 schools. Future iterations should incorporate longitudinal data (tracking schools over time) and qualitative metrics (teacher experience years, curriculum type) to capture the unobserved variance seen in the Public school sector.")
              )))
    )
  )
)


# --- 3. SERVER LOGIC ---
server <- function(input, output) {
  
  # Reactive Filter
  filtered_data <- reactive({
    if(input$school_filter == "All Schools") { df } else { df %>% filter(school_type == input$school_filter) }
  })
  
  # Raw Table
  output$raw_table <- renderDT({ datatable(df, options = list(pageLength = 10, scrollX = TRUE)) })
  
  # Map
  output$map_plot <- renderPlotly({
    us_map <- map_data("state")
    map_viz <- state_summary %>% right_join(us_map, by = "region")
    p <- ggplot(map_viz, aes(x=long, y=lat, group=group, fill=avg_score, text=paste("State:", toupper(region), "<br>Score:", round(avg_score,1)))) +
      geom_polygon(color="white", size=0.2) + scale_fill_gradient(low="#ffcccc", high="#003366") + theme_void() + labs(fill="Score")
    ggplotly(p, tooltip="text")
  })
  output$state_rank_table <- renderTable({ state_summary %>% arrange(desc(avg_score)) %>% select(state, avg_score) %>% head(10) })
  
  # --- SCHOOL TYPE PLOTS ---
  output$pie_plot_type <- renderPlotly({
    counts <- filtered_data() %>% count(school_type)
    plot_ly(counts, labels = ~school_type, values = ~n, type = 'pie',
            textposition = 'inside', textinfo = 'label+percent',
            marker = list(colors = brewer.pal(3, "Set2")))
  })
  
  # THE HISTOGRAM YOU REQUESTED
  output$hist_plot <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = avg_test_score_percent, fill = school_type)) +
      geom_histogram(binwidth = 5, color = "white", alpha = 0.8, position = "identity") +
      scale_fill_brewer(palette = "Set2") +
      theme_minimal() + labs(x="Test Score (%)", y="Count")
    ggplotly(p) %>% layout(barmode = "overlay")
  })
  
  output$box_plot_type <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = school_type, y = avg_test_score_percent, fill = school_type)) +
      geom_boxplot(alpha = 0.7) + scale_fill_brewer(palette = "Pastel1") + theme_minimal() + labs(x="", y="Score (%)")
    ggplotly(p)
  })
  
  # --- FINANCE SCATTER (FIXED: 3 LINES) ---
  output$scatter_finance <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x=funding_per_student_usd, y=avg_test_score_percent, color=school_type)) +
      geom_point(alpha=0.5, size=2) + 
      # This adds the 3 distinct regression lines
      geom_smooth(method="lm", se=FALSE, size=1.5) +
      scale_color_brewer(palette="Set1") + 
      theme_minimal() + labs(x="Funding ($)", y="Score (%)")
    ggplotly(p)
  })
  
  # --- SOCIO PLOTS ---
  output$scatter_income <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x=percent_low_income, y=avg_test_score_percent, color=school_type)) +
      geom_point(alpha=0.5) + theme_minimal() + labs(x="Low Income (%)", y="Score (%)")
    ggplotly(p)
  })
  output$density_dropout <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x=dropout_rate_percent, fill=school_type)) +
      geom_density(alpha=0.5) + theme_minimal() + labs(x="Dropout Rate (%)", y="Density")
    ggplotly(p)
  })
  
  # --- HEATMAP (FIXED: TEXT NUMBERS ADDED) ---
  output$heatmap_plot <- renderPlotly({
    nums <- filtered_data() %>% select_if(is.numeric)
    corr_mat <- round(cor(nums, use = "complete.obs"), 2) # Round to 2 decimals
    
    fixed_colors <- list(c(0, "#b2182b"), c(0.5, "#ffffff"), c(1, "#2166ac"))
    
    plot_ly(x = colnames(corr_mat), y = rownames(corr_mat), z = corr_mat,
            type = "heatmap",
            colorscale = fixed_colors,
            zmin = -1, zmax = 1) %>%
      add_annotations(
        x = rep(colnames(corr_mat), each = nrow(corr_mat)),
        y = rep(rownames(corr_mat), times = ncol(corr_mat)),
        text = as.character(as.vector(corr_mat)), # This adds the numbers!
        showarrow = FALSE,
        font = list(color = "black")
      ) %>%
      layout(xaxis = list(tickangle = 45))
  })
}

shinyApp(ui, server)