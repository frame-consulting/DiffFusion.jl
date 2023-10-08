
using DiffFusion
using Test
using Zygote
using ForwardDiff

@testset "Payoff evaluation and sensitivities." begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    @testset "FX option valuation and Vega." begin
        #
        function straddle(t::DiffFusion.ModelTime)
            S = DiffFusion.Asset(t, "EUR-USD")
            K = DiffFusion.Fixed(1.25)
            Z = DiffFusion.Fixed(0.0)
            V = DiffFusion.Pay(DiffFusion.Max(S - K, Z) + DiffFusion.Max(K - S, Z), t)
            return V
        end    
        #
        model = TestModels.hybrid_model_full
        param_dict = DiffFusion.model_parameters(model)
        #
        model_dict = Dict{String, Any}()
        # println(param_dict["Full"])
        #
        ch = TestModels.ch_full
        times = 0.0:1.0:5.0
        n_paths = 2^10
        sim(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        sim_ = sim(model, ch)
        path_ = DiffFusion.path(sim_, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        shift = 1.0e-7
        #
        for obs_time in (1.0, 2.0, 5.0,)
            payoffs = [ straddle(obs_time) ]
            model_price = DiffFusion.model_price(payoffs, path_, nothing, "")
            println("Obs_time: " * string(obs_time) * ", model_price: " * string(model_price))
            (v, g) = DiffFusion.model_price_and_vegas(payoffs, model, sim, TestModels.ts_list, TestModels.context, nothing, "")
            @test v == model_price
            # Vega
            for key in keys(g)
                if isa(param_dict[key], AbstractDict)
                    param_key = nothing
                    if param_dict[key]["type"] == DiffFusion.GaussianHjmModel
                        param_key = "sigma_f"
                    end
                    if param_dict[key]["type"] == DiffFusion.LognormalAssetModel
                        param_key = "sigma_x"
                    end
                    if isnothing(param_key)
                        continue
                    end
                    grad = g[key][param_key].values
                    for k = 1:length(grad)
                        param_dict_u = deepcopy(param_dict)
                        param_dict_u[key][param_key].values[k,1] += shift
                        mdl_u = DiffFusion.build_model(model.alias, param_dict_u, model_dict)
                        sim_u = sim(mdl_u, ch)
                        path_u = DiffFusion.path(sim_u, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                        model_price_u = DiffFusion.model_price(payoffs, path_u, nothing, "")
                        #
                        param_dict_d = deepcopy(param_dict)
                        param_dict_d[key][param_key].values[k,1] -= shift
                        mdl_d = DiffFusion.build_model(model.alias, param_dict_d, model_dict)
                        sim_d = sim(mdl_d, ch)
                        path_d = DiffFusion.path(sim_d, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                        model_price_d = DiffFusion.model_price(payoffs, path_d, nothing, "")
                        #
                        delta = (model_price_u - model_price_d) / (2 * shift)
                        # println(key * "/" * param_key * "/" * string(k) * ": grad = " * string(grad[k]) * ", delta = " * string(delta) * ".")
                        @test isapprox(grad[k], delta, atol=1.0e-8)
                    end
                end
            end
            # mean reversion sensitivity
            for key in keys(g)
                if isa(param_dict[key], AbstractDict)
                    param_key = nothing
                    if param_dict[key]["type"] == DiffFusion.GaussianHjmModel
                        param_key = "chi"
                    end
                    if isnothing(param_key)
                        continue
                    end
                    grad = g[key][param_key].values
                    for k = 1:length(grad)
                        param_dict_u = deepcopy(param_dict)
                        param_dict_u[key][param_key].values[k,1] += shift
                        mdl_u = DiffFusion.build_model(model.alias, param_dict_u, model_dict)
                        sim_u = sim(mdl_u, ch)
                        path_u = DiffFusion.path(sim_u, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                        model_price_u = DiffFusion.model_price(payoffs, path_u, nothing, "")
                        #
                        param_dict_d = deepcopy(param_dict)
                        param_dict_d[key][param_key].values[k,1] -= shift
                        mdl_d = DiffFusion.build_model(model.alias, param_dict_d, model_dict)
                        sim_d = sim(mdl_d, ch)
                        path_d = DiffFusion.path(sim_d, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                        model_price_d = DiffFusion.model_price(payoffs, path_d, nothing, "")
                        #
                        delta = (model_price_u - model_price_d) / (2 * shift)
                        # println(key * "/" * param_key * "/" * string(k) * ": grad = " * string(grad[k]) * ", delta = " * string(delta) * ".")
                        @test isapprox(grad[k], delta, atol=1.0e-8)
                    end
                end
            end
            # correlation sensitivity
            grad = g["Full"].correlations
            for (k, g) in grad
                param_dict_u = deepcopy(param_dict)
                param_dict_u["Full"].correlations[k] += shift
                mdl_u = DiffFusion.build_model(model.alias, param_dict_u, model_dict)
                sim_u = sim(mdl_u, param_dict_u["Full"])
                path_u = DiffFusion.path(sim_u, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                model_price_u = DiffFusion.model_price(payoffs, path_u, nothing, "")
                #
                param_dict_d = deepcopy(param_dict)
                param_dict_d["Full"].correlations[k] -= shift
                mdl_d = DiffFusion.build_model(model.alias, param_dict_d, model_dict)
                sim_d = sim(mdl_d, param_dict_d["Full"])
                path_d = DiffFusion.path(sim_d, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
                model_price_d = DiffFusion.model_price(payoffs, path_d, nothing, "")
                #
                delta = (model_price_u - model_price_d) / (2 * shift)
                # println(k * ": grad = " * string(g) * ", delta = " * string(delta) * ".")
                @test isapprox(g, delta, atol=1.0e-8)
            end
            #
        end
    end

    @testset "Test Vega for empty payoff" begin
        model = TestModels.hybrid_model_full
        param_dict = DiffFusion.model_parameters(model)
        model_dict = Dict{String, Any}()
        ch = TestModels.ch_full
        times = 0.0:1.0:5.0
        n_paths = 2^10
        sim(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        payoffs = [  ]
        #
        sim_ = sim(model, ch)
        path_ = DiffFusion.path(sim_, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        model_price = DiffFusion.model_price(payoffs, path_, nothing, "")
        #
        (v, g) = DiffFusion.model_price_and_vegas(payoffs, model, sim, TestModels.ts_list, TestModels.context, nothing, "")
        @test v == model_price
        #println(g)
    end

    @testset "Test Vega without correlation holder" begin
        delta = DiffFusion.flat_parameter([ 1., 10. ])
        chi = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times =  [ 0. ]
        values = [ 80.;
                   90.;;] * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("USD",times,values)
        hjm_model = DiffFusion.gaussian_hjm_model("USD",delta,chi,sigma_f,nothing,nothing)
        model = DiffFusion.simple_model("Std", [hjm_model])
        empty_key = DiffFusion._empty_context_key
        #
        context = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(empty_key => "yc/USD:OIS")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD", DiffFusion.RatesEntry("USD", "USD",
                    Dict(
                        empty_key => "yc/USD:OIS",
                        "OIS" => "yc/USD:OIS",
                        "NULL" => "yc/ZERO"
                    ))),
            ]),
            Dict{String, DiffFusion.AssetEntry}(),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        #
        param_dict = DiffFusion.model_parameters(model)
        model_dict = Dict{String, Any}()
        model_r = DiffFusion.build_model(model.alias, param_dict, model_dict)
        @test string(model_r) == string(model)
        times = 0.0:1.0:5.0
        n_paths = 2^10
        sim(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        payoffs = [ DiffFusion.Pay(DiffFusion.Fixed(1.0), 5.0) ]
        #
        sim_ = sim(model, TestModels.ch_one)
        path_ = DiffFusion.path(sim_, TestModels.ts_list, context, DiffFusion.LinearPathInterpolation)
        model_price = DiffFusion.model_price(payoffs, path_, nothing, "")
        # println(model_price)
        #
        (v, g) = DiffFusion.model_price_and_vegas(payoffs, model, sim, TestModels.ts_list, context, nothing, "")
        @test v == model_price
        # println(g)
    end


    @testset "FX option valuation and Vega via input vector." begin
        #
        function straddle(t::DiffFusion.ModelTime)
            S = DiffFusion.Asset(t, "EUR-USD")
            K = DiffFusion.Fixed(1.25)
            Z = DiffFusion.Fixed(0.0)
            V = DiffFusion.Pay(DiffFusion.Max(S - K, Z) + DiffFusion.Max(K - S, Z), t)
            return V
        end
        #
        model = TestModels.hybrid_model_full
        param_dict = DiffFusion.model_parameters(model)
        #
        model_dict = Dict{String, Any}()
        # println(param_dict["Full"])
        #
        ch = TestModels.ch_full
        times = 0.0:1.0:5.0
        n_paths = 2^10
        sim(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments = DiffFusion.sobol_brownian_increments)
        sim_ = sim(model, ch)
        path_ = DiffFusion.path(sim_, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        shift = 1.0e-7
        #
        gradient_vector = [
            [-0.1707732829915917,  0.02129735705423064,  0.00286803828073537, 0.9679407996239741, 0.1281457611147937, -0.01539456201794944, 0.0],
            [-0.3344022365411503, -0.05887779884571783,  0.07714805320649105, 1.3261439394215784, 0.3131252864963913, -0.02366540492906325, 0.0],
            [-1.0008172071633483,  0.01704810876350376, -0.11890800858904177, 1.8847644534652820, 1.5518594407653001,  0.20851010022659852, 0.0],
        ]
        #
        for (obs_time, g_ref) in zip((1.0, 2.0, 5.0,), gradient_vector)
            payoffs = [ straddle(obs_time) ]
            model_price = DiffFusion.model_price(payoffs, path_, nothing, "")
            println("Obs_time: " * string(obs_time) * ", model_price: " * string(model_price))
            (v1, g1, l1) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim, TestModels.ts_list, TestModels.context, nothing, "", Zygote)
            (v2, g2, l2) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim, TestModels.ts_list, TestModels.context, nothing, "", ForwardDiff)
            @test v1 == model_price
            @test v2 == model_price
            @test isapprox(g1, g_ref, atol=1.0e-12)
            @test isapprox(g2, g_ref, atol=1.0e-12)
        end
    end

end
