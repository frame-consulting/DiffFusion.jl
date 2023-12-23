
"""
    abstract type CashFlow end

A CashFlow represents a general payment in an unspecified currency.

In a simulation, we calculate discounted expected cash flows in a
consistent numeraire currency.

The `CashFlow` object is inspired by QuantLib's CashFlow interface.

We apply the convention that cash flows are formulated for unit notionals.
Actual notionals are applied at the level of legs. This design aims at
simplifying MTM cross currency swap legs with notional exchange.
"""
abstract type CashFlow end

"""
    pay_time(cf::CashFlow)

Return the payment time for a CashFlow.

This represents a default implementation

This method is used to calculate discounted expected values.
"""
pay_time(cf::CashFlow) = cf.pay_time

"""
    amount(cf::CashFlow)

Return the payoff representing the simulated cash flow amount of the payment.

This method is intended to be used for general payoffs in conjunction with AMC.
"""
function amount(cf::CashFlow)
    error("CashFlow needs to implement amount method.")
end

"""
    expected_amount(cf::CashFlow, obs_time::ModelTime)

Return the payoff representing the simulated expected amount of the payment.

Expectation is calculated in ``T``-forward measure of cash flow currency with
``T`` being the payment time and conditioning on observation time.

This method is intended to be used for analytical pricers.
"""
function expected_amount(cf::CashFlow, obs_time::ModelTime)
    error("CashFlow needs to implement expected_amount method.")
end


"""
    abstract type Coupon <: CashFlow end

A Coupon is a payment that is composed of an (effective) coupon rate and
a year fraction.
"""
abstract type Coupon <: CashFlow end

"""
    year_fraction(cf::Coupon)

Derive the year fraction for a Coupon.
"""
function year_fraction(cf::Coupon)
    error("Coupon needs to implement year_fraction method.")
end

"""
    coupon_rate(cf::Coupon)

Return a payoff for the realised simulated effective coupon rate.
"""
function coupon_rate(cf::Coupon)
    error("Coupon needs to implement coupon_rate method.")
end

"""
    forward_rate(cf::Coupon, obs_time::ModelTime)

Return a payoff for the effective forward rate of the coupon.

Expectation is calculated in T-forward measure of cash flow currency with
T being the payment time and conditioning on observation time.

This method is intended to be used for analytical pricers.
"""
function forward_rate(cf::Coupon, obs_time::ModelTime)
    error("Coupon needs to implement forward_rate method.")
end

"""
    amount(cf::Coupon)

Calculate payment amount for a Coupon.
"""
amount(cf::Coupon) = coupon_rate(cf) * year_fraction(cf)

"""
    expected_amount(cf::Coupon, obs_time::ModelTime)

Calculate expected payment amount for a Coupon.
"""
expected_amount(cf::Coupon, obs_time::ModelTime) = forward_rate(cf, obs_time) * year_fraction(cf)

"""
    first_time(cf::Coupon)

Derive the first event time of the `Coupon`.

This time is used in conjunction with call rights to determine whether
a coupon period is already broken.
"""
function first_time(cf::Coupon)
    error("Coupon needs to implement first_time method.")
end

"""
    struct FixedCashFlow <: CashFlow
        pay_time::ModelTime
        amount::ModelValue
    end

A simple deterministic cash flow (normalised to one unit notional)
"""
struct FixedCashFlow <: CashFlow
    pay_time::ModelTime
    amount::ModelValue
end

"""
    amount(cf::FixedCashFlow)

Return FixedCashFlow amount.
"""
amount(cf::FixedCashFlow) = Fixed(cf.amount)

"""
    expected_amount(cf::FixedCashFlow, obs_time::ModelTime)

Return FixedCashFlow expected amount.
"""
expected_amount(cf::FixedCashFlow, obs_time::ModelTime) = Fixed(cf.amount)


"""
    struct CombinedCashFlow <: CashFlow
        first::CashFlow
        second::CashFlow
        op::Function
    end

A composition of two cash flows in a single cash flow.

This `CashFlow` type is intended e.g. for spreads and caplets/floorlets.
"""
struct CombinedCashFlow <: CashFlow
    first::CashFlow
    second::CashFlow
    op::Function
end


"""
    combined_cashflow(
        first::CashFlow,
        second::CashFlow,
        op::Function,
        )

Create a CombinedCashFlow object.
"""
function combined_cashflow(
    first::CashFlow,
    second::CashFlow,
    op::Function,
    )
    #
    @assert pay_time(first) == pay_time(second)
    return CombinedCashFlow(first, second, op)
end

import Base.+
import Base.-
(+)(first::CashFlow, second::CashFlow) = combined_cashflow(first, second, +)
(-)(first::CashFlow, second::CashFlow) = combined_cashflow(first, second, -)


"""
    pay_time(cf::CombinedCashFlow)

Return the payment time for a CombinedCashFlow.
"""
pay_time(cf::CombinedCashFlow) = pay_time(cf.first)


"""
    amount(cf::CombinedCashFlow)

Return the payoff representing the simulated cash flow amount of the payment.
"""
amount(cf::CombinedCashFlow) = cf.op(amount(cf.first), amount(cf.second))

"""
    expected_amount(cf::CombinedCashFlow, obs_time::ModelTime)

Return the payoff representing the simulated expected amount of the payment.
"""
expected_amount(cf::CombinedCashFlow, obs_time::ModelTime) = cf.op(expected_amount(cf.first, obs_time), expected_amount(cf.second, obs_time))
