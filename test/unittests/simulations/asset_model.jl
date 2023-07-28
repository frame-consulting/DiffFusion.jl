
using DiffFusion
using StatsBase
using Test

@testset "Asset model simulation." begin

    include("../test_tolerances.jl")
    abs_tol = test_tolerances["simulations/asset_model.jl"]
    @info "Run simulation test with tolerance abs_tol=" * string(abs_tol) * "."

    ch = DiffFusion.correlation_holder("Std")
    #
    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ] * 1.0e-2
    sigma_fx = DiffFusion.backward_flat_volatility("EUR-USD",times,values)
    asset_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    @testset "Simple simulation Asset Model." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(asset_model, ch, times, n_paths, with_progress_bar = false)
        @test size(sim.X) == (1,1024,6)
        # martingale test for asset
        one = mean(exp.(sim.X), dims=(1,2) )
        @test one[1] == 1.0
        @test isapprox(one[2], 1.008416855922482,  atol=abs_tol)
        @test isapprox(one[3], 0.982099766021187,  atol=abs_tol)
        @test isapprox(one[4], 0.990453803968384,  atol=abs_tol)
        @test isapprox(one[5], 0.9861609642910488, atol=abs_tol)
        @test isapprox(one[6], 0.9760952738715304, atol=abs_tol)
    end

    @testset "Simple Sobol sequence simulation." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        # asset model simulation
        sim = DiffFusion.simple_simulation(asset_model, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim.X) == (1,1024,6)
        # martingale test for asset
        one = mean(exp.(sim.X), dims=(1,2) )
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9999781497156314, atol=abs_tol)
        @test isapprox(one[3], 0.9999553555277515, atol=abs_tol)
        @test isapprox(one[4], 1.000763306879854 , atol=abs_tol)
        @test isapprox(one[5], 0.999399781315226 , atol=abs_tol)
        @test isapprox(one[6], 0.9974113348693537, atol=abs_tol)
    end

    @testset "Simple simulation with progress bar." begin
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(asset_model, ch, times, n_paths, with_progress_bar = true)
        @test size(sim.X) == (1,1024,11)
    end
end