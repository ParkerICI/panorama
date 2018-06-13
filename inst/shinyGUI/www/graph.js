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
    var b = {};
    console.log(a);
    for (var i in a = a.match(/(\w+\((\-?\d+\.?\d*e?\-?\d*,?)+\))+/g))
    {
        var c = a[i].match(/[\w\.\-]+/g);
        b[c.shift()] = c;
    }
    return b;
}




class PixiGraph {
    
    constructor(data) {
        this.data = data
    }


    getNodeFillScale(nodes, visControl) {
        var ret = null;
        
        if (visControl.nodeColorAttr && visControl.nodeColorAttr != "") {
            var attr = visControl.nodeColorAttr;
            ret = d3.scale.linear()
                    .domain(d3.extent(nodes, d => d[attr]))
                    .range([visControl.colorMin, visControl.colorMax])
			        .interpolate(d3.interpolateLab);
        }
        else
            ret = val => ""
        return ret;
    };
    
    
    
    
    getNodeSizeScale(nodes, visControl) {
        var ret = null;

        var v = nodes.filter(d => !d.type || d.type != "landmark")

        if (visControl.nodeSize == "Proportional") {
            ret = d3.scale.linear()
                    .range([visControl.minNodeSize, visControl.maxNodeSize])
                    .domain(d3.extent(v, d => d.popsize));
        }
        else //Return a constant number
            ret = val => 0.8 * visControl.landmarkNodeSize
        return ret;
    };
    
    
    
    
    
    getCircleTexture() {
        var renderer = new PIXI.CanvasRenderer(100, 100, { antialias: true, transparent: true });
        renderer.backgroundColor = 0xFFFFFF;
        var graphics = new PIXI.Graphics();
        graphics.beginFill(parseInt("FFFFFF", 16));
        graphics.drawCircle(50, 50, 50);
        var container = new PIXI.Container();
        
        
        container.addChild(graphics);
        renderer.render(container);
        return (PIXI.Texture.fromCanvas(renderer.view))
    }
    
    
    
    addToDOM(domEl, width, height, onNodeNewSelection, onNodeAddToSelection) {
        this.renderer = new PIXI.WebGLRenderer(width, height, { antialias: true, interactive: true });
        this.renderer.backgroundColor = 0xFFFFFF;
        
        // add the renderer view element to the DOM
        domEl.appendChild(this.renderer.view);
        this.rootContainer = new PIXI.Container();
        
        this.graphContainer = new PIXI.Container();
        this.nodeContainer = new PIXI.Container();
        this.edgeContainer = new PIXI.Container();
        this.graphContainer.interactive = true;
        this.nodeContainer.interactive = true;
        
        this.graphContainer.addChild(this.edgeContainer);
        this.graphContainer.addChild(this.nodeContainer);
        this.rootContainer.addChild(this.graphContainer);
        this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, width, height);
        this.onNodeNewSelection = onNodeNewSelection;

        this.onNodeAddToSelection = onNodeAddToSelection;
        
        var zoom = (function (rootContainer, graphContainer, 
            edgeContainer, renderer) {
            return function (x, y, isZoomIn) {
                var beforeTransform = renderer.plugins.interaction.eventData.data.getLocalPosition(graphContainer);
                
                var direction = isZoomIn ? 1 : -1;
                var factor = (1 + direction * 0.1);
                edgeContainer.visible = false;
                graphContainer.scale.x *= factor;
                graphContainer.scale.y *= factor;
                graphContainer.updateTransform();
                
                
                setTimeout(function () { edgeContainer.visible = true; renderer.render(rootContainer) }, 200);
                
                
                graphContainer.updateTransform();
                var afterTransform = renderer.plugins.interaction.eventData.data.getLocalPosition(graphContainer);
                
                graphContainer.position.x += (afterTransform.x - beforeTransform.x) * graphContainer.scale.x;
                graphContainer.position.y += (afterTransform.y - beforeTransform.y) * graphContainer.scale.y;
                graphContainer.updateTransform();
                renderer.render(rootContainer);
            }
        })(this.rootContainer, this.graphContainer, this.edgeContainer, this.renderer);
        
        
        
        domEl.addEventListener("wheel", e => {
            e.stopPropagation();
            e.preventDefault();
            zoom(e.clientX, e.clientY, e.deltaY < 0);
        });

