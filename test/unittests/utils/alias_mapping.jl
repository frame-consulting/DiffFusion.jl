using DiffFusion
using Distributions
using Test

@testset "Alias mapping" begin
    A = [ "a", "b", "c", "d", "e" ]
    @test DiffFusion.alias_mapping(A, []) == [1, 2, 3, 4, 5]
    @test DiffFusion.alias_mapping(A, [ "a", "b", "c" ]) == [1, 2, 3, 4, 5]
    @test DiffFusion.alias_mapping(A, [ "a", "b", "d" ]) == [1, 2, 4, 3, 5]
    @test DiffFusion.alias_mapping(A, [ "a", "b", "e" ]) == [1, 2, 4, 5, 3]
    @test DiffFusion.alias_mapping(A, [ "b", "e", "c" ]) == [4, 1, 3, 5, 2]
end
