

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

get_graph_centering_transform <- function(x, y, svg.width, svg.height) {
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

get_summary_table <- function(sc.data, sel.graph, sel.nodes) {
    G <- sc.data$graphs[[sel.graph]]
    col.names <- get_numeric_vertex_attributes(sc.data)
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


export_clusters <- function(working.dir, sel.graph, sel.nodes) {
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



graph_to_json <- function(G, sel.edges = NULL) {
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
    edges <- cbind(edges, id = 1:nrow(edges))
    
    if(!is.null(sel.edges)) {
        edges.df <- igraph::get.data.frame(G, what = "edges")
        if(sel.edges == "Highest scoring")
            edges <- edges[edges.df$highest_scoring == 1, ]
        else if(sel.edges == "To landmark")
            edges <- edges[edges.df$cluster_to_landmark == 1, ]
        else if(sel.edges == "Inter cluster")
            edges <- edges[edges.df$inter_cluster == 1, ]
    }
    
    
    nodes <- igraph::get.data.frame(G, what = c("vertices"))
    nodes$x <- x
    nodes$y <- y
   
    
    nodes <- nodes[, c("x", "y", "Label", "popsize")]
    
    if(!is.null(V(G)$type))
       nodes$type <- V(G)$type
    
    ret <- list(nodes = jsonlite::toJSON(nodes), edges = jsonlite::toJSON(edges))
    return(ret)
}



get_vertex_attributes <- function(G) {
    d <- igraph::get.data.frame(G, what = "vertices")
    #Don't consider attributes which are only present in the landmarks
    d <- d[d$type == "cluster",]
    #num <- sapply(d, function(x) {is.numeric(x) && !any(is.na(x))})
    v <- igraph::list.vertex.attributes(G) #[num]
    v <- v[grep("@", v, invert = T)]
    exclude <- c("x", "y", "cellType", "type", "groups", "r", "g", "b", "size", "DNA1", "DNA2", "BC1", "BC2", "BC3", "BC4", "BC5", "BC6", "Time", "Cell_length", "Cisplatin", "beadDist", "highest_scoring_edge")
    return(v[!(v %in% exclude)])
}

get_number_of_cells_per_landmark <- function(sc.data, sel.graph) {
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






    