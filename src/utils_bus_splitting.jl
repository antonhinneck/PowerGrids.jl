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

function __splitBus!(pg::PowerGrid, id::Int64, n_bus_bars::Int64 = 2; smart = false)
    # Regular bus: type = 1
    # Bus bar: type = 2
    # Connector: type = 3
    # Load: type = 4
    # Generator: type = 5
    proxy = false
    if n_bus_bars == 1
        proxy = true
    end

    if smart
        nWE = length(pg.lines_at_bus[id])
        nGE = length(pg.generators_at_bus[id])
        if pg.bus_demand[id] > 0.0
            nGd = 1
        else
            nGd = 0
        end
        nWB = min(nWE, Int64(floor((nWE + nGE + nGd) / 2)))
        if nWE = 1
            n_bus_bars = 0
        else
            n_bus_bars = nWB
        end
    end

    if !pg.bus_decomposed[id]
        sg = sub_grid(id, Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Dict{Int64, Int64}(), Dict{Int64, Dict{Int64, Int64}}())
        #push!(sg.buses, id)
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
                    line_id = addLine!(pg, bb, con, is_aux = true)
                    push!(internalLine, external_line_by_connector[con] => line_id)
                    push!(sg.lines, line_id)
                end
                push!(internal_line_by_bus_bar, bb => internalLine)
            end

            # Construct load
            load_buses = Vector{Int64}()
            load_exists = false
            if pg.bus_demand[id] > 0.0
                load_exists = true
                lb = addBus!(pg, root = id, type = 4)
                push!(pg.bus_demand, lb => pg.bus_demand[id])
                push!(load_buses, lb)
                push!(sg.buses, lb)
                pg.bus_demand[id] = 0.0
            end

            # Construct Load - bus bar lines
            if load_exists
                for bb in bus_bars
                    line_id = addLine!(pg, lb, bb, is_aux = true, is_proxy = proxy)
                    #push!(bus_bar_root_line, bb => line_id)
                    push!(sg.lines, line_id)
                end
            end

            # Construct generators
            gen_buses = Vector{Int64}()
            for g in pg.generators_at_bus[id]
                gb = addBus!(pg, root = id, type = 5)
                push!(gen_buses, gb)
                push!(sg.buses, gb)
                push!(pg.generators_at_bus[gb], g)
            end
            pg.generators_at_bus[id] = Vector{Int64}()
            # Construct generator - bus bar lines
            if length(gen_buses) != 0
                for bb in bus_bars
                    for gb in gen_buses
                        line_id = addLine!(pg, gb, bb, is_aux = true, is_proxy = proxy)
                        #push!(bus_bar_root_line, bb => line_id)
                        push!(sg.lines, line_id)
                    end
                end
            end

            # # Construct root - bus bar lines
            # for bb in bus_bars
            #     line_id = addLine!(pg, id, bb, is_aux = true, is_proxy = true)
            #     push!(bus_bar_root_line, bb => line_id)
            #     push!(sg.lines, line_id)
            # end
        end
        pg.bus_decomposed[id] = true
        push!(pg.root_buses, id)
        if pg.sub_grids == nothing
            pg.sub_grids = Vector{sub_grid}()
        end
        sg.con_buses = connectors
        sg.bus_bars = bus_bars
        sg.load_buses = load_buses
        sg.gen_buses = gen_buses
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

# Construct initial solution with all lines active
#-------------------------------------------------
function sol_allActive(case; select = :first)

    sol = zeros(length(case.lines))

    @inline function _set_line_as_active(bus::Int64)
        if select == :first
            for l in case.lines_at_bus[bus]
                if case.line_is_aux[l]
                    sol[l] = 1.0
                    break
                end
            end
        end
    end

    for sg in case.sub_grids
        # Set bus bar - connector lines
        #------------------------------
        for cb in sg.con_buses
            _set_line_as_active(cb)
        end

        # Set bus bar - load bus lines
        #-----------------------------
        for lb in sg.load_buses
            _set_line_as_active(lb)
        end

        # Set bus bar - gen bus lines
        #----------------------------
        for gb in sg.gen_buses
            _set_line_as_active(gb)
        end
    end

    return sol
end

# Construct OBSP solution from OTSP solution
#-------------------------------------------
function sol_otsp2obsp(case, sol_otsp::Array{T, 1} where T <: Real; select = :first)

    sol = zeros(length(case.lines))

    @inline function _set_line_as_active(bus::Int64, bus_bar::Int64)
        if select == :first
            for l in case.lines_at_bus[bus]
                if case.line_is_aux[l] && (case.line_end[l] == bus_bar || case.line_start[l] == bus_bar)
                    sol[l] = 1.0
                    break
                end
            end
        end
    end

    for sg in case.sub_grids

        @assert length(sg.bus_bars) > 0 "At least one bus bar must exist in the substation model."
        bus_bar = sg.bus_bars[1]

        # Set bus bar - con lines
        #------------------------
        for (i, cb) in enumerate(sg.con_buses)
            if sol_otsp[sg.externalLines[i]] == 1.0
                _set_line_as_active(cb, bus_bar)
            end
        end

        # Set bus bar - load bus lines
        #-----------------------------
        for lb in sg.load_buses
            _set_line_as_active(lb, bus_bar)
        end

        # Set bus bar - gen bus lines
        #----------------------------
        for gb in sg.gen_buses
            _set_line_as_active(gb, bus_bar)
        end
    end

    return sol
