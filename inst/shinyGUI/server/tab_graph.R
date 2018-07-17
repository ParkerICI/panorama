reactiveNetwork <- function (outputId) {
    HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"></div>", sep=""))
}

visControl <- function(outputId) {
    HTML(paste("<div id=\"", outputId, "\" class=\"shiny-vis-control\"></div>", sep=""))
}


render_graph_ui <- function(working.directory, ...) { renderUI({
fluidPage(
    shinyjs::useShinyjs(),
    tags$head(tags$script(src = "mainwindow.js")),
    sidebarPanel(
        selectInput("graphui_display_edges", "Display edges", choices = c("All", "Highest scoring", "Inter cluster", "To landmark"), width = "100%"),
        selectInput("graphui_node_color_attr", "Nodes color", choices = c("Default"), width = "100%"),
        fluidRow(
                column(6,
                       selectInput("graphui_stats_type", "Stats type", choices = c("Absolute", "Ratio", "Difference"))
                       
                ),
                column(6,
                       conditionalPanel(
                           condition = "input.graphui_stats_type != 'Absolute'",
                           selectInput("graphui_stats_relative_to", "Stats relative to:", choices = c(""), width = "100%")
                       )
                )
            ),
            
        selectInput("graphui_color_number", "Number of colors", choices = c(2,3)),
        fluidRow(
            column(6,
                   colourpicker::colourInput("graphui_color_under", "Under", value = "#FFFF00")
            ),
            column(6,
                   colourpicker::colourInput("graphui_color_over", "Over", value = "#0000FF")
            )
        ),
        fluidRow(
            column(4,
                   colourpicker::colourInput("graphui_color_min", "Min", value = "#E7E7E7")
            ),
            column(4,
                   conditionalPanel(
                       condition = "input.graphui_color_number == 3",
                       colourpicker::colourInput("graphui_color_mid", "Mid", value = "#E7E7E7")
                   )
            ),
            column(4,
                   colourpicker::colourInput("graphui_color_max", "Max", value = "#E71601")
            )
        ),
        conditionalPanel(
            condition = "input.graphui_color_number == 3",
            sliderInput("graphui_color_scale_mid", "Color scale midpoint", min = 0.0, max = 5.0, value = 2.5, round = -2, step = 0.1, sep = "")
        ),
        sliderInput("graphui_color_scale_lim", "Color scale limits", min = 0.0, max = 5.0, value = c(0.0, 5.0), round = -2, step = 0.1, sep = ""),
        fluidRow(
            column(6,
                   numericInput("graphui_color_scale_min", "Color scale min", 0)
            ),
            column(6,
                   numericInput("graphui_color_scale_max", "Color scale max", 5)
            )
        ),
        fluidRow(
            column(6,
                   selectInput("graphui_node_size", "Nodes size", choices = c("Proportional", "Default"), width = "100%")
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
            column(6, 
                selectInput("graphui_plot_type", "Plot type", choices = c("Density", "Boxplot", "Scatterplot"), width = "100%")
            ),
            column(6,
                selectInput("graphui_facet_by", "Facet by", choices = c("Sample", "Variable"), width = "100%")
            )
        ),
        fluidRow(
            column(4, 
                checkboxInput("graphui_pool_clusters_data", "Pool clusters data", value = FALSE)
            ),
            column(4,
                checkboxInput("graphui_pool_samples_data", "Pool samples data", value = FALSE)
            ),
            column(4,
                actionButton("graphui_plot_clusters", 
                    tagList(tags$div(id = "graphui_plot_clusters_text", "Plot clusters"), tags$div(id = "graphui_plot_clusters_spinner", class = "spinner", style = "visibility: hidden")),
                    style = "position: relative"
                )
            )
        ),
        conditionalPanel(
            condition = "input.graphui_plot_type == 'Scatterplot'",
            fluidRow(
                column(6,
                       selectInput("graphui_x_axis", "X axis", choices = "", width = "100%")
                ),
                column(6,
                       selectInput("graphui_y_axis", "Y axis", choices = "", width = "100%")
                )
            )
        ),
        conditionalPanel(
            condition = "input.graphui_plot_type != 'Scatterplot'",
            fluidRow(
                column(12,
                    selectInput("graphui_markers_to_plot", "Markers to plot", choices = c(""), multiple = T, width = "100%")
                )
            )
        ),
        selectizeInput("graphui_samples_to_plot", "Samples to plot", choices = c(""), multiple = T, width = "100%")
    ),
    
    
    mainPanel(
        fluidRow(
            column(6,
                selectizeInput("graphui_selected_graph", "Choose a graph", choices = c("", list.files(path = working.directory, pattern = "*.graphml$")), width = "100%")
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
                actionButton("graphui_toggle_cluster_labels", "Toggle cluster labels") 
            ),
            column(4,
                actionButton("graphui_toggle_landmark_labels", "Toggle landmark labels")       
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

get_selected_nodes <- reactive({
    sel <- input$graphui_selected_nodes
    G <- get_graph()
    
    if(!is.null(igraph::V(G)$type)) {
        type <- igraph::V(G)$type[sel]
        sel <- sel[type == "cluster"]
    }
    return(sel)
})


observe({
    G <- get_graph()
    if(!is.null(G)) {
        attrs <- panorama:::get_vertex_attributes(G)
        
        isolate({
            sel.marker <- NULL
            if(input$graphui_node_color_attr %in% attrs)
                sel.marker <- input$graphui_node_color_attr
            else
                sel.marker <- "Default"
            markers.for.plotting <- setdiff(panorama:::get_numeric_vertex_attributes(G), "popsize")
            updateSelectInput(session, "graphui_node_color_attr", choices = c("Default", attrs), selected = sel.marker)
            updateSelectInput(session, "graphui_markers_to_plot", choices = markers.for.plotting, selected = markers.for.plotting)
            updateSelectInput(session, "graphui_x_axis", choices = markers.for.plotting)
            updateSelectInput(session, "graphui_y_axis", choices = markers.for.plotting)
            sample.names <- panorama:::get_sample_names(G)
            updateSelectInput(session, "graphui_active_sample", choices = c("All", sample.names),
                                selected = input$graphui_active_sample)
            updateSelectizeInput(session, "graphui_samples_to_plot", choices = sample.names)
            updateSelectInput(session, "graphui_stats_relative_to", choices = sample.names,
                                selected = input$graphui_stats_relative_to)
        })
    }
})


output$graphui_mainnet <- reactive({
    G <- get_graph()
    ret <- NULL
    
    if(!is.null(G)) 
        ret <- panorama:::graph_to_json(G, input$graphui_display_edges)
    
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
    if(is.null(input$graphui_node_color_attr) || input$graphui_node_color_attr == "Default")
        return(NULL)
    else {
        x <- NULL
        if(input$graphui_active_sample == "All")
            x <- input$graphui_node_color_attr
        else
            x <- paste(input$graphui_node_color_attr, input$graphui_active_sample, sep = "@")
        
        G <- get_graph()
        
        ret <- igraph::get.vertex.attribute(G, x)
        
        if(input$graphui_stats_type != "Absolute") {
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
#            panorama:::get_number_of_cells_per_landmark(scaffold_data(), input$graphui_selected_graph)     
#        }
#        else
#        {
#            panorama:::get_summary_table(scaffold_data(), input$graphui_selected_graph, input$graphui_selected_nodes)
#        }
#    }
#}, options = list(scrollX = TRUE, searching = FALSE, scrollY = "800px", paging = FALSE, info = FALSE, processing = FALSE))



output$graphui_plot = renderPlot(width = 1200, height = 800, expr = {
    p <- NULL
    if(!is.null(input$graphui_plot_clusters) && input$graphui_plot_clusters != 0) {
        isolate({
            markers.to.plot <- NULL
            if(input$graphui_plot_type == "Scatterplot")
                markers.to.plot = c(input$graphui_x_axis, input$graphui_y_axis)
            else
                markers.to.plot <- input$graphui_markers_to_plot
            
            if((length(markers.to.plot) >= 1) && (length(input$graphui_selected_nodes) > 0)) {
                G <- get_graph()
                
                samples.to.plot <- NULL
                if(length(input$graphui_samples_to_plot) > 0 || panorama:::graph_type(G) == "multiple") {
                    if(input$graphui_plot_type == "Density" && !input$graphui_pool_samples_data) {
                        showModal(modalDialog(
                            "Cannot display Density plots with sample-specific data",
                            "Please either select Boxplot, or pool samples data",
                            easyClose = TRUE
                        ))
                        return(p)
                    }
                    samples.to.plot <- input$graphui_samples_to_plot
                }
            
                session$sendCustomMessage(type = "plot_loading", "none")

                p <- panorama:::plot_clusters(G, 
                                    clusters = get_selected_nodes(),
                                    col.names = markers.to.plot,
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



observe({
    if(!is.null(input$graphui_export_selected_clusters) && input$graphui_export_selected_clusters > 0)
    {
        isolate({
            if(!is.null(input$graphui_selected_nodes) && length(input$graphui_selected_nodes) >= 1)
                panorama:::export_clusters(working.directory, input$graphui_selected_graph, input$graphui_selected_nodes)
        })
    }
})

observe({
    G <- get_graph()
    node.color.attr <- get_node_color_attr()
    if(!is.null(G)) {
        if(is.null(igraph::V(G)$type) || length(unique(igraph::V(G)$type)) == 1) {
            shinyjs::hide("graphui_display_edges")
            shinyjs::hide("graphui_toggle_landmark_labels")
        } 
        else {
            shinyjs::show("graphui_display_edges")
            shinyjs::show("graphui_toggle_landmark_labels")
        }    
            
        graph.type <- panorama:::graph_type(G)
        if(graph.type == "pooled") {
            shinyjs::show("graphui_active_sample")
            shinyjs::show("graphui_stats_type")
            shinyjs::show("graphui_stats_relative_to")
            shinyjs::show("graphui_samples_to_plot")
            shinyjs::show("graphui_facet_by")
            shinyjs::show("graphui_pool_samples_data")
        } else {
            shinyjs::hide("graphui_active_sample")
            shinyjs::hide("graphui_stats_type")
            shinyjs::hide("graphui_stats_relative_to")
            shinyjs::hide("graphui_samples_to_plot")

            if(graph.type == "multiple") {
                shinyjs::show("graphui_facet_by")
                shinyjs::show("graphui_pool_samples_data")
            } else {
                shinyjs::hide("graphui_facet_by")
                shinyjs::hide("graphui_pool_samples_data")
            }

        }
    }
    
    if(!is.null(node.color.attr) && is.character(node.color.attr)) {
        shinyjs::hide("graphui_color_number")
        shinyjs::hide("graphui_color_mid")
        shinyjs::hide("graphui_color_max")
        shinyjs::hide("graphui_color_scale_mid")
        shinyjs::hide("graphui_color_scale_lim")
        shinyjs::hide("graphui_color_scale_min")
        shinyjs::hide("graphui_color_scale_max")
        shinyjs::hide("graphui_color_under")
        shinyjs::hide("graphui_color_over")
        shinyjs::hide("graphui_color_min")
        
    } else {
        shinyjs::show("graphui_color_number")
        shinyjs::show("graphui_color_mid")
        shinyjs::show("graphui_color_max")
        shinyjs::show("graphui_color_scale_mid")
        shinyjs::show("graphui_color_scale_lim")
        shinyjs::show("graphui_color_scale_min")
        shinyjs::show("graphui_color_scale_max")
        shinyjs::show("graphui_color_under")
        shinyjs::show("graphui_color_over")
        shinyjs::show("graphui_color_min")
        
    }

})


#observe({
#    print("###")
#    print(input$graphui_selected_nodes)
#    
#})



