function loadCase(; source = :csv)

    if source == :csv
        ds = _csv2dataset()
    elseif source == :psdb

    else
        error("Invalid source was selected.")
    end

    # Build Model Data
    #-----------------
    #buses = [ds.buses[i].bus_i for i in 1:length(ds.buses)]
    buses = [i for i in 1:length(ds.buses)]

    # Bus properties
    #---------------
    bus_id = Dict{Int64, Int64}()
    bus_Pd = Dict{Int64, Float64}()
    bus_Qd = Dict{Int64, Float64}()
    bus_Vmin = Dict{Int64, Float64}()
    bus_Vmax = Dict{Int64, Float64}()

    # Buses - Generators
    #-------------------
    generators_at_bus = Dict{Int64, Vector{Int64}}()

    # Buses - Lines
    #--------------
    lines_at_bus = Dict{Int64, Vector{Int64}}()
    lines_start_at_bus = Dict{Int64, Vector{Int64}}()
    lines_end_at_bus = Dict{Int64, Vector{Int64}}()

    # Bus splitting
    #--------------
    bus_decomposed = Vector{Bool}()
    root_buses = Vector{Int64}()
    bus_is_root = Vector{Bool}()
    root_bus = Dict{Int64, Int64}()
    bus_type = Dict{Int64, Int64}()
    bus_is_aux = Dict{Int64, Bool}()

    for i in 1:length(ds.buses)

        push!(bus_id, ds.buses[i].bus_i => i)
        #push!(bus_idRev, Int64(i) => ds.buses[i].bus_i)
        push!(bus_Pd, buses[i] => ds.buses[i].Pd)
        push!(bus_Qd, buses[i] => ds.buses[i].Qd)
        push!(bus_Vmin, buses[i] => ds.buses[i].Vmin)
        push!(bus_Vmax, buses[i] => ds.buses[i].Vmax)

        push!(generators_at_bus, buses[i] => Vector{Int64}())

        push!(lines_at_bus, buses[i] => Vector{Int64}())
        push!(lines_start_at_bus, buses[i] => Vector{Int64}())
        push!(lines_end_at_bus, buses[i] => Vector{Int64}())

        push!(bus_decomposed, false)
        push!(bus_is_root, true)
        push!(root_bus, i => 0)
        push!(bus_type, i => 1)
        push!(bus_is_aux, i => false)
    end

    generators = [i for i in 1:length(ds.generators)]

    # Generator properties
    #---------------------
    generator_Pmin = Dict{Int64, Float64}()
    generator_Pmax = Dict{Int64, Float64}()
    generator_bus_id = Dict{Int64, Int64}()
    generator_c0 = Dict{Int64, Float64}()
    generator_c1 = Dict{Int64, Float64}()
    generator_c2 = Dict{Int64, Float64}()
    generator_Qmin = Dict{Int64, Float64}()
    generator_Qmax = Dict{Int64, Float64}()

    for i in 1:length(generators)

        push!(generator_Pmin, generators[i] => ds.generators[i].Pmin)
        push!(generator_Pmax, generators[i] => ds.generators[i].Pmax)
        push!(generator_Qmin, generators[i] => ds.generators[i].Qmin)
        push!(generator_Qmax, generators[i] => ds.generators[i].Qmax)
        push!(generator_bus_id, generators[i] => ds.generators[i].bus_i)
        push!(generator_c0, generators[i] => ds.generators[i].c0)
        push!(generator_c1, generators[i] => ds.generators[i].c1)
        push!(generator_c2, generators[i] => ds.generators[i].c2)
        push!(generator_Qmin, generators[i] => ds.generators[i].Qmin)
        push!(generator_Qmax, generators[i] => ds.generators[i].Qmax)

        # Buses - Generators
        #-------------------
        push!(generators_at_bus[bus_id[ds.generators[i].bus_i]], generators[i])

    end

    lines = [i for i in 1:length(ds.branches)]
    line_id = Dict{Int64, Int64}()
    line_start = Dict{Int64, Int64}()
    line_end = Dict{Int64, Int64}()
    line_capacity = Dict{Int64, Float64}()
    line_r = Dict{Int64, Float64}()
    line_x = Dict{Int64, Float64}()
    line_b = Dict{Int64, Float64}()
    line_is_aux = Dict{Int64, Bool}()
    line_is_proxy = Dict{Int64, Bool}()

    for i in 1:length(lines)

        push!(line_id, i => i)
        push!(line_start, i => ds.branches[i].fbus)
        push!(line_end,  i => ds.branches[i].tbus)
        push!(line_r, i => ds.branches[i].r)
        push!(line_x, i => ds.branches[i].x)
        push!(line_b, i => ds.branches[i].b)
        push!(line_capacity, i => ds.branches[i].rateA)

        # Bus - Lines
        #------------
        push!(lines_at_bus[bus_id[ds.branches[i].fbus]], i)
        push!(lines_at_bus[bus_id[ds.branches[i].tbus]], i)
        push!(lines_start_at_bus[bus_id[ds.branches[i].fbus]], i)
        push!(lines_end_at_bus[bus_id[ds.branches[i].tbus]], i)

        # Bus splitting
        #--------------
        push!(line_is_aux, i => false)
        push!(line_is_proxy, i => false)
    end

    vertex_edge_matrix = zeros(length(ds.buses), length(ds.buses))
    adjacent_nodes = Vector{Vector{Int64}}()

    for i in 1:length(ds.buses)

        push!(adjacent_nodes, Vector{Int64}())

    end

    for i in 1:length(ds.buses)
        vertex_edge_matrix[convert(Int64, bus_id[ds.branches[i].fbus]), i] = 1
        vertex_edge_matrix[convert(Int64, bus_id[ds.branches[i].tbus]), i] = -1
        push!(adjacent_nodes[convert(Int64,  bus_id[ds.branches[i].fbus])],  bus_id[ds.branches[i].tbus])
    end

    dataset = PowerGrid(ds.baseMVA,
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
                        generator_Pmin,
                        generator_Pmax,
                        generator_Qmin,
                        generator_Qmax,
                        generator_c0,
                        generator_c1,
                        generator_c2,
                        generator_bus_id,
                        generators_at_bus,
                        lines,
                        line_is_aux,
                        line_is_proxy,
                        line_start,
                        line_end,
                        line_capacity,
                        line_r,
                        line_x,
                        line_b,
                        lines_at_bus,
                        lines_start_at_bus,
                        lines_end_at_bus,
                        bus_id,
                        bus_Pd,
                        bus_Qd,
                        bus_Vmin,
                        bus_Vmax,
                        nothing,
                        line_id)

    return dataset
