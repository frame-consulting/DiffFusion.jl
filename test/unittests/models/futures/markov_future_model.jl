
using DiffFusion
using LinearAlgebra
using Test

@testset "Markov Future model methods." begin

    delta = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter("Std", [ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.]
    sigma_F = DiffFusion.backward_flat_volatility("Std",times,values)

    @testset "Model setup." begin
        m = DiffFusion.markov_future_model("Std",delta,chi,sigma_F,nothing,nothing)
        @test DiffFusion.alias(m) == "Std"
        @test DiffFusion.state_alias(m)  == [ "Std_x_1", "Std_x_2", "Std_x_3", ]
        @test DiffFusion.factor_alias(m) == [ "Std_f_1", "Std_f_2", "Std_f_3", ]
        #
        HHfInv = DiffFusion.benchmark_times_scaling(chi(),delta())
        @test m.hjm_model.sigma_T(1.5) == HHfInv * Diagonal([60., 70., 80.])
        @test m.hjm_model.sigma_T(5.0) == HHfInv * Diagonal([70., 80., 90.])
        @test m.hjm_model.sigma_T(12.0) == HHfInv * Diagonal([80., 90., 90.])
        #
        m = DiffFusion.markov_future_model("Std",delta,chi,sigma_F,nothing,nothing,DiffFusion.ZeroRateScaling)
        A_inv = DiffFusion.benchmark_times_scaling(chi(), delta(), DiffFusion.ZeroRateScaling)
        @test m.hjm_model.sigma_T(1.5) == A_inv * Diagonal([60., 70., 80.])
        @test m.hjm_model.sigma_T(5.0) == A_inv * Diagonal([70., 80., 90.])
        @test m.hjm_model.sigma_T(12.0) == A_inv * Diagonal([80., 90., 90.])
        #
        m = DiffFusion.markov_future_model("Std",delta,chi,sigma_F,nothing,nothing,DiffFusion.DiagonalScaling)
        @test m.hjm_model.sigma_T(1.5) == Diagonal([60., 70., 80.])
        @test m.hjm_model.sigma_T(5.0) == Diagonal([70., 80., 90.])
        @test m.hjm_model.sigma_T(12.0) == Diagonal([80., 90., 90.])
        #
        @test_throws AssertionError DiffFusion.markov_future_model("Std", DiffFusion.flat_parameter("", delta()[2:end]), chi, sigma_F, nothing, nothing)
        @test_throws AssertionError DiffFusion.markov_future_model("Std", delta, DiffFusion.flat_parameter("", chi()[2:end]), sigma_F, nothing, nothing)
        @test_throws AssertionError DiffFusion.markov_future_model("Std", DiffFusion.flat_parameter("", reverse(delta())), chi, sigma_F, nothing, nothing)
        @test_throws AssertionError DiffFusion.markov_future_model("Std", delta, DiffFusion.flat_parameter("", reverse(chi())), sigma_F, nothing, nothing)
    end

    @testset "Model Correlation." begin
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)
        m_wo_corr = DiffFusion.markov_future_model("Std",delta,chi,sigma_F, nothing, nothing)  
        m_w_corr = DiffFusion.markov_future_model("Std",delta,chi,sigma_F, ch, nothing)
        S1 = m_wo_corr.hjm_model.sigma_T(1.5)
        S2 = m_w_corr.hjm_model.sigma_T(1.5)
        G = [ 1.0 0.8 0.5;
              0.8 1.0 0.8;
              0.5 0.8 1.0]
        L = cholesky(G).L
        @test isapprox(S1 * L, S2, atol=1.0e-12)
    end

    @testset "Theta calculation." begin
        m = DiffFusion.markov_future_model("Theta_3F",delta,chi,sigma_F,nothing,nothing)
        @test_nowarn DiffFusion.Theta(m, 0.0, 1.0)
        @test_nowarn DiffFusion.Theta(m, 1.0, 2.0)
        @test_nowarn DiffFusion.Theta(m, 2.0, 3.5)
        @test_nowarn DiffFusion.Theta(m, 2.0, 5.0)
        @test_nowarn DiffFusion.Theta(m, 5.0, 10.0)
        @test_nowarn DiffFusion.Theta(m, 1.0, 15.0)
        # test against manual calculation model
        theta_times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        theta_model = [ DiffFusion.Theta(m, s, t) for (s,t) in theta_times ]
        # display(theta_model)
        y(u) = DiffFusion.func_y(m.hjm_model, u)
        σT(u) = m.hjm_model.sigma_T(u)
        χ = m.hjm_model.chi()
        for ((s, t), Θ) in zip(theta_times, theta_model)
            f(u) = DiffFusion.H_hjm(m.hjm_model,u,t).*(y(u)*χ - vec(sum(σT(u) * σT(u)', dims=2)))
            Θ_ref = 0.5 * DiffFusion._vector_integral(f, s, t)
            @test isapprox(Θ, Θ_ref, rtol=1.0e-8)
        end
    end

    @testset "H calculation." begin
        m = DiffFusion.markov_future_model("Theta_3F",delta,chi,sigma_F,nothing,nothing)
        H = DiffFusion.H_T(m, 0.5, 2.5)
        @test size(H) == (3, 3)
        times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        mkv_model = [ DiffFusion.H_T(m, s, t) for (s,t) in times ]
        hjm_model = [ DiffFusion.H_T(m.hjm_model, s, t) for (s,t) in times ]
        for (H_mkv, H_hjm) in zip(mkv_model, hjm_model)
            @test H_mkv == H_hjm[1:3, 1:3]
        end
    end

    @testset "Sigma calculation." begin
        m = DiffFusion.markov_future_model("Theta_3F",delta,chi,sigma_F,nothing,nothing)
        Σ = DiffFusion.Sigma_T(m, 0.5, 2.5)(1.0)
        @test size(Σ) == (3, 3)
        times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        mkv_model = [ DiffFusion.Sigma_T(m, s, t)(0.5*(s+t)) for (s,t) in times ]
        hjm_model = [ DiffFusion.Sigma_T(m.hjm_model, s, t)(0.5*(s+t)) for (s,t) in times ]
        for (Σ_mkv, Σ_hjm) in zip(mkv_model, hjm_model)
            @test isapprox(Σ_mkv, Σ_hjm[1:3, 1:3], atol=1.0e-13)
            # display(Σ_mkv - Σ_hjm[1:3, 1:3])
        end
    end

    @testset "Model functions" begin
        m = DiffFusion.markov_future_model("NIK", delta, chi, sigma_F, nothing, nothing)
        y = DiffFusion.func_y(m.hjm_model, 4.0)
        h = DiffFusion.H_hjm(m, 4.0, 8.0)
        X = [ 1., 2., 3. ] * [ 1., 2., 3., 4.]'
        dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        SX = DiffFusion.model_state(X, dict)
        @test_throws AssertionError DiffFusion.log_future(m, "WrongAlias", 4.0, 8.0, SX)
        #
        X = [ 0., 0., 1., 2., 3., 0. ] * [ 1., 2., 3., 4. ]'
        s_alias = [ "1", "2", "NIK_x_1", "NIK_x_2", "NIK_x_3", "6" ]
        dict = DiffFusion.alias_dictionary(s_alias)
        SX = DiffFusion.model_state(X, dict)
        @test DiffFusion.log_future(m, "NIK", 4.0, 8.0, SX) == (X[3:5,:] .+ 0.5*y*(1.0 .- h))' * h
        #
        s_alias = [ "1", "2", "NIK_x_0", "NIK_x_2", "NIK_x_3", "6" ]
        dict = DiffFusion.alias_dictionary(s_alias)
        SX = DiffFusion.model_state(X, dict)
        @test_throws KeyError DiffFusion.log_future(m, "NIK", 4.0, 8.0, SX)
    end

end
