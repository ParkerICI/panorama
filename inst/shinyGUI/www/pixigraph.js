

class PixiGraph {
    
    constructor(width, height, data) {
        this.data = data
        this.renderer = new PIXI.WebGLRenderer(width, height, { antialias: true, interactive: true })
        this.renderer.backgroundColor = 0xFFFFFF

        this.rootContainer = new PIXI.Container()
        
        this.graphContainer = new PIXI.Container()
        this.nodeContainer = new PIXI.Container()
        this.edgeContainer = new PIXI.Container()
        this.graphContainer.interactive = true
        this.nodeContainer.interactive = true
        
        this.graphContainer.addChild(this.edgeContainer)
        this.graphContainer.addChild(this.nodeContainer)
        this.rootContainer.addChild(this.graphContainer)
        this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, width, height)

        this.circleTexture = PixiGraph.getCircleTexture()
    }


    static getNodeFillScale(nodes, visControl) {
        let ret = null
        
        if (visControl.nodeColorAttr && visControl.nodeColorAttr != "") {
            let attr = visControl.nodeColorAttr
            ret = d3.scale.linear()
                    .domain(d3.extent(nodes, d => d[attr]))
                    .range([visControl.colorMin, visControl.colorMax])
			        .interpolate(d3.interpolateLab)
        }
        else
            ret = val => ""
        return ret
    }
    
    getCircleSprite() {
        let sprite = new PIXI.Sprite(this.circleTexture)
        return(sprite)
    }
    
    static getEdgeGraphics(edges) {
        let graphics = new PIXI.Graphics()
        graphics.lineStyle(1, 0xE6E6E6, 1)

        edges.forEach(d => {
            graphics.moveTo(d.x1, d.y1)
            graphics.lineTo(d.x2, d.y2)
            graphics.endFill()
        
        })

        return(graphics)
    }

    static getNodeSizeScale(nodes, visControl) {
        let ret = null

        let v = nodes.filter(d => !d.type || d.type != "landmark")

        if (visControl.nodeSize == "Proportional") {
            ret = d3.scale.linear()
                    .range([visControl.minNodeSize, visControl.maxNodeSize])
                    .domain(d3.extent(v, d => d.popsize))
        }
        else //Return a constant number
            ret = val => 0.8 * visControl.landmarkNodeSize
        return ret
    }
    
    
    
    
    
    static getCircleTexture() {
        let renderer = new PIXI.CanvasRenderer(100, 100, { antialias: true, transparent: true })
        renderer.backgroundColor = 0xFFFFFF
        let graphics = new PIXI.Graphics()
        graphics.beginFill(0x000000)
        graphics.drawCircle(50, 50, 50)
        graphics.beginFill(0xFFFFFF)
        graphics.drawCircle(50, 50, 45)
        let container = new PIXI.Container()
        
        
        container.addChild(graphics)
        renderer.render(container)
        return (PIXI.Texture.fromCanvas(renderer.view))
    }
    
    
    
    addToDOM(domEl, onNodeNewSelection, onNodeAddToSelection) {
        domEl.appendChild(this.renderer.view)

        this.onNodeNewSelection = onNodeNewSelection

        this.onNodeAddToSelection = onNodeAddToSelection
        
        let zoom = (function (rootContainer, graphContainer, 
            edgeContainer, renderer) {
            return function (x, y, isZoomIn) {
                let beforeTransform = renderer.plugins.interaction.eventData.data.getLocalPosition(graphContainer)
                
                let direction = isZoomIn ? 1 : -1
                let factor = (1 + direction * 0.1)
                edgeContainer.visible = false
                graphContainer.scale.x *= factor
                graphContainer.scale.y *= factor
                graphContainer.updateTransform()
                
                
                setTimeout(function () { edgeContainer.visible = true; renderer.render(rootContainer) }, 200)
                
                
                graphContainer.updateTransform()
                let afterTransform = renderer.plugins.interaction.eventData.data.getLocalPosition(graphContainer)
                
                graphContainer.position.x += (afterTransform.x - beforeTransform.x) * graphContainer.scale.x
                graphContainer.position.y += (afterTransform.y - beforeTransform.y) * graphContainer.scale.y
                graphContainer.updateTransform()
                renderer.render(rootContainer)
            }
        })(this.rootContainer, this.graphContainer, this.edgeContainer, this.renderer)
        
        
        
        domEl.addEventListener("wheel", e => {
            e.stopPropagation()
            e.preventDefault()
            zoom(e.clientX, e.clientY, e.deltaY < 0)
        })

        this.addDragNDrop()
    }
    
    addDragNDrop() {
        let isDragging = false,
            prevX, prevY,
            mouseDownX, mouseDownY
        let isSelecting = false
        let rectangleContainer = new PIXI.Container
        let nodeContainer = this.nodeContainer
        let edgeContainer = this.edgeContainer
        let graphContainer = this.graphContainer
        graphContainer.addChild(rectangleContainer)

        let renderer = this.renderer
        let curSelNodesIdx = []
        let onNodeNewSelection = this.onNodeNewSelection
  
        

        let clearCurrentSelection = () => {
            rectangleContainer.removeChildren()
            nodeContainer.children.forEach(n => n.tint = n.cachedTint)
        }
        
        graphContainer.mousedown = e => {
            let pos = e.data.getLocalPosition(graphContainer)
            prevX = pos.x
            prevY = pos.y
            
            mouseDownX = prevX
            mouseDownY = prevY
            if (e.data.originalEvent.altKey) {
                isSelecting = true
                clearCurrentSelection()
            }
            else {
                isDragging = true
                edgeContainer.visible = false
            }
            renderer.render(graphContainer)
        }
    
        graphContainer.mousemove = e => {
            let pos = e.data.getLocalPosition(graphContainer)
            
            if (isDragging) {
                let dx = pos.x - mouseDownX
                let dy = pos.y - mouseDownY
                
                graphContainer.position.x += dx
                graphContainer.position.y += dy
                graphContainer.updateTransform()
                
                prevX = pos.x; prevY = pos.y
            }
            else if (isSelecting) {
                clearCurrentSelection()
                let rectWidth = pos.x - mouseDownX
                let rectHeight = pos.y - mouseDownY
                let rectGraphics = new PIXI.Graphics()
                rectGraphics.lineStyle(2, 0xFF0000)
                rectGraphics.drawRect(
                    mouseDownX,
					mouseDownY,
					rectWidth,
					rectHeight 
                )
                rectangleContainer.addChild(rectGraphics)
                let rect = new PIXI.Rectangle(mouseDownX, mouseDownY, rectWidth, rectHeight)
                curSelNodesIdx = []
                nodeContainer.children.forEach((n, i) => {
                    if (rect.contains(n.x, n.y)) {
                        n.tint = 0xFF0000
                        curSelNodesIdx.push(i)
                    }
                })
            }
            renderer.render(graphContainer)

        }
        
        graphContainer.mouseup = e => {

            rectangleContainer.removeChildren()
            edgeContainer.visible = true
            renderer.render(graphContainer)
            if (isSelecting) {
                onNodeNewSelection(curSelNodesIdx)
            }
            isDragging = false
            isSelecting = false
        }
    }

    draw(visControl) {

        if(!this.data)
            return

        let nodes = this.data.nodes
        let edges = this.data.edges
        let nodeContainer = this.nodeContainer
        let nodeRimContainer = this.nodeRimContainer
        let edgeContainer = this.edgeContainer
        let graphContainer = this.graphContainer
        let onNodeAddToSelection = this.onNodeAddToSelection
        let onNodeNewSelection = this.onNodeNewSelection
        let nodeFillScale = PixiGraph.getNodeFillScale(nodes, visControl)
        let nodeSizeScale = PixiGraph.getNodeSizeScale(nodes, visControl)
        
        nodeContainer.removeChildren()
        edgeContainer.removeChildren()

        let edgeGraphics = PixiGraph.getEdgeGraphics(edges)
        edgeContainer.addChild(edgeGraphics)
        
        nodes.map((d, i) => {
            let sprite = this.getCircleSprite()
            sprite.x = d.x
            sprite.y = d.y
            sprite.interactive = true
            
            let size = 0
            
            if(d.type && d.type == "landmark")
                size = visControl.landmarkNodeSize
            else
                size = nodeSizeScale(d.popsize)
            
            sprite.scale.x = 0.005 * size
            sprite.scale.y = 0.005 * size
            //Given that the anchor point is in the middle the x and y of the hitArea are 0
            //Also 50 is the radius of the original sprite that then gets scaled down
            sprite.hitArea = new PIXI.Circle(0, 0, 50)

            sprite.mousedown = e => {
                if (e.data.originalEvent.shiftKey) {
                    e.currentTarget.tint = 0xFF0000
                    onNodeAddToSelection(i)
                }
            }
            /*
            sprite.mouseover = function (e) {
                console.log("Hovering")
            }*/
            let col = null

            if(visControl.nodeColorAttr == "Default") {
                if(d.type && d.type == "landmark")
                    col = 0xFF7580
                else
                    col = 0x4F93DE

            }
            else
                col = parseInt(nodeFillScale(d[visControl.nodeColorAttr]).substr(1, 7), 16)
            
            sprite.tint = col
            sprite.cachedTint = col
            sprite.anchor = new PIXI.Point(0.5, 0.5)

            nodeContainer.addChild(sprite)
        })
        
        
        if (visControl.selectedNodesIdx && visControl.selectedNodesIdx.length) 
            visControl.selectedNodesIdx.forEach(i => nodeContainer.getChildAt(i).tint = 0xFF0000)
        
        this.renderer.render(this.rootContainer)
    }
    
}

