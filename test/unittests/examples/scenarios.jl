
using DiffFusion
using OrderedCollections
using StatsBase
using Test

@testset "Test Example scenarios." begin

    @testset "Test scenario generation" begin
        serialised_example = DiffFusion.Examples.load(DiffFusion.Examples.examples[1])
        example = DiffFusion.Examples.build(serialised_example)
        p = DiffFusion.Examples.portfolio!(example, 5)
        example["config/simulation"]["n_paths"] = 2^3
        example["config/simulation"]["with_progress_bar"] = false
        example["config/instruments"]["with_progress_bar"] = false
        scens = DiffFusion.Examples.scenarios!(example)
        @test size(scens.X) == (8,11,10)
        #println(size(scens.X))
        if (VERSION ≥ v"1.8")
            include("../test_tolerances.jl")
            abs_tol = test_tolerances["examples/examples.jl"]
            @info "Run regression test with tolerance abs_tol=" * string(abs_tol) * "."
            model_prices = mean(scens.X, dims=1)[1,:,:]
            model_prices_ref = [
                [-8.800555497384697e6,  -6.07808164368673e6,   -3.3187282691737576e6, -672029.3457423754,     0.0,                   0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 8.160079321240904e6,   5.782307214012554e6,   3.0812848909246367e6,  594154.193234952,      0.0,                   0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.2822341462636108e6,  1.3029336403312571e6,  961005.648992561,      649862.4700369746,     330640.52573131735,    0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [-4.7792180451030135e6, -4.957854667238739e6,  -3.57056069700439e6,   -2.2736408185762977e6, -1.0536949659889038e6,  0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 2.052058322602283e7,   1.832776757448519e7,   1.5474993060098102e7,  1.293956741487134e7,   1.033712222856691e7,   8.146139880661084e6,  5.786556779180105e6,  3.6831770676249014e6,  1.778317403472245e6,  0.0, 0.0],
                [-1.0293449963390617e7, -1.2045759086816011e7, -1.0130447923588654e7, -8.25226609388778e6,   -6.365452567595003e6,  -4.960721291998141e6, -3.592765178156452e6, -2.3417890170609104e6, -910843.1582618165,    0.0, 0.0],
                [-3.0867037091375636e6, -3.1021029535281807e6, -2.4262161572243813e6, -1.7936053330619307e6, -1.1811297262802331e6, -579710.019653324,     0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.1099997673603833e7,  1.0682319288259225e7,  8.851333604135886e6,   6.07541945048077e6,    3.7196127373196674e6,  1.981583938268917e6,  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [-2.117850952661921e6,  -1.6730349282217107e6, -1.1200395685294988e6, -750925.3389081224,    -333348.85200295626,    0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.5292265651649681e6,  1.177272444382534e6,   1.00410357138036e6,    402283.8362401061,     144423.71924248908,    0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
            ]
            for k in axes(model_prices, 2)
                @test isapprox(model_prices[:,k], model_prices_ref[k], atol=abs_tol)
                # println(scens.leg_aliases[k])
                # println(model_prices[:,k])
            end
        end
    end

    @testset "Test full scenario" begin
        serialised_example = DiffFusion.Examples.load(DiffFusion.Examples.examples[1])
        example = DiffFusion.Examples.build(serialised_example)
        example["config/simulation"]["n_paths"] = 2^3
        example["config/simulation"]["with_progress_bar"] = false
        example["config/instruments"]["with_progress_bar"] = false
        #
        path_ = DiffFusion.Examples.path!(example)
        portfolio_ = DiffFusion.Examples.portfolio!(
            example,
            8,  # swap
            8,  # swaptions
            8,  # berms
        )
        legs = vcat(portfolio_...)
        #
        config = example["config/instruments"]
        obs_times = config["obs_times"]
        if isa(obs_times, AbstractDict)
            obs_times = Vector(obs_times["start"]:obs_times["step"]:obs_times["stop"])
        end
        with_progress_bar = config["with_progress_bar"]
        discount_curve_key = config["discount_curve_key"]
        #
        for leg in legs
            if isa(leg, DiffFusion.BermudanSwaptionLeg)
                DiffFusion.reset_regression!(leg, path_, leg.regression_data.make_regression)
            end
        end
        #
        scens = DiffFusion.scenarios(
            legs,
            obs_times,
            path_,
            discount_curve_key,
            with_progress_bar=with_progress_bar
        )
        @test size(scens.X) == (8, 11, 32)
    end

end
