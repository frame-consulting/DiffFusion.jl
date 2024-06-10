
using DiffFusion
using StatsBase
using Test

@testset "CEV model simulation." begin

    ch = DiffFusion.correlation_holder("Std")
    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ] * 1.0e-2
    sigma_fx = DiffFusion.backward_flat_volatility("EUR-USD",times,values)
    lognormal_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    @testset "Regression with log-normal model." begin
        cev_model = DiffFusion.cev_asset_model("EUR-USD", sigma_fx, DiffFusion.flat_parameter(0.0), ch, nothing)
        #
        times = 0.0:2.0:10.0
        n_paths = 2^3
        sim1 = DiffFusion.simple_simulation(lognormal_model, ch, times, n_paths, with_progress_bar = false)
        sim2 = DiffFusion.diagonal_simulation(cev_model, ch, times, n_paths, with_progress_bar = false)
        @test isapprox(sim1.X, sim2.X, atol=1.0e-15)
    end

    @testset "Martingale test single model." begin
        skew_x = DiffFusion.backward_flat_parameter(
            "EUR-USD",
            [ 1., 2., 5., 10. ],
            [ -0.25 -0.25 -0.25 -0.25; ],
        )
        cev_model = DiffFusion.cev_asset_model("EUR-USD", sigma_fx, skew_x, ch, nothing)
        #
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.diagonal_simulation(cev_model, ch, times, n_paths, with_progress_bar = true)
        one = mean(exp.(sim.X), dims=(1,2))[1,1,:]
        @test isapprox(one, ones(11), atol=0.04)
        #display(one)
        #vol = std(exp.(sim.X), dims=(1,2))[1,1,:] ./ (sqrt.(times) .+ 1.0e-16)
        #display(vol)
    end

    @testset "Martingale test quanto model." begin
        skew_x = DiffFusion.backward_flat_parameter(
            "EUR-USD",
            [ 1., 2., 5., 10. ],
            [ -0.25 -0.25 -0.25 -0.25; ],
        )
        model1 = DiffFusion.cev_asset_model("EUR-USD", sigma_fx, skew_x, ch, nothing)
        model2 = DiffFusion.cev_asset_model("USD-GBP", sigma_fx, skew_x, ch, model1)
        model = DiffFusion.diagonal_model("Std", [model1, model2])
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD-GBP_x", -0.25)
        #
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.diagonal_simulation(model, ch, times, n_paths, with_progress_bar = false)
        one = mean(exp.(sim.X[1,:,:]), dims=(1,))[1,:]
        @test isapprox(one, ones(11), atol=0.04)
        #display(one)
        # one = mean(exp.(sim.X[2,:,:]), dims=(1,))[1,:]
        one = mean(exp.(sim.X[1,:,:] + sim.X[2,:,:]), dims=(1,))[1,:]
        @test isapprox(one, ones(11), atol=0.09)
        #display(one)
        #
        # vol = std(exp.(sim.X[1,:,:]), dims=(1,))[1,:] ./ (sqrt.(times) .+ 1.0e-16)
        # display(vol)
        # vol = std(exp.(sim.X[2,:,:]), dims=(1,))[1,:] ./ (sqrt.(times) .+ 1.0e-16)
        # display(vol)
        # vol = std(exp.(sim.X[1,:,:] + sim.X[2,:,:]), dims=(1,))[1,:] ./ (sqrt.(times) .+ 1.0e-16)
        # display(vol)
    end

end
