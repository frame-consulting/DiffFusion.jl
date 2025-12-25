
"""
    alias_mapping(
        state_alias_full::AbstractVector,
        state_alias_subs::AbstractVector,
        )

Return an index list that maps elements from `state_alias_subs`
to positions in `state_alias_full`.

Index list has length equal to length(state_alias_full).
"""
function alias_mapping(
    state_alias_full::AbstractVector,
    state_alias_subs::AbstractVector,
    )
    #
    @assert state_alias_full == unique(state_alias_full)
    @assert state_alias_subs  == unique(state_alias_subs)
    for alias in state_alias_subs
        @assert alias in state_alias_full
    end
    #
    idx_zero = length(state_alias_subs)
    idx_list = Int[]
    for alias in state_alias_full
        idx = findfirst(isequal(alias), state_alias_subs)
        if !isnothing(idx)
            push!(idx_list, idx)
        else
            push!(idx_list, idx_zero += 1)
        end
    end
    return idx_list
end
