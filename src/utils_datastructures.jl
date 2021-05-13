function param_mat_c2_rt(pg::T where T <: PowerGrid)
    # Returns quadratic costs of generator g.
    _mat_c2_rt = zeros(size(pg.generators, 1), size(pg.generators, 1))
    for i in pg.generators
        _mat_c2_rt[i] = pg.generator_c2[i]
    end
    return _vec_c2
end

function param_vec_c2(pg::T where T <: PowerGrid)
    # Returns quadratic costs of generator g.
    _vec_c2 = zeros(size(pg.generators, 1))
    for i in 1:size(pg.generators, 1)
        try
            _vec_c2[i] = pg.generator_c2[i]
        catch ex
            _vec_c2[i] = 0
        end
    end
    return _vec_c2
end

function param_vec_c1(pg::T where T <: PowerGrid)
    # Returns linear costs of generator g.
    _vec_c1 = zeros(size(pg.generators, 1))
    for i in 1:size(pg.generators, 1)
        try
            _vec_c1[i] = pg.generator_c1[i]
        catch ex
            _vec_c1[i] = 0
        end
    end
    return _vec_c1
end

function param_vec_c0(pg::T where T <: PowerGrid; normalized = false)
    # Returns vector of maximal line capacity.
    _vec_c0 = zeros(size(pg.generators, 1))
    for i in 1:size(pg.generators, 1)
        try
            _vec_c0[i] = pg.generator_c0[i]
        catch ex
            _vec_c0[i] = 0
        end
    end
    return _vec_c0
end

function param_vec_fmax(pg::T where T <: PowerGrid; normalized = false)
    # Returns vector of maximal line capacity.
    _vec_fmax = zeros(size(pg.lines, 1))
    for i in 1:size(pg.lines, 1)
        try
            _vec_fmax[i] = pg.line_capacity[i]
        catch ex
            _vec_fmax[i] = 0
        end
    end
    return _vec_fmax
end

function param_vec_x(pg::T where T <: PowerGrid)
    # Returns vector of line reactances.
    _vec_x = zeros(size(pg.lines, 1))
    for i in 1:size(pg.lines, 1)
        try
            _vec_x[i] = pg.line_reactance[i]
        catch ex
            _vec_x[i] = 0
        end
    end
    return _vec_x
end

function param_vec_Pmax(pg::T where T <: PowerGrid; normalized = false)
    # Returns vector of bus loads.
    _vec_Pmax = zeros(size(pg.generators, 1))
    for i in 1:size(pg.generators, 1)
        try
            _vec_Pmax[i] = pg.generator_capacity_max[i]
        catch ex
            _vec_Pmax[i] = 0
        end
    end
    if normalized
        _vec_Pmax /= pg.base_mva
    end
    return _vec_Pmax
end

function param_vec_d(pg::T where T <: PowerGrid; normalized = false)
    # Returns vector of bus loads.
    _vec_d = zeros(size(pg.buses, 1))
    for i in 1:size(pg.buses, 1)
        try
            _vec_d[i] = pg.bus_demand[i]
        catch ex
            _vec_d[i] = 0
        end
    end
    if normalized
        _vec_d /= pg.base_mva
    end
    return _vec_d
end

function param_mat_A(pg::T where T <: PowerGrid; _feas_check = false)
    # Returns matrix A, which contains 1 if line e
    # starts and -1 if line e ends at node v.
    _mat_A = zeros(size(pg.lines, 1), size(pg.buses, 1))
    for i in 1:size(pg.lines, 1)
        _mat_A[i, pg.line_start[i]] = 1
        _mat_A[i, pg.line_end[i]] = -1
    end
    # Check feasibility of matrix, rows should sum to 0.
    _feas = true
    if _feas_check
        for i in 1:size(_mat_A,1)
            println(sum(_mat_A[i, :]))
            if sum(_mat_A[i, :]) != 0
                _feas = false
            end
        end
    end
    @assert _feas == true "Rows do not sum to 1."
    return _mat_A
end

function param_mat_X(pg::T where T <: PowerGrid)
    # Returns B matrix including the susceptence 
    # of every line in pg on its diagonal.
    _mat_X = zeros(size(pg.lines, 1), size(pg.lines, 1))
    for i in 1:size(pg.lines, 1)
        _mat_X[i, i] = 1 / pg.line_reactance[i]
    end
    return _mat_X
end