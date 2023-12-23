
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
                [ 8.160079321240904e6,   5.7823072140125595e6,  3.08128489092463e6,    594154.193234952,      0.0,                   0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.2822341462636108e6,  1.3029336403312571e6,  961005.648992561,      649862.4700369746,     330640.52573131735,    0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [-4.7792180451030135e6, -4.957854667238729e6,  -3.570560697004381e6,  -2.2736408185762935e6, -1.0536949659888982e6,  0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 2.052058322602283e7,   1.8327767574485175e7,  1.5474993060098104e7,  1.2939567414871339e7,  1.0337122228566911e7,  8.146139880661089e6,  5.786556779180116e6,  3.683177067624899e6,   1.7783174034722417e6, 0.0, 0.0],
                [-1.0293449963390617e7, -1.2045759086815968e7, -1.0130447923588615e7, -8.252266093887748e6,  -6.365452567594981e6,  -4.960721291998119e6, -3.592765178156436e6, -2.3417890170609113e6, -910843.158261814,     0.0, 0.0],
                [-3.0867037091375636e6, -3.1021029535281807e6, -2.4262161572243813e6, -1.7936053330619307e6, -1.1811297262802331e6, -579710.019653324,     0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.1099997673603833e7,  1.0682319288259184e7,  8.85133360413585e6,    6.075419450480742e6,   3.719612737319657e6,   1.981583938268915e6,  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [-2.117850952661921e6,  -1.6730349282217112e6, -1.1200395685295006e6, -750925.3389081238,    -333348.8520029578,     0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
                [ 1.5292265651649681e6,  1.1772724443825367e6,  1.0041035713803598e6,  402283.8362401064,     144423.71924248966,    0.0,                  0.0,                  0.0,                   0.0,                  0.0, 0.0],
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
        println(size(scens.X))
    end

end
