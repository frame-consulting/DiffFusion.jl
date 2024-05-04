
using DiffFusion
using OrderedCollections
using Test


@testset "Benchmark scenario generation." begin

    @testset "Test Vanilla swaps" begin
        results = OrderedDict[]
        for example_string in DiffFusion.Examples.examples
            @info "Run example " * example_string
            serialised_example = DiffFusion.Examples.load(example_string)
            example = DiffFusion.Examples.build(serialised_example)
            example["config/simulation"]["simulation_times"]["step"] = 0.25
            example["config/instruments"]["obs_times"]["step"] = 0.25
            example["config/simulation"]["n_paths"] = 2^13
            example["config/simulation"]["with_progress_bar"] = false
            example["config/instruments"]["with_progress_bar"] = false
            #
            path_ = DiffFusion.Examples.path!(example)
            portfolio_ = DiffFusion.Examples.portfolio!(
                example,
                32,  # swap
                0,  # swaptions
                0,  # berms
            )
            legs = vcat(portfolio_...)
            #
            config = example["config/instruments"]
            obs_times = config["obs_times"]
            if isa(obs_times, AbstractDict)
                obs_times = Vector(obs_times["start"]:obs_times["step"]:obs_times["stop"])
            end
            with_progress_bar = config["with_progress_bar"]
            discount_curve_key = config["discount_curve_key"]
            #
            for leg in legs
                if isa(leg, DiffFusion.BermudanSwaptionLeg)
                    DiffFusion.reset_regression!(leg, path_, leg.regression_data.make_regression)
                end
            end
            #
            GC.gc()
            time_ = @elapsed @time scens = DiffFusion.scenarios(
                legs,
                obs_times,
                path_,
                discount_curve_key,
                with_progress_bar=with_progress_bar
            )
            push!(
                results,
                OrderedDict(
                    "example"   => example_string,
                    "run_time"  => time_,
                )
            )    
        end
    end


end