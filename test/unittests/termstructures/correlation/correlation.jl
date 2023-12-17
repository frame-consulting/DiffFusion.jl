using DiffFusion
using Test

using LinearAlgebra

@testset "Correlation holders." begin

    @testset "Correlation holder" begin
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "EUR", "USD", 0.5)
        DiffFusion.set_correlation!(ch, "EUR", "EUR-USD", -0.3)
        DiffFusion.set_correlation!(ch, "USD", "EUR-USD", -0.4)
        #
        @test DiffFusion.alias(ch) == "Std"
        @test ch.sep == "<>"
        @test DiffFusion.correlation(ch, "EUR", "USD") == 0.5
        @test DiffFusion.correlation(ch, "USD", "EUR") == 0.5
        @test DiffFusion.correlation(ch, "EUR-USD", "EUR-USD") == 1.0
        @test DiffFusion.correlation(ch, "EUR", "GBP") == 0.0
        @test DiffFusion.correlation(ch, "GBP", "GBP") == 1.0
        #
        @test DiffFusion.correlation(ch, ["EUR", "USD"]) == [1.0 0.5; 0.5 1.0]
        @test DiffFusion.correlation(ch, ["GBP"]) == ones(1,1) # [1.0;;]
        @test DiffFusion.correlation(ch, ["EUR", "EUR-USD", "GBP"]) == 
            [  1.0 -0.3  0.0;
              -0.3  1.0  0.0;
               0.0  0.0  1.0]
        @test DiffFusion.correlation(ch, ["1", "2", "3"]) == Matrix{Float64}(I, 3, 3)
        #
        # correlation holder from dictionary
        ch2 = DiffFusion.correlation_holder("Std", ch.correlations)
        @test ch2 == ch
    end

    @testset "Additional correlation calls" begin
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "EUR", "USD", 0.5)
        DiffFusion.set_correlation!(ch, "EUR", "EUR-USD", -0.3)
        DiffFusion.set_correlation!(ch, "USD", "EUR-USD", -0.4)
        #
        @test ch("EUR", "USD") == 0.5
        @test ch("EUR", "GBP") == 0.0
        @test ch(["EUR", "USD", "EUR-USD"]) == ch(["EUR", "USD", "EUR-USD"], ["EUR", "USD", "EUR-USD"])
        @test ch("EUR", ["USD", "GBP"]) == [ 0.5 0.0; ]
        @test ch(["USD", "GBP"], "EUR" ) == reshape([ 0.5, 0.0], (2,1)) # [ 0.5; 0.0;; ]
    end

end
