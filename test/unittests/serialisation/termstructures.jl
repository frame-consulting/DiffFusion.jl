using DiffFusion
using OrderedCollections
using Test

@testset "Serialise and de-serialise term structures." begin

    @testset "Termstructure serialisation." begin
        d = DiffFusion.serialise(DiffFusion.flat_forward("USD", 0.03))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
            "alias" => "USD",
            "rate" => 0.03
        )
        #
        d = DiffFusion.serialise(DiffFusion.zero_curve("USD", [0.0, 10.0], [0.02, 0.03]))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.ZeroCurve",
            "constructor" => "zero_curve",
            "alias" => "USD",
            "times" => [0.0, 10.0],
            "values" => [0.02, 0.03]
        )
        #
        d = DiffFusion.serialise(DiffFusion.linear_zero_curve("USD", [0.0, 10.0], [0.02, 0.03]))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.LinearZeroCurve",
            "constructor" => "LinearZeroCurve",
            "alias" => "USD",
            "times" => [0.0, 10.0],
            "values" => [0.02, 0.03]
        )
        #
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50.  60.  70.  80. ;
                   50.  50.  50.  50. ;
                   30.  20.  20.  40. ]
        #
        d = DiffFusion.serialise(DiffFusion.backward_flat_volatility("USD", times, values))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatVolatility",
            "constructor" => "BackwardFlatVolatility",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        #
        d = DiffFusion.serialise(DiffFusion.backward_flat_parameter("USD", times, values))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatParameter",
            "constructor" => "BackwardFlatParameter",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        #
        d = DiffFusion.serialise(DiffFusion.forward_flat_parameter("USD", times, values))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.ForwardFlatParameter",
            "constructor" => "ForwardFlatParameter",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        #
        d = DiffFusion.serialise(DiffFusion.flat_parameter("USD", 0.05))
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatParameter",
            "constructor" => "BackwardFlatParameter",
            "alias" => "USD",
            "times" => [0.0],
            "values" => [[0.05]],
        )
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "EUR", "USD", 0.5)
        DiffFusion.set_correlation!(ch, "EUR", "EUR-USD", -0.3)
        DiffFusion.set_correlation!(ch, "USD", "EUR-USD", -0.4)
        d = DiffFusion.serialise(ch)
        @test d == OrderedDict{String, Any}(
            "typename" => "DiffFusion.CorrelationHolder",
            "constructor" => "CorrelationHolder",
            "alias" => "Std",
            "correlations" => OrderedDict{String, Any}(
                "EUR-USD<>USD" => -0.4,
                "EUR<>USD" => 0.5,
                "EUR<>EUR-USD" => -0.3
            ),
            "sep" => "<>",
        )
        #println(d)
    end

    @testset "Termstructure de-serialisation." begin
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
            "alias" => "USD",
            "rate" => 0.03
        )
        @test DiffFusion.deserialise(d) == DiffFusion.flat_forward("USD", 0.03)
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.ZeroCurve",
            "constructor" => "zero_curve",
            "alias" => "USD",
            "times" => [0.0, 10.0],
            "values" => [0.02, 0.03]
        )
        @test string(DiffFusion.deserialise(d)) == string(DiffFusion.zero_curve("USD", [0.0, 10.0], [0.02, 0.03]))
        #
        times =  [  1.,  2.,  5., 10. ]
        values = [ 50.  60.  70.  80. ;
                   50.  50.  50.  50. ;
                   30.  20.  20.  40. ]
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatVolatility",
            "constructor" => "BackwardFlatVolatility",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        @test string(DiffFusion.deserialise(d)) == string(DiffFusion.backward_flat_volatility("USD", times, values))
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatParameter",
            "constructor" => "BackwardFlatParameter",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        @test string(DiffFusion.deserialise(d)) == string(DiffFusion.backward_flat_parameter("USD", times, values))
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.ForwardFlatParameter",
            "constructor" => "ForwardFlatParameter",
            "alias" => "USD",
            "times" => [1.0, 2.0, 5.0, 10.0],
            "values" => [
                [50.0, 60.0, 70.0, 80.0],
                [50.0, 50.0, 50.0, 50.0],
                [30.0, 20.0, 20.0, 40.0]],
            )
        @test string(DiffFusion.deserialise(d)) == string(DiffFusion.forward_flat_parameter("USD", times, values))
        #
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.BackwardFlatParameter",
            "constructor" => "BackwardFlatParameter",
            "alias" => "USD",
            "times" => [0.0],
            "values" => [[0.05]],
        )
        @test string(DiffFusion.deserialise(d)) == string(DiffFusion.flat_parameter("USD", 0.05))
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "EUR", "USD", 0.5)
        DiffFusion.set_correlation!(ch, "EUR", "EUR-USD", -0.3)
        DiffFusion.set_correlation!(ch, "USD", "EUR-USD", -0.4)
        d = OrderedDict{String, Any}(
            "typename" => "DiffFusion.CorrelationHolder",
            "constructor" => "CorrelationHolder",
            "alias" => "Std",
            "correlations" => OrderedDict{String, Any}(
                "EUR-USD<>USD" => -0.4,
                "EUR<>USD" => 0.5,
                "EUR<>EUR-USD" => -0.3
            ),
            "sep" => "<>",
        )
        @test string(DiffFusion.deserialise(d)) == string(ch)
        # println(deserialise(d))
    end


end
