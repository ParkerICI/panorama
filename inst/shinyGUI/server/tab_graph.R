reactiveNetwork <- function (outputId) {
    HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"></div>", sep=""))
}

visControl <- function(outputId) {
    HTML(paste("<div id=\"", outputId, "\" class=\"shiny-vis-control\"></div>", sep=""))
}

row <- function(...) {
    tags$div(class="row", ...)
}

col <- function(width, ...) {
    tags$div(class=paste0("span", width), ...)
}


render_graph_ui <- function(working.directory, ...) { renderUI({
fluidPage(
    tags$head(tags$script(src = "mainwindow.js")),
    sidebarPanel(
        selectInput("graphui_display_edges", "Display edges:", choices = c("All", "Highest scoring", "Inter cluster", "To landmark"), width = "100%"),
        selectInput("graphui_node_color_attr", "Nodes color:", choices = c("Default"), width = "100%"),
        fluidRow(
                column(6,
                       selectInput("graphui_stats_type", "Stats type", choices = c("Ratio", "Difference"))
                ),
                column(6,
                       selectInput("graphui_stats_relative_to", "Stats relative to:", choices = c("Absolute"), width = "100%")
                )
            ),
            
        selectInput("graphui_color_number", "Number of colors", choices = c(2,3)),
        fluidRow(
            column(6,
                   colourpicker::colourInput("graphui_color_under", "Under:", value = "#FFFF00")
            ),
            column(6,
                   colourpicker::colourInput("graphui_color_over", "Over:", value = "#0000FF")
            )
        ),
        fluidRow(
            column(4,
                   colourpicker::colourInput("graphui_color_min", "Min:", value = "#E7E7E7")
            ),
            column(4,
                   conditionalPanel(
                       condition = "input.graphui_color_number == 3",
                       colourpicker::colourInput("graphui_color_mid", "Mid:", value = "#E7E7E7")
                   )
            ),
            column(4,
                   colourpicker::colourInput("graphui_color_max", "Max:", value = "#E71601")
            )
        ),
        conditionalPanel(
            condition = "input.graphui_color_number == 3",
            sliderInput("graphui_color_scale_mid", "Color scale midpoint", min = 0.0, max = 5.0, value = 2.5, round = -2, step = 0.1, sep = "")
        ),
        sliderInput("graphui_color_scale_lim", "Color scale limits", min = 0.0, max = 5.0, value = c(0.0, 5.0), round = -2, step = 0.1, sep = ""),
        fluidRow(
            column(6,
                   numericInput("graphui_color_scale_min", "Color scale min:", 0)
            ),
            column(6,
                   numericInput("graphui_color_scale_max", "Color scale max:", 5)
            )
        ),
        fluidRow(
            column(6,
                   selectInput("graphui_node_size", "Nodes size:", choices = c("Proportional", "Default"), width = "100%")
            ),
            column(6,
                   numericInput("graphui_min_node_size", "Minimum node size", 2, min = 0, max = 1000)
            )
        ),
        fluidRow(
            column(6,
                   numericInput("graphui_max_node_size", "Maximum node size", 80, min = 0, max = 1000)
            ),
            column(6,
                   numericInput("graphui_landmark_node_size", "Landmark node size", 40, min = 0, max = 1000)
            )
        ),
        fluidRow(
            column(4, 
                selectInput("graphui_plot_type", "Plot type:", choices = c("Density", "Boxplot", "Scatterplot"), width = "100%")
            ),
            column(4,
                selectInput("graphui_facet_by", "Facet by:", choices = c("Sample", "Variable"), width = "100%")
            ),
            column(4, 
                checkboxInput("graphui_pool_clusters_data", "Pool clusters data", value = FALSE),
                checkboxInput("graphui_pool_samples_data", "Pool samples data", value = FALSE),
                actionButton("graphui_plot_clusters", "Plot selected clusters")
            )
        ),
        selectInput("graphui_markers_to_plot", "Markers to plot in cluster view:", choices = c(""), multiple = T, width = "100%"),
        selectizeInput("graphui_samples_to_plot", "Samples to plot", choices = c(""), multiple = T, width = "100%")
    ),
    
    
    mainPanel(
        fluidRow(
            column(6,
                selectizeInput("graphui_selected_graph", "Choose a graph:", choices = c("", list.files(path = working.directory, pattern = "*.graphml$")), width = "100%")
            ),
            column(6,
                selectizeInput("graphui_active_sample", "Active sample", choices = c("All"), width = "100%")     
            )
            
        ),
        fluidRow(
            column(12,
                visControl("graphui_viscontrol"),
                reactiveNetwork(outputId = "graphui_mainnet")
            )
        ),
        fluidRow(
            column(4,
                actionButton("graphui_reset_graph_position", "Reset graph position")
            ),
            column(4,
                actionButton("graphui_toggle_landmark_labels", "Toggle landmark labels")       
            ),
            column(4,
                actionButton("graphui_toggle_cluster_labels", "Toggle cluster labels") 
            )
            #column(3,
            #    actionButton("graphui_export_selected_clusters", "Export selected clusters")
            #)
        ),
        fluidRow(
            column(12,
                plotOutput("graphui_plot")
            )
        )
    ))

})}

