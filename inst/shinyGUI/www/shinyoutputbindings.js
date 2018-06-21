class NetworkOutputBinding extends Shiny.OutputBinding {

    constructor(width, height) {
        super()
        this.selectedNodes = new Set()
        this.pixiGraph = new PixiGraph(width, height, null) 
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

        if(!el.hasChildNodes())
            this.pixiGraph.addToDOM(el, 
                (sel) => this.onNodeNewSelection(sel),
                (sel) => this.onNodeAddToSelection(sel)
            )
        
        let data = {
            nodes: JSON.parse(Rdata.nodes),
            edges: JSON.parse(Rdata.edges)
        }

        this.pixiGraph.data = data
        
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





let networkOutputBinding = new NetworkOutputBinding(1200, 800)
let visControlOutputBinding = new VisControlOutputBinding(networkOutputBinding)

Shiny.outputBindings.register(networkOutputBinding, 'networkbinding');
Shiny.outputBindings.register(visControlOutputBinding, 'viscontrolbinding');



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

function parse_trans_string (a)
{
    //This requires the different arguments (transl, scale etc.) to be space-delimited
    let b = {};
    console.log(a);
    for (let i in a = a.match(/(\w+\((\-?\d+\.?\d*e?\-?\d*,?)+\))+/g))
    {
        let c = a[i].match(/[\w\.\-]+/g);
        b[c.shift()] = c;
    }
    return b;
}


Shiny.addCustomMessageHandler("reset_colors",
    function(value)
    {
        d3.selectAll(".node").style("fill", "");
    }
);

Shiny.addCustomMessageHandler("reset_graph_position",
    function(value)
    {
        d3.select("g").attr("transform", "");
    }
);

Shiny.addCustomMessageHandler("toggle_label",
    function(value)
    {
        let target = value.target == "cluster" ? ".label-cluster" : ".label-landmark";
        d3.selectAll(target).style("display", value.display);
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

Shiny.addCustomMessageHandler("get_selected_nodes",
    function(value)
    {
        let res = d3.selectAll(".selected").data().map(function(d) {return(d.name)});
        Shiny.onInputChange("graphui_selected_nodes", res);
    }
);


Shiny.addCustomMessageHandler("toggle_node_size",
    function(value)
    {
        if(value.display == "proportional")
            d3.selectAll("circle.node").attr("r", function(d) {return d.size;});
        else if(value.display == "default")
            d3.selectAll("circle.node").attr("r", function(d) {return d.type == "1" ? "8" : "5"});
    }
);


//</script>
