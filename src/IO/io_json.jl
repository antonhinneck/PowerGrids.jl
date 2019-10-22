# Functions to convert the data sets into a JSON string.
#-------------------------------------------------------

mutable struct json_model

    name::String
    busses::Vector{B where B <: Bus}
    branches::Vector{B where B <: Branch}
    generators::Vector{G where G <: Generator}

end

function upload_dataset(data, url::String)

    postBody = JSON.json(data.jsonModel)
    HTTP.request("POST", url, ["Content-Type" => "application/json;charset=UTF-8"], postBody)

end

#postBody = JSON.json(data.jsonModel)
#HTTP.request("POST", "http://localhost:8080/data/upload", ["Content-Type" => "application/json;charset=UTF-8"], postBody)

#JSON.print(stdout, data.jsonModel, 2)

#include("Model_switching.jl")
