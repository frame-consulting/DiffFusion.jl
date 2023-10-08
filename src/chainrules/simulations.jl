
# We flag context_keys method as non-differentiable.
#
# The method uses split() which includes push!() on string arrays.
# This is a mutable array function that is not supported by
# Zygote.
ChainRulesCore.@non_differentiable context_keys(key::String)

# We flag _check_path_setup method as non-differentiable.
#
# The method uses unique() which includes push!() on string arrays.
# This is a mutable array function that is not supported by
# Zygote.
ChainRulesCore.@non_differentiable _check_path_setup(
    sim::Simulation,
    ts_dict::Dict{String,<:Termstructure},
    cxt::Context,
    )

# We flag _check_unique_ts method as non-differentiable.
#
# The method uses unique() which includes push!() on string arrays.
# This is a mutable array function that is not supported by
# Zygote.
ChainRulesCore.@non_differentiable _check_unique_ts(ts_alias::AbstractVector)

# Random number generation is not differentiable
ChainRulesCore.@non_differentiable pseudo_brownian_increments(
    n_states::Int,
    n_paths::Int,
    n_times::Int,  # without zero
    )

# Random number generation is not differentiable
ChainRulesCore.@non_differentiable pseudo_brownian_increments(
    n_states::Int,
    n_paths::Int,
    n_times::Int,  # without zero
    seed::Int,
    )


# Random number generation is not differentiable
ChainRulesCore.@non_differentiable sobol_brownian_increments(
    n_states::Int,
    n_paths::Int,
    n_times::Int,  # without zero
    )
