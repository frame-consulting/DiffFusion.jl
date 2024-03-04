
using DiffFusion

using Test

@testset "Relative return coupons." begin

    @testset "Non-trivial year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnCoupon(3.0, 5.0, 9.0, 2.0, "EUHICP", "EUR", "EURHICP-RR")
        @test DiffFusion.pay_time(C) == 9.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.Asset(5.0, "EUHICP") / DiffFusion.Asset(3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "((((S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 5.00) / P(EUR, 0.00, 5.00)) / (S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 3.00) / P(EUR, 0.00, 3.00))) * Exp{CA(EUHICP, 0.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "((((S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 5.00) / P(EUR, 1.00, 5.00)) / (S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 3.00) / P(EUR, 1.00, 3.00))) * Exp{CA(EUHICP, 1.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "((((S(EUHICP, 3.00) * P(EURHICP-RR, 3.00, 5.00) / P(EUR, 3.00, 5.00)) / S(EUHICP, 3.00)) * Exp{CA(EUHICP, 3.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "((((S(EUHICP, 4.00) * P(EURHICP-RR, 4.00, 5.00) / P(EUR, 4.00, 5.00)) / S(EUHICP, 3.00)) * Exp{CA(EUHICP, 4.00, 4.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((S(EUHICP, 5.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((S(EUHICP, 5.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

    @testset "No payment delay year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnCoupon(3.0, 5.0, 5.0, 2.0, "EUHICP", "EUR", "EURHICP-RR")
        @test DiffFusion.pay_time(C) == 5.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.Asset(5.0, "EUHICP") / DiffFusion.Asset(3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "((((S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 5.00) / P(EUR, 0.00, 5.00)) / (S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 3.00) / P(EUR, 0.00, 3.00))) * Exp{CA(EUHICP, 0.00, 3.00, 5.00, 5.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "((((S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 5.00) / P(EUR, 1.00, 5.00)) / (S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 3.00) / P(EUR, 1.00, 3.00))) * Exp{CA(EUHICP, 1.00, 3.00, 5.00, 5.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "((((S(EUHICP, 3.00) * P(EURHICP-RR, 3.00, 5.00) / P(EUR, 3.00, 5.00)) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "((((S(EUHICP, 4.00) * P(EURHICP-RR, 4.00, 5.00) / P(EUR, 4.00, 5.00)) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((S(EUHICP, 5.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((S(EUHICP, 5.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

    @testset "Trivial year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnCoupon(3.0, 3.0, 5.0, 2.0, "EUHICP", "EUR", "EURHICP-RR")
        @test DiffFusion.pay_time(C) == 5.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.Asset(3.0, "EUHICP") / DiffFusion.Asset(3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "((((S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 3.00) / P(EUR, 0.00, 3.00)) / (S(EUHICP, 0.00) * P(EURHICP-RR, 0.00, 3.00) / P(EUR, 0.00, 3.00))) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "((((S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 3.00) / P(EUR, 1.00, 3.00)) / (S(EUHICP, 1.00) * P(EURHICP-RR, 1.00, 3.00) / P(EUR, 1.00, 3.00))) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "(((S(EUHICP, 3.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "(((S(EUHICP, 3.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((S(EUHICP, 3.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((S(EUHICP, 3.00) / S(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

    @testset "Non-trivial year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnIndexCoupon(3.0, 5.0, 9.0, 2.0, "EUHICP")
        @test DiffFusion.pay_time(C) == 9.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.ForwardIndex(5.0, 5.0, "EUHICP") / DiffFusion.ForwardIndex(3.0, 3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "(((I(EUHICP, 0.00, 5.00) / I(EUHICP, 0.00, 3.00)) * Exp{CA(EUHICP, 0.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "(((I(EUHICP, 1.00, 5.00) / I(EUHICP, 1.00, 3.00)) * Exp{CA(EUHICP, 1.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "(((I(EUHICP, 3.00, 5.00) / I(EUHICP, 3.00)) * Exp{CA(EUHICP, 3.00, 3.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "(((I(EUHICP, 4.00, 5.00) / I(EUHICP, 3.00)) * Exp{CA(EUHICP, 4.00, 4.00, 5.00, 9.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((I(EUHICP, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((I(EUHICP, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

    @testset "No payment delay year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnIndexCoupon(3.0, 5.0, 5.0, 2.0, "EUHICP")
        @test DiffFusion.pay_time(C) == 5.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.ForwardIndex(5.0, 5.0, "EUHICP") / DiffFusion.ForwardIndex(3.0, 3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "(((I(EUHICP, 0.00, 5.00) / I(EUHICP, 0.00, 3.00)) * Exp{CA(EUHICP, 0.00, 3.00, 5.00, 5.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "(((I(EUHICP, 1.00, 5.00) / I(EUHICP, 1.00, 3.00)) * Exp{CA(EUHICP, 1.00, 3.00, 5.00, 5.00)} - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "(((I(EUHICP, 3.00, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "(((I(EUHICP, 4.00, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((I(EUHICP, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((I(EUHICP, 5.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

    @testset "Trivial year-on-Year coupon. " begin
        C = DiffFusion.RelativeReturnIndexCoupon(3.0, 3.0, 5.0, 2.0, "EUHICP")
        @test DiffFusion.pay_time(C) == 5.0
        @test DiffFusion.year_fraction(C) == 2.0
        @test DiffFusion.coupon_rate(C) === (DiffFusion.ForwardIndex(3.0, 3.0, "EUHICP") / DiffFusion.ForwardIndex(3.0, 3.0, "EUHICP") - 1.0) / 2.0
        @test string(DiffFusion.forward_rate(C, 0.0)) == "(((I(EUHICP, 0.00, 3.00) / I(EUHICP, 0.00, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 1.0)) == "(((I(EUHICP, 1.00, 3.00) / I(EUHICP, 1.00, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 3.0)) == "(((I(EUHICP, 3.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 4.0)) == "(((I(EUHICP, 3.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 5.0)) == "(((I(EUHICP, 3.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
        @test string(DiffFusion.forward_rate(C, 9.0)) == "(((I(EUHICP, 3.00) / I(EUHICP, 3.00)) - 1.0000) / 2.0000)"
    end

end