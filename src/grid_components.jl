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
    cMinus1::S where S<:Number
    test::S where S<:Number
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
    cMinus1::S where S<:Number
    test::S where S<:Number
    c0::S where S<:Number

end
