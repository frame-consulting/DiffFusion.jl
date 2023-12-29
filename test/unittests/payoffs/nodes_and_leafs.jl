using DiffFusion
using Test

@testset "Nodes and Leaf payoffs." begin

    "A trivial path for testing."
    struct ConstantPath <: DiffFusion.AbstractPath end
    DiffFusion.numeraire(p::ConstantPath, t::DiffFusion.ModelTime, curve_key::String) = t * ones(5)
    DiffFusion.bank_account(p::ConstantPath, t::DiffFusion.ModelTime, key::String) = 3.0 * ones(5)
    DiffFusion.zero_bond(p::ConstantPath, t::DiffFusion.ModelTime, T::DiffFusion.ModelTime, key::String) = 4.0 * ones(5)
    DiffFusion.asset(p::ConstantPath, t::DiffFusion.ModelTime, key::String) = 5.0 * ones(5)
    DiffFusion.forward_asset(p::ConstantPath, t::DiffFusion.ModelTime, T::DiffFusion.ModelTime, key::String) = 6.0 * ones(5)
    DiffFusion.fixing(p::ConstantPath, t::DiffFusion.ModelTime, key::String) = 6.0 * ones(5)
    DiffFusion.length(p::ConstantPath) = 5

    @testset "Leaf payoffs" begin
        path = ConstantPath()
        #
        p = DiffFusion.Numeraire(1.0, "Std")
        @test DiffFusion.obs_time(p) == 1.0
        @test DiffFusion.obs_times(p) == Set(1.0)
        @test DiffFusion.at(p, path) == 1.0 * ones(5)
        @test p(path) == 1.0 * ones(5)
        @test string(p) == "N(Std, 1.00)"
        #
        p = DiffFusion.BankAccount(2.0, "EUR")
        @test DiffFusion.obs_time(p) == 2.0
        @test DiffFusion.obs_times(p) == Set(2.0)
        @test DiffFusion.at(p, path) == 3.0 * ones(5)
        @test p(path) == 3.0 * ones(5)
        @test string(p) == "B(EUR, 2.00)"
        #
        p = DiffFusion.ZeroBond(4.0, 10.0, "USD")
        @test DiffFusion.obs_time(p) == 4.0
        @test DiffFusion.obs_times(p) == Set(4.0)
        @test DiffFusion.at(p, path) == 4.0 * ones(5)
        @test p(path) == 4.0 * ones(5)
        @test string(p) == "P(USD, 4.00, 10.00)"
        #
        p = DiffFusion.Asset(2.0, "GBP")
        @test DiffFusion.obs_time(p) == 2.0
        @test DiffFusion.obs_times(p) == Set(2.0)
        @test DiffFusion.at(p, path) == 5.0 * ones(5)
        @test p(path) == 5.0 * ones(5)
        @test string(p) == "S(GBP, 2.00)"
        #
        p = DiffFusion.ForwardAsset(2.0, 5.0, "GBP")
        @test DiffFusion.obs_time(p) == 2.0
        @test DiffFusion.obs_times(p) == Set(2.0)
        @test DiffFusion.at(p, path) == 6.0 * ones(5)
        @test p(path) == 6.0 * ones(5)
        @test string(p) == "S(GBP, 2.00, 5.00)"
        #
        p = DiffFusion.Fixing(-0.5, "SOFR")
        @test DiffFusion.obs_time(p) == -0.5
        @test DiffFusion.obs_times(p) == Set(-0.5)
        @test DiffFusion.at(p, path) == 6.0 * ones(5)
        @test p(path) == 6.0 * ones(5)
        @test string(p) == "Idx(SOFR, -0.50)"
        #
        p = DiffFusion.Fixed(3.5)
        @test DiffFusion.obs_time(p) == 0.0
        @test DiffFusion.obs_times(p) == Set(0.0)
        @test DiffFusion.at(p, path) == 3.5 * ones(5)
        @test p(path) == 3.5 * ones(5)
        @test string(p) == "3.5000"
        #
        p = DiffFusion.ScalarValue(3.5)
        @test DiffFusion.obs_time(p) == 0.0
        @test DiffFusion.obs_times(p) == Set(0.0)
        @test DiffFusion.at(p, path) == 3.5
        @test p(path) == 3.5
        @test string(p) == "3.5000"
        #
    end

    @testset "Unary nodes" begin
        path = ConstantPath()
        p = DiffFusion.Pay(DiffFusion.Fixed(3.5), 1.0)
        @test DiffFusion.obs_time(p) == 1.0
        @test DiffFusion.obs_times(p) == Set([0.0, 1.0])
        @test DiffFusion.at(p, path) == 3.5 * ones(5)
        @test p(path) == 3.5 * ones(5)
        @test string(p) == "(3.5000 @ 1.00)"
        #
        p = DiffFusion.Cache(DiffFusion.Fixed(3.5))
        @test DiffFusion.obs_time(p) == 0.0
        @test DiffFusion.obs_times(p) == Set(0.0)
        @test isnothing(p.path)
        @test isnothing(p.value)
        @test DiffFusion.at(p, path) == 3.5 * ones(5)
        @test p.path == path
        @test p.path === path
        @test p.value == 3.5 * ones(5)
        @test string(p) == "{3.5000}"
        #
        p.value = 1.5 * ones(5)
        @test p(path) == 1.5 * ones(5)
        @test p(path) == 1.5 * ones(5)
        #
        p = DiffFusion.Cache(DiffFusion.Asset(5.0, "USD"))
        @test string(p) == "{S(USD, 5.00)}"
    end

    @testset "Binary nodes" begin
        path = ConstantPath()
        asset = DiffFusion.Asset(3.0, "USD") # 5
        zcb = DiffFusion.ZeroBond(3.0, 5.0, "USD") # 4
        one = DiffFusion.Fixed(1.0)
        two = DiffFusion.Fixed(2.0)
        #
        @test (asset + zcb)(path) == 9.0 * ones(5)
        @test (asset - zcb)(path) == 1.0 * ones(5)
        @test (asset * zcb)(path) == 20.0 * ones(5)
        @test (zcb / two)(path) == 2.0 * ones(5)
        #
        @test (zcb + 3.0)(path) == 7.0 * ones(5)
        @test (zcb - 3.0)(path) == 1.0 * ones(5)
        @test (zcb * 3.0)(path) == 12.0 * ones(5)
        @test (zcb / 2.0)(path) == 2.0 * ones(5)
        #
        @test (10.0 + asset)(path) == 15.0 * ones(5)
        @test (10.0 - asset)(path) == 5.0 * ones(5)
        @test (2 * asset)(path) == 10.0 * ones(5)
        @test (10 / asset)(path) == 2.0 * ones(5)
        #
        @test (one <  two)(path) == 1.0 * ones(5)
        @test (one <= two)(path) == 1.0 * ones(5)
        @test (one == two)(path) == 0.0 * ones(5)
        @test (one != two)(path) == 1.0 * ones(5)
        @test (one >= two)(path) == 0.0 * ones(5)
        @test (one >  two)(path) == 0.0 * ones(5)
        #
        @test (1.0 <  two)(path) == 1.0 * ones(5)
        @test (1.0 <= two)(path) == 1.0 * ones(5)
        @test (1.0 == two)(path) == 0.0 * ones(5)
        @test (1.0 != two)(path) == 1.0 * ones(5)
        @test (1.0 >= two)(path) == 0.0 * ones(5)
        @test (1.0 >  two)(path) == 0.0 * ones(5)
        #
        @test (one <  2.0)(path) == 1.0 * ones(5)
        @test (one <= 2.0)(path) == 1.0 * ones(5)
        @test (one == 2.0)(path) == 0.0 * ones(5)
        @test (one != 2.0)(path) == 1.0 * ones(5)
        @test (one >= 2.0)(path) == 0.0 * ones(5)
        @test (one >  2.0)(path) == 0.0 * ones(5)
        #
        @test_throws ErrorException DiffFusion.Logical(one, two, ".")(path)
        #
        @test DiffFusion.Max(one, two)(path) == 2.0 * ones(5)
        @test DiffFusion.Min(one, two)(path) == 1.0 * ones(5)
        @test DiffFusion.Max(1.0, two)(path) == 2.0 * ones(5)
        @test DiffFusion.Min(1.0, two)(path) == 1.0 * ones(5)
        @test DiffFusion.Max(one, 2.0)(path) == 2.0 * ones(5)
        @test DiffFusion.Min(one, 2.0)(path) == 1.0 * ones(5)
        #
        @test string(one +  two) == "(1.0000 + 2.0000)"
        @test string(one -  two) == "(1.0000 - 2.0000)"
        @test string(one *  two) == "1.0000 * 2.0000"
        @test string(one /  two) == "(1.0000 / 2.0000)"
        @test string(one <  two) == "(1.0000 < 2.0000)"
        @test string(one <= two) == "(1.0000 <= 2.0000)"
        @test string(one == two) == "(1.0000 == 2.0000)"
        @test string(one != two) == "(1.0000 != 2.0000)"
        @test string(one >= two) == "(1.0000 >= 2.0000)"
        @test string(one >  two) == "(1.0000 > 2.0000)"
        @test string(DiffFusion.Max(one, two)) == "Max(1.0000, 2.0000)"
        @test string(DiffFusion.Min(one, two)) == "Min(1.0000, 2.0000)"
        #
        @test DiffFusion.obs_time(DiffFusion.Asset(3.0, "USD") + DiffFusion.Asset(3.0, "USD")) == 3.0
        @test DiffFusion.obs_time(DiffFusion.Asset(3.0, "USD") + DiffFusion.Asset(4.0, "USD")) == 4.0
        @test DiffFusion.obs_times(1.0 + DiffFusion.Asset(3.0, "USD") + DiffFusion.Asset(4.0, "USD")) == Set([0.0, 3.0, 4.0])
        #
        p = 1.0 + DiffFusion.Asset(3.0, "USD") + DiffFusion.Asset(4.0, "USD")
        p = DiffFusion.Cache(p) * 2
        p = p / DiffFusion.ZeroBond(3.0, 5.0, "USD")
        p = DiffFusion.Pay(p, 7.0)
        @test string(p) == "(({((1.0000 + S(USD, 3.00)) + S(USD, 4.00))} * 2.0000 / P(USD, 3.00, 5.00)) @ 7.00)"
        @test DiffFusion.obs_time(p) == 7.0
        @test DiffFusion.obs_times(p) == Set([0.0, 3.0, 4.0, 7.0])
        #
        if VERSION >= v"1.7"  # @test_warn does not work with Julia 1.6
            @test_warn "Pay time is before observation time." (p = DiffFusion.Pay(p, 2.0))
            @test DiffFusion.obs_time(p) == 2.0
            @test DiffFusion.obs_times(p) == Set([0.0, 2.0, 3.0, 4.0, 7.0])
        end
    end
end
