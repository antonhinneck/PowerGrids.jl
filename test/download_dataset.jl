include("C:/Users/Anton Hinneck/juliaPackages/GitHub/PowerGrids.jl/src/PowerGrids.jl")
using .PowerGrids

using HTTP, JSON3, StructTypes
url = "https://localhost/get/dataset?id=54423&apiToken=YK437rJWjoFDVn2MnPgWxWgy"
response = HTTP.request("GET", url, ["Content-Type" => "application/json;charset=UTF-8"], require_ssl_verification = false)
#ds_dict = JSON.Parser.parse(String(response.body))

responseBody = String(response.body)

StructTypes.StructType(::Type{PowerGrids._dataset}) = StructTypes.Struct()


parsed = JSON3.read(responseBody, PowerGrids._dataset)

newDs = PowerGrids._dataset(parsed["network_id"],
                            parsed["name"],
                            parsed["baseMVA"],
                            parsed["buses"],
                            parsed["branches"],
                            parsed["generators"])

using Parsers, Mmap, UUIDs, Dates, StructTypes
a = 2
codeunits("ht")
a = Vector{Float64}()

a = Int64(0b00000001)
a << 4

parsed["buses"]
JSON3.read(parsed["buses"][1])



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
