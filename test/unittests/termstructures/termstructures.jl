using DiffFusion
using Test

@testset "Term structures for simulation and valuation." begin

    @testset "Abstract Termstructure" begin
        struct NoTermStructure <: DiffFusion.Termstructure end
        ts = NoTermStructure()
        @test_throws ErrorException DiffFusion.alias(ts)
    end

    @testset "Abstract CorrelationTermstructure" begin
        struct NoCorrelationTermstructure <: DiffFusion.CorrelationTermstructure end
        ts = NoCorrelationTermstructure()
        #
        @test_throws ErrorException DiffFusion.correlation(ts, "A", "B")
        @test_throws ErrorException DiffFusion.correlation(ts, ["A", "B"])
        @test_throws ErrorException DiffFusion.correlation(ts, ["A", "B"], ["A", "B"])
        @test_throws ErrorException DiffFusion.correlation(ts, "A", ["A", "B"])
        @test_throws ErrorException DiffFusion.correlation(ts, ["A", "B"], "B")
        #
        @test_throws ErrorException ts("A", "B")
        @test_throws ErrorException ts(["A", "B"])
        @test_throws ErrorException ts(["A", "B"], ["A", "B"])
        @test_throws ErrorException ts("A", ["A", "B"])
        @test_throws ErrorException ts(["A", "B"], "B")
    end

    @testset "Abstract CreditDefaultTermstructure" begin
        struct NoCreditDefaultTermstructure <: DiffFusion.CreditDefaultTermstructure end
        ts = NoCreditDefaultTermstructure()
        @test_throws ErrorException DiffFusion.survival(ts, 1.0)
        @test_throws ErrorException ts(1.0)
    end

    @testset "Abstract FuturesTermstructure" begin
        struct NoFuturesTermstructure <: DiffFusion.FuturesTermstructure end
        ts = NoFuturesTermstructure()
        @test_throws ErrorException DiffFusion.future_price(ts, 1.0)
        @test_throws ErrorException ts(1.0)
    end

    @testset "Abstract InflationTermstructure" begin
        struct NoInflationTermstructure <: DiffFusion.InflationTermstructure end
        ts = NoInflationTermstructure()
        @test_throws ErrorException DiffFusion.inflation_index(ts, 1.0)
        @test_throws ErrorException ts(1.0)
    end

    @testset "Abstract ParameterTermstructure" begin
        struct NoParameterTermstructure <: DiffFusion.ParameterTermstructure end
        ts = NoParameterTermstructure()
        @test_throws ErrorException DiffFusion.value(ts)
        @test_throws ErrorException DiffFusion.value(ts, DiffFusion.TermstructureScalar)  # as_scalar
        @test_throws ErrorException DiffFusion.value(ts, 1.0)
        @test_throws ErrorException DiffFusion.value(ts, 1.0, DiffFusion.TermstructureScalar)  # as_scalar
        @test_throws ErrorException ts()
        @test_throws ErrorException ts(DiffFusion.TermstructureScalar)
        @test_throws ErrorException ts(1.0)
        @test_throws ErrorException ts(1.0, DiffFusion.TermstructureScalar)
    end

    @testset "Abstract YieldTermstructure" begin
        struct NoYieldTermstructure <: DiffFusion.YieldTermstructure end
        ts = NoYieldTermstructure()
        @test_throws ErrorException DiffFusion.discount(ts, 1.0)
        @test_throws ErrorException ts(1.0)
    end

    @testset "Abstract VolatilityTermstructure" begin
        struct NoVolatilityTermstructure <: DiffFusion.VolatilityTermstructure end
        ts = NoVolatilityTermstructure()
        @test_throws ErrorException DiffFusion.volatility(ts, 1.0)
        @test_throws ErrorException DiffFusion.volatility(ts, 1.0, DiffFusion.TermstructureScalar)  # as_scalar
        @test_throws ErrorException DiffFusion.volatility(ts, 1.0, 2.0)
        @test_throws ErrorException ts(1.0)
        @test_throws ErrorException ts(1.0, DiffFusion.TermstructureScalar)
        @test_throws ErrorException ts(1.0, 2.0)
    end

    include("correlation/correlation.jl")
    include("credit/credit.jl")
    include("futures/futures.jl")
    include("inflation/inflation.jl")
    include("parameter/parameter.jl")
    include("rates/rates.jl")
    include("volatility/volatility.jl")

    @testset "Piece-wise constant properties" begin
        struct NoTermstructure <: DiffFusion.Termstructure end
        ts = NoTermstructure()
        @test_throws ErrorException DiffFusion.is_constant(ts, 2.0, 3.0)
    end

end
