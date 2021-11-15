mutable struct PowerGrid
    # bus::DataFrame
    # gen::DataFrame
    # gencost::DataFrame
    # branch::DataFrame
    # buses_input
    # generators_input
    # branches_input
    base_mva
    buses
    root_buses
    bus_decomposed
    bus_is_root
    root_bus
    bus_type
    bus_is_aux
    vertex_edge_matrix
    adjacent_nodes
    generators
    generator_Pmin
    generator_Pmax
    generator_Qmin
    generator_Qmax
    generator_c0
    generator_c1
    generator_c2
    generator_bus_id
    generators_at_bus
    lines
    line_is_aux
    line_is_proxy
    line_start
    line_end
    line_capacity
    line_r
    line_x
    line_b
    lines_at_bus
    lines_start_at_bus
    lines_end_at_bus
    bus_id
    bus_Pd
    bus_Qd
    bus_Vmin
    bus_Vmax
    sub_grids
    line_id
end

mutable struct sub_grid
    root_bus::Int64
    buses::Vector{Int64}
    bus_bars::Vector{Int64}
    con_buses::Vector{Int64}
    load_buses::Vector{Int64}
    gen_buses::Vector{Int64}
    lines::Vector{Int64}
    externalLines::Vector{Int64}
    bus_bar_root_line::Dict{Int64, Int64}
    internalLineByBusBar::Dict{Int64, Dict{Int64, Int64}}
end

abstract type Bus end
abstract type Branch end
abstract type Generator end

mutable struct bus <: Bus
    bus_i::S where S<:Integer
    type::S where S<:Real
    Pd::S where S<:Real
    Qd::S where S<:Real
    Gs::S where S<:Real
    Bs::S where S<:Number
    area::S where S<:Number
    Vm::S where S<:Number
    Va::S where S<:Number
    baseKV::S where S<:Number
    zone::S where S<:Number
    Vmax::S where S<:Number
    Vmin::S where S<:Number
    # latitude::S where S<:Real
    # longitude::S where S<:Real
end

mutable struct branch <: Branch
    fbus::S where S<:Number
    tbus::S where S<:Number
    r::S where S<:Number
    x::S where S<:Number
    b::S where S<:Number
    rateA::S where S<:Number
    rateB::S where S<:Number
    rateC::S where S<:Number
    ratio::S where S<:Number
    angle::S where S<:Number
    status::S where S<:Number
    angmin::S where S<:Number
    angmax::S where S<:Number
end

mutable struct generator <: Generator
    ## Generator DATA
    ##---------------
    bus_i::S where S<:Number
    Pg::S where S<:Number
    Qg::S where S<:Number
    Qmax::S where S<:Number
    Qmin::S where S<:Number
    Vg::S where S<:Number
    mBase::S where S<:Number
    status::S where S<:Number
    Pmax::S where S<:Number
    Pmin::S where S<:Number
    ## Cost DATA
    ##---------------
    two::S where S<:Number
    startup::S where S<:Number
    shutdown::S where S<:Number
    n::S where S<:Number
    c2::S where S<:Number
    c1::S where S<:Number
    c0::S where S<:Number
end

mutable struct extended_generator <: Generator
    ## Generator DATA
    ##---------------
    bus_i::S where S<:Number
    Pg::S where S<:Number
    Qg::S where S<:Number
    Qmax::S where S<:Number
    Qmin::S where S<:Number
    Vg::S where S<:Number
    mBase::S where S<:Number
    status::S where S<:Number
    Pmax::S where S<:Number
    Pmin::S where S<:Number
    Pc1::S where S<:Number
    Pc2::S where S<:Number
    Qc1min::S where S<:Number
    Qc1max::S where S<:Number
    Qc2min::S where S<:Number
    Qc2max::S where S<:Number
    ramp_agc::S where S<:Number
    ramp_10::S where S<:Number
    ramp_30::S where S<:Number
    ramp_q::S where S<:Number
    apf::S where S<:Number
    ## Cost DATA
    ##---------------
    two::S where S<:Number
    startup::S where S<:Number
    shutdown::S where S<:Number
    n::S where S<:Number
    c2::S where S<:Number
    c1::S where S<:Number
    c0::S where S<:Number
end
