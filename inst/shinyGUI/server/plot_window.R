render_plot_window <- function() { renderUI({
    fluidPage(
        # This window is managed outside of shiny in plotwindow.js
        tags$head(tags$script(src = "plotwindow.js")),
        p("Hello world!")
        
        
    )
        
})}