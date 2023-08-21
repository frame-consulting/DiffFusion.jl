
using DiffFusion
using Test

@testset "CashFlowLeg tests." begin

    @testset "Abstract CashFlowLeg." begin
        struct NoLeg <: DiffFusion.CashFlowLeg end
        @test_throws ErrorException DiffFusion.future_cashflows(NoLeg(), 2.0)
        @test_throws ErrorException DiffFusion.discounted_cashflows(NoLeg(), 2.0)
    end

    @testset "Deterministic notional legs" begin
        cash_flows = [
            DiffFusion.FixedCashFlow(-1.0, 0.5),
            DiffFusion.FixedCashFlow( 0.0, 0.5),
            DiffFusion.FixedCashFlow( 1.0, 0.5),
            DiffFusion.FixedRateCoupon(2.0, 0.03, 1.0),
            DiffFusion.FixedRateCoupon(3.0, 0.03, 1.0),
            DiffFusion.SimpleRateCoupon(3.0, 3.0, 4.0, 4.0, 1.0, "EURIBOR12M", nothing, 0.01)
        ]
        notionals = [ 10., 20., 30., 40., 50., 60., ]
        #
        leg = DiffFusion.cashflow_leg("One",cash_flows, notionals, "EUR:OIS")
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 4
        @test string(payoffs[1]) == "(30.0000 * 0.5000 @ 1.00)"
        @test string(payoffs[4]) == "(60.0000 * (L(EURIBOR12M, 3.00; 3.00, 4.00) + 0.0100) * 1.0000 @ 4.00)"
        #
        payoffs = DiffFusion.future_cashflows(leg, 2.5)
        @test length(payoffs) == 2
        @test string(payoffs[1]) == "(50.0000 * 0.0300 * 1.0000 @ 3.00)"
        @test string(payoffs[2]) == "(60.0000 * (L(EURIBOR12M, 3.00; 3.00, 4.00) + 0.0100) * 1.0000 @ 4.00)"
        #
        payoffs = DiffFusion.discounted_cashflows(leg, 2.5)
        @test length(payoffs) == 2
        @test string(payoffs[1]) == "(P(EUR:OIS, 2.50, 3.00) * 50.0000 * 0.0300 * 1.0000 @ 2.50)"
        @test string(payoffs[2]) == "(P(EUR:OIS, 2.50, 4.00) * 60.0000 * (L(EURIBOR12M, 2.50; 3.00, 4.00) + 0.0100) * 1.0000 @ 2.50)"
        #
        payoffs = DiffFusion.discounted_cashflows(leg, 3.5)
        @test length(payoffs) == 1
        @test string(payoffs[1]) == "(P(EUR:OIS, 3.50, 4.00) * 60.0000 * (L(EURIBOR12M, 3.00; 3.00, 4.00) + 0.0100) * 1.0000 @ 3.50)"
        #
        notionals = 100.0 * ones(6)
        leg2 = DiffFusion.cashflow_leg("Two",cash_flows, notionals, "EUR:OIS")
        leg3 = DiffFusion.cashflow_leg("Two",cash_flows, 100.0, "EUR:OIS")
        @test leg2.alias == leg3.alias
        @test leg2.cashflows == leg3.cashflows
        @test leg2.notionals == leg3.notionals
        @test leg2.curve_key == leg3.curve_key
        @test leg2.fx_key == leg3.fx_key
        @test leg2.payer_receiver == leg3.payer_receiver
        #
        leg = DiffFusion.cashflow_leg("Two",cash_flows, 100.0, "EUR:OIS", "EUR-USD")
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 4
        @test string(payoffs[4]) == "(S(EUR-USD, 4.00) * 100.0000 * (L(EURIBOR12M, 3.00; 3.00, 4.00) + 0.0100) * 1.0000 @ 4.00)"
        payoffs = DiffFusion.discounted_cashflows(leg, 3.5)
        @test length(payoffs) == 1
        @test string(payoffs[1]) == "(S(EUR-USD, 3.50) * P(EUR:OIS, 3.50, 4.00) * 100.0000 * (L(EURIBOR12M, 3.00; 3.00, 4.00) + 0.0100) * 1.0000 @ 3.50)"
        #
        leg = DiffFusion.cashflow_leg("Two",cash_flows, 100.0, "EUR:OIS", "EUR-USD", -1)
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 4
        @test string(payoffs[1]) == "(S(EUR-USD, 1.00) * -100.0000 * 0.5000 @ 1.00)"
        #
        leg = DiffFusion.cashflow_leg("Two",cash_flows[end:end], 100.0)
        @test leg.curve_key == "EURIBOR12M"
        #
        @test_throws AssertionError DiffFusion.cashflow_leg("Two",cash_flows, 100.0)
        @test_throws AssertionError DiffFusion.cashflow_leg("Two",cash_flows, 0.0, "EUR:OIS")
        @test_throws AssertionError DiffFusion.cashflow_leg("Two",cash_flows, notionals[2:end], "EUR:OIS")
    end

end
