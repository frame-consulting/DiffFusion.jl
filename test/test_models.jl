
"""
We provide a example models and products that are re-used in various test cases.

This aims at simplifying test design.
"""

module TestModels

using DiffFusion

ch_one = DiffFusion.correlation_holder("One")
ch_full = DiffFusion.correlation_holder("Full")
#
DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_2", 0.5)
DiffFusion.set_correlation!(ch_full, "USD_f_2", "USD_f_3", 0.5)
DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_3", 0.2)
#
DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.50)
#
DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_1", -0.30)
DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_2", -0.30)
DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_3", -0.30)
#
DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_1", -0.20)
DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_2", -0.20)
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
        ("EUR", DiffFusion.RatesEntry("EUR","EUR",
            Dict(
                empty_key => "yc/EUR:XCY",
                "XCY" => "yc/EUR:XCY",
                "OIS" => "yc/EUR:OIS",
                "NULL" => "yc/ZERO"
            ))),
        ("SXE50", DiffFusion.RatesEntry("SXE50", nothing,
            Dict(empty_key => "div/SXE50"))),
    ]),
    Dict{String, DiffFusion.AssetEntry}([
        ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "pa/EUR-USD", Dict(empty_key => "yc/USD:OIS"), Dict(empty_key => "yc/EUR:XCY"))), 
        ("SXE50", DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "pa/SXE50-EUR", Dict(empty_key => "yc/EUR:XCY"), Dict(empty_key => "div/SXE50"))),
    ]),
    Dict{String, DiffFusion.ForwardIndexEntry}(),
    Dict{String, DiffFusion.FutureIndexEntry}(),
    Dict{String, DiffFusion.FixingEntry}([
        ("USD:OIS", DiffFusion.FixingEntry("USD:OIS", "pa/USD:OIS")),
        ("EUR:OIS", DiffFusion.FixingEntry("EUR:OIS", "pa/EUR:OIS")),
    ]),
)

# term structures
ts_list = [
    DiffFusion.flat_forward("yc/USD:OIS", 0.03),
    DiffFusion.flat_forward("yc/EUR:OIS", 0.02),
    DiffFusion.flat_forward("yc/EUR:XCY", 0.025),
    DiffFusion.flat_forward("div/SXE50", 0.01),
    #
    DiffFusion.flat_parameter("pa/EUR-USD", 1.25),
    DiffFusion.flat_parameter("pa/SXE50-EUR", 3750.00),
    DiffFusion.flat_parameter("pa/USD:OIS", 0.03),
    DiffFusion.flat_parameter("pa/EUR:OIS", 0.02),
    #
    DiffFusion.flat_forward("yc/ZERO", 0.00),
]

hybrid_model_one  = DiffFusion.simple_model("Std", setup_models(ch_one))
hybrid_model_full = DiffFusion.simple_model("Std", setup_models(ch_full))

# example EUR-USD swap
effective_time = -1.0/12
maturity_time = effective_time + 2.0
coupons_per_year = 4
eur_spread_rate = 0.01
eur_notional = 1.0e+4
eur_payer_receiver = +1.0
#
eur_leg = DiffFusion.Examples.compounded_rate_leg(
    "EUR:OIS-leg",
    effective_time,
    maturity_time,
    coupons_per_year,
    "EUR:OIS",
    "EUR:OIS",
    eur_spread_rate,
    eur_notional,
    "EUR:XCY",
    "EUR-USD",
    eur_payer_receiver,
)
usd_const_ntl_leg = DiffFusion.Examples.compounded_rate_leg(
    "USD:OIS-const-ntl-leg",
    effective_time,
    maturity_time,
    coupons_per_year,
    "USD:OIS",
    "USD:OIS",
    nothing,
    eur_notional * 1.25,
    "USD:OIS",
    nothing,
    -eur_payer_receiver,
)
usd_leg = DiffFusion.mtm_cashflow_leg(
    "USD:OIS-leg",
    usd_const_ntl_leg,
    eur_notional,
    effective_time,
    "EUR:XCY",
    "EUR-USD",
)


end # 