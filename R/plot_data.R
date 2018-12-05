

#' @export
plot_communities <- function(G, att.names, ...) {
    tab <- igraph::get.data.frame(G, what = "vertices")
    df <- tab[, c(att.names, "community_id")]
    
    df <- plyr::ddply(df, ~community_id, plyr::colwise(median))
    
    m <- as.matrix(df[, att.names])
    row.names(m) <- df$community_id
    gplots::heatmap.2(m, trace = "none", ...)
}



density_scatterplot <- function(tab, x.name, y.name, facet.by = NULL) {

    tab$cellType <- as.factor(tab$cellType)
    maxx <- max(tab[, x.name], na.rm = T) + 0.5
    maxy <- max(tab[, y.name], na.rm = T) + 0.5

    
    if(is.null(tab$sample) || length(unique(tab$sample)) == 1) {
        m <- plyr::ddply(tab, ~cellType, function(m, x.name, y.name) {
            colramp <- grDevices::colorRampPalette(c("black", "red", "yellow"))
            dens.col <- grDevices::densCols(m[, x.name], m[, y.name], colramp = colramp)
            return(data.frame(m, dens.col = dens.col, check.names = FALSE))
        }, x.name = x.name, y.name = y.name)
        
        (p <- ggplot2::ggplot(ggplot2::aes_string(x = x.name, y = y.name, color = "dens.col", size = 1), data = m)
                + ggplot2::facet_wrap(~cellType)
                + ggplot2::geom_point()
                + ggplot2::scale_colour_identity() 
                + ggplot2::scale_size_identity()
                + ggplot2::xlim(0, maxx)
                + ggplot2::ylim(0, maxy)
        )
    } else {
        if(facet.by == "Cluster")
            (p <- ggplot2::ggplot(ggplot2::aes_string(x = x.name, y = y.name, size = 1, colour = "sample"), data = tab)
                    + ggplot2::facet_wrap(~cellType)
                    + ggplot2::geom_point()
                    + ggplot2::scale_size_identity()
                    + ggplot2::xlim(0, maxx)
                    + ggplot2::ylim(0, maxy)
             )
        else if(facet.by == "Sample")
            (p <- ggplot2::ggplot(ggplot2::aes_string(x = x.name, y = y.name, size = 1, colour = "cellType"), data = tab)
                    + ggplot2::facet_wrap(~sample)
                    + ggplot2::geom_point()
                    + ggplot2::scale_size_identity()
                    + ggplot2::xlim(0, maxx)
                    + ggplot2::ylim(0, maxy)
            )
    }
    
    
    return(p)
}


