
using DiffFusion
using OrderedCollections
using Test


@testset "Serialise and de-serialise arrays." begin

    @testset "Serialise arrays" begin
        @test DiffFusion.serialise([ 1, 2, 3 ]) == [ 1, 2, 3 ]
        @test DiffFusion.serialise([ 1.0, 2.0, 3.0 ]) == [ 1.0, 2.0, 3.0 ]
        @test DiffFusion.serialise([ 1, 2.0, "three" ]) == [ 1, 2.0, "three" ]
        #
        @test DiffFusion.serialise(ones(2,3)) == [[1.0, 1.0, 1.0], [1.0, 1.0, 1.0]]
        #
        d = DiffFusion.serialise(ones(2,3,4))
        d_ref = OrderedDict{String, Any}(
            "typename" => "Array{Float64, 3}",
            "constructor" => "array",
            "data" => ones(24),
            "dims" => [2, 3, 4]
        )
        @test d == d_ref
    end

    @testset "De-serialise arrays" begin
        @test DiffFusion.deserialise([ 1, 2, 3 ]) == [ 1, 2, 3 ]
        @test DiffFusion.deserialise([ 1.0, 2.0, 3.0 ]) == [ 1.0, 2.0, 3.0 ]
        @test DiffFusion.deserialise([ 1, 2.0, "three" ]) == [ 1, 2.0, "three" ]
        #
        @test DiffFusion.deserialise([[1.0, 1.0, 1.0], [1.0, 1.0, 1.0]]) == ones(2,3)
        #
        d = OrderedDict{String, Any}(
            "typename" => "Array",
            "constructor" => "array",
            "data" => ones(2),
            "dims" => [ 2, ],
        )
        @test DiffFusion.deserialise(d) == ones(2)
        #
        d = OrderedDict{String, Any}(
            "typename" => "Array",
            "constructor" => "array",
            "data" => ones(6),
            "dims" => [ 2, 3, ],
        )
        @test DiffFusion.deserialise(d) == ones((2,3))
        #
        d = OrderedDict{String, Any}(
            "typename" => "Array",
            "constructor" => "array",
            "data" => ones(24),
            "dims" => [ 2, 3, 4, ],
        )
        @test DiffFusion.deserialise(d) == ones((2, 3, 4))
    end

end