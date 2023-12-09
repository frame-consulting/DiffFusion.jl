using DiffFusion
using Test

@testset "AMC payoffs." begin

    "A trivial path for testing."
    n_paths = 20
    struct ConstantPath <: DiffFusion.AbstractPath end
    DiffFusion.numeraire(p::ConstantPath, t::DiffFusion.ModelTime, curve_alias::String) = ones(n_paths)
    DiffFusion.bank_account(p::ConstantPath, t::DiffFusion.ModelTime, alias::String) = 1.0 * ones(n_paths)
    DiffFusion.zero_bond(p::ConstantPath, t::DiffFusion.ModelTime, T::DiffFusion.ModelTime, alias::String) = 1.0 * ones(n_paths)
    DiffFusion.asset(p::ConstantPath, t::DiffFusion.ModelTime, alias::String) = t * ones(n_paths)
    DiffFusion.length(p::ConstantPath) = n_paths

    @testset "Payoff setup." begin
        x = [ DiffFusion.Asset(6.0, "Std"), DiffFusion.Asset(7.0, "Std") ]
        y = [ DiffFusion.Asset(8.0, "Std"), DiffFusion.Asset(9.0, "Std") ]
        z = [ DiffFusion.Asset(3.0, "Std"), DiffFusion.Asset(4.0, "Std") ]
        #
        p1 = DiffFusion.AmcMax(5.0, x, y, z, nothing, nothing, "Std")
        p2 = DiffFusion.AmcMin(5.0, x, y, z, nothing, nothing, "Std")
        p3 = DiffFusion.AmcOne(5.0, x, y, z, nothing, nothing, "Std")
        p4 = DiffFusion.AmcSum(5.0, x, z, nothing, nothing, "Std")
        #
        @test DiffFusion.obs_time(p1) == 5.0
        @test DiffFusion.obs_time(p2) == 5.0
        @test DiffFusion.obs_time(p3) == 5.0
        @test DiffFusion.obs_time(p4) == 5.0
        #
        @test DiffFusion.obs_times(p1) == Set([3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
        @test DiffFusion.obs_times(p2) == Set([3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
        @test DiffFusion.obs_times(p3) == Set([3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
        @test DiffFusion.obs_times(p4) == Set([3.0, 4.0, 5.0, 6.0, 7.0])
        #
        @test string(p1) == "AmcMax(5.00, [S(Std, 6.00), S(Std, 7.00)], [S(Std, 8.00), S(Std, 9.00)], [S(Std, 3.00), S(Std, 4.00)])"
        @test string(p2) == "AmcMin(5.00, [S(Std, 6.00), S(Std, 7.00)], [S(Std, 8.00), S(Std, 9.00)], [S(Std, 3.00), S(Std, 4.00)])"
        @test string(p3) == "AmcOne(5.00, [S(Std, 6.00), S(Std, 7.00)], [S(Std, 8.00), S(Std, 9.00)], [S(Std, 3.00), S(Std, 4.00)])"
        @test string(p4) == "AmcSum(5.00, [S(Std, 6.00), S(Std, 7.00)], [], [S(Std, 3.00), S(Std, 4.00)])"
    end

    @testset "Has AMC property" begin
        x = [ DiffFusion.Asset(6.0, "Std"), DiffFusion.Asset(7.0, "Std") ]
        y = [ DiffFusion.Asset(8.0, "Std"), DiffFusion.Asset(9.0, "Std") ]
        z = [ DiffFusion.Asset(3.0, "Std"), DiffFusion.Asset(4.0, "Std") ]
        #
        p1 = DiffFusion.AmcMax(5.0, x, y, z, nothing, nothing, "Std")
        p2 = DiffFusion.AmcMin(5.0, x, y, z, nothing, nothing, "Std")
        p3 = DiffFusion.AmcOne(5.0, x, y, z, nothing, nothing, "Std")
        p4 = DiffFusion.AmcSum(5.0, x, z, nothing, nothing, "Std")
        #
        @test DiffFusion.has_amc_payoff(x) == false
        #
        @test DiffFusion.has_amc_payoff(p1) == true
        @test DiffFusion.has_amc_payoff(p2) == true
        @test DiffFusion.has_amc_payoff(p3) == true
        @test DiffFusion.has_amc_payoff(p4) == true
        #
        @test DiffFusion.has_amc_payoff(p1 + x[1]) == true
        @test DiffFusion.has_amc_payoff(p1 + p2) == true
        @test DiffFusion.has_amc_payoff(DiffFusion.Pay(p1, 5.0)) == true
        @test DiffFusion.has_amc_payoff([p1, p2, p3, p4]) == true
    end

    @testset "Payoff calibration." begin
        x = [ DiffFusion.Asset(6.0, "Std"), DiffFusion.Asset(7.0, "Std") ]
        y = [ DiffFusion.Asset(8.0, "Std"), DiffFusion.Asset(9.0, "Std") ]
        z = [ DiffFusion.Asset(3.0, "Std"), DiffFusion.Asset(4.0, "Std") ]
        #
        path = ConstantPath()
        make_regression = (C, O) -> DiffFusion.polynomial_regression(C, O, 2)
        #
        p1 = DiffFusion.AmcMax(5.0, x, y, z, path, make_regression, "Std")
        p2 = DiffFusion.AmcMin(5.0, x, y, z, path, make_regression, "Std")
        p3 = DiffFusion.AmcOne(5.0, x, y, z, path, make_regression, "Std")
        p4 = DiffFusion.AmcSum(5.0, x, z, path, make_regression, "Std")
        #
        @test !isnothing(DiffFusion.calibrate_regression(p1.links, p1.regr))
        @test !isnothing(DiffFusion.calibrate_regression(p2.links, p2.regr))
        @test !isnothing(DiffFusion.calibrate_regression(p3.links, p3.regr))
        @test !isnothing(DiffFusion.calibrate_regression(p4.links, p4.regr))
        #
        DiffFusion.reset_regression!(p1, path, make_regression)
        DiffFusion.reset_regression!(p2, path, make_regression)
        DiffFusion.reset_regression!(p3, path, make_regression)
        DiffFusion.reset_regression!(p4, path, make_regression)
        #
        @test isnothing(p1.regr.regression)
        @test isnothing(p2.regr.regression)
        @test isnothing(p3.regr.regression)
        @test isnothing(p4.regr.regression)
        #
        @test p1(path) == 17.0 * ones(n_paths)
        @test p2(path) == 13.0 * ones(n_paths)
        @test p3(path) == zeros(n_paths)
        @test isapprox(p4(path), 13.0 * ones(n_paths), atol=2.0e-14)
        #
        p1 = DiffFusion.AmcMax(5.0, x, y, z, nothing, nothing, "Std")
        p2 = DiffFusion.AmcMin(5.0, x, y, z, nothing, nothing, "Std")
        p3 = DiffFusion.AmcOne(5.0, x, y, z, nothing, nothing, "Std")
        p4 = DiffFusion.AmcSum(5.0, x, z, nothing, nothing, "Std")
        #
        @test p1(path) == 17.0 * ones(n_paths)
        @test p2(path) == 13.0 * ones(n_paths)
        @test p3(path) == zeros(n_paths)
        @test p4(path) == 13.0 * ones(n_paths)
        #
        payoff = DiffFusion.Pay(p1 + p2, 10.0) - 1.0
        DiffFusion.reset_regression!(payoff, path, make_regression)
        #
        @test isnothing(p1.regr.regression)
        @test isnothing(p2.regr.regression)
        @test isnothing(p3.regr.regression)
        @test isnothing(p4.regr.regression)
        #
        @test p1.regr.path == path
        @test p2.regr.path == path
        @test isnothing(p3.regr.path)
        @test isnothing(p4.regr.path)
        #
        @test p1.regr.make_regression == make_regression
        @test p2.regr.make_regression == make_regression
        @test isnothing(p3.regr.make_regression)
        @test isnothing(p4.regr.make_regression)
        #
        struct NoPayoff <: DiffFusion.Payoff end
        @test_throws ErrorException DiffFusion.reset_regression!(NoPayoff(), path, make_regression)
    end

end
