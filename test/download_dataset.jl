include("C:/Users/Anton Hinneck/juliaPackages/GitHub/PowerGrids.jl/src/PowerGrids.jl")
using .PowerGrids

using HTTP, JSON, JSON2
url = "https://localhost/get/dataset?name=pglib_opf_case118_ieee"
response = HTTP.request("GET", url, ["Content-Type" => "application/json;charset=UTF-8"], require_ssl_verification = false)
#ds_dict = JSON.Parser.parse(String(response.body))

JSON2.@format String(response.body)
        network_id => (exclude = true,)
end
String(response.body)
ds = JSON2.read(String(response.body), PowerGrids._dataset)


a = @pretty String(response.body)
print(a)
baseMVA = ds["baseMVA"]
name = ds["name"]

buses = Vector{PowerGrids.bus}()
branches = Vector{PowerGrids.branch}()
generators = Vector{PowerGrids.extended_generator}()

for i in 1:length(ds["branches"])

        push!(branches, PowerGrids.branch(values(ds["branches"][i])...))

end

ds = PowerGrids._dataset(ds["name"],
              ds["baseMVA"],
              ds["buses"],
              ds["branches"],
              ds["generators"])
