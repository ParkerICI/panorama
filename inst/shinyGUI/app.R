
ui <- navbarPage("SCAFFoLD",
    header = list(tags$head(tags$script(src = "d3-scale.min.js")),
        tags$head(tags$script(src = "d3-interpolate.min.js")),
        tags$head(tags$script(src = "d3-array.min.js")),
        tags$head(tags$script(src = "d3-color.min.js")),
        tags$head(tags$script(src = "pixi.min.js")),
        tags$head(tags$script(src = "pixigraph.js")),
        tags$head(tags$script(src = "shinyoutputbindings.js")),
        singleton(tags$head(tags$link(rel = 'stylesheet', type = 'text/css', href = 'graph.css')))
    ),
    tabPanel("Map exploration", 
             uiOutput("graphUI"),
             uiOutput("plotWindow"))
    #tabPanel("Run SCAFFoLD Analysis", uiOutput("analysisUI")),
    #tabPanel("Run clustering", uiOutput("clusteringUI")),
    #tabPanel("Map dataset", uiOutput("mappingUI")),
    #tabPanel("Unsupervised map", uiOutput("unsupervisedUI")),
    #tabPanel("Run Citrus", uiOutput("citrusUI")),
    #tabPanel("Edit SCAFFoLD file", uiOutput("editingUI"))
)



server <- function(input, output, session) {
    options(shiny.error=traceback)
    app.dir <- file.path(system.file(package = "scaffold2"), "shinyGUI")
    
    observe({
        
        query <- parseQueryString(session$clientData$url_search)
        
        if (is.null(query[['plot']])) {
            if(exists(".ScaffoldWorkingDir"))
                working.directory <- .ScaffoldWorkingDir
            else
                working.directory <- dirname(file.choose())

            source(file.path(app.dir, "server", "tab_graph.R"), local = T)$value

            output$graphUI <- render_graph_ui(working.directory, input, output, session)
        } else {
            
            source(file.path(app.dir, "server", "plot_window.R"), local = T)$value
            
            output$plotWindow <- render_plot_window()
        }
    })
}

shinyApp(ui = ui, server = server)