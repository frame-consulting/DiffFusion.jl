
using DiffFusion
using Test

@testset "Payoff evaluation and sensitivities." begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end


    function call(t::DiffFusion.ModelTime)
        S = DiffFusion.Asset(t, "EUR-USD")
        K = DiffFusion.Fixed(1.40)
        Z = DiffFusion.Fixed(0.0)
        V = DiffFusion.Pay(DiffFusion.Max(S - K, Z), t)
        return V
    end

    function put(t::DiffFusion.ModelTime)
        S = DiffFusion.Asset(t, "EUR-USD")
        K = DiffFusion.Fixed(1.40)
        Z = DiffFusion.Fixed(0.0)
        V = DiffFusion.Pay(DiffFusion.Max(K - S, Z), t)
        return V
    end

    function straddle(t::DiffFusion.ModelTime)
        S = DiffFusion.Asset(t, "EUR-USD")
        K = DiffFusion.Fixed(1.25)
        Z = DiffFusion.Fixed(0.0)
        V = DiffFusion.Pay(DiffFusion.Max(S - K, Z) + DiffFusion.Max(K - S, Z), t)
        return V
    end

    @testset "European option valuation and delta." begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        # option payoff...
        pay_time = 5.0
        V = straddle(pay_time)
        #
        make_regression = (C, O) -> DiffFusion.polynomial_regression(C, O, 2)
        #
        for obs_time in (0.0, 1.0, 2.0 )
            println("Obs_time: " * string(obs_time) * ".")
            Z = [
                DiffFusion.Asset(obs_time, "EUR-USD"),
                DiffFusion.ZeroBond(obs_time, pay_time, "EUR"),
                DiffFusion.ZeroBond(obs_time, pay_time, "USD"),
            ]
            payoffs = [ DiffFusion.AmcSum(
                obs_time, [V], Z, path, make_regression, "USD"
            )]
            model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
            println(model_price)
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


    @testset "Bermudan option valuation and delta." begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:10.0
        n_paths = 2^16
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        # option payoff...
        maturity_time = 5.0
        #
        # Julia 1.6 exhibits instabilities in FD delta calculation with degree = 2
        degree = if (VERSION < v"1.7") 1 else 2 end
        make_regression = (C, O) -> DiffFusion.polynomial_regression(C, O, degree)
        #
        for obs_time in (1.0, 2.0, 3.0)
            println("Obs_time: " * string(obs_time) * ".")
            H = put(maturity_time)
            for T in maturity_time-1:-1:obs_time
                Z = [
                    DiffFusion.Asset(T, "EUR-USD"),
                    DiffFusion.ZeroBond(T, maturity_time, "EUR"),
                    DiffFusion.ZeroBond(T, maturity_time, "USD"),
                ]
                U = put(T)
                H = DiffFusion.AmcMax(T, [H], [U], Z, path, make_regression, "USD")
            end
            payoffs = [ H ]
            model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
            println(model_price)
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
