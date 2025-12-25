using DiffFusion
using Printf
using SparseArrays
using Test

@testset "Gaussian HJM model methods." begin

    delta = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter("Std", [ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.] * 1.0e-4
    sigma_f = DiffFusion.backward_flat_volatility("Std",times,values)
    #
    ch = DiffFusion.correlation_holder("Std")
    DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
    DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
    DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)
    #
    quanto_model = nothing
    #
    slope_d_vals = [
        10. 10. 10. 10.;
        10. 10. 10. 10.;
        10. 10. 10. 10.
    ] * 1.0e-2 * (-1.0)
    slope_d = DiffFusion.backward_flat_parameter(
        "Std", times, slope_d_vals
    )
    #
    slope_u_vals = [
        15. 15. 15. 15.;
        15. 15. 15. 15.;
        15. 15. 15. 15.
    ] * 1.0e-2
    slope_u = DiffFusion.backward_flat_parameter(
        "Std", times, slope_u_vals
    )
    #
    sigma_min = 1.0e-4
    sigma_max = 500. * 1.0e-4
    #
    volatility_model = DiffFusion.ornstein_uhlenbeck_model(
        "OU",
        DiffFusion.flat_parameter("Std", 0.10),  # chi
        DiffFusion.flat_volatility("Std", 0.20),  # sigma_x
    )
    volatility_function = exp


    @testset "Model setup." begin
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m1 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        m2 = DiffFusion.quasi_gaussian_model(
            "Std", delta, chi, sigma_f,
            slope_d, slope_u, sigma_min, sigma_max,
            ch, quanto_model, DiffFusion.ForwardRateScaling,
            volatility_model, volatility_function,
        )
        #
        @test string(m1) == string(m2)
        #
        m1 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        #
        m2 = DiffFusion.quasi_gaussian_model(
            "Std", delta, chi, sigma_f,
            slope_d, slope_u, sigma_min, sigma_max,
            ch, quanto_model, DiffFusion.ForwardRateScaling,
            nothing, nothing,
        )
        #
        @test string(m1) == string(m2)
        #
        @test DiffFusion.alias(m1) == "Std"
        @test DiffFusion.alias(m1) == DiffFusion.alias(gaussian_model)
        #
        @test DiffFusion.state_alias(m1) == [
            "Std_x_1", "Std_x_2", "Std_x_3", "Std_s",
            "Std_y_1_1", "Std_y_2_1", "Std_y_3_1",
            "Std_y_1_2", "Std_y_2_2", "Std_y_3_2",
            "Std_y_1_3", "Std_y_2_3", "Std_y_3_3"
        ]
        @test DiffFusion.factor_alias(m1) == [ "Std_f_1", "Std_f_2", "Std_f_3" ]
        #
        slope_24 = DiffFusion.backward_flat_parameter("", times, rand(2,4))
        slope_35 = DiffFusion.backward_flat_parameter("", vcat(times, 15.0), rand(3,5))
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_24, slope_u, sigma_min, sigma_max, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_35, slope_u, sigma_min, sigma_max, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_24, sigma_min, sigma_max, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_35, sigma_min, sigma_max, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_u, 0.0, sigma_max, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_u, sigma_max, sigma_min, nothing, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_u, sigma_min, sigma_max, volatility_model, nothing)
        )
        @test_throws AssertionError DiffFusion.gaussian_hjm_model(
            "Std", DiffFusion.quasi_gaussian_model(gaussian_model, slope_d, slope_u, sigma_min, sigma_max, nothing, volatility_function)
        )
        #
        @test DiffFusion.parameter_grid(m1)        == times
        @test DiffFusion.state_dependent_Theta(m1) == true
        @test DiffFusion.state_dependent_H(m1)     == false
        @test DiffFusion.state_dependent_Sigma(m1) == true
        @test DiffFusion.state_alias_H(m1) == [
            "Std_x_1", "Std_x_2", "Std_x_3", "Std_s",
            "Std_y_1_1", "Std_y_2_1", "Std_y_3_1",
            "Std_y_1_2", "Std_y_2_2", "Std_y_3_2",
            "Std_y_1_3", "Std_y_2_3", "Std_y_3_3"
        ]
        @test DiffFusion.factor_alias_Sigma(m1) == [ "Std_f_1", "Std_f_2", "Std_f_3" ]
    end

    @testset "Modelled variables" begin
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        X = collect(1:length(DiffFusion.state_alias(m))) .* ones(1, 5)
        SX = DiffFusion.model_state(X, m)
        #
        @test DiffFusion.state_variable(m, SX) == [1, 2, 3] .* ones(1, 5)
        @test DiffFusion.integrated_state_variable(m, SX) == [ 4 ] .* ones(1, 5)
        Y = DiffFusion.auxiliary_variable(m, SX)
        Y_ref = [ 5 8 11; 6 9 12; 7 10 13 ]
        for p in 1:5
            Y_ = Y[:,:,p]
            @test Y_ == Y_ref
        end

    end


    @testset "Volatility specification" begin
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        idx = DiffFusion.alias_dictionary([ "Std_x_1", "Std_x_2", "Std_x_3", "OU_x", ])
        X = [
            0.0 -1.0  1.0 -1.0  1.0;
            0.0 -1.0  1.0  1.0 -1.0;
            0.0 -1.0  1.0 -1.0  1.0;
            0.0 -1.0  1.0  0.5  0.0
        ] .* 1.0e-2
        SX = DiffFusion.model_state(X, idx)
        #
        vol_mdl = DiffFusion.func_sigma_f(m, 3.0, 3.0, SX)
        #
        smile_ref = [
            0. -10. 15. -10.  15.;
            0. -10. 15.  15. -10.;
            0. -10. 15. -10.  15.
        ] * 1.0e-4
        #
        vol_ref = exp.([0.0 -1.0  1.0  0.5  0.0] .* 1.0e-2 ) .*
            ([ 70., 80., 90.] .* 1.0e-4 .+ smile_ref
            )
        #
        @test vol_mdl == vol_ref
        #
        # local vol model
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        vol_mdl = DiffFusion.func_sigma_f(m, 3.0, 3.0, SX)
        #
        vol_ref =[ 70., 80., 90.] .* 1.0e-4 .+ smile_ref
        #
        @test vol_mdl == vol_ref
        #
        # boundaries
        #
        SX = DiffFusion.model_state(X * 1.0e+2, idx)
        vol_mdl = DiffFusion.func_sigma_f(m, 3.0, 3.0, SX)
        vol_ref = [
            70. 1. 500.   1. 500.;
            80. 1. 500. 500.   1.;
            90. 1. 500.   1. 500.
        ] * 1.0e-4
        #
        @test vol_mdl == vol_ref
    end


    @testset "Theta calculation" begin
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        #
        for s in 0.0:5.0
            y0 = DiffFusion.func_y(gaussian_model, s)
            X0 = vcat(
                [ 0.0, 0.0, 0.0, 1.0],  # x, s
                vec(y0),
                [ 0.0 ],  # ν
            )
            idx_dict = DiffFusion.alias_dictionary(
                vcat(DiffFusion.state_alias(m), DiffFusion.state_alias(volatility_model))
            )
            SX = DiffFusion.model_state(
                reshape(X0, (:,1)),
                idx_dict
            )
            #
            Θ = DiffFusion.Theta(m, s, s, SX)
            @test isapprox(Θ[1:4], zeros(4), atol=1.0e-16)
            @test isapprox(Θ[5:13], vec(y0), atol=1.0e-16)
            #
            t = s + 1.0
            Θ_Q = DiffFusion.Theta(m, s, t, SX)
            Θ_G = DiffFusion.Theta(m.gaussian_model, s, t, nothing)
            y_1 = DiffFusion.func_y(gaussian_model, t)
            @test isapprox(Θ_Q[1:4], Θ_G, atol=1.0e-16)
            @test isapprox(Θ_Q[5:13], vec(y_1), atol=1.0e-16)
        end
    end


    @testset "H calculation" begin
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        s = 0.5
        t = 2.5
        H_T = DiffFusion.H_T(m, s, t)
        H_T_gaussian = DiffFusion.H_T(gaussian_model, s, t)
        @test H_T[1:4, 1:4] == H_T_gaussian
        @test H_T[5:13, 1:4] == spzeros(9, 4)
        @test H_T[1:4, 5:13] == spzeros(4, 9)
        @test H_T[5:13, 5:13] == spzeros(9, 9)
    end


    @testset "Sigma calculation" begin
        #
        gaussian_model = DiffFusion.gaussian_hjm_model(
            "Std", delta, chi, sigma_f, ch, quanto_model,
        )
        #
        m = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        #
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)), 1),
            m,
        )
        #
        intervalls = [
            (0.0, 0.5),
            (0.5, 1.0),
            (1.0, 2.0),
            (2.0, 3.0),
            (3.0, 4.0),
            (4.0, 5.0),
            (5.0, 12.0),
        ]
        ϵ = sqrt(eps())
        for (s, t) in intervalls
            sigmaT_tst = DiffFusion.Sigma_T(m, s, t, SX)
            sigmaT_ref = DiffFusion.Sigma_T(m.gaussian_model, s, t)
            for u in [ s + ϵ, 0.5*(s+t), t]
                s_tst = sigmaT_tst(u)
                s_ref = sigmaT_ref(u)
                @test s_tst == s_ref
            end
        end

    end
end
