options(stringsAsFactors = F)

#' @export
plot_communities <- function(G, att.names, ...) {
    tab <- igraph::get.data.frame(G, what = "vertices")
    df <- tab[, c(att.names, "community_id")]
    
    df <- plyr::ddply(df, ~community_id, plyr::colwise(median))
    
    m <- as.matrix(df[, att.names])
    row.names(m) <- df$community_id
    gplots::heatmap.2(m, trace = "none", ...)
}



density_scatterplot <- function(tab, x_name, y_name, grouping) {
    m <- plyr::ddply(tab, grouping, function(m, x_name, y_name) {
        colramp <- grDevices::colorRampPalette(c("black", "red", "yellow"))
        dens.col <- grDevices::densCols(m[, x_name], m[, y_name], colramp = colramp)
        return(data.frame(m, dens.col = dens.col))
    }, x_name = x_name, y_name = y_name)
    
    maxx <- max(m[, x_name], na.rm = T) + 0.5
    maxy <- max(m[, y_name], na.rm = T) + 0.5
    
    (p <- ggplot2::ggplot(ggplot2::aes_string(x = x_name, y = y_name, color = "dens.col", size = 1), data = m)
            + ggplot2::facet_wrap(grouping)
            + ggplot2::geom_point()
            + ggplot2::scale_colour_identity() 
            + ggplot2::scale_size_identity()
            + ggplot2::xlim(0, maxx)
            + ggplot2::ylim(0, maxy)
    )
    
    return(p)
}


load_rds_data <- function(v, dir) {
    ret <- lapply(v, function(s) {
        readRDS(file.path(dir, sprintf("%s.rds", s)))
    })
    return(do.call(rbind, ret))
}


add_missing_columns <- function(m, col.names, fill.data) {
    v <- col.names[!(col.names %in% colnames(m))]
    ret <- matrix(nrow = nrow(m), ncol = length(v), data = fill.data)
    colnames(ret) <- v
    ret <- data.frame(m, ret, check.names = FALSE, stringsAsFactors = FALSE)
    return(ret)
}


load_clusters_data <- function(clusters, samples, dir.prefix) {
    df <- data.frame(clusters, samples, stringsAsFactors = FALSE)
    
    ret <- plyr::dlply(df, ~samples, function(x) {
        return(load_rds_data(x$clusters, file.path(dir.prefix, x$samples[1])))
        
    })
    
    return(do.call(rbind, ret))
    
    
}


plot_scaffold_clusters <- function(G, clusters, working.dir, col.names, pool.cluster.data, plot.type) {
  
    browser()
    
    cl.labels <- V(G)$Label[clusters]
    
    if(!is.null(V(G)$sample)) {
        samples <- V(G)$sample[clusters]
        clusters.data <- load_clusters_data(cl.labels, samples, file.path(working.dir, "clusters_data"))
    } else {
        clusters.data <- load_rds_data(cl.labels, file.path(working.dir, "clusters_data", "pooled"))
    }
    
    clusters.data <- clusters.data[, c(col.names, "cellType")]
    
    temp <- clusters.data
    
    if(any(V(G)$type == "landmark")) {
    
        # Select only the landmark nodes that are connected to these clusters
        land <- V(G)[nei(V(G)$Label %in% cl.labels)]$Label
        land <- V(G)[(V(G)$Label %in% land) & V(G)$type == "landmark"]$Label
        landmarks.data <- load_rds_data(land, file.path(working.dir, "landmarks_data"))
        
        
        #This only works if the col.names are actually present in the clustered.data
        #TODO: figure out a consistent way to deal with panel mismatches
        
        common.names <- col.names[(col.names %in% names(clusters.data)) & (col.names %in% names(landmarks.data))]
        landmarks.data <- landmarks.data[, c(common.names, "cellType")]
        landmarks.data <- add_missing_columns(landmarks.data, col.names, fill.data = NA)
        temp <- rbind(clusters.data, landmarks.data)
    }
    
    print("FIXME: Need to split data by samples")
    
    if(pool.cluster.data)
        clusters.data$cellType <- "Clusters"
    
    p <- NULL
    
    if(plot.type == "Scatterplot")
        p <- density_scatterplot(temp, x_name = col.names[1], y_name = col.names[2], grouping = "cellType")
    
    else {
        temp <- reshape::melt(temp, id.vars = "cellType")
        temp$variable <- as.factor(temp$variable)
        temp$cellType <- as.factor(temp$cellType)
        
        if(plot.type == "Density")
            p <- (ggplot2::ggplot(ggplot2::aes(x = value, color = cellType), data = temp) 
                    + ggplot2::geom_density() 
                    + ggplot2::facet_wrap(~variable, scales = "free"))
        
        else if(plot.type == "Boxplot")
            p <- (ggplot2::ggplot(ggplot2::aes(x = variable, fill = cellType, y = value), data = temp) 
                    + ggplot2::geom_boxplot())
    }
    return(p)
}

run_test <- function() {
    setwd("C:/Users/fgherardini/temp/scaffold_demo/scaffold_result")
    fname <- "A_cells_found_normalized_A_cells_found_normalized.fcs - A_cells_found_normalized.fcs_Cells.fcs.clustered.txt.graphml"
    G <- igraph::read.graph(fname, format = "graphml")
    scaffold2:::plot_scaffold_clusters(c("c1", "c2", "c3"), G, fname, "./", col.names = c("CD3", "CD45", "CD19", "CD14"), F, "Boxplot")
                           
    
    
    
    
    
}










