## PowerGrids provides unified access
## to data sets like pglib in Julia.
#####--------------------------------

## AUTHOR
## Anton Hinneck
## anton.hinneck@skoltech.ru
#####-----------------------

module PowerGrids

#using Pkg
using DataFrames, CSV, JSON, HTTP
using LightGraphs: ne, nv, AbstractSimpleGraph, SimpleGraph, add_vertex!, add_edge!
#include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")

export set_csv_path, csv_cases, select_csv_case, loadCase,
       __splitBus!, splitBus!, addBus!, addLine!, newBus!, update_line,
       split_build_x0, dfs_components, reassign_generator!, reassign_demand!, reduce_grid,
       param_mat_A, param_mat_B, param_vec_d, param_vec_x, param_vec_fmax, param_vec_Pmax,
       param_vec_c0, param_vec_c1, param_vec_c2, param_mat_c2_rt, param_mat_P, toGraph, sol_allActive

# cases, readDataset, toGraph, AnnotatedSimpleGraph, paton, adjacency_list,
#         SpanningTreeToIndicators, rndPermute, rmLines!, solutionToLineIndicators!, upload_dataset,
#         lmps_model, addBus!, addLine!, splitBus!, _splitBus!, dfs, bfs, bfs_omit,
#         newBus!, update_line, split_build_x0

include("./structs_main.jl")
include("./structs_aux.jl")

include("./IO/io_json.jl")
include("./IO/in_csv.jl")

include("./load.jl")

include("./utils_change_network.jl")
include("./utils_bus_splitting.jl")

include("./utils_datastructures.jl")

#include("./graph_functions.jl")
include("./IO/io_graph.jl")

## End Module
##-----------
end
