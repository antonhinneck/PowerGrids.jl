## PowerGrids provides unified access
## to data sets like pglib in Julia.
#####--------------------------------
## For offline use, the package
## contains a collection of pglib
## data sets in xlsx format.
#####--------------------------------
## For online use, an interface
## to opengrid.io is available.
#####--------------------------------

## AUTHOR
## Anton Hinneck
## anton.hinneck@skoltech.ru
#####-----------------------

module PowerGrids

function string_to_symbol_array(string_array)

    out = Array{Symbol, 1}()

    for i in 1:length(string_array)

        push!(out, Symbol(string_array[i]))

    end

    return  out
end

function to_df(raw_data)

    if typeof(raw_data) <: Tuple
        df = DataFrame(raw_data[1], raw_data[2])
    end
    return df

end

struct bus

    bus_i::S where S<:Integer
    type::S where S<:Real
    Pd::S where S<:Real
    Qd::S where S<:Real
    Gs::S where S<:Real
    Bs::S where S<:Number
    area::S where S<:Number
    Vm::S where S<:Number
    Va::S where S<:Number
    baseKV::S where S<:Number
    zone::S where S<:Number
    Vmax::S where S<:Number
    Vmin::S where S<:Number

end

struct branch


    fbus::S where S<:Number
    tbus::S where S<:Number
    r::S where S<:Number
    x::S where S<:Number
    b::S where S<:Number
    rateA::S where S<:Number
    rateB::S where S<:Number
    rateC::S where S<:Number
    ratio::S where S<:Number
    angle::S where S<:Number
    status::S where S<:Number
    angmin::S where S<:Number
    angmax::S where S<:Number

end

struct generator

    ## Generator DATA
    ##---------------
    bus_i::S where S<:Number
    Pg::S where S<:Number
    Qg::S where S<:Number
    Qmax::S where S<:Number
    Qmin::S where S<:Number
    Vg::S where S<:Number
    mBase::S where S<:Number
    status::S where S<:Number
    Pmax::S where S<:Number
    Pmin::S where S<:Number
    ## Cost DATA
    ##---------------
    two::S where S<:Number
    startup::S where S<:Number
    shutdown::S where S<:Number
    n::S where S<:Number
    cMinus1::S where S<:Number
    test::S where S<:Number
    c0::S where S<:Number

end

struct extended_generator

    ## Generator DATA
    ##---------------
    bus_i::S where S<:Number
    Pg::S where S<:Number
    Qg::S where S<:Number
    Qmax::S where S<:Number
    Qmin::S where S<:Number
    Vg::S where S<:Number
    mBase::S where S<:Number
    status::S where S<:Number
    Pmax::S where S<:Number
    Pmin::S where S<:Number
    Pc1::S where S<:Number
    Pc2::S where S<:Number
    Qc1min::S where S<:Number
    Qc1max::S where S<:Number
    Qc2min::S where S<:Number
    Qc2max::S where S<:Number
    ramp_agc::S where S<:Number
    ramp_10::S where S<:Number
    ramp_30::S where S<:Number
    ramp_q::S where S<:Number
    apf::S where S<:Number

    ## Cost DATA
    ##---------------
    two::S where S<:Number
    startup::S where S<:Number
    shutdown::S where S<:Number
    n::S where S<:Number
    cMinus1::S where S<:Number
    test::S where S<:Number
    c0::S where S<:Number

end

struct json_model

    name::String
    busses::Vector{bus}
    branches::Vector{branch}
    generators

end

struct PowerGrid

    bus::DataFrame
    gen::DataFrame
    gencost::DataFrame
    branch::DataFrame
    busses
    vertex_edge_matrix
    adjacent_nodes
    generators
    generator_capacity
    generator_costs
    generators_at_bus
    lines
    line_start
    line_end
    line_capacity
    line_reactance
    lines_at_bus
    lines_start_at_bus
    lines_end_at_bus
    bus_demand
    jsonModel

end

