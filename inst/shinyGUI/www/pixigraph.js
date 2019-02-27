

class PixiGraph {
    
    constructor(onNodeNewSelection, onNodeAddToSelection) {
 
        this.renderer = new PIXI.WebGLRenderer({ antialias: true, interactive: true })  
        //this.renderer.roundPixels = true
        this.renderer.backgroundColor = 0xFFFFFF
        
        this.rootContainer = new PIXI.Container()
        this.legendOverlay = new PIXI.Container()
        this.rootContainer.addChild(this.legendOverlay)


        this.graphContainer = new PIXI.Container()
        this.nodeContainer = new PIXI.Container()
        this.pieContainer = new PIXI.Container()
        this.edgeContainer = new PIXI.Container()
        this.textContainer = new PIXI.Container()
        this.graphContainer.interactive = true
        //this.nodeContainer.interactive = true
        
        this.graphContainer.addChild(this.edgeContainer)
        this.graphContainer.addChild(this.nodeContainer)
        this.graphContainer.addChild(this.pieContainer)
        this.graphContainer.addChild(this.textContainer)
        this.rootContainer.addChild(this.graphContainer)
        //this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, this.renderer.width, this.renderer.height)
        
      
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

        let maxX = d3.max(this.data.nodes, d => d.x)
        let maxY = d3.max(this.data.nodes, d => d.y)

        this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, Math.ceil(maxX + (maxX * 0.1)), Math.ceil(maxY + (maxY * 0.1)))

        this.data.edges = this.data.edges.map(d => {
            let ret = d
            ret.x1 += xPadding; ret.x2 += xPadding
            ret.y1 += yPadding; ret.y2 += yPadding
            return(ret)
        })

