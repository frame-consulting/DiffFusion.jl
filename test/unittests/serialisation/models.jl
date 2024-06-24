
using DiffFusion
using OrderedCollections
using Test
using YAML

@testset "Serialise and de-serialise models." begin

    _empty_key = DiffFusion._empty_context_key


    ch_one = DiffFusion.correlation_holder("One")
    ch_full = DiffFusion.correlation_holder("Full")
    #
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_2", "EUR_f_3", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_1", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_2", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_3", -0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_1", -0.20)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_2", -0.20)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "EUR_f_1", 0.30)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "EUR_f_2", 0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "SXE50_x", 0.70)

    setup_models(ch) = begin
        sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
        fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
    
        sigma_fx = DiffFusion.flat_volatility("SXE50", 0.10)
        eq_model = DiffFusion.lognormal_asset_model("SXE50", sigma_fx, ch, fx_model)
    
        delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
        times_dom =  [ 0. ]
        values_dom = [ 50. 60. 70. ]' * 1.0e-4
        sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
        hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)
    
        delta_for = DiffFusion.flat_parameter([ 1., 10. ])
        chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times_for =  [ 0. ]
        values_for = [ 80. 90. ]' * 1.0e-4
        sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
        hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model)

        return [ hjm_model_dom, fx_model, hjm_model_for, eq_model ]
    end

    @testset "GaussianHjmModel (de-)serialisation." begin
        models = setup_models(ch_full)
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        #
        s = DiffFusion.serialise(models[1])
        d = OrderedDict(
            "typename" => "DiffFusion.GaussianHjmModel",
            "constructor" => "gaussian_hjm_model",
            "alias" => "USD",
            "delta" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.0], [7.0], [15.0]],
                ),
            "chi" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.01], [0.1], [0.3]],
                ),
            "sigma_f" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "USD",
                "times" => [0.0],
                "values" => [[0.005], [0.006], [0.007]]
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "nothing",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        if VERSION >= v"1.7" # equality tests fail with Julia 1.6
            @test s == d
            @test string(o) == string(models[1])
        end
        #
        s = DiffFusion.serialise(models[3])
        d = OrderedDict(
            "typename" => "DiffFusion.GaussianHjmModel",
            "constructor" => "gaussian_hjm_model",
            "alias" => "EUR",
            "delta" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.0], [10.0]],
                ),
            "chi" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.01], [0.15]],
                ),
            "sigma_f" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "EUR",
                "times" => [0.0],
                "values" => [[0.008], [0.009000000000000001]],
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "{EUR-USD}",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        if VERSION >= v"1.7" # equality tests fail with Julia 1.6
            @test s == d
            @test string(o) == string(models[3])
        end
    end

    @testset "GaussianHjmModel with BenchmarkTimesScaling (de-)serialisation." begin
        models = setup_models(ch_full)
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        #
        d = OrderedDict(
            "typename" => "DiffFusion.GaussianHjmModel",
            "constructor" => "gaussian_hjm_model",
            "alias" => "USD",
            "delta" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.0], [7.0], [15.0]],
                ),
            "chi" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.01], [0.1], [0.3]],
                ),
            "sigma_f" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "USD",
                "times" => [0.0],
                "values" => [[0.005], [0.006], [0.007]]
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "nothing",
            "scaling_type" => OrderedDict{String, Any}(
                "typename"    => "DiffFusion.BenchmarkTimesScaling",
                "constructor" => "BenchmarkTimesScaling",
                "enumeration" => 1,
            ),
        )
        o = DiffFusion.deserialise(d, ref_dict)
        s = DiffFusion.serialise(o)
        if VERSION >= v"1.7" # equality tests fail with Julia 1.6
            @test s == d
        end
        #
        d = OrderedDict(
            "typename" => "DiffFusion.GaussianHjmModel",
            "constructor" => "gaussian_hjm_model",
            "alias" => "EUR",
            "delta" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.0], [10.0]],
                ),
            "chi" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.01], [0.15]],
                ),
            "sigma_f" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "EUR",
                "times" => [0.0],
                "values" => [[0.008], [0.009000000000000001]],
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "{EUR-USD}",
            "quanto_model" => "nothing",
            "scaling_type" => OrderedDict{String, Any}(
                "typename"    => "DiffFusion.BenchmarkTimesScaling",
                "constructor" => "BenchmarkTimesScaling",
                "enumeration" => 2,
            ),
        )
        o = DiffFusion.deserialise(d, ref_dict)
        s = DiffFusion.serialise(o)
        if VERSION >= v"1.7" # equality tests fail with Julia 1.6
            @test s == d
        end
    end

    @testset "LognormalAssetModel (de-)serialisation." begin
        models = setup_models(ch_full)
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        #
        s = DiffFusion.serialise(models[2])
        d = OrderedDict(
            "typename" => "DiffFusion.LognormalAssetModel",
            "constructor" => "lognormal_asset_model",
            "alias" => "EUR-USD",
            "sigma_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "EUR-USD",
                "times" => [0.0],
                "values" => [[0.15]]
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "nothing",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        @test s == d
        @test string(o) == string(models[2])
        #
        s = DiffFusion.serialise(models[4])
        d = OrderedDict(
            "typename" => "DiffFusion.LognormalAssetModel",
            "constructor" => "lognormal_asset_model",
            "alias" => "SXE50",
            "sigma_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "SXE50",
                "times" => [0.0],
                "values" => [[0.1]]
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "{EUR-USD}",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        @test s == d
        @test string(o) == string(models[4])
    end

    @testset "CevAssetModel (de-)serialisation." begin
        models = setup_models(ch_full)
        σ = DiffFusion.flat_volatility(0.15)
        γ = DiffFusion.flat_parameter(1.3)
        m = DiffFusion.cev_asset_model("EUR-USD", σ, γ, ch_full, nothing)
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        #
        s = DiffFusion.serialise(m)
        d = OrderedDict(
            "typename" => "DiffFusion.CevAssetModel",
            "constructor" => "cev_asset_model",
            "alias" => "EUR-USD",
            "sigma_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.15]]
                ),
            "skew_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.3]]
                ),
                "correlation_holder" => "{Full}",
            "quanto_model" => "nothing",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        @test s == d
        @test string(o) == string(m)
        #
        m = DiffFusion.cev_asset_model("SXE50", σ, γ, ch_full, models[2])
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        s = DiffFusion.serialise(m)
        d = OrderedDict(
            "typename" => "DiffFusion.CevAssetModel",
            "constructor" => "cev_asset_model",
            "alias" => "SXE50",
            "sigma_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatVolatility",
                "constructor" => "BackwardFlatVolatility",
                "alias" => "",
                "times" => [0.0],
                "values" => [[0.15]]
                ),
            "skew_x" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.BackwardFlatParameter",
                "constructor" => "BackwardFlatParameter",
                "alias" => "",
                "times" => [0.0],
                "values" => [[1.3]]
                ),
            "correlation_holder" => "{Full}",
            "quanto_model" => "{EUR-USD}",
        )
        o = DiffFusion.deserialise(d, ref_dict)
        @test s == d
        @test string(o) == string(m)
    end

    @testset "SimpleModel (de-)serialisation." begin
        models = setup_models(ch_one)
        ref_dict = Dict(
            "EUR-USD" => models[2],
            "One" => ch_one,
            "Full" => ch_full
        )
        #
        c = DiffFusion.simple_model("Std", models)
        s = DiffFusion.serialise(c)
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.SimpleModel",
            "constructor" => "simple_model",
            "alias" => "Std",
            "models" => OrderedDict{String, Any}[
                OrderedDict(
                    "typename" => "DiffFusion.GaussianHjmModel",
                    "constructor" => "gaussian_hjm_model",
                    "alias" => "USD",
                    "delta" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatParameter",
                        "constructor" => "BackwardFlatParameter",
                        "alias" => "",
                        "times" => [0.0],
                        "values" => [[1.0], [7.0], [15.0]],
                        ),
                    "chi" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatParameter",
                        "constructor" => "BackwardFlatParameter",
                        "alias" => "",
                        "times" => [0.0],
                        "values" => [[0.01], [0.1], [0.3]],
                        ),
                    "sigma_f" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatVolatility",
                        "constructor" => "BackwardFlatVolatility",
                        "alias" => "USD",
                        "times" => [0.0],
                        "values" => [[0.005], [0.006], [0.007]]
                        ),
                    "correlation_holder" => "{One}",
                    "quanto_model" => "nothing",
                    ),
                OrderedDict(
                    "typename" => "DiffFusion.LognormalAssetModel",
                    "constructor" => "lognormal_asset_model",
                    "alias" => "EUR-USD",
                    "sigma_x" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatVolatility",
                        "constructor" => "BackwardFlatVolatility",
                        "alias" => "EUR-USD",
                        "times" => [0.0],
                        "values" => [[0.15]]
                        ),
                    "correlation_holder" => "{One}",
                    "quanto_model" => "nothing",
                    ),
                OrderedDict(
                    "typename" => "DiffFusion.GaussianHjmModel",
                    "constructor" => "gaussian_hjm_model",
                    "alias" => "EUR",
                    "delta" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatParameter",
                        "constructor" => "BackwardFlatParameter",
                        "alias" => "",
                        "times" => [0.0],
                        "values" => [[1.0], [10.0]],
                        ),
                    "chi" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatParameter",
                        "constructor" => "BackwardFlatParameter",
                        "alias" => "",
                        "times" => [0.0],
                        "values" => [[0.01], [0.15]],
                        ),
                    "sigma_f" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatVolatility",
                        "constructor" => "BackwardFlatVolatility",
                        "alias" => "EUR",
                        "times" => [0.0],
                        "values" => [[0.008], [0.009000000000000001]],
                        ),
                    "correlation_holder" => "{One}",
                    "quanto_model" => "{EUR-USD}",
                    ),
                OrderedDict(
                    "typename" => "DiffFusion.LognormalAssetModel",
                    "constructor" => "lognormal_asset_model",
                    "alias" => "SXE50",
                    "sigma_x" => OrderedDict{String, Any}(
                        "typename" => "DiffFusion.BackwardFlatVolatility",
                        "constructor" => "BackwardFlatVolatility",
                        "alias" => "SXE50",
                        "times" => [0.0],
                        "values" => [[0.1]]
                        ),
                    "correlation_holder" => "{One}",
                    "quanto_model" => "{EUR-USD}",
                    ),
                ]
        )
        o = DiffFusion.deserialise(d, ref_dict)
        if VERSION >= v"1.7" # equality tests fail with Julia 1.6
            @test s == d
            @test string(o) == string(c)
        end
        #
        @test_throws AssertionError DiffFusion.deserialise(d)
        #println(d)
    end

    @testset "Model SimpleModel (de-)serialisation as list." begin
        models = setup_models(ch_one)
        c = DiffFusion.simple_model("Std", models)
        s = DiffFusion.serialise_as_list(c)
        obj_dict = DiffFusion.deserialise_from_list(s)
        #
        ref_alias_list = [ "One", "EUR-USD", "USD", "EUR", "SXE50", "Std" ]
        ref_type_list = [
            DiffFusion.CorrelationHolder,
            DiffFusion.LognormalAssetModel,
            DiffFusion.GaussianHjmModel,
            DiffFusion.GaussianHjmModel,
            DiffFusion.LognormalAssetModel,
            DiffFusion.SimpleModel,
        ]
        @test [ k for k in keys(obj_dict) ] == ref_alias_list
        @test [ typeof(v) for v in values(obj_dict) ] == ref_type_list
        # @test string(obj_dict["Std"]) == string(c) # CorrelationHolder types do not match.
        yaml_string = YAML.write(s)
        yaml_dict_list = YAML.load(yaml_string; dicttype=OrderedDict{String,Any})
        obj_dict = DiffFusion.deserialise_from_list(yaml_dict_list)
        @test [ k for k in keys(obj_dict) ] == ref_alias_list
        @test [ typeof(v) for v in values(obj_dict) ] == ref_type_list
        @test yaml_dict_list == s
        # println(yaml_dict_list)
    end


    @testset "De-serialisation of dictionaries in list." begin
        dict_list = [
            OrderedDict(
                "alias" => "config",
                "seed" => 42
                ),
        ]
        obj_dict = DiffFusion.deserialise_from_list(dict_list)
        @test haskey(obj_dict, "config")
        @test obj_dict["config"] == Dict{String, Any}("seed" => 42, "alias" => "config")
    end



    @testset "Context serialisation." begin
        context = DiffFusion.simple_context("Std", [ "USD", "EUR", "GBP" ] )
        s = DiffFusion.serialise(context)
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.Context",
            "constructor" => "Context",
            "alias" => "Std",
            "numeraire" => OrderedDict{String, Any}(
                "typename" => "DiffFusion.NumeraireEntry",
                "constructor" => "NumeraireEntry",
                "context_key" => "USD",
                "model_alias" => "USD",
                "termstructure_dict" => OrderedDict{String, Any}(_empty_key => "USD")
                ),
            "rates" => OrderedDict{String, Any}(
                "EUR" => OrderedDict{String, Any}(
                    "typename" => "DiffFusion.RatesEntry",
                    "constructor" => "RatesEntry",
                    "context_key" => "EUR",
                    "model_alias" => "EUR",
                    "termstructure_dict" => OrderedDict{String, Any}(_empty_key => "EUR")
                    ),
                "GBP" => OrderedDict{String, Any}(
                    "typename" => "DiffFusion.RatesEntry",
                    "constructor" => "RatesEntry",
                    "context_key" => "GBP",
                    "model_alias" => "GBP",
                    "termstructure_dict" => OrderedDict{String, Any}(_empty_key => "GBP")
                    ), 
                "USD" => OrderedDict{String, Any}(
                    "typename" => "DiffFusion.RatesEntry",
                    "constructor" => "RatesEntry",
                    "context_key" => "USD",
                    "model_alias" => "USD",
                    "termstructure_dict" => OrderedDict{String, Any}(_empty_key => "USD")
                    )
                ),
            "assets" => OrderedDict{String, Any}(
                "EUR-USD" => OrderedDict{String, Any}(
                    "typename" => "DiffFusion.AssetEntry",
                    "constructor" => "AssetEntry",
                    "context_key" => "EUR-USD",
                    "asset_model_alias" => "EUR-USD",
                    "domestic_model_alias" => "USD", 
                    "foreign_model_alias" => "EUR",
                    "asset_spot_alias" => "EUR-USD",
                    "domestic_termstructure_dict" => OrderedDict{String, Any}(_empty_key => "USD"),
                    "foreign_termstructure_dict" => OrderedDict{String, Any}(_empty_key => "EUR")
                    ),
                "GBP-USD" => OrderedDict{String, Any}(
                    "typename" => "DiffFusion.AssetEntry",
                    "constructor" => "AssetEntry",
                    "context_key" => "GBP-USD",
                    "asset_model_alias" => "GBP-USD",
                    "domestic_model_alias" => "USD",
                    "foreign_model_alias" => "GBP",
                    "asset_spot_alias" => "GBP-USD",
                    "domestic_termstructure_dict" => OrderedDict{String, Any}(_empty_key => "USD"),
                    "foreign_termstructure_dict" => OrderedDict{String, Any}(_empty_key => "GBP")
                    )
                ),
            "forward_indices" => OrderedDict{String, Any}(),
            "future_indices" => OrderedDict{String, Any}(),
            "fixings" => OrderedDict{String, Any}(),
        )
        o = DiffFusion.deserialise(d)
        @test s == d
        @test string(o) == string(context)
        # println(d)
    end

end