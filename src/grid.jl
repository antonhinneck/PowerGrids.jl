mutable struct PowerGrid

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

function readDataset(DataSource)

    dataset_name = DataSource[1:(length(DataSource) - 4)]

    cd(@__DIR__)
    cd("datasets")

    bus_df = to_df(XLSX.readtable(DataSource, "bus"))
    gen_df = to_df(XLSX.readtable(DataSource, "gen"))
    gencost_df = to_df(XLSX.readtable(DataSource, "gencost"))
    branch_df = to_df(XLSX.readtable(DataSource, "branch"))
    global_df = to_df(XLSX.readtable(DataSource, "global"))

    print(global_df)

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
    busses = [bus_df[:, 1]...]
    bus_demand = Dict{Int64, Float64}()
    generators_at_bus = Dict{Int64, Vector{Int64}}()
    lines_at_bus = Dict{Int64, Vector{Int64}}()
    lines_start_at_bus = Dict{Int64, Vector{Int64}}()
    lines_end_at_bus = Dict{Int64, Vector{Int64}}()
    get_bus_index = Dict{Int64, Int64}()

    for i in 1:length(busses)

        push!(generators_at_bus, busses[i] => Vector{Int64}())
        push!(lines_at_bus, busses[i]=> Vector{Int64}())
        push!(lines_start_at_bus, busses[i] => Vector{Int64}())
        push!(lines_end_at_bus, busses[i] => Vector{Int64}())
        push!(get_bus_index, busses[i] => i)

    end

    for i in 1:length(busses)

        push!(bus_demand, busses[i] => bus_df[i,3])

    end

    generators = [i for i in 1:length(gen_df[:, 1])]
    generator_capacity = Dict{Int64, Float64}()
    generator_costs = Dict{Int64, Float64}()

    for i in 1:length(generators)

        push!(generator_capacity, generators[i] => gen_df[i,9])
        push!(generator_costs, generators[i] => gen_df[i,4] + gen_df[i,6])
        push!(generators_at_bus[gen_df[i,1]], generators[i])

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
        vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,1]]),i] = 1
        vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,2]]),i] = -1
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

    cd(@__DIR__)
    return dataset

end
