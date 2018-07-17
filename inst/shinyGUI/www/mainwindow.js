window.open("?plot=true", "_blank")


$(document).on('shiny:value', event => {

    if(event.target.id == "graphui_plot") {
        event.preventDefault()

        document.getElementById("graphui_plot_clusters_spinner").style.visibility = "hidden"
        document.getElementById("graphui_plot_clusters_text").style.visibility = "visible"

        localStorage.setItem("current_plot", event.value.src)
        localStorage.removeItem('current_plot');
    }
})