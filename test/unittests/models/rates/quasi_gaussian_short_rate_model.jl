using DiffFusion
using SparseArrays
using Test

@testset "quasi-Gaussian short rate model methods." begin

    chi = DiffFusion.flat_parameter(0.03)
    sigma_f = DiffFusion.flat_volatility(0.01)
    volatility_function = DiffFusion.GaussianShortRateModelFunction()

    @testset "Model setup" begin
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "Std",
            chi,
            sigma_f,
            nothing,
            volatility_function,
        )
        #
        @test DiffFusion.alias(model) == "Std"
        @test DiffFusion.state_alias(model) == ["Std_x_1", "Std_s", "Std_y_1_1"]
        @test DiffFusion.factor_alias(model) == ["Std_f_1"]
        @test DiffFusion.parameter_grid(model) == [0.0]  # due to the constant volatility
    end

    @testset "Theta calculation" begin
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "Std",
            chi,
            sigma_f,
            nothing,
            volatility_function,
        )
        for s in 0.0:5.0
            y0 = DiffFusion.func_y(model.gaussian_model, s)
            X0 = vcat(
                [ 0.0, 1.0],  # x, s
                vec(y0),
            )
            idx_dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(model))
            SX_1 = DiffFusion.model_state(
                reshape(X0, (:,1)),
                idx_dict
            )
            SX_3 = DiffFusion.model_state(
                hcat(X0, X0, X0),
                idx_dict
            )
            #
            Θ = DiffFusion.Theta(model, s, s, SX_1)
            @test isapprox(Θ[1:2], zeros(2), atol=1.0e-16)
            @test isapprox(Θ[3:3], vec(y0), atol=1.0e-16)
            #
            t = s + 1.0
            Θ_Q = DiffFusion.Theta(model, s, t, SX_1)
            Θ_G = DiffFusion.Theta(model.gaussian_model, s, t, nothing)
            y_1 = DiffFusion.func_y(model.gaussian_model, t)
            @test isapprox(Θ_Q[1:2], Θ_G, atol=1.0e-16)
            @test isapprox(Θ_Q[3:3], vec(y_1), atol=1.0e-16)
            # check vectorized calculation
            Θ_v = DiffFusion.Theta_vectorized(model, s, s, SX_3)
            for i in 1:3
                @test isapprox(Θ_v[:,i], Θ, atol=1.0e-16)
            end
            Θ_v_Q = DiffFusion.Theta_vectorized(model, s, t, SX_3)
            for i in 1:3
                @test isapprox(Θ_v_Q[:,i], Θ_Q, atol=1.0e-16)
            end
        end
    end

    @testset "H calculation" begin
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "Std",
            chi,
            sigma_f,
            nothing,
            volatility_function,
        )
        s = 0.5
        t = 2.5
        H_T = DiffFusion.H_T(model, s, t)
        H_T_gaussian = DiffFusion.H_T(model.gaussian_model, s, t)
        @test H_T[1:2, 1:2] == H_T_gaussian
        @test H_T[3:3, 1:2] == spzeros(1, 2)
        @test H_T[1:2, 3:3] == spzeros(2, 1)
        @test H_T[3:3, 3:3] == spzeros(1, 1)
    end

    @testset "Sigma calculation" begin
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "Std",
            chi,
            sigma_f,
            nothing,
            volatility_function,
        )
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(model)), 1),
            model,
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
        for (s, t) in intervalls
            sigmaT_tst = DiffFusion.Sigma_T(model, s, t, SX)
            sigmaT_vec = DiffFusion.Sigma_T_vectorized(model, s, t, SX)
            sigmaT_ref = DiffFusion.Sigma_T(model.gaussian_model, s, t)
            for u in [ s, 0.5*(s+t), t]
                s_tst = sigmaT_tst(u)
                s_vec = sigmaT_vec(u)
                s_ref = sigmaT_ref(u)
                @test s_tst == s_ref
                @test s_vec[:,:,1] == s_ref
            end
        end
    end
end