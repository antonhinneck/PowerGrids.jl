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

function __splitBus!(pg::PowerGrid, id::Int64, n_bus_bars::Int64 = 2)
    # Regular bus: type = 1
    # Bus bar: type = 2
    # Connector: type = 3
    # Load: type = 4
    # Generator: type = 5
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
                    line_id = addLine!(pg, bb, con, is_aux = true, is_proxy = true)
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
                    line_id = addLine!(pg, lb, bb, is_aux = true, is_proxy = true)
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
                        line_id = addLine!(pg, gb, bb, is_aux = true, is_proxy = true)
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
