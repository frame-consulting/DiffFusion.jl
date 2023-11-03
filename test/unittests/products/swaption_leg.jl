
using DiffFusion

using Test

@testset "SwaptionLeg tests." begin
    
    @testset "Libor cash-settled swaption tests." begin
        expiry_time = 4.9
        settlement_time = 5.1
        float_coupons = [
            DiffFusion.SimpleRateCoupon(5.0, 5.0, 6.0, 6.0, 1.0, "E12M", nothing, nothing),
            DiffFusion.SimpleRateCoupon(6.0, 6.0, 7.0, 7.0, 1.0, "E12M", nothing, nothing),
        ]
        fixed_couons = [
            DiffFusion.FixedRateCoupon(6.0, 0.02, 1.0)
            DiffFusion.FixedRateCoupon(7.0, 0.02, 1.0)
        ]
        payer_receiver = 1.0
        swap_disc_curve_key = "EUR:OIS"
        settlement_type = DiffFusion.SwaptionCashSettlement
        #
        notional = 100.0
        swpt_disc_curve_key = "EUR:XCY"
        swpt_fx_key = "EUR-USD"
        swpt_long_short = -1.0
        #
        swpt = DiffFusion.SwaptionLeg(
            "swpt/1",
            expiry_time,
            settlement_time,
            float_coupons,
            fixed_couons,
            payer_receiver,
            swap_disc_curve_key,
            settlement_type,
            notional,
            swpt_disc_curve_key,
            swpt_fx_key,
            swpt_long_short,
        )
        @test DiffFusion.alias(swpt) == "swpt/1"
        #
        @test length(DiffFusion.future_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.future_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 5.05)[1]) == "(S(EUR-USD, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test length(DiffFusion.future_cashflows(swpt, 5.1)) == 0
        @test length(DiffFusion.future_cashflows(swpt, 6.0)) == 0
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.discounted_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 0.00) * P(EUR:XCY, 0.00, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 0.00; 5.00, 6.00),...,L(E12M, 0.00; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 0.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 2.50) * P(EUR:XCY, 2.50, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 2.50; 5.00, 6.00),...,L(E12M, 2.50; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 2.50)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.00) * P(EUR:XCY, 5.00, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.00)"
        @test length(DiffFusion.discounted_cashflows(swpt, 5.1)) == 0
        @test length(DiffFusion.discounted_cashflows(swpt, 6.0)) == 0
        # cfs = DiffFusion.discounted_cashflows(swpt, 0.0)
        # for p in cfs
        #     println(string(p))
        # end
    end

    @testset "Libor physically-settled swaption tests." begin
        expiry_time = 4.9
        settlement_time = 5.1
        float_coupons = [
            DiffFusion.SimpleRateCoupon(5.0, 5.0, 6.0, 6.0, 1.0, "E12M", nothing, nothing),
            DiffFusion.SimpleRateCoupon(6.0, 6.0, 7.0, 7.0, 1.0, "E12M", nothing, nothing),
        ]
        fixed_couons = [
            DiffFusion.FixedRateCoupon(6.0, 0.02, 1.0)
            DiffFusion.FixedRateCoupon(7.0, 0.02, 1.0)
        ]
        payer_receiver = 1.0
        swap_disc_curve_key = "EUR:OIS"
        settlement_type = DiffFusion.SwaptionPhysicalSettlement
        #
        notional = 100.0
        swpt_disc_curve_key = "EUR:XCY"
        swpt_fx_key = "EUR-USD"
        swpt_long_short = -1.0
        #
        swpt = DiffFusion.SwaptionLeg(
            "swpt/2",
            expiry_time,
            settlement_time,
            float_coupons,
            fixed_couons,
            payer_receiver,
            swap_disc_curve_key,
            settlement_type,
            notional,
            swpt_disc_curve_key,
            swpt_fx_key,
            swpt_long_short,
        )
        @test DiffFusion.alias(swpt) == "swpt/2"
        #
        @test length(DiffFusion.future_cashflows(swpt, 2.5)) == 4
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 6.00) * -100.0000 * L(E12M, 5.00; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[2]) == "(S(EUR-USD, 7.00) * -100.0000 * L(E12M, 6.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[3]) == "(S(EUR-USD, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[4]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 5.5)) == 4
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[1]) == "(S(EUR-USD, 6.00) * -100.0000 * L(E12M, 5.00; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[2]) == "(S(EUR-USD, 7.00) * -100.0000 * L(E12M, 6.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[3]) == "(S(EUR-USD, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[4]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 6.0)) == 2
        @test string(DiffFusion.future_cashflows(swpt, 6.0)[1]) == "(S(EUR-USD, 7.00) * -100.0000 * L(E12M, 6.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 6.0)[2]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 7.0)) == 0
        @test length(DiffFusion.future_cashflows(swpt, 8.0)) == 0
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.discounted_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 0.00) * P(EUR:XCY, 0.00, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 0.00; 5.00, 6.00),...,L(E12M, 0.00; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 0.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 2.50) * P(EUR:XCY, 2.50, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 2.50; 5.00, 6.00),...,L(E12M, 2.50; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 2.50)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.00) * P(EUR:XCY, 5.00, 5.10) * -100.0000 * Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.00)"
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 5.1)) == 4
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[1]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 6.00) * -100.0000 * L(E12M, 5.00; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[2]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 7.00) * -100.0000 * L(E12M, 5.10; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[3]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[4]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 6.0)) == 2
        @test string(DiffFusion.discounted_cashflows(swpt, 6.0)[1]) == "(S(EUR-USD, 6.00) * P(EUR:OIS, 6.00, 7.00) * -100.0000 * L(E12M, 6.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 6.0)[2]) == "(S(EUR-USD, 6.00) * P(EUR:OIS, 6.00, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([L(E12M, 4.90; 5.00, 6.00),...,L(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test length(DiffFusion.discounted_cashflows(swpt, 7.0)) == 0
        @test length(DiffFusion.discounted_cashflows(swpt, 8.0)) == 0
        # cfs = DiffFusion.discounted_cashflows(swpt, 6.0)
        # for p in cfs
        #     println(string(p))
        # end
    end

    @testset "OIS cash-settled swaption tests." begin
        expiry_time = 4.9
        settlement_time = 5.1
        period_times_1 = 5.0:0.1:6.0
        period_times_2 = 6.0:0.1:7.0
        period_year_fractions_1 = period_times_1[2:end] - period_times_1[1:end-1]
        period_year_fractions_2 = period_times_2[2:end] - period_times_2[1:end-1]
        float_coupons = [
            DiffFusion.CompoundedRateCoupon(period_times_1, period_year_fractions_1, 6.0, "E12M", nothing, nothing),
            DiffFusion.CompoundedRateCoupon(period_times_2, period_year_fractions_2, 7.0, "E12M", nothing, nothing),
        ]
        fixed_couons = [
            DiffFusion.FixedRateCoupon(6.0, 0.02, 1.0)
            DiffFusion.FixedRateCoupon(7.0, 0.02, 1.0)
        ]
        payer_receiver = -1.0
        swap_disc_curve_key = "EUR:OIS"
        settlement_type = DiffFusion.SwaptionCashSettlement
        #
        notional = 100.0
        swpt_disc_curve_key = "EUR:XCY"
        swpt_fx_key = "EUR-USD"
        swpt_long_short = 1.0
        #
        swpt = DiffFusion.SwaptionLeg(
            "swpt/3",
            expiry_time,
            settlement_time,
            float_coupons,
            fixed_couons,
            payer_receiver,
            swap_disc_curve_key,
            settlement_type,
            notional,
            swpt_disc_curve_key,
            swpt_fx_key,
            swpt_long_short,
        )
        @test DiffFusion.alias(swpt) == "swpt/3"
        #
        @test length(DiffFusion.future_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.future_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test string(DiffFusion.future_cashflows(swpt, 5.05)[1]) == "(S(EUR-USD, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.10)"
        @test length(DiffFusion.future_cashflows(swpt, 5.1)) == 0
        @test length(DiffFusion.future_cashflows(swpt, 6.0)) == 0
        # #
        @test length(DiffFusion.discounted_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.discounted_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 0.00) * P(EUR:XCY, 0.00, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 0.00; 5.00, 6.00),...,R(E12M, 0.00; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 0.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 2.50) * P(EUR:XCY, 2.50, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 2.50; 5.00, 6.00),...,R(E12M, 2.50; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 2.50)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.00) * P(EUR:XCY, 5.00, 5.10) * 100.0000 * Swaption_Rec([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.00)"
        @test length(DiffFusion.discounted_cashflows(swpt, 5.1)) == 0
        @test length(DiffFusion.discounted_cashflows(swpt, 6.0)) == 0
        # cfs = DiffFusion.discounted_cashflows(swpt, 0.0)
        # for p in cfs
        #     println(string(p))
        # end
    end


    @testset "OIS physically-settled swaption tests." begin
        expiry_time = 4.9
        settlement_time = 5.1
        period_times_1 = 5.0:0.1:6.0
        period_times_2 = 6.0:0.1:7.0
        period_year_fractions_1 = period_times_1[2:end] - period_times_1[1:end-1]
        period_year_fractions_2 = period_times_2[2:end] - period_times_2[1:end-1]
        float_coupons = [
            DiffFusion.CompoundedRateCoupon(period_times_1, period_year_fractions_1, 6.0, "E12M", nothing, nothing),
            DiffFusion.CompoundedRateCoupon(period_times_2, period_year_fractions_2, 7.0, "E12M", nothing, nothing),
        ]
        fixed_couons = [
            DiffFusion.FixedRateCoupon(6.0, 0.02, 1.0)
            DiffFusion.FixedRateCoupon(7.0, 0.02, 1.0)
        ]
        payer_receiver = 1.0
        swap_disc_curve_key = "EUR:OIS"
        settlement_type = DiffFusion.SwaptionPhysicalSettlement
        #
        notional = 100.0
        swpt_disc_curve_key = "EUR:XCY"
        swpt_fx_key = "EUR-USD"
        swpt_long_short = -1.0
        #
        swpt = DiffFusion.SwaptionLeg(
            "swpt/4",
            expiry_time,
            settlement_time,
            float_coupons,
            fixed_couons,
            payer_receiver,
            swap_disc_curve_key,
            settlement_type,
            notional,
            swpt_disc_curve_key,
            swpt_fx_key,
            swpt_long_short,
        )
        @test DiffFusion.alias(swpt) == "swpt/4"
        #
        @test length(DiffFusion.future_cashflows(swpt, 2.5)) == 4
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 6.00) * -100.0000 * R(E12M, 6.00; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[2]) == "(S(EUR-USD, 7.00) * -100.0000 * R(E12M, 7.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[3]) == "(S(EUR-USD, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 2.5)[4]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 5.5)) == 4
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[1]) == "(S(EUR-USD, 6.00) * -100.0000 * R(E12M, 6.00; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[2]) == "(S(EUR-USD, 7.00) * -100.0000 * R(E12M, 7.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[3]) == "(S(EUR-USD, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.future_cashflows(swpt, 5.5)[4]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 6.0)) == 2
        @test string(DiffFusion.future_cashflows(swpt, 6.0)[1]) == "(S(EUR-USD, 7.00) * -100.0000 * R(E12M, 7.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        @test string(DiffFusion.future_cashflows(swpt, 6.0)[2]) == "(S(EUR-USD, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 7.00)"
        #
        @test length(DiffFusion.future_cashflows(swpt, 7.0)) == 0
        @test length(DiffFusion.future_cashflows(swpt, 8.0)) == 0
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 0.0)) == 1
        @test string(DiffFusion.discounted_cashflows(swpt, 0.0)[1]) == "(S(EUR-USD, 0.00) * P(EUR:XCY, 0.00, 5.10) * -100.0000 * Swaption_Pay([R(E12M, 0.00; 5.00, 6.00),...,R(E12M, 0.00; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 0.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 2.5)[1]) == "(S(EUR-USD, 2.50) * P(EUR:XCY, 2.50, 5.10) * -100.0000 * Swaption_Pay([R(E12M, 2.50; 5.00, 6.00),...,R(E12M, 2.50; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 2.50)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.0)[1]) == "(S(EUR-USD, 5.00) * P(EUR:XCY, 5.00, 5.10) * -100.0000 * Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) @ 5.00)"
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 5.1)) == 4
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[1]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 6.00) * -100.0000 * R(E12M, 5.10; 5.00, 6.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[2]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 7.00) * -100.0000 * R(E12M, 5.10; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[3]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 6.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        @test string(DiffFusion.discounted_cashflows(swpt, 5.1)[4]) == "(S(EUR-USD, 5.10) * P(EUR:OIS, 5.10, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 5.10)"
        #
        @test length(DiffFusion.discounted_cashflows(swpt, 6.0)) == 2
        @test string(DiffFusion.discounted_cashflows(swpt, 6.0)[1]) == "(S(EUR-USD, 6.00) * P(EUR:OIS, 6.00, 7.00) * -100.0000 * R(E12M, 6.00; 6.00, 7.00) * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test string(DiffFusion.discounted_cashflows(swpt, 6.0)[2]) == "(S(EUR-USD, 6.00) * P(EUR:OIS, 6.00, 7.00) * 100.0000 * 0.0200 * 1.0000 * {(Swaption_Pay([R(E12M, 4.90; 5.00, 6.00),...,R(E12M, 4.90; 6.00, 7.00)], 0.0200, EUR:OIS; 4.90) > 0.0000)} @ 6.00)"
        @test length(DiffFusion.discounted_cashflows(swpt, 7.0)) == 0
        @test length(DiffFusion.discounted_cashflows(swpt, 8.0)) == 0
        # cfs = DiffFusion.discounted_cashflows(swpt, 6.0)
        # for p in cfs
        #     println(string(p))
        # end
    end



end