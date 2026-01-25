
"""
    struct LiborRate <: Leaf
        obs_time::ModelTime
        start_time::ModelTime
        end_time::ModelTime
        year_fraction::ModelValue
        key::String
    end

A simple compounded forward Libor rate.
"""
struct LiborRate <: Leaf
    obs_time::ModelTime
    start_time::ModelTime
    end_time::ModelTime
    year_fraction::ModelValue
    key::String
end

"""
    LiborRate(
       obs_time::ModelTime,
       start_time::ModelTime,
       end_time::ModelTime,
       key::String,
       )

A simple compounded forward Libor rate with year fraction from model time.
"""
function LiborRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    )
    return LiborRate(obs_time, start_time, end_time, end_time-start_time, key)
end

"""
    at(p::LiborRate, path::AbstractPath)

Derive the forward Libor rate at a given path.
"""
function at(p::LiborRate, path::AbstractPath)
    if p.obs_time == p.start_time
        df1_df2 = 1.0 ./ zero_bond(path, p.obs_time, p.end_time, p.key)
    else
        df1_df2 = compounding_factor(path, p.obs_time, p.start_time, p.end_time, p.key)
    end
    return (df1_df2 .- 1.0) ./ p.year_fraction
end

"""
    string(p::LiborRate)

Formatted (and shortened) output for LiborRate payoff.
"""
string(p::LiborRate) = @sprintf("L(%s, %.2f; %.2f, %.2f)", p.key, p.obs_time, p.start_time, p.end_time)


"""
    struct CompoundedRate <: Payoff
        obs_time::ModelTime
        start_time::ModelTime
        end_time::ModelTime
        year_fraction::ModelValue
        fixed_compounding::Union{Payoff, Nothing}
        key::String
        fixed_type::DataType  # distinguish from constructors
    end

A continuously compounded backward looking rate.

This is a proxy for daily compounded RFR coupon rates.

For obs_time less start_time it is equivalent to a Libor rate.
"""
struct CompoundedRate <: Payoff
    obs_time::ModelTime
    start_time::ModelTime
    end_time::ModelTime
    year_fraction::ModelValue
    fixed_compounding::Union{Payoff, Nothing}
    key::String
    fixed_type::DataType  # distinguish from constructors
end

"""
    CompoundedRate(
        obs_time_::ModelTime,
        start_time::ModelTime,
        end_time::ModelTime,
        year_fraction::ModelValue,
        key::String,
        fixed_compounding::Union{Payoff, Nothing} = nothing,
        )

A continuously compounded backward looking rate.
"""
function CompoundedRate(
    obs_time_::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    year_fraction::ModelValue,
    key::String,
    fixed_compounding::Union{Payoff, Nothing} = nothing,
    )
    @assert isnothing(fixed_compounding) || obs_time(fixed_compounding) == 0.0
    return CompoundedRate(
        obs_time_,
        start_time,
        end_time,
        year_fraction,
        fixed_compounding,
        key,
        typeof(fixed_compounding),
    )
end


"""
    CompoundedRate(
        obs_time::ModelTime,
        start_time::ModelTime,
        end_time::ModelTime,
        key::String,
        fixed_compounding::Union{Payoff, Nothing} = nothing,
        )

A continuously compounded backward looking rate with year fraction from model time.
"""
function CompoundedRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    fixed_compounding::Union{Payoff, Nothing} = nothing,
    )
    return CompoundedRate(
        obs_time,
        start_time,
        end_time,
        end_time-start_time,
        key,
        fixed_compounding,
    )
end


