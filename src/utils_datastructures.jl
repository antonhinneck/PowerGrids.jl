function _line_is_radial(pg::T where T <: PowerGrid, A)
    # Returns vector of ones and zeros, indicating
    # whether line e is radial or not.
    _line_is_radial = zeros(length(pg.lines))
    _connectivity = A'*A
    @assert Base.size(_connectivity, 1) == Base.size(_connectivity, 2)
    for i in 1:Base.size(_connectivity, 1)
        if _connectivity[i, i] == 1.0
            for j in pg.lines_at_bus[i]
                _line_is_radial[pg.line_id[j]] == 1.0
            end
        end
        if _connectivity[i, i] == 0.0
            println("Warning: Grid islanded.")
        end
    end
    return _line_is_radial
end

function rm_update_line_id(pg::T where T <: PowerGrid)
    counter = 1
    for l in pg.lines
        pg.line_id[l] = counter
        counter += 1
    end
end

function param_mat_P(pg::T where T <: PowerGrid)
    # Returns quadratic costs of generator g.
    _mat_P = zeros(size(pg.buses, 1), size(pg.generators, 1))
    for i in pg.generators
        _mat_P[pg.generator_bus_id[i], i] = 1
    end
    return _mat_P
end

function param_mat_c2_rt(pg::T where T <: PowerGrid)
    # Returns quadratic costs of generator g.
    _mat_c2_rt = zeros(size(pg.generators, 1), size(pg.generators, 1))
    for i in pg.generators
        _mat_c2_rt[i, i] = pg.generator_c2[i]^2
    end
    return _mat_c2_rt
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
    if normalized
        _vec_fmax /= pg.base_mva
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

function param_mat_A(pg::T where T <: PowerGrid; _feas_check = false, line_statuses = ones(length(pg.lines)))
    # Returns matrix A, which contains 1 if line e
    # starts and -1 if line e ends at node v.
    _mat_A = zeros(size(pg.lines, 1), size(pg.buses, 1))
    for i in 1:size(pg.lines, 1)
        if line_statuses[i] == 1.0
            _mat_A[i, pg.line_start[i]] = 1
            _mat_A[i, pg.line_end[i]] = -1
        end
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

function param_mat_A_alt(pg::T where T <: PowerGrids.PowerGrid, A)
    # Returns matrix A, which contains 1 if line e
    # starts and -1 if line e ends at node v.
    # Radial lines are removed.
    _mat_A_alt = copy(A)
    _radial_lines = _line_is_radial(pg, A)
    for l in _radial_lines
        if l == 1.0
            if pg.lines_at_bus[pg.line_start[l]] == 1 && pg.lines_at_bus[pg.line_end[l]] > 1
                _mat_A_alt[l, pg.line_start[l]] = 0
            elseif pg.lines_at_bus[pg.line_end[l]] == 1 && pg.lines_at_bus[pg.line_start[l]] > 1
                _mat_A_alt[l, pg.line_end[l]] = 0
            else
                println("Warning: Uncaught case in param_mat_A_alt.")
            end
        end
    end
    return _mat_A_alt
end

function param_mat_B(pg::T where T <: PowerGrids.PowerGrid; _refbus = 1.0, line_statuses = ones(length(pg.lines)))
    # Returns B matrix including the susceptence 
    # of every line in pg on its diagonal.
    _mat_B = zeros(size(pg.buses, 1), size(pg.buses, 1))
    for i in 1:size(pg.lines, 1)
        if line_statuses[i] == 1.0
            @assert pg.line_start[i] != pg.line_end[i]
            _mat_B[pg.line_start[i], pg.line_end[i]] -= 1 / pg.line_x[i]
            _mat_B[pg.line_end[i], pg.line_start[i]] -= 1 / pg.line_x[i]
            _mat_B[pg.line_start[i], pg.line_start[i]] += 1 / pg.line_x[i]
            _mat_B[pg.line_end[i], pg.line_end[i]] += 1 / pg.line_x[i]
        end
    end
    _mat_B[_refbus, :] = zeros(length(_mat_B[_refbus, :]))
    _mat_B[:, _refbus] = zeros(length(_mat_B[:, _refbus]))
    _mat_B[_refbus, _refbus] = 1.0
    return _mat_B
end

function param_mat_B_alt(pg::T where T <: PowerGrids.PowerGrid, A_alt, B; _refbus = 1.0)
    # Returns B matrix including the susceptence 
    # of every line in pg on its diagonal.
    # Without radial lines.
    _mat_B_alt = copy(B)
    _numlines_at_bus = diag(A_alt'*A_alt)
    for i in pg.buses
        if _numlines_at_bus[i] == 0.0 || i == _refbus
            for j in pg.buses
                _mat_B_alt[i, j] = 0
            end
            _mat_B_alt[i, i] = 1.0
        end
    end
    return _mat_B_alt
end

function param_mat_X(B)
    # Returns matrix X, which is the inverse of B.
    # Requires LinearAlgebra.jl
    return inv(B)
end

function param_mat_X_alt(B_alt; _refbus = 1)
    # Returns matrix X, which is the inverse of B.
    # Requires LinearAlgebra.jl
    X_alt = inv(B_alt)
    X_alt[_refbus, _refbus] = 0
    return X_alt
end

function param_mat_ptdf(pg::T where T <: PowerGrids.PowerGrid; _refbus = 1, line_statuses = ones(length(pg.lines)))

    A = param_mat_A(pg, line_statuses = line_statuses)
    B = param_mat_B(pg, _refbus = _refbus, line_statuses = line_statuses)
    B_alt = param_mat_B_alt(pg, param_mat_A_alt(pg, A), B, _refbus = _refbus)
    X_alt = param_mat_X_alt(B_alt, _refbus = _refbus)
    _ptdf = diagm([1 / pg.line_x[l] for l in pg.lines]) * A * X_alt 

    _is_radial = _line_is_radial(pg, A)
    for l in pg.lines
        if _is_radial[l] == 1.0
            _ptdf[l,l] = 0.0
        end
    end
    
    return _ptdf
end

function param_mat_lodf(pg::T where T <: PowerGrids.PowerGrid; _refbus = 1, line_statuses = ones(length(pg.lines)), _tol = 1e-6)

    num_lines = length(pg.lines)
    A = param_mat_A(pg, line_statuses = line_statuses)
    A_alt = param_mat_A_alt(pg, A)
    B = param_mat_B(pg, _refbus = _refbus, line_statuses = line_statuses)
    B_alt = param_mat_B_alt(pg, param_mat_A_alt(pg, A), B, _refbus = _refbus)
    X_alt = param_mat_X_alt(B_alt, _refbus = _refbus)
    _ptdf = diagm([1 / pg.line_x[l] for l in pg.lines]) * A * X_alt 
    _tmp_mat1 = _ptdf * A_alt'
    _tmp_mat2 = diag(_tmp_mat1)

    ## Treat divide-by-zero issues
    ##############################
    for i in pg.lines
        if abs(_tmp_mat2[pg.line_id[i]] - 1.0) < _tol
            _tmp_mat2[pg.line_id[i]] = 0.0
        end
    end

    _lodf = _tmp_mat1 ./ (ones(num_lines, num_lines) - ones(num_lines, 1) * _tmp_mat2')
    _lodf = _lodf - diagm(diag(_lodf)) - diagm(ones(num_lines))

    return _lodf
end
