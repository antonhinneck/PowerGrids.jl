include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")
include("C:/Users/Anton Hinneck/.julia/packages/PowerGrids/src/PowerGrids.jl")

grid = PowerGrids.readDataset(PowerGrids.datasets()[5])
graph = PowerGrids.toGraph(grid)

GraphVisualization.plot(graph, [300,300])

using LightGraphs
graph = SimpleGraph()
add_vertex!(graph)
add_vertex!(graph)
add_vertex!(graph)
add_edge!(graph, 1,2)
add_edge!(graph, 1,3)

degree(graph)