load_rds_data <- function(v, dir, skip.missing = FALSE) {
    ret <- lapply(v, function(s) {
        fname <- file.path(dir, sprintf("%s.rds", s))
        if(file.exists(fname))
            readRDS(file.path(dir, sprintf("%s.rds", s)))
        else {
            if(skip.missing)
                return(NULL)
            else
                stop(sprintf("File not found: %s", fname))
        }
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


load_clusters_data <- function(clusters, samples, dir.prefix, skip.missing = FALSE) {
    df <- data.frame(clusters, samples, stringsAsFactors = FALSE)
    
    ret <- plyr::dlply(df, ~samples, function(x) {
        ret <- load_rds_data(x$clusters, file.path(dir.prefix, x$samples[1]), skip.missing)
        ret$sample <- x$samples[1]
        return(ret)
    })

    return(do.call(rbind, ret))
    
    
}


#samples.to.plot need to be specified if pool.samples = F, and this is a multi files clustering
#pool clusters implies pool samples

#' Plot clusters data
#' 
#' This function plots data for individual clusters and landmarks and has different behaviours depending 
#'   on whether the clusters represent individual or multiple samples (i.e. wether they were generated using
#'   \code{scfeatures::cluster_fcs_files} or \code{scfeatures::cluster_fcs_files_groups})
#' 
#' @param G An \code{igraph} graph object
#' @param clusters A numeric vector representing the indices of the vertices of \code{G} to plot (i.e. the clusters)
#' @param col.names A character vector of variables to plot (these must correspond to the columns in the original clusters data)
#' @param working.dir The working directory. Must contain two subdirectories named \code{clusters_data} and \code{landmarks_data}. The latter
#'   is only necessary if \code{G} contains nodes of type \code{landmark} (i.e. it represents a Scaffold map)
#' @param plot.type Either \code{"Boxplot"} or \code{"Scatterplot"}. The type of plot
#' @param pool.clusters Whether to pool the clusters data. If this is \code{FALSE} each cluster is plotted separately
#' @param pool.samples Whether to pool data from different samples. If this is \code{FALSE} each sample is plotted separately
#' @param samples.to.plot The samples to be plotted. This option is only used if \code{pool.samples == FALSE} and \code{G} does not have 
#'   a \code{sample} vertex property (i.e. the vertices were generated using \code{scfeatures::cluster_fcs_files_groups}, and as such they represent
#'   multiple samples). In such cases, if this option is \code{NULL}, the pooled data is plotted, otherwise only data for the corresponding samples
#'   is plotted. If instead the nodes (i.e. the clusters) represent single samples
#'   the samples to be plotted are selected from the \code{sample} vertex property of the corresponding nodes
#' @param facet.by In cases where multiple samples are plotted, whether the plots should be faceted by \code{"Sample"} or by \code{"Variable"}
#' 
#' @return Returns a \code{ggplot2} plot object
#' 
plot_clusters <- function(G, clusters, col.names, working.dir, plot.type, pool.clusters = FALSE, 
                          pool.samples = FALSE, samples.to.plot = NULL, facet.by = "Sample") {
    if(!dir.exists(file.path(working.dir, "clusters_data")))
        stop("clusters_data directory is missing, data cannot be plotted")
    
    cl.labels <- V(G)$Label[clusters]
    clusters.data <- NULL
    
    if(is.null(V(G)$sample) && is.null(samples.to.plot)) { # Load the pooled data
        pooled.data.dir <- tools::file_path_sans_ext(igraph::get.graph.attribute(G, "fname"))
        clusters.data <- load_rds_data(cl.labels, file.path(working.dir, "clusters_data", "pooled", pooled.data.dir))
        clusters.data$sample <- NULL
    }
    else {
        samples <- NULL
        if(!is.null(V(G)$sample))
            samples <- V(G)$sample[clusters]
        else
            samples <- rep(samples.to.plot, each = length(clusters))
        
        clusters.data <- load_clusters_data(cl.labels, samples, file.path(working.dir, "clusters_data"), skip.missing = TRUE)
    }
    
    if(pool.samples)
        clusters.data$sample <- NULL
    
    if(pool.clusters) 
        clusters.data$cellType <- "Clusters"
    
    temp <- clusters.data[, c(col.names, "cellType")]
    if(!is.null(clusters.data$sample))
        temp$sample <- as.factor(clusters.data$sample)
    clusters.data <- temp
    
    landmarks.data <- NULL
    
    if(any(V(G)$type == "landmark")) {
        # Select only the landmark nodes that are connected to these clusters
        land <- V(G)[nei(V(G)$Label %in% cl.labels)]$Label
        land <- V(G)[(V(G)$Label %in% land) & V(G)$type == "landmark"]$Label
        landmarks.data <- load_rds_data(land, file.path(working.dir, "landmarks_data"))
        
        common.names <- intersect(col.names, names(landmarks.data))
        landmarks.data <- landmarks.data[, c(common.names, "cellType")]
        landmarks.data <- add_missing_columns(landmarks.data, col.names, fill.data = NA)

        if(!is.null(clusters.data$sample))
            # Duplicate landmarks data for each sample for plotting
            landmarks.data <- data.frame(landmarks.data, sample = rep(unique(clusters.data$sample), each = nrow(landmarks.data)),
                                         check.names = FALSE, stringsAsFactors = FALSE)
    }

    temp <- rbind(clusters.data, landmarks.data)
    

    
    p <- NULL
    
    if(plot.type == "Scatterplot")
        p <- density_scatterplot(temp, x.name = col.names[1], y.name = col.names[2], facet.by)
    else 
        p <- expression_plot(temp, plot.type, facet.by)

    return(p)
}


expression_plot <- function(tab, plot.type, facet.by = "Sample") {
    # Add error message that you cannot subset density plots by sample
    p <- NULL
    
    if(is.null(tab$sample) || length(unique(tab$sample)) == 1) {
        tab$sample <- NULL
        tab <- reshape::melt(tab, id.vars = "cellType")
        tab$variable <- as.factor(tab$variable)
        tab$cellType <- as.factor(tab$cellType)
        
        if(plot.type == "Density")
            p <- (ggplot2::ggplot(ggplot2::aes(x = value, color = cellType), data = tab) 
                  + ggplot2::geom_density() 
                  + ggplot2::facet_wrap(~variable, scales = "free"))
        
        else if(plot.type == "Boxplot") 
            p <- (ggplot2::ggplot(ggplot2::aes(x = variable, fill = cellType, y = value), data = tab) 
                  + ggplot2::geom_boxplot()
                  + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)))
    } else {
        tab <- reshape::melt(tab, id.vars = c("cellType", "sample"))
        tab$variable <- as.factor(tab$variable)
        tab$cellType <- as.factor(tab$cellType)
        tab$sample <- stringr::str_wrap(tab$sample, 20)
        
        if(plot.type == "Boxplot") {
            if(facet.by == "Sample")
                p <- (ggplot2::ggplot(ggplot2::aes(x = variable, fill = cellType, y = value), data = tab) 
                      + ggplot2::geom_boxplot()
                      + ggplot2::facet_wrap(~sample)
                      + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)))
            else if(facet.by == "Variable")
                p <- (ggplot2::ggplot(ggplot2::aes(x = sample, fill = cellType, y = value), data = tab) 
                      + ggplot2::geom_boxplot()
                      + ggplot2::facet_wrap(~variable)
                      + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)))
        } else
            message("Cannot do density plot for multiple samples")
        
    }

    
    return(p)
}

run_test <- function() {
    setwd("C:/Users/fgherardini/temp/dave_flu/fcs files/scaffold_result/")
    fname <- "group1.graphml"
    G <- igraph::read.graph(fname, format = "graphml")
                           
    panorama:::plot_clusters(G,  c(20, 21 , 22), col.names = c("CD3", "CD45", "CD19", "CD14"), working.dir = "./", plot.type = "Boxplot", 
                              pool.clusters = F, pool.samples = F, samples.to.plot = c("101_3.fcs", "102_4.fcs"))
    
    
    
    
}










