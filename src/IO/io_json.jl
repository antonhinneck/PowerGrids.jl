# Functions to convert the data sets into a JSON string.
#-------------------------------------------------------

mutable struct json_model

    name::String
    buses::Vector{B where B <: Bus}
    branches::Vector{B where B <: Branch}
    generators::Vector{G where G <: Generator}

end

struct lmp

    bus_i::Int64
    lmp::Float64

end

mutable struct lmps_model

    datasetName::String
    lmps::Vector{lmp}

end

function upload_dataset(data, url::String)

    postBody = JSON.json(data.jsonModel)
    HTTP.request("POST", url, ["Content-Type" => "application/json;charset=UTF-8"], postBody, require_ssl_verification = false)

end

function upload_lmps(name::String, _buses::Vector{Int64}, _lmps::Vector{Float64}, url::String)

    @assert length(_buses) == length(_lmps)
    lmps = Vector{lmp}()

    for i in 1:length(_buses)
        push!(lmps, lmp(_buses[i], _lmps[i]))
    end

    postBody = JSON.json(lmps_model(name, lmps))
    HTTP.request("POST", url, ["Content-Type" => "application/json;charset=UTF-8"], postBody, require_ssl_verification = false)

end

#postBody = JSON.json(data.jsonModel)
#HTTP.request("POST", "http://localhost:8080/data/upload", ["Content-Type" => "application/json;charset=UTF-8"], postBody)

#JSON.print(stdout, data.jsonModel, 2)

#include("Model_switching.jl")
