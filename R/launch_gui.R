#' @export
panorama <- function(working.dir = NULL, ...) {
    if(!is.null(working.dir)) {
        .GlobalEnv$.ScaffoldWorkingDir <- working.dir
        on.exit(rm(.ScaffoldWorkingDir, envir = .GlobalEnv))
    }
    args <- list(...)

    if(is.null(args$port))
        args$port <- 8072
    
    args$appDir <- file.path(system.file(package = "panorama"), "shinyGUI")
    
    do.call(shiny::runApp, args)
}



