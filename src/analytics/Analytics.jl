
"""
    aggregate(
        scens::ScenarioCube,
        average_paths::Bool=true,
        aggregate_legs::Bool=true,
        )

Average paths and aggregate legs in ScenarioCube.

`scens` is the input `ScenarioCube`.

If `average_paths` is true then reduce scenario cube along
path axis. Otherwise, keep individual paths.

If `aggregate_legs` is true then reduce scenario cube
along the axis of legs. Otherwise, keep individual legs.
"""
function aggregate(scens::ScenarioCube, average_paths::Bool=true, aggregate_legs::Bool=true)
    X = scens.X
    leg_aliases = scens.leg_aliases
    if average_paths
        X = mean(X, dims=1)
    end
    if aggregate_legs
        X = sum(X, dims=3)
        alias_ = ""
        for a in leg_aliases
            alias_ = alias_ * a * "_"
        end
        leg_aliases = [ alias_[begin:end-1] ]
    end
    return ScenarioCube(
        X,
        scens.times,
        leg_aliases,
        scens.numeraire_context_key,
        scens.discount_curve_key,
    )
end


"""
    expected_exposure(
        scens::ScenarioCube,
        gross_leg::Bool = false,
        average_paths::Bool = true,
        aggregate_legs::Bool = true,
        )

Calculate expected positive exposure (EPE or EE).

`scens` is the input `ScenarioCube`.

If `gross_leg` is true then calculate positive floor on
trade level. Otherwise, use netted portfolio to determine
positive floor.

If `average_paths` is true then reduce scenario cube along
path axis. Otherwise, keep individual paths.

If `aggregate_legs` is true then reduce scenario cube
along the axis of legs. Otherwise, keep individual legs.
"""
function expected_exposure(
    scens::ScenarioCube,
    gross_leg::Bool = false,
    average_paths::Bool = true,
    aggregate_legs::Bool = true,
    )
    #
    if gross_leg
        is_positive = scens.X .> 0.0
    else
        is_positive = sum(scens.X, dims=3) .> 0.0
    end
    leg_aliases = [ "EE[" * leg_alias * "]" for leg_alias in scens.leg_aliases ]
    ee_scens = ScenarioCube(
        is_positive .* scens.X,
        scens.times,
        leg_aliases,
        scens.numeraire_context_key,
        scens.discount_curve_key,
    )
    return aggregate(ee_scens, average_paths, aggregate_legs)
end


"""
    potential_future_exposure(
        scens::ScenarioCube,
        quantile_::ModelValue,
        gross_leg::Bool = false,
        )

Calculate the potential future exposure (PFE).

`scens` is the input `ScenarioCube`.

`quantile_` is the desired quantile for PFE calculation.

If `gross_leg` is true then calculate positive floor on
trade level. Otherwise, use netted portfolio to determine
positive floor.
"""
function potential_future_exposure(
    scens::ScenarioCube,
    quantile_::ModelValue,
    gross_leg::Bool = false,
    )
    #
    scens_ee = expected_exposure(scens, gross_leg, false, true)
    Q = vcat([ quantile(scens_ee.X[:,k,1], quantile_) for k in axes(scens_ee.X, 2) ]...)
    X = reshape(Q, (1,length(Q), 1))
    leg_aliases = [
        @sprintf("Q_%.2f[%s]", quantile_, leg_alias)
        for leg_alias in scens_ee.leg_aliases
    ]
    return ScenarioCube(
        X,
        scens_ee.times,
        leg_aliases,
        scens_ee.numeraire_context_key,
        scens_ee.discount_curve_key,
    )

end


"""
    valuation_adjustment(
        credit_ts::CreditDefaultTermstructure,
        recovery_rate::ModelValue,
        cva_dva::ModelValue,
        scens::ScenarioCube,
        gross_leg::Bool = false,
        average_paths::Bool = true,
        aggregate_legs::Bool = true,
        rho::ModelValue = 0.5,
        )

Calculate unilateral CVA and DVA for a given `ScenarioCube`.
Result is a `ScenarioCube` with *non-negative* XVA contributions
along the time axis.

`credit_ts` is the credit spread curve to calculate survival
probabilities. `recovery_rate` is the corresponding constant
recovery rate value (typicall 0.40).

`cva_dva` is a binary flag to model CVA (+1.0) and DVA (-1.0).

`scens` is the input `ScenarioCube`. Values are assumed to
be *discounted* prices in the corresponding portfolio currency.

Parameters `gross_leg`, `average_paths` and `aggregate_legs`
are used as in function `expected_exposure`.

`rho` specifies how to integrate discounted prices. `rho=0.5`
uses trapezoidal rule. This choice is used in BCBS paper
*Basel III: A global regulatory framework for more resilient
banks and banking systems* (2011). `rho=0.0` uses prices at
the start of period and is proposed in Green, *XVA* (2016).
"""
function valuation_adjustment(
    credit_ts::CreditDefaultTermstructure,
    recovery_rate::ModelValue,
    cva_dva::ModelValue,
    scens::ScenarioCube,
    gross_leg::Bool = false,
    average_paths::Bool = true,
    aggregate_legs::Bool = true,
    rho::ModelValue = 0.5,
    )
    #
    if gross_leg
        is_positive = (cva_dva * scens.X) .> 0.0
    else
        is_positive = (cva_dva * sum(scens.X, dims=3)) .> 0.0
    end
    meas_str = "XVA"
    if cva_dva == 1.0
        meas_str = "CVA"
    end
    if cva_dva == -1.0
        meas_str = "DVA"
    end
    leg_aliases = [ meas_str * "[" * leg_alias * "]" for leg_alias in scens.leg_aliases ]
    #
    default_probs = [
        survival(credit_ts, T0) - survival(credit_ts, T1)
        for (T0, T1) in zip(scens.times[begin:end-1], scens.times[begin+1:end])
    ]
    xva = zeros(size(scens.X))
    for k in 2:size(scens.X, 2)
        # xva formula goes here...
        xva[:,k,:] = (1.0 - recovery_rate) .* (
            default_probs[k-1] .* (
                (1.0-rho) .* scens.X[:,k-1,:] .* is_positive[:,k-1,:] .+
                rho .* scens.X[:,k,:] .* is_positive[:,k,:]
            )
        )
    end
    xva_scens = ScenarioCube(
        xva,
        scens.times,
        leg_aliases,
        scens.numeraire_context_key,
        scens.discount_curve_key,
    )
    return aggregate(xva_scens, average_paths, aggregate_legs)
end
