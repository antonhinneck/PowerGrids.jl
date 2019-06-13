include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")
include("C:/Users/Anton Hinneck/.julia/packages/PowerGrids/src/PowerGrids.jl")

#grid = PowerGrids.readDataset(PowerGrids.datasets()[5]) # 14 busses
#grid = PowerGrids.readDataset(PowerGrids.datasets()[36]) # 588 busses
grid = PowerGrids.readDataset(PowerGrids.datasets()[2]) # 118 busses
PowerGrids.datasets()
graph = PowerGrids.toGraph(grid)

GraphVisualization.plot(graph, [400,400])
