using DiffFusion
using StatsBase
using Test

@testset "Ornstein-Uhlenbeck model simulation." begin

    ch = DiffFusion.correlation_holder("Std")
    #
    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ] * 1.0e-2
    chi = DiffFusion.flat_parameter("Std", 0.10)
    sigma_x = DiffFusion.backward_flat_volatility("Std",times,values)
    ou_model = DiffFusion.ornstein_uhlenbeck_model("OU", chi, sigma_x)

    @testset "Simple simulation OU Model." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(ou_model, ch, times, n_paths, with_progress_bar = false)
        @test size(sim.X) == (1,1024,6)
        # martingale test for asset
        zero = reshape(mean(sim.X, dims=(1,2)), 6)
        abs_tol = 0.01
        @test zero[1] == 0.0
        @test isapprox(zero[2], 0.0, atol =   abs_tol)
        @test isapprox(zero[3], 0.0, atol = 2*abs_tol)
        @test isapprox(zero[4], 0.0, atol =   abs_tol)
        @test isapprox(zero[5], 0.0, atol =   abs_tol)
        @test isapprox(zero[6], 0.0, atol = 2*abs_tol)
    end

    @testset "Simple Sobol sequence simulation." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        # ou model simulation
        sim = DiffFusion.simple_simulation(ou_model, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim.X) == (1,1024,6)
        # martingale test for asset
        zero = mean(sim.X, dims=(1,2) )
        abs_tol = 1.0e-10
        @test zero[1] == 0.0
        @test isapprox(zero[2], 0.0, atol=abs_tol)
        @test isapprox(zero[3], 0.0, atol=abs_tol)
        @test isapprox(zero[4], 0.0, atol=abs_tol)
        @test isapprox(zero[5], 0.0, atol=abs_tol)
        @test isapprox(zero[6], 0.0, atol=abs_tol)
    end

    @testset "Simple simulation with progress bar." begin
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(ou_model, ch, times, n_paths, with_progress_bar = true)
        @test size(sim.X) == (1,1024,11)
    end

    @testset "Simulation via simple model." begin
        times =  [ 1., 2., 5., 10. ]
        values_1 = [ 15. 10. 20. 30.; ] * 1.0e-2
        values_2 = values_1 .+ 0.05
        sigma_x_1 = DiffFusion.backward_flat_volatility("", times, values_1)
        sigma_x_2 = DiffFusion.backward_flat_volatility("", times, values_2)
        chi_1 = DiffFusion.flat_parameter("", 0.10)
        chi_2 = DiffFusion.flat_parameter("", 0.15)
        ou_model_1 = DiffFusion.ornstein_uhlenbeck_model("md/OU/1", chi_1, sigma_x_1)
        ou_model_2 = DiffFusion.ornstein_uhlenbeck_model("md/OU/2", chi_2, sigma_x_2)
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "md/OU/1_x", "md/OU/2_x", 0.50)
        #
        model = DiffFusion.simple_model("Std", [ou_model_1, ou_model_2])
        #
        times = 0.0:2.0:10.0
        n_paths = 2^10
        # ou model simulation
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim.X) == (2,1024,6)
        for (idx, t) in enumerate(times)
            v1 = DiffFusion.covariance(ou_model_1, ch, 0.0, t, nothing)
            v2 = DiffFusion.covariance(ou_model_2, ch, 0.0, t, nothing)
            cov_mod = DiffFusion.covariance(model, ch, 0.0, t, nothing)
            #
            @test v1[1,1] == cov_mod[1,1]
            @test v2[1,1] == cov_mod[2,2]
            #
            cov_sim = cov(sim.X[:,:,idx], dims=2)
            @test isapprox(cov_sim, cov_mod, atol = 2.0e-3)
        end
    end


end