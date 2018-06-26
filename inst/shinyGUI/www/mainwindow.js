window.open("?plot=true", "_blank")


$(document).on('shiny:value', event => {
    console.log(event)
    if(event.target.id == "graphui_plot") {
        localStorage.setItem("current_plot", event.value.src)
        localStorage.removeItem('current_plot');
    }
})