
using DiffFusion
using Test

@testset "AbstractPath" begin

    @testset "AbstractPath setup" begin
        struct NoPath <: DiffFusion.AbstractPath end
        @test_throws ErrorException DiffFusion.numeraire(NoPath(), 5.0, "Std")
        @test_throws ErrorException DiffFusion.bank_account(NoPath(), 5.0, "Std")
        @test_throws ErrorException DiffFusion.zero_bond(NoPath(), 5.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.zero_bonds(NoPath(), 5.0, [8.0, 10.0], "Std")
        @test_throws ErrorException DiffFusion.compounding_factor(NoPath(), 5.0, 8.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.asset(NoPath(), 5.0, "Std")
        @test_throws ErrorException DiffFusion.forward_asset(NoPath(), 5.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.forward_asset_and_zero_bonds(NoPath(), 5.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.forward_index(NoPath(), 5.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.future_index(NoPath(), 5.0, 10.0, "Std")
        @test_throws ErrorException DiffFusion.fixing(NoPath(), 5.0, "Std")
        @test_throws ErrorException DiffFusion.length(NoPath())
        # not yet implemented...
        @test_throws ErrorException DiffFusion.asset_convexity_adjustment(NoPath(), 5.0, 6.0, 7.0, 8.0, "Std")
        @test_throws ErrorException DiffFusion.index_convexity_adjustment(NoPath(), 5.0, 6.0, 7.0, 8.0, "Std")
        @test_throws ErrorException DiffFusion.swap_rate_variance(NoPath(), 1.0, 2.0, [2.0, 3.0, 4.0], [1.0, 1.0], "Std")
        @test_throws ErrorException DiffFusion.forward_rate_variance(NoPath(), 1.0, 2.0, 2.0, 3.0, "Std")
        @test_throws ErrorException DiffFusion.asset_variance(NoPath(), 1.0, 2.0, "Std")
    end

end

@testset "Monte Carlo paths." begin
    
    _empty_key = DiffFusion._empty_context_key

    # hybrid model

    ch = DiffFusion.correlation_holder("Std")

    sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
    fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    sigma_fx = DiffFusion.flat_volatility("SXE50", 0.10)
    eq_model = DiffFusion.lognormal_asset_model("SXE50-EUR", sigma_fx, ch, fx_model)

    delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
    chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
    times_dom =  [ 0. ]
    values_dom = [ 50. 60. 70.]' * 1.0e-4
    sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
    hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)

    delta_for = DiffFusion.flat_parameter([ 1., 10. ])
    chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
    times_for =  [ 0. ]
    values_for = [ 80. 90. ]' * 1.0e-4
    sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
    hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model)

    delta_nik = DiffFusion.flat_parameter(1.0)
    chi_nik = DiffFusion.flat_parameter(0.05)
    sigma_nik = DiffFusion.flat_volatility("NIK", 0.10)
    mkv_model = DiffFusion.markov_future_model("NIK", delta_nik, chi_nik, sigma_nik, nothing, nothing)

    m = DiffFusion.simple_model("Std", [ hjm_model_dom, fx_model, hjm_model_for, eq_model, mkv_model ])

    # artificial simulation

    times = [ 0.0, 1.0, 2.0, 4.0, 8.0, 16. ]
    n_paths = 5
    X = ones(length(DiffFusion.state_alias(m)), n_paths, length(times))
    X[:,:,1] = zeros(length(DiffFusion.state_alias(m)), n_paths)
    X[:,:,5] = 2.0 * ones(length(DiffFusion.state_alias(m)), n_paths)
    sim = DiffFusion.Simulation(m, times, X, nothing)

    # valuation context with deterministic dividend yield

    context = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD", "OIS" => "USD")),
        Dict{String, DiffFusion.RatesEntry}([
            ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD", "OIS" => "USD", "NO" => "ZERO"))),
            ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR", "NO" => "ZERO"))),
            ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
        ]),
        Dict{String, DiffFusion.AssetEntry}([
            ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
            ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ("HICP", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "ZERO"), Dict(_empty_key => "ZERO"))),
        ]),
        Dict{String, DiffFusion.ForwardIndexEntry}([
            ("HICP", DiffFusion.ForwardIndexEntry("EUR-USD-FWD", "EUR-USD", "USD", "EUR", "EUR-USD-FWD")),
        ]),
        Dict{String, DiffFusion.FutureIndexEntry}([
            ("NIK", DiffFusion.FutureIndexEntry("NIK", "NIK", "NIK-FUT")),
        ]),
        Dict{String, DiffFusion.FixingEntry}([
            ("SOFR", DiffFusion.FixingEntry("SOFR", "USD-SOFR-Fixings")),
        ]),
    )

    # term structures
    ts = [
        DiffFusion.flat_forward("USD", 0.03),
        DiffFusion.flat_forward("EUR", 0.02),
        DiffFusion.flat_forward("SXE50", 0.01),
        DiffFusion.flat_parameter("EUR-USD", 1.25),
        DiffFusion.flat_parameter("EUR-USD-FWD", 1.25),
        DiffFusion.flat_parameter("SXE50-EUR", 3750.00),
        DiffFusion.flat_forward("ZERO", 0.00),
        DiffFusion.flat_parameter("NIK-FUT", 23776.50),
        DiffFusion.flat_parameter("USD-SOFR-Fixings", 0.0123),
    ]

    @testset "Path setup." begin
        p = DiffFusion.path(sim, ts, context)
        @test p.interpolation == DiffFusion.NoPathInterpolation
        @test length(p) == 5
        # missing rates model
        wrong_cxt = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                ("SXE50", DiffFusion.RatesEntry("SXE50", "SXE50", Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test_throws AssertionError DiffFusion.path(sim, ts, wrong_cxt)
        # missing asset model
        wrong_cxt = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test_throws AssertionError DiffFusion.path(sim, ts, wrong_cxt)
        # missing foreign rates model
        wrong_cxt = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", "SXE50", "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        @test_throws AssertionError DiffFusion.path(sim, ts, wrong_cxt)
        # missing term structure
        wrong_cxt = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}([
                ("USD-SOFR", DiffFusion.FixingEntry("USD-SOFR", "USD-SOFR-Fixings")),
            ]),
        )
        DiffFusion.path(sim, ts, wrong_cxt)
        @test_throws AssertionError DiffFusion.path(sim, ts[2:end], wrong_cxt)
        @test_throws AssertionError DiffFusion.path(sim, ts[1:end-1], wrong_cxt)
    end

    @testset "State variable calculation" begin
        #
        @test DiffFusion.state_variable(sim, 0.0, DiffFusion.NoPathInterpolation) == zeros(10, 5)
        @test DiffFusion.state_variable(sim, 1.0, DiffFusion.NoPathInterpolation) == ones(10, 5)
        @test DiffFusion.state_variable(sim, 8.0, DiffFusion.NoPathInterpolation) == 2.0 * ones(10, 5)
        #
        @test DiffFusion.state_variable(sim, 8.0 - 0.4/365, DiffFusion.NoPathInterpolation) == 2.0 * ones(10, 5)
        @test DiffFusion.state_variable(sim, 8.0 + 0.4/365, DiffFusion.NoPathInterpolation) == 2.0 * ones(10, 5)
        @test DiffFusion.state_variable(sim, 0.0 - 0.4/365, DiffFusion.NoPathInterpolation) == zeros(10, 5)
        @test DiffFusion.state_variable(sim, 16.0 + 0.4/365, DiffFusion.NoPathInterpolation) == ones(10, 5)
        #
        @test_throws AssertionError DiffFusion.state_variable(sim, -0.5, DiffFusion.NoPathInterpolation)
        @test_throws AssertionError DiffFusion.state_variable(sim,  1.5, DiffFusion.NoPathInterpolation)
        @test_throws AssertionError DiffFusion.state_variable(sim, 16.5, DiffFusion.NoPathInterpolation)
        #
        @test DiffFusion.state_variable(sim, 0.0, DiffFusion.LinearPathInterpolation) == zeros(10, 5)
        @test DiffFusion.state_variable(sim, 1.0, DiffFusion.LinearPathInterpolation) == ones(10, 5)
        @test DiffFusion.state_variable(sim, 8.0, DiffFusion.LinearPathInterpolation) == 2.0 * ones(10, 5)
        #
        @test DiffFusion.state_variable(sim, 8.0 - 0.4/365, DiffFusion.LinearPathInterpolation) == 2.0 * ones(10, 5)
        @test DiffFusion.state_variable(sim, 8.0 + 0.4/365, DiffFusion.LinearPathInterpolation) == 2.0 * ones(10, 5)
        @test DiffFusion.state_variable(sim, 0.0 - 0.4/365, DiffFusion.LinearPathInterpolation) == zeros(10, 5)
        @test DiffFusion.state_variable(sim, 16.0 + 0.4/365, DiffFusion.LinearPathInterpolation) == ones(10, 5)
        #
        @test DiffFusion.state_variable(sim, -0.5, DiffFusion.LinearPathInterpolation) == zeros(10, 5)
        @test DiffFusion.state_variable(sim,  0.5, DiffFusion.LinearPathInterpolation) == 0.5 * ones(10, 5)
        @test DiffFusion.state_variable(sim,  0.5, DiffFusion.LinearPathInterpolation) == 0.5 * ones(10, 5)
        @test DiffFusion.state_variable(sim,  5.0, DiffFusion.LinearPathInterpolation) == 1.25 * ones(10, 5)
        @test DiffFusion.state_variable(sim, 16.5, DiffFusion.LinearPathInterpolation) == ones(10, 5)
    end

    @testset "Alias-based discount factors." begin
        p = DiffFusion.path(sim, ts, context)
        t = 2.0
        @test DiffFusion.discount(t, p.ts_dict, "USD") == exp(-0.03 * t)
        @test DiffFusion.discount(t, p.ts_dict, "EUR") == exp(-0.02 * t)
        @test DiffFusion.discount(t, p.ts_dict, "SXE50") == exp(-0.01 * t)
        @test isapprox(DiffFusion.discount(t, p.ts_dict, "EUR", "USD",   "+"), exp(-0.05 * t), atol=1.0e-15)
        @test isapprox(DiffFusion.discount(t, p.ts_dict, "USD", "SXE50", "+"), exp(-0.04 * t), atol=1.0e-15)
        @test isapprox(DiffFusion.discount(t, p.ts_dict, "USD", "EUR",   "-"), exp(-0.01 * t), atol=1.0e-15)
        @test isapprox(DiffFusion.discount(t, p.ts_dict, "SXE50", "USD", "-"), exp(+0.02 * t), atol=1.0e-15)
        #
        @test DiffFusion.discount(t, p.ts_dict, "EUR", nothing, "+") == exp(-0.02 * t)
        @test_throws AssertionError DiffFusion.discount(t, p.ts_dict, "EUR", "USD", "*")
        @test_throws AssertionError DiffFusion.discount(t, p.ts_dict, "EUR", "USD", nothing)
    end

    @testset "Stochastic model functions." begin
        p = DiffFusion.path(sim, ts, context)
        t = 2.0
        @test isapprox(DiffFusion.numeraire(p, t, "USD"), exp(1.0 + 0.03*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.numeraire(p, t, "USD:OIS"), exp(1.0 + 0.03*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.numeraire(p, t, "USD:OIS-OIS"), exp(1.0) * ones(5), atol=1.0e-15)
        #
        @test isapprox(DiffFusion.bank_account(p, t, "USD"), exp(1.0 + 0.03*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "EUR"), exp(1.0 + 0.02*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "SXE50"), exp(0.01*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "USD:NO"), exp(1.0 + 0.00*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "USD:OIS"), exp(1.0 + 0.03*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "USD:NO-OIS"), exp(1.0 - 0.03*t) * ones(5), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "USD:OIS+OIS"), exp(1.0 + 0.06*t) * ones(5), atol=5.0e-15)
        #
        @test_throws KeyError DiffFusion.bank_account(p, t, "GBP")
        @test_throws KeyError DiffFusion.bank_account(p, t, "USD:LIB")
        @test_throws KeyError DiffFusion.bank_account(p, t, "USD:OIS-LIB3M")
        #
        T = 5.0
        zb0 = DiffFusion.zero_bond(p, t, T, "USD:NO")
        @test isapprox(DiffFusion.zero_bond(p, t, T, "USD"), zb0 * exp(-0.03*(T-t)), atol=5.0e-15)
        @test isapprox(DiffFusion.zero_bond(p, t, T, "USD:OIS-OIS"), zb0, atol=5.0e-15)
        zb0 = DiffFusion.zero_bond(p, t, T, "EUR:NO")
        @test isapprox(DiffFusion.zero_bond(p, t, T, "EUR"), zb0 * exp(-0.02*(T-t)), atol=5.0e-15)
        @test isapprox(DiffFusion.zero_bond(p, t, T, "SXE50"), ones(5) * exp(-0.01*(T-t)), atol=5.0e-15)
        #
        dfT = DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "USD")
        @test size(dfT) == (5, 3)
        @test maximum(abs.(dfT[:,1] - DiffFusion.zero_bond(p, t, 4.0, "USD"))) < 1.0e-13
        @test maximum(abs.(dfT[:,2] - DiffFusion.zero_bond(p, t, 5.0, "USD"))) < 1.0e-13
        @test maximum(abs.(dfT[:,3] - DiffFusion.zero_bond(p, t, 6.0, "USD"))) < 1.0e-13
        dfT = DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "EUR")
        @test size(dfT) == (5, 3)
        @test maximum(abs.(dfT[:,1] - DiffFusion.zero_bond(p, t, 4.0, "EUR"))) < 1.0e-13
        @test maximum(abs.(dfT[:,2] - DiffFusion.zero_bond(p, t, 5.0, "EUR"))) < 1.0e-13
        @test maximum(abs.(dfT[:,3] - DiffFusion.zero_bond(p, t, 6.0, "EUR"))) < 1.0e-13
        #
        @test_nowarn DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "USD:OIS")
        @test_nowarn DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "USD:NO-OIS")
        @test_nowarn DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "USD:NO+OIS")
        #
        df1 = DiffFusion.zero_bond(p, 2.0, 5.0, "USD")
        df2 = DiffFusion.zero_bond(p, 2.0, 7.0, "USD")
        cmp = DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "USD")
        @test maximum(abs.(cmp - df1 ./ df2)) < 1.0e-13
        df1 = DiffFusion.zero_bond(p, 2.0, 5.0, "EUR")
        df2 = DiffFusion.zero_bond(p, 2.0, 7.0, "EUR")
        cmp = DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "EUR")
        @test maximum(abs.(cmp - df1 ./ df2)) < 1.0e-13
        #
        @test_nowarn DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "USD:OIS")
        @test_nowarn DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "USD:NO-OIS")
        @test_nowarn DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "USD:NO+OIS")
        #
        @test_throws KeyError DiffFusion.zero_bond(p, t, T, "GBP")
        @test_throws KeyError DiffFusion.zero_bond(p, t, T, "USD:LIB")
        @test_throws KeyError DiffFusion.zero_bond(p, t, T, "USD:OIS-LIB3M")
        @test_throws KeyError DiffFusion.zero_bond(p, t, T, "SXE50:OIS")
        #
        X = zeros(length(DiffFusion.state_alias(m)), n_paths, length(times))
        sim = DiffFusion.Simulation(m, times, X, nothing)  # simplify calculations
        p = DiffFusion.path(sim, ts, context)
        @test isapprox(DiffFusion.asset(p, t, "EUR-USD"), ones(5) * 1.25 * exp(0.01*t), atol=5.0e-15)
        @test isapprox(DiffFusion.asset(p, t, "SXE50"), ones(5) * 3750.00 * exp(0.01*t), atol=5.0e-15)
        #
        S_t = DiffFusion.asset(p, t, "EUR-USD")
        P_d = DiffFusion.zero_bond(p, t, T, "USD")
        P_f = DiffFusion.zero_bond(p, t, T, "EUR")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "EUR-USD"), S_t .* P_f ./ P_d, atol=5.0e-15)
        (S_t_, P_d_, P_f_) = DiffFusion.forward_asset_and_zero_bonds(p, t, T, "EUR-USD")
        @test isapprox(S_t_, S_t, atol=1.0e-14)
        @test isapprox(P_d_, P_d, atol=1.0e-14)
        @test isapprox(P_f_, P_f, atol=1.0e-14)
        #
        S_t = DiffFusion.asset(p, t, "SXE50")
        P_d = DiffFusion.zero_bond(p, t, T, "EUR")
        P_f = DiffFusion.zero_bond(p, t, T, "SXE50")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "SXE50"), S_t .* P_f ./ P_d, atol=5.0e-15)
        (S_t_, P_d_, P_f_) = DiffFusion.forward_asset_and_zero_bonds(p, t, T, "SXE50")
        @test isapprox(S_t_, S_t, atol=1.0e-11)
        @test isapprox(P_d_, P_d, atol=1.0e-14)
        @test isapprox(P_f_, P_f, atol=1.0e-14)
        #
        @test DiffFusion.fixing(p, -1.0, "SOFR") == 0.0123 * ones(5)
        @test DiffFusion.fixing(p,  0.0, "SOFR") == 0.0123 * ones(5)
        @test DiffFusion.fixing(p,  0.5, "SOFR") == 0.0123 * ones(5)
        #
        fwd_index_1 = DiffFusion.forward_index(p, 4.0, 5.0, "HICP")
        fwd_index_2 = DiffFusion.asset(p, 4.0, "HICP") .* DiffFusion.zero_bond(p, 4.0, 5.0, "EUR:NO") ./ DiffFusion.zero_bond(p, 4.0, 5.0, "USD:NO")
        @test isapprox(fwd_index_1, fwd_index_2, atol=5.0e-15)
        #
        @test DiffFusion.future_index(p, 4.0, 4.0, "NIK") == 23776.5 * ones(5)
        fut_idx = DiffFusion.future_index(p, 4.0, 8.0, "NIK")
        @test isapprox(fut_idx, 23840.87131543661 * ones(5), atol=1.0e-15)
        #
        SX = DiffFusion.model_state(DiffFusion.state_variable(p.sim, 1.0, DiffFusion.NoPathInterpolation), p.sim.model)
        v1 = DiffFusion.swap_rate_variance(p, 1.0, 4.0, [4.0, 5.0], [1.0], "EUR")
        v2 = DiffFusion.swap_rate_variance(p.sim.model, "EUR", p.ts_dict["EUR"], 1.0, 4.0, [4.0, 5.0], [1.0], SX)
        #
        v1 = DiffFusion.forward_rate_variance(p, 1.0, 4.0, 4.0, 5.0, "EUR")
        v2 = DiffFusion.forward_rate_variance(p.sim.model, "EUR", 1.0, 4.0, 4.0, 5.0)
        @test v1 == ones(5) * v2
        #
        #
        v1 = DiffFusion.asset_variance(p, 1.0, 4.0, "EUR-USD")
        v2 = DiffFusion.asset_variance(p.sim.model, "EUR-USD", "USD", "EUR", 1.0, 4.0, SX)
        @test v1 == ones(5) * v2
        #
        v1 = DiffFusion.asset_variance(p, 1.0, 4.0, "SXE50")
        v2 = DiffFusion.asset_variance(p.sim.model, "SXE50-EUR", "EUR", nothing, 1.0, 4.0, SX)
        @test v1 == ones(5) * v2
        #
        models = sim.model.models
        ca_path = DiffFusion.asset_convexity_adjustment(p, 5.0, 10.0, 15.0, 20.0, "EUR-USD")
        log_ca = DiffFusion.log_asset_convexity_adjustment(models[1], models[3], models[2], 5.0, 10.0, 15.0, 20.0)
        @test ca_path == exp(log_ca) * ones(5)
        #
        ca_path_index = DiffFusion.index_convexity_adjustment(p, 5.0, 10.0, 15.0, 20.0, "HICP")
        @test isapprox(ca_path_index, ca_path, atol=5.0e-15)
    end

    @testset "Deterministic modelling." begin
        det_context = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", nothing, Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", nothing, Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", nothing, Dict(_empty_key => "EUR"))),
                ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", nothing, nothing, nothing, "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("SXE50",   DiffFusion.AssetEntry("SXE50", nothing, nothing, nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}([
                ("HICP", DiffFusion.ForwardIndexEntry("EUR-USD-FWD", nothing, nothing, nothing, "EUR-USD-FWD")),
            ]),
            Dict{String, DiffFusion.FutureIndexEntry}([
                ("NIK", DiffFusion.FutureIndexEntry("NIK", nothing, "NIK-FUT")),
            ]),
            Dict{String, DiffFusion.FixingEntry}([
                ("SOFR", DiffFusion.FixingEntry("SOFR", "USD-SOFR-Fixings")),
            ]),
        )
        det_sim = DiffFusion.Simulation(m, zeros(0), zeros(0,1,0), nothing)
        p = DiffFusion.path(det_sim, ts, det_context)
        t = 2.0
        T = 5.0
        @test isapprox(DiffFusion.numeraire(p, t, "USD"), exp(0.03*t) * ones(1), atol=1.0e-15)
        #
        @test isapprox(DiffFusion.bank_account(p, t, "USD"), exp(0.03*t) * ones(1), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "EUR"), exp(0.02*t) * ones(1), atol=1.0e-15)
        @test isapprox(DiffFusion.bank_account(p, t, "SXE50"), exp(0.01*t) * ones(1), atol=1.0e-15)
        #
        @test isapprox(DiffFusion.zero_bond(p, t, T, "USD"), exp(-0.03*(T-t)) * ones(1), atol=5.0e-15)
        @test isapprox(DiffFusion.zero_bond(p, t, T, "EUR"), exp(-0.02*(T-t)) * ones(1), atol=5.0e-15)
        @test isapprox(DiffFusion.zero_bond(p, t, T, "SXE50"), exp(-0.01*(T-t)) * ones(1), atol=5.0e-15)
        #
        dfT = DiffFusion.zero_bonds(p, t, [4.0, 5.0, 6.0], "USD")
        @test size(dfT) == (1, 3)
        @test maximum(abs.(dfT[:,1] - DiffFusion.zero_bond(p, t, 4.0, "USD"))) < 1.0e-13
        @test maximum(abs.(dfT[:,2] - DiffFusion.zero_bond(p, t, 5.0, "USD"))) < 1.0e-13
        @test maximum(abs.(dfT[:,3] - DiffFusion.zero_bond(p, t, 6.0, "USD"))) < 1.0e-13
        #
        df1 = DiffFusion.zero_bond(p, 2.0, 5.0, "USD")
        df2 = DiffFusion.zero_bond(p, 2.0, 7.0, "USD")
        cmp = DiffFusion.compounding_factor(p, 2.0, 5.0, 7.0, "USD")
        @test maximum(abs.(cmp - df1 ./ df2)) < 1.0e-13
        #
        @test isapprox(DiffFusion.asset(p, t, "EUR-USD"), 1.25 * exp(0.01*t) * ones(1), atol=5.0e-15)
        @test isapprox(DiffFusion.asset(p, t, "SXE50"), 3750.00 * exp(0.01*t) * ones(1), atol=5.0e-15)
        #
        @test isapprox(DiffFusion.forward_asset(p, t, T, "EUR-USD"), 1.25 * exp(0.01*T) * ones(1), atol=5.0e-15)
        @test isapprox(DiffFusion.forward_asset(p, t, T, "SXE50"), 3750.00 * exp(0.01*T) * ones(1), atol=5.0e-15)
        #
        (S_t_, P_d_, P_f_) = DiffFusion.forward_asset_and_zero_bonds(p, t, T, "EUR-USD")
        S_T = DiffFusion.forward_asset(p, t, T, "EUR-USD")
        @test isapprox(S_t_ .* P_f_ ./ P_d_, S_T, atol=1.0e-14)
        #
        (S_t_, P_d_, P_f_) = DiffFusion.forward_asset_and_zero_bonds(p, t, T, "SXE50")
        S_T = DiffFusion.forward_asset(p, t, T, "SXE50")
        @test isapprox(S_t_ .* P_f_ ./ P_d_, S_T, atol=1.0e-12)
        #
        @test isapprox(DiffFusion.forward_index(p, 4.0, 5.0, "HICP"), 1.25 * ones(1), atol=5.0e-15)
        #
        @test isapprox(DiffFusion.future_index(p, 4.0, 5.0, "NIK"), 23776.5 * ones(1), atol=5.0e-15)
        #
        @test DiffFusion.fixing(p, -1.0, "SOFR") == 0.0123 * ones(1)
        #
        @test DiffFusion.swap_rate_variance(p, 1.0, 2.0, [2.0, 3.0], [1.0], "EUR") == zeros(1)
        @test DiffFusion.forward_rate_variance(p, 1.0, 2.0, 2.0, 3.0, "USD") == zeros(1)
        @test DiffFusion.asset_variance(p, 1.0, 2.0, "EUR-USD") == zeros(1)
    end

    @testset "Forward asset special cases." begin
        t = 2.0
        T = 5.0
        #
        context = DiffFusion.Context("Std",
            DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
            Dict{String, DiffFusion.RatesEntry}([
                ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD"))),
                ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR"))),
                #
                ("USD_NULL",   DiffFusion.RatesEntry("USD", nothing, Dict(_empty_key => "USD"))),
                ("EUR_NULL",   DiffFusion.RatesEntry("EUR", nothing, Dict(_empty_key => "EUR"))),
            ]),
            Dict{String, DiffFusion.AssetEntry}([
                ("DK_MODEL", DiffFusion.AssetEntry("EUR-USD", nothing, "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("ST_DIV_1", DiffFusion.AssetEntry("EUR-USD", nothing, nothing, "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("ST_DIV_2", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", nothing, "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
                ("RATES", DiffFusion.AssetEntry("EUR-USD", nothing, "USD", nothing, "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
            ]),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        p = DiffFusion.path(sim, ts, context)
        #
        S_t = DiffFusion.asset(p, t, "DK_MODEL")
        P_d = DiffFusion.zero_bond(p, t, T, "USD")
        P_f = DiffFusion.zero_bond(p, t, T, "EUR")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "DK_MODEL"), S_t .* P_f ./ P_d, atol=5.0e-15)
        #
        S_t = DiffFusion.asset(p, t, "ST_DIV_1")
        P_d = DiffFusion.zero_bond(p, t, T, "USD_NULL")
        P_f = DiffFusion.zero_bond(p, t, T, "EUR")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "ST_DIV_1"), S_t .* P_f ./ P_d, atol=5.0e-15)
        #
        S_t = DiffFusion.asset(p, t, "ST_DIV_2")
        P_d = DiffFusion.zero_bond(p, t, T, "USD_NULL")
        P_f = DiffFusion.zero_bond(p, t, T, "EUR")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "ST_DIV_2"), S_t .* P_f ./ P_d, atol=5.0e-15)
        #
        S_t = DiffFusion.asset(p, t, "RATES")
        P_d = DiffFusion.zero_bond(p, t, T, "USD")
        P_f = DiffFusion.zero_bond(p, t, T, "EUR_NULL")
        @test isapprox(DiffFusion.forward_asset(p, t, T, "RATES"), S_t .* P_f ./ P_d, atol=5.0e-15)
    end
end