end

#
# function datasets(verbose = false)
# # This function returns all data
# # set names in the directory "datasets".
#
#     # Read file names
#     cd((@__DIR__))
#     cd("datasets")
#     itr = walkdir(pwd(), topdown = false, follow_symlinks = false)
#     datasets = first(itr)[3]
#
#     # Remove non-data files
#     i = 1
#     print("-------------\n")
#     while (i <= length(datasets))
#         if !(datasets[i][(length(datasets[i]) - 4):length(datasets[i])] == ".xlsx")
#             deleteat!(datasets, i)
#             i = i - 1
#         end
#         i += 1
#     end
#
#     if verbose
#         for i in 1:length(datasets)
#             println("[INFO] ", datasets[i]," - ", i)
#         end
#     end
#     # Return data files
#     return datasets
# end
#
# function loadDataset(DataSource)
#
#     dataset_name = DataSource[1:(length(DataSource) - 5)]
#
#     cd(@__DIR__)
#     cd("datasets")
#
#     bus_df = to_df(XLSX.readtable(DataSource, "bus"))
#     gen_df = to_df(XLSX.readtable(DataSource, "gen"))
#     gencost_df = to_df(XLSX.readtable(DataSource, "gencost"))
#     branch_df = to_df(XLSX.readtable(DataSource, "branch"))
#     global_df = to_df(XLSX.readtable(DataSource, "global"))
#
#     geotags = false
#     if size(bus_df, 2) == 15
#         geotags = true
#     end
#
#     if typeof(global_df[1,1]) <: Number
#         base_mva = convert(Float64,global_df[1,1])
#     else
#         base_mva = nothing
#     end
#
#     if typeof(global_df[1,2]) <: Number
#         objective = global_df[1,2]
#     else
#         objective = nothing
#     end
#
#     if string(global_df[1,3]) != "NaN"
#         bibtex = global_df[1,3]
#     else
#         bibtex = nothing
#     end
#
#     # Build JsonModel
#     #----------------
#     is_extended_generator = false
#     if size(gen_df, 2) > 10
#         is_extended_generator = true
#     end
#
#     buses_input = Vector{bus}()
#     if is_extended_generator
#         generators_input = Vector{extended_generator}()
#     else
#         generators_input = Vector{generator}()
#     end
#     branches_input = Vector{branch}()
#
#     for i in 1:size(bus_df, 1)
#         if geotags
#             push!(buses_input, bus(bus_df[i, :]...))
#         else
#             push!(buses_input, bus(bus_df[i, :]..., 0.0, 0.0))
#         end
#     end
#
#     if size(gen_df, 1) == size(gencost_df, 1)
#         for i in 1:size(gen_df, 1)
#             if is_extended_generator
#                 if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
#                     push!(generators_input, extended_generator(gen_df[i, :]...,
#                                             gencost_df[i, :]...))
#                 else
#                     push!(generators_input, extended_generator(gen_df[i, 1],
#                                                                 gen_df[i, 2],
#                                                                 gen_df[i, 3],
#                                                                 Inf,
#                                                                 -Inf,
#                                                                 gen_df[i, 6],
#                                                                 gen_df[i, 7],
#                                                                 gen_df[i, 8],
#                                                                 gen_df[i, 9],
#                                                                 gen_df[i, 10],
#                                                                 gen_df[i, 11],
#                                                                 gen_df[i, 12],
#                                                                 gen_df[i, 13],
#                                                                 gen_df[i, 14],
#                                                                 gen_df[i, 15],
#                                                                 gen_df[i, 16],
#                                                                 gen_df[i, 17],
#                                                                 gen_df[i, 18],
#                                                                 gen_df[i, 19],
#                                                                 gen_df[i, 20],
#                                                                 gen_df[i, 21],
#                                                                 gencost_df[i, :]...))
#                 end
#             else
#                 if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
#                     push!(generators_input, generator(gen_df[i, :]...,
#                                             gencost_df[i, :]...))
#                 else
#                     push!(generators_input, generator(gen_df[i, 1],
#                                                         gen_df[i, 2],
#                                                         gen_df[i, 3],
#                                                         Inf,
#                                                         -Inf,
#                                                         gen_df[i, 6],
#                                                         gen_df[i, 7],
#                                                         gen_df[i, 8],
#                                                         gen_df[i, 9],
#                                                         gen_df[i, 10],
#                                                         gencost_df[i, :]...))
#                 end
#             end
#         end
#     else
#         print("Generator and Cost Data Mismatch.")
#     end
#
#     for i in 1:size(branch_df, 1)
#         push!(branches_input, branch(branch_df[i, :]...))
#     end
#
#     JsonModel = json_model(dataset_name, buses_input, branches_input, generators_input)
#
#     # Build Model Data
#     #-----------------
#     buses = [bus_df[:, 1]...]
#     root_buses = Vector{Int64}()
#     bus_decomposed = Vector{Bool}()
#     bus_is_root = Vector{Bool}()
#     bus_demand = Dict{Int64, Float64}()
#     generators_at_bus = Dict{Int64, Vector{Int64}}()
#     lines_at_bus = Dict{Int64, Vector{Int64}}()
#     lines_start_at_bus = Dict{Int64, Vector{Int64}}()
#     lines_end_at_bus = Dict{Int64, Vector{Int64}}()
#     get_bus_index = Dict{Int64, Int64}()
#     root_bus = Dict{Int64, Int64}()
#     bus_type = Dict{Int64, Int64}()
#     bus_is_aux = Dict{Int64, Bool}()
#
#     for i in 1:length(buses)
#
#         push!(generators_at_bus, buses[i] => Vector{Int64}())
#         push!(lines_at_bus, buses[i]=> Vector{Int64}())
#         push!(lines_start_at_bus, buses[i] => Vector{Int64}())
#         push!(lines_end_at_bus, buses[i] => Vector{Int64}())
#         push!(get_bus_index, buses[i] => i)
#         push!(bus_decomposed, false)
#         push!(bus_is_root, true)
#         push!(root_bus, i => 0)
#         push!(bus_type, i => 1)
#         push!(bus_is_aux, i => false)
#
#     end
#
#     for i in 1:length(buses)
#
#         push!(bus_demand, buses[i] => bus_df[i,3])
#
#     end
#
#     generators = [i for i in 1:length(gen_df[:, 1])]
#     generator_capacity = Dict{Int64, Float64}()
#     generator_costs = Dict{Int64, Float64}()
#
#     for i in 1:length(generators)
#
#         push!(generator_capacity, generators[i] => gen_df[i,9])
#         push!(generator_costs, generators[i] => gencost_df[i,6])
#         push!(generators_at_bus[gen_df[i,1]], generators[i])
#
#     end
#
#     lines = [i for i in 1:length(branch_df[:,1])]
#     line_start = Dict{Int64, Int64}()
#     line_end = Dict{Int64, Int64}()
#     line_capacity = Dict{Int64, Float64}()
#     line_reactance = Dict{Int64, Float64}()
#     line_is_aux = Dict{Int64, Bool}()
#     line_is_proxy = Dict{Int64, Bool}()
#
#     for i in 1:length(lines)
#
#         push!(line_start, i => branch_df[i,1])
#         push!(line_end,  i => branch_df[i,2])
#         push!(line_capacity, i => branch_df[i,6])
#         push!(line_reactance, i => branch_df[i,4])
#         push!(lines_at_bus[branch_df[i,1]], i)
#         push!(lines_at_bus[branch_df[i,2]], i)
#         push!(lines_start_at_bus[branch_df[i,1]], i)
#         push!(lines_end_at_bus[branch_df[i,2]], i)
#         push!(line_is_aux, i => false)
#         push!(line_is_proxy, i => false)
#
#     end
#
#     vertex_edge_matrix = zeros(length(bus_df[:,1]), length(branch_df[:,1]))
#     adjacent_nodes = Vector{Vector{Int64}}()
#
#     for i in 1:length(branch_df[:, 1])
#
#         push!(adjacent_nodes, Vector{Int64}())
#
#     end
#
#     for i in 1:length(branch_df[:, 1])
#         vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,1]]),i] = 1
#         vertex_edge_matrix[convert(Int64, get_bus_index[branch_df[i,2]]),i] = -1
#         push!(adjacent_nodes[convert(Int64, get_bus_index[branch_df[i,1]])], get_bus_index[branch_df[i,2]])
#     end
#
#     dataset = PowerGrid(bus_df,
#                         gen_df,
#                         gencost_df,
#                         branch_df,
#                         buses,
#                         root_buses,
#                         bus_decomposed,
#                         bus_is_root,
#                         root_bus,
#                         bus_type,
#                         bus_is_aux,
#                         vertex_edge_matrix,
#                         adjacent_nodes,
#                         generators,
#                         generator_capacity,
#                         generator_costs,
#                         generators_at_bus,
#                         lines,
#                         line_is_aux,
#                         line_is_proxy,
#                         line_start,
#                         line_end,
#                         line_capacity,
#                         line_reactance,
#                         lines_at_bus,
#                         lines_start_at_bus,
#                         lines_end_at_bus,
#                         bus_demand,
#                         JsonModel,
#                         bibtex,
#                         base_mva,
#                         nothing)
#
#     cd(@__DIR__)
#     return dataset
#
# end
