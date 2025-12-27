using DiffFusion
using Distributed
using OrderedCollections
using Test

@testset "Serialise and de-serialise models and term structures." begin

    @testset "Basic object types serialisation" begin
        @test_throws ErrorException DiffFusion.serialise('1')
        @test DiffFusion.serialise(nothing) == "nothing"
        @test DiffFusion.serialise("Std") == "Std"
        @test DiffFusion.serialise(42) == 42
        @test DiffFusion.serialise(42.1) == 42.1
        #
        d = Dict("A" => 1, "B" => 2.0, "C" => "Std" )
        @test DiffFusion.serialise(d) == OrderedCollections.OrderedDict{String, Any}(
            "B" => 2.0,
            "A" => 1,
            "C" => "Std"
        )
    end

    @testset "Simple Remote call serialisation." begin
        f = remotecall(()-> "Std", workers()[1])
        @test DiffFusion.serialise(f) == "Std"
        f = remotecall(()-> 42.1, workers()[1])
        @test DiffFusion.serialise(f) == 42.1
    end

    @testset "Basic object types de-serialisation" begin
        @test isnothing(DiffFusion.deserialise("nothing"))
        @test DiffFusion.deserialise("Std") == "Std"
        @test DiffFusion.deserialise(42) == 42
        @test DiffFusion.deserialise(42.1) == 42.1
        #
        o = OrderedCollections.OrderedDict{String, Any}(
            "B" => 2.0,
            "A" => 1,
            "C" => "Std"
        )
        @test DiffFusion.deserialise(o) == Dict("A" => 1, "B" => 2.0, "C" => "Std" )
    end

    @testset "Function name serialisation" begin
        ufo(x) = "ufo" * string(x)
        @test DiffFusion.serialise(exp) == "{exp}"
        @test DiffFusion.serialise(ufo) == "{ufo}"
        #
        d = Dict("exp" => exp, "ufo" => "ufo")
        @test DiffFusion.deserialise("{exp}", d) == exp
        @test DiffFusion.deserialise("{ufo}", d) == "ufo"
    end

end
