
using DiffFusion

using Test

@testset "DiagonalModel methods." begin

    ch = DiffFusion.correlation_holder("Std")
    #
    DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", 0.8)
    DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", 0.8)
    DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch, "USD_f_1", "USD_f_2", 0.75)

    sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
    asset_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    delta_dom = DiffFusion.flat_parameter("", [ 1., 7., 15. ])
    chi_dom = DiffFusion.flat_parameter("", [ 0.01, 0.10, 0.30 ])
    times_dom =  [ 0. ]
    values_dom = [ 50. 60. 70. ]' * 1.0e-4
    sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
    hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)

    delta_for = DiffFusion.flat_parameter("", [ 1., 10. ])
    chi_for = DiffFusion.flat_parameter("", [ 0.01, 0.15 ])
    times_for =  [ 0. ]
    values_for = [ 80. 90. ]' * 1.0e-4
    sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
    hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,asset_model)

    delta_nik = DiffFusion.flat_parameter(1.0)
    chi_nik = DiffFusion.flat_parameter(0.05)
    sigma_nik = DiffFusion.flat_volatility("NIK", 0.10)
    mkv_model = DiffFusion.markov_future_model("NIK", delta_nik, chi_nik, sigma_nik, nothing, nothing)

    @testset "Model setup." begin
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, mkv_model ])
        @test DiffFusion.alias(m) == "Std"
        @test DiffFusion.model_alias(m) == ["USD", "EUR-USD", "EUR", "NIK"]
        @test DiffFusion.state_alias(m) == ["USD_x_1", "USD_x_2", "USD_x_3", "USD_s", "EUR-USD_x", "EUR_x_1", "EUR_x_2", "EUR_s", "NIK_x_1"]
        @test DiffFusion.factor_alias(m) == ["USD_f_1", "USD_f_2", "USD_f_3", "EUR-USD_x", "EUR_f_1", "EUR_f_2", "NIK_f_1"]
        @test DiffFusion.state_dependent_Theta(m) == false
        @test DiffFusion.state_alias_H(m) == DiffFusion.state_alias(m)
        @test DiffFusion.state_dependent_H(m) == false
        @test DiffFusion.factor_alias_Sigma(m) == DiffFusion.factor_alias(m)
        @test DiffFusion.state_dependent_Sigma(m) == false        
    end

    @testset "Access model state variables" begin
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, mkv_model ])
        y_d = DiffFusion.func_y(hjm_model_dom, 4.0)
        G_d = DiffFusion.G_hjm(hjm_model_dom, 4.0, 8.0)
        y_f = DiffFusion.func_y(hjm_model_for, 5.0)
        G_f = DiffFusion.G_hjm(hjm_model_for, 5.0, 7.0)
        X = (1:9) * [ 1., 2., 3.]'
        dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        SX = DiffFusion.model_state(X, dict)
        #
        @test DiffFusion.log_asset(m, "EUR-USD", 1.0, SX) == 5 * [ 1., 2., 3. ]
        @test DiffFusion.log_bank_account(m, "USD", 1.0, SX) == 4 * [ 1., 2., 3. ]
        @test DiffFusion.log_bank_account(m, "EUR", 1.0, SX) == 8 * [ 1., 2., 3. ]
        @test DiffFusion.log_zero_bond(m, "USD", 4.0, 8.0, SX) == X[1:3,:]'*G_d .+ 0.5*G_d'*y_d*G_d
        @test DiffFusion.log_zero_bond(m, "EUR", 5.0, 7.0, SX) == X[6:7,:]'*G_f .+ 0.5*G_f'*y_f*G_f
        @test DiffFusion.log_asset_convexity_adjustment(m, "USD", "EUR", "EUR-USD", 5.0, 10.0, 15.0, 20.0) == DiffFusion.log_asset_convexity_adjustment(hjm_model_dom, hjm_model_for, asset_model, 5.0, 10.0, 15.0, 20.0)
        @test DiffFusion.log_future(m, "NIK", 5.0, 10.0, SX) == DiffFusion.log_future(mkv_model, "NIK", 5.0, 10.0, SX)
        #
        yts = DiffFusion.flat_forward(0.01)
        @test DiffFusion.swap_rate_variance(m, "EUR", yts, 1.0, 8.0, [8.0, 9.0, 10.0], [1.0, 1.0], SX) == DiffFusion.swap_rate_variance(hjm_model_for, "EUR", yts, 1.0, 8.0, [8.0, 9.0, 10.0], [1.0, 1.0], SX)
        @test DiffFusion.forward_rate_variance(m, "USD", 1.0, 8.0, 8.0, 9.0) == DiffFusion.forward_rate_variance(hjm_model_dom, "USD", 1.0, 8.0, 8.0, 9.0)
        @test DiffFusion.asset_variance(m, "EUR-USD", "USD", "EUR", 1.0, 8.0, SX) == DiffFusion.asset_variance(asset_model, hjm_model_dom, hjm_model_for, ch, 1.0, 8.0)

        @test DiffFusion.asset_variance(m, "EUR-USD", "USD", "EUR", 1.0, 8.0, SX) == DiffFusion.asset_variance(asset_model, hjm_model_dom, hjm_model_for, ch, 1.0, 8.0)
        @test DiffFusion.asset_variance(m, "EUR-USD", nothing, "EUR", 1.0, 8.0, SX) == DiffFusion.asset_variance(asset_model, nothing, hjm_model_for, ch, 1.0, 8.0)
        @test DiffFusion.asset_variance(m, "EUR-USD", "USD", nothing, 1.0, 8.0, SX) == DiffFusion.asset_variance(asset_model, hjm_model_dom, nothing, ch, 1.0, 8.0)
        @test DiffFusion.asset_variance(m, "EUR-USD", nothing, nothing, 1.0, 8.0, SX) == DiffFusion.asset_variance(asset_model, nothing, nothing, ch, 1.0, 8.0)
        @test DiffFusion.asset_variance(m, nothing, "USD", "EUR", 1.0, 8.0, SX) == DiffFusion.asset_variance(nothing, hjm_model_dom, hjm_model_for, ch, 1.0, 8.0)
        @test DiffFusion.asset_variance(m, nothing, nothing, nothing, 1.0, 8.0, SX) == 0.0
        #
        @test_throws KeyError DiffFusion.log_asset(m, "WrongAlias", 1.0, SX)
        @test_throws KeyError DiffFusion.log_bank_account(m, "WrongAlias", 1.0, SX)
        @test_throws KeyError DiffFusion.log_zero_bond(m, "WrongAlias", 4.0, 8.0, SX)
        @test_throws KeyError DiffFusion.log_future(m, "WrongAlias", 4.0, 8.0, SX)
    end

    @testset "Model functions." begin
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, mkv_model ])
        s = 1.0
        t = 3.0
        params = DiffFusion.simulation_parameters(m, nothing, s, t)
        # display(params)
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            params,
            )
        theta0 = DiffFusion.Theta(m, s, t, SX)
        @test size(theta0) == (9,)
        @test theta0[1:4] == DiffFusion.Theta(hjm_model_dom, s, t)
        @test theta0[5:5] == DiffFusion.Theta(asset_model, s, t)
        @test theta0[6:8] == DiffFusion.Theta(hjm_model_for, s, t)
        @test theta0[9:9] == DiffFusion.Theta(mkv_model, s, t)
        #
        H0 = DiffFusion.H_T(m, s, t)
        @test H0[1:4,1:4] == DiffFusion.H_T(hjm_model_dom, s, t)
        @test H0[5:5,5:5] == DiffFusion.H_T(asset_model, s, t)
        @test H0[6:8,6:8] == DiffFusion.H_T(hjm_model_for, s, t)
        @test H0[9:9,9:9] == DiffFusion.H_T(mkv_model, s, t)
        #
        Sigma0T = DiffFusion.Sigma_T(m, s, t, SX)(0.5*(s+t))
        @test Sigma0T[1:4,1:3] == DiffFusion.Sigma_T(hjm_model_dom,s,t)(0.5*(s+t))
        @test Sigma0T[5:5,4:4] == DiffFusion.Sigma_T(asset_model,s,t)(0.5*(s+t))
        @test Sigma0T[6:8,5:6] == DiffFusion.Sigma_T(hjm_model_for,s,t)(0.5*(s+t))
        @test Sigma0T[9:9,7:7] == DiffFusion.Sigma_T(mkv_model,s,t)(0.5*(s+t))
        # check Quanto impact
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR_f_1", -0.30)
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR_f_2", -0.30)
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR_f_3", -0.30)
        #
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD_f_1", -0.20)
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD_f_2", -0.20)
        #
        DiffFusion.set_correlation!(ch, "USD_f_1", "EUR_f_1", 0.50)
        DiffFusion.set_correlation!(ch, "USD_f_2", "EUR_f_2", 0.50)
        #
        theta1 = DiffFusion.Theta(m, s, t, SX)  # use 'old' params with 'old' Theta
        @test theta1 == theta0
        #
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, nothing, s, t),
            )
        theta1 = DiffFusion.Theta(m, s, t, SX)  # use new params calculated with updated correlations.
        @test theta1[1:5] == theta0[1:5]
        @test theta1[6:8] > theta0[6:8]  # negative correlation yields positive quanto adjustment
        #
        H1 = DiffFusion.H_T(m, s, t)
        @test H1 == H0
        #
        Sigma1T = DiffFusion.Sigma_T(m, s, t, SX)(0.5*(s+t))
        @test Sigma1T == Sigma0T        
    end


    @testset "Model functions with CIR model." begin
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        cir_model_1 = DiffFusion.cox_ingersoll_ross_model("CRD1", z0, chi, theta, sigma)
        cir_model_2 = DiffFusion.cox_ingersoll_ross_model("CRD2", z0 + 0.01, chi, theta + 0.01, sigma)
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, cir_model_1, cir_model_2, mkv_model ])
        s = 1.0
        t = 3.0
        params = DiffFusion.simulation_parameters(m, nothing, s, t)
        # display(params)
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            params,
            )
        theta0 = DiffFusion.Theta(m, s, t, SX)
        @test size(theta0) == (11,)
        @test theta0[1:4] == DiffFusion.Theta(hjm_model_dom, s, t)
        @test theta0[5:5] == DiffFusion.Theta(asset_model, s, t)
        @test theta0[6:8] == DiffFusion.Theta(hjm_model_for, s, t)
        @test theta0[9:9] == DiffFusion.Theta(cir_model_1, s, t, DiffFusion.model_state(SX.X, SX.idx, DiffFusion.simulation_parameters(cir_model_1, nothing, s, t)))
        @test theta0[10:10] == DiffFusion.Theta(cir_model_2, s, t, DiffFusion.model_state(SX.X, SX.idx, DiffFusion.simulation_parameters(cir_model_2, nothing, s, t)))
        @test theta0[11:11] == DiffFusion.Theta(mkv_model, s, t)
        #
        H0 = DiffFusion.H_T(m, s, t)
        @test H0[1:4,1:4] == DiffFusion.H_T(hjm_model_dom, s, t)
        @test H0[5:5,5:5] == DiffFusion.H_T(asset_model, s, t)
        @test H0[6:8,6:8] == DiffFusion.H_T(hjm_model_for, s, t)
        @test H0[9:9,9:9] == zeros(1,1)
        @test H0[10:10,10:10] == zeros(1,1)
        @test H0[11:11,11:11] == DiffFusion.H_T(mkv_model, s, t)
        #
        Sigma0T = DiffFusion.Sigma_T(m, s, t, SX)(0.5*(s+t))
        @test Sigma0T[1:4,1:3] == DiffFusion.Sigma_T(hjm_model_dom,s,t)(0.5*(s+t))
        @test Sigma0T[5:5,4:4] == DiffFusion.Sigma_T(asset_model,s,t)(0.5*(s+t))
        @test Sigma0T[6:8,5:6] == DiffFusion.Sigma_T(hjm_model_for,s,t)(0.5*(s+t))
        @test Sigma0T[9:9,7:7] == DiffFusion.Sigma_T(cir_model_1,s,t,DiffFusion.model_state(SX.X, SX.idx, DiffFusion.simulation_parameters(cir_model_1, nothing, s, t)))(0.5*(s+t))
        @test Sigma0T[10:10,8:8] == DiffFusion.Sigma_T(cir_model_2,s,t,DiffFusion.model_state(SX.X, SX.idx, DiffFusion.simulation_parameters(cir_model_2, nothing, s, t)))(0.5*(s+t))
        @test Sigma0T[11:11,9:9] == DiffFusion.Sigma_T(mkv_model,s,t)(0.5*(s+t))
    end

    @testset "State-independent correlation." begin
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        cir_model_1 = DiffFusion.cox_ingersoll_ross_model("CRD1", z0, chi, theta, sigma)
        cir_model_2 = DiffFusion.cox_ingersoll_ross_model("CRD2", z0 + 0.01, chi, theta + 0.01, sigma)
        cir_model_3 = DiffFusion.cox_ingersoll_ross_model("CRD3", z0 + 0.02, chi, theta + 0.02, sigma)
        m = DiffFusion.diagonal_model("Std", [ cir_model_1, cir_model_2, cir_model_3 ])
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD2_x", 0.30)
        DiffFusion.set_correlation!(ch, "CRD2_x", "CRD3_x", 0.40)
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD3_x", 0.50)
        #
        s = 1.0
        t = 3.0
        SX1 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        SX2 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1) .- 0.01,
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        SX3 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1) .+ 0.01,
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        (V1, C1) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX1)
        (V2, C2) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX2)
        (V3, C3) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX3)
        @test V1 < V2
        @test V1 > V3
        C = [
            1.0 0.3 0.5
            0.3 1.0 0.4
            0.5 0.4 1.0
        ]
        @test isapprox(C1, C, atol=5.0e-16)
        @test isapprox(C2, C, atol=5.0e-16)
        @test isapprox(C3, C, atol=5.0e-16)
        #
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, cir_model_1, cir_model_2, cir_model_3 ])
        SX1 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        SX2 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1) .- 0.01,
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        SX3 = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1) .+ 0.01,
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            DiffFusion.simulation_parameters(m, ch, s, t),
        )
        (V1, C1) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX1)
        (V2, C2) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX2)
        (V3, C3) = DiffFusion.volatility_and_correlation(m, ch, s, t, SX3)
        @test V1[1:8] == V2[1:8]
        @test V1[1:8] == V3[1:8]
        @test V1[9:11] < V2[9:11]
        @test V1[9:11] > V3[9:11]
        @test isapprox(C1, C2, atol=5.0e-16)
        @test isapprox(C2, C3, atol=5.0e-16)
        #display(C1)
        #display(C2)
        #display(C3)
    end

    @testset "Model functions with CEV model." begin        
        asset_model = DiffFusion.cev_asset_model("EUR-USD", sigma_fx, DiffFusion.flat_parameter(-0.25) , ch, nothing)
        hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,asset_model)
        m = DiffFusion.diagonal_model("Std", [ hjm_model_dom, asset_model, hjm_model_for, mkv_model ])
        s = 1.0
        t = 3.0
        params = DiffFusion.simulation_parameters(m, nothing, s, t)
        # display(params)
        SX = DiffFusion.model_state(
            zeros(length(DiffFusion.state_alias(m)),1),
            DiffFusion.alias_dictionary(DiffFusion.state_alias(m)),
            params,
            )
        theta0 = DiffFusion.Theta(m, s, t, SX)
        @test size(theta0) == (9,)
        @test theta0[1:4] == DiffFusion.Theta(hjm_model_dom, s, t)
        @test theta0[5:5] == DiffFusion.Theta(asset_model, s, t, SX)
        @test theta0[6:8] == DiffFusion.Theta(hjm_model_for, s, t, SX)
        @test theta0[9:9] == DiffFusion.Theta(mkv_model, s, t)
        #
        H0 = DiffFusion.H_T(m, s, t)
        @test H0[1:4,1:4] == DiffFusion.H_T(hjm_model_dom, s, t)
        @test H0[5:5,5:5] == DiffFusion.H_T(asset_model, s, t)
        @test H0[6:8,6:8] == DiffFusion.H_T(hjm_model_for, s, t)
        @test H0[9:9,9:9] == DiffFusion.H_T(mkv_model, s, t)
        #
        Sigma0T = DiffFusion.Sigma_T(m, s, t, SX)(0.5*(s+t))
        @test Sigma0T[1:4,1:3] == DiffFusion.Sigma_T(hjm_model_dom,s,t)(0.5*(s+t))
        @test Sigma0T[5:5,4:4] == DiffFusion.Sigma_T(asset_model,s,t, SX)(0.5*(s+t))
        @test Sigma0T[6:8,5:6] == DiffFusion.Sigma_T(hjm_model_for,s,t)(0.5*(s+t))
        @test Sigma0T[9:9,7:7] == DiffFusion.Sigma_T(mkv_model,s,t)(0.5*(s+t))
    end

    @testset "Model setup with quasi-Gaussian model" begin
        times = hjm_model_dom.sigma_T.sigma_f.times
        slope_d = DiffFusion.backward_flat_parameter("Std", times, zeros(3, length(times)))
        slope_u = DiffFusion.backward_flat_parameter("Std", times, zeros(3, length(times)))
        sigma_min = 1.0e-4
        sigma_max = 5.0e-2
        #
        volatility_model = DiffFusion.ornstein_uhlenbeck_model(
            "OU",
            DiffFusion.flat_parameter("Std", 0.10),  # chi
            DiffFusion.flat_volatility("Std", 0.20),  # sigma_x
        )
        volatility_function = exp
        #
        quasi_gaussian_model = DiffFusion.quasi_gaussian_model(
            hjm_model_dom, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        m = DiffFusion.diagonal_model(
            "Std",
            [ quasi_gaussian_model, volatility_model ],
        )
        #
        @test DiffFusion.state_alias_Sigma(m) == ["USD_x_1", "USD_x_2", "USD_x_3", "USD_s", "OU_x"]
        #
        idx_list = DiffFusion.alias_mapping(
            DiffFusion.state_alias(m),
            DiffFusion.state_alias_Sigma(m)
        )
        @test idx_list == [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 5]
        #
        m = DiffFusion.diagonal_model(
            "Std",
            [ volatility_model, quasi_gaussian_model ],
        )
        #
        @test DiffFusion.state_alias_Sigma(m) == ["OU_x", "USD_x_1", "USD_x_2", "USD_x_3", "USD_s"]
        #
        idx_list = DiffFusion.alias_mapping(
            DiffFusion.state_alias(m),
            DiffFusion.state_alias_Sigma(m)
        )
        @test idx_list == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    end

end
