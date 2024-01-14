
ch = correlation_holder("Std")

m1 = lognormal_asset_model("md/EUR-USD", flat_volatility(0.15), ch, nothing)
m2 = lognormal_asset_model("md/SXE50-EUR", flat_volatility(0.15), ch, m1)
m3 = gaussian_hjm_model("md/USD", flat_parameter([0.0]), flat_parameter([0.01]), flat_volatility(0.01), ch, nothing)
m4 = gaussian_hjm_model("md/EUR", flat_parameter([0.0]), flat_parameter([0.01]), flat_volatility(0.01), ch, m1)
m5 = simple_model("md/Std", [m1, m2, m3, m4, ])

alias(m1)
alias(m3)
alias(m5)
