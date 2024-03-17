
using DiffFusion
using StatsBase
using Test


@testset "Path simulation and model functions." begin
    
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

    context = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
        Dict{String, DiffFusion.RatesEntry}([
            ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD", "OIS" => "USD", "NULL" => "ZERO"))),
            ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR", "OIS" => "USD", "NULL" => "ZERO"))),
            ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
        ]),
        Dict{String, DiffFusion.AssetEntry}([
            ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))), 
            ("SXE50", DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
        ]),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}(),
    )

    # term structures
    ts = [
        DiffFusion.flat_forward("USD", 0.03),
        DiffFusion.flat_forward("EUR", 0.02),
        DiffFusion.flat_forward("SXE50", 0.01),
        DiffFusion.flat_parameter("EUR-USD", 1.25),
        DiffFusion.flat_parameter("SXE50-EUR", 3750.00),
        DiffFusion.flat_forward("ZERO", 0.00),
    ]

    @testset "Simple simulation, no correlation" begin
        models = setup_models(ch_one)
        m = DiffFusion.simple_model("Std", models)
        times = [ 0.0, 1.0, 2.0, 4.0, 8.0, 16. ]
        n_paths = 2^13
        sim = DiffFusion.simple_simulation(m, ch_one, times, n_paths, with_progress_bar = false)
        p = DiffFusion.path(sim, ts, context)
        for t in times[2:end]
            #
            num = DiffFusion.numeraire(p, t, "USD")
            one = (1.0 / DiffFusion.discount(ts[1], t)) ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol=3.6e-3 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "USD")
                one = (1.0 / DiffFusion.discount(ts[1], t+dT)) * zcb ./ num
                # println(abs(mean(one) - 1.0))
                @test isapprox(mean(one), 1.0, atol=7.0e-3 )
            end
            fx = DiffFusion.asset(p, t, "EUR-USD")
            bd = DiffFusion.bank_account(p, t, "USD")
            bf = DiffFusion.bank_account(p, t, "EUR")
            one = bd ./ num  # num = bd!
            # println(maximum(abs.(one .- 1.0)))
            @test maximum(abs.(one .- 1.0)) < 1.0e-15
            one = (1.0/1.25) * bf .* fx ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol=9.8e-3 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "EUR")
                one = (1.0 / DiffFusion.discount(ts[2], t+dT) / 1.25) * zcb .* fx ./ num
                # println(abs(mean(one) - 1.0))
                @test isapprox(mean(one), 1.0, atol=2.5e-2 )
            end
            sxe50 = DiffFusion.asset(p, t, "SXE50")
            bf = DiffFusion.bank_account(p, t, "SXE50")
            one = bf * DiffFusion.discount(ts[3], t)
            # println(maximum(abs.(one .- 1.0)))
            @test maximum(abs.(one .- 1.0)) < 1.0e-15
            one = (1.0 / 1.25 / 3750.00) * sxe50 .* bf .* fx ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol=1.5e-2 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "SXE50")
                one = zcb * DiffFusion.discount(ts[3], t) / DiffFusion.discount(ts[3], t+dT)
                # println(maximum(abs.(one .- 1.0)))
                @test maximum(abs.(one .- 1.0)) < 1.0e-15
            end
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                fx_fwd = DiffFusion.forward_asset(p, t, t+dT, "EUR-USD")
                fx = DiffFusion.asset(p, t, "EUR-USD")
                zcb_d = DiffFusion.zero_bond(p, t, t+dT, "USD")
                zcb_f = DiffFusion.zero_bond(p, t, t+dT, "EUR")
                one = fx_fwd ./ (fx .* zcb_f ./ zcb_d)
                @test maximum(abs.(one .- 1.0)) < 1.5e-15
            end
        end
    end

    @testset "Simple simulation, full correlation" begin
        models = setup_models(ch_full)
        m = DiffFusion.simple_model("Std", models)
        times = [ 0.0, 1.0, 2.0, 4.0, 8.0, 16. ]
        n_paths = 2^16
        sim = DiffFusion.simple_simulation(m, ch_full, times, n_paths, with_progress_bar = false)
        p = DiffFusion.path(sim, ts, context)
        for t in times[2:end]
            #
            num = DiffFusion.numeraire(p, t, "USD")
            one = (1.0 / DiffFusion.discount(ts[1], t)) ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol=1.5e-3 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "USD")
                one = (1.0 / DiffFusion.discount(ts[1], t+dT)) * zcb ./ num
                # println(abs(mean(one) - 1.0))
                @test isapprox(mean(one), 1.0, atol=3.7e-3 )
            end
            fx = DiffFusion.asset(p, t, "EUR-USD")
            bd = DiffFusion.bank_account(p, t, "USD")
            bf = DiffFusion.bank_account(p, t, "EUR")
            one = bd ./ num  # num = bd!
            # println(maximum(abs.(one .- 1.0)))
            @test maximum(abs.(one .- 1.0)) < 1.0e-15
            one = (1.0/1.25) * bf .* fx ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol = 3.8e-3 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "EUR")
                one = (1.0 / DiffFusion.discount(ts[2], t+dT) / 1.25) * zcb .* fx ./ num
                # println(abs(mean(one) - 1.0))
                @test isapprox(mean(one), 1.0, atol=6.6e-2 )
            end
            sxe50 = DiffFusion.asset(p, t, "SXE50")
            bf = DiffFusion.bank_account(p, t, "SXE50")
            one = bf * DiffFusion.discount(ts[3], t)
            # println(maximum(abs.(one .- 1.0)))
            @test maximum(abs.(one .- 1.0)) < 1.0e-15
            one = (1.0 / 1.25 / 3750.00) * sxe50 .* bf .* fx ./ num
            # println(abs(mean(one) - 1.0))
            @test isapprox(mean(one), 1.0, atol = VERSION<v"1.7" ? 3.3e-3 : 2.4e-3 )
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                zcb = DiffFusion.zero_bond(p, t, t+dT, "SXE50")
                one = zcb * DiffFusion.discount(ts[3], t) / DiffFusion.discount(ts[3], t+dT)
                # println(maximum(abs.(one .- 1.0)))
                @test maximum(abs.(one .- 1.0)) < 1.0e-15
            end
            for dT in [1.0, 2.0, 4.0, 8.0, 16.0]
                fx_fwd = DiffFusion.forward_asset(p, t, t+dT, "EUR-USD")
                fx = DiffFusion.asset(p, t, "EUR-USD")
                zcb_d = DiffFusion.zero_bond(p, t, t+dT, "USD")
                zcb_f = DiffFusion.zero_bond(p, t, t+dT, "EUR")
                one = fx_fwd ./ (fx .* zcb_f ./ zcb_d)
                @test maximum(abs.(one .- 1.0)) < 1.5e-15
            end
        end
    end


end
