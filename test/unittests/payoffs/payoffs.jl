using DiffFusion
using Test

@testset "Payoff scripting framework." begin

    @testset "Abstract payoffs." begin
        # a trivial payoff
        struct NoPayoff <: DiffFusion.Payoff end
        p = NoPayoff()
        # a trivial path for testing
        struct ConstantPath <: DiffFusion.AbstractPath end
        path = ConstantPath()
        @test_throws ErrorException DiffFusion.obs_time(p)
        @test_throws ErrorException DiffFusion.obs_times(p)
        @test_throws ErrorException DiffFusion.at(p, path)
        @test_throws ErrorException p(path)
    end

    include("amc_payoffs.jl")
    include("asset_options.jl")
    include("barrier_options.jl")
    include("nodes_and_leafs.jl")
    include("rates_payoffs.jl")
    include("rates_options.jl")

end
