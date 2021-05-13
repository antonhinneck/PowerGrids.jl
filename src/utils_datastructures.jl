function param_mat_A(pg::T where T <: PowerGrid)
    # Returns matrix A, which contains 1 if line e
    # starts and -1 if line e ends at node v.
    _mat_A = zeros(size(pg.lines), size(pg.buses))
    for i in 1:pg.lines
        _mat_A[i, pg.line_start[i]]
        _mat_A[i, pg.line_end[i]]
    end
    return _mat_A
end

function param_mat_B(pg::T where T <: PowerGrid)
    # Returns B matrix including the susceptence 
    # of every line in pg on its diagonal.
    _mat_B = zeros(size(pg.lines), size(pg.lines))
    for i in 1:pg.lines
        _mat_B[i, i] = pg.line_resistance[i]
    end
    return _mat_B
end