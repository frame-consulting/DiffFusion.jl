
"""
    struct BermudanExercise
        exercise_time::ModelTime
        cashflow_legs::AbstractVector
        make_regression_variables::Function
    end

A container holding the information about an exercise event of a `BermudanSwaptionLeg`.

Here, `exercise_time` is the individual option exercise time and `cashflow_legs` is a
list of `CashFlowLeg`s.

The cash flows in the cash flow legs are supposed to start after `exercise_time`.
That is, the `BermudanExercise` manages the lag between option exercise and option
settlement.

`make_regression_variables` is a function with signature

    (exercise_time) -> [ regr_payoff_1, ..., regr_payoff_N ].

The function takes observation time as input to allow for re-usable fuctions. It
returns a list of regression payoffs used for this particular exercise.

The result of the function is passed on to the `AmcPayoff` creation.
"""
struct BermudanExercise
    exercise_time::ModelTime
    cashflow_legs::AbstractVector
    make_regression_variables::Function
end


"""
    bermudan_exercise(
        exercise_time::ModelTime,
        cashflow_legs::AbstractVector,
        make_regression_variables::Function,
        )

Create a `BermudanExercise` and check for valid inputs.
"""
function bermudan_exercise(
    exercise_time::ModelTime,
    cashflow_legs::AbstractVector,
    make_regression_variables::Function,
    )
    #
    @assert exercise_time > 0.0
    @assert length(cashflow_legs) > 0
    for leg in cashflow_legs
        @assert isa(leg, CashFlowLeg)
    end
    return BermudanExercise(exercise_time, cashflow_legs, make_regression_variables)
end


"""
A Bermudan swaption implemented as a `CashFlowLeg`.

`alias` is the leg alias.

`bermudan_exercises` is a list of `BermudanExercise`s in ascending order.

`option_long_short` is `+1` for a long option position (buy) and `-1` for a
short option position (sell).

`numeraire_curve_key` is a discount curve key used for numeraie calculation
in `AmcPayoff`s.

`hold_values` is a list of `Payoff`s per `BermudanExercise` that represent the option
prices if not exercised.

`exercise_triggers` is a list of `Payoff`s per `BermudanExercise` that represent
the indicator whether option was not exercised at respective exercise time.

`make_regression_variables` is a function with signature

    (obs_time) -> [ regr_payoff_1, ..., regr_payoff_N ].

The function takes observation time as input to allow for re-usable fuctions. It
returns a list of regression payoffs used for regression to current observation time.

The result of the function `make_regression_variables` is passed on to the `AmcPayoff`
creation.

`regression_data` holds function to create a regression and a `Path` to calibrate
the regression. Details are passed on to `AmcPayoff` at creation. The elements are
supposed to be updated subsequent to `BermudanSwaptionLeg` creation. This should
allow decoupling of leg creation and usage. 
"""
struct BermudanSwaptionLeg <: CashFlowLeg
    alias::String
    bermudan_exercises::AbstractVector
    option_long_short::ModelValue
    numeraire_curve_key::String
    hold_values::AbstractVector
    exercise_triggers::AbstractVector
    make_regression_variables::Function
    regression_data::AmcPayoffRegression
end



"""
    bermudan_swaption_leg(
        alias::String,
        bermudan_exercises::AbstractVector,
        option_long_short::ModelValue,
        numeraire_curve_key::String,
        make_regression_variables::Function,
        path::Union{AbstractPath, Nothing},
        make_regression::Union{Function, Nothing},
        )

Create a `BermudanSwaptionLeg`.

Calculate hold value payoffs and exercise trigger payoffs and setup the
`BermudanSwaptionLeg` object. 

`alias`, `bermudan_exercises`, `option_long_short`, `numeraire_curve_key`,
and `make_regression_variables` are passed on to `BermudanSwaptionLeg`.

`path` and `make_regression` are used to create an `AmcPayoffRegression`
object for  `AmcPayoff`s. This data is supposed to be updated subsequent
to leg cretion.
"""
function bermudan_swaption_leg(
    alias::String,
    bermudan_exercises::AbstractVector,
    option_long_short::ModelValue,
    numeraire_curve_key::String,
    make_regression_variables::Function,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    )
    #
    @assert length(bermudan_exercises) > 0
    exercise_times = [ e.exercise_time for e in bermudan_exercises ]
    if length(exercise_times) > 1
        @assert exercise_times[begin+1:end] > exercise_times[begin:end-1]
    end
    # backward induction algorithm
    #
    # last exercise requires special treatment
    Hk = Fixed(0.0)  # hold value after last exercise
    # A key assumption is that we can calculate discounted (!) cash flows
    # for our underlying. In principle, this assumption can be relaxed to
    # undiscounted cash fows. But this will increase the variance for
    # conditional expectation (i.e. regression) calibration.
    Uk = vcat([
        discounted_cashflows(leg, bermudan_exercises[end].exercise_time)
        for leg in bermudan_exercises[end].cashflow_legs
    ]...)
    Uk = Cache(sum(Uk))
    hold_values = [ Cache(Max(Hk, Uk)), ]
    exercise_triggers = [ Cache(Hk > Uk), ]
    # backward sweep
    for ex in reverse(bermudan_exercises[begin:end-1])
        Hk = AmcSum(
            ex.exercise_time,
            [hold_values[end],],
            ex.make_regression_variables(ex.exercise_time),
            path,
            make_regression,
            numeraire_curve_key,
        )
        Hk = Cache(Hk)
        Uk = vcat([
            discounted_cashflows(leg, ex.exercise_time)
            for leg in ex.cashflow_legs
        ]...)
        Uk = Cache(sum(Uk))
        hold_values = vcat(hold_values, Cache(Max(Hk, Uk)))
        exercise_triggers = vcat(exercise_triggers, Cache(Hk > Uk))
    end
    #
    return BermudanSwaptionLeg(
        alias,
        bermudan_exercises,
        option_long_short,
        numeraire_curve_key,
        reverse(hold_values),  # in ascending order again
        reverse(exercise_triggers),
        make_regression_variables,
        AmcPayoffRegression(path, make_regression, nothing),
    )