        // TODO: Modify this to generate a texture instead of 
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
                fontSize = 16 
            }
            
            label.style = {fontFamily: 'Arial', fontSize: fontSize, fill: 0x210E0F, align: 'left', strokeThickness: 1}
            label.position = new PIXI.Point(d.x, d.y)
            label.anchor = new PIXI.Point(0, 0.5)
            label.resolution = 2

            this.textContainer.addChild(label)
        })

        
    }

    static getNodeFillScale(nodes, visControl) {
        let ret = null

        if(visControl.nodeColorAttr != null && (typeof visControl.nodeColorAttr[0] == "string")) {
            let s = new Set(visControl.nodeColorAttr)
            ret = d3.scaleOrdinal()
                    .domain(Array.from(s.values()))
                    .range(d3.schemeSet3)
        }
        else
            ret = d3.scaleLinear()
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
            ret = d3.scaleLinear()
                    .range([visControl.minNodeSize, visControl.maxNodeSize])
                    .domain(d3.extent(visControl.nodeSizeAttr))
        }
        else //Return a constant number
            ret = val => 0.8 * visControl.landmarkNodeSize
        return ret
    }
    
    

    static createPieSlice(x, y, height, theta) {
        let triangle = new PIXI.Graphics()
        triangle.beginFill(0xFFFFFF, 1)
        triangle.lineStyle(0, 0x000000, 1)
        triangle.moveTo(x, y)
        triangle.lineTo(x + height, y)
        triangle.arc(x, y, height, 0, theta * Math.PI/180)
        triangle.endFill();
        return(triangle)

    }


    static getPieSliceTexture(theta) {
        let renderer = new PIXI.CanvasRenderer(100, 100, { antialias: true, transparent: true })
        renderer.backgroundColor = 0xFFFFFF
        let triangle = this.createPieSlice(50, 0, 50, theta)

        let container = new PIXI.Container()
        container.addChild(triangle)
        renderer.render(container)
        return(PIXI.Texture.fromCanvas(renderer.view))
    }

    static getPieSliceSprite(texture) {
        let sprite = new PIXI.Sprite(texture)
        sprite.anchor.set(0.5, 0)
        return(sprite)
    }
    
    static colorToInt(color) {
        let col = d3.rgb(color)
        let ret = (col.r * 65536) + (col.g * 256) + col.b
        return(ret)
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

    toggleClusterLabels(selectedNodes) {
        if(selectedNodes == null || selectedNodes.length == 0)
            this.textContainer.children.forEach((d, i) => {
                let node = this.data.nodes[i]
                if(!node.type || node.type == "cluster")
                    d.visible = !d.visible
            })
        else
            selectedNodes.forEach(i => {
                let label = this.textContainer.children[i]
                label.visible = !label.visible
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
            renderer.render(this.rootContainer)
        }
    
        graphContainer.mousemove = e => {
            
            if (isDragging) {
                let pos = e.data.getLocalPosition(graphContainer)
                let dx = pos.x - mouseDownX
                let dy = pos.y - mouseDownY
                
                graphContainer.position.x += dx
                graphContainer.position.y += dy
                graphContainer.updateTransform()
                
                prevX = pos.x; prevY = pos.y
                renderer.render(this.rootContainer)
            }
            else if (isSelecting) {
                clearCurrentSelection()
                let pos = e.data.getLocalPosition(graphContainer)
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
                renderer.render(this.rootContainer)
            }
        }
        
        graphContainer.mouseup = e => {

            rectangleContainer.removeChildren()
            edgeContainer.visible = true
            renderer.render(this.rootContainer)
            if (isSelecting) {
                this.onNodeNewSelection(curSelNodesIdx)
            }
            isDragging = false
            isSelecting = false
        }
    }

    resize(width, height) {
        this.renderer.resize(width, height)
        //this.graphContainer.hitArea = new PIXI.Rectangle(0, 0, this.renderer.width, this.renderer.height)
        this.renderer.render(this.rootContainer)
    }

    drawLegendOverlay(nodeFillScale) {
        let domain = nodeFillScale.domain()
        let yPadding = 10

        domain.forEach((d, i) => {
            let sprite = this.getCircleSprite()
            let x = this.renderer.width * 0.02
            let y = this.renderer.height * 0.03 * i + yPadding

            sprite.x = x 
            sprite.y = y
            sprite.scale.x = 0.15
            sprite.scale.y = 0.15
            sprite.tint =  PixiGraph.colorToInt(nodeFillScale(d))

            let label = new PIXI.Text(d)
            label.style =  {fontFamily: 'Arial', fontSize: 12, fill: 0x210E0F, align: 'left', strokeThickness: 1}
            label.position = new PIXI.Point(x + 20, y)
            
            this.legendOverlay.addChild(sprite)
            this.legendOverlay.addChild(label)
        })
  
      


    }

    static getColorPie(v, colorScale, visControl) {
        let angle = 360 / v.length
        let container = new PIXI.Container()
        let texture = PixiGraph.getPieSliceTexture(angle)


        v.forEach((d, i) => {
            let sprite = PixiGraph.getPieSliceSprite(texture)
            if(d) {
                if(d < colorScale.domain()[0])
                    sprite.tint = parseInt(visControl.colorUnder.substr(1, 7), 16)
                else if(d > colorScale.domain()[2]) // [1] is the midpoint of the scale so we need [2]
                    sprite.tint = parseInt(visControl.colorOver.substr(1, 7), 16)
                else
                    sprite.tint = PixiGraph.colorToInt(colorScale(d))
            }
            else
                sprite.tint = 0x919191
            sprite.x = 50
            sprite.y = 50
            sprite.rotation = i * angle * (Math.PI / 180)
            container.addChild(sprite)
        })
        container.pivot.x = 50
        container.pivot.y = 50

        return(container)
    }

    getNodeSize(nodeIdx, visControl, nodeSizeScale) {
        let size = 0
        let node = this.data.nodes[nodeIdx]
        if(node.type && node.type == "landmark")
            size = visControl.landmarkNodeSize
        else {
            if(visControl.nodeSizeAttr == null)
                size = 0.8 * visControl.landmarkNodeSize
            else
                size = nodeSizeScale(visControl.nodeSizeAttr[nodeIdx])
        }
        return(size)
    }

    drawPies(visControl) {
        let allValues = Object.values(visControl.timeseriesData).flat()

        let colorScale = d3.scaleLinear()
            .domain(visControl.colorScaleDomain)
            .range(visControl.colorScaleRange)

        console.log(colorScale.domain())
        let nodeSizeScale = PixiGraph.getNodeSizeScale(this.data.nodes, visControl)
        let nodeIdx = 0

        this.nodeContainer.children.forEach((sprite, i) => {
            let node = this.data.nodes[i]
            if(!node.type || (node.type != "landmark")) {
                let v = visControl.timeseriesData[nodeIdx]
                if(v) {
                    let pie = PixiGraph.getColorPie(v, colorScale, visControl)
                    pie.x = sprite.x
                    pie.y = sprite.y
                    let size = this.getNodeSize(i, visControl, nodeSizeScale)
                    pie.scale.x = 0.005 * size
                    pie.scale.y = 0.005 * size
                    pie.rotation = 270 * (Math.PI / 180)
                    this.pieContainer.addChild(pie)
                }
                ++nodeIdx
            }
        })
    }

    draw(visControl) {
        if(!this.data)
            return

        this.pieContainer.removeChildren()
        this.legendOverlay.removeChildren()

        if (visControl.nodeColorAttr == "Timeseries") {
            if(!visControl.timeseriesData)
                return
            this.pieContainer.visible = true
            this.drawPies(visControl)
            // Draw a graph with default colors behind the pies
            visControl.nodeColorAttr = null
            this.drawGraph(visControl)        
        }
        else {
            this.pieContainer.visible = false
            this.drawGraph(visControl)
        }

        this.renderer.render(this.rootContainer)
    }

    drawGraph(visControl) {        
        let nodeFillScale = PixiGraph.getNodeFillScale(this.data.nodes, visControl)
        let nodeSizeScale = PixiGraph.getNodeSizeScale(this.data.nodes, visControl)

        if(visControl.nodeColorAttr != null && (typeof visControl.nodeColorAttr[0] == "string"))
            this.drawLegendOverlay(nodeFillScale)

        this.nodeContainer.children.forEach((sprite, i) => {            
            let node = this.data.nodes[i]
            let size = this.getNodeSize(i, visControl, nodeSizeScale)
            
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
                let attr = visControl.nodeColorAttr[i]
                col = PixiGraph.colorToInt(nodeFillScale(attr))
                
                if(typeof attr != "string") {
                    if(attr > domain[domain.length - 1])
                        col = parseInt(visControl.colorOver.substr(1, 7), 16)
                    else if(attr < domain[0])
                        col = parseInt(visControl.colorUnder.substr(1, 7), 16)
                }
            }
            
            sprite.tint = col
            sprite.cachedTint = col
        })
        
        if (visControl.selectedNodesIdx && visControl.selectedNodesIdx.length) 
            visControl.selectedNodesIdx.forEach(i => nodeContainer.getChildAt(i).tint = 0xFF0000)
        
        
    }
    
}

