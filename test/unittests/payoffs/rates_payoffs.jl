using DiffFusion
using Test

@testset "Rates payoffs." begin

    "A trivial path for testing."
    struct ConstantPath <: DiffFusion.AbstractPath end
    DiffFusion.numeraire(p::ConstantPath, t::DiffFusion.ModelTime, curve_key::String) = t * ones(5)
    DiffFusion.bank_account(p::ConstantPath, t::DiffFusion.ModelTime, key::String) = t * ones(5)
    DiffFusion.zero_bond(p::ConstantPath, t::DiffFusion.ModelTime, T::DiffFusion.ModelTime, key::String) = 1.0 * ones(5)
    DiffFusion.length(p::ConstantPath) = 5

    @testset "Libor Rate payoff" begin
        path = ConstantPath()
        #
        L = DiffFusion.LiborRate(1.0, 2.0, 3.0, "USD-Lib-3m")
        @test DiffFusion.obs_time(L) == 1.0
        @test DiffFusion.at(L, path) == zeros(5)
        @test string(L) == "L(USD-Lib-3m, 1.00; 2.00, 3.00)"
        @test DiffFusion.obs_time(L) == 1.0
        @test DiffFusion.obs_times(L) == Set([1.0])
    end

    @testset "Compounded Rate payoff" begin
        path = ConstantPath()
        #
        L = DiffFusion.CompoundedRate(1.0, 2.0, 3.0, "SOFR")
        @test DiffFusion.obs_time(L) == 1.0
        @test DiffFusion.at(L, path) == zeros(5)
        @test string(L) == "R(SOFR, 1.00; 2.00, 3.00)"
        #
        @test DiffFusion.at(DiffFusion.CompoundedRate(2.0, 2.0, 3.0, "SOFR"), path) == zeros(5)
        @test DiffFusion.at(DiffFusion.CompoundedRate(2.5, 2.0, 3.0, "SOFR"), path) == 0.25 * ones(5)
        @test DiffFusion.at(DiffFusion.CompoundedRate(3.0, 2.0, 3.0, "SOFR"), path) == 0.50 * ones(5)
        #
        @test DiffFusion.obs_time(DiffFusion.CompoundedRate(1.0, 2.0, 3.0, "SOFR")) == 1.0
        @test DiffFusion.obs_time(DiffFusion.CompoundedRate(2.0, 2.0, 3.0, "SOFR")) == 2.0
        @test DiffFusion.obs_time(DiffFusion.CompoundedRate(2.5, 2.0, 3.0, "SOFR")) == 2.5
        @test DiffFusion.obs_time(DiffFusion.CompoundedRate(3.0, 2.0, 3.0, "SOFR")) == 3.0
        #
        @test DiffFusion.obs_times(DiffFusion.CompoundedRate(1.0, 2.0, 3.0, "SOFR")) == Set([1.0])
        @test DiffFusion.obs_times(DiffFusion.CompoundedRate(2.0, 2.0, 3.0, "SOFR")) == Set([2.0])
        @test DiffFusion.obs_times(DiffFusion.CompoundedRate(2.5, 2.0, 3.0, "SOFR")) == Set([2.0, 2.5])
        @test DiffFusion.obs_times(DiffFusion.CompoundedRate(3.0, 2.0, 3.0, "SOFR")) == Set([2.0, 3.0])
        @test DiffFusion.obs_times(DiffFusion.CompoundedRate(4.0, 2.0, 3.0, "SOFR")) == Set([2.0  3.0])
        #
        fixed_compounding = 1.0 + 0.01 * DiffFusion.Fixing(-0.01, "SOFR")
        R = DiffFusion.CompoundedRate(0.5, 0.0, 1.0, "SOFR", fixed_compounding)
        @test string(R) == "R(SOFR, 0.50; 0.00, 1.00; (1.0000 + 0.0100 * Idx(SOFR, -0.01)))"
        @test DiffFusion.obs_times(R) == Set((-0.01, 0.0, 0.5))
    end

end
