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
using DataFrames, XLSX, JSON, HTTP
using LightGraphs: ne, nv, AbstractSimpleGraph, SimpleGraph, add_vertex!, add_edge!
#include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")

export PowerGrid, datasets, readDataset, toGraph, AnnotatedSimpleGraph, paton, adjacency_list,
        SpanningTreeToIndicators, rndPermute, rmLines!, solutionToLineIndicators!, upload_dataset,
        lmps_model, addBus!, addLine!, splitBus!, _splitBus!, dfs, bfs, bfs_omit,
        newBus!, update_line, split_build_x0

include("./grid_components.jl")
include("./grid.jl")
include("./utils.jl")
include("./graph_functions.jl")
include("./IO/io_json.jl")
include("./IO/io_graph.jl")

## End Module
##-----------
end