end


"""
    discounted_cashflows(leg::BermudanSwaptionLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.

Critical aspect is to consider the path-dependent exercise into the
option underlying.

Consider an `obs_time` after a given `BermudanExercise` (last exercise).
For this implementation, we make the assumption that exercise at `obs_time`
will only be into the underlying of the last exercise.

Above assumption is does not pose a limitation if all underlyings are the
same, i.e. standard Bermudans. 

Above assumption is a limitation if the Bermudan can be exercised into
different underlyings per exercise time. This corresponds to a more
complex trigger option.

Above assumption can be relaxed at the expense of calculating discounted
cash flows for all (earlier) underlyings.
"""
function discounted_cashflows(leg::BermudanSwaptionLeg, obs_time::ModelTime)
    if obs_time < leg.bermudan_exercises[begin].exercise_time
        Ht = AmcSum(
            obs_time,
            [ leg.hold_values[begin] ],
            leg.make_regression_variables(obs_time),
            leg.regression_data.path,
            leg.regression_data.make_regression,
            leg.numeraire_curve_key,
        )
        return [ Ht ]
    end
    exercise_times = [ e.exercise_time for e in leg.bermudan_exercises ]
    # Find index such that `T[idx] ≤ t < T[idx+1]`.
    # If `t` is smaller than the first (or all) times `T` then return `0`.
    last_exercise_idx = searchsortedlast(exercise_times, obs_time)
    @assert last_exercise_idx ≥ 1  # otherwise we should have returned earlier
    Ht = Fixed(0.0)  # option after last exercise
    if last_exercise_idx < length(exercise_times)
        # non-trivial option value
        Ht = AmcSum(
            obs_time,
            [ leg.hold_values[last_exercise_idx + 1] ],
            leg.make_regression_variables(obs_time),
            leg.regression_data.path,
            leg.regression_data.make_regression,
            leg.numeraire_curve_key,
        )
    end
    # Underlying if exercised.
    # NOTE:
    # We make the assumption that exercise will only be into the
    # underlying at `last_exercise_idx`.
    Ut = vcat([
        discounted_cashflows(leg, obs_time)
        for leg in leg.bermudan_exercises[last_exercise_idx].cashflow_legs
    ]...)
    if length(Ut) > 0
        Ut = sum(Ut)
    else
        Ut = nothing
    end
    # Check earlier exercise.
    not_exercised_trigger = leg.exercise_triggers[begin]
    for trigger in leg.exercise_triggers[begin+1:last_exercise_idx]
        not_exercised_trigger = not_exercised_trigger * trigger
    end
    #
    if last_exercise_idx < length(exercise_times)
        @assert !isnothing(Ut)  # avoid degenerated cases
        berm = (not_exercised_trigger * Ht + (1.0 - not_exercised_trigger) * Ut)
    else
        # Ht = 0
        if !isnothing(Ut)
            berm = (1.0 - not_exercised_trigger) * Ut
        else
            # underlying matured, Ut = 0 as well
            return Payoff[]
        end
    end
    return [ Pay(berm, obs_time) ]
end


"""
    reset_regression!(
        leg::BermudanSwaptionLeg,
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Reset the regression properties for the AMC payoffs of the `BermudanSwaptionLeg`.

This method is used to allow setting and updating AMC regression after
leg creation.
"""
function reset_regression!(
    leg::BermudanSwaptionLeg,
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
    # update regression details for existing cached payoffs
    for payoff in leg.hold_values
        reset_regression!(payoff, path, make_regression)
    end
    for payoff in leg.exercise_triggers
        reset_regression!(payoff, path, make_regression)
    end
    # update regression details for new payoff creation
    leg.regression_data.regression = nothing
    leg.regression_data.path = path
    leg.regression_data.make_regression = make_regression
end
