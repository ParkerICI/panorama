function plot_receive(ev) {
    if (ev.key != 'current_plot') return // ignore other keys
    let msgData = ev.oldValue
    
    if(msgData) {
        let imgDiv = document.getElementById("plotOutput")
        
        while(imgDiv.firstChild)
            imgDiv.removeChild(imgDiv.firstChild)
 
        let img = document.createElement('img')
        img.id = "plotWindow_plot"
        img.setAttribute("src", msgData)
        
        imgDiv.appendChild(img)
    }
}



//Watch for modifications to the local storage and load the plot from it
window.addEventListener("storage", function(ev) {plot_receive(ev);}); 