include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")
include("C:/Users/Anton Hinneck/.julia/packages/PowerGrids/src/PowerGrids.jl")

grid = PowerGrids.readDataset(PowerGrids.datasets()[6])

graph = PowerGrids.toGraph(grid)
