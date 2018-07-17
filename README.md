# Installation

1. Install the `devtools` package if you have not already
```R
install.packages("devtools")
```

2. install `panorama` with the following command
```R
devtools::install_github("ParkerICI/panorama")
```

This will install the `panorama` R package together with all the required dependencies. If evertyhing was successful you should be able to start the GUI with the following commands

```R
library(panorama)
panorama()
```
to stop the GUI simply hit the `ESC` key in your R session.

# Usage

When you launch the GUI you will be prompted to select a file. You can select *any* file in what you want to be your working directory and this will set the working directory for the remainder of the session.

The working directory must contain all the `graphml` files you want to visualize, plus a sub-folder named `clusters_data` containing the single-cell data for each cluster. If the graphml files represent Scaffold maps, a sub-folder called `landmarks_data` must also be present. 

If the `graphml` files were generated using the [scgraphs](https://github.com/ParkerICI/scgraphs) package these directories were generated for you as long as the `process.clusters.data` option was set to `TRUE` in `scgraphs::run_scaffold_analysis` or `scgraphs::get_unsupervised_graph_from_files` (please refer to the documentation of the `scgraphs` packages for details)

Once the working directory has been selected two browser windows will be opened: a main window containing the graph visualization, and a separate plotting window. Please note the following, depending on your browser settings:
- If your browser is configured to block pop-ups you need to allow pop-ups coming from the address `127.0.0.1:8072` (8072 is the default `panorama` port, you will have to enable pop-ups coming from a different port if you change this default)
- If your browser is configured to open new windows in a new tab, the last tab shown in the browser will be the plotting window, which is initially empty. The main `panorama` interface will be in a different tab

## Description of the GUI functionality

- **Choose a graph**: select the `graphml` file you want to visualize from a list of files contained in your working directory

You can interact with the graph using the mouse as follows:
- Scrolling: zoom in/out. 
- Left click + drag: panning
- Click on a node + Shift key: add the node to the current selection, or create a new selection if none existed (selected nodes are displayed in red)
- Left click + drag + Alt key: select all nodes inside a rectangle. To clear the current selection use this key combination to create a selection on an empty area of the graph

The appearence of the graph can be modified with the following controls:

- **Active sample**: whether to display data for All the samples (i.e. the pooled data) or a specific sample (this control is only available if the graph represents multiple samples, i.e. it was generated from pooled clustering). Selecting a different sample changes the size and color of the nodes, to reflect statistics calculated using only data from the current active sample.
- **Display edges**: select which edges to display:
   - All: displays all the edges
   - Highest scoring: for each node, display the highest scoring connection to a landmark (i.e. this is the most similar landmark)
   - Inter cluster: only display edges between clusters
   - To landmark: only display edges between clusters and landmarks
- **Nodes color**: use this dropdown to color the nodes according to the expression of a specific marker, or with "Default" colors (clusters in Blue, landmarks in red)
- **Stats type**: only available if the graph represents mulitple samples:
  - Absolute: the node colors represent the absolute value of the selected marker in the active sample
  - Ratio: the node colors represent the ratio between the value of the selected marker in the active sample and the value of the selected marker in the sample selected from the **Stats relative to** dropdown. The ratio is calculated on the asinh transformed values
  - Difference: the node colors represent the difference between the value of the selected marker in the active sample and the value of the selected marker in the sample selected from the **Stats relative to** dropdown. The difference is calculated on the asinh transformed values
- **Stats relative to**: only available if the graph represents multiple samples and **Stats type** is different from `Absolute`. The sample with respect to which stats are calculated (see **Stats type**)
- **Number of colors**: number of colors to use in the color scale
- **Under**: the color to use for values that are below the minimum of the scale
- **Over**: the color to use for value that are above the maximum of the scale
- **Min**: the color corresponding to the minimum of the scale
- **Mid**: the color corresponding to the midpoint of the scale (only available if the number of colors is 3)
- **Max**: the color corresponding to the maximum of the scale
- **Color scale midpoint**: the value corresponding to the midpoint of the color scale (only available if the number of colors is 3)
- **Color scale limits**: the numerical values that correspond to the domain of the color scale
- **Color scale min**: the minimum value available in the **Color scale limits** slider
- **Color scale max**: the maximum value available in the **Color scale limits** slider
- **Nodes size**: select whether you want the size of the nodes to be constant (Default) or Proportional to the number of cells in each cluster. 
- **Minimum / Maximum / Landmark node size**: the minimum and maximum size for the cluster and the size of the landmark (red) nodes
- **Reset graph position**: this button will reset the graph to its initial position, which is intended to display most of the nodes in a single image
- **Toggle landmark labels**: toggle the display of the landmark labels on/off
- **Toggle cluster labels**: toggle the display of the cluster labels on/off
- **Export selected clusters**: click this button to export the events in the selected clusters in a separate FCS file. For this to work, the original RData files corresponding to the clustered files in use must be located in the working directory. A new FCS file will be created in the working directory, with a name starting with *scaffold_export*, and ending with a random string of alpha-numeric characters, to prevent naming conflicts.

One of the most useful ways to inspect a cluster is to plot the expression values for the cells that comprise the cluster. The controls below allow you to control the appeareance of the plot. Only data for the clusters that have been selected will be plotted. If the graph represents a Scaffold map, the plot will also include the data for the landmarks that are connected to the selected clusters

- **Plot type**: the type of plot to display. Either a boxplot, a density plot, or a scatteplot (biaxial).
- **Facet by**: only availabe if the graph represents data from multiple samples. Whether the plot should be faceted by Sample or Variable, i.e. wether each Sample or each Variable should be its separate plot in the panel
- **Pool clusters data**: whether to pool all the data from the selected clusters for plotting. If the option is not selected, each cluster will be plotted individually as a separate boxplot, or density plot. Selecting this option will pool all the clusters data together for plotting. Note that if this option is selected, and the graph represents data from multiple samples, the data for the different samples will be pooled as well
- **Pool samples data**: only available if the graph represents data from multiple samples and **Pool clusters data** is not selected. Whether to pool the data from multiple samples for plotting.
- **Markers to plot**: Select which markers you want to display in the plot.
- **Samples to plot**: only available if the graph represents data from multiple samples. If this is left empty, the pooled data is plotted, otherwise only the data from the specified samples
- **Plot clusters**: plot the selected clusters. A spinner animation will appear in this button while the plot is loading. The plots appear in the separate plotting window




