
# We flag alias_dictionary method as non-differentiable.
# 
# The dictionary operations appear to use try/catch.
# Try/catch is not supported by Zygote.
ChainRulesCore.@non_differentiable alias_dictionary(alias_list)

# unique causes errors in Zygote.
ChainRulesCore.@non_differentiable _unique_strings(s::AbstractVector)

# do not differentiate time grid operations
ChainRulesCore.@non_differentiable _intersect_interval(s::ModelTime, t::ModelTime, grid::AbstractVector)

# do not differentiate time grid operations
ChainRulesCore.@non_differentiable parameter_grid(m::Model)
ChainRulesCore.@non_differentiable parameter_grid(m::LognormalAssetModel)
ChainRulesCore.@non_differentiable parameter_grid(m::MarkovFutureModel)
ChainRulesCore.@non_differentiable parameter_grid(m::CompositeModel)
ChainRulesCore.@non_differentiable parameter_grid(m::GaussianHjmModel)
ChainRulesCore.@non_differentiable parameter_grid(models::Union{AbstractVector, Tuple})
