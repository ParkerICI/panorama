

class PixiGraph {
    
    constructor(onNodeNewSelection, onNodeAddToSelection) {
        this.renderer = new PIXI.WebGLRenderer({ antialias: true, interactive: true })
        //this.renderer.roundPixels = true
        this.renderer.backgroundColor = 0xFFFFFF

        this.rootContainer = new PIXI.Container()
        
        this.graphContainer = new PIXI.Container()
        this.nodeContainer = new PIXI.Container()
        this.edgeContainer = new PIXI.Container()
        this.textContainer = new PIXI.Container()
        this.graphContainer.interactive = true
        //this.nodeContainer.interactive = true
        
        this.graphContainer.addChild(this.edgeContainer)
        this.graphContainer.addChild(this.nodeContainer)
        this.graphContainer.addChild(this.textContainer)
        this.rootContainer.addChild(this.graphContainer)
        this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, this.renderer.width, this.renderer.height)
        
        this.circleTexture = PixiGraph.getCircleTexture()

        // This is used to make sure different graphs are always drawn in the same position
        this.maxXOffset = 0 
        this.maxYOffset = 0

        this.onNodeAddToSelection = onNodeAddToSelection
        this.onNodeNewSelection = onNodeNewSelection

       
    }

    set graphData(data) {
        this.data = data

        let minX = d3.min(this.data.nodes, d => d.x)
        let minY = d3.min(this.data.nodes, d => d.y)

        if(minX < 0 && (Math.abs(minX) > this.maxXOffset))
            this.maxXOffset = Math.abs(minX)

        if(minY < 0 && (Math.abs(minY) > this.maxYOffset))
            this.maxYOffset = Math.abs(minY)
        
        let xPadding = 50 + this.maxXOffset
        let yPadding = 50 + this.maxYOffset

        this.data.nodes = this.data.nodes.map(d => {
            let ret = d
            ret.x += xPadding
            ret.y += yPadding 
            return(ret)
        })

        this.data.edges = this.data.edges.map(d => {
            let ret = d
            ret.x1 += xPadding; ret.x2 += xPadding
            ret.y1 += yPadding; ret.y2 += yPadding
            return(ret)
        })

        // TODO: Modify this to generate a texture in stead of 
        // PIXI.Graphics objects

        this.nodeContainer.removeChildren()
        this.edgeContainer.removeChildren()
        this.textContainer.removeChildren()

        this.edgeGraphics = new PIXI.Graphics()
        this.edgeGraphics.lineStyle(1, 0xE6E6E6, 1)

        this.data.edges.forEach(d => {
            this.edgeGraphics.moveTo(d.x1, d.y1)
            this.edgeGraphics.lineTo(d.x2, d.y2)
            this.edgeGraphics.endFill()
        
        })


        this.edgeContainer.addChild(this.edgeGraphics)

        this.data.nodes.map((d, i) => {
            let sprite = this.getCircleSprite()
            sprite.x = d.x
            sprite.y = d.y
            sprite.interactive = true
            
            //Given that the anchor point is in the middle the x and y of the hitArea are 0
            //Also 50 is the radius of the original sprite that then gets scaled down
            sprite.hitArea = new PIXI.Circle(0, 0, 50)

            sprite.mousedown = e => {
                if (e.data.originalEvent.shiftKey) {
                    e.currentTarget.tint = 0xFF0000
                    this.onNodeAddToSelection([i])
                }
            }

            let col = null

            sprite.anchor = new PIXI.Point(0.5, 0.5)
            this.nodeContainer.addChild(sprite)

            let label = new PIXI.Text(d.Label)
            let fontSize = 12
            label.visible = false
            
            if(d.type && d.type == "landmark") {
                label.visible = true
                fontSize = 24 
            }
            
            label.style = {fontFamily : 'Arial', fontSize: fontSize, fill : 0x210E0F, align : 'left', strokeThickness:1}
            label.position = new PIXI.Point(d.x, d.y)
            label.resolution = 2

            this.textContainer.addChild(label)
        })

        
    }

    static getNodeFillScale(nodes, visControl) {
        let ret = null
        console.log(visControl)
        ret = d3.scale.linear()
                .domain(visControl.colorScaleDomain)
                .range(visControl.colorScaleRange)
			    .interpolate(d3.interpolateLab)        
        return ret
    }
    
    getCircleSprite() {
        let sprite = new PIXI.Sprite(this.circleTexture)
        return(sprite)
    }
    


    static getNodeSizeScale(nodes, visControl) {
        let ret = null

        let v = nodes.filter(d => !d.type || d.type != "landmark")

        if (visControl.nodeSizeAttr != null) {
            ret = d3.scale.linear()
                    .range([visControl.minNodeSize, visControl.maxNodeSize])
                    .domain(d3.extent(visControl.nodeSizeAttr))
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
    
    
    resetPosition() {
        this.graphContainer.scale.x = 1
        this.graphContainer.scale.y = 1

        this.graphContainer.position.x = 0
        this.graphContainer.position.y = 0

        this.renderer.render(this.rootContainer)
    }

    toggleLandmarkLabels() {
        this.textContainer.children.forEach((d, i) => {
            let node = this.data.nodes[i]
            if(node.type && node.type == "landmark")
                d.visible = !d.visible
        })
        this.renderer.render(this.rootContainer)
    }

    toggleClusterLabels() {
        this.textContainer.children.forEach((d, i) => {
            let node = this.data.nodes[i]
            if(!node.type || node.type == "cluster")
                d.visible = !d.visible
        })
        this.renderer.render(this.rootContainer)
    }

    addToDOM(domEl) {
        domEl.appendChild(this.renderer.view)
        this.addDragNDrop()
        
        let zoom = (x, y, isZoomIn) => {
            let beforeTransform = this.renderer.plugins.interaction.eventData.data.getLocalPosition(this.graphContainer)
            
            let direction = isZoomIn ? 1 : -1
            let factor = (1 + direction * 0.1)
            //this.edgeContainer.visible = false
            this.graphContainer.scale.x *= factor
            this.graphContainer.scale.y *= factor
            this.graphContainer.updateTransform()
            
            
            setTimeout(() => { this.edgeContainer.visible = true; this.renderer.render(this.rootContainer) }, 200)
            
            
            this.graphContainer.updateTransform()
            let afterTransform = this.renderer.plugins.interaction.eventData.data.getLocalPosition(this.graphContainer)
            
            this.graphContainer.position.x += (afterTransform.x - beforeTransform.x) * this.graphContainer.scale.x
            this.graphContainer.position.y += (afterTransform.y - beforeTransform.y) * this.graphContainer.scale.y
            this.graphContainer.updateTransform()
            this.renderer.render(this.rootContainer)
        }
        
        
        
        
        domEl.addEventListener("wheel", e => {
            e.stopPropagation()
            e.preventDefault()
            zoom(e.clientX, e.clientY, e.deltaY < 0)
        })

        this.resize(domEl.offsetWidth, window.innerHeight * 0.8)

        window.addEventListener("resize", e => {
            this.resize(domEl.offsetWidth, window.innerHeight * 0.8)
        })

        
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
                //edgeContainer.visible = false
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
                let rect = null
                if(rectWidth < 0)
                    rect = new PIXI.Rectangle(mouseDownX + rectWidth, mouseDownY + rectHeight,
                        Math.abs(rectWidth), Math.abs(rectHeight))
                else
                    rect = new PIXI.Rectangle(mouseDownX, mouseDownY, rectWidth, rectHeight)

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
                this.onNodeNewSelection(curSelNodesIdx)
            }
            isDragging = false
            isSelecting = false
        }
    }

    resize(width, height) {
        this.renderer.resize(width, height)
        this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, this.renderer.width, this.renderer.height)
    }

    draw(visControl) {
        if(!this.data)
            return
        
        let nodes = this.data.nodes
        let edges = this.data.edges
        let nodeFillScale = PixiGraph.getNodeFillScale(nodes, visControl)
        let nodeSizeScale = PixiGraph.getNodeSizeScale(nodes, visControl)
        
        this.nodeContainer.children.forEach((sprite, i) => {            
            let node = this.data.nodes[i]
            let size = 0
            
            if(node.type && node.type == "landmark")
                size = visControl.landmarkNodeSize
            else {
                if(visControl.nodeSizeAttr == null)
                    size = 0.8 * visControl.landmarkNodeSize
                else
                    size = nodeSizeScale(visControl.nodeSizeAttr[i])
            }
            
            sprite.scale.x = 0.005 * size
            sprite.scale.y = 0.005 * size

            let col = null

            if(visControl.nodeColorAttr == null) {
                if(node.type && node.type == "landmark") 
                    col = 0xFF7580
                else
                    col = 0x4F93DE
            }
            else {
                let domain = visControl.colorScaleDomain
                if(visControl.nodeColorAttr[i] > domain[domain.length - 1])
                    col = parseInt(visControl.colorOver.substr(1, 7), 16)
                else if(visControl.nodeColorAttr[i] < domain[0])
                    col = parseInt(visControl.colorUnder.substr(1, 7), 16)
                else
                    col = parseInt(nodeFillScale(visControl.nodeColorAttr[i]).substr(1, 7), 16)
            }
            
            sprite.tint = col
            sprite.cachedTint = col
        })
        
        if (visControl.selectedNodesIdx && visControl.selectedNodesIdx.length) 
            visControl.selectedNodesIdx.forEach(i => nodeContainer.getChildAt(i).tint = 0xFF0000)
        
        this.renderer.render(this.rootContainer)
    }
    
}

