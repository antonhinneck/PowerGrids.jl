# Functions to convert the data sets into a JSON string.
#-------------------------------------------------------

mutable struct json_model

    name::String
    busses::Vector{B where B <: Bus}
    branches::Vector{B where B <: Branch}
    generators::Vector{G where G <: Generator}

end