        this.addDragNDrop();
    }
    
    addDragNDrop() {
        var isDragging = false,
            prevX, prevY,
            mouseDownX, mouseDownY;
        var isSelecting = false;
        var rectangleContainer = new PIXI.Container;
        var nodeContainer = this.nodeContainer;
        var edgeContainer = this.edgeContainer;
        var graphContainer = this.graphContainer;
        graphContainer.addChild(rectangleContainer);

        var renderer = this.renderer;
        var curSelNodesIdx = [];
        var onNodeNewSelection = this.onNodeNewSelection;
  
        

        var clearCurrentSelection = () => {
            rectangleContainer.removeChildren();
            nodeContainer.children.forEach(n => n.tint = n.cachedTint)
        }
        
        graphContainer.mousedown = e => {
            var pos = e.data.getLocalPosition(graphContainer);
            prevX = pos.x;
            prevY = pos.y;
            
            mouseDownX = prevX;
            mouseDownY = prevY;
            if (e.data.originalEvent.altKey) {
                isSelecting = true;
                clearCurrentSelection();
            }
            else {
                isDragging = true;
                edgeContainer.visible = false;
            }
            renderer.render(graphContainer);
        };
        
        graphContainer.mousemove = e => {
            var pos = e.data.getLocalPosition(graphContainer);
            
            if (isDragging) {
                var dx = pos.x - mouseDownX;
                var dy = pos.y - mouseDownY;
                
                graphContainer.position.x += dx;
                graphContainer.position.y += dy;
                graphContainer.updateTransform();
                
                prevX = pos.x; prevY = pos.y;
            }
            else if (isSelecting) {
                clearCurrentSelection();
                var rectWidth = pos.x - mouseDownX;
                var rectHeight = pos.y - mouseDownY;
                var rectGraphics = new PIXI.Graphics();
                rectGraphics.lineStyle(2, 0xFF0000);
                rectGraphics.drawRect(
                    mouseDownX,
					    mouseDownY,
					    rectWidth,
					    rectHeight 
                );
                rectangleContainer.addChild(rectGraphics);
                var rect = new PIXI.Rectangle(mouseDownX, mouseDownY, rectWidth, rectHeight);
                curSelNodesIdx = [];
                nodeContainer.children.forEach((n, i) => {
                    if (rect.contains(n.x, n.y)) {
                        n.tint = 0xFF0000;
                        curSelNodesIdx.push(i);
                    }
                });
            }
            renderer.render(graphContainer);

        };
        
        graphContainer.mouseup = e => {

            rectangleContainer.removeChildren();
            edgeContainer.visible = true;
            renderer.render(graphContainer);
            if (isSelecting) {
                onNodeNewSelection(curSelNodesIdx);
            }
            isDragging = false;
            isSelecting = false;
        };
    }

    draw(visControl) {

        if(!this.data)
            return;

        var nodes = this.data.nodes;
        var edges = this.data.edges;
        var nodeContainer = this.nodeContainer;
        var edgeContainer = this.edgeContainer;
        var graphContainer = this.graphContainer;
        var onNodeAddToSelection = this.onNodeAddToSelection;
        var onNodeNewSelection = this.onNodeNewSelection;
        var nodeFillScale = this.getNodeFillScale(nodes, visControl);
        var nodeSizeScale = this.getNodeSizeScale(nodes, visControl);
        
        var circleSprite = this.getCircleTexture();
        
        nodeContainer.removeChildren();
        edgeContainer.removeChildren();
 
        var graphics = new PIXI.Graphics();

        graphics.lineStyle(1, 0xE6E6E6, 1);

        edges.map(d => {
            graphics.moveTo(d.x1, d.y1)
            graphics.lineTo(d.x2, d.y2)
            graphics.endFill();
        
        })

        edgeContainer.addChild(graphics);
        
        nodes.map((d, i) => {
            var sprite = new PIXI.Sprite(circleSprite);
            sprite.x = d.x;
            sprite.y = d.y;
            sprite.interactive = true;
            
            var size = 0
            
            if(d.type && d.type == "landmark")
                size = visControl.landmarkNodeSize
            else
                size = nodeSizeScale(d.popsize);
            
            sprite.scale.x = 0.005 * size;
            sprite.scale.y = 0.005 * size;
            //Given that the anchor point is in the middle the x and y of the hitArea are 0
            //Also 50 is the radius of the original sprite that then gets scaled down
            sprite.hitArea = new PIXI.Circle(0, 0, 50);

            sprite.mousedown = e => {
                if (e.data.originalEvent.shiftKey) {
                    onNodeAddToSelection([i]);
                }
            }
            /*
            sprite.mouseover = function (e) {
                console.log("Hovering");
            }*/
            var col = null

            if(visControl.nodeColorAttr == "Default") {
                if(d.type && d.type == "landmark")
                    col = 0xFF7580
                else
                    col = 0x4F93DE

            }
            else
                col = parseInt(nodeFillScale(d[visControl.nodeColorAttr]).substr(1, 7), 16);
            
                sprite.tint = col;
            sprite.cachedTint = col;
            sprite.anchor = new PIXI.Point(0.5, 0.5);
            nodeContainer.addChild(sprite);

        });
        
        
        if (visControl.selectedNodesIdx && visControl.selectedNodesIdx.length) 
            visControl.selectedNodesIdx.forEach(i => nodeContainer.getChildAt(i).tint = 0xFF0000);
               
        this.renderer.render(this.rootContainer);
    }
    
}


var pixiGraph = new PixiGraph(null);

var visControlOutputBinding = new Shiny.OutputBinding();


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


var networkOutputBinding = new Shiny.OutputBinding();

$.extend(networkOutputBinding, {

         find: scope => {
            return $(scope).find('.shiny-network-output');
         },

         renderValue: (el, Rdata) => {
            if(Rdata == null) return;

            if(!el.hasChildNodes())
                pixiGraph.addToDOM(el, 1200, 800, () => {}, () => {})
            
            var data = {
                nodes: JSON.parse(Rdata.nodes),
                edges: JSON.parse(Rdata.edges)
            }

            pixiGraph.data = data
            
            function rescale()
            {
                var transString = "translate(" + d3.event.translate + ") scale(" + d3.event.scale + ")";
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
        var old_data = d3.selectAll(".node").data();
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
        var target = value.target == "cluster" ? ".label-cluster" : ".label-landmark";
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
        var res = d3.selectAll(".selected").data().map(function(d) {return(d.name)});
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
