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

function addLine!(pg::PowerGrid, tbus, fbus; is_aux = false, is_proxy = false, reactance = 10e-4, capacity = 5000.0)
    nl = length(pg.lines)
    id = nl + 1
    push!(pg.lines, id)
    push!(pg.lines_at_bus[tbus], id)
    push!(pg.lines_at_bus[fbus], id)
    push!(pg.line_is_aux, id => is_aux)
    push!(pg.line_is_proxy, id => is_proxy)
    push!(pg.line_start, id => tbus)
    push!(pg.lines_start_at_bus[tbus], id)
    push!(pg.line_end, id => fbus)
    push!(pg.lines_end_at_bus[fbus], id)
    push!(pg.line_capacity, id => capacity)
    push!(pg.line_reactance, id => reactance)
    return id
end

function splitBus!(pg::PowerGrid, id::Int64)
    if !pg.bus_decomposed[id]
        sg = sub_grid(id, Vector{Int64}(), Vector{Int64}())
        push!(sg.buses, id)
        new_buses = Vector{Int64}()
        if length(pg.lines_at_bus[id]) > 1
            for i in 1:length(pg.lines_at_bus[id])
                nb = addBus!(pg, root = id)
                push!(new_buses, nb)
                push!(sg.buses, nb)
                lid = addLine!(pg, id, nb, is_aux = true)
                push!(sg.lines, lid)
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
                    lid = addLine!(pg, new_buses[i], new_buses[j], is_aux = true, is_proxy = true)
                    push!(sg.lines, lid)
                end
            end
        end
        pg.bus_decomposed[id] = true
        push!(pg.root_buses, id)
        if pg.sub_grids == nothing
            pg.sub_grids = Vector{sub_grid}()
        end
        push!(pg.sub_grids, sg)
        return true, new_buses
    else
        println("A bus can only be split once.")
        println("Consider reloading the dataset, to perform this operation.")
        return false
    end
end

function _splitBus!(pg::PowerGrid, id::Int64, n_bus_bars::Int64 = 2)
    # Regular bus: type = 1
    # Bus bar: type = 2
    # Connector: type = 3
    if !pg.bus_decomposed[id]
        sg = sub_grid(id, Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Dict{Int64, Int64}(), Dict{Int64, Dict{Int64, Int64}}())
        push!(sg.buses, id)
        connectors = Vector{Int64}()
        bus_bars = Vector{Int64}()
        bus_bar_root_line = Dict{Int64, Int64}()
        externalLines = Vector{Int64}()
        external_line_by_connector = Dict{Int64, Int64}()
        internal_line_by_bus_bar = Dict{Int64, Dict{Int64, Int64}}()
        if length(pg.lines_at_bus[id]) >= 1
            # Construct connectors
            for i in 1:length(pg.lines_at_bus[id])
                nb = addBus!(pg, root = id, type = 3)
                push!(external_line_by_connector, nb => pg.lines_at_bus[id][1])
                push!(externalLines, pg.lines_at_bus[id][1])
                push!(connectors, nb)
                push!(sg.buses, nb)
                # Connectors - Reconfigure lines
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
            # Construct bus bars
            for i in 1:n_bus_bars
                nb = addBus!(pg, root = id, type = 2)
                push!(bus_bars, nb)
                push!(sg.buses, nb)
            end
            # Construct connector - bus bar lines
            for bb in bus_bars
                internalLine = Dict{Int64, Int64}()
                for con in connectors
                    line_id = addLine!(pg, bb, con, is_aux = true, is_proxy = true)
                    push!(internalLine, external_line_by_connector[con] => line_id)
                    push!(sg.lines, line_id)
                end
                push!(internal_line_by_bus_bar, bb => internalLine)
            end
            # Construct root - bus bar lines
            for bb in bus_bars
                line_id = addLine!(pg, id, bb, is_aux = true, is_proxy = true)
                push!(bus_bar_root_line, bb => line_id)
                push!(sg.lines, line_id)
            end
        end
        pg.bus_decomposed[id] = true
        push!(pg.root_buses, id)
        if pg.sub_grids == nothing
            pg.sub_grids = Vector{sub_grid}()
        end
        sg.connectors = connectors
        sg.bus_bars = bus_bars
        sg.internalLineByBusBar = internal_line_by_bus_bar
        sg.externalLines = externalLines
        sg.bus_bar_root_line = bus_bar_root_line
        push!(pg.sub_grids, sg)
        return true
    else
        println("A bus can only be split once.")
        println("Consider reloading the dataset, to perform this operation.")
        return false
    end
end