get_graph <- reactive({
    if(!is.null(input$graphui_selected_graph) && input$graphui_selected_graph != "") {
        G <- igraph::read.graph(file.path(working.directory, input$graphui_selected_graph), format = "graphml")
        return(G)
    } else {
        return(NULL)
    }
    
})


observe({
    G <- get_graph()
    if(!is.null(G)) {
        attrs <- scaffold2:::get_numeric_vertex_attributes(G)
        
        isolate({
            sel.marker <- NULL
            if(input$graphui_node_color_attr %in% attrs)
                sel.marker <- input$graphui_node_color_attr
            else
                sel.marker <- "Default"
            markers.for.plotting <- attrs[attrs != "popsize"]
            updateSelectInput(session, "graphui_node_color_attr", choices = c("Default", attrs), selected = sel.marker)
            updateSelectInput(session, "graphui_markers_to_plot", choices = markers.for.plotting, selected = markers.for.plotting)
            sample.names <- scaffold2:::get_sample_names(G)
            updateSelectInput(session, "graphui_active_sample", choices = c("All", sample.names),
                                selected = input$graphui_active_sample)
            updateSelectizeInput(session, "graphui_samples_to_plot", choices = sample.names)
            updateSelectInput(session, "graphui_stats_relative_to", choices = c("Absolute", sample.names),
                                selected = input$graphui_stats_relative_to)
        })
    }
})


output$graphui_mainnet <- reactive({
    G <- get_graph()
    ret <- NULL
    
    if(!is.null(G)) 
        ret <- scaffold2:::graph_to_json(G, input$graphui_display_edges)
    
    return(ret)
})

get_node_size_attr <- reactive({
    G <- get_graph()
    
    if(is.null(G))
        return(NULL)
    else {
        if(input$graphui_node_size == "Default")
            return(NULL)
        else if(input$graphui_node_size == "Proportional") {
            x <- NULL
            if(input$graphui_active_sample == "All")
                x <- "popsize"
            else
                x <- paste("popsize", input$graphui_active_sample, sep = "@")
            
            G <- get_graph()

            ret <- igraph::get.vertex.attribute(G, x)

            return(ret / sum(ret))
        }
    }
})

get_node_color_attr <- reactive({
    if(input$graphui_node_color_attr == "Default")
        return(NULL)
    else {
        x <- NULL
        if(input$graphui_active_sample == "All")
            x <- input$graphui_node_color_attr
        else
            x <- paste(input$graphui_node_color_attr, input$graphui_active_sample, sep = "@")
        
        G <- get_graph()
        
        ret <- igraph::get.vertex.attribute(G, x)
        
        if(input$graphui_stats_relative_to != "Absolute") {
            rel.to <- paste(input$graphui_node_color_attr, input$graphui_stats_relative_to, sep = "@")
            
            if(input$graphui_stats_type == "Difference")
                ret <- ret - igraph::get.vertex.attribute(G, rel.to)
            else if(input$graphui_stats_type == "Ratio")
                ret <- ret / igraph::get.vertex.attribute(G, rel.to)
            ret[is.infinite(ret)] <- NA
        }
        
        
        return(ret)
    }
})





observe({
    print("###")
    print(input$graphui_selected_nodes)
    
})

output$graphui_viscontrol <- reactive({
    # Taking this dependency here is necessary because 
    # chaging the viscontrol object is what triggers the re-rendering. Without this
    # the scene would not rendered when a different graph is selected, or when
    # the edges to display are changed
    
    input$graphui_selected_graph
    input$graphui_display_edges
    
    colorScaleDomain <- NULL
    colorScaleRange <- NULL
    
    if(input$graphui_color_number == 2) {
        colorScaleRange <- c(input$graphui_color_min, input$graphui_color_max)
        colorScaleDomain <- input$graphui_color_scale_lim
           
    } else {
        colorScaleRange <- c(input$graphui_color_min, input$graphui_color_mid, input$graphui_color_max)
        colorScaleDomain <- c(input$graphui_color_scale_lim[1], input$graphui_color_scale_mid, input$graphui_color_scale_lim[2])
    }

    return(list(
        minNodeSize = input$graphui_min_node_size,
        maxNodeSize = input$graphui_max_node_size,
        nodeColorAttr = get_node_color_attr(),
        nodeSizeAttr = get_node_size_attr(),
        colorUnder = input$graphui_color_under,
        colorOver = input$graphui_color_over,
        colorScaleRange = colorScaleRange,
        colorScaleDomain = colorScaleDomain,
        landmarkNodeSize = input$graphui_landmark_node_size
    ))
})


