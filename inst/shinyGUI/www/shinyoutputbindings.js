class NetworkOutputBinding extends Shiny.OutputBinding {

    constructor() {
        super()
        this.selectedNodes = new Set()
        this.pixiGraph = new PixiGraph(
            (sel) => this.onNodeNewSelection(sel),
            (sel) => this.onNodeAddToSelection(sel)
        )

    }

    find(scope) {
        return $(scope).find('.shiny-network-output');
    }

    onNodeNewSelection(sel) {
        this.selectedNodes.clear()
        this.onNodeAddToSelection(sel)
    }

    onNodeAddToSelection(sel) {
        sel.forEach(i => this.selectedNodes.add(i))
        
        //Switch to 1-based indexing for R
        let selToR = Array.from(this.selectedNodes).map(i => i + 1)
        Shiny.onInputChange("graphui_selected_nodes", selToR)
    }

    renderValue(el, Rdata) {
        if(Rdata == null) return

        let data = {
            nodes: JSON.parse(Rdata.nodes),
            edges: JSON.parse(Rdata.edges)
        }

        this.pixiGraph.graphData = data

        if(!el.hasChildNodes())
            this.pixiGraph.addToDOM(el)
    }

    resetPosition() {
        this.pixiGraph.resetPosition()
    }

    toggleLandmarkLabels() {
        this.pixiGraph.toggleLandmarkLabels()
    }

    toggleClusterLabels() {
        this.pixiGraph.toggleClusterLabels()
    }
}

class VisControlOutputBinding extends Shiny.OutputBinding {

    constructor(networkOutputBinding) {
        super()
        this.pixiGraph = networkOutputBinding.pixiGraph

    }

    find(scope) {
        return $(scope).find('.shiny-vis-control')
    }

    renderValue(el, visControl) {
        if(!visControl)
            return

        this.pixiGraph.draw(visControl)
    }
}





let networkOutputBinding = new NetworkOutputBinding()
let visControlOutputBinding = new VisControlOutputBinding(networkOutputBinding)

Shiny.outputBindings.register(networkOutputBinding, 'networkbinding');
Shiny.outputBindings.register(visControlOutputBinding, 'viscontrolbinding');


Shiny.addCustomMessageHandler("reset_graph_position",
    value => networkOutputBinding.resetPosition()
)

Shiny.addCustomMessageHandler("toggle_landmark_labels",
    value => networkOutputBinding.toggleLandmarkLabels()
)

Shiny.addCustomMessageHandler("toggle_cluster_labels",
    value => networkOutputBinding.toggleClusterLabels()
)


///////



function display_edge(option_val, edge_type)
{
    if(option_val == "All")
        return true;
    else if(option_val == "Inter cluster")
        return(edge_type == "inter_cluster");
    else if(option_val == "To landmark")
        return(edge_type == "cluster_to_landmark" || edge_type == "highest_scoring");
    else if(option_val == "Highest scoring")
        return(edge_type == "highest_scoring");
    else
        return(false);
}

Shiny.addCustomMessageHandler("reset_colors",
    function(value)
    {
        d3.selectAll(".node").style("fill", "");
    }
);






Shiny.addCustomMessageHandler("toggle_display_edges",
    function(value)
    {
        d3.selectAll(".link").style("display", function(d) {return(display_edge(value, d.edge_type) ? "" : "none")});
        /*if(value == "All")
            d3.selectAll(".link").style("display", "");
        else if(value == "Inter cluster")
            d3.selectAll(".link").style("display", function(d) {return(d.type == "inter_cluster" ? "" : "none")});
        else if(value == "To landmark")
            d3.selectAll(".link").style("display", function(d) {return((d.type == "cluster_to_landmark" || d.type == "highest_scoring") ? "" : "none")});
        else if(value == "Highest scoring")
            d3.selectAll(".link").style("display", function(d) {return(d.type == "highest_scoring" ? "" : "none")});*/
    }
);