function __redirect_line(pg::PowerGrids.PowerGrid, line_id, fbus, tbus)

    @inline function swap_tb_fb()
        tmp = deepcopy(tbus)
        tbus = deepcopy(fbus)
        fbus = deepcopy(tmp)
    end

    fbus_is_new = true
    tbus_is_new = true

    if fbus == pg.line_end[line_id]
        fbus_is_new = false
        swap_tb_fb()
    elseif fbus == pg.line_start[line_id]
        fbus_is_new = false
    end

    if tbus == pg.line_start[line_id]
        tbus_is_new = false
        swap_tb_fb()
    elseif tbus == pg.line_end[line_id]
        tbus_is_new = false
    end

    if !((tbus_is_new && fbus_is_new) || (tbus == fbus))

        println(line_id," ",fbus," ",tbus)

        fbus_old = pg.line_start[line_id]
        tbus_old = pg.line_end[line_id]

        if fbus != fbus_old
            println("fbus")
            pg.line_start[line_id] = fbus
            if line_id in Set(pg.lines_start_at_bus[fbus_old])
                println(true)
                idx = indexin(line_id, pg.lines_start_at_bus[fbus_old])[]
                deleteat!(pg.lines_start_at_bus[fbus_old], idx)
                push!(pg.lines_start_at_bus[fbus], line_id)
            elseif line_id in Set(pg.lines_end_at_bus[fbus_old])
                println(true)
                println("Warning: Check line arrays.")
                idx = indexin(line_id, pg.lines_end_at_bus[fbus_old])[]
                deleteat!(pg.lines_end_at_bus[fbus_old], idx)
                push!(pg.lines_end_at_bus[fbus], line_id)
            end
            if line_id in Set(pg.lines_at_bus[fbus_old])
                idx = indexin(line_id, pg.lines_at_bus[fbus_old])[]
                deleteat!(pg.lines_at_bus[fbus_old], idx)
                push!(pg.lines_at_bus[fbus], line_id)
            end
        end

        if tbus != tbus_old
            println("tbus")
            pg.line_end[line_id] = tbus
            if line_id in Set(pg.lines_end_at_bus[tbus_old])
                idx = indexin(line_id, pg.lines_end_at_bus[tbus_old])[]
                deleteat!(pg.lines_end_at_bus[tbus_old], idx)
                push!(pg.lines_end_at_bus[tbus], line_id)
            elseif line_id in Set(pg.lines_start_at_bus[tbus_old])
                println("Warning: Check line arrays.")
                idx = indexin(line_id, pg.lines_start_at_bus[tbus_old])[]
                deleteat!(pg.lines_start_at_bus[tbus_old], idx)
                push!(pg.lines_start_at_bus[tbus], line_id)
            end
            if line_id in Set(pg.lines_at_bus[tbus_old])
                idx = indexin(line_id, pg.lines_at_bus[tbus_old])[]
                deleteat!(pg.lines_at_bus[tbus_old], idx)
                push!(pg.lines_at_bus[tbus], line_id)
            end
        end

    else
        print("No changes made: Choose tbus and fbus to be different and assign new values.")
    end
end

function addBus!(pg::PowerGrid; demand = 0.0, root = 0, type = 1, is_aux = true)

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

    push!(pg.root_bus, id => root)
    push!(pg.bus_type, id => type)
    push!(pg.bus_is_aux, id => is_aux)
    return id
end

function newBus!(pg::PowerGrid; demand = 0.0, root = 0)

    nb = length(pg.buses)
    id = pg.buses[nb] + 1
    push!(pg.buses, id)
    push!(pg.bus_decomposed, false)
    push!(pg.bus_demand, id => demand)
    push!(pg.bus_is_root, true)

    push!(pg.lines_at_bus, id => Vector{Int64}())
    push!(pg.lines_start_at_bus, id => Vector{Int64}())
    push!(pg.lines_end_at_bus, id => Vector{Int64}())
    push!(pg.adjacent_nodes, Vector{Int64}())
    push!(pg.generators_at_bus, id => Vector{Int64}())

    push!(pg.root_bus, id => root)
    return id
end



function update_line(pg::PowerGrids.PowerGrid, line_id, fbus, tbus; update_fbus = true)

    if update_fbus

        fbus_old = pg.line_start[line_id]
        pg.line_start[line_id] = fbus

        if line_id in Set(pg.lines_start_at_bus[fbus_old])
            idx = indexin(line_id, pg.lines_start_at_bus[fbus_old])[]
            deleteat!(pg.lines_start_at_bus[fbus_old], idx)
            push!(pg.lines_start_at_bus[fbus], line_id)
        else
            println("Error: Line not starting at bus.")
        end

        if line_id in Set(pg.lines_at_bus[fbus_old])
            idx = indexin(line_id, pg.lines_at_bus[fbus_old])[]
            deleteat!(pg.lines_at_bus[fbus_old], idx)
            push!(pg.lines_at_bus[fbus], line_id)
        else
            println("Error: Line not connected to bus.")
        end

    else

        tbus_old = pg.line_end[line_id]
        pg.line_end[line_id] = tbus

        if line_id in Set(pg.lines_end_at_bus[tbus_old])
            idx = indexin(line_id, pg.lines_end_at_bus[tbus_old])[]
            deleteat!(pg.lines_end_at_bus[tbus_old], idx)
            push!(pg.lines_end_at_bus[tbus], line_id)
        else
            println("Error: Line not starting at bus.")
        end

        if line_id in Set(pg.lines_at_bus[tbus_old])
            idx = indexin(line_id, pg.lines_at_bus[tbus_old])[]
            deleteat!(pg.lines_at_bus[tbus_old], idx)
            push!(pg.lines_at_bus[tbus], line_id)
        else
            println("Error: Line not connected to bus.")
        end

    end
end

function split_build_x0(case, otsp_sol = nothing)

    x0 = Dict{Int64, Float64}()
    for l in case.lines
        x0[l] = 0.0
    end

    for sg in case.sub_grids

        bb = sg.bus_bars[1]
        for l in case.lines_at_bus[bb]
            x0[l] = 1.0
        end
    end

    if otsp_sol != nothing

        for l in 1:length(otsp_sol)
            if round(abs(otsp_sol[l])) == 0.0
                fbus = case.line_start[l]
                tbus = case.line_end[l]
                @assert tbus != fbus

                if case.bus_is_aux[tbus]
                    for laux in case.lines_at_bus[fbus]
                        if case.line_is_aux[laux]
                            if x0[laux] == 1.0
                                x0[laux] = 0.0
                            end
                        end
                    end
                end

                if case.bus_is_aux[tbus]
                    for laux in case.lines_at_bus[tbus]
                        if case.line_is_aux[laux]
                            if x0[laux] == 1.0
                                x0[laux] = 0.0
                            end
                        end
                    end
                end

            end
        end
    end

    return x0
end
