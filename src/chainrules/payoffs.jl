
# do not differentiate AMC regression setting

ChainRulesCore.@non_differentiable reset_regression!(
    p::AmcPayoff,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
)

ChainRulesCore.@non_differentiable reset_regression!(
    p::UnaryNode,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
)

ChainRulesCore.@non_differentiable reset_regression!(
    p::BinaryNode,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
)

ChainRulesCore.@non_differentiable reset_regression!(
    p::Union{Leaf, CompoundedRate, Optionlet, Swaption},
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
)
