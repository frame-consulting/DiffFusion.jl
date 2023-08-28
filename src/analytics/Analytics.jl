
"""
    aggregate(
        scens::ScenarioCube,
        average_paths::Bool=true,
        aggregate_legs::Bool=true,
        )

Average paths and aggregate legs in ScenarioCube.
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