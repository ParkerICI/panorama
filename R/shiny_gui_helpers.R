


rescale_size <- function(max.size, min.size, max.val, x)
{
    return(((max.size - min.size) * x) / max.val + min.size);
}

get_vertex_size <- function(G, figure.width, node.size.attr, min.node.size, max.node.size, landmark.node.size) {
    size.attr <- igraph::get.vertex.attribute(G, node.size.attr)
    ret <- size.attr / sum(size.attr, na.rm = T)
    print("FIXMEEEEEEEEEE")
    ret <- rescale_size(max.node.size, min.node.size, 0.7, ret)
    ret[V(G)$type == "landmark"] <- landmark.node.size
    return(ret)
}


get_sample_names <- function(G) {
    ret <- NULL
    
    if(!is.null(V(G)$sample))
       ret <- V(G)$sample
    else {
        s <- igraph::list.vertex.attributes(G)
        s <- grep("@", s, value = T)
        ret <- sapply(strsplit(s, "@"), function (x) {x[[2]]})
    }
    
    return(unique(ret))
}

combine_marker_sample_name <- function(sel.marker, active.sample)
{
    if(active.sample == "All" || active.sample == "Absolute" || sel.marker == "Default")
        return(sel.marker)
    else
        return(paste(sel.marker, active.sample, sep = "@"))
    
}


get_graph_centering_transform <- function(x, y, svg.width, svg.height)
{
    padding <- 50
    G.width <- max(x) - min(x)
    G.height <- max(y) - min(y)
    scaling <- max(c(G.width / (svg.width - (padding * 2)), G.height / (svg.height - (padding * 2))))
    
    x <- x / scaling
    y <- y / scaling
    
    offset.y <- min(y) - padding
    graph.x.center <- (min(x) + max(x)) / 2
    offset.x <- graph.x.center - (svg.width / 2)
    
    return(list(offset.x = offset.x, offset.y = offset.y, scaling = scaling))
    
    
}

get_graph_table <- function(sc.data, sel.graph)
{
    G <- sc.data$graphs[[sel.graph]]
    ret <- igraph::get.data.frame(G, what = c("vertices"))
    return(ret)
}


get_summary_table <- function(sc.data, sel.graph, sel.nodes)
{
    G <- sc.data$graphs[[sel.graph]]
    col.names <- get_numeric_vertex_attributes(sc.data, sel.graph)
    tab <- igraph::get.data.frame(G, what = "vertices")
    temp <-tab[tab$Label %in% sel.nodes,]
    ret <- temp[, col.names]    
    ret <- rbind(ret, apply(ret, 2, median, na.rm = T))
    popsize <- data.frame(Cells = temp$popsize, Percentage = temp$popsize / sum(tab$popsize[tab$type == "cluster"]))
    popsize <- rbind(popsize, colSums(popsize))
    ret <- cbind(popsize, ret)
    ret <- data.frame(Label = c(temp$Label, "Summary"), ret)
    ret$Percentage <- signif(ret$Percentage * 100, digits = 4)
    return(ret)
}


export_clusters <- function(working.dir, sel.graph, sel.nodes)
{
    d <- gsub(".txt$", ".all_events.RData", sel.graph)
    d <- file.path(working.dir, d)
    d <- my_load(d)
    clus <- as.numeric(gsub("c", "", sel.nodes))
    d <- d[d$cellType %in% clus,]
    f <- flowFrame(as.matrix(d))
    p <- sprintf("scaffold_export_%s_", gsub(".fcs.clustered.txt", "", sel.graph))
    outname <- tempfile(pattern = p, tmpdir = working.dir, fileext = ".fcs")
    print(outname)
    write.FCS(f, outname)
}



graph_to_json <- function(G) {
    edges <- data.frame(igraph::get.edgelist(G, names = F) - 1)
    colnames(edges) <- c("source", "target")
    svg.width <- 1200
    svg.height <- 800
    svg.center <- c(svg.width / 2, svg.height / 2)
    
    x <- V(G)$x
    y <- V(G)$y
    
    y <- -1 * y
    x <- x + abs(min(x))
    y <- y + abs(min(y))
    num.landmarks <- sum(V(G)$type == "landmark")
    
    trans <- NULL
    if(!is.null(V(G)$type) && any(V(G)$type == "landmark"))
        trans <- get_graph_centering_transform(x[V(G)$type == "landmark"], y[V(G)$type == "landmark"], svg.width, svg.height)
    else
        trans <- get_graph_centering_transform(x, y, svg.width, svg.height)
    
    x <- (x / trans$scaling) - trans$offset.x
    y <- (y / trans$scaling) - trans$offset.y
    
    
    edges <- cbind(edges, x1 = x[edges[, "source"] + 1], x2 = x[edges[, "target"] + 1])
    edges <- cbind(edges, y1 = y[edges[, "source"] + 1], y2 = y[edges[, "target"] + 1])
    edges <- cbind(edges, id = 1:nrow(edges), type = E(G)$type)
    
    nodes <- igraph::get.data.frame(G, what = c("vertices"))
    nodes$x <- x
    nodes$y <- y
   
    
    nodes <- nodes[, c("x", "y", "Label", "popsize")]
    
    if(!is.null(V(G)$type))
       nodes$type <- V(G)$type
    
    ret <- list(nodes = jsonlite::toJSON(nodes), edges = jsonlite::toJSON(edges))
    return(ret)
}


