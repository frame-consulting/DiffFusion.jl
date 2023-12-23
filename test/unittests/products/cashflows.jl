
using DiffFusion
using Test

@testset "General cash flows." begin

    @testset "Abstract CashFlow" begin
        struct NoCashFlow <: DiffFusion.CashFlow end
        @test_throws ErrorException DiffFusion.pay_time(NoCashFlow())
        @test_throws ErrorException DiffFusion.amount(NoCashFlow())
        @test_throws ErrorException DiffFusion.expected_amount(NoCashFlow(), 1.0)
    end

    @testset "Abstract Coupon" begin
        struct NoCoupon <: DiffFusion.Coupon end
        @test_throws ErrorException DiffFusion.year_fraction(NoCoupon())
        @test_throws ErrorException DiffFusion.coupon_rate(NoCoupon())
        @test_throws ErrorException DiffFusion.forward_rate(NoCoupon(), 1.0)
        @test_throws ErrorException DiffFusion.first_time(NoCoupon())
        struct SimpleCoupon <: DiffFusion.Coupon
            pay_time::DiffFusion.ModelTime
        end
        DiffFusion.year_fraction(cf::SimpleCoupon) = 0.5
        DiffFusion.coupon_rate(cf::SimpleCoupon) = 2.0
        DiffFusion.forward_rate(cf::SimpleCoupon, t::DiffFusion.ModelTime) = 4.0
        #
        c = SimpleCoupon(1.0)
        @test DiffFusion.pay_time(c) == 1.0
        @test DiffFusion.amount(c) == 1.0
        @test DiffFusion.expected_amount(c, 2.0) == 2.0
    end

    @testset "FixedCashFlow" begin
        C = DiffFusion.FixedCashFlow(2.0, 100.0)
        @test DiffFusion.pay_time(C) == 2.0
        @test DiffFusion.amount(C) === DiffFusion.Fixed(100.0)
        @test DiffFusion.expected_amount(C, 1.0) === DiffFusion.Fixed(100.0)
    end


end

