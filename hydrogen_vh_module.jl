module Hydrogen_Vh
    using LinearAlgebra
    
    struct Hydrogen_Vh_param
        ELE_TOTAL::Int64
        INTEGTABLENUM::Int64
        NODE_TOTAL::Int64
        RESULT_FILENAME::String
    end

    mutable struct Hydrogen_Vh_variables
        mat_A_ele::Array{Float64, 3}
        mat_A_glo::SymTridiagonal{Float64,Array{Float64,1}}
        ug::Array{Float64, 1}
        vec_b_ele::Array{Float64, 2}
        vec_b_glo::Array{Float64, 1}
        w::Array{Float64, 1}
        x::Array{Float64, 1}
    end
end