end

function dfs_components(pg::PowerGrids.PowerGrid, sg::PowerGrids.sub_grid; l_stat = nothing) # TODO: op_status

    visited = fill(false, length(sg.buses))
    visited_lines = Vector{Int64}()
    all_visited = false
    components = Vector{PowerGrids.sub_grid}()
    connected_buses = [sg.root_bus]
    iter = 0

    @inline function _transfer_bus!(sg, _sg, b::Int64)
    # This function writes type-specific bus information into a new sub grid.

        # Regular bus: type = 1
        # Bus bar: type = 2
        # Connector: type = 3
        # Load: type = 4
        # Generator: type = 5
        type = convert(Int64, 0)
        if b in Set(sg.bus_bars)
            type = convert(Int64, 2)
            push!(_sg.bus_bars, b)
        elseif b in Set(sg.con_buses)
            type = convert(Int64, 3)
            push!(_sg.con_buses, b)
        elseif b in Set(sg.load_buses)
            type = convert(Int64, 4)
            push!(_sg.load_buses, b)
        elseif b in Set(sg.gen_buses)
            type = convert(Int64, 5)
            push!(_sg.gen_buses, b)
        else
            throw(ErrorException("Bus type undetermined."))
        end

        push!(_sg.buses, b)

        return type
    end

    while !all_visited #&& iter < 3

        for i in 1:length(visited)
            if !visited[i]
                connected_buses = [sg.buses[i]]
                break
            end
        end

        _sg = PowerGrids.sub_grid(sg.root_bus, Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Vector{Int64}(), Dict{Int64, Int64}(), Dict{Int64, Dict{Int64, Int64}}())

        while length(connected_buses) > 0

            new_buses = Vector{Int64}()
            for b in connected_buses
                _transfer_bus!(sg, _sg, b)
                for l in pg.lines_at_bus[b]
                    if l in Set(sg.lines) && !(l in Set(visited_lines)) && round(l_stat[l]) == 1.0
                        #if !(l in Set(visited_lines))
                        if pg.line_start[l] == b
                            push!(new_buses, pg.line_end[l])
                        else
                            push!(new_buses, pg.line_start[l])
                        end
                        push!(_sg.lines, l)
                        push!(visited_lines, l)
                        #end
                    end
                end
            end

            for (i, b) in enumerate(sg.buses)
                if b in Set(connected_buses)
                    visited[i] = true
                end
            end
            connected_buses = deepcopy(new_buses)
        end

        all_visited = true
        for v in visited
            if !v
                all_visited = false
                break
            end
        end
        iter += 1
        #push!(components, _sg)
        single_connector = false
        if length(_sg.buses) == 1
            if (pg.bus_type[_sg.buses[1]] == 3)
                single_connector = true
            end
        end

        if length(_sg.buses) > 1 || single_connector
            push!(components, _sg)
        end
    end

    return components
end

function reassign_generator!(case, gen, src, target)

    @assert gen in Set(case.generators) "Generator does not exist."
    @assert gen in Set(case.generators_at_bus[src]) "Generator is not assigned to src."

    idx = indexin(gen, case.generators_at_bus[src])[]
    deleteat!(case.generators_at_bus[src], idx)

    push!(case.generators_at_bus[target], gen)
end

function reassign_demand!(case, src, target)

    @assert case.bus_demand[target] == 0.0 "Demand at target bus is unequal 0."
    case.bus_demand[target] = case.bus_demand[src]
    case.bus_demand[src] = 0.0
end

function reduce_grid(pg::PowerGrids.PowerGrid, pg_id::Int64, l_stat)

    PowerGrids.select_csv_case(pg_id)
    reset_case = PowerGrids.loadCase()
    #println(reset_case.buses)

    if pg.sub_grids != nothing
        for sg in pg.sub_grids
            components = dfs_components(pg, sg, l_stat = l_stat)

            for (i,c) in enumerate(components)

                if i > 1

                    connected_lines = Vector{Int64}()

                    for b in c.buses
                        for l in pg.lines_at_bus[b]
                            if l in Set(reset_case.lines)
                                push!(connected_lines, l)
                            end
                        end
                    end

                    nbid = newBus!(reset_case)
                    obid = c.root_bus

                    # Redirect lines
                    for l in connected_lines
                        if reset_case.line_start[l] == obid
                            update_line(reset_case, l, nbid, pg.line_end[l])
                        elseif reset_case.line_end[l] == obid
                            update_line(reset_case, l, pg.line_start[l], nbid, update_fbus = false)
                        else
                            print("Line has no matching start or end.")
                        end
                    end

                    # Reassign generators
                    for gb in c.gen_buses
                        reassign_generator!(reset_case, pg.generators_at_bus[gb][], c.root_bus, nbid)
                    end

                    # Reassign loads
                    if length(c.load_buses) != 0
                        reassign_demand!(reset_case, c.root_bus, nbid)
                    end
                end

            end
        end
    else
        print("This function can only be applied after splitBus! has been called.")
    end

    return reset_case
end
