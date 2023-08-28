
using DiffFusion
using Test

@testset "Scenario generation and scenario arithmetics." begin

    ch = DiffFusion.correlation_holder("Std")
    #
    delta = DiffFusion.flat_parameter([ 1. ])
    chi = DiffFusion.flat_parameter([ 0.01 ])
    times =  [ 0. ]
    values = [ 0. ]'
    sigma_f = DiffFusion.backward_flat_volatility("", times, values)
    #
    hjm_model_dom = DiffFusion.gaussian_hjm_model("mdl/USD", delta, chi, sigma_f, ch, nothing)
    hjm_model_for = DiffFusion.gaussian_hjm_model("mdl/EUR", delta, chi, sigma_f, ch, nothing)
    #
    sigma_x = DiffFusion.flat_volatility("", 0.0)
    fx_model = DiffFusion.lognormal_asset_model("mdl/EUR-USD", sigma_x, ch, nothing)
    eq_model = DiffFusion.lognormal_asset_model("mdl/SXE50", sigma_x, ch, fx_model)
    #
    m = DiffFusion.simple_model("mdl/Std", [ hjm_model_dom, hjm_model_for, fx_model, eq_model ])

    ts = [
        DiffFusion.flat_forward("yc/ZERO", 0.00),
        DiffFusion.flat_parameter("pa/EUR-USD", 2.0),
        DiffFusion.flat_parameter("pa/SXE50", 100.0)
    ]

    ctx = DiffFusion.context(
        "Std",
        DiffFusion.numeraire_entry("USD", "mdl/USD", "yc/ZERO"),
        [
            DiffFusion.rates_entry("USD", "mdl/USD", "yc/ZERO"),
            DiffFusion.rates_entry("EUR", "mdl/EUR", "yc/ZERO"),
        ],
        [
            DiffFusion.asset_entry("EUR-USD", "mdl/EUR-USD", "mdl/USD", "mdl/EUR", "pa/EUR-USD", "yc/ZERO", "yc/ZERO"),
            DiffFusion.asset_entry("SXE50", "mdl/SXE50", "mdl/USD", nothing, "pa/SXE50", "yc/ZERO", "yc/ZERO"),
        ],
    )
    
    times = 0.0:2.0:10.0
    n_paths = 2^3
    sim = DiffFusion.simple_simulation(m, ch, times, n_paths, with_progress_bar = false)
    path = DiffFusion.path(sim, ts, ctx, DiffFusion.LinearPathInterpolation)

    @testset "Test scenario joining." begin
        leg1 = DiffFusion.cash_balance_leg("leg/1", 1.0)
        leg2 = DiffFusion.cash_balance_leg("leg/2", 1.0, "EUR-USD")
        leg3 = DiffFusion.asset_leg("leg/3", "EUR-USD", 1.0)
        leg4 = DiffFusion.asset_leg("leg/4", "SXE50", 1.0, "EUR-USD")
        #
        scens1 = DiffFusion.scenarios([leg1, ], times, path, nothing, with_progress_bar = false)
        scens2 = DiffFusion.scenarios([leg2, ], times, path, nothing, with_progress_bar = false)
        scens3 = DiffFusion.scenarios([leg3, ], times, path, nothing, with_progress_bar = false)
        scens4 = DiffFusion.scenarios([leg4, ], times, path, nothing, with_progress_bar = false)
        #
        @test scens1.X == ones((8,6,1))
        @test scens2.X == 2.0 * ones((8,6,1))
        @test scens3.X == 2.0 * ones((8,6,1))
        @test scens4.X == 200.0 * ones((8,6,1))
        #
        scens_12 = DiffFusion.join_scenarios(scens1, scens2)
        @test size(scens_12.X) == (8, 6, 2)
        @test scens_12.leg_aliases == ["leg/1", "leg/2"]
        #
        scens_1234 = DiffFusion.join_scenarios([ scens_12, scens3, scens4 ])
        @test size(scens_1234.X) == (8, 6, 4)
        @test scens_1234.leg_aliases == ["leg/1", "leg/2", "leg/3", "leg/4", ]
        #
        # display(size(scens_1234.X))
        # display(scens_1234.X)
    end

    @testset "Test arithmetic operations." begin
        leg1 = DiffFusion.cash_balance_leg("leg/1", 1.0)
        leg2 = DiffFusion.cash_balance_leg("leg/2", 1.0, "EUR-USD")
        leg3 = DiffFusion.asset_leg("leg/3", "EUR-USD", 1.0)
        leg4 = DiffFusion.asset_leg("leg/4", "SXE50", 1.0, "EUR-USD")
        #
        scens1 = DiffFusion.scenarios([leg1, ], times, path, nothing, with_progress_bar = false)
        scens2 = DiffFusion.scenarios([leg2, ], times, path, nothing, with_progress_bar = false)
        scens3 = DiffFusion.scenarios([leg3, ], times, path, nothing, with_progress_bar = false)
        scens4 = DiffFusion.scenarios([leg4, ], times, path, nothing, with_progress_bar = false)
        #
        scens_11 = DiffFusion.join_scenarios(scens1, scens1)
        scens_22 = DiffFusion.join_scenarios(scens2, scens2)
        #
        s = scens_11 + scens_22
        @test s.X == 3.0 * ones(8, 6, 2)
        @test s.leg_aliases == ["(leg/1 + leg/2)", "(leg/1 + leg/2)"]
        s = scens_11 - scens_22
        @test s.X == -1.0 * ones(8, 6, 2)
        @test s.leg_aliases == ["(leg/1 - leg/2)", "(leg/1 - leg/2)"]
        s = scens_11 * scens_22
        @test s.X == 2.0 * ones(8, 6, 2)
        @test s.leg_aliases == ["(leg/1 * leg/2)", "(leg/1 * leg/2)"]
        s = scens_11 / scens_22
        @test s.X == 0.5 * ones(8, 6, 2)
        @test s.leg_aliases == ["(leg/1 / leg/2)", "(leg/1 / leg/2)"]
        # broadcast via legs
        @test (scens_11 + scens2).X == (scens_11 + scens_22).X
        @test (scens_11 + scens2).leg_aliases == (scens_11 + scens_22).leg_aliases
        #
        @test (scens1 + scens_22).X == (scens_11 + scens_22).X
        @test (scens1 * scens_22).leg_aliases == (scens_11 * scens_22).leg_aliases
        # broadcast via paths
        scens_11_a = DiffFusion.aggregate(scens_11, true, false)
        scens_22_a = DiffFusion.aggregate(scens_22, true, false)
        #
        @test (scens_11_a + scens2).X == (scens_11 + scens_22).X
        @test (scens_11_a + scens2).leg_aliases == (scens_11 + scens_22).leg_aliases
        #
        @test (scens1 + scens_22_a).X == (scens_11 + scens_22).X
        @test (scens1 * scens_22_a).leg_aliases == (scens_11 * scens_22).leg_aliases
        #
        # display(size(s.X))
        # display(s.X)
        # println(s.leg_aliases)
    end
end