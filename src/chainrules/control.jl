
function non_differentiable_warn(message)
    @warn message
end

function non_differentiable_warn(message, variable)
    @warn message variable
end

ChainRulesCore.@non_differentiable non_differentiable_warn(message)
ChainRulesCore.@non_differentiable non_differentiable_warn(message, variable)
