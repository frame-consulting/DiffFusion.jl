
using DiffFusion
using Test

@testset "CashFlowLeg tests." begin

    @testset "Mark-to-mark legs flows" begin
        cash_flows = [
            DiffFusion.FixedCashFlow(2.0, 0.01)
            DiffFusion.FixedCashFlow(3.0, 0.01)
            DiffFusion.FixedCashFlow(4.0, 0.01)
        ]
        intitial_notional = 100. # GBP
        curve_key_dom = "EUR:XCCY"
        curve_key_for = "GBP:XCCY"
        fx_key_dom = "EUR-USD"
        fx_key_for = "GBP-USD"
        fx_reset_times = [ 1.0, 2.0, 3.0 ]
        fx_pay_times   = [ 2.0, 3.0, 4.0 ]
        payer_receiver = 1.0
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            fx_key_dom,
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(S(EUR-USD, 4.00) * (S(GBP-USD, 3.00) / S(EUR-USD, 3.00)) * 100.0000 * 0.0100 @ 4.00)"
        @test string(payoffs[6]) == "(S(EUR-USD, 4.00) * ((S(GBP-USD, 3.00) / S(EUR-USD, 3.00)) - (S(GBP-USD, 4.00) / S(EUR-USD, 4.00))) * 100.0000 @ 4.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            nothing, # DOM = NUM
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(S(GBP-USD, 3.00) * 100.0000 * 0.0100 @ 4.00)"
        @test string(payoffs[6]) == "((S(GBP-USD, 3.00) - S(GBP-USD, 4.00)) * 100.0000 @ 4.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            fx_key_dom,
            nothing, # FOR = NUM
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(S(EUR-USD, 4.00) * (1.0000 / S(EUR-USD, 3.00)) * 100.0000 * 0.0100 @ 4.00)"
        @test string(payoffs[6]) == "(S(EUR-USD, 4.00) * ((1.0000 / S(EUR-USD, 3.00)) - (1.0000 / S(EUR-USD, 4.00))) * 100.0000 @ 4.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            nothing, # DOM = NUM
            nothing, # FOR = NUM
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.future_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(100.0000 * 0.0100 @ 4.00)"
        @test string(payoffs[6]) == "(0.0000 @ 4.00)"
        #for p in payoffs
        #    println(string(p))
        #end
    end

    @testset "Mark-to-mark discounted legs flows as of t=0" begin
        cash_flows = [
            DiffFusion.FixedCashFlow(2.0, 0.01)
            DiffFusion.FixedCashFlow(3.0, 0.01)
            DiffFusion.FixedCashFlow(4.0, 0.01)
        ]
        intitial_notional = 100. # GBP
        curve_key_dom = "EUR:XCCY"
        curve_key_for = "GBP:XCCY"
        fx_key_dom = "EUR-USD"
        fx_key_for = "GBP-USD"
        fx_reset_times = [ 1.0, 2.0, 3.0 ]
        fx_pay_times   = [ 2.0, 3.0, 4.0 ]
        payer_receiver = 1.0
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            fx_key_dom,
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(S(EUR-USD, 0.00) * ((S(GBP-USD, 0.00) / S(EUR-USD, 0.00)) * P(GBP:XCCY, 0.00, 3.00) / P(EUR:XCCY, 0.00, 3.00)) * 100.0000 * P(EUR:XCCY, 0.00, 4.00) * 0.0100 @ 0.00)"
        @test string(payoffs[6]) == "(S(EUR-USD, 0.00) * P(EUR:XCCY, 0.00, 4.00) * (((S(GBP-USD, 0.00) / S(EUR-USD, 0.00)) * P(GBP:XCCY, 0.00, 3.00) / P(EUR:XCCY, 0.00, 3.00)) - ((S(GBP-USD, 0.00) / S(EUR-USD, 0.00)) * P(GBP:XCCY, 0.00, 4.00) / P(EUR:XCCY, 0.00, 4.00))) * 100.0000 @ 0.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            "USD:OIS",
            curve_key_for,
            nothing, # DOM = NUM
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "((S(GBP-USD, 0.00) * P(GBP:XCCY, 0.00, 3.00) / P(USD:OIS, 0.00, 3.00)) * 100.0000 * P(USD:OIS, 0.00, 4.00) * 0.0100 @ 0.00)"
        @test string(payoffs[6]) == "(P(USD:OIS, 0.00, 4.00) * ((S(GBP-USD, 0.00) * P(GBP:XCCY, 0.00, 3.00) / P(USD:OIS, 0.00, 3.00)) - (S(GBP-USD, 0.00) * P(GBP:XCCY, 0.00, 4.00) / P(USD:OIS, 0.00, 4.00))) * 100.0000 @ 0.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            "USD:OIS",
            fx_key_dom,
            nothing, # FOR = NUM
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "(S(EUR-USD, 0.00) * ((1.0000 / S(EUR-USD, 0.00)) * P(USD:OIS, 0.00, 3.00) / P(EUR:XCCY, 0.00, 3.00)) * 100.0000 * P(EUR:XCCY, 0.00, 4.00) * 0.0100 @ 0.00)"
        @test string(payoffs[6]) == "(S(EUR-USD, 0.00) * P(EUR:XCCY, 0.00, 4.00) * (((1.0000 / S(EUR-USD, 0.00)) * P(USD:OIS, 0.00, 3.00) / P(EUR:XCCY, 0.00, 3.00)) - ((1.0000 / S(EUR-USD, 0.00)) * P(USD:OIS, 0.00, 4.00) / P(EUR:XCCY, 0.00, 4.00))) * 100.0000 @ 0.00)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            "USD:OIS",
            "USD:OIS",
            nothing, # DOM = NUM
            nothing, # FOR = NUM
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 0.0)
        @test length(payoffs) == 6
        @test string(payoffs[5]) == "((1.0000 * P(USD:OIS, 0.00, 3.00) / P(USD:OIS, 0.00, 3.00)) * 100.0000 * P(USD:OIS, 0.00, 4.00) * 0.0100 @ 0.00)"
        @test string(payoffs[6]) == "(P(USD:OIS, 0.00, 4.00) * ((1.0000 * P(USD:OIS, 0.00, 3.00) / P(USD:OIS, 0.00, 3.00)) - (1.0000 * P(USD:OIS, 0.00, 4.00) / P(USD:OIS, 0.00, 4.00))) * 100.0000 @ 0.00)"
        # for p in payoffs
        #     println(string(p))
        #     println(DiffFusion.obs_times(p))
        # end
        # println()
    end

    @testset "Mark-to-mark discounted legs flows as of t>0" begin
        cash_flows = [
            DiffFusion.FixedCashFlow(2.0, 0.01)
            DiffFusion.FixedCashFlow(3.0, 0.01)
            DiffFusion.FixedCashFlow(4.0, 0.01)
        ]
        intitial_notional = 100. # GBP
        curve_key_dom = "EUR:XCCY"
        curve_key_for = "GBP:XCCY"
        fx_key_dom = "EUR-USD"
        fx_key_for = "GBP-USD"
        fx_reset_times = [ 1.0, 2.0, 3.0 ]
        fx_pay_times   = [ 2.0, 3.0, 4.0 ]
        payer_receiver = 1.0
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            curve_key_dom,
            curve_key_for,
            fx_key_dom,
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 2.5)
        @test length(payoffs) == 4
        @test string(payoffs[1]) == "(S(EUR-USD, 2.50) * (S(GBP-USD, 2.00) / S(EUR-USD, 2.00)) * 100.0000 * P(EUR:XCCY, 2.50, 3.00) * 0.0100 @ 2.50)"
        @test string(payoffs[2]) == "(S(EUR-USD, 2.50) * P(EUR:XCCY, 2.50, 3.00) * ((S(GBP-USD, 2.00) / S(EUR-USD, 2.00)) - ((S(GBP-USD, 2.50) / S(EUR-USD, 2.50)) * P(GBP:XCCY, 2.50, 3.00) / P(EUR:XCCY, 2.50, 3.00))) * 100.0000 @ 2.50)"
        #
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-EUR-Swap",
            cash_flows,
            intitial_notional,
            "USD:OIS",
            curve_key_for,
            nothing, # DOM = NUM
            fx_key_for,
            fx_reset_times,
            fx_pay_times,
            payer_receiver,
        )        #
        payoffs = DiffFusion.discounted_cashflows(leg, 2.5)
        @test length(payoffs) == 4
        @test string(payoffs[1]) == "(S(GBP-USD, 2.00) * 100.0000 * P(USD:OIS, 2.50, 3.00) * 0.0100 @ 2.50)"
        @test string(payoffs[2]) == "(P(USD:OIS, 2.50, 3.00) * (S(GBP-USD, 2.00) - (S(GBP-USD, 2.50) * P(GBP:XCCY, 2.50, 3.00) / P(USD:OIS, 2.50, 3.00))) * 100.0000 @ 2.50)"
        # for p in payoffs
        #     println(string(p))
        #     println(DiffFusion.obs_times(p))
        # end
        # println()
    end

    @testset "Mark-to-mark leg from deterministic leg" begin
        cash_flows = [
            DiffFusion.FixedCashFlow(2.0, 0.01)
            DiffFusion.FixedCashFlow(3.0, 0.01)
            DiffFusion.FixedCashFlow(4.0, 0.01)
        ]
        intitial_notional = 100. # GBP
        initial_reset_time = 1.0
        curve_key_for = "GBP:XCCY"
        fx_key_for = "GBP-USD"
        payer_receiver = 1.0
        #
        determ_leg = DiffFusion.cashflow_leg(
            "GBP-USD-Swap",
            cash_flows,
            ones(length(cash_flows)),
            "USD:OIS",
            nothing,
            payer_receiver,
        )
        leg = DiffFusion.mtm_cashflow_leg(
            "GBP-USD-Swap",
            determ_leg,
            intitial_notional,
            initial_reset_time,
            curve_key_for,
            fx_key_for,
        )
        payoffs = DiffFusion.discounted_cashflows(leg, 2.5)
        @test length(payoffs) == 4
        @test string(payoffs[1]) == "(S(GBP-USD, 2.00) * 100.0000 * P(USD:OIS, 2.50, 3.00) * 0.0100 @ 2.50)"
        @test string(payoffs[2]) == "(P(USD:OIS, 2.50, 3.00) * (S(GBP-USD, 2.00) - (S(GBP-USD, 2.50) * P(GBP:XCCY, 2.50, 3.00) / P(USD:OIS, 2.50, 3.00))) * 100.0000 @ 2.50)"
        #for p in payoffs
        #    println(string(p))
        #    println(DiffFusion.obs_times(p))
        #end
        #println()
    end


end
