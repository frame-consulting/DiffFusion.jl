
using DiffFusion
using Test
using UnicodePlots

@testset "Test asset option simulation" begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end
    
    function plot_scens(scens, title)
        plt = lineplot(scens.times, scens.X[1,:,:],
            title = title,
            name = scens.leg_aliases,
            xlabel = "obs_time",
            ylabel = "price (EUR)",
            width = 80,
            height = 30,
        )
        println()
        display(plt)
        println()
    end


    @testset "Test VanillaAssetOption simulation" begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = 0.0:1.0:6.0
        n_paths = 2^13
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        #
        call_leg = DiffFusion.cashflow_leg(
            "leg/C/EUR-USD/5y/1.25",
            [ DiffFusion.VanillaAssetOptionFlow(5.0, 5.0, 1.25, +1.0, "EUR-USD"), ],
            [ 1.0, ],
            "USD"
        )
        put_leg = DiffFusion.cashflow_leg(
            "leg/P/EUR-USD/5y/1.25",
            [ DiffFusion.VanillaAssetOptionFlow(5.0, 5.0, 1.25, -1.0, "EUR-USD"), ],
            [ 1.0, ],
            "USD"
        )
        scens = DiffFusion.scenarios([call_leg, put_leg], times, path, "")
        mv = DiffFusion.aggregate(scens, true, false)
        #
        plot_scens(mv, "EUR-USD option mv")
    end

end
