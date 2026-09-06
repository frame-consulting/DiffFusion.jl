
"""
    struct CreditRiskyCashFlowLeg <: CashFlowLeg
        cash_flow_leg::DeterministicCashFlowLeg
        credit_curve_key::String
        recovery_rate::ModelValue
    end

A cash flow leg with credit risky with default and recovery modelling.

We decorate a DeterministicCashFlowLeg and re-use DeterministicCashFlowLeg
methodology as much as possible.
"""
struct CreditRiskyCashFlowLeg <: CashFlowLeg
    cash_flow_leg::DeterministicCashFlowLeg
    credit_curve_key::String
    recovery_rate::ModelValue
end


"""
    credit_risky_cashflow_leg(
    cash_flow_leg::DeterministicCashFlowLeg,
    credit_curve_key::String,
    recovery_rate::ModelValue = 0.0,
    )

Construct a CreditRiskyCashFlowLeg.
"""
function credit_risky_cashflow_leg(
    cash_flow_leg::DeterministicCashFlowLeg,
    credit_curve_key::String,
    recovery_rate::ModelValue = 0.0,
    )
    @assert 0.0 ≤ recovery_rate && recovery_rate ≤ 1.0
    return CreditRiskyCashFlowLeg(cash_flow_leg, credit_curve_key, recovery_rate)
end


"""
    future_cashflows(leg::CreditRiskyCashFlowLeg, obs_time::ModelTime)

Delegate future cash flow calculation to the underlying DeterministicCashFlowLeg.
"""
function future_cashflows(leg::CreditRiskyCashFlowLeg, obs_time::ModelTime)
    return future_cashflows(leg.cash_flow_leg, obs_time)
    # Maybe better multiply by non-default probability to obs_time.
    # Modelling choice depends on the context application of cash flows.
end


"""
    discounted_cashflows(leg::CreditRiskyCashFlowLeg, obs_time::ModelTime)

Calculate contractual cash flows subject to survival and recovery cash flows
in case of default between cash flow dates.
"""
function discounted_cashflows(leg::CreditRiskyCashFlowLeg, obs_time::ModelTime)
    payoffs = discounted_cashflows(leg.cash_flow_leg, obs_time)
    credit_risky_payoffs = Payoff[]
    for payoff in payoffs
        # methodology should also work with other CashFlowLeg types
        @assert isa(payoff, Pay)
        maturity_time = pay_time(payoff.x)
        Q = SurvivalProbability(obs_time, maturity_time, leg.credit_curve_key)
        P = Q * payoff.x
        push!(credit_risky_payoffs, Pay(P, payoff.obs_time))
    end
    # add default payoffs
    if leg.recovery_rate > 0.0
        # this is specific for DeterministicCashFlowLeg
        # we assume last cash flow is notional payment
        notional = leg.cash_flow_leg.notionals[end]
        amount = expected_amount(leg.cash_flow_leg.cashflows[end], obs_time)
        recovery_value = leg.cash_flow_leg.payer_receiver * notional * leg.recovery_rate
        recovery_payoff = recovery_value * amount  # maybe better cache
        #
        pay_times = [
            pay_time(cf) for cf in leg.cash_flow_leg.cashflows
            if pay_time(cf) > obs_time
        ]
        pay_times = unique(sort(pay_times))
        pay_times = vcat([obs_time], pay_times)
        for (start_time, end_time) in zip(pay_times[1:end-1], pay_times[begin+1:end])
            default_time = 0.5 * (start_time + end_time)
            Q0 = SurvivalProbability(obs_time, start_time, leg.credit_curve_key)
            Q1 = SurvivalProbability(obs_time, end_time, leg.credit_curve_key)
            DF = ZeroBond(obs_time, default_time, leg.cash_flow_leg.curve_key)
            P = DF * recovery_payoff
            if !isnothing(leg.cash_flow_leg.fx_key)
                P = Asset(obs_time, leg.cash_flow_leg.fx_key) * P
            end
            P = (Q0 - Q1) * P
            push!(credit_risky_payoffs, Pay(P, obs_time))
        end
    end
    return credit_risky_payoffs
end
