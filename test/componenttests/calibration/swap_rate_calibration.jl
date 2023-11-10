
using DiffFusion

using Test

@testset "Test Gaussian HJM model calibration." begin
    
    @testset "Test flat parameter calibration." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        option_times = [ 1.0, 2.0, 5.0, 10.0 ]
        swap_maturities = [ 2.0, 10.0, 20.0 ]
        #
        c = 0.80
        ch = DiffFusion.correlation_holder("Full")
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", c)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", c)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", c)
        #
        option_times = [ 1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 15.0, 20.0 ]
        swap_maturities = [ 1.0, 2.0, 5.0, 10.0, 20.0 ]
        #
        vols = [
            104.1   109.7   108.9   104.4   95.5
            103.9   106.3   104.5   101.3   92.6
            103.4   104.6   101.2    98.1   89.2
             98.5    98.4    94.4    89.7   80.7
             92.4    92.2    88.0    83.3   73.9
             86.5    86.6    81.5    76.4   66.5
             78.6    78.2    73.1    67.5   58.1
             73.2    73.2    67.7    62.0   52.7
            ] * 1.0e-4
        op_idx = [ 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -13.5e-4)
        @test all(res.fit .<   8.2e-4)
        println("")
        println("Global model calibration results 1:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f)
        display(res.fit * 1e+4)
        #
        vols = [
            142.0   146.6   139.6   129.3   125.8
            139.1   138.4   128.8   119.3   116.1
            133.2   131.3   120.6   110.9   107.4
            118.0   116.1   106.6    98.6    95.2
            107.2   105.7    97.7    91.1    87.1
             97.7    96.1    89.7    85.2    80.4
             88.8    87.7    83.4    80.0    74.1
             81.4    80.6    77.7    74.4    68.1
            ]  * 1.0e-4
        op_idx = [ 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -18.5e-4)
        @test all(res.fit .<  13.5e-4)
        println("")
        println("Global model calibration results 2:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f)
        display(res.fit * 1e+4)
        #
        vols = [
            129.1   130.7   119.5   106.5   92.9
            127.0   124.2   113.7   101.3   89.4
            119.7   115.2   107.5    96.3   85.5
            106.6   103.4    97.3    89.0   79.4
             96.2    93.9    89.5    82.6   73.6
             86.0    83.9    80.0    74.5   66.3
             74.2    71.9    68.9    64.6   58.4
             65.3    64.4    61.5    57.9   53.2
            ] * 1.0e-4
        op_idx = [ 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -12.2e-4)
        @test all(res.fit .<  12.4e-4)
        println("")
        println("Global model calibration results 3:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f)
        display(res.fit * 1e+4)
    end

    @testset "Test piece-wise flat vol calibration." begin
        yts = DiffFusion.zero_curve("", [0.0, 10.0], [0.03, 0.03])
        option_times = [ 1.0, 2.0, 5.0, 10.0 ]
        swap_maturities = [ 2.0, 10.0, 20.0 ]
        #
        c = 0.80
        ch = DiffFusion.correlation_holder("Full")
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", c)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", c)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", c)
        #
        option_times = [ 1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 15.0, 20.0 ]
        swap_maturities = [ 1.0, 2.0, 5.0, 10.0, 20.0 ]
        #
        delta = DiffFusion.flat_parameter([ 2., 5., 10. ])
        chi = DiffFusion.flat_parameter([ 0.03, 0.20, 0.50 ])
        #
        vols = [
            104.1   109.7   108.9   104.4   95.5
            103.9   106.3   104.5   101.3   92.6
            103.4   104.6   101.2    98.1   89.2
             98.5    98.4    94.4    89.7   80.7
             92.4    92.2    88.0    83.3   73.9
             86.5    86.6    81.5    76.4   66.5
             78.6    78.2    73.1    67.5   58.1
             73.2    73.2    67.7    62.0   52.7
            ] * 1.0e-4
        op_idx = [ 1, 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", delta, chi, ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -6.4e-4)
        @test all(res.fit .<  7.4e-4)
        println("")
        println("Piece-wise model calibration results 1:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f.times)
        display(res.model.sigma_T.sigma_f.values)
        display(res.fit * 1e+4)
        #
        delta = DiffFusion.flat_parameter([ 2., 5., 10. ])
        chi = DiffFusion.flat_parameter([ 0.03, 0.30, 0.40 ])
        #
        vols = [
            142.0   146.6   139.6   129.3   125.8
            139.1   138.4   128.8   119.3   116.1
            133.2   131.3   120.6   110.9   107.4
            118.0   116.1   106.6    98.6    95.2
            107.2   105.7    97.7    91.1    87.1
             97.7    96.1    89.7    85.2    80.4
             88.8    87.7    83.4    80.0    74.1
             81.4    80.6    77.7    74.4    68.1
            ] * 1.0e-4
        op_idx = [ 1, 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", delta, chi, ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -4.1e-4)
        @test all(res.fit .<  6.8e-4)
        println("")
        println("Piece-wise model calibration results 2:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f.times)
        display(res.model.sigma_T.sigma_f.values)
        display(res.fit * 1e+4)
        #
        delta = DiffFusion.flat_parameter([ 2., 5., 10. ])
        chi = DiffFusion.flat_parameter([ 0.02, 0.20, 0.30 ])
        #
        vols = [
            129.1   130.7   119.5   106.5   92.9
            127.0   124.2   113.7   101.3   89.4
            119.7   115.2   107.5    96.3   85.5
            106.6   103.4    97.3    89.0   79.4
             96.2    93.9    89.5    82.6   73.6
             86.0    83.9    80.0    74.5   66.3
             74.2    71.9    68.9    64.6   58.4
             65.3    64.4    61.5    57.9   53.2
            ] * 1.0e-4
        op_idx = [ 1, 2, 4, 6 ]
        sw_idx = [ 2, 3, 4 ]
        res = DiffFusion.gaussian_hjm_model("EUR", delta, chi, ch, option_times[op_idx], swap_maturities[sw_idx], vols[op_idx, sw_idx], yts, max_iter = 5)
        @test all(res.fit .> -0.1e-4)
        @test all(res.fit .<  0.1e-4)
        println("")
        println("Piece-wise model calibration results 3:")
        display(res.model.chi)
        display(res.model.sigma_T.sigma_f.times)
        display(res.model.sigma_T.sigma_f.values)
        display(res.fit * 1e+4)
    end

end