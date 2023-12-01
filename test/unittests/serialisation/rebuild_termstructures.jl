using DiffFusion
using Test
using OrderedCollections

@testset "Extract term structures and rebuild term structure dictionary." begin

    @testset "Extract and rebuild" begin
        delim = DiffFusion._split_alias_identifyer
        ts_vector = [
            DiffFusion.flat_forward("yc/flat_forward", 0.01),
            DiffFusion.zero_curve("yc/zero_curve", [ 1.0, 10.0 ], [ 0.02, 0.03 ]),
            DiffFusion.linear_zero_curve("yc/linear_zero_curve", [ 2.0, 5.0 ], [ 0.02, 0.03 ]),
            DiffFusion.backward_flat_parameter("pa/backward_flat_parameter", [ 0.0 ], [ 1.0 ]),
            DiffFusion.forward_flat_parameter("pa/forward_flat_parameter", [0.0, 2.0], [ 0.10, 0.15] ),
        ]
        ts_dict = OrderedDict{String,DiffFusion.Termstructure}(((DiffFusion.alias(ts_), ts_) for ts_ in ts_vector))
        #
        (l, v) = DiffFusion.termstructure_values(ts_dict)
        labels = [
            "yc/flat_forward" * delim * "DiffFusion.FlatForward" * delim * "rate",
            "yc/zero_curve" * delim * "DiffFusion.ZeroCurve" * delim * "1.00",
            "yc/zero_curve" * delim * "DiffFusion.ZeroCurve" * delim * "10.00",
            "yc/linear_zero_curve" * delim * "DiffFusion.LinearZeroCurve" * delim * "2.00",
            "yc/linear_zero_curve" * delim * "DiffFusion.LinearZeroCurve" * delim * "5.00",
            "pa/backward_flat_parameter" * delim * "DiffFusion.BackwardFlatParameter" * delim * "0.00",
            "pa/forward_flat_parameter" * delim * "DiffFusion.ForwardFlatParameter" * delim * "0.00",
            "pa/forward_flat_parameter" * delim * "DiffFusion.ForwardFlatParameter" * delim * "2.00"
        ]
        values = [0.01, 0.02, 0.03, 0.02, 0.03, 1.0, 0.1, 0.15]
        @test l == labels
        @test v == values
        #
        d1 = deepcopy(ts_dict)
        d2 = DiffFusion.termstructure_dictionary!(ts_dict, l, v)
        @test string(d1) == string(d2)
        #println(l)
        #println(v)
    end

    @testset "Extract and rebuild with permutation" begin
        delim = DiffFusion._split_alias_identifyer
        ts_vector = [
            DiffFusion.flat_forward("yc/flat_forward", 0.01),
            DiffFusion.zero_curve("yc/zero_curve", [ 1.0, 10.0 ], [ 0.02, 0.03 ]),
            DiffFusion.backward_flat_parameter("pa/backward_flat_parameter", [ 0.0 ], [ 1.0 ]),
            DiffFusion.forward_flat_parameter("pa/forward_flat_parameter", [0.0, 2.0], [ 0.10, 0.15] ),
        ]
        ts_dict = OrderedDict{String,DiffFusion.Termstructure}(((DiffFusion.alias(ts_), ts_) for ts_ in ts_vector))
        #
        (l, v) = DiffFusion.termstructure_values(ts_dict)
        labels = [
            "pa/forward_flat_parameter" * delim * "DiffFusion.ForwardFlatParameter" * delim * "0.00",
            "pa/forward_flat_parameter" * delim * "DiffFusion.ForwardFlatParameter" * delim * "2.00",
            "pa/backward_flat_parameter" * delim * "DiffFusion.BackwardFlatParameter" * delim * "0.00",
            "yc/zero_curve" * delim * "DiffFusion.ZeroCurve" * delim * "1.00",
            "yc/zero_curve" * delim * "DiffFusion.ZeroCurve" * delim * "10.00",
            "yc/flat_forward" * delim * "DiffFusion.FlatForward" * delim * "rate",
        ]
        values = [ 0.1, 0.15, 1.0, 0.02, 0.03, 0.01,]
        @test l != labels
        @test v != values
        #
        d1 = deepcopy(ts_dict)
        d2 = DiffFusion.termstructure_dictionary!(ts_dict, l, v)
        @test string(d1) == string(d2)
        #println(l)
        #println(v)
    end

end
