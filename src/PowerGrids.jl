## PowerGrids provides unified access
## to data sets like pglib in Julia.
#####--------------------------------
## For offline use, the package
## contains a collection of pglib
## data sets in xlsx format.
#####--------------------------------
## For online use, an interface
## to opengrid.io is available.
#####--------------------------------

## AUTHOR
## Anton Hinneck
## anton.hinneck@skoltech.ru
#####-----------------------

module PowerGrids

using Pkg
using DataFrames, XLSX, JSON, LightGraphs
include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")

export datasets, readDataset, toGraph, AnnotatedSimpleGraph, paton, adjacency_list, line_vector

include("./graph_functions.jl")
include("./utils.jl")
include("./grid_components.jl")
include("./grid.jl")
include("./IO/io_json.jl")
include("./IO/io_graph.jl")

## End Module
##-----------
end
