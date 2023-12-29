
using DiffFusion

using Test

@testset "Test rates option payoffs." begin

    delta = DiffFusion.flat_parameter(1.0)
    chi = DiffFusion.flat_parameter(0.000001)
    sigma = DiffFusion.flat_volatility(0.01)
    ch = DiffFusion.correlation_holder("Std")
    model = DiffFusion.gaussian_hjm_model("mdl/EUR", delta, chi, sigma, ch, nothing)
    #
    sim = DiffFusion.simple_simulation(model, ch, [0.0], 3, with_progress_bar = false)
    #
    ts = [
        DiffFusion.flat_forward("yc/EUR", 0.00)
        DiffFusion.flat_forward("yc/EUR2", 0.02)
    ]
    #
    ctx = DiffFusion.context(
        "Std",
        DiffFusion.numeraire_entry("EUR", "mdl/EUR", "yc/EUR"),
        [
            DiffFusion.rates_entry("EUR", "mdl/EUR",
                Dict(
                    DiffFusion._empty_context_key => "yc/EUR",
                    "6M" => "yc/EUR2"
                ),
            ),
        ],
    )
    path = DiffFusion.path(sim, ts, ctx, DiffFusion.LinearPathInterpolation)
    
    @testset "Test Libor Optionlet" begin
        L = DiffFusion.LiborRate(1.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.03)
        @test_throws AssertionError DiffFusion.Optionlet(0.0, 2.0, L, K, +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, DiffFusion.ZeroBond(2.0, 5.0, "EUR"), +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, K, +1.0, DiffFusion.ZeroBond(2.0, 5.0, "EUR"))
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 3.0, L, K, +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, K, +2.0)
        Cp = DiffFusion.Optionlet(1.0, 2.0, L, K, 1.0)
        Cp2 = DiffFusion.Optionlet(1.0, 2.0, L, K, 1.0, DiffFusion.ScalarValue(1.0))
        @test Cp === Cp2
        @test DiffFusion.obs_time(Cp) == 1.0
        @test DiffFusion.obs_times(Cp) == Set([0.0, 1.0])
        @test string(Cp) == "Caplet(L(EUR, 1.00; 2.00, 3.00), 0.0300; 2.00)"
        #
        # intrinsic call value
        L = DiffFusion.LiborRate(2.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(-0.01)
        Cp = DiffFusion.Optionlet(2.0, 2.0, L, K, 1.0)
        @test isapprox(DiffFusion.at(Cp, path), 0.0101 * ones(3), atol=1.0e-8)  # small deviation from 0.01 due to y(t) impact
        #
        # ATM call option
        L = DiffFusion.LiborRate(0.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(-0.00)
        Cp = DiffFusion.Optionlet(0.0, 2.0, L, K, 1.0)
        v_call = DiffFusion.bachelier_price(0.0, 0.0, 0.01*sqrt(2.0), +1.0)
        @test isapprox(Cp(path), v_call*ones(3), atol=1.0e-7)
        #
        # inrinsic put value
        L = DiffFusion.LiborRate(2.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.02)
        Fl = DiffFusion.Optionlet(2.0, 2.0, L, K, -1.0)
        @test isapprox(DiffFusion.at(Fl, path), 0.0199 * ones(3), atol=1.0e-8)  # small deviation from 0.01 due to y(t) impact
        @test string(Fl) == "Floorlet(L(EUR, 2.00; 2.00, 3.00), 0.0200; 2.00)"
        #
        # put option
        L = DiffFusion.LiborRate(0.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.01)
        Fl = DiffFusion.Optionlet(0.0, 2.0, L, K, -1.0)
        v_put = DiffFusion.bachelier_price(0.01, 0.00, 0.01*sqrt(2.0), -1.0)
        @test isapprox(Fl(path), v_put*ones(3), atol=1.0e-4)  # ITM match is less good
        #
        # call-put parity
        L = DiffFusion.LiborRate(1.0, 3.0, 4.0, "EUR")
        K = DiffFusion.Fixed(0.01)
        Cp = DiffFusion.Optionlet(1.0, 3.0, L, K, +1.0)
        Fl = DiffFusion.Optionlet(1.0, 3.0, L, K, -1.0)
        V = (Cp - Fl) - (L - K)
        @test isapprox(V(path), zeros(3), atol=1.0e-14)
    end

    @testset "Test OIS Optionlet" begin
        L = DiffFusion.CompoundedRate(1.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.03)
        @test_throws AssertionError DiffFusion.Optionlet(0.0, 2.0, L, K, +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, DiffFusion.ZeroBond(2.0, 5.0, "EUR"), +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, K, +1.0, DiffFusion.ZeroBond(2.0, 5.0, "EUR"))
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 2.0, L, K, +1.0)
        @test_throws AssertionError DiffFusion.Optionlet(1.0, 3.0, L, K, +2.0)
        Cp = DiffFusion.Optionlet(1.0, 3.0, L, K, 1.0)
        Cp2 = DiffFusion.Optionlet(1.0, 3.0, L, K, 1.0, DiffFusion.ScalarValue(1.0))
        @test Cp === Cp2
        @test DiffFusion.obs_time(Cp) == 1.0
        @test DiffFusion.obs_times(Cp) == Set([0.0, 1.0])
        @test string(Cp) == "Caplet(R(EUR, 1.00; 2.00, 3.00), 0.0300; 3.00)"
        #
        # intrinsic call value
        L = DiffFusion.CompoundedRate(3.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(-0.01)
        Cp = DiffFusion.Optionlet(3.0, 3.0, L, K, 1.0)
        @test isapprox(Cp(path), 0.01*ones(3), atol=1.0e-14)
        #
        # ATM call option
        L = DiffFusion.CompoundedRate(0.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.00)
        Cp = DiffFusion.Optionlet(0.0, 3.0, L, K, 1.0)
        v_call = DiffFusion.bachelier_price(0.0, 0.0, 0.01*sqrt(2.0+1.0/3.0), +1.0)
        @test isapprox(Cp(path), v_call*ones(3), atol=1.0e-6)
        #
        # intrinsic put value
        L = DiffFusion.CompoundedRate(3.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.02)
        Fl = DiffFusion.Optionlet(3.0, 3.0, L, K, -1.0)
        @test isapprox(Fl(path), 0.02*ones(3), atol=1.0e-14)
        #
        # put option
        L = DiffFusion.CompoundedRate(0.0, 2.0, 3.0, "EUR")
        K = DiffFusion.Fixed(0.01)
        Fl = DiffFusion.Optionlet(0.0, 3.0, L, K, -1.0)
        v_put = DiffFusion.bachelier_price(0.01, 0.00, 0.01*sqrt(2.0+1.0/3.0), -1.0)
        @test isapprox(Fl(path), v_put*ones(3), atol=1.0e-4)  # ITM match is less good
        #
        # call-put parity
        L = DiffFusion.CompoundedRate(1.0, 3.0, 4.0, "EUR")
        K = DiffFusion.Fixed(0.01)
        Cp = DiffFusion.Optionlet(1.0, 4.0, L, K, +1.0)
        Fl = DiffFusion.Optionlet(1.0, 4.0, L, K, -1.0)
        V = (Cp - Fl) - (L - K)
        @test isapprox(V(path), zeros(3), atol=1.0e-14)
        # Forward-backward inequality
        L = DiffFusion.LiborRate(1.0, 3.0, 4.0, "EUR")
        K = DiffFusion.Fixed(0.01)
        Cp_L = DiffFusion.Optionlet(1.0, 3.0, L, K, +1.0)
        Fl_L = DiffFusion.Optionlet(1.0, 3.0, L, K, -1.0)
        @test all(Cp(path) .≥ Cp_L(path))
        @test all(Fl(path) .≥ Fl_L(path))
    end

    @testset "Test Libor swaption." begin
        obs_time = 1.0
        expiry_time = 2.0
        rates = [
            DiffFusion.LiborRate(1.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(1.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        fixed_times = [2.0, 3.0, 4.0]
        fixed_weights = [1.0, 1.0]
        fixed_rate = 0.0
        swpt = DiffFusion.Swaption(
            obs_time,
            expiry_time,
            expiry_time,
            rates,
            fixed_times,
            fixed_weights,
            fixed_rate,
            +1,
            "EUR",
        )
        @test DiffFusion.obs_time(swpt) == 1.0
        @test DiffFusion.obs_times(swpt) == Set(1.0)
        @test string(swpt) == "Swaption_Pay([L(EUR, 1.00; 2.00, 3.00),...,L(EUR, 1.00; 3.00, 4.00)], 0.0000, EUR; 2.00)"
        #
        # intrinsic call value
        rates = [
            DiffFusion.LiborRate(0.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(0.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        swpt = DiffFusion.Swaption(0.0, 0.0, 0.0, rates, fixed_times, fixed_weights, -0.02, +1, "EUR",)
        @test swpt(path) == 0.04 * ones(3)
        #
        # ATM call option
        rates = [
            DiffFusion.LiborRate(0.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(0.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        swpt = DiffFusion.Swaption(0.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.00, +1, "EUR",)
        v_call = 2.0 * DiffFusion.bachelier_price(0.0, 0.0, 0.01*sqrt(2.0), +1.0)
        @test isapprox(swpt(path), v_call*ones(3), atol=1.0e-5)
        #
        # intrinsic put value
        rates = [
            DiffFusion.LiborRate(2.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(2.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        swpt = DiffFusion.Swaption(2.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, -1, "EUR",)
        @test isapprox(swpt(path), (2*0.01 - 0.0004)*ones(3), atol=1.0e-5)
        #
        # put option
        rates = [
            DiffFusion.LiborRate(1.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(1.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        swpt = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, -1, "EUR",)
        v_put = 2.0 * DiffFusion.bachelier_price(0.01, 0.0, 0.01*sqrt(1.0), -1.0)
        @test isapprox(swpt(path), v_put*ones(3), atol=1.0e-3)
        #
        # call-put parity
        rates = [
            DiffFusion.LiborRate(1.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.LiborRate(1.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        pay = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, +1, "EUR",)
        rec = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, -1, "EUR",)
        cp = pay - rec
        fl = rates[1] * DiffFusion.ZeroBond(1.0, 3.0, "EUR") + rates[2] * DiffFusion.ZeroBond(1.0, 4.0, "EUR")
        an = DiffFusion.ZeroBond(1.0, 3.0, "EUR") + DiffFusion.ZeroBond(1.0, 4.0, "EUR")
        df = DiffFusion.ZeroBond(1.0, 2.0, "EUR")
        sw = (fl - 0.01 * an) / df
        V  = cp - sw
        @test isapprox(V(path), zeros(3), atol=1.0e-14)
    end

    @testset "Test OIS swaption." begin
        obs_time = 1.0
        expiry_time = 2.0
        rates = [
            DiffFusion.CompoundedRate(1.0, 2.0, 3.0, 1.0, "EUR"),
            DiffFusion.CompoundedRate(1.0, 3.0, 4.0, 1.0, "EUR"),
        ]
        fixed_times = [2.0, 3.0, 4.0]
        fixed_weights = [1.0, 1.0]
        fixed_rate = 0.0
        swpt = DiffFusion.Swaption(
            obs_time,
            expiry_time,
            expiry_time,
            rates,
            fixed_times,
            fixed_weights,
            fixed_rate,
            +1,
            "EUR",
        )
        @test DiffFusion.obs_time(swpt) == 1.0
        @test DiffFusion.obs_times(swpt) == Set(1.0)
        @test string(swpt) == "Swaption_Pay([R(EUR, 1.00; 2.00, 3.00),...,R(EUR, 1.00; 3.00, 4.00)], 0.0000, EUR; 2.00)"
        #
        # test equivalence to Libor swaption
        rates = [
            DiffFusion.LiborRate(1.0, 2.0, 3.0, 1.0, "EUR:6M"),
            DiffFusion.LiborRate(1.0, 3.0, 4.0, 1.0, "EUR:6M"),
        ]
        pay_L = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, +1, "EUR",)
        rec_L = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, -1, "EUR",)
        rates = [
            DiffFusion.CompoundedRate(1.0, 2.0, 3.0, 1.0, "EUR:6M"),
            DiffFusion.CompoundedRate(1.0, 3.0, 4.0, 1.0, "EUR:6M"),
        ]
        pay_C = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, +1, "EUR",)
        rec_C = DiffFusion.Swaption(1.0, 2.0, 2.0, rates, fixed_times, fixed_weights, 0.01, -1, "EUR",)
        #
        @test pay_C(path) == pay_L(path)
        @test rec_C(path) == rec_L(path)
    end

end
