# Functions to convert the data sets into a JSON string.
#-------------------------------------------------------

function upload_dataset(pg::PowerGrid, url::String)

    postBody = JSON.json(_jsonModel(CASE_NAME,
                                    pg.buses_input,
                                    pg.generators_input,
                                    pg.branches_input))
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

function upload_clustering(data, _buses, _assignments, _url::String; name = "", type = "")
#_name - denotes the cluster's name
#_type - denotes the clustering method (e.g. "spatial")

    _clusterAmount = length(unique(_assignments))

    ncas = Vector{NodalClusterAssignment}()
    for i in 1:length(_buses)
        nca = NodalClusterAssignment(_buses[i], _assignments[i])
        push!(ncas, nca)
    end

    nc = NodalClustering(data.jsonModel.name, name, type, _clusterAmount, ncas)
    println(length(_assignments))
    println(length(_buses))
    println(length(ncas))

    postBody = JSON.json(nc)
    HTTP.request("POST", _url, ["Content-Type" => "application/json;charset=UTF-8"], postBody, require_ssl_verification = false)
end

#postBody = JSON.json(data.jsonModel)
#HTTP.request("POST", "http://localhost:8080/data/upload", ["Content-Type" => "application/json;charset=UTF-8"], postBody)

#JSON.print(stdout, data.jsonModel, 2)

#include("Model_switching.jl")
