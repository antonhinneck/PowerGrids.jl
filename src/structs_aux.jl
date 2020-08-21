# Results
#--------

struct lmp
    bus_i::Int64
    lmp::Float64
end

mutable struct lmps_model
    datasetName::String
    lmps::Vector{lmp}
end

struct NodalClusterAssignment
    bus_i::Int64
    clusterNumber::Int64
end

mutable struct NodalClustering
    datasetName::String
    name::String
    type::String
    clusterAmount::Int64
    nodalClusterAssignments::Vector{NodalClusterAssignment}
end

# IO
#---

mutable struct _dataset
    name::String
    baseMVA::Int64
    buses::Vector{B where B <: Bus}
    branches::Vector{B where B <: Branch}
    generators::Vector{G where G <: Generator}
end
