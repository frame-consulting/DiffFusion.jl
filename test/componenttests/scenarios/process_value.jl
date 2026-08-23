using DiffFusion
using Test


@testset "Analyse process values via payoff." begin

    example_dict = DiffFusion.Examples.load("g3_3factor_real_world")
    example_obj = DiffFusion.Examples.build(example_dict)
    sim = DiffFusion.Examples.simulation!(example_obj)
    #
    _empty_key = DiffFusion._empty_context_key
    context = DiffFusion.Context(
        "Std",
        DiffFusion.NumeraireEntry("Zero", nothing, Dict(_empty_key => "yc/zero")),
        Dict{String, DiffFusion.RatesEntry}(),
        Dict{String, DiffFusion.AssetEntry}(),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.ProcessEntry}([
            ("EUR", DiffFusion.ProcessEntry("EUR", "md/EUR", "pa/zero")),
            ("USD", DiffFusion.ProcessEntry("USD", "md/USD", "pa/zero")),
            ("USD-EUR", DiffFusion.ProcessEntry("USD-EUR", "md/USD-EUR", "pa/zero")),
            ("G3-EUR", DiffFusion.ProcessEntry("G3-EUR", "md/G3-EUR", "pa/zero")),
        ]),
        Dict{String, DiffFusion.FixingEntry}(),
    )
    #
    ts_list = [
        DiffFusion.flat_forward("yc/zero", 0.00),
        DiffFusion.flat_parameter("pa/zero", zeros(14)),  # for G3-EUR
    ]
    #
    path_ = DiffFusion.path(sim, ts_list, context)
    #
    p1 = DiffFusion.ProcessValue(10.0, 1, "EUR")
    p2 = DiffFusion.ProcessValue(10.0, 4, "EUR")
    p3 = DiffFusion.ProcessValue(10.0, 1, "USD-EUR")
    p4 = DiffFusion.ProcessValue(10.0, 1, "USD")
    p5 = DiffFusion.ProcessValue(10.0, 4, "USD")
    #
    p6 = DiffFusion.ProcessValue(10.0, 1, "G3-EUR")
    p7 = DiffFusion.ProcessValue(10.0, 4, "G3-EUR")
    p8 = DiffFusion.ProcessValue(10.0, 14, "G3-EUR")
    #
    @test p1(path_) == sim.X[1,:, 11]
    @test p2(path_) == sim.X[4,:, 11]
    @test p3(path_) == sim.X[5,:, 11]
    @test p4(path_) == sim.X[6,:, 11]
    @test p5(path_) == sim.X[9,:, 11]
    #
    @test p6(path_) == sim.X[1,:, 11]
    @test p7(path_) == sim.X[4,:, 11]
    @test p8(path_) == sim.X[14,:, 11]

end