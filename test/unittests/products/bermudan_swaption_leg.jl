using DiffFusion
using Test

@testset "Test Bermudan swaption leg" begin

    # simple rate as single regression payoff
    make_regression_variables(t) = [ DiffFusion.LiborRate(t, t, 5.0, "EURIBOR12M"), ]

    fixed_flows = [
        DiffFusion.FixedRateCoupon(2.0, 0.03, 1.0, 1.0),
        DiffFusion.FixedRateCoupon(3.0, 0.03, 1.0, 2.0),
        DiffFusion.FixedRateCoupon(4.0, 0.03, 1.0, 3.0),
        DiffFusion.FixedRateCoupon(5.0, 0.03, 1.0, 4.0),
        ]

    libor_flows = [
        DiffFusion.SimpleRateCoupon(1.0, 1.0, 2.0, 2.0, 1.0, "EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(2.0, 2.0, 3.0, 3.0, 1.0, "EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(3.0, 3.0, 4.0, 4.0, 1.0, "EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(4.0, 4.0, 5.0, 5.0, 1.0, "EURIBOR12M", nothing, nothing),
    ]

    notionals = [ 1.0, 1.0, 1.0, 1.0, ]

    exercise_1 = DiffFusion.bermudan_exercise(
        1.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:OIS", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:OIS", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )
    exercise_2 = DiffFusion.bermudan_exercise(
        2.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[2:end], notionals[2:end], "EUR:OIS", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[2:end], notionals[2:end], "EUR:OIS", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )
    exercise_3 = DiffFusion.bermudan_exercise(
        3.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[3:end], notionals[3:end], "EUR:OIS", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[3:end], notionals[3:end], "EUR:OIS", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )

    @testset "Test exercise setup" begin
        exerc = DiffFusion.bermudan_exercise(
            1.0,
            [
                DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:OIS", nothing,  1.0),  # receiver
                DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:OIS", nothing, -1.0),  # payer
            ],
            make_regression_variables,
        )
        @test isa(exerc, DiffFusion.BermudanExercise)
        # positive exrcise time required
        @test_throws AssertionError DiffFusion.bermudan_exercise(
            0.0,
            [
                DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:OIS", nothing,  1.0),  # receiver
                DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:OIS", nothing, -1.0),  # payer
            ],
            make_regression_variables,
        )
        # cash flow leg(s) required
        @test_throws AssertionError DiffFusion.bermudan_exercise(
            1.0,
            [ ],
            make_regression_variables,
        )
        # cash flow leg(s) required
        @test_throws AssertionError DiffFusion.bermudan_exercise(
            1.0,
            [ 1 ],
            make_regression_variables,
        )
        # make_regression_variables must be function
        @test_throws MethodError DiffFusion.bermudan_exercise(
            1.0,
            [
                DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:OIS", nothing,  1.0),  # receiver
                DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:OIS", nothing, -1.0),  # payer
            ],
            1,
        )
    end

berm_00 =
"AmcSum(0.00, [{Max({AmcSum(1.00, [{Max({AmcSum(2.00, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.00; 2.00, 5.00)])}, {(((((" *
"(P(EUR:OIS, 2.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00) + " *
"(P(EUR:OIS, 2.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 4.00) * -1.0000 * L(EURIBOR12M, 2.00; 3.00, 4.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * -1.0000 * L(EURIBOR12M, 2.00; 4.00, 5.00) * 1.0000 @ 2.00))})}], [], " *
"[L(EURIBOR12M, 1.00; 1.00, 5.00)])}, {(((((((" *
"(P(EUR:OIS, 1.00, 2.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00) + " *
"(P(EUR:OIS, 1.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 2.00) * -1.0000 * L(EURIBOR12M, 1.00; 1.00, 2.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 3.00) * -1.0000 * L(EURIBOR12M, 1.00; 2.00, 3.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * -1.0000 * L(EURIBOR12M, 1.00; 3.00, 4.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * -1.0000 * L(EURIBOR12M, 1.00; 4.00, 5.00) * 1.0000 @ 1.00))})}], [], " *
"[L(EURIBOR12M, 0.00; 0.00, 5.00)])"

berm_05 =
"AmcSum(0.50, [{Max({AmcSum(1.00, [{Max({AmcSum(2.00, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.00; 2.00, 5.00)])}, {(((((" *
"(P(EUR:OIS, 2.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00) + " *
"(P(EUR:OIS, 2.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 4.00) * -1.0000 * L(EURIBOR12M, 2.00; 3.00, 4.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * -1.0000 * L(EURIBOR12M, 2.00; 4.00, 5.00) * 1.0000 @ 2.00))})}], [], " *
"[L(EURIBOR12M, 1.00; 1.00, 5.00)])}, {(((((((" *
"(P(EUR:OIS, 1.00, 2.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00) + " *
"(P(EUR:OIS, 1.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 2.00) * -1.0000 * L(EURIBOR12M, 1.00; 1.00, 2.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 3.00) * -1.0000 * L(EURIBOR12M, 1.00; 2.00, 3.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * -1.0000 * L(EURIBOR12M, 1.00; 3.00, 4.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * -1.0000 * L(EURIBOR12M, 1.00; 4.00, 5.00) * 1.0000 @ 1.00))})}], [], " *
"[L(EURIBOR12M, 0.50; 0.50, 5.00)])"

option_10 =
"AmcSum(1.00, [{Max({AmcSum(2.00, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.00; 2.00, 5.00)])}, {(((((" *
"(P(EUR:OIS, 2.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00) + " *
"(P(EUR:OIS, 2.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 4.00) * -1.0000 * L(EURIBOR12M, 2.00; 3.00, 4.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * -1.0000 * L(EURIBOR12M, 2.00; 4.00, 5.00) * 1.0000 @ 2.00))})}], [], " *
"[L(EURIBOR12M, 1.00; 1.00, 5.00)])"

underl_10 =
"(((((((" *
"(P(EUR:OIS, 1.00, 2.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00) + " *
"(P(EUR:OIS, 1.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 2.00) * -1.0000 * L(EURIBOR12M, 1.00; 1.00, 2.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 3.00) * -1.0000 * L(EURIBOR12M, 1.00; 2.00, 3.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 4.00) * -1.0000 * L(EURIBOR12M, 1.00; 3.00, 4.00) * 1.0000 @ 1.00)) + " *
"(P(EUR:OIS, 1.00, 5.00) * -1.0000 * L(EURIBOR12M, 1.00; 4.00, 5.00) * 1.0000 @ 1.00))"


berm_10 = "(({({"*option_10*"} > {"*underl_10*"})} * "*option_10*" + (1.0000 - {({"*option_10*"} > {"*underl_10*"})}) * "*underl_10*") @ 1.00)"

option_15 =
"AmcSum(1.50, [{Max({AmcSum(2.00, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.00; 2.00, 5.00)])}, {(((((" *
"(P(EUR:OIS, 2.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00) + " *
"(P(EUR:OIS, 2.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 4.00) * -1.0000 * L(EURIBOR12M, 2.00; 3.00, 4.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * -1.0000 * L(EURIBOR12M, 2.00; 4.00, 5.00) * 1.0000 @ 2.00))})}], [], " *
"[L(EURIBOR12M, 1.50; 1.50, 5.00)])"

underl_15 =
"(((((((" *
"(P(EUR:OIS, 1.50, 2.00) * 1.0000 * 0.0300 * 1.0000 @ 1.50) + " *
"(P(EUR:OIS, 1.50, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 2.00) * -1.0000 * L(EURIBOR12M, 1.00; 1.00, 2.00) * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 3.00) * -1.0000 * L(EURIBOR12M, 1.50; 2.00, 3.00) * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 4.00) * -1.0000 * L(EURIBOR12M, 1.50; 3.00, 4.00) * 1.0000 @ 1.50)) + " *
"(P(EUR:OIS, 1.50, 5.00) * -1.0000 * L(EURIBOR12M, 1.50; 4.00, 5.00) * 1.0000 @ 1.50))"

berm_15 = "(({({"*option_10*"} > {"*underl_10*"})} * "*option_15*" + (1.0000 - {({"*option_10*"} > {"*underl_10*"})}) * "*underl_15*") @ 1.50)"

option_20 =
"AmcSum(2.00, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.00; 2.00, 5.00)])"

underl_20 =
"(((((" *
"(P(EUR:OIS, 2.00, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00) + " *
"(P(EUR:OIS, 2.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 4.00) * -1.0000 * L(EURIBOR12M, 2.00; 3.00, 4.00) * 1.0000 @ 2.00)) + " *
"(P(EUR:OIS, 2.00, 5.00) * -1.0000 * L(EURIBOR12M, 2.00; 4.00, 5.00) * 1.0000 @ 2.00))"

option_25 =
"AmcSum(2.50, [{Max(0.0000, {(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))})}], [], " *
"[L(EURIBOR12M, 2.50; 2.50, 5.00)])"

underl_25 =
"(((((" *
"(P(EUR:OIS, 2.50, 3.00) * 1.0000 * 0.0300 * 1.0000 @ 2.50) + " *
"(P(EUR:OIS, 2.50, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 2.50)) + " *
"(P(EUR:OIS, 2.50, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 2.50)) + " *
"(P(EUR:OIS, 2.50, 3.00) * -1.0000 * L(EURIBOR12M, 2.00; 2.00, 3.00) * 1.0000 @ 2.50)) + " *
"(P(EUR:OIS, 2.50, 4.00) * -1.0000 * L(EURIBOR12M, 2.50; 3.00, 4.00) * 1.0000 @ 2.50)) + " *
"(P(EUR:OIS, 2.50, 5.00) * -1.0000 * L(EURIBOR12M, 2.50; 4.00, 5.00) * 1.0000 @ 2.50))"

berm_25 = "(({({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})} * "*option_25*
          " + (1.0000 - {({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})}) * "*underl_25*") @ 2.50)"


underl_30 =
"(((" *
"(P(EUR:OIS, 3.00, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00) + " *
"(P(EUR:OIS, 3.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.00)) + " *
"(P(EUR:OIS, 3.00, 5.00) * -1.0000 * L(EURIBOR12M, 3.00; 4.00, 5.00) * 1.0000 @ 3.00))"

underl_35 =
"(((" *
"(P(EUR:OIS, 3.50, 4.00) * 1.0000 * 0.0300 * 1.0000 @ 3.50) + " *
"(P(EUR:OIS, 3.50, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 3.50)) + " *
"(P(EUR:OIS, 3.50, 4.00) * -1.0000 * L(EURIBOR12M, 3.00; 3.00, 4.00) * 1.0000 @ 3.50)) + " *
"(P(EUR:OIS, 3.50, 5.00) * -1.0000 * L(EURIBOR12M, 3.50; 4.00, 5.00) * 1.0000 @ 3.50))"

underl_40 =
"(" *
"(P(EUR:OIS, 4.00, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 4.00) + " *
"(P(EUR:OIS, 4.00, 5.00) * -1.0000 * L(EURIBOR12M, 4.00; 4.00, 5.00) * 1.0000 @ 4.00))"

underl_45 =
"(" *
"(P(EUR:OIS, 4.50, 5.00) * 1.0000 * 0.0300 * 1.0000 @ 4.50) + " *
"(P(EUR:OIS, 4.50, 5.00) * -1.0000 * L(EURIBOR12M, 4.00; 4.00, 5.00) * 1.0000 @ 4.50))"

berm_30 = "((1.0000 - {({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})} * {(0.0000 > {"*underl_30*"})}) * "*underl_30*" @ 3.00)"
berm_35 = "((1.0000 - {({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})} * {(0.0000 > {"*underl_30*"})}) * "*underl_35*" @ 3.50)"
berm_40 = "((1.0000 - {({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})} * {(0.0000 > {"*underl_30*"})}) * "*underl_40*" @ 4.00)"
berm_45 = "((1.0000 - {({"*option_10*"} > {"*underl_10*"})} * {({"*option_20*"} > {"*underl_20*"})} * {(0.0000 > {"*underl_30*"})}) * "*underl_45*" @ 4.50)"

    @testset "Test discounted_cashflows" begin
        berm = DiffFusion.bermudan_swaption_leg(
            "berm",
            [ exercise_1, exercise_2, exercise_3,],
            1.0, # long option
            "OIS", # default discounting (curve key)
            make_regression_variables,
            nothing, # path
            nothing, # make_regression
        )
        @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        cfs = DiffFusion.discounted_cashflows(berm, 0.0)
        @test length(cfs) == 1
        #
        @test string(DiffFusion.discounted_cashflows(berm, 0.0)[1]) == berm_00
        @test string(DiffFusion.discounted_cashflows(berm, 0.5)[1]) == berm_05
        @test string(DiffFusion.discounted_cashflows(berm, 1.0)[1]) == berm_10
        @test string(DiffFusion.discounted_cashflows(berm, 1.5)[1]) == berm_15
        @test string(DiffFusion.discounted_cashflows(berm, 2.5)[1]) == berm_25
        @test string(DiffFusion.discounted_cashflows(berm, 3.0)[1]) == berm_30
        @test string(DiffFusion.discounted_cashflows(berm, 3.5)[1]) == berm_35
        @test string(DiffFusion.discounted_cashflows(berm, 4.0)[1]) == berm_40
        @test string(DiffFusion.discounted_cashflows(berm, 4.5)[1]) == berm_45

        @test length(DiffFusion.discounted_cashflows(berm, 5.0)) == 0
        @test length(DiffFusion.discounted_cashflows(berm, 5.5)) == 0
    end

    @testset "Test regression details setup" begin
        # some dummy regression details
        struct NoPath <: DiffFusion.AbstractPath end
        no_make_regression = () -> nothing
        #
        berm = DiffFusion.bermudan_swaption_leg(
            "berm",
            [ exercise_1, exercise_2, exercise_3,],
            1.0, # long option
            "OIS", # default discounting (curve key)
            make_regression_variables,
            NoPath(), # path
            no_make_regression, # make_regression
        )
        @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        @test berm.regression_data.path == NoPath()
        @test berm.regression_data.make_regression == no_make_regression
        @test berm.hold_values[begin].x.x.x.regr.path == NoPath()
        @test berm.hold_values[begin].x.x.x.regr.make_regression == no_make_regression
        @test DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.path == NoPath()
        @test DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.make_regression == no_make_regression
        #
        berm = DiffFusion.bermudan_swaption_leg(
            "berm",
            [ exercise_1, exercise_2, exercise_3,],
            1.0, # long option
            "OIS", # default discounting (curve key)
            make_regression_variables,
            nothing, # path
            nothing, # make_regression
        )
        @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        @test isnothing(berm.regression_data.path)
        @test isnothing(berm.regression_data.make_regression)
        @test isnothing(berm.hold_values[begin].x.x.x.regr.path)
        @test isnothing(berm.hold_values[begin].x.x.x.regr.make_regression)
        @test isnothing(DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.path)
        @test isnothing(DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.make_regression)
        #
        DiffFusion.reset_regression!(berm, NoPath(), no_make_regression)
        @test berm.regression_data.path == NoPath()
        @test berm.regression_data.make_regression == no_make_regression
        @test berm.hold_values[begin].x.x.x.regr.path == NoPath()
        @test berm.hold_values[begin].x.x.x.regr.make_regression == no_make_regression
        @test DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.path == NoPath()
        @test DiffFusion.discounted_cashflows(berm, 0.0)[1].regr.make_regression == no_make_regression
    end


    @testset "Test convenient constructors" begin
        fixed_leg = DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:OIS", nothing,  1.0)  # receiver
        float_leg = DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:OIS", nothing, -1.0)  # payer
        exercises = DiffFusion.make_bermudan_exercises(
            fixed_leg,
            float_leg,
            [ 1.0, 2.0, 3.0, 3.5 ],
        )
        #
        @test [ e.exercise_time for e in exercises ] == [ 1.0, 2.0, 3.0, 3.5 ]
        @test [ length(e.cashflow_legs) for e in exercises ] == [ 2, 2, 2, 2 ]
        @test length(exercises[1].cashflow_legs[1].cashflows) == 4
        @test length(exercises[1].cashflow_legs[2].cashflows) == 4
        @test length(exercises[2].cashflow_legs[1].cashflows) == 3
        @test length(exercises[2].cashflow_legs[2].cashflows) == 3
        @test length(exercises[3].cashflow_legs[1].cashflows) == 2
        @test length(exercises[3].cashflow_legs[2].cashflows) == 2
        @test length(exercises[4].cashflow_legs[1].cashflows) == 1
        @test length(exercises[4].cashflow_legs[2].cashflows) == 1
        #
        r = exercises[1].make_regression_variables(1.0)
        @test length(r) == 1
        @test string(r[1]) == "L(EURIBOR12M, 1.00; 1.00, 5.00)"
        r = exercises[4].make_regression_variables(3.5)
        @test length(r) == 1
        @test string(r[1]) == "L(EURIBOR12M, 3.50; 4.00, 5.00)"
        #
        @test_throws AssertionError DiffFusion.make_bermudan_exercises(
            fixed_leg,
            float_leg,
            [ 4.5 ],
        )
        #
        berm = DiffFusion.bermudan_swaption_leg(
            "berm",
            fixed_leg,
            float_leg,
            [ 1.0, 2.0, 3.0, 3.5 ],
            -1.0,
        )
        @test isa(berm, DiffFusion.BermudanSwaptionLeg)
    end

end
