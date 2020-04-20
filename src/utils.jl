function string_to_symbol_array(string_array)
# This function converts an Array{String, 1}
# into an Array{Symbol, 1}.

    out = Array{Symbol, 1}()

    for i in 1:length(string_array)

        push!(out, Symbol(string_array[i]))

    end

    return  out
end

function to_df(raw_data)
# This function takes 2 Arrays
# and constructs a DataFrame.


    if typeof(raw_data) <: Tuple
        df = DataFrame(raw_data[1], raw_data[2])
    end
    return df

end

function datasets(verbose = false)
# This function returns all data
# file names in the directory "datasets".

    # Read file names
    cd((@__DIR__))
    cd("datasets")
    itr = walkdir(pwd(), topdown = false, follow_symlinks = false)
    datasets = first(itr)[3]

    # Remove non-data files
    i = 1
    print("-------------\n")
    while (i <= length(datasets))
        if !(datasets[i][(length(datasets[i]) - 4):length(datasets[i])] == ".xlsx")
            deleteat!(datasets, i)
            i = i - 1
        end
        i += 1
    end

    if verbose
        for i in 1:length(datasets)
            println("[INFO] ", datasets[i]," - ", i)
        end
    end
    # Return data files
    return datasets
end

# This function returns
# a permuted array.
#----------------------

function rndPermute(a::Array{T, 1} where T <: Any)

    idxs = [i for i in 1:length(a)]
    permutation = Vector{Int64}()

    while length(idxs) > 0
        idx = rand(1:length(idxs))
        push!(permutation, a[idxs[idx]])
        deleteat!(idxs, idx)
    end

    return permutation
end

function addBus!(pg::PowerGrid; demand = 0.0)
    nb = length(pg.buses)
    id = pg.buses[nb] + 1
    push!(pg.buses, id)
    push!(pg.bus_decomposed, true)
    push!(pg.bus_demand, id => demand)
    push!(pg.bus_is_root, false)
    push!(pg.lines_at_bus, id => Vector{Int64}())
    push!(pg.lines_start_at_bus, id => Vector{Int64}())
    push!(pg.lines_end_at_bus, id => Vector{Int64}())
    push!(pg.adjacent_nodes, Vector{Int64}())
    push!(pg.generators_at_bus, id => Vector{Int64}())
    return id
end

function addLine!(pg::PowerGrid, tbus, fbus; is_aux = false, reactance = 0.0001, capacity = 5000.0)
    nl = length(pg.lines)
    id = nl + 1
    push!(pg.lines, id)
    push!(pg.lines_at_bus[tbus], id)
    push!(pg.lines_at_bus[fbus], id)
    push!(pg.line_is_aux, id => is_aux)
    push!(pg.line_start, id => tbus)
    push!(pg.lines_start_at_bus[tbus], id)
    push!(pg.line_end, id => fbus)
    push!(pg.lines_end_at_bus[fbus], id)
    push!(pg.line_capacity, id => capacity)
    push!(pg.line_reactance, id => reactance)
end

function splitBus!(pg::PowerGrid, id::Int64)
    if !pg.bus_decomposed[id]
        new_buses = Vector{Int64}()
        if length(pg.lines_at_bus[id]) > 1
            for i in 1:length(pg.lines_at_bus[id])
                nb = addBus!(pg)
                push!(new_buses, nb)
                addLine!(pg, id, nb, is_aux = true)
                # Reconfigure Lines
                cl = pg.lines_at_bus[id][1]
                deleteat!(pg.lines_at_bus[id], 1)
                if cl in pg.lines_start_at_bus[id]
                    idx = indexin(cl, pg.lines_start_at_bus[id])[]
                    deleteat!(pg.lines_start_at_bus[id], idx)
                    push!(pg.lines_start_at_bus[nb], cl)
                    pg.line_start[cl] = nb
                else
                    idx = indexin(cl, pg.lines_end_at_bus[id])[]
                    deleteat!(pg.lines_end_at_bus[id], idx)
                    push!(pg.lines_end_at_bus[nb], cl)
                    pg.line_end[cl] = nb
                end
                push!(pg.lines_at_bus[nb], cl)
            end
            # Construct Auxilliary Lines
            for i in 1:length(new_buses)
                for j in (i + 1):length(new_buses)
                    addLine!(pg, new_buses[i], new_buses[j], is_aux = true)
                end
            end
        end
        pg.bus_decomposed[id] = true
        return true, new_buses
    else
        println("A bus can only be split once.")
        println("Consider reloading the dataset, to perform this operation.")
        return false
    end
end
