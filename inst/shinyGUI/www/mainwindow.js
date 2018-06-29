window.open("?plot=true", "_blank")


$(document).on('shiny:value', event => {

    if(event.target.id == "graphui_plot") {
        event.preventDefault()
        localStorage.setItem("current_plot", event.value.src)
        localStorage.removeItem('current_plot');
    }
})