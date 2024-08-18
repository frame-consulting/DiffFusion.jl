
using DiffFusion

using Test

@testset "Test asset option cash flows" begin
    
    @testset "Test VanillaAssetOptionFlow" begin
        cf = DiffFusion.VanillaAssetOptionFlow(5.0, 6.0, 1.5, +1.0, "EUR-USD")
        @test DiffFusion.pay_time(cf) == 6.0
        @test string(DiffFusion.amount(cf)) == "Max(1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        @test string(DiffFusion.expected_amount(cf, 0.0)) == "Call(S(EUR-USD, 0.00, 5.00), 1.5000)"
        @test string(DiffFusion.expected_amount(cf, 2.0)) == "Call(S(EUR-USD, 2.00, 5.00), 1.5000)"
        @test string(DiffFusion.expected_amount(cf, 5.0)) == "Max(1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        @test string(DiffFusion.expected_amount(cf, 6.0)) == "Max(1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        #
        cf = DiffFusion.VanillaAssetOptionFlow(5.0, 6.0, 1.5, -1.0, "EUR-USD")
        @test DiffFusion.pay_time(cf) == 6.0
        @test string(DiffFusion.amount(cf)) == "Max(-1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        @test string(DiffFusion.expected_amount(cf, 0.0)) == "Put(S(EUR-USD, 0.00, 5.00), 1.5000)"
        @test string(DiffFusion.expected_amount(cf, 2.0)) == "Put(S(EUR-USD, 2.00, 5.00), 1.5000)"
        @test string(DiffFusion.expected_amount(cf, 5.0)) == "Max(-1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        @test string(DiffFusion.expected_amount(cf, 6.0)) == "Max(-1.0000 * (S(EUR-USD, 5.00) - 1.5000), 0.0000)"
        #
        # println(string(DiffFusion.expected_amount(cf, 0.0)))
    end

    @testset "Test BarrierAssetOptionFlow" begin
        cf = DiffFusion.BarrierAssetOptionFlow(5.0, 6.0, 1.25, 1.35, 0.0, "UOC", "EUR-USD", 0.5)
        @test DiffFusion.pay_time(cf) == 6.0
        @test string(DiffFusion.expected_amount(cf, 0.0)) == "UOCall(S(EUR-USD, 0.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 2.0)) == "UOCall(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 5.0)) == "UOCall(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 6.0)) == "UOCall(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 7.0)) == "UOCall(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
        #
        cf = DiffFusion.BarrierAssetOptionFlow(5.0, 6.0, 1.25, 1.35, 0.0, "DIP", "EUR-USD", 0.5)
        @test DiffFusion.pay_time(cf) == 6.0
        @test string(DiffFusion.expected_amount(cf, 0.0)) == "DIPut(S(EUR-USD, 0.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 2.0)) == "DIPut(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 5.0)) == "DIPut(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 6.0)) == "DIPut(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
        @test string(DiffFusion.expected_amount(cf, 7.0)) == "DIPut(S(EUR-USD, 5.00, 5.00), X = 1.2500, H = 1.3500)"
    end

end