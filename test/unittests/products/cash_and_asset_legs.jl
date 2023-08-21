
using DiffFusion
using Test

@testset "Test cash and asset legs" begin
    
    @testset "Test CashBalanceLeg." begin
        leg = DiffFusion.cash_balance_leg("leg/1", 100.0)
        p = DiffFusion.discounted_cashflows(leg, 5.0)
        @test length(p) == 1
        @test string(p[1]) == "(100.0000 @ 5.00)"
        #
        leg = DiffFusion.cash_balance_leg("leg/1", 100.0, "EUR-USD", -1)
        p = DiffFusion.discounted_cashflows(leg, 1.0)
        @test string(p[1]) == "(S(EUR-USD, 1.00) * -100.0000 @ 1.00)"
        #
        leg = DiffFusion.cash_balance_leg("leg/1", 100.0, nothing, -1, 3.0)
        p = DiffFusion.discounted_cashflows(leg, 1.0)
        @test string(p[1]) == "(-100.0000 @ 1.00)"
        @test length(DiffFusion.discounted_cashflows(leg, 3.0)) == 0
        @test length(DiffFusion.discounted_cashflows(leg, 5.0)) == 0
        # println(string(p[1]))
    end


    @testset "Test CashBalanceLeg." begin
        leg = DiffFusion.asset_leg("leg/1", "SXE50", 100.0)
        p = DiffFusion.discounted_cashflows(leg, 5.0)
        @test length(p) == 1
        @test string(p[1]) == "(100.0000 * S(SXE50, 5.00) @ 5.00)"
        #
        leg = DiffFusion.asset_leg("leg/1", "SXE50", 100.0, "EUR-USD", -1)
        p = DiffFusion.discounted_cashflows(leg, 1.0)
        @test string(p[1]) == "(S(EUR-USD, 1.00) * -100.0000 * S(SXE50, 1.00) @ 1.00)"
        #
        leg = DiffFusion.asset_leg("leg/1", "SXE50", 100.0, nothing, -1, 3.0)
        p = DiffFusion.discounted_cashflows(leg, 1.0)
        @test string(p[1]) == "(-100.0000 * S(SXE50, 1.00) @ 1.00)"
        @test length(DiffFusion.discounted_cashflows(leg, 3.0)) == 0
        @test length(DiffFusion.discounted_cashflows(leg, 5.0)) == 0
        # println(string(p[1]))
    end


end