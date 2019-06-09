include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")
include("C:/Users/Anton Hinneck/.julia/packages/PowerGrids/src/PowerGrids.jl")

grid = PowerGrids.readDataset(PowerGrids.datasets()[5])

graph = PowerGrids.toGraph(grid)
