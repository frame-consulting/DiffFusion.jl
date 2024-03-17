
using DiffFusion
using Test

@testset "Payoff evaluation and sensitivities." begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    @testset "Vanilla swap valuation and delta." begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        swap = (TestModels.eur_leg, TestModels.usd_leg)
        #
        obs_time = 0.5
        for obs_time in (0.0, 0.5, 2.0)
            println("Obs_time: " * string(obs_time) * ".")
            payoffs = vcat(
                DiffFusion.discounted_cashflows(swap[1], obs_time),
                DiffFusion.discounted_cashflows(swap[2], obs_time),
            )
            model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
            # println(model_price)
            (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, "USD")
            @test v == model_price
            # test deltas via manual FD
            shift = 1.0e-7
            for alias in keys(g)
                if isa(path.ts_dict[alias], DiffFusion.FlatForward)
                    grad = g[alias].rate
                end
                if isa(path.ts_dict[alias], DiffFusion.PiecewiseFlatParameter)
                    grad = g[alias].values[1,1]
                end
                #
                path_u = deepcopy(path)
                path_d = deepcopy(path)
                if isa(path.ts_dict[alias], DiffFusion.FlatForward)
                    path_u.ts_dict[alias] = DiffFusion.flat_forward(alias, path.ts_dict[alias].rate + shift)
                    path_d.ts_dict[alias] = DiffFusion.flat_forward(alias, path.ts_dict[alias].rate - shift)
                end
                if isa(path.ts_dict[alias], DiffFusion.PiecewiseFlatParameter)
                    path_u.ts_dict[alias] = DiffFusion.BackwardFlatParameter(alias, path.ts_dict[alias].times, path.ts_dict[alias].values .+ shift)
                    path_d.ts_dict[alias] = DiffFusion.BackwardFlatParameter(alias, path.ts_dict[alias].times, path.ts_dict[alias].values .- shift)
                end
                model_price_u = DiffFusion.model_price(payoffs, path_u, nothing, "USD")
                model_price_d = DiffFusion.model_price(payoffs, path_d, nothing, "USD")
                delta = (model_price_u - model_price_d) / (2 * shift)
                #
                println(alias * ": grad = " * string(grad) * ", delta = " * string(delta) * ".")
                @test isapprox(grad, delta, rtol=1.0e-6, atol=1.0e-4)
            end # alias
        end # obs_time
    end # testset
    
end
