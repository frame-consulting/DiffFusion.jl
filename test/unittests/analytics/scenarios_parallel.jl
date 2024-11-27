
using Distributed

using DiffFusion
using Test

@testset "Parallel scenario generation." begin

    function is_equal_scenarios(s1::DiffFusion.ScenarioCube, s2::DiffFusion.ScenarioCube)
        if size(s1.X) != size(s2.X)
            return false
        end
        if maximum(abs.(s1.X .- s2.X)) > 0.0
            return false
        end
        return (s1.times == s2.times) &&
            (s1.leg_aliases == s2.leg_aliases) &&
            (s1.numeraire_context_key == s2.numeraire_context_key) &&
            (s1.discount_curve_key == s2.discount_curve_key)
    end

    n_threads = Threads.nthreads()
    n_workers = nworkers()
    @info "Run parallel scenario generation with $n_workers workers and $n_threads threads."

    example = DiffFusion.Examples.build(
        DiffFusion.Examples.load("g3_3factor_real_world")
    )  
    #    
    model = example["md/G3-EUR"]
    context = example["ct/EUR"]
    correlation_holder = example["ch/EUR"]
    ts_dict = DiffFusion.Examples.term_structures(example)

    times = 0.0:0.5:10.0
    n_paths = 2^3
    sim = DiffFusion.simple_simulation(
        model,
        correlation_holder,
        times,
        n_paths,
        with_progress_bar = true,
    )
    path = DiffFusion.path(
        sim,
        ts_dict,
        context,
        DiffFusion.LinearPathInterpolation,
    )

    portfolio = [
        DiffFusion.Examples.random_swap(example)
        for k in 1:9
    ]
    swap_legs = vcat(portfolio...)

    # scenarios w/o discounting

    scens_st = DiffFusion.scenarios(swap_legs, times, path, nothing)
    scens_mt = DiffFusion.scenarios_multi_threaded(swap_legs, times, path, nothing)
    scens_mp = DiffFusion.scenarios_distributed(swap_legs, times, path, nothing)
    scens_mx = DiffFusion.scenarios_parallel(swap_legs, times, path, nothing)
    #
    # println(maximum(abs.(scens_mt.X - scens_st.X)))
    # println(maximum(abs.(scens_mp.X - scens_st.X)))
    # println(maximum(abs.(scens_mx.X - scens_st.X)))
    @test is_equal_scenarios(scens_mt, scens_st)
    @test is_equal_scenarios(scens_mp, scens_st)
    @test is_equal_scenarios(scens_mx, scens_st)

    # scenarios w/ discounting

    scens_st = DiffFusion.scenarios(swap_legs, times, path, "EUR:ESTR")
    scens_mt = DiffFusion.scenarios_multi_threaded(swap_legs, times, path, "EUR:ESTR")
    scens_mp = DiffFusion.scenarios_distributed(swap_legs, times, path, "EUR:ESTR")
    scens_mx = DiffFusion.scenarios_parallel(swap_legs, times, path, "EUR:ESTR")
    #
    # println(maximum(abs.(scens_mt.X - scens_st.X)))
    # println(maximum(abs.(scens_mp.X - scens_st.X)))
    # println(maximum(abs.(scens_mx.X - scens_st.X)))
    @test is_equal_scenarios(scens_mt, scens_st)
    @test is_equal_scenarios(scens_mp, scens_st)
    @test is_equal_scenarios(scens_mx, scens_st)


    # println(size(scens.X))
end