observe({
    updateSliderInput(session, "graphui_color_scale_lim", min = input$graphui_color_scale_min,
                          max = input$graphui_color_scale_max)
})

#output$graphui_table <- renderDataTable({
#    sc.data <- scaffold_data()
#    if(!is.null(sc.data) && !is.null(input$graphui_selected_graph) && input$graphui_selected_graph != "")
#    {
#        if(is.null(input$graphui_selected_nodes) || length(input$graphui_selected_nodes) == 0)
#        {
#            scaffold2:::get_number_of_cells_per_landmark(scaffold_data(), input$graphui_selected_graph)     
#        }
#        else
#        {
#            scaffold2:::get_summary_table(scaffold_data(), input$graphui_selected_graph, input$graphui_selected_nodes)
#        }
#    }
#}, options = list(scrollX = TRUE, searching = FALSE, scrollY = "800px", paging = FALSE, info = FALSE, processing = FALSE))

output$graphui_plot = renderPlot({
    p <- NULL
    if(!is.null(input$graphui_plot_clusters) && input$graphui_plot_clusters != 0) {
        isolate({
            col.names <- input$graphui_markers_to_plot
            if((length(col.names) >= 1) && (length(input$graphui_selected_nodes) > 0)) {
                G <- get_graph()
                
                
                samples.to.plot <- NULL
                if(length(input$graphui_samples_to_plot) > 0) {
                    if(input$graphui_plot_type == "Density" && !input$graphui_pool_samples_data) {
                        showModal(modalDialog(
                            "If you are plotting data for individual samples you cannot use Density plots",
                            "Please either select Boxplot, or pool samples data",
                            easyClose = TRUE
                        ))
                        return(p)
                    }
                    samples.to.plot <- input$graphui_samples_to_plot
                }

                p <- scaffold2:::plot_clusters(G, 
                                    clusters = input$graphui_selected_nodes, 
                                    col.names = input$graphui_markers_to_plot,
                                    working.dir = working.directory,
                                    plot.type = input$graphui_plot_type,
                                    pool.clusters = input$graphui_pool_clusters_data,
                                    pool.samples = input$graphui_pool_samples_data,
                                    samples.to.plot = samples.to.plot,
                                    facet.by = input$graphui_facet_by
                )
            }
                
        })
    }
    print(p)
})

observeEvent(input$graphui_reset_graph_position, {
        session$sendCustomMessage(type = "reset_graph_position", "none")
    }
)

observeEvent(input$graphui_toggle_landmark_labels, {
        session$sendCustomMessage(type = "toggle_landmark_labels", "none")
    }
)

observeEvent(input$graphui_toggle_cluster_labels, {
        session$sendCustomMessage(type = "toggle_cluster_labels", "none")
    }
)


#output$graphui_plot_title = renderPrint({
#    if(!is.null(input$graphui_selected_cluster) && input$graphui_selected_cluster != "")
#        sprintf("Plotting cluster %s", input$graphui_selected_cluster)
#})




observe({
    if(!is.null(input$graphui_reset_colors) && input$graphui_reset_colors != 0)
    {
        #session$sendCustomMessage(type = "reset_colors", "none")
    }
})

observe({
    if(!is.null(input$graphui_export_selected_clusters) && input$graphui_export_selected_clusters > 0)
    {
        isolate({
            if(!is.null(input$graphui_selected_nodes) && length(input$graphui_selected_nodes) >= 1)
                scaffold2:::export_clusters(working.directory, input$graphui_selected_graph, input$graphui_selected_nodes)
        })
    }
})





observe({
        display_edges <- input$graphui_display_edges
        #session$sendCustomMessage(type = "toggle_display_edges", display_edges)
})

observe({
    if(!is.null(input$graphui_toggle_cluster_labels) && input$graphui_toggle_cluster_labels != 0)
    {
        display <- ifelse(input$graphui_toggle_cluster_labels %% 2 == 0, "none", "")
        #session$sendCustomMessage(type = "toggle_label", list(target = "cluster", display = display))
    }
})

observe({
    display <- tolower(input$graphui_node_size)
    #session$sendCustomMessage(type = "toggle_node_size", list(display = display))
})


observe({
    if(!is.null(input$graphui_toggle_node_size) && input$graphui_toggle_node_size != 0)
    {
        display <- ifelse(input$graphui_toggle_node_size %% 2 == 0, "proportional", "default")
        #session$sendCustomMessage(type = "toggle_node_size", list(display = display))
    }
})