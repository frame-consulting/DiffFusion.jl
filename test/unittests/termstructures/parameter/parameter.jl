using DiffFusion
using Test

@testset "Parameter term structures." begin

    @testset "BackwardFlatParameter" begin
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50.  60.  70.  80. ;
                   50.  50.  50.  50. ;
                   30.  20.  20.  40. ] * 1e-4
        ts = DiffFusion.backward_flat_parameter("MR", times, values)
        #
        @test DiffFusion.alias(ts) == "MR"
        @test DiffFusion.time_idx(ts, 0.0) == 1
        @test DiffFusion.time_idx(ts, 0.5) == 1
        @test DiffFusion.time_idx(ts, 1.0) == 1
        @test DiffFusion.time_idx(ts, 1.1) == 2
        @test DiffFusion.time_idx(ts, 10.0) == 4
        @test DiffFusion.time_idx(ts, 10.5) == 5
        #
        @test DiffFusion.value(ts, 0.0) == [ 50., 50., 30., ] * 1e-4
        @test DiffFusion.value(ts, 1.0) == [ 50., 50., 30., ] * 1e-4
        @test DiffFusion.value(ts, 1.5) == [ 60., 50., 20., ] * 1e-4
        @test DiffFusion.value(ts, 10.0) == [ 80., 50., 40., ] * 1e-4
        @test DiffFusion.value(ts, 12.0) == [ 80., 50., 40., ] * 1e-4
        #
        @test_throws AssertionError DiffFusion.value(ts, 1.5, DiffFusion.TermstructureScalar)
        @test_throws AssertionError DiffFusion.backward_flat_parameter("MR", times[2:end], values)
        @test_throws AssertionError DiffFusion.backward_flat_parameter("MR", vcat([2.0], times[2:end]), values)
        #
        @test ts(1.5) == [ 60., 50., 20., ] * 1e-4
    end

    @testset "ForwardFlatParameter" begin
        times =  [  -1.,  0.,  1., 2.  ]
        values = [  50., 60., 70., 80. ]
        ts = DiffFusion.forward_flat_parameter("Idx", times, values)
        #
        @test DiffFusion.alias(ts) == "Idx"
        @test DiffFusion.time_idx(ts, -1.5) == 0
        @test DiffFusion.time_idx(ts, -1.0) == 1
        @test DiffFusion.time_idx(ts, -0.5) == 1
        @test DiffFusion.time_idx(ts, -0.0) == 1 # ! Attention !
        @test DiffFusion.time_idx(ts,  0.0) == 2
        @test DiffFusion.time_idx(ts,  1.5) == 3
        @test DiffFusion.time_idx(ts,  3.5) == 4
        #
        @test DiffFusion.value(ts, -2.0) == [ 50., ]
        @test DiffFusion.value(ts, -1.0) == [ 50., ]
        @test DiffFusion.value(ts, -0.5) == [ 50., ]
        @test DiffFusion.value(ts,  0.0) == [ 60., ]
        @test DiffFusion.value(ts,  3.0) == [ 80., ]
        #
        @test DiffFusion.value(ts, 1.5, DiffFusion.TermstructureScalar) == 70.
        @test ts(1.5) == [ 70., ]
        #
        @test_throws AssertionError DiffFusion.forward_flat_parameter("MR", times[2:end], values)
        @test_throws AssertionError DiffFusion.forward_flat_parameter("MR", vcat([2.0], times[2:end]), values)
        #
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50.  60.  70.  80. ;
                   50.  50.  50.  50. ;
                   30.  20.  20.  40. ]
        ts = DiffFusion.forward_flat_parameter("Std", times, values)
        @test ts(1.5) == [ 50., 50., 30.]
    end

    @testset "Scalar parameter" begin
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50., 60., 70., 80. ] * 1.0e-4
        ts = DiffFusion.backward_flat_parameter("MR", times, values)
        #
        @test DiffFusion.alias(ts) == "MR"
        @test DiffFusion.value(ts, 1.5) == [ 60. ] * 1e-4
        @test DiffFusion.value(ts, 1.5, DiffFusion.TermstructureScalar) == 60. * 1e-4
        #
        @test ts(1.5) == [ 60. ] * 1e-4
        @test ts(1.5, DiffFusion.TermstructureScalar) == 60. * 1e-4
    end

    @testset "Flat parameter" begin
        ts = DiffFusion.flat_parameter("MR", 35. * 1e-4)
        #
        @test DiffFusion.alias(ts) == "MR"
        @test DiffFusion.value(ts) == [ 35. ] * 1e-4
        @test DiffFusion.value(ts, DiffFusion.TermstructureScalar) == 35. * 1e-4
        @test DiffFusion.value(ts, 1.5) == [ 35. ] * 1e-4
        @test DiffFusion.value(ts, 1.5, DiffFusion.TermstructureScalar) == 35. * 1e-4
        #
        @test ts() == [ 35. ] * 1e-4
        @test ts(DiffFusion.TermstructureScalar) == 35. * 1e-4
        @test ts(1.5) == [ 35. ] * 1e-4
        @test ts(1.5, DiffFusion.TermstructureScalar) == 35. * 1e-4
        #
        ts_simple = DiffFusion.flat_parameter(35. * 1e-4)
        @test DiffFusion.alias(ts_simple) == ""
        @test ts() == [ 35. ] * 1e-4
    end

end
