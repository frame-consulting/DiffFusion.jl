
using DiffFusion
using Test

@testset "Extract term structures and rebuild models." begin

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
        eq_model = DiffFusion.lognormal_asset_model("SXE50-EUR", sigma_fx, ch, fx_model)
    
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
    
    hybrid_model_full = DiffFusion.simple_model("Std", setup_models(ch_full))

    @testset "Extract model parameters" begin
        full_model = hybrid_model_full
        usd_model = full_model.models[1]
        eur_usd_model = full_model.models[2]
        eur_model = full_model.models[3]
        sxe50_model = full_model.models[4]
        #
        d = DiffFusion.model_parameters(usd_model)
        @test length(d) == 1
        @test haskey(d, DiffFusion.alias(usd_model))
        d = d[DiffFusion.alias(usd_model)]
        for (a, b) in zip(keys(d), ["correlation_holder", "quanto_model", "chi", "sigma_f", "scaling_type", "type", "delta", "alias"])
            @test a == b
        end
        #
        d = DiffFusion.model_parameters(eur_usd_model)
        @test length(d) == 1
        @test haskey(d, DiffFusion.alias(eur_usd_model))
        d = d[DiffFusion.alias(eur_usd_model)]
        for (a, b) in zip(keys(d), ["quanto_model", "sigma_x", "type", "correlation_holder", "alias"])
            @test a == b
        end
        #
        d = DiffFusion.model_parameters(full_model)
        for (a, b) in zip(keys(d), ["EUR", "Std", "Full", "EUR-USD", "SXE50-EUR", "USD"])
            @test a == b
        end
    end

    @testset "Re-build models" begin
        full_model = hybrid_model_full
        usd_model = full_model.models[1]
        eur_usd_model = full_model.models[2]
        eur_model = full_model.models[3]
        sxe50_model = full_model.models[4]
        #
        param_dict = DiffFusion.model_parameters(full_model)
        model_dict = Dict{String, Any}()
        #
        model = DiffFusion.build_model(DiffFusion.alias(usd_model), param_dict, model_dict)
        @test string(model) == string(usd_model)
        #
        model = DiffFusion.build_model(DiffFusion.alias(eur_usd_model), param_dict, model_dict)
        @test string(model) == string(eur_usd_model)
        #
        @test_throws KeyError DiffFusion.build_model(DiffFusion.alias(eur_model), param_dict, model_dict)
        model_dict[DiffFusion.alias(eur_usd_model)] = eur_usd_model
        model = DiffFusion.build_model(DiffFusion.alias(eur_model), param_dict, model_dict)
        @test string(model) == string(eur_model)
        #
        model_dict = Dict{String, Any}()
        @test_throws KeyError DiffFusion.build_model(DiffFusion.alias(sxe50_model), param_dict, model_dict)
        model_dict[DiffFusion.alias(eur_usd_model)] = eur_usd_model
        model = DiffFusion.build_model(DiffFusion.alias(sxe50_model), param_dict, model_dict)
        @test string(model) == string(sxe50_model)
        #
        model_dict = Dict{String, Any}()
        model = DiffFusion.build_model(DiffFusion.alias(full_model), param_dict, model_dict)
        @test string(model) == string(full_model)
    end


    @testset "Extract model volatilities and re-build model." begin
        full_model = hybrid_model_full
        usd_model = full_model.models[1]
        eur_usd_model = full_model.models[2]
        eur_model = full_model.models[3]
        sxe50_model = full_model.models[4]
        #
        delim = DiffFusion._split_alias_identifyer
        #
        d = DiffFusion.model_parameters(usd_model)
        (l, v) = DiffFusion.model_volatility_values(usd_model.alias, d)
        @test l == [
            "USD" * delim * "sigma_f" * delim * "1" * delim * "0.00",
            "USD" * delim * "sigma_f" * delim * "2" * delim * "0.00",
            "USD" * delim * "sigma_f" * delim * "3" * delim * "0.00",
        ]
        @test v == [0.005, 0.006, 0.007]
        d1 = deepcopy(d)
        d2 = DiffFusion.model_parameters!(d, l, v)
        for (key, param) in d1["USD"]
            @test string(param) == string(d2["USD"][key])
        end
        #
        d = DiffFusion.model_parameters(eur_usd_model)
        (l, v) = DiffFusion.model_volatility_values(eur_usd_model.alias, d)
        @test l == ["EUR-USD" * delim * "sigma_x" * delim * "1" * delim * "0.00"]
        @test v == [0.15]
        d1 = deepcopy(d)
        d2 = DiffFusion.model_parameters!(d, l, v)
        for (key, param) in d1["EUR-USD"]
            @test string(param) == string(d2["EUR-USD"][key])
        end
        #
        d = DiffFusion.model_parameters(full_model)
        (l, v) = DiffFusion.model_volatility_values(full_model.alias, d)
        @test l == [
            "USD" * delim * "sigma_f" * delim * "1" * delim * "0.00",
            "USD" * delim * "sigma_f" * delim * "2" * delim * "0.00",
            "USD" * delim * "sigma_f" * delim * "3" * delim * "0.00",
            "EUR-USD" * delim * "sigma_x" * delim * "1" * delim * "0.00",
            "EUR" * delim * "sigma_f" * delim * "1" * delim * "0.00",
            "EUR" * delim * "sigma_f" * delim * "2" * delim * "0.00",
            "SXE50-EUR" * delim * "sigma_x" * delim * "1" * delim * "0.00",
        ]
        @test v == [50.0*1e-4, 60.0*1e-4, 70.0*1e-4, 0.15, 80.0*1e-4, 90.0*1e-4, 0.10]
        d1 = deepcopy(d)
        d2 = DiffFusion.model_parameters!(d, l, v)
        #
        model1 = DiffFusion.build_model(DiffFusion.alias(full_model), d1, Dict{String, Any}())
        model2 = DiffFusion.build_model(DiffFusion.alias(full_model), d2, Dict{String, Any}())
        @test string(model1) == string(model2)
        @test string(model2) == string(full_model)
    end

    @testset "Test term structure dimensions." begin
        full_model = hybrid_model_full
        usd_model = full_model.models[1]
        eur_usd_model = full_model.models[2]
        eur_model = full_model.models[3]
        sxe50_model = full_model.models[4]
        #
        d = DiffFusion.model_parameters(usd_model)
        ts = d["USD"]["sigma_f"]
        ts = DiffFusion.backward_flat_volatility(ts.alias, [1.0, 2.0, 3.0, 4.0], rand(3,4))
        d["USD"]["sigma_f"] = ts
        (l, v) = DiffFusion.model_volatility_values(usd_model.alias, d)
        d1 = deepcopy(d)
        d2 = DiffFusion.model_parameters!(d, l, v)
        @test d1["USD"]["sigma_f"].values == d2["USD"]["sigma_f"].values
        #
        d = DiffFusion.model_parameters(eur_usd_model)
        ts = d["EUR-USD"]["sigma_x"]
        ts = DiffFusion.backward_flat_volatility(ts.alias, [1.0, 2.0, 3.0, 4.0], rand(1,4))
        d["EUR-USD"]["sigma_x"] = ts
        (l, v) = DiffFusion.model_volatility_values(eur_usd_model.alias, d)
        d1 = deepcopy(d)
        d2 = DiffFusion.model_parameters!(d, l, v)
        @test d1["EUR-USD"]["sigma_x"].values == d2["EUR-USD"]["sigma_x"].values
        # println(l)
        # println(v)
    end

    @testset "CevAssetModel re-build" begin
        σ = DiffFusion.flat_volatility(0.15)
        γ = DiffFusion.flat_parameter(1.3)
        m = DiffFusion.cev_asset_model("EUR-USD", σ, γ, ch_full, nothing)
        d = DiffFusion.model_parameters(m)
        (l, v) = DiffFusion.model_volatility_values(m.alias, d)
        #
        p_dict = Dict{String, Any}( "Full" => ch_full )
        for k in keys(d)
            p_dict[k] = d[k]
        end
        DiffFusion.model_parameters!(p_dict, l, v)
        m_dict = Dict{String, Any}()
        m1 = DiffFusion.build_model(m.alias, p_dict, m_dict)
        @test string(m1) == string(m)
        # println(l)
        # println(d)
    end

end
