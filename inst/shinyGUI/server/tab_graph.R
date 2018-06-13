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


render_graph_ui <- function(working.directory, ...){renderUI({
fluidPage(
    fluidRow(
        column(6,
          
            visControl("graphui_viscontrol"),
            reactiveNetwork(outputId = "graphui_mainnet")
        ),
        column(3,
               dataTableOutput("graphui_table")
        ),
        column(3,
            selectizeInput("graphui_selected_graph", "Choose a graph:", choices = c("", list.files(path = working.directory, pattern = "*.graphml$")), width = "100%"),
            selectizeInput("graphui_active_sample", "Active sample", choices = c("All"), width = "100%"),
            selectInput("graphui_node_color_attr", "Nodes color:", choices = c("Default"), width = "100%"),
            fluidRow(
                column(6,
                    selectInput("graphui_stats_type", "Stats type", choices = c("Ratio", "Difference"))
                ),
                column(6,
                    selectInput("graphui_stats_relative_to", "Stats relative to:", choices = c("Absolute"), width = "100%")
                )
            ),
            selectInput("graphui_color_scaling", "Color scaling:", choices = c("global", "local"), width = "100%"),
            h4("Colors for scale"),
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
            selectInput("graphui_display_edges", "Display edges:", choices = c("All", "Highest scoring", "Inter cluster", "To landmark"), width = "100%"), br(),
            actionButton("graphui_reset_graph_position", "Reset graph position"), br(),
            actionButton("graphui_toggle_landmark_labels", "Toggle landmark labels"), br(),
            actionButton("graphui_toggle_cluster_labels", "Toggle cluster labels"), br(),
            actionButton("graphui_export_selected_clusters", "Export selected clusters"), br(),
            p("For the export to work, the original RData files corresponding to the clustered files in use must be located in the working directory"),
            actionButton("graphui_plot_clusters", "Plot selected clusters"), checkboxInput("graphui_pool_cluster_data", "Pool cluster data", value = FALSE), br(),
            selectInput("graphui_plot_type", "Plot type:", choices = c("Density", "Boxplot", "Scatterplot"), width = "100%"),
            selectInput("graphui_markers_to_plot", "Markers to plot in cluster view:", choices = c(""), multiple = T, width = "100%"),
            verbatimTextOutput("graphui_dialog1")
        )
    ),
    fluidRow(
        column(12,
            plotOutput("graphui_plot")
        )
    )
)
})}



get_main_graph <- reactive({
    if(!is.null(input$graphui_selected_graph) && input$graphui_selected_graph != "") {
        
        G <- igraph::read.graph(file.path(working.directory, input$graphui_selected_graph), format = "graphml")
        
        attrs <- scaffold2:::get_numeric_vertex_attributes(G)
        node.size.attr <- scaffold2:::combine_marker_sample_name("popsize", input$graphui_active_sample)
        
        isolate({
            sel.marker <- NULL
            if(input$graphui_node_color_attr %in% attrs)
                sel.marker <- input$graphui_node_color_attr
            else
                sel.marker <- "Default"
            updateSelectInput(session, "graphui_node_color_attr", choices = c("Default", attrs), selected = sel.marker)
            updateSelectInput(session, "graphui_markers_to_plot", choices = attrs, selected = attrs)
            sample.names <- scaffold2:::get_sample_names(G)
            updateSelectInput(session, "graphui_active_sample", choices = c("All", sample.names),
                                selected = input$graphui_active_sample)
            updateSelectInput(session, "graphui_stats_relative_to", choices = c("Absolute", sample.names),
                                selected = input$graphui_stats_relative_to)
        })
        return(scaffold2:::get_graph(G))
    }
    else
        return(NULL)
})

read_color_scale_info <- reactive({
    return(list(sel.marker = input$graphui_marker, color.scale.lim = input$graphui_color_scale_lim,
                color.scale.mid = input$graphui_color_scale_mid))
})


output$graphui_mainnet <- reactive({
    ret <- get_main_graph()
    if(!is.null(ret)) {
        ret$trans_to_apply <- isolate({input$graphui_cur_transform})
    }
    return(ret)
})


output$graphui_viscontrol <- reactive({
    # Taking this dependency here is necessary because 
    # chaging the viscontrol object is what triggers the re-rendering. Without this
    # the scene would not rendered when a different graph is selected
    
    input$graphui_selected_graph
    return(list(
        minNodeSize = input$graphui_min_node_size,
        maxNodeSize = input$graphui_max_node_size,
        nodeSize = input$graphui_node_size,
        nodeColorAttr = input$graphui_node_color_attr,
        colorMin = input$graphui_color_min,
        colorMax = input$graphui_color_max,
        landmarkNodeSize = input$graphui_landmark_node_size,
        nodeSizeAttr = "CD3"
    ))
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
    #session$sendCustomMessage(type = "get_selected_nodes", list())
    if(!is.null(input$graphui_plot_clusters) && input$graphui_plot_clusters != 0)
    {
        isolate({
            col.names <- input$graphui_markers_to_plot
            if((length(col.names) >= 1) && (length(input$graphui_selected_nodes) >= 1))
                p <- scaffold2:::plot_cluster(scaffold_data(), input$graphui_selected_nodes, input$graphui_selected_graph, 
                                            input$graphui_markers_to_plot, input$graphui_pool_cluster_data, input$graphui_plot_type)
        })
    }
    print(p)
})


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
    if(!is.null(input$graphui_reset_graph_position) && input$graphui_reset_graph_position != 0)
    {
        #session$sendCustomMessage(type = "reset_graph_position", "none")
    }
})

observe({
    if(!is.null(input$graphui_toggle_landmark_labels) && input$graphui_toggle_landmark_labels != 0)
    {
        display <- ifelse(input$graphui_toggle_landmark_labels %% 2 == 0, "", "none")
        #session$sendCustomMessage(type = "toggle_label", list(target = "landmark", display = display))
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