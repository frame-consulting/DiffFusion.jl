using DiffFusion
using Test

using Interpolations


@testset "Yield curves for discount factor calculation." begin

    @testset "FlatForward" begin
        ts = DiffFusion.flat_forward("USD", 0.03)
        #
        @test DiffFusion.alias(ts) == "USD"
        @test DiffFusion.discount(ts, 2.0) == exp(-0.06)
        @test isapprox( DiffFusion.zero_rate(ts, 1.0, 3.0), 0.03, atol=1.0e-16 )
        @test isapprox( DiffFusion.forward_rate(ts, 2.0),   0.03, atol=2.8e-11 )
        #
        ts2 = DiffFusion.flat_forward(0.01)
        @test DiffFusion.alias(ts2) == ""
        @test ts2.rate == 0.01
        #
        @test ts(2.0) == exp(-0.06)
    end

    @testset "ZeroCurve with linear interpolation." begin
        times  = [1.0, 3.0, 6.0, 10.0]
        values = [1.0, 1.0, 2.0,  3.0] .* 1e-2
        ts = DiffFusion.zero_curve("EUR", times, values)
        #
        @test DiffFusion.alias(ts) == "EUR"
        @test DiffFusion.discount(ts, 0.0) == 1.0
        @test DiffFusion.discount(ts, 0.5) == exp(-0.5*0.01)
        @test DiffFusion.discount(ts, 2.0) == exp(-2.0*0.01)
        @test DiffFusion.discount(ts, 4.5) == exp(-4.5*0.015)
        @test DiffFusion.discount(ts, 10.0) == exp(-10.0*0.03)
        @test isapprox(DiffFusion.discount(ts, 12.0), exp(-12.0*0.035), atol=1.2e-16)
        #
        @test isapprox( DiffFusion.zero_rate(ts, 4.5), 0.015, atol=1.0e-16)
        @test isapprox( DiffFusion.zero_rate(ts, 0.5, 4.5), (4.5*0.015 - 0.5*0.01)/4.0, atol=1.0e-16)
        #
        @test ts(4.5) == exp(-4.5*0.015)
        #
        # zero curve without alias
        ts2 = DiffFusion.zero_curve(times, values)
        @test DiffFusion.alias(ts2) == ""
        @test DiffFusion.discount(ts2, 0.0) == 1.0
        @test DiffFusion.discount(ts2, 0.5) == exp(-0.5*0.01)
        @test DiffFusion.discount(ts2, 2.0) == exp(-2.0*0.01)
        @test DiffFusion.discount(ts2, 4.5) == exp(-4.5*0.015)
        @test DiffFusion.discount(ts2, 10.0) == exp(-10.0*0.03)
    end

    @testset "LinearZeroCurve." begin
        #
        times  = [1.0, 3.0, 6.0, 10.0]
        values = [1.0, 1.0, 2.0,  3.0] .* 1e-2
        #
        @test DiffFusion.alias(DiffFusion.linear_zero_curve("Std", times, values)) == "Std"
        #
        ts_tst = DiffFusion.linear_zero_curve(times, values)
        # test correct interpolation
        ts_ref = DiffFusion.zero_curve(times, values)
        _times = 1.0:0.5:10.0
        for t in _times
            @test DiffFusion.discount(ts_tst, t) == DiffFusion.discount(ts_ref, t)
        end
        # test left flat extrapolation
        ts_ref = DiffFusion.flat_forward(0.01)
        _times = 0.0:0.5:1.0
        for t in _times
            @test DiffFusion.discount(ts_tst, t) == DiffFusion.discount(ts_ref, t)
        end
        # test right flat extrapolation
        ts_ref = DiffFusion.flat_forward(0.03)
        _times = 10.0:0.5:11.0
        for t in _times
            @test DiffFusion.discount(ts_tst, t) == DiffFusion.discount(ts_ref, t)
        end
    end

    @testset "Test alias-based interpolated zero curves." begin
        times =   [ 1.0,   2.0,   3.0,   5.0,   7.0,  10.0,  15.0,  20.0,  30.0  ]
        values =  [ 3.61,  3.62,  3.43,  3.17,  3.07,  3.04,  3.06,  2.92,  2.59 ] * 1.0e-2
        methods = [ "linear", "cubic", "akima", "fritschcarlson", "fritschbutland", "steffen" ]
        ts = [
            DiffFusion.zero_curve(times, values, m)
            for m in methods
        ]
        i_times = 0.0:0.1:20.0
        i_values = hcat((
            [ DiffFusion.forward_rate(ts_, t) for t in i_times ]
            for ts_ in ts
        )...)
        Δf = i_values .- i_values[:,1]
        @test max(abs.(Δf)...) < 4.0e-3
    end

end
