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



let pixiGraph = new PixiGraph(1200, 800, null);

let visControlOutputBinding = new Shiny.OutputBinding();


$.extend(visControlOutputBinding, {
    find: scope => {
        return $(scope).find('.shiny-vis-control');
    },
    
    renderValue: (el, visControl) => {
        if(!visControl)
            return
        
        pixiGraph.draw(visControl)
    }
})

Shiny.outputBindings.register(visControlOutputBinding, 'viscontrolbinding');


let networkOutputBinding = new Shiny.OutputBinding();

$.extend(networkOutputBinding, {

         find: scope => {
            return $(scope).find('.shiny-network-output');
         },

         renderValue: (el, Rdata) => {
            if(Rdata == null) return;

            if(!el.hasChildNodes())
                pixiGraph.addToDOM(el, () => {}, () => {})
            
            let data = {
                nodes: JSON.parse(Rdata.nodes),
                edges: JSON.parse(Rdata.edges)
            }

            pixiGraph.data = data
            
            function rescale()
            {
                let transString = "translate(" + d3.event.translate + ") scale(" + d3.event.scale + ")";
                vis.attr("transform", transString);
                //Shiny.onInputChange("graphui_cur_transform", transString);
            }

                    
         }
    });
Shiny.outputBindings.register(networkOutputBinding, 'networkbinding');

Shiny.addCustomMessageHandler("color_nodes",
    function(color)
    {
        //This is necessary to restore the data that is overwritten by
        //the color command
        let old_data = d3.selectAll(".node").data();
        d3.selectAll(".node")
            .data(color)
            .style("fill", function(d) {return d; });
        d3.selectAll(".node").data(old_data);

    }
);

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
