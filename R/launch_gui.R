#' @export
scaffold.run <- function(launch.browser = TRUE,
                         working.dir = NULL, ...)
{
    if(!is.null(working.dir))
    {
        .GlobalEnv$.ScaffoldWorkingDir <- working.dir
        on.exit(rm(.ScaffoldWorkingDir, envir = .GlobalEnv))
    }
    
    shiny::runApp(appDir = file.path(system.file(package = "scaffold2"), "shinyGUI"), launch.browser = launch.browser, ...)
}



