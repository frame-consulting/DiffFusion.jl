
using DiffFusion
using Test

@testset "Test ReadTermstructures." begin
    
    @testset "Test read_parameters." begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "fixings.csv")
        #
        @test_throws AssertionError DiffFusion.read_parameters(file_name, ';')
        res = DiffFusion.read_parameters(file_name, ',')
        @test isa(res, Vector{DiffFusion.ForwardFlatParameter})
        @test size(res) == (9,)
        #
        res = DiffFusion.read_parameters(file_name, ',', DiffFusion.backward_flat_parameter)
        @test !isa(res, Vector{DiffFusion.ForwardFlatParameter})
        @test isa(res, Vector{DiffFusion.BackwardFlatParameter})
        @test size(res) == (9,)
    end

    @testset "Test read_volatilities." begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "fx_vols.csv")
        #
        @test_throws AssertionError DiffFusion.read_volatilities(file_name, ';')
        res = DiffFusion.read_volatilities(file_name, ',')
        @test isa(res, Vector{DiffFusion.BackwardFlatVolatility})
        @test size(res) == (2,)
    end

    @testset "Test read_volatility." begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "eur-3f-vol.csv")
        @test_throws AssertionError DiffFusion.read_volatility(file_name, ';')
        res = DiffFusion.read_volatility(file_name, ',')
        @test isa(res, DiffFusion.BackwardFlatVolatility)
        #
        file_name = joinpath(DiffFusion.Examples._csv_path, "usd-3f-vol.csv")
        @test_throws AssertionError DiffFusion.read_volatility(file_name, ';')
        res = DiffFusion.read_volatility(file_name, ',')
        @test isa(res, DiffFusion.BackwardFlatVolatility)
        #
        file_name = joinpath(DiffFusion.Examples._csv_path, "gbp-3f-vol.csv")
        @test_throws AssertionError DiffFusion.read_volatility(file_name, ';')
        res = DiffFusion.read_volatility(file_name, ',')
        @test isa(res, DiffFusion.BackwardFlatVolatility)
        #
    end

    @testset "Test read_zero_curve." begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "zero_curves.csv")
        #
        @test_throws AssertionError DiffFusion.read_zero_curves(file_name, ';')
        res = DiffFusion.read_zero_curves(file_name, ',')
        @test isa(res, Vector{DiffFusion.ZeroCurve})
        @test size(res) == (9,)
    end

    @testset "Test read_correlations." begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "correlations.csv")
        #
        @test_throws AssertionError DiffFusion.read_correlations(file_name, ';')
        res = DiffFusion.read_correlations(file_name, ',')
        @test isa(res, DiffFusion.CorrelationHolder)
        @test DiffFusion.alias(res) == "corr/STD"
    end

    context = DiffFusion.context(
        "ctx/g3",
        DiffFusion.numeraire_entry("USD", "md/USD", "yc/USD:SOFR"),
        [
            DiffFusion.rates_entry(
                "USD",
                "md/USD",
                Dict(
                    DiffFusion._empty_context_key => "yc/USD:SOFR",
                    "SOFR" => "yc/USD:SOFR",
                )
            ),
            DiffFusion.rates_entry(
                "EUR",
                "md/EUR",
                Dict(
                    DiffFusion._empty_context_key => "yc/EUR:XCCYUSD",
                    "ESTR" => "yc/EUR:ESTR",
                    "EURIBOR1M" => "yc/EUR:EURIBOR1M",
                    "EURIBOR3M" => "yc/EUR:EURIBOR3M",
                    "EURIBOR6M" => "yc/EUR:EURIBOR6M",
                    "EURIBOR12M" => "yc/EUR:EURIBOR12M",
                ),
            ),
            DiffFusion.rates_entry(
                "GBP",
                "md/GBP",
                Dict(
                    DiffFusion._empty_context_key => "yc/GBP:XCCYUSD",
                    "SONIA" => "yc/GBP:SONIA",
                )
            ),
        ],
        [
            DiffFusion.asset_entry(
                "EUR-USD",
                "md/EUR-USD",
                "md/USD",
                "md/EUR",
                "pa/EUR-USD",
                "yc/USD:SOFR",
                "yc/EUR:XCCYUSD",
            ),
            DiffFusion.asset_entry(
                "GBP-USD",
                "md/GBP-USD",
                "md/USD",
                "md/GBP",
                "pa/GBP-USD",
                "yc/USD:SOFR",
                "yc/GBP:XCCYUSD",
            ),
        ]
    )

    @testset "Test path setup" begin
        file_name = joinpath(DiffFusion.Examples._csv_path, "correlations.csv")
        ch = DiffFusion.read_correlations(file_name, ',')
        #
        file_name = joinpath(DiffFusion.Examples._csv_path, "fx_vols.csv")
        fx_vols = DiffFusion.read_volatilities(file_name, ',')
        fx_vols = Dict([(DiffFusion.alias(ts),ts) for ts in fx_vols])
        #
        file_name = joinpath(DiffFusion.Examples._csv_path, "usd-3f-vol.csv")
        usd_vol = DiffFusion.read_volatility(file_name, ',')
        file_name = joinpath(DiffFusion.Examples._csv_path, "eur-3f-vol.csv")
        eur_vol = DiffFusion.read_volatility(file_name, ',')
        file_name = joinpath(DiffFusion.Examples._csv_path, "gbp-3f-vol.csv")
        gbp_vol = DiffFusion.read_volatility(file_name, ',')
        #
        fx_model_1 = DiffFusion.lognormal_asset_model("md/EUR-USD", fx_vols["vol/EUR-USD"], ch, nothing)
        fx_model_2 = DiffFusion.lognormal_asset_model("md/GBP-USD", fx_vols["vol/GBP-USD"], ch, nothing)
        delta = DiffFusion.flat_parameter([ 1., 5.0, 10.0 ])
        chi = DiffFusion.flat_parameter([ 0.01, 0.10, 0.50 ])
        hjm_model_1 = DiffFusion.gaussian_hjm_model("md/USD", delta, chi, usd_vol, ch, nothing)
        hjm_model_2 = DiffFusion.gaussian_hjm_model("md/EUR", delta, chi, eur_vol, ch, fx_model_1)
        hjm_model_3 = DiffFusion.gaussian_hjm_model("md/GBP", delta, chi, gbp_vol, ch, fx_model_2)
        #
        model = DiffFusion.simple_model("md/g3", [hjm_model_1, fx_model_1, hjm_model_2, fx_model_2, hjm_model_3])
        #
        times = [ 0.0 ]
        n_paths = 2^3
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        #
        file_name = joinpath(DiffFusion.Examples._csv_path, "fixings.csv")
        fixings = DiffFusion.read_parameters(file_name, ',')
        file_name = joinpath(DiffFusion.Examples._csv_path, "zero_curves.csv")
        curves = DiffFusion.read_zero_curves(file_name, ',')
        #
        path = DiffFusion.path(sim, vcat(fixings, curves), context)
        @test isa(path, DiffFusion.Path)
    end

end
