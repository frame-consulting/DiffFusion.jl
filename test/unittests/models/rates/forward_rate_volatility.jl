
using DiffFusion

using Test

@testset "Test forward rate variance calculation." begin
    
    delta = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter("Std", [ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.]
    sigma_f = DiffFusion.backward_flat_volatility("Std",times,values)
    #
    ch = DiffFusion.correlation_holder("Std")
    DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
    DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
    DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)

    @testset "Forward looking rates." begin
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,ch,nothing)
        t = 1.0
        T = 8.0
        T0 = 9.0
        T1 = 10.0
        #
        ν² = DiffFusion.forward_rate_variance(m, t, T, T0, T1)
        #
        cov = DiffFusion.covariance(m, ch, t, T, nothing)
        G = DiffFusion.G_hjm(m, T, T1) - DiffFusion.G_hjm(m, T, T0)
        ν²_ref = G' * cov[1:end-1,1:end-1] * G
        @test isapprox(ν², ν²_ref, rtol=1.0e-14)
        #
        @test DiffFusion.forward_rate_variance(m, "Std", t, T, T0, T1) == DiffFusion.forward_rate_variance(m, t, T, T0, T1)
    end

    @testset "Backward looking rates" begin
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,ch,nothing)
        t = 1.0
        T = 10.0
        T0 = 9.0
        T1 = 10.0
        #
        ν² = DiffFusion.forward_rate_variance(m, t, T, T0, T1)
        #
        ν0² = DiffFusion.forward_rate_variance(m, t, T0, T0, T1)
        cov = DiffFusion.covariance(m, ch, t, T0, nothing)
        G = DiffFusion.G_hjm(m, T0, T1)
        ν1² = G' * cov[1:end-1,1:end-1] * G
        @test isapprox(ν0², ν1², rtol=1.0e-14)
        #
        f(u) = DiffFusion.G_hjm(m, u, T1)' * m.sigma_T(u) * m.sigma_T(u)' * DiffFusion.G_hjm(m, u, T1)
        ν2² = DiffFusion._scalar_integral(f, T0, T1)
        @test isapprox(ν², ν1² + ν2², rtol=1.0e-14)
        # println(ν² - ν1² - ν2²)
        #
        σ = sqrt(ν0² / (T0 - t))
        ν2²_approx = σ^2 * (T1 - T0) / 3 
        @test isapprox(ν2², ν2²_approx, rtol=0.1)
        #
        ν² = DiffFusion.forward_rate_variance(m, T0, T, T0, T1)
        @test isapprox(ν², ν2², rtol=1.0e-14)
        #
        ν² = DiffFusion.forward_rate_variance(m, 0.5*(T0+T1), T, T0, T1)
        ν2² = DiffFusion._scalar_integral(f, 0.5*(T0+T1), T1)
        @test isapprox(ν², ν2², rtol=1.0e-14)
        #println(ν²)
        #println(ν2²)
        #
        @test DiffFusion.forward_rate_variance(m, "Std", t, T, T0, T1) == DiffFusion.forward_rate_variance(m, t, T, T0, T1)
    end

    @testset "Corner cases" begin
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,ch,nothing)
        t = 1.0
        T = 8.0
        T0 = 9.0
        T1 = 10.0
        #
        @test DiffFusion.forward_rate_variance(m, 8.0, 8.0, T0, T1) == 0.0
        @test DiffFusion.forward_rate_variance(m, 9.0, 8.0, T0, T1) == 0.0
        @test_throws AssertionError DiffFusion.forward_rate_variance(m, t, 0.5*(T0+T1), T0, T1)
        @test_throws AssertionError DiffFusion.forward_rate_variance(m, t, T1 + 1.0, T0, T1)
        #
    end

end