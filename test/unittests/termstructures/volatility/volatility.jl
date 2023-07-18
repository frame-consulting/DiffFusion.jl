using DiffFusion
using Test

@testset "Volatility term structures." begin

    @testset "BackwardFlatVolatility" begin
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50.  60.  70.  80. ;
                   50.  50.  50.  50. ;
                   30.  20.  20.  40. ] * 1e-4
        ts = DiffFusion.backward_flat_volatility("USD", times, values)
        #
        @test DiffFusion.alias(ts) == "USD"
        @test DiffFusion.time_idx(ts, 0.0) == 1
        @test DiffFusion.time_idx(ts, 0.5) == 1
        @test DiffFusion.time_idx(ts, 1.0) == 1
        @test DiffFusion.time_idx(ts, 1.1) == 2
        @test DiffFusion.time_idx(ts, 10.0) == 4
        @test DiffFusion.time_idx(ts, 10.5) == 5
        #
        @test DiffFusion.volatility(ts, 0.0) == [ 50., 50., 30., ] * 1e-4
        @test DiffFusion.volatility(ts, 1.0) == [ 50., 50., 30., ] * 1e-4
        @test DiffFusion.volatility(ts, 1.5) == [ 60., 50., 20., ] * 1e-4
        @test DiffFusion.volatility(ts, 10.0) == [ 80., 50., 40., ] * 1e-4
        @test DiffFusion.volatility(ts, 12.0) == [ 80., 50., 40., ] * 1e-4
        #
        @test_throws AssertionError DiffFusion.volatility(ts, 1.5, DiffFusion.TermstructureScalar)
        @test_throws AssertionError DiffFusion.backward_flat_volatility("USD", times[2:end], values)
        @test_throws AssertionError DiffFusion.backward_flat_volatility("USD", vcat([2.0], times[2:end]), values)
        #
        @test ts(1.5) == [ 60., 50., 20., ] * 1e-4
    end

    @testset "Scalar volatility" begin
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50., 60., 70., 80. ] * 1.0e-4
        ts = DiffFusion.backward_flat_volatility("USD", times, values)
        #
        @test DiffFusion.alias(ts) == "USD"
        @test DiffFusion.volatility(ts, 1.5) == [ 60. ] * 1e-4
        @test DiffFusion.volatility(ts, 1.5, DiffFusion.TermstructureScalar) == 60. * 1e-4
        #
        @test ts(1.5) == [ 60. ] * 1e-4
        @test ts(1.5, DiffFusion.TermstructureScalar) == 60. * 1e-4
    end

    @testset "Flat volatility" begin
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50., 60., 70., 80. ] * 1.0e-4
        ts = DiffFusion.flat_volatility("USD", 35. * 1e-4)
        #
        @test DiffFusion.alias(ts) == "USD"
        @test DiffFusion.volatility(ts, 1.5) == [ 35. ] * 1e-4
        @test DiffFusion.volatility(ts, 1.5, DiffFusion.TermstructureScalar) == 35. * 1e-4
        #
        @test ts(1.5) == [ 35. ] * 1e-4
        @test ts(1.5, DiffFusion.TermstructureScalar) == 35. * 1e-4
        #
        @test string(DiffFusion.flat_volatility( 0.01 )) == string(DiffFusion.flat_volatility("", 0.01))
    end

end
