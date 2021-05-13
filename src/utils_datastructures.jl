function param_mat_A(pg::T where T <: PowerGrid)
    # Returns matrix A, which contains 1 if line e
    # starts and -1 if line e ends at node v.
    _mat_A = zeros(size(pg.lines, 1), size(pg.buses, 1))
    for i in 1:size(pg.lines, 1)
        _mat_A[i, pg.line_start[i]] = 1
        _mat_A[i, pg.line_end[i]] = -1
    end
    return _mat_A
end

function param_mat_X(pg::T where T <: PowerGrid)
    # Returns B matrix including the susceptence 
    # of every line in pg on its diagonal.
    _mat_X = zeros(size(pg.lines, 1), size(pg.lines, 1))
    for i in 1:size(pg.lines, 1)
        _mat_X[i, i] = pg.line_reactance[i]
    end
    return _mat_X
end