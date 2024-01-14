
example_ = Examples.build(Examples.load("g3_1factor_flat"))
example_["config/simulation"]["with_progress_bar"] = false
example_["config/simulation"]["n_paths"] = 2^3
example_["config/instruments"]["with_progress_bar"] = false

path_ = Examples.path!(example_)

legs = vcat(
    Examples.random_swap(example_, "USD"),
    Examples.random_swap(example_, "EUR"),
    Examples.random_swap(example_, "EUR-USD"),
    Examples.random_swap(example_, "EUR6M-USD3M"),
    Examples.random_swaption(example_, "SOFR_SWPN"),
    Examples.random_swaption(example_, "EURIBOR6M_SWPN"),
    Examples.random_swaption(example_, "SONIA_SWPN"),
    Examples.random_bermudan(example_, "SOFR_SWPN"),
    Examples.random_bermudan(example_, "EURIBOR6M_SWPN"),
    Examples.random_bermudan(example_, "SONIA_SWPN"),
)

scens = scenarios(legs, sim.times, path_, "", with_progress_bar=false)
scens = aggregate(scens)

join_scenarios([scens, scens,])
scens + scens
scens - scens
scens * scens
scens / scens
