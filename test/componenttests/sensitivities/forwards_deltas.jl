
using DiffFusion
using Test
using Zygote
using ForwardDiff

@testset "Payoff evaluation and sensitivities." begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    @testset "FX forward valuation and Delta." begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        #
        for obs_time in (0.0, 0.5, 2.0)
            # println("Obs_time: " * string(obs_time) * ".")
            payoffs = [ DiffFusion.Asset(obs_time, "EUR-USD") ]
            model_price = DiffFusion.model_price(payoffs, path, nothing, "")
            # println(model_price)
            (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, "")
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
                model_price_u = DiffFusion.model_price(payoffs, path_u, nothing, "")
                model_price_d = DiffFusion.model_price(payoffs, path_d, nothing, "")
                delta = (model_price_u - model_price_d) / (2 * shift)
                #
                # println(alias * ": grad = " * string(grad) * ", delta = " * string(delta) * ".")
                @test isapprox(grad, delta, rtol=1.0e-6, atol=1.0e-4)
            end # alias
        end # obs_time
    end # testset


    @testset "Test Delta for empty payoff" begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        payoffs = [ ]
        model_price = DiffFusion.model_price(payoffs, path, nothing, "")
        @test model_price == 0.0
        (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, "")
        @test v == model_price
    end


    @testset "FX forward valuation and Delta Sensitivity vector." begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments = DiffFusion.sobol_brownian_increments)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        gradient_vector = [
            [0.0, 0.0, 0.0, 0.0, 0.0,  0.0,                0.0, 1.0,                0.0],
            [0.0, 0.0, 0.0, 0.0, 0.0, -0.6154863068313337, 0.0, 0.9847780909301339, 0.0],
            [0.0, 0.0, 0.0, 0.0, 0.0, -2.378310467107729,  0.0, 0.9513241868430915, 0.0],
        ]
        #
        for (obs_time, g_ref) in zip((0.0, 0.5, 2.0,), gradient_vector)
            # println("Obs_time: " * string(obs_time) * ".")
            payoffs = [ DiffFusion.Asset(obs_time, "EUR-USD") ]
            model_price = DiffFusion.model_price(payoffs, path, nothing, "")
            # println(model_price)
            (v1, g1, l1) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "", Zygote)
            (v2, g2, l2) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "", ForwardDiff)
            @test v1 == model_price
            @test v2 == model_price
            @test isapprox(g1, g_ref, atol=1.0e-12)
            @test isapprox(g2, g_ref, atol=1.0e-12)
        end # obs_time
    end # testset

end
