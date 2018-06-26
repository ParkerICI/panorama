function plot_receive(ev) {
    if (ev.key != 'current_plot') return // ignore other keys
    let msgData = ev.oldValue

    if(msgData) {
        let cur_img = document.getElementById("plotWindow_plot")

        if(cur_img)
            cur_img.parentNode.removeChild(cur_img)
        let img = document.createElement('img')
        img.id = "plotWindow_plot"
        img.setAttribute("src", msgData)
        
        document.getElementById("plotWindow").appendChild(img);
    }
}



//Watch for modifications to the local storage and load the plot from it
window.addEventListener("storage", function(ev) {plot_receive(ev);}); 