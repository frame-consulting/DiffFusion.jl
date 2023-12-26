using DiffFusion
using Test

@testset "Credit default curves." begin

    @testset "Test FlatSpreadCurve." begin
        cv = DiffFusion.flat_spread_curve("Std", 0.05)
        @test DiffFusion.alias(cv) == "Std"
        @test cv(1.0) == exp(-0.05)
        #
        cv = DiffFusion.flat_spread_curve(0.05)
        @test DiffFusion.alias(cv) == ""
        @test cv(1.0) == exp(-0.05)
    end


    @testset "Test LogSurvivalCurve." begin
        times = [0.0, 2.0, 5.0]
        survival_probs = [1.0, 0.5, 0.25]
        cv = DiffFusion.survival_curve("Std", times, survival_probs)
        cv = DiffFusion.survival_curve("Std", times, survival_probs, "CUBIC")
        #
        cv = DiffFusion.survival_curve("Std", times, survival_probs)
        #
        @test cv(0.0) == 1.0
        @test cv(2.0) == 0.5
        @test cv(5.0) == 0.25
        #
        @test cv(1.0) == exp(-0.34657359027997264)
        @test isapprox(cv(3.0), 0.5 * exp(-0.23104906018664842), atol=1.0e-14)
    end

end
