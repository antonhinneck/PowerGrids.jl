include("C:/Users/Anton Hinneck/juliaPackages/GitHub/PowerGrids.jl/src/PowerGrids.jl")
using .PowerGrids

set_csv_path("C:/Users/Anton Hinneck/Documents/Git/pglib2csv/pglib/2020-08-21.19-54-30-275/csv")
csv_cases(verbose = true)
select_csv_case(3)
loadCase()