function import_PowerGrid(DataSource, dataset_name)

    bus_df = to_df(XLSX.readtable(DataSource, "bus"))
    gen_df = to_df(XLSX.readtable(DataSource, "gen"))
    gencost_df = to_df(XLSX.readtable(DataSource, "gencost"))
    branch_df = to_df(XLSX.readtable(DataSource, "branch"))

    # Build JsonModel
    #----------------
    is_extended_generator = false
    if size(gen_df, 2) > 10
        is_extended_generator = true
    end

    busses_input = Vector{bus}()
    if is_extended_generator
        generators_input = Vector{extended_generator}()
    else
        generators_input = Vector{generator}()
    end
    branches_input = Vector{branch}()

    for i in 1:size(bus_df, 1)
        push!(busses_input, bus(bus_df[i, :]...))
    end

    if size(gen_df, 1) == size(gencost_df, 1)
        for i in 1:size(gen_df, 1)
            if is_extended_generator
                push!(generators_input, extended_generator(gen_df[i, :]...,
                                        gencost_df[i, :]...))
            else
                push!(generators_input, generator(gen_df[i, :]...,
                                        gencost_df[i, :]...))
            end
        end
    else
        print("Generator and Cost Data Mismatch.")
    end

    for i in 1:size(branch_df, 1)
        push!(branches_input, branch(branch_df[i, :]...))
    end

    JsonModel = json_model(dataset_name,busses_input,branches_input,generators_input)

    # Build Model Data
    #-----------------
    busses = [i for i in 1:length(bus_df[:, 1])]
    bus_demand = Dict{Int64, Float64}()
    generators_at_bus = Dict{Int64, Vector{Int64}}()
    lines_at_bus = Dict{Int64, Vector{Int64}}()
    lines_start_at_bus = Dict{Int64, Vector{Int64}}()
    lines_end_at_bus = Dict{Int64, Vector{Int64}}()

    for i in 1:length(busses)

        push!(generators_at_bus, i => Vector{Int64}())
        push!(lines_at_bus, i => Vector{Int64}())
        push!(lines_start_at_bus, i => Vector{Int64}())
        push!(lines_end_at_bus, i => Vector{Int64}())

    end

    for i in 1:length(busses)

        push!(bus_demand, i => bus_df[i,3])

    end

    generators = [i for i in 1:length(gen_df[:, 1])]
    generator_capacity = Dict{Int64, Float64}()
    generator_costs = Dict{Int64, Float64}()

    for i in 1:length(generators)

        push!(generator_capacity, generators[i] => gen_df[i,9])
        push!(generator_costs, generators[i] => gen_df[i,4] + gen_df[i,6])
        push!(generators_at_bus[gen_df[i,1]], i)

    end

    lines = [i for i in 1:length(branch_df[:,1])]
    line_start = Dict{Int64, Int64}()
    line_end = Dict{Int64, Int64}()
    line_capacity = Dict{Int64, Float64}()
    line_reactance = Dict{Int64, Float64}()

    for i in 1:length(lines)

        push!(line_start, i => branch_df[i,1])
        push!(line_end,  i => branch_df[i,2])
        push!(line_capacity, i => branch_df[i,6])
        push!(line_reactance, i => branch_df[i,4])
        push!(lines_at_bus[branch_df[i,1]], i)
        push!(lines_at_bus[branch_df[i,2]], i)
        push!(lines_start_at_bus[branch_df[i,1]], i)
        push!(lines_end_at_bus[branch_df[i,2]], i)

    end

    vertex_edge_matrix = zeros(length(bus_df[:,1]), length(branch_df[:,1]))
    adjacent_nodes = Vector{Vector{Int64}}()

    for i in 1:length(branch_df[:, 1])

        push!(adjacent_nodes, Vector{Int64}())

    end

    for i in 1:length(branch_df[:, 1])
        vertex_edge_matrix[convert(Int64, branch_df[i,1]),i] = 1
        vertex_edge_matrix[convert(Int64, branch_df[i,2]),i] = -1
        push!(adjacent_nodes[convert(Int64, branch_df[i,1])], branch_df[i,2])
    end

    dataset = PowerGrid(bus_df,
                        gen_df,
                        gencost_df,
                        branch_df,
                        busses,
                        vertex_edge_matrix,
                        adjacent_nodes,
                        generators,
                        generator_capacity,
                        generator_costs,
                        generators_at_bus,
                        lines,
                        line_start,
                        line_end,
                        line_capacity,
                        line_reactance,
                        lines_at_bus,
                        lines_start_at_bus,
                        lines_end_at_bus,
                        bus_demand,
                        JsonModel)

    return dataset

end

## End Module
##-----------
end
