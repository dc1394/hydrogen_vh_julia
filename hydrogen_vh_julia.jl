module Hydrogen_Vh
    include("hydrogen_vh_module.jl")
    include("hydrogen_fem_julia.jl")
    using FastGaussQuadrature
    using LinearAlgebra
    using Match
    using Printf

    function construct(hfem_param)
        vh_param = Hydrogen_Vh.Hydrogen_Vh_param("result.csv", 100)

        tmp_dv = zeros(2)
        tmp_ev = zeros(1)
        
        vh_val =  Hydrogen_Vh.Hydrogen_Vh_variables(
            zeros(hfem_param.ELE_TOTAL, 2, 2),
            SymTridiagonal(tmp_dv, tmp_ev),
            zeros(hfem_param.NODE_TOTAL),
            zeros(hfem_param.ELE_TOTAL, 2),
            zeros(hfem_param.NODE_TOTAL),
            zeros(vh_param.INTEGTABLENUM),
            zeros(vh_param.INTEGTABLENUM))
        
        vh_val.x, vh_val.w = gausslegendre(vh_param.INTEGTABLENUM)

        return vh_param, vh_val
    end

    function do_run(hfem_param, hfem_val, vh_val)
        # 要素行列とLocal節点ベクトルを生成
        make_element_matrix_and_vector(hfem_param, hfem_val, vh_val)

        # 全体行列と全体ベクトルを生成
        tmp_dv, tmp_ev = make_global_matrix_and_vector(hfem_param, hfem_val, vh_val)

        # 境界条件処理
        boundary_conditions(hfem_param, vh_val, tmp_dv, tmp_ev)

        #// 連立方程式を解く
        vh_val.ug = vh_val.mat_A_glo \ vh_val.vec_b_glo
    end

    save_result(hfem_val, vh_val) = let
        open("result.csv", "w" ) do fp
            for i = 2:length(hfem_val.node_r_glo)
                r = hfem_val.node_r_glo[i]
                println(fp, @sprintf "%.14f, %.14f, %.14f" (r) (vh_val.ug[i] / r) (- (1.0 + 1.0 / r) * exp(-2.0 * r) + 1.0 / r))
            end
        end
    end
    
    function boundary_conditions(hfem_param, vh_val, tmp_dv, tmp_ev)
        a = 0.0;
        tmp_dv[1] = 1.0
        vh_val.vec_b_glo[1] = a;
        vh_val.vec_b_glo[2] -= a * tmp_ev[1];
        tmp_ev[1] = 0.0;
    
        b = 1.0;
        tmp_dv[hfem_param.NODE_TOTAL] = 1.0;
        vh_val.vec_b_glo[hfem_param.NODE_TOTAL] = b;
        vh_val.vec_b_glo[hfem_param.NODE_TOTAL - 1] -= b * tmp_ev[hfem_param.NODE_TOTAL - 1]
        tmp_ev[hfem_param.NODE_TOTAL - 1] = 0.0;

        vh_val.mat_A_glo = SymTridiagonal(tmp_dv, tmp_ev)
    end

    function gl_integ(f, x1, x2, vh_val)
        xm = 0.5 * (x1 + x2);
        xr = 0.5 * (x2 - x1);
        
        s = sum(i -> vh_val.w[i] * f(xm + xr * vh_val.x[i]), eachindex(vh_val.x))
        
        return s * xr;
    end

    function make_element_matrix_and_vector(hfem_param, hfem_val, vh_val)
        # 要素行列とLocal節点ベクトルの各成分を計算
        for e = 1:hfem_param.ELE_TOTAL
            for i = 1:2
                for j = 1:2
                    vh_val.mat_A_ele[e, i, j] = (-1) ^ i * (-1) ^ j / hfem_val.length[e]
                end

                vh_val.vec_b_ele[e, i] =
                    @match i begin
                        1 => -gl_integ(r -> -r * Hydrogen_FEM.rho(hfem_param, hfem_val, r) * (hfem_val.node_r_ele[e, 2] - r) / hfem_val.length[e],
                                hfem_val.node_r_ele[e, 1],
                                hfem_val.node_r_ele[e, 2],
                                vh_val)
                        
                        2 => -gl_integ(r -> -r * Hydrogen_FEM.rho(hfem_param, hfem_val, r) * (r - hfem_val.node_r_ele[e, 1]) / hfem_val.length[e],
                                hfem_val.node_r_ele[e, 1],
                                hfem_val.node_r_ele[e, 2],
                                vh_val)
                    
                        _ => 0.0
                    end
            end
        end
    end

    function make_global_matrix_and_vector(hfem_param, hfem_val, vh_val)
        tmp_dv = zeros(hfem_param.NODE_TOTAL)
        tmp_ev = zeros(hfem_param.NODE_TOTAL - 1)

        # 全体行列と全体ベクトルを生成
        for e = 1:hfem_param.ELE_TOTAL
            for i = 1:2
                for j = 1:2
                    if hfem_val.node_num_seg[e, i] == hfem_val.node_num_seg[e, j]
                        tmp_dv[hfem_val.node_num_seg[e, i]] += vh_val.mat_A_ele[e, i, j]
                    elseif hfem_val.node_num_seg[e, i] + 1 == hfem_val.node_num_seg[e, j]
                        tmp_ev[hfem_val.node_num_seg[e, i]] += vh_val.mat_A_ele[e, i, j]
                    end
                end
                
                vh_val.vec_b_glo[hfem_val.node_num_seg[e, i]] += vh_val.vec_b_ele[e, i]
            end
        end

        return tmp_dv, tmp_ev
    end
end