"""
    at(p::CompoundedRate, path::AbstractPath)

Derive the compounded backward looking rate at a given path.
"""
function at(p::CompoundedRate, path::AbstractPath)
    fixed_cmp = 1.0
    if !isnothing(p.fixed_compounding)
        fixed_cmp = at(p.fixed_compounding, path)
    end
    if p.obs_time ≤ p.start_time
        if p.obs_time == p.start_time
            df1_df2 = 1.0 ./ zero_bond(path, p.obs_time, p.end_time, p.key)
        else
            df1_df2 = compounding_factor(path, p.obs_time, p.start_time, p.end_time, p.key)
        end
        return (fixed_cmp .* df1_df2 .- 1.0) ./ p.year_fraction
    end
    if p.obs_time < p.end_time
        cmp = bank_account(path, p.obs_time, p.key) ./ bank_account(path, p.start_time, p.key)
        df2 = zero_bond(path, p.obs_time, p.end_time, p.key)
        return (fixed_cmp .* cmp ./ df2 .- 1.0) ./ p.year_fraction
    end
    # p.obs_time ≥ end p.end_time
    cmp = bank_account(path, p.end_time, p.key) ./ bank_account(path, p.start_time, p.key)
    return (fixed_cmp .* cmp .- 1.0) ./ p.year_fraction
end

"""
    string(p::CompoundedRate)

Formatted (and shortened) output for CompoundedRate payoff.
"""
string(p::CompoundedRate) = begin
    if isnothing(p.fixed_compounding)
        return @sprintf("R(%s, %.2f; %.2f, %.2f)", p.key, p.obs_time, p.start_time, p.end_time)
    else
        return @sprintf("R(%s, %.2f; %.2f, %.2f; %s)", p.key, p.obs_time, p.start_time, p.end_time, string(p.fixed_compounding))
    end
end

"""
    obs_time(p::CompoundedRate)

Calculate observation time for CompoundedRate payoff.
"""
obs_time(p::CompoundedRate) = min(p.obs_time, p.end_time)

"""
    obs_times(p::CompoundedRate)

Calculate all observation times (i.e. event times) for CompoundedRate payoff.
"""
function obs_times(p::CompoundedRate)
    fix_times = Set()
    if !isnothing(p.fixed_compounding)
        fix_times = obs_times(p.fixed_compounding)
    end
    if p.obs_time ≤ p.start_time
        return union(Set(p.obs_time), fix_times)
    else
        return union(Set((p.start_time, obs_time(p))), fix_times)
    end
end



"""
    struct Annuity <: Leaf
        obs_time::ModelTime
        fixed_times::AbstractVector  # (n+1,) vector, see Swaption payoff
        fixed_weights::AbstractVector  # (n,) vector
        disc_key::String
    end

A leg of cash flows with values/weights and pay times.

We use the convention of `Swaption` payoffs that we have n+1 `fixed_times`
and n `fixed_weights`.

Time `fixed_times[1]` is supposed to be the leg start time.

Cash flow weights correspond to `fixed_times[2:end]`.

We assume `obs_time` less or equal `fixed_times[1]`.
"""
struct Annuity <: Leaf
    obs_time::ModelTime
    fixed_times::AbstractVector  # (n+1,) vector, see Swaption payoff
    fixed_weights::AbstractVector  # (n,) vector
    disc_key::String
end


"""
    at(p::Annuity, path::AbstractPath)

Derive annuity at a given path.
"""
function at(p::Annuity, path::AbstractPath)
    zb_fixed = zero_bonds(path, p.obs_time, p.fixed_times[begin+1:end], p.disc_key)  # (p, n) matrix
    return zb_fixed * p.fixed_weights
end


"""
    annuity_and_leg_at(p::Annuity, path::AbstractPath)

Derive annuity and simple float leg value at a given path.
"""
function annuity_and_leg_at(p::Annuity, path::AbstractPath)
    zbs = zero_bonds(path, p.obs_time, p.fixed_times, p.disc_key)  # (p, n+1) matrix
    zb_fixed = @view zbs[:, begin+1:end]
    annuity = zb_fixed * p.fixed_weights
    simple_float_leg = @view(zbs[:,begin]) - @view(zbs[:,end])
    return (annuity, simple_float_leg)
end


"""
    string(p::Annuity)

Formatted (and shortened) output for Annuity payoff.
"""
string(p::Annuity) = begin
    @sprintf("Annuity(%.2f, [%.2f,...,%.2f], %s)",
        p.obs_time,
        p.fixed_times[begin],
        p.fixed_times[end],
        p.disc_key,
    )
end
