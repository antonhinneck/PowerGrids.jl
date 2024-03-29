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

function getidx(arr, val)
    @assert eltype(arr) == typeof(val)
    id = -1
    for i in 1:length(arr)
        if arr[i] == val
            id = i
            break
        end
    end
    return id
end

# Switching criteria
# Line differnce switching criterion
function get_sensitivities_lpsc(pg::PowerGrids.PowerGrid, model::Model; line_statuses = ones(length(pg.lines)))
    _lpsc = Array{Float64, 1}(undef, Base.size(pg.lines, 1))
    for i in 1:length(pg.lines)
        if pg.lines[i] in keys([model[:f]...])
            _lpsc[i] = value(model[:f][pg.lines[i]]) * ( dual(model[:nb][pg.bus_id[pg.line_end[pg.lines[i]]]]) - dual(model[:nb][pg.bus_id[pg.line_start[pg.lines[i]]]]) )
        else
            _lpsc[i] = 0.0
        end
    end
    return _lpsc
end

# Price difference switching criterion
function get_sensitivities_pdsc(pg::PowerGrids.PowerGrid, model::Model; line_statuses = ones(length(pg.lines)))
    _pdsc = Array{Float64, 1}(undef, Base.size(pg.lines, 1))
    for i in 1:length(pg.lines)
        _pdsc[i] = ( dual(model[:nb][pg.bus_id[pg.line_end[pg.lines[i]]]]) - dual(model[:nb][pg.bus_id[pg.line_start[pg.lines[i]]]]) )
    end
    return _pdsc
end

# Total cost difference switching criterion
function get_sensitivities_tcdsc(pg::PowerGrids.PowerGrid, model::Model; line_statuses = ones(length(pg.lines)))
    _tcdsc = Array{Float64, 1}(undef, Base.size(pg.lines, 1))
    _lodf = PowerGrids.param_mat_lodf(pg)
    _β1 = [dual.(model[:fl1]).data[(l,)] for l in 1:length(pg.lines)]
    _β2 = [dual.(model[:fl2]).data[(l,)] for l in 1:length(pg.lines)]
    _f = value.(model[:f]).data
    for i in 1:length(pg.lines)
        _val = (_β1 - _β2)' * _lodf[i, :]
        if _val * _f[(i,)] < 0
            _tcdsc[i] = _val
        else
            _tcdsc[i] = 0.0
        end
    end
    return _tcdsc
end

# PTDF-Weighted cost derivative criterion: DONE
function get_sensitivities_pwsc(pg::PowerGrids.PowerGrid, model::Model; line_statuses = ones(length(pg.lines)))
    _pdsc = Array{Float64, 1}(undef, Base.size(pg.lines, 1))
    _lodf = PowerGrids.param_mat_lodf(pg)
    _β1 = [dual.(model[:fl1]).data[(l,)] for l in 1:length(pg.lines)]
    _β2 = [dual.(model[:fl2]).data[(l,)] for l in 1:length(pg.lines)]
    _π = [dual.(model[:nb]).data[b] for b in 1:length(pg.buses)]
    _f = [value.(model[:f]).data[(l,)] for l in 1:length(pg.lines)]
    for i in 1:length(pg.lines)
        _val = _β1[i] - _β2[i] - _π[pg.bus_id[pg.line_end[i]]] + _π[pg.bus_id[pg.line_start[i]]]
        _crit = (_β1 - _β2)' * _lodf[i, :]
        if _crit * _f[i] < 0
            _pdsc[i] = _val
        else
            _pdsc[i] = 0.0
        end
    end
    return _pdsc
end