get_limits_for_marker <- function(sc.data, sel.graph, active.sample, sel.marker, color.scaling)
{
    if(color.scaling == "local")
    {
        v <- combine_marker_sample_name()
        
    }
    
}

get_color_for_marker <- function(sc.data, sel.marker, rel.to.sample, sel.graph, active.sample, color.scaling, 
                                 stats.type, colors.to.interpolate, color.under, color.over, color.scale.limits = NULL, color.scale.mid = NULL)
{
    G <- sc.data$graphs[[sel.graph]]
    if(sel.marker == "Default")
    {
        ret <- rep("#4F93DE", vcount(G))
        ret[V(G)$type == "cluster"] <- "#FF7580"
        return(list(color.vector = ret, color.scale.lim = NULL))
    }
    else
    {
        v <- igraph::get.vertex.attribute(G, combine_marker_sample_name(sel.marker, active.sample))
        
        f <- colorRamp(colors.to.interpolate, interpolate = "linear")
        
        if(rel.to.sample != "Absolute")
        {
            rel.to.marker <- combine_marker_sample_name(sel.marker, rel.to.sample)
            if(stats.type == "Difference")
                v <- v - (get.vertex.attribute(G, rel.to.marker))
            else if(stats.type == "Ratio")
                v <- v / (get.vertex.attribute(G, rel.to.marker))
            v[is.infinite(v)] <- NA
        }
        color.scale.lim <- NULL
        if(color.scaling == "local")
            color.scale.lim <- list(min = min(v, na.rm = T), max = max(v, na.rm = T))
        if(!is.null(color.scale.limits))
        {
            under <- v < color.scale.limits[1]
            over <- v > color.scale.limits[2]
            v[under] <- color.scale.limits[1]
            v[over] <- color.scale.limits[2]
            if(is.null(color.scale.mid))
                v <-  scales::rescale(v)
            else
                v <- scales::rescale_mid(v, mid = color.scale.mid)
            v <- f(v)
            v <- apply(v, 1, function(x) {sprintf("rgb(%s)", paste(round(x), collapse = ","))})
            v[under] <- sprintf("rgb(%s)", paste(col2rgb(color.under), collapse = ","))
            v[over] <- sprintf("rgb(%s)", paste(col2rgb(color.over), collapse = ","))
            
        }
        else
        {
            v <- f(scales::rescale(v)) #colorRamp needs an argument in the range [0, 1]
            v <- apply(v, 1, function(x) {sprintf("rgb(%s)", paste(round(x), collapse = ","))})
        }
        return(list(color.vector = v, color.scale.lim = color.scale.lim))
    }
}

get_numeric_vertex_attributes <- function(G)
{
    d <- igraph::get.data.frame(G, what = "vertices")
    #Don't consider attributes which are only present in the landmarks
    d <- d[d$type == "cluster",]
    num <- sapply(d, function(x) {is.numeric(x) && !any(is.na(x))})
    v <- igraph::list.vertex.attributes(G)[num]
    v <- v[grep("@", v, invert = T)]
    exclude <- c("x", "y", "cellType", "type", "groups", "r", "g", "b", "size", "DNA1", "DNA2", "BC1", "BC2", "BC3", "BC4", "BC5", "BC6", "Time", "Cell_length", "Cisplatin", "beadDist", "highest_scoring_edge")
    return(v[!(v %in% exclude)])
}

get_number_of_cells_per_landmark <- function(sc.data, sel.graph)
{
    G <- sc.data$graphs[[sel.graph]]
    land <- V(G)[V(G)$type == "landmark"]$Label
    ee <- igraph::get.edgelist(G)
    ee <- ee[V(G)[V(G)$type == "cluster"]$highest_scoring_edge,]
    vv <- V(G)[as.numeric(ee[,2])]
    popsize <- V(G)[vv]$popsize
    dd <- data.frame(Landmark = ee[,1], popsize)
    dd <- ddply(dd, ~Landmark, function(x) {sum(x["popsize"])})
    dd <- cbind(dd, Percentage = dd$V1 / sum(dd$V1))
    names(dd) <- c("Landmark", "Cells", "Percentage")
    dd$Percentage <- signif(dd$Percentage * 100, digits = 4)
    return(dd)
}

get_fcs_col_names <- function(f.path)
{
    fcs.file <- flowCore::read.FCS(f.path)
    params <- flowCore::pData(flowCore::parameters(fcs.file))
    ret <- as.vector(params$desc)
    
    if(any(is.na(ret)))
    {
        w <- is.na(ret)
        ret[w] <- as.vector(params$name[w])
    }
    
    return(ret)
}




    