include("hydrogen_fem_julia.jl")
include("hydrogen_vh_julia.jl")
using Printf
using .Hydrogen_FEM
using .Hydrogen_Vh
#using Plots

function main()
    hfem_param, hfem_val = Hydrogen_FEM.construct()
    
    Hydrogen_FEM.make_wavefunction(hfem_param, hfem_val)
    vh_param, vh_val = Hydrogen_Vh.construct(hfem_param)
    Hydrogen_Vh.do_run(hfem_param, hfem_val, vh_val)

    @printf "計算が終わりました\n"
    Hydrogen_Vh.save_result(hfem_val, vh_param, vh_val)
    @printf "計算結果を%sに書き込みました\n" vh_param.RESULT_FILENAME
    #plot(val.node_r_glo, val.phi)
end
@time main()