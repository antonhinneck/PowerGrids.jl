mutable struct PowerGrid

    bus::DataFrame
    gen::DataFrame
    gencost::DataFrame
    branch::DataFrame
    buses
    root_buses
    bus_decomposed
    bus_is_root
    root_bus
    bus_type
    bus_is_aux
    vertex_edge_matrix
    adjacent_nodes
    generators
    generator_capacity
    generator_costs
    generators_at_bus
    lines
    line_is_aux
    line_is_proxy
    line_start
    line_end
    line_capacity
    line_reactance
    lines_at_bus
    lines_start_at_bus
    lines_end_at_bus
    bus_demand
    jsonModel
    bibtex
    base_mva
    sub_grids

end

mutable struct sub_grid

    root_bus::Int64
    buses::Vector{Int64}
    bus_bars::Vector{Int64}
    connectors::Vector{Int64}
    lines::Vector{Int64}
    externalLines::Vector{Int64}
    bus_bar_root_line::Dict{Int64, Int64}
    internalLineByBusBar::Dict{Int64, Dict{Int64, Int64}}

end

function readDataset(DataSource)

    dataset_name = DataSource[1:(length(DataSource) - 5)]

    cd(@__DIR__)
    cd("datasets")

    bus_df = to_df(XLSX.readtable(DataSource, "bus"))
    gen_df = to_df(XLSX.readtable(DataSource, "gen"))
    gencost_df = to_df(XLSX.readtable(DataSource, "gencost"))
    branch_df = to_df(XLSX.readtable(DataSource, "branch"))
    global_df = to_df(XLSX.readtable(DataSource, "global"))

    geotags = false
    if size(bus_df, 2) == 15
        geotags = true
    end

    if typeof(global_df[1,1]) <: Number
        base_mva = convert(Float64,global_df[1,1])
    else
        base_mva = nothing
    end

    if typeof(global_df[1,2]) <: Number
        objective = global_df[1,2]
    else
        objective = nothing
    end

    if string(global_df[1,3]) != "NaN"
        bibtex = global_df[1,3]
    else
        bibtex = nothing
    end

    # Build JsonModel
    #----------------
    is_extended_generator = false
    if size(gen_df, 2) > 10
        is_extended_generator = true
    end

    buses_input = Vector{bus}()
    if is_extended_generator
        generators_input = Vector{extended_generator}()
    else
        generators_input = Vector{generator}()
    end
    branches_input = Vector{branch}()

    for i in 1:size(bus_df, 1)
        if geotags
            push!(buses_input, bus(bus_df[i, :]...))
        else
            push!(buses_input, bus(bus_df[i, :]..., 0.0, 0.0))
        end
    end

    if size(gen_df, 1) == size(gencost_df, 1)
        for i in 1:size(gen_df, 1)
            if is_extended_generator
                if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
                    push!(generators_input, extended_generator(gen_df[i, :]...,
                                            gencost_df[i, :]...))
                else
                    push!(generators_input, extended_generator(gen_df[i, 1],
                                                                gen_df[i, 2],
                                                                gen_df[i, 3],
                                                                Inf,
                                                                -Inf,
                                                                gen_df[i, 6],
                                                                gen_df[i, 7],
                                                                gen_df[i, 8],
                                                                gen_df[i, 9],
                                                                gen_df[i, 10],
                                                                gen_df[i, 11],
                                                                gen_df[i, 12],
                                                                gen_df[i, 13],
                                                                gen_df[i, 14],
                                                                gen_df[i, 15],
                                                                gen_df[i, 16],
                                                                gen_df[i, 17],
                                                                gen_df[i, 18],
                                                                gen_df[i, 19],
                                                                gen_df[i, 20],
                                                                gen_df[i, 21],
                                                                gencost_df[i, :]...))
                end
            else
                if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
                    push!(generators_input, generator(gen_df[i, :]...,
                                            gencost_df[i, :]...))
                else
                    push!(generators_input, generator(gen_df[i, 1],
                                                        gen_df[i, 2],
                                                        gen_df[i, 3],
                                                        Inf,
                                                        -Inf,
                                                        gen_df[i, 6],
                                                        gen_df[i, 7],
                                                        gen_df[i, 8],
                                                        gen_df[i, 9],
                                                        gen_df[i, 10],
                                                        gencost_df[i, :]...))
                end
            end
        end
    else
        print("Generator and Cost Data Mismatch.")
    end

    for i in 1:size(branch_df, 1)
        push!(branches_input, branch(branch_df[i, :]...))
    end

    JsonModel = json_model(dataset_name,buses_input,branches_input,generators_input)

    # Build Model Data
    #-----------------
    buses = [bus_df[:, 1]...]
    root_buses = Vector{Int64}()
    bus_decomposed = Vector{Bool}()
    bus_is_root = Vector{Bool}()
    bus_demand = Dict{Int64, Float64}()
    generators_at_bus = Dict{Int64, Vector{Int64}}()
    lines_at_bus = Dict{Int64, Vector{Int64}}()
    lines_start_at_bus = Dict{Int64, Vector{Int64}}()
    lines_end_at_bus = Dict{Int64, Vector{Int64}}()
    get_bus_index = Dict{Int64, Int64}()
    root_bus = Dict{Int64, Int64}()
    bus_type = Dict{Int64, Int64}()
    bus_is_aux = Dict{Int64, Bool}()

    for i in 1:length(buses)

        push!(generators_at_bus, buses[i] => Vector{Int64}())
        push!(lines_at_bus, buses[i]=> Vector{Int64}())
        push!(lines_start_at_bus, buses[i] => Vector{Int64}())
        push!(lines_end_at_bus, buses[i] => Vector{Int64}())
        push!(get_bus_index, buses[i] => i)
        push!(bus_decomposed, false)
        push!(bus_is_root, true)
        push!(root_bus, i => 0)
        push!(bus_type, i => 1)
        push!(bus_is_aux, i => false)

    end

    for i in 1:length(buses)

        push!(bus_demand, buses[i] => bus_df[i,3])

    end

    generators = [i for i in 1:length(gen_df[:, 1])]
    generator_capacity = Dict{Int64, Float64}()
    generator_costs = Dict{Int64, Float64}()

    for i in 1:length(generators)

        push!(generator_capacity, generators[i] => gen_df[i,9])
        push!(generator_costs, generators[i] => gencost_df[i,6])
        push!(generators_at_bus[gen_df[i,1]], generators[i])

    end

    lines = [i for i in 1:length(branch_df[:,1])]
    line_start = Dict{Int64, Int64}()
    line_end = Dict{Int64, Int64}()
    line_capacity = Dict{Int64, Float64}()
    line_reactance = Dict{Int64, Float64}()
    line_is_aux = Dict{Int64, Bool}()
    line_is_proxy = Dict{Int64, Bool}()

    for i in 1:length(lines)

        push!(line_start, i => branch_df[i,1])
        push!(line_end,  i => branch_df[i,2])
        push!(line_capacity, i => branch_df[i,6])
        push!(line_reactance, i => branch_df[i,4])
        push!(lines_at_bus[branch_df[i,1]], i)
        push!(lines_at_bus[branch_df[i,2]], i)
        push!(lines_start_at_bus[branch_df[i,1]], i)
        push!(lines_end_at_bus[branch_df[i,2]], i)
        push!(line_is_aux, i => false)
        push!(line_is_proxy, i => false)

    end

    vertex_edge_matrix = zeros(length(bus_df[:,1]), length(branch_df[:,1]))
    adjacent_nodes = Vector{Vector{Int64}}()

    for i in 1:length(branch_df[:, 1])

        push!(adjacent_nodes, Vector{Int64}())

    end

    for i in 1:length(branch_df[:, 1])
        vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,1]]),i] = 1
        vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,2]]),i] = -1
        push!(adjacent_nodes[convert(Int64, get_bus_index[branch_df[i,1]])], get_bus_index[branch_df[i,2]])
    end

    dataset = PowerGrid(bus_df,
                        gen_df,
                        gencost_df,
                        branch_df,
                        buses,
                        root_buses,
                        bus_decomposed,
                        bus_is_root,
                        root_bus,
                        bus_type,
                        bus_is_aux,
                        vertex_edge_matrix,
                        adjacent_nodes,
                        generators,
                        generator_capacity,
                        generator_costs,
                        generators_at_bus,
                        lines,
                        line_is_aux,
                        line_is_proxy,
                        line_start,
                        line_end,
                        line_capacity,
                        line_reactance,
                        lines_at_bus,
                        lines_start_at_bus,
                        lines_end_at_bus,
                        bus_demand,
                        JsonModel,
                        bibtex,
                        base_mva,
                        nothing)

    cd(@__DIR__)
    return dataset

end
