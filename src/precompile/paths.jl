
sim = simple_simulation(m5, ch, [0.0, 1.0], 2^3, with_progress_bar=false, brownian_increments=sobol_brownian_increments)

ts = [
    flat_forward("ts/USD", 0.03),
    flat_forward("ts/EUR", 0.02),
    flat_forward("ts/SXE50", 0.01),
    flat_parameter("ts/EUR-USD", 1.25),
    flat_parameter("ts/SXE50-EUR", 3750.00),
    flat_forward("ts/ZERO", 0.00),
]

numeraire_entry("EUR")
numeraire_entry("EUR", "md/EUR")
numeraire_entry("EUR", "md/EUR", "ts/EUR")

rates_entry("EUR")
rates_entry("EUR", "md/EUR")
rates_entry("EUR", "md/EUR", "ts/EUR")

asset_entry("EUR-USD")
asset_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR")
asset_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR", "ts/EUR-USD", "ts/USD", "ts/EUR")

forward_index_entry("EUR-USD")
forward_index_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR")
forward_index_entry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR", "ts/EUR-USD")

future_index_entry("NIK")
future_index_entry("NIK", "md/NIK")
future_index_entry("NIK", "md/NIK", "ts/NIK")

fixing_entry("SOFR")
fixing_entry("SOFR", "ts/SOFR")

context(
    "Std",
    numeraire_entry("USD"),
    [ rates_entry("USD"), rates_entry("EUR"), ],
    [ asset_entry("EUR-USD"), ],
    [ forward_index_entry("EUR-USD"), ],
    [ future_index_entry("NIK"), ],
    [ fixing_entry("SOFR"), ],
)

ctx = Context("Std",
    NumeraireEntry("USD", "md/USD", Dict(_empty_context_key => "ts/USD")),
    Dict{String, RatesEntry}([
        ("USD",   RatesEntry("USD", "md/USD", Dict(_empty_context_key => "ts/USD", "OIS" => "ts/USD", "NULL" => "ts/ZERO"))),
        ("EUR",   RatesEntry("EUR", "md/EUR", Dict(_empty_context_key => "ts/EUR", "OIS" => "ts/USD", "NULL" => "ts/ZERO"))),
        ("SXE50", RatesEntry("SXE50", nothing, Dict(_empty_context_key => "ts/SXE50"))),
    ]),
    Dict{String, AssetEntry}([
        ("EUR-USD", AssetEntry("EUR-USD", "md/EUR-USD", "md/USD", "md/EUR", "ts/EUR-USD", Dict(_empty_context_key => "ts/USD"), Dict(_empty_context_key => "ts/EUR"))), 
        ("SXE50", AssetEntry("SXE50", "md/SXE50-EUR", "md/EUR", nothing, "ts/SXE50-EUR", Dict(_empty_context_key => "ts/EUR"), Dict(_empty_context_key => "ts/SXE50"))),
    ]),
    Dict{String, ForwardIndexEntry}(),
    Dict{String, FutureIndexEntry}(),
    Dict{String, FixingEntry}(),
)

path_ = path(sim, ts, ctx, LinearPathInterpolation)
