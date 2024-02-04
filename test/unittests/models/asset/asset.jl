using DiffFusion
using Test

@testset "Models for tradeable assets" begin

    @testset "AssetModel methods." begin
        struct NoAssetModel <: DiffFusion.AssetModel end
        m = NoAssetModel()
        #
        @test_throws ErrorException DiffFusion.asset_volatility(m, 1.0, 2.0)
        #
        X = [ 11., 12., 13. ] * [1.]'
        model_alias = ["A", "B", "C" ]
        SX = DiffFusion.model_state(X, DiffFusion.alias_dictionary(model_alias))
        @test_throws ErrorException DiffFusion.asset_volatility(m, 1.0, 2.0, SX)
    end

    include("lognormal_asset_model.jl")
    include("asset_volatility_and_calibration.jl")

end
