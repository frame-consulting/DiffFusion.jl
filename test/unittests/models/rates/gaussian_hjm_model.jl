using DiffFusion
using Test

using LinearAlgebra


@testset "Gaussian HJM model methods." begin

    delta = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter("Std", [ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.]
    sigma_f = DiffFusion.backward_flat_volatility("Std",times,values)

    @testset "Model setup." begin
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,nothing,nothing)
        @test DiffFusion.alias(m) == "Std"
        @test DiffFusion.state_alias(m) == [ "Std_x_1", "Std_x_2", "Std_x_3", "Std_s" ]
        @test DiffFusion.factor_alias(m) == [ "Std_f_1", "Std_f_2", "Std_f_3" ]
        HHfInv = DiffFusion.benchmark_times_scaling(chi(),delta())
        @test m.sigma_T(1.5) == HHfInv * Diagonal([60., 70., 80.])
        @test m.sigma_T(5.0) == HHfInv * Diagonal([70., 80., 90.])
        @test m.sigma_T(12.0) == HHfInv * Diagonal([80., 90., 90.])
        @test DiffFusion.correlation_holder(m) == nothing
        #
        @test_throws AssertionError DiffFusion.gaussian_hjm_model("Std", DiffFusion.flat_parameter("", delta()[2:end]), chi, sigma_f, nothing, nothing)
        @test_throws AssertionError DiffFusion.gaussian_hjm_model("Std", delta, DiffFusion.flat_parameter("", chi()[2:end]), sigma_f, nothing, nothing)
        @test_throws AssertionError DiffFusion.gaussian_hjm_model("Std", DiffFusion.flat_parameter("", reverse(delta())), chi, sigma_f, nothing, nothing)
        @test_throws AssertionError DiffFusion.gaussian_hjm_model("Std", delta, DiffFusion.flat_parameter("", reverse(chi())), sigma_f, nothing, nothing)
    end

    @testset "Variance calculation." begin
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,nothing,nothing)
        HHfInv = DiffFusion.benchmark_times_scaling(chi(),delta())
        ref_times = [ 0.0, 0.5, 1.0, 1.5, 2.0, 3.0 ]
        y = [ DiffFusion.func_y(m,t) for t in ref_times ]
        #
        @test y[3] == m.y[:,:,1]
        @test y[5] == m.y[:,:,2]
        #
        y_ref = zeros(3,3,6)
        y_ref[:,:,2] = DiffFusion.func_y(y_ref[:,:,1], chi(), HHfInv * Diagonal([50., 60., 70.]), 0.0, 0.5)
        y_ref[:,:,3] = DiffFusion.func_y(y_ref[:,:,2], chi(), HHfInv * Diagonal([50., 60., 70.]), 0.5, 1.0)
        y_ref[:,:,4] = DiffFusion.func_y(y_ref[:,:,3], chi(), HHfInv * Diagonal([60., 70., 80.]), 1.0, 1.5)
        y_ref[:,:,5] = DiffFusion.func_y(y_ref[:,:,4], chi(), HHfInv * Diagonal([60., 70., 80.]), 1.5, 2.0)
        y_ref[:,:,6] = DiffFusion.func_y(y_ref[:,:,5], chi(), HHfInv * Diagonal([70., 80., 90.]), 2.0, 3.0)
        @test y[1] == y_ref[:,:,1]
        @test y[2] == y_ref[:,:,2]
        @test isapprox(y[3], y_ref[:,:,3], atol=4.0e-10)
        @test isapprox(y[4], y_ref[:,:,4], atol=4.0e-10)
        @test isapprox(y[5], y_ref[:,:,5], atol=9.0e-10)
        @test isapprox(y[6], y_ref[:,:,6], atol=9.0e-10)
        # test against Hull White model
        sigma_f_1 = DiffFusion.backward_flat_volatility("1F", times, values[1,:])
        m = DiffFusion.gaussian_hjm_model("1F", DiffFusion.flat_parameter("Std", [ 0.0 ]), DiffFusion.flat_parameter("Std", [ 0.10]), sigma_f_1, nothing, nothing)
        y_HW = [ 2265.86558653,  5117.98028263, 13862.9220481 , 25327.74189857]
        @test isapprox(m.y[1,1,1], y_HW[1], atol=4.8e-9)
        @test isapprox(m.y[1,1,2], y_HW[2], atol=4.4e-9)
        @test isapprox(m.y[1,1,3], y_HW[3], atol=1.1e-9)
        @test isapprox(m.y[1,1,4], y_HW[4], atol=2.6e-9)
        ref_times = [ 0.5, 1.5, 3.0, 8.0, 12.0 ]
        y = [ DiffFusion.func_y(m, t) for t in ref_times ]
        y_HW = [
            1189.532274550506,
            3763.1664422807503,
            8631.344400621772,
            22046.16057525346,
            27527.451642289474
        ]
        @test y[1][1,1] == y_HW[1]
        @test y[2][1,1] == y_HW[2]
        @test y[3][1,1] == y_HW[3]
        @test y[4][1,1] == y_HW[4]
        @test y[5][1,1] == y_HW[5]
    end

    @testset "Theta calculation." begin
        m = DiffFusion.gaussian_hjm_model("Theta_3F",delta,chi,sigma_f,nothing,nothing)
        @test_nowarn DiffFusion.Theta(m, 0.0, 1.0)
        @test_nowarn DiffFusion.Theta(m, 1.0, 2.0)
        @test_nowarn DiffFusion.Theta(m, 2.0, 3.5)
        @test_nowarn DiffFusion.Theta(m, 2.0, 5.0)
        @test_nowarn DiffFusion.Theta(m, 5.0, 10.0)
        @test_nowarn DiffFusion.Theta(m, 1.0, 15.0)
        # test against Hull White model
        sigma_f_1 = DiffFusion.backward_flat_volatility("1F", times, values[1,:])
        m = DiffFusion.gaussian_hjm_model("1F", DiffFusion.flat_parameter("Std", [ 0.0 ]), DiffFusion.flat_parameter("Std", [ 0.10]), sigma_f_1, nothing, nothing)
        theta_times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        theta_model = [ DiffFusion.Theta(m, s, t) for (s,t) in theta_times ]
        theta_ref = [
            [1131.9896257578391, 386.82441616027126 ],
            [3581.1263500786827, 1583.0016941940937 ],
            [72681.77203540465, 144326.01020771352  ],
            [14633.12718965099, 16073.009843178781  ],
            [134966.70600636245, 613300.5614684084  ]
        ]
        @test isapprox(theta_model[1], theta_ref[1], atol=1.5e-13 )
        @test isapprox(theta_model[2], theta_ref[2], atol=7.0e-13 )
        @test isapprox(theta_model[3], theta_ref[3], atol=3.0e-11 )
        @test isapprox(theta_model[4], theta_ref[4], rtol=7.5e-9  )
        @test isapprox(theta_model[5], theta_ref[5], rtol=2.0e-9  )
    end

    @testset "Model Correlation." begin
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)
        m_wo_corr = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f, nothing, nothing)  
        m_w_corr = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f, ch, nothing)
        @test DiffFusion.correlation_holder(m_w_corr) == ch
        S1 = m_wo_corr.sigma_T(1.5)
        S2 = m_w_corr.sigma_T(1.5)
        G = [ 1.0 0.8 0.5;
              0.8 1.0 0.8;
              0.5 0.8 1.0]
        L = cholesky(G).L
        @test isapprox(S1 * L, S2, atol=1.0e-12)
    end

    @testset "H calculation." begin
        m = DiffFusion.gaussian_hjm_model("Theta_3F",delta,chi,sigma_f,nothing,nothing)
        H = DiffFusion.H_T(m, 0.5, 2.5)'
        @test size(H) == (4, 4)
        H_ = DiffFusion.H_hjm(chi(), 0.5, 2.5)
        G_ = DiffFusion.G_hjm(chi(), 0.5, 2.5)
        H_ref = [
            H_[1] 0     0     0;
            0     H_[2] 0     0;
            0     0     H_[3] 0;
            G_[1] G_[2] G_[3] 1;
        ]
        @test H == H_ref
        # test against Hull White model
        sigma_f_1 = DiffFusion.backward_flat_volatility("1F", times, values[1,:])
        m = DiffFusion.gaussian_hjm_model("1F", DiffFusion.flat_parameter("Std", [ 0.0 ]), DiffFusion.flat_parameter("Std", [ 0.10]), sigma_f_1, nothing, nothing)
        H_times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        H_model = [ DiffFusion.H_T(m, s, t)' for (s,t) in H_times ]
        H_ref = [ # H, G
            [0.90483742, 0.95162582],
            [0.90483742, 0.95162582],
            [0.67032005, 3.29679954],
            [0.74081822, 2.59181779],
            [0.36787944, 6.32120559]
        ]
        for (H_m, H_r) in zip(H_model, H_ref)
            @test H_m[:,2] == [ 0., 1. ]
            @test isapprox(H_m[:,1], H_r, atol=4.0e-9)
        end
    end

    @testset "Sigma calculation." begin
        m = DiffFusion.gaussian_hjm_model("Theta_3F",delta,chi,sigma_f,nothing,nothing)
        s = 0.5
        t = 2.5
        sigmaT_u = DiffFusion.Sigma_T(m,s,t)
        HHfInv = DiffFusion.benchmark_times_scaling(chi(),delta())
        u_times = [ 0.5, 1.0, 1.5, 2.0, 2.5 ]
        for u in u_times
            sigma_T = sigmaT_u(u)
            @test size(sigma_T) == (4,3)
            H_ = DiffFusion.H_hjm(chi(), u, t)
            G_ = DiffFusion.G_hjm(chi(), u, t)
            sigma_f_m = m.sigma_T.sigma_f(u)
            sigma_T_ref = vcat(
                Diagonal(H_) * HHfInv * Diagonal(sigma_f_m),
                G_' * HHfInv * Diagonal(sigma_f_m)
            )
            @test isapprox(sigma_T, sigma_T_ref, atol=1.0e-12)
        end
        # test against Hull White model
        sigma_f_1 = DiffFusion.backward_flat_volatility("1F", times, values[1,:])
        m = DiffFusion.gaussian_hjm_model("1F", DiffFusion.flat_parameter("Std", [ 0.0 ]), DiffFusion.flat_parameter("Std", [ 0.10]), sigma_f_1, nothing, nothing)
        s = 0.5
        t = 2.5
        sigmaT_u = DiffFusion.Sigma_T(m,s,t)
        u_times = [ 0.5, 1.0, 1.5, 2.0, 2.5 ]
        sigma_T_refs = [
            [40.93653765, 90.63462346],
            [43.03539882, 69.64601179],
            [54.29024508, 57.09754918],
            [57.07376547, 29.26234530],
            [70.00000000,  0.00000000],
        ]
        for (u, sigma_T_ref) in zip(u_times, sigma_T_refs)
            sigma_T = sigmaT_u(u)
            @test size(sigma_T) == (2,1)
            @test isapprox(vec(sigma_T), sigma_T_ref, atol=4.1e-9)
        end
    end

    @testset "Covariance calculation." begin
        m = DiffFusion.gaussian_hjm_model("Theta_3F",delta,chi,sigma_f,nothing,nothing)
        #
        cov = DiffFusion.covariance(m,nothing,0.0,1.0,nothing)
        y = DiffFusion.func_y(m, 1.0)
        @test isapprox(cov[1:end-1,1:end-1], y, atol=2.0e-10)
        #
        cov = DiffFusion.covariance(m,nothing,0.0,4.0,nothing)
        y = DiffFusion.func_y(m, 4.0)
        @test isapprox(cov[1:end-1,1:end-1], y, atol=4.0e-10)
        #
        cov = DiffFusion.covariance(m,nothing,3.0,8.0,nothing)
        y0 = DiffFusion.func_y(m, 3.0)
        y1 = DiffFusion.func_y(m, 8.0)
        H = DiffFusion.H_hjm(m, 3.0, 8.0)
        y = y1 - Diagonal(H) * y0 * Diagonal(H)
        @test isapprox(cov[1:end-1,1:end-1], y, rtol=7.0e-9)
        # with correlation
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,ch,nothing)
        cov = DiffFusion.covariance(m,ch,3.0,8.0,nothing)
        y0 = DiffFusion.func_y(m, 3.0)
        y1 = DiffFusion.func_y(m, 8.0)
        H = DiffFusion.H_hjm(m, 3.0, 8.0)
        y = y1 - Diagonal(H) * y0 * Diagonal(H)
        @test isapprox(cov[1:end-1,1:end-1], y, rtol=7.0e-9)
        # test against Hull White model
        sigma_f_1 = DiffFusion.backward_flat_volatility("1F", times, values[1,:])
        m = DiffFusion.gaussian_hjm_model("1F", DiffFusion.flat_parameter("Std", [ 0.0 ]), DiffFusion.flat_parameter("Std", [ 0.10]), sigma_f_1, nothing, nothing)
        cov_times = [ (0.0, 1.0), (1.0, 2.0), (6.0, 10.0), (0.5, 3.5), (2.5, 12.5) ]
        cov_mdl = [ DiffFusion.covariance(m,nothing,a,b,nothing) for (a,b) in cov_times ]
        cov_ref = [
            [ 2265.8655865252267 1131.9896257578391; 1131.9896257578391 773.64883232054250 ],
            [ 3262.8464445963270 1630.0650610912883; 1630.0650610912883 1114.0543185415813 ],
            [ 17621.473148248908 34780.439054701760; 34780.439054701760 102243.90408107398 ],
            [ 9488.6174859740190 12349.146896718303; 12349.146896718303 24155.313468232183 ],
            [ 27010.809359589766 118775.99731894341; 118775.99731894341 948399.11766215540 ]
        ]
        @test isapprox(cov_mdl[1], cov_ref[1], rtol=1.0e-15)
        @test isapprox(cov_mdl[2], cov_ref[2], rtol=1.0e-15)
        @test isapprox(cov_mdl[3], cov_ref[3], rtol=1.0e-15)
        @test isapprox(cov_mdl[4], cov_ref[4], rtol=3.5e-9)
        @test isapprox(cov_mdl[5], cov_ref[5], rtol=1.0e-15)
    end


    @testset "Access model state variables" begin
        m = DiffFusion.gaussian_hjm_model("Theta_3F",delta,chi,sigma_f,nothing,nothing)
        y = DiffFusion.func_y(m, 4.0)
        G = DiffFusion.G_hjm(m, 4.0, 8.0)
        X = [ 1., 2., 3., 4.] * [ 1., 2., 3.]'
        dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        SX = DiffFusion.model_state(X, dict)
        SX_2 = DiffFusion.model_state(X, m)
        @test string(SX_2) == string(SX)
        @test DiffFusion.log_bank_account(m, DiffFusion.alias(m), 1.0, SX) == [ 4., 8., 12. ]
        @test_throws AssertionError DiffFusion.log_bank_account(m, "WrongAlias", 1.0, SX) 
        @test DiffFusion.log_zero_bond(m, DiffFusion.alias(m), 4.0, 8.0, SX) == X[1:3,:]' * G .+ 0.5 * G'*y*G
        @test_throws AssertionError DiffFusion.log_zero_bond(m, "WrongAlias", 4.0, 8.0, SX)
        #
        df1 = DiffFusion.log_zero_bond(m, DiffFusion.alias(m), 4.0, 8.0, SX)
        df2 = DiffFusion.log_zero_bond(m, DiffFusion.alias(m), 4.0, 10.0, SX)
        cmp = DiffFusion.log_compounding_factor(m, DiffFusion.alias(m), 4.0, 8.0, 10.0, SX)
        @test cmp == df2 - df1
        @test_throws AssertionError DiffFusion.log_compounding_factor(m, "WrongAlias", 4.0, 8.0, 10.0, SX)
        #
        X = [ 0., 0., 1., 2., 3., 4., 0. ] * [ 1., 2., 3.]'
        s_alias = [ "1", "2", "Theta_3F_x_1", "Theta_3F_x_2", "Theta_3F_x_3", "Theta_3F_s", "7" ]
        dict = DiffFusion.alias_dictionary(s_alias)
        SX = DiffFusion.model_state(X, dict)
        @test DiffFusion.log_bank_account(m, "Theta_3F", 1.0, SX) == [ 4., 8., 12. ]
        @test DiffFusion.log_zero_bond(m, "Theta_3F", 4.0, 8.0, SX) == X[3:5,:]' * G .+ 0.5 * G'*y*G
        #
        df1 = DiffFusion.log_zero_bond(m, "Theta_3F", 4.0, 8.0, SX)
        df2 = DiffFusion.log_zero_bond(m, "Theta_3F", 4.0, 10.0, SX)
        cmp = DiffFusion.log_compounding_factor(m, "Theta_3F", 4.0, 8.0, 10.0, SX)
        @test cmp == df2 - df1
        #
        s_alias = [ "1", "2", "Theta_3F_x_0", "Theta_3F_x_2", "Theta_3F_x_3", "Theta_3F_t", "7" ]
        dict = DiffFusion.alias_dictionary(s_alias)
        SX = DiffFusion.model_state(X, dict)
        @test_throws KeyError DiffFusion.log_bank_account(m, "Theta_3F", 1.0, SX)
        @test_throws KeyError DiffFusion.log_zero_bond(m, "Theta_3F", 4.0, 8.0, SX)
        @test_throws KeyError DiffFusion.log_compounding_factor(m, "Theta_3F", 4.0, 8.0, 10.0, SX)
    end

end

