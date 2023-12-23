using DiffFusion
using OrderedCollections
using Random
using Test
using YAML


@testset "Test Examples." begin

    @testset "Test leg generation" begin
        leg = DiffFusion.Examples.fixed_rate_leg(
            "", 0.0, 10.0, 1, 0.03, 1.0e+4, "USD"
        )
        @test length(leg.cashflows) == 10
        @test isa(leg.cashflows[1], DiffFusion.FixedRateCoupon)
        #
        leg = DiffFusion.Examples.simple_rate_leg(
            "", 0.0, 2.0, 2, "EUR:EURIBOR6M", "EUR:EURIBOR6M", nothing, 1.0e+4, "EUR", "EUR-USD"
        )
        @test length(leg.cashflows) == 4
        @test isa(leg.cashflows[1], DiffFusion.SimpleRateCoupon)
        #
        leg = DiffFusion.Examples.compounded_rate_leg(
            "", 0.0, 1.0, 4, "USD:SOFR", "USD:SOFR", nothing, 1.0e+4, "USD"
        )
        @test length(leg.cashflows) == 4
        @test isa(leg.cashflows[1], DiffFusion.CompoundedRateCoupon)
        #println(leg)
    end

    yaml_string =
    """
    config/instruments:
      seed: 123456
      swap_types:
        - USD
        - EUR
        - GBP
        - EUR-USD
        - GBP-USD
        - EUR6M-USD3M
      swaption_types:
        - SOFR_SWPN
        - EURIBOR6M_SWPN
        - SONIA_SWPN
      bermudan_types:
        - SOFR_SWPN
        - EURIBOR6M_SWPN
        - SONIA_SWPN
      USD:
        type: VANILLA
        discount_curve_key: USD:SOFR
        fx_key:
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
      EUR:
        type: VANILLA
        discount_curve_key: EUR:XCCY
        fx_key: EUR-USD
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 1
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: SIMPLE
          coupons_per_year: 2
          forward_curve_key: EUR:EURIBOR6M
          fixing_key: EUR:EURIBOR6M
      GBP:
        type: VANILLA
        discount_curve_key: GBP:XCCY
        fx_key: GBP-USD
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: GBP:SONIA
          fixing_key: GBP:SONIA
      EUR-USD:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: EUR:ESTR
          fixing_key: EUR:ESTR
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: EUR:XCCY
          fx_key: EUR-USD
      GBP-USD:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: GBP:SONIA
          fixing_key: GBP:SONIA
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: GBP:XCCY
          fx_key: GBP-USD
      EUR6M-USD3M:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: SIMPLE
          coupons_per_year: 4
          forward_curve_key: USD:LIB3M
          fixing_key: USD:LIB3M
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: SIMPLE
          coupons_per_year: 2
          forward_curve_key: EUR:EURIBOR6M
          fixing_key: EUR:EURIBOR6M
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: EUR:XCCY
          fx_key: EUR-USD
      SOFR_SWPN:
        setlement_type: CASH
        #
        type: VANILLA
        discount_curve_key: USD:SOFR
        fx_key:
        min_start: 1.0
        max_start: 10.0
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
      EURIBOR6M_SWPN:
        setlement_type: CASH
        bermudan_time: 2
        #
        type: VANILLA
        discount_curve_key: EUR:XCCY
        fx_key: EUR-USD
        min_start: 1.0
        max_start: 10.0
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 1
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: SIMPLE
          coupons_per_year: 2
          forward_curve_key: EUR:EURIBOR6M
          fixing_key: EUR:EURIBOR6M
      SONIA_SWPN:
        setlement_type: CASH
        #
        type: VANILLA
        discount_curve_key: GBP:XCCY
        fx_key: GBP-USD
        min_start: 1.0
        max_start: 10.0
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: GBP:SONIA
          fixing_key: GBP:SONIA
    """

    @testset "Test leg generation" begin
        leg = DiffFusion.Examples.fixed_rate_leg(
            "", 0.0, 10.0, 1, 0.03, 1.0e+4, "USD"
        )
        @test length(leg.cashflows) == 10
        @test isa(leg.cashflows[1], DiffFusion.FixedRateCoupon)
        #
        leg = DiffFusion.Examples.simple_rate_leg(
            "", 0.0, 2.0, 2, "EUR:EURIBOR6M", "EUR:EURIBOR6M", nothing, 1.0e+4, "EUR", "EUR-USD"
        )
        @test length(leg.cashflows) == 4
        @test isa(leg.cashflows[1], DiffFusion.SimpleRateCoupon)
        #
        leg = DiffFusion.Examples.compounded_rate_leg(
            "", 0.0, 1.0, 4, "USD:SOFR", "USD:SOFR", nothing, 1.0e+4, "USD"
        )
        @test length(leg.cashflows) == 4
        @test isa(leg.cashflows[1], DiffFusion.CompoundedRateCoupon)
        #println(leg)
    end


    @testset "Test swap generation" begin
        example = YAML.load(yaml_string, dicttype=OrderedDict{String,Any})
        for type_key in example["config/instruments"]["swap_types"]
            swap = DiffFusion.Examples.random_swap(example, type_key)
            @test length(swap) == 2
            @test swap[1].payer_receiver * swap[2].payer_receiver == -1
        end
        Random.seed!(example["config/instruments"]["seed"])
        for k in 1:10
            swap = DiffFusion.Examples.random_swap(example)
            @test length(swap) == 2
            @test swap[1].payer_receiver * swap[2].payer_receiver == -1
            # println(
            #     typeof(swap[1]), ", " ,
            #     typeof(swap[1].cashflows[1]), ", " ,
            #     typeof(swap[2]), ", " ,
            #     typeof(swap[2].cashflows[1]), ", " ,
            # )
        end
        #
        DiffFusion.Examples.display_portfolio(example)
        p = DiffFusion.Examples.portfolio!(example, 5)
        DiffFusion.Examples.display_portfolio(example)
        @test length(p) == 5
    end


    @testset "Test swaption generation" begin
        example = YAML.load(yaml_string, dicttype=OrderedDict{String,Any})
        for type_key in example["config/instruments"]["swaption_types"]
            swaption = DiffFusion.Examples.random_swaption(example, type_key)[1]
            @test isa(swaption, DiffFusion.SwaptionLeg)
          end
          Random.seed!(example["config/instruments"]["seed"])
          for k in 1:10
              swaption = DiffFusion.Examples.random_swaption(example)[1]
              @test isa(swaption, DiffFusion.SwaptionLeg)
              println(swaption.alias * ": " *
                  string(swaption.expiry_time) * "x" *
                  string(swaption.fixed_coupons[end].pay_time - swaption.expiry_time)
              )
          end
    end


    @testset "Test Bermudan generation" begin
      example = YAML.load(yaml_string, dicttype=OrderedDict{String,Any})
      for type_key in example["config/instruments"]["bermudan_types"]
          berm = DiffFusion.Examples.random_bermudan(example, type_key)[1]
          @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        end
        Random.seed!(example["config/instruments"]["seed"])
        berm = DiffFusion.Examples.random_bermudan(example, "SOFR_SWPN")[1]
        if length(berm.bermudan_exercises) > 1
            @test berm.bermudan_exercises[2].exercise_time - berm.bermudan_exercises[1].exercise_time == 1.0
        end
        berm = DiffFusion.Examples.random_bermudan(example, "EURIBOR6M_SWPN")[1]
        if length(berm.bermudan_exercises) > 1
            @test berm.bermudan_exercises[2].exercise_time - berm.bermudan_exercises[1].exercise_time == 2.0
        end
        for k in 1:10
          berm = DiffFusion.Examples.random_bermudan(example)[1]
            @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        end
  end

end
