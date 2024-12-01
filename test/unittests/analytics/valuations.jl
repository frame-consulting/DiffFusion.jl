
using DiffFusion
using Test
using Zygote
using FiniteDifferences
using ForwardDiff

@testset "Payoff evaluation and sensitivities." begin
    @info "Testing AD sensitivities. This takes some time for compilation."

    ch = DiffFusion.correlation_holder("One")
    sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
    fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    empty_key = DiffFusion._empty_context_key
    #
    context = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("USD", nothing, Dict(empty_key => "yc/USD:OIS")),
        Dict{String, DiffFusion.RatesEntry}(),
        Dict{String, DiffFusion.AssetEntry}([
            ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", nothing, nothing, "pa/EUR-USD", Dict(empty_key => "yc/USD:OIS"), Dict(empty_key => "yc/EUR:XCY"))), 
        ]),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}(),
    )
    
    ts_list = [
        DiffFusion.flat_forward("yc/USD:OIS", 0.03),
        DiffFusion.flat_forward("yc/EUR:XCY", 0.025),
        #
        DiffFusion.flat_parameter("pa/EUR-USD", 1.25),
    ]
    
    times = 0.0:1.0:2.0
    n_paths = 2^6
    sim = DiffFusion.simple_simulation(fx_model, ch, times, n_paths, with_progress_bar = false)
    path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)

    sim_func(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
    make_regression(C, O) = DiffFusion.polynomial_regression(C, O, 1)

    @testset "Delta calculation" begin
        @info "Start testing AD Deltas..."
        payoffs = [ DiffFusion.Asset(2.0, "EUR-USD")]
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, "USD")
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, nothing)
        (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, nothing)
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v1, g1, l1) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v2 == model_price
        @test isapprox(g1, g2, atol=1.0e-12)
        @test isapprox(g2, g3, atol=1.0e-10)
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, nothing)
        (v1, g1, l1) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v3 == model_price
        @test isapprox(g1, g2, atol=1.0e-12)
        @test isapprox(g2, g3, atol=1.0e-9)
        @info "Finished."
        #println(g2)
    end

    @testset "Vega calculation" begin
        @info "Start testing AD Vegas..."
        model = DiffFusion.simple_model("Std", [fx_model])
        #
        payoffs = [ DiffFusion.Asset(2.0, "EUR-USD")]
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v, g) = DiffFusion.model_price_and_vegas(payoffs, model, sim_func, ts_list, context, nothing, "USD")
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v1, g1, l1) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v3 == model_price
        @test isapprox(g1, g2, atol=1.0e-12)
        @test isapprox(g2, g3, atol=1.0e-10)
        @info "Finished."
        # println(g1)
    end

    @testset "Zero model price and delta/vega calculation" begin
        # also capture case with non-trivial correlation
        ch = DiffFusion.correlation_holder("Two")
        DiffFusion.set_correlation!(ch, "EUR-USD_x", "GBP-USD_x", 0.3)
        sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
        fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
        sim = DiffFusion.simple_simulation(fx_model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)
        #
        payoffs = [ ]
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        @test model_price == 0.0
        #
        @info "Testing Zero AD Deltas..."
        #
        (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, "USD")
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, nothing)
        (v, g) = DiffFusion.model_price_and_deltas(payoffs, path, nothing, nothing)
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v1, g1, l1) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, "USD", FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v2 == model_price
        # @test isapprox(g1, g2, atol=1.0e-12)
        # @test isapprox(g2, g3, atol=1.0e-10)
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, nothing)
        (v1, g1, l1) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_deltas_vector(payoffs, path, nothing, nothing, FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v3 == model_price
        # @test isapprox(g1, g2, atol=1.0e-12)
        # @test isapprox(g2, g3, atol=1.0e-9)
        #
        @info "Testing Zero AD Vegas..."
        #
        model = DiffFusion.simple_model("Std", [fx_model])
        #
        (v, g) = DiffFusion.model_price_and_vegas(payoffs, model, sim_func, ts_list, context, nothing, "USD")
        @test v == model_price
        #
        model_price = DiffFusion.model_price(payoffs, path, nothing, "USD")
        (v1, g1, l1) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", Zygote)
        (v2, g2, l2) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", ForwardDiff)
        (v3, g3, l3) = DiffFusion.model_price_and_vegas_vector(payoffs, model, sim_func, ts_list, context, nothing, "USD", FiniteDifferences)
        @test v1 == model_price
        @test v2 == model_price
        @test v3 == model_price
        # @test isapprox(g1, g2, atol=1.0e-12)
        # @test isapprox(g2, g3, atol=1.0e-10)
    end

end
