using DiffFusion
using Test

@testset "Credit-risky cash flow leg" begin

        cash_flows = [
            # pay_time, fixed_rate, year_fraction, first_time
            DiffFusion.FixedRateCoupon(1.0, 0.03, 1.01, 0.0),
            DiffFusion.FixedRateCoupon(2.0, 0.03, 1.01, 1.0),
            DiffFusion.FixedRateCoupon(3.0, 0.03, 1.01, 2.0),
            DiffFusion.FixedCashFlow(3.0, 1.0),  # notional at maturity
        ]
        notionals = 100.0 * ones(4)
        #
        leg = DiffFusion.cashflow_leg(
            "One",
            cash_flows,
            notionals,
            "EUR:OIS",
            # "EUR-USD",
        )

    @testset "Zero recovery rate leg" begin
        credit_curve_key = "CDS:EU"
        recovery_rate = 0.0
        credit_risky_leg = DiffFusion.credit_risky_cashflow_leg(leg, credit_curve_key, recovery_rate)
        payoffs_tst = DiffFusion.future_cashflows(credit_risky_leg, 0.0)
        payoffs_ref = DiffFusion.future_cashflows(leg, 0.0)
        for (p_tst, p_ref) in zip(payoffs_tst, payoffs_ref)
            @test string(p_tst) == string(p_ref)
        end
        #
        payoffs = DiffFusion.discounted_cashflows(credit_risky_leg, 1.5)
        @test length(payoffs) == 3
        @test string(payoffs[1]) == "(Q(CDS:EU, 1.50, 2.00) * P(EUR:OIS, 1.50, 2.00) * 100.0000 * 0.0300 * 1.0100 @ 1.50)"
        @test string(payoffs[2]) == "(Q(CDS:EU, 1.50, 3.00) * P(EUR:OIS, 1.50, 3.00) * 100.0000 * 0.0300 * 1.0100 @ 1.50)"
        @test string(payoffs[3]) == "(Q(CDS:EU, 1.50, 3.00) * P(EUR:OIS, 1.50, 3.00) * 100.0000 * 1.0000 @ 1.50)"
    end

    @testset "Non-zero recovery rate leg" begin
        credit_curve_key = "CDS:EU"
        recovery_rate = 0.40
        credit_risky_leg = DiffFusion.credit_risky_cashflow_leg(leg, credit_curve_key, recovery_rate)
        payoffs_tst = DiffFusion.future_cashflows(credit_risky_leg, 0.0)
        payoffs_ref = DiffFusion.future_cashflows(leg, 0.0)
        for (p_tst, p_ref) in zip(payoffs_tst, payoffs_ref)
            @test string(p_tst) == string(p_ref)
        end
        #
        payoffs = DiffFusion.discounted_cashflows(credit_risky_leg, 1.5)
        @test length(payoffs) == 5
        @test string(payoffs[1]) == "(Q(CDS:EU, 1.50, 2.00) * P(EUR:OIS, 1.50, 2.00) * 100.0000 * 0.0300 * 1.0100 @ 1.50)"
        @test string(payoffs[2]) == "(Q(CDS:EU, 1.50, 3.00) * P(EUR:OIS, 1.50, 3.00) * 100.0000 * 0.0300 * 1.0100 @ 1.50)"
        @test string(payoffs[3]) == "(Q(CDS:EU, 1.50, 3.00) * P(EUR:OIS, 1.50, 3.00) * 100.0000 * 1.0000 @ 1.50)"
        @test string(payoffs[4]) == "((Q(CDS:EU, 1.50, 1.50) - Q(CDS:EU, 1.50, 2.00)) * P(EUR:OIS, 1.50, 1.75) * 40.0000 * 1.0000 @ 1.50)"
        @test string(payoffs[5]) == "((Q(CDS:EU, 1.50, 2.00) - Q(CDS:EU, 1.50, 3.00)) * P(EUR:OIS, 1.50, 2.50) * 40.0000 * 1.0000 @ 1.50)"
    end

    @testset "Non-zero recovery rate leg with currency exchange" begin
        leg = DiffFusion.cashflow_leg(
            "One",
            cash_flows,
            notionals,
            "EUR:OIS",
            "EUR-USD",
        )
        credit_curve_key = "CDS:EU"
        recovery_rate = 0.40
        credit_risky_leg = DiffFusion.credit_risky_cashflow_leg(leg, credit_curve_key, recovery_rate)
        payoffs_tst = DiffFusion.future_cashflows(credit_risky_leg, 0.0)
        payoffs_ref = DiffFusion.future_cashflows(leg, 0.0)
        for (p_tst, p_ref) in zip(payoffs_tst, payoffs_ref)
            @test string(p_tst) == string(p_ref)
        end
        #
        payoffs = DiffFusion.discounted_cashflows(credit_risky_leg, 2.5)
        @test length(payoffs) == 3
        @test string(payoffs[1]) == "(Q(CDS:EU, 2.50, 3.00) * S(EUR-USD, 2.50) * P(EUR:OIS, 2.50, 3.00) * 100.0000 * 0.0300 * 1.0100 @ 2.50)"
        @test string(payoffs[2]) == "(Q(CDS:EU, 2.50, 3.00) * S(EUR-USD, 2.50) * P(EUR:OIS, 2.50, 3.00) * 100.0000 * 1.0000 @ 2.50)"
        @test string(payoffs[3]) == "((Q(CDS:EU, 2.50, 2.50) - Q(CDS:EU, 2.50, 3.00)) * S(EUR-USD, 2.50) * P(EUR:OIS, 2.50, 2.75) * 40.0000 * 1.0000 @ 2.50)"
    end

end