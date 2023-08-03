
using DiffFusion
using Test

@testset "Simulation context and context alias." begin

    _empty_key = DiffFusion._empty_context_key

    @testset "Context entries" begin
        @test string(DiffFusion.numeraire_entry("EUR")) == string(DiffFusion.NumeraireEntry(
            "EUR", nothing, Dict(_empty_key => "EUR")
        ))
        @test string(DiffFusion.numeraire_entry("EUR", "md/EUR")) == string(DiffFusion.NumeraireEntry(
            "EUR", "md/EUR", Dict(_empty_key => "EUR")
        ))
        @test string(DiffFusion.numeraire_entry("EUR", "md/EUR", "ts/EUR")) == string(DiffFusion.NumeraireEntry(
            "EUR", "md/EUR", Dict(_empty_key => "ts/EUR")
        ))
        #
        @test string(DiffFusion.rates_entry("EUR")) == string(DiffFusion.RatesEntry(
            "EUR", nothing, Dict(_empty_key => "EUR")
        ))
        @test string(DiffFusion.rates_entry("EUR", "md/EUR")) == string(DiffFusion.RatesEntry(
            "EUR", "md/EUR", Dict(_empty_key => "EUR")
        ))
        @test string(DiffFusion.rates_entry("EUR", "md/EUR", "ts/EUR")) == string(DiffFusion.RatesEntry(
            "EUR", "md/EUR", Dict(_empty_key => "ts/EUR")
        ))
        #
        @test string(DiffFusion.asset_entry("EUR-USD")) == string(DiffFusion.AssetEntry(
            "EUR-USD",
            nothing,
            nothing,
            nothing,
            "EUR-USD",
            Dict(_empty_key => "USD"),
            Dict(_empty_key => "EUR"),
        ))
        @test string(DiffFusion.asset_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR")) == string(DiffFusion.AssetEntry(
            "EUR-USD",
            "md/EUR-USD",
            "md/USD",
            "md/EUR",
            "EUR-USD",
            Dict(_empty_key => "USD"),
            Dict(_empty_key => "EUR"),
        ))
        @test string(DiffFusion.asset_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR", "ts/EUR-USD", "ts/USD", "ts/EUR")) == string(DiffFusion.AssetEntry(
            "EUR-USD",
            "md/EUR-USD",
            "md/USD",
            "md/EUR",
            "ts/EUR-USD",
            Dict(_empty_key => "ts/USD"),
            Dict(_empty_key => "ts/EUR"),
        ))
        #
        @test string(DiffFusion.forward_index_entry("EUR-USD")) == string(DiffFusion.ForwardIndexEntry(
            "EUR-USD",
            nothing,
            nothing,
            nothing,
            "EUR-USD",
        ))
        @test string(DiffFusion.forward_index_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR")) == string(DiffFusion.ForwardIndexEntry(
            "EUR-USD",
            "md/EUR-USD",
            "md/USD",
            "md/EUR",
            "EUR-USD",
        ))
        @test string(DiffFusion.forward_index_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR", "ts/EUR-USD")) == string(DiffFusion.ForwardIndexEntry(
            "EUR-USD",
            "md/EUR-USD",
            "md/USD",
            "md/EUR",
            "ts/EUR-USD",
        ))
        #
        @test string(DiffFusion.future_index_entry("NIK")) == string(DiffFusion.FutureIndexEntry(
            "NIK",
            nothing,
            "NIK",
        ))
        @test string(DiffFusion.future_index_entry("NIK", "md/NIK")) == string(DiffFusion.FutureIndexEntry(
            "NIK",
            "md/NIK",
            "NIK",
        ))
        @test string(DiffFusion.future_index_entry("NIK", "md/NIK", "ts/NIK")) == string(DiffFusion.FutureIndexEntry(
            "NIK",
            "md/NIK",
            "ts/NIK",
        ))
        #
        @test string(DiffFusion.fixing_entry("SOFR")) == string(DiffFusion.FixingEntry(
            "SOFR",
            "SOFR",
        ))
        @test string(DiffFusion.fixing_entry("SOFR", "ts/SOFR")) == string(DiffFusion.FixingEntry(
            "SOFR",
            "ts/SOFR",
        ))
    end

    @testset "Context setup" begin
        @test _empty_key == "<empty_key>"  # we want to see if this is changed
        #
        c = DiffFusion.simple_context("Std", ["USD", "EUR", "GBP"])
        c_ref = DiffFusion.Context(
            "Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD", DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR", DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                ("GBP", DiffFusion.RatesEntry("GBP", "GBP", Dict(_empty_key => "GBP"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("GBP-USD", DiffFusion.AssetEntry("GBP-USD", "GBP-USD", "USD", "GBP", "GBP-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "GBP"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test DiffFusion.alias(c) == DiffFusion.alias(c_ref)
        @test string(c) == string(c_ref)
        # a more realistic context
        g3 = DiffFusion.Context(
            "G3",
            DiffFusion.NumeraireEntry("USD", "USD-HJM1F", Dict(_empty_key => "USD-SOFR")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD", DiffFusion.RatesEntry("USD", "USD-HJM1F", Dict(
                    _empty_key => "USD-SOFR", # default curve
                    "SOFR"    => "USD-SOFR",          # same as default, but explicit
                    "LIBOR3M" => "USD-Libor3m",       # (legacy) 3m projection curve
                ))),
                ("EUR", DiffFusion.RatesEntry("EUR", "EUR-HJM1F", Dict(
                    _empty_key => "EUR-XCCY", # default curve, USD-SOFR collateral
                    "ESTR"      => "EUR-ESTR",        # ESTR (projection) curve
                    "EURIBOR6M" => "EUR-Euribor6m",   # 6m Euribor (projection) curve
                ))),
                ("GBP", DiffFusion.RatesEntry("GBP", "GBP-HJM1F", Dict(
                    _empty_key => "GBP-XCCY", # default curve, USD-SOFR collateral
                    "SONIA" => "GBP-SONIA",           # SONIA (projection) curve
                ))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD",
                    "EUR-USD-BS",
                    "USD-HJM1F",
                    "EUR-HJM1F",
                    "EUR-USD-SPOT",
                    Dict(_empty_key => "USD-SOFR"),
                    Dict(_empty_key => "EUR-XCCY")
                )),
                ("GBP-USD", DiffFusion.AssetEntry("GBP-USD",
                    "GBP-USD-BS",
                    "USD-HJM1F",
                    "GBP-HJM1F",
                    "GBP-USD-SPOT",
                    Dict(_empty_key => "USD-SOFR"),
                    Dict(_empty_key => "GBP-XCCY")
                )),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}([
                ("USD-SOFR", DiffFusion.FixingEntry("USD-SOFR", "USD-SOFR-Fixings")),
                ("USD-LIBOR3M", DiffFusion.FixingEntry("USD-LIBOR3M", "USD-Libor3m-Fixings")),
                ("EUR-ESTR", DiffFusion.FixingEntry("EUR-ESTR", "EUR-ESTR-Fixings")),
                ("EURIBOR6M", DiffFusion.FixingEntry("EURIBOR6M", "Euribor6m-Fixings")),
                ("SONIA", DiffFusion.FixingEntry("SONIA", "SONIA-Fixings")),
            ]),
        )
        @test DiffFusion.alias(g3) == "G3"
        @test DiffFusion.key(g3.numeraire) == "USD"
        @test g3.numeraire.model_alias == "USD-HJM1F"
        @test g3.numeraire.termstructure_dict[_empty_key] == "USD-SOFR"
        @test g3.rates["USD"].termstructure_dict["SOFR"] == "USD-SOFR"
        @test g3.rates["EUR"].termstructure_dict[_empty_key] == "EUR-XCCY"
        @test g3.rates["GBP"].model_alias == "GBP-HJM1F"
        @test DiffFusion.key(g3.assets["EUR-USD"]) == "EUR-USD"
        @test g3.assets["GBP-USD"].asset_model_alias == "GBP-USD-BS"
        for key in keys(g3.fixings)
            @test key in ["USD-SOFR", "USD-LIBOR3M", "EUR-ESTR", "EURIBOR6M", "SONIA" ]
        end
    end

    @testset "Deterministic model context." begin
        c = DiffFusion.deterministic_model_context("Std", ["USD", "EUR", "GBP"])
        c_ref = DiffFusion.Context(
            "Std",
            DiffFusion.NumeraireEntry("USD", nothing, Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD", DiffFusion.RatesEntry("USD", nothing, Dict(_empty_key => "USD"))),
                ("EUR", DiffFusion.RatesEntry("EUR", nothing, Dict(_empty_key => "EUR"))),
                ("GBP", DiffFusion.RatesEntry("GBP", nothing, Dict(_empty_key => "GBP"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", nothing, nothing, nothing, "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("GBP-USD", DiffFusion.AssetEntry("GBP-USD", nothing, nothing, nothing, "GBP-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "GBP"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test string(c) == string(c_ref)
    end

    @testset "Simplified Context setup" begin
        ctx = DiffFusion.context("Std", DiffFusion.numeraire_entry("USD"))
        ctx_ref = DiffFusion.Context(
            "Std",
            DiffFusion.numeraire_entry("USD"),
            Dict{String, DiffFusion.RatesEntry}(),
            Dict{String, DiffFusion.AssetEntry}(),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test string(ctx) == string(ctx_ref)
        #
        ctx = DiffFusion.context(
            "Std",
            DiffFusion.numeraire_entry("USD"),
            [ DiffFusion.rates_entry("USD"), DiffFusion.rates_entry("EUR"), ],
            [ DiffFusion.asset_entry("EUR-USD"), ],
            [ DiffFusion.forward_index_entry("EUR-USD"), ],
            [ DiffFusion.future_index_entry("NIK"), ],
            [ DiffFusion.fixing_entry("SOFR"), ],
        )
        ctx_ref = DiffFusion.Context(
            "Std",
            DiffFusion.numeraire_entry("USD"),
            Dict{String, DiffFusion.RatesEntry}(
                "USD" => DiffFusion.rates_entry("USD"),
                "EUR" => DiffFusion.rates_entry("EUR"),
            ),
            Dict{String, DiffFusion.AssetEntry}(
                "EUR-USD" => DiffFusion.asset_entry("EUR-USD"),
            ),
            Dict{String, DiffFusion.ForwardIndexEntry}(
                "EUR-USD" => DiffFusion.forward_index_entry("EUR-USD"),
            ),
            Dict{String, DiffFusion.FutureIndexEntry}(
                "NIK" => DiffFusion.future_index_entry("NIK"),
            ),
            Dict{String, DiffFusion.FixingEntry}(
                "SOFR" => DiffFusion.fixing_entry("SOFR"),
            ),
        )
        @test string(ctx) == string(ctx_ref)
    end


    @testset "Context key parsing." begin
        @test DiffFusion.context_keys("EUR") == ("EUR", _empty_key, _empty_key, _empty_key)
        @test DiffFusion.context_keys("EUR:") == ("EUR", _empty_key, _empty_key, _empty_key)
        @test DiffFusion.context_keys(":EUR") == (_empty_key, "EUR", _empty_key, _empty_key)
        @test DiffFusion.context_keys(":EUR:") == (_empty_key, "EUR:", _empty_key, _empty_key)
        @test DiffFusion.context_keys("EUR:OIS") == ("EUR", "OIS", _empty_key, _empty_key)
        @test DiffFusion.context_keys("EUR:OIS:SPD") == ("EUR", "OIS:SPD", _empty_key, _empty_key)
        @test DiffFusion.context_keys("EUR:OIS+SPD") == ("EUR", "OIS", "SPD", "+")
        @test DiffFusion.context_keys("EUR:OIS-SPD") == ("EUR", "OIS", "SPD", "-")
        @test DiffFusion.context_keys("EUR-USD") == ("EUR-USD", _empty_key, _empty_key, _empty_key)
        @test DiffFusion.context_keys("EUR-USD:OIS-OIS") == ("EUR-USD", "OIS", "OIS", "-")
        #
        @test DiffFusion._join_context_keys("EUR-USD", "OIS", "OIS", "-") == "EUR-USD:OIS-OIS"
    end
    
end
