
using DiffFusion
using Test

@testset "Year-on-year convexity adjustment." begin

    ch_one = DiffFusion.correlation_holder("One")
    ch_full = DiffFusion.correlation_holder("Full")
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_2", 0.8)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "USD_f_3", 0.8)
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_1", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_2", -0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_1", -0.20)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_2", -0.20)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_3", -0.20)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "EUR_f_1", 0.30)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "EUR_f_2", 0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "SXE50_x", 0.70)
    
    function setup_models(
        ch;
        dom_vol_scaling = 1.0,
        for_vol_scaling = 1.0,
        ast_vol_scaling = 1.0,
        )
        sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15 * ast_vol_scaling)
        fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
    
        sigma_fx = DiffFusion.flat_volatility("SXE50", 0.10)
        eq_model = DiffFusion.lognormal_asset_model("SXE50-EUR", sigma_fx, ch, fx_model)
    
        delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
        times_dom =  [ 0. ]
        values_dom = [ 50. 60. 70. ]' * 1.0e-4 * dom_vol_scaling
        sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
        hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)
    
        delta_for = DiffFusion.flat_parameter([ 1., 10. ])
        chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times_for =  [ 0. ]
        values_for = [ 80. 90. ]' * 1.0e-4 * for_vol_scaling
        sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
        hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model)
    
        return [ hjm_model_dom, fx_model, hjm_model_for, eq_model ]
    end
    
    @testset "Boundary cases per times." begin
        ch = ch_full
        models = setup_models(ch)
        #
        ca(t, T0, T1, T2) = DiffFusion.log_asset_convexity_adjustment(
            models[1],
            models[3],
            models[2],
            t, T0, T1, T2,
            )
        # T0 == T1, deterministic payoff
        t = 10.0
        T = [ 10.0, 12.0, 14.0, 16.0, 18.0, 20.0 ]
        T2 = 20.0
        for (T0, T1) in zip(T, T)
            @test isapprox(ca(t, T0, T1, T2), 0.0, atol=1.0e-16)
            # display(ca(t, T0, T1, T2))
        end
        # t == T0, T1 == T2, forward index w/o payment delay
        t = 10.0
        T0 = 10.0
        T = [ 10.0, 12.0, 14.0, 16.0, 18.0, 20.0 ]
        for (T1, T2) in zip(T, T)
            @test isapprox(ca(t, T0, T1, T2), 0.0, atol=1.2e-16)
            # display(ca(t, T0, T1, T2))
        end
    end

    @testset "Boundary cases deterministic rates." begin
        ch = ch_full
        models = setup_models(
            ch,
            dom_vol_scaling = 0.0,
            for_vol_scaling = 0.0,
            )
        #
        ca(t, T0, T1, T2) = DiffFusion.log_asset_convexity_adjustment(
            models[1],
            models[3],
            models[2],
            t, T0, T1, T2,
            )
        # T0 == T1, deterministic payoff
        t = 10.0
        T0 = 13.0
        T1 = 16.0
        T2 = 20.0
        @test ca(t, T0, T1, T2) == 0.0
        # display(ca(t, T0, T1, T2))
    end

end
