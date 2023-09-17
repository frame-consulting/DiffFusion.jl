using DiffFusion
using Test

@testset "Serialise and de-serialise models and term structures." begin

    include("basic_types.jl")
    include("array.jl")
    include("models.jl")
    include("objects.jl")
    include("termstructures.jl")
    #
    include("rebuild_models.jl")
    include("rebuild_termstructures.jl")

end
