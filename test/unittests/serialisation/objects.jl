
using DiffFusion
using OrderedCollections
using Test

@testset "Test object (de-)serialisation" begin
    
    @testset "Test object with args." begin
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "flat_forward",
            "alias" => "USD",
            "rate" => 0.03,
        )
        obj = DiffFusion.deserialise(d)
        @test obj == DiffFusion.FlatForward("USD", 0.03)
        d2 = DiffFusion.serialise(obj)
        d2_ref = OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
            "alias" => "USD",
            "rate" => 0.03,
        )
        @test d2 == d2_ref
        obj2 = DiffFusion.deserialise(d2)
        @test obj2 == obj
    end


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


    @testset "Test object with kwargs" begin
        model = hybrid_model_full
        ch = ch_full
        repository = Dict{String, Any}(
            DiffFusion.alias(model) => model,
            DiffFusion.alias(ch) => ch,
            "true" => true,
            "false" => false,
            "SobolBrownianIncrements" => DiffFusion.sobol_brownian_increments
        )
        # println(keys(repository))
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.Simulation",
            "constructor" => "simple_simulation",
            "model" => "{Std}",
            "ch" => "{Full}",
            "times" => [ 0.0, 2.0, 4.0, 6.0, 8.0, 10.0 ],
            "n_paths" => 2^10,
            "kwargs" => OrderedDict{String, Any}(
                "with_progress_bar" => "{false}",
                "brownian_increments" => "{SobolBrownianIncrements}",
            ),
        )
        obj = DiffFusion.deserialise(d, repository)
        obj_ref = DiffFusion.simple_simulation(
            model,
            ch,
            [ 0.0, 2.0, 4.0, 6.0, 8.0, 10.0 ],
            2^10;
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments,
        )
        @test obj.X == obj_ref.X
    end
end