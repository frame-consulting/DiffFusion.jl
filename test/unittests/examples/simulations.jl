
using DiffFusion
using OrderedCollections
using Test


@testset "Test Example simulations." begin

    # some short-cuts
    alias = DiffFusion.alias
    at = DiffFusion.at


    "Run tests for a given example."
    function test_example_simulation(ex_name::String)
        serialised_example = DiffFusion.Examples.load(ex_name)
        example = DiffFusion.Examples.build(serialised_example)
        model = DiffFusion.Examples.model(example)
        ch = DiffFusion.Examples.correlation_holder(example)
        # we do not want outputs here
        example["config/simulation"]["with_progress_bar"] = false
        sim = DiffFusion.Examples.simulation!(example)
        ctx = DiffFusion.Examples.context(example)
        ts_dict = DiffFusion.Examples.term_structures(example)
        path_ = DiffFusion.Examples.path!(example)
        #
        @test typeof(serialised_example) == Vector{OrderedDict{String, Any}}
        @test typeof(example) == OrderedDict{String, Any}
        @test typeof(model) == DiffFusion.SimpleModel
        @test typeof(ch)  == DiffFusion.CorrelationHolder
        @test typeof(sim)  == DiffFusion.Simulation
        @test sim  == example[alias(model) * "/simulation"]
        @test typeof(ctx) == DiffFusion.Context
        @test typeof(ts_dict)  == Dict{String, DiffFusion.Termstructure}
        @test typeof(path_) == DiffFusion.Path
        @test path_ == example[alias(sim.model) * "/path"]
        #
        n_paths = example["config/simulation"]["n_paths"]
        @test size(at(DiffFusion.Numeraire(1.0, "USD"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.BankAccount(1.0, "USD"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "USD:SOFR"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "USD:LIB3M"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.BankAccount(1.0, "EUR"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "EUR:XCCY"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "EUR:ESTR"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.BankAccount(1.0, "GBP"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "GBP:XCCY"), path_)) == (n_paths,)
        @test size(at(DiffFusion.BankAccount(1.0, "GBP:SONIA"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "USD"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "USD:SOFR"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "USD:LIB3M"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "EUR"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "EUR:XCCY"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "EUR:ESTR"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "GBP"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "GBP:XCCY"), path_)) == (n_paths,)
        @test size(at(DiffFusion.ZeroBond(1.0, 2.0, "GBP:SONIA"), path_)) == (n_paths,)
        #
        @test size(at(DiffFusion.Asset(1.0, "EUR-USD"), path_)) == (n_paths,)
        @test size(at(DiffFusion.Asset(1.0, "GBP-USD"), path_)) == (n_paths,)
    end
    

    @testset "Test empty example edge cases." begin
        empty_example = OrderedDict{String, Any}()
        @test_throws ErrorException DiffFusion.Examples.model(empty_example)
    end

    @testset "Example models." begin
        test_example_simulation(DiffFusion.Examples.examples[1])
    end


    @testset "Missing/default example keys." begin
        serialised_example = DiffFusion.Examples.load(DiffFusion.Examples.examples[1])
        #
        example = DiffFusion.Examples.build(serialised_example)
        example["config/simulation"]["n_paths"] = 2^3
        example["config/simulation"]["with_progress_bar"] = false  # we do not want outputs here
        delete!(example["config/simulation"],"with_progress_bar")
        delete!(example["config/simulation"],"seed")
        delete!(example["config/instruments"],"path_interpolation")
        path1 = DiffFusion.Examples.path!(example)
        path2 = DiffFusion.Examples.path!(example)  # use cached path
        @test path1 == path2
        #
        delete!(example["config/simulation"],"with_progress_bar")
        scens1 = DiffFusion.Examples.scenarios!(example)
        scens2 = DiffFusion.Examples.scenarios!(example)  # use cached scenarios
        @test scens1 == scens2
    end


end