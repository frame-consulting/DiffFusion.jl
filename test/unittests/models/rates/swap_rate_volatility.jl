
using DiffFusion
using Test

@testset "Test Gaussian HJM swaprate volatility calculation." begin
    
    if !@isdefined(TestModels)
        include("../../../test_models.jl")
    end

    @testset "Test swap rate gradient." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        swap_times = [ 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 ]
        w = [ 1.0, 1.0, 1.0, 1.0, 1.0 ]
        #
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        times =  [ 0. ]
        values = [ 50. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_1f = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        m = hjm_1f
        #
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        # println(size(SX.X))
        q = DiffFusion.swap_rate_gradient(yts, m, 1.0, swap_times, w, SX)
        @test size(q) == (5,1)
        @test all(q .> 0.92 * ones(5,1))
        @test all(q .< 1.02 * ones(5,1))
        #
        m = TestModels.hybrid_model_full.models[1]
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        # println(size(SX.X))
        q = DiffFusion.swap_rate_gradient(yts, m, 1.0, swap_times, w, SX)
        @test size(q) == (5,3)
        @test all(q ./ q[3,:]' .> 0.87 * ones(5,1))
        @test all(q ./ q[3,:]' .< 1.15 * ones(5,1))
        #
        #println(size(q))
        #for i in 1:size(q)[1]
        #    println(q[i,:]' ./ q[3,:]' )
        #end
    end

    @testset "Test swap rate volatility²." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        swap_times = [ 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 ]
        w = [ 1.0, 1.0, 1.0, 1.0, 1.0 ]
        #
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        times =  [ 0. ]
        values = [ 50. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_1f = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        m = hjm_1f
        #
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        σ² = DiffFusion.swap_rate_volatility²(yts, m, 1.0, swap_times, w, SX)
        @test size(σ²) == (5,)
        @test all(sqrt.(σ²) .> 0.0046)
        @test all(sqrt.(σ²) .< 0.0052)
        #
        m = TestModels.hybrid_model_full.models[1]
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        σ² = DiffFusion.swap_rate_volatility²(yts, m, 1.0, swap_times, w, SX)
        @test size(σ²) == (5,)
        @test all(sqrt.(σ²) .> 0.0055)
        @test all(sqrt.(σ²) .< 0.0068)
        # println(sqrt.(σ²))
    end

    @testset "Test swap rate variance." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        swap_times = [ 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 ]
        w = [ 1.0, 1.0, 1.0, 1.0, 1.0 ]
        #
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        times =  [ 0. ]
        values = [ 50. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_1f = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        m = hjm_1f
        #
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        ν² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times, w, SX)
        @test size(ν²) == (5,)
        @test all(sqrt.(ν²/4.0) .> 0.0047)
        @test all(sqrt.(ν²/4.0) .< 0.0053)
        # println(sqrt.(ν²/4.0))
        #
        m = TestModels.hybrid_model_full.models[1]
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        ν² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times, w, SX)
        @test size(ν²) == (5,)
        @test all(sqrt.(ν²/4.0) .> 0.0053)
        @test all(sqrt.(ν²/4.0) .< 0.0067)
        # println(sqrt.(ν²/4.0))
        #
        @test DiffFusion.swap_rate_variance(m, m.alias, yts, 1.0, 5.0, swap_times, w, SX) == DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times, w, SX)
    end


    @testset "Test swap rate covariance 1-Factor." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        swap_times_1 = [ 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 ]
        w_1 = ones(5)
        swap_times_2 = [ 5.0, 6.0 ]
        w_2 = ones(1)
        #
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        times =  [ 0. ]
        values = [ 100. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_1f = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        m = hjm_1f
        #
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        ν1² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times_1, w_1, SX)
        ν2² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times_2, w_2, SX)
        γ1 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_1, w_1, SX)
        γ2 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_2, w_2, swap_times_2, w_2, SX)
        @test ν1² == γ1
        @test ν2² == γ2
        #
        γ12 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_2, w_2, SX)
        Γ = DiffFusion.swap_rate_correlation(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_2, w_2, SX)
        @test Γ == γ12 ./ sqrt.(ν1² .* ν2²)
        @test isapprox(Γ, ones(5), atol=1.0e-10)
        # println(Γ)
    end

    @testset "Test swap rate covariance 3-Factor." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        swap_times_1 = vec(5.0:15.0)
        w_1 = ones(length(swap_times_1)-1)
        swap_times_2 = [ 5.0, 6.0 ]
        w_2 = ones(1)
        #
        ch = DiffFusion.correlation_holder("Full")
        #
        c = 0.30
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", c)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", c)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", c)
        delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi = DiffFusion.flat_parameter(1.0 * [ 0.01, 0.10, 0.30 ] .+ 0.00 )
        times =  [ 0. ]
        values = [ 70. 70. 70. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("EUR",times,values)
        hjm_3f = DiffFusion.gaussian_hjm_model("EUR",delta,chi,sigma_f,ch,nothing)
        m = hjm_3f # abbreviate
        #
        d = length(DiffFusion.factor_alias(m))
        X = ones(d + 1) * [ -0.05, -0.03, 0.0, 0.03, 0.05 ]'
        SX = DiffFusion.model_state(X, m)
        #
        ν1² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times_1, w_1, SX)
        ν2² = DiffFusion.swap_rate_variance(yts, m, 1.0, 5.0, swap_times_2, w_2, SX)
        γ1 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_1, w_1, SX)
        γ2 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_2, w_2, swap_times_2, w_2, SX)
        @test ν1² == γ1
        @test ν2² == γ2
        #
        γ12 = DiffFusion.swap_rate_covariance(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_2, w_2, SX)
        Γ = DiffFusion.swap_rate_correlation(yts, m, 1.0, 5.0, swap_times_1, w_1, swap_times_2, w_2, SX)
        @test Γ == γ12 ./ sqrt.(ν1² .* ν2²)
        @test all(Γ .< 0.83)
        @test all(Γ .> 0.74)
        if false
            println("σ_1: " * string(sqrt.(ν1²./4.0)))
            println("σ_2: " * string(sqrt.(ν2²./4.0)))
            println("Γ:   " * string(Γ))
        end
    end


    @testset "Test model-implied volatilities." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        option_times = [ 1.0, 2.0, 5.0, 10.0 ]
        swap_maturities = [ 2.0, 10.0, 20.0 ]
        #
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        times =  [ 0. ]
        values = [ 100. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_1f = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        m = hjm_1f
        #
        σ = DiffFusion.model_implied_volatilties(yts, m, option_times, swap_maturities)
        @test size(σ) == (4,3)
        @test all(σ .> 0.0090)
        @test all(σ .< 0.0103)
        #
        c = 0.30
        ch = DiffFusion.correlation_holder("Full")
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", c)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", c)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", c)
        delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi = DiffFusion.flat_parameter(1.0 * [ 0.01, 0.10, 0.30 ] .+ 0.00 )
        times =  [ 0. ]
        values = [ 70. 70. 70. ]' * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("EUR",times,values)
        hjm_3f = DiffFusion.gaussian_hjm_model("EUR",delta,chi,sigma_f,ch,nothing)
        m = hjm_3f # abbreviate
        #
        σ = DiffFusion.model_implied_volatilties(yts, m, option_times, swap_maturities)
        @test size(σ) == (4,3)
        @test all(σ .> 0.0054)
        @test all(σ .< 0.0074)
        # display(σ)
    end


end