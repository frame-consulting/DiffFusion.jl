using DiffFusion
using Test

@testset "Products that generate payoffs." begin

    include("cashflows.jl")
    include("asset_option_flows.jl")
    include("rates_coupons.jl")
    include("cashflow_leg.jl")
    include("mtm_cashflow_leg.jl")
    include("cash_and_asset_legs.jl")
    include("swaption_leg.jl")
    include("bermudan_swaption_leg.jl")

end
