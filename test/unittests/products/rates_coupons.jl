
using DiffFusion
using Test

@testset "Interest rate coupons." begin

    @testset "FixedRateCoupon test" begin
        C = DiffFusion.FixedRateCoupon(2.0, 0.05, 0.5)
        @test DiffFusion.pay_time(C) == 2.0
        @test DiffFusion.year_fraction(C) == 0.5
        @test DiffFusion.coupon_rate(C) === DiffFusion.Fixed(0.05)
        @test DiffFusion.forward_rate(C, 1.0) === DiffFusion.Fixed(0.05)
        @test DiffFusion.amount(C) === DiffFusion.Fixed(0.05) * DiffFusion.Fixed(0.5)
        @test DiffFusion.expected_amount(C, 1.0) === DiffFusion.Fixed(0.05) * DiffFusion.Fixed(0.5)
        #
        @test_throws ErrorException DiffFusion.first_time(C)
        C = DiffFusion.FixedRateCoupon(2.0, 0.05, 0.5, 1.5)
        @test DiffFusion.first_time(C) == 1.5
    end

    @testset "SimpleRateCoupon test" begin
        C = DiffFusion.SimpleRateCoupon(1.8, 2.0, 3.0, 3.2, 1.0, "EUR6M", nothing, nothing)
        @test DiffFusion.pay_time(C) == 3.2
        @test DiffFusion.year_fraction(C) == 1.0
        @test DiffFusion.first_time(C) == 1.8
        @test string(DiffFusion.amount(C))               == "L(EUR6M, 1.80; 2.00, 3.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 1.0)) == "L(EUR6M, 1.00; 2.00, 3.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 1.9)) == "L(EUR6M, 1.80; 2.00, 3.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 2.5)) == "L(EUR6M, 1.80; 2.00, 3.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 3.5)) == "L(EUR6M, 1.80; 2.00, 3.00) * 1.0000"
        #
        C = DiffFusion.SimpleRateCoupon(1.8, 2.0, 3.0, 3.2, 1.0, "EUR6M", nothing, 0.01)
        @test string(DiffFusion.amount(C))               == "(L(EUR6M, 1.80; 2.00, 3.00) + 0.0100) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 1.0)) == "(L(EUR6M, 1.00; 2.00, 3.00) + 0.0100) * 1.0000"
        #
        C = DiffFusion.SimpleRateCoupon(-0.5, -0.5, 1.5, 1.5, 1.0, "EUR6M", nothing, nothing)
        @test_throws AssertionError DiffFusion.amount(C)
        #
        C = DiffFusion.SimpleRateCoupon(-0.5, -0.5, 0.5, 1.0, 1.0, "EUR6M", "EURIBOR", nothing)
        @test string(DiffFusion.amount(C))                 == "Idx(EURIBOR, -0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.25) ) == "Idx(EURIBOR, -0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.25) ) == "Idx(EURIBOR, -0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.75) ) == "Idx(EURIBOR, -0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 2.75) ) == "Idx(EURIBOR, -0.50) * 1.0000"
        #
        C = DiffFusion.SimpleRateCoupon(-0.5, -0.5, 0.5, 1.0, 1.0, "EUR6M", "EURIBOR", 0.01)
        @test string(DiffFusion.amount(C)) == "(Idx(EURIBOR, -0.50) + 0.0100) * 1.0000"
    end

    @testset "CompoundedRateCoupon test" begin
        period_times = 1.0:0.1:2.0
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", nothing, nothing)
        @test DiffFusion.pay_time(C) == 2.0
        @test DiffFusion.year_fraction(C) == 1.0
        @test DiffFusion.first_time(C) == 1.0
        @test string(DiffFusion.amount(C))               == "R(USD:SOFR, 2.00; 1.00, 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.5)) == "R(USD:SOFR, 0.50; 1.00, 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 1.0)) == "R(USD:SOFR, 1.00; 1.00, 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 1.5)) == "R(USD:SOFR, 1.50; 1.00, 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 3.0)) == "R(USD:SOFR, 3.00; 1.00, 2.00) * 1.0000"
        #
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", nothing, 0.01)
        @test string(DiffFusion.amount(C))               == "(R(USD:SOFR, 2.00; 1.00, 2.00) + 0.0100) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.5)) == "(R(USD:SOFR, 0.50; 1.00, 2.00) + 0.0100) * 1.0000"
        #
        period_times = -0.5:0.25:0.5
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", nothing, nothing)
        @test_throws AssertionError DiffFusion.amount(C)
        #
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", "SOFR", nothing)
        @test string(DiffFusion.amount(C)) == "R(USD:SOFR, 0.50; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.0)) == "R(USD:SOFR, 0.00; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.2)) == "R(USD:SOFR, 0.20; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.4)) == "R(USD:SOFR, 0.40; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.6)) == "R(USD:SOFR, 0.60; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) * 1.0000"
        #
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", "SOFR", 0.01)
        @test string(DiffFusion.amount(C)) == "(R(USD:SOFR, 0.50; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) + 0.0100) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.4)) == "(R(USD:SOFR, 0.40; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) + 0.0100) * 1.0000"
        #
        period_times = -0.9:0.25:0.1
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", "SOFR", nothing)
        @test string(DiffFusion.amount(C)) == "(((1.0000 + Idx(SOFR, -0.90) * 0.2500) * (1.0000 + Idx(SOFR, -0.65) * 0.2500) * (1.0000 + Idx(SOFR, -0.40) * 0.2500) * (1.0000 + Idx(SOFR, -0.15) * 0.2500) - 1.0000) / 1.0000) * 1.0000"
        @test string(DiffFusion.expected_amount(C, 0.0)) == string(DiffFusion.amount(C))
        @test string(DiffFusion.expected_amount(C, 0.05)) == string(DiffFusion.amount(C))
        @test string(DiffFusion.expected_amount(C, 0.1)) == string(DiffFusion.amount(C))
        @test string(DiffFusion.expected_amount(C, 0.2)) == string(DiffFusion.amount(C))
        # println(string(DiffFusion.amount(C)))
        # println(string(DiffFusion.expected_amount(C, 0.0)))
    end

    @testset "CompoundedRate option test" begin
        period_times = 1.0:0.1:2.0
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", nothing, nothing)
        O = DiffFusion.OptionletCoupon(C, 0.01, +1.0)  # expiry_time from CompoundedRateCoupon
        @test DiffFusion.pay_time(O) == 2.0
        @test DiffFusion.year_fraction(O) == 1.0
        @test string(DiffFusion.amount(O))               == "Max(1.0000 * (R(USD:SOFR, 2.00; 1.00, 2.00) - 0.0100), 0.0000) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.5)) == "Caplet(R(USD:SOFR, 0.50; 1.00, 2.00), 0.0100; 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 1.0)) == "Caplet(R(USD:SOFR, 1.00; 1.00, 2.00), 0.0100; 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 1.5)) == "Caplet(R(USD:SOFR, 1.50; 1.00, 2.00), 0.0100; 2.00) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 3.0)) == "Max(1.0000 * (R(USD:SOFR, 2.00; 1.00, 2.00) - 0.0100), 0.0000) * 1.0000"
        #
        period_times = -0.5:0.25:0.5
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", nothing, nothing)
        O = DiffFusion.OptionletCoupon(period_times[end], C, 0.01, -1.0)
        @test_throws AssertionError DiffFusion.amount(C)
        #
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", "SOFR", nothing)
        O = DiffFusion.OptionletCoupon(period_times[end], C, 0.01, -1.0)
        @test string(DiffFusion.amount(O)) == "Max(-1.0000 * (R(USD:SOFR, 0.50; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) - 0.0100), 0.0000) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.0)) == "Floorlet(R(USD:SOFR, 0.00; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)), 0.0100; 0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.2)) == "Floorlet(R(USD:SOFR, 0.20; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)), 0.0100; 0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.4)) == "Floorlet(R(USD:SOFR, 0.40; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)), 0.0100; 0.50) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.6)) == "Max(-1.0000 * (R(USD:SOFR, 0.50; 0.00, 0.50; (1.0000 + Idx(SOFR, -0.50) * 0.2500) * (1.0000 + Idx(SOFR, -0.25) * 0.2500)) - 0.0100), 0.0000) * 1.0000"
        # println(string(expected_amount(O, 0.4)))
        #
        period_times = -0.9:0.25:0.1
        period_year_fractions = period_times[2:end] - period_times[1:end-1]
        C = DiffFusion.CompoundedRateCoupon(period_times, period_year_fractions, period_times[end], "USD:SOFR", "SOFR", nothing)
        O = DiffFusion.OptionletCoupon(period_times[end], C, 0.01, -1.0)
        @test string(DiffFusion.amount(O)) == "Max(-1.0000 * ((((1.0000 + Idx(SOFR, -0.90) * 0.2500) * (1.0000 + Idx(SOFR, -0.65) * 0.2500) * (1.0000 + Idx(SOFR, -0.40) * 0.2500) * (1.0000 + Idx(SOFR, -0.15) * 0.2500) - 1.0000) / 1.0000) - 0.0100), 0.0000) * 1.0000"
        @test string(DiffFusion.expected_amount(O, 0.0)) == string(DiffFusion.amount(O))
        @test string(DiffFusion.expected_amount(O, 0.05)) == string(DiffFusion.amount(O))
        @test string(DiffFusion.expected_amount(O, 0.1)) == string(DiffFusion.amount(O))
        @test string(DiffFusion.expected_amount(O, 0.2)) == string(DiffFusion.amount(O))
        # println(string(amount(O)))
        # println(string(expected_amount(O, 0.0)))
    end

    @testset "CombinedCashFlow test." begin
        C = DiffFusion.SimpleRateCoupon(1.8, 2.0, 3.0, 3.2, 1.0, "EUR6M", nothing, nothing)
        @test_throws AssertionError C + DiffFusion.FixedRateCoupon(2.0, 0.05, 1.0)
        F = DiffFusion.FixedRateCoupon(3.2, 0.01, 1.0)
        C = C + F
        @test string(DiffFusion.amount(C)) == "(L(EUR6M, 1.80; 2.00, 3.00) * 1.0000 + 0.0100 * 1.0000)"
        @test string(DiffFusion.expected_amount(C, 1.0)) == "(L(EUR6M, 1.00; 2.00, 3.00) * 1.0000 + 0.0100 * 1.0000)"
    end

end
