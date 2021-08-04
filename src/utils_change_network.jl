function addBus!(pg::PowerGrid; demand = 0.0, root = 0, type = 1, is_aux = true)

    nb = length(pg.buses)
    id = pg.buses[nb] + 1
    push!(pg.buses, id)
    push!(pg.bus_decomposed, true)
    push!(pg.bus_Pd, id => demand)
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

function addLine!(pg::PowerGrid, tbus, fbus; is_aux = false, is_proxy = false, x = 10e-4, capacity = 5000.0)
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
    push!(pg.line_x, id => x)
    return id
end

function _redirect_line(pg::PowerGrids.PowerGrid, line_id, fbus, tbus)

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
