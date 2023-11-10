
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
        # flat implied vol surface
        implied_vols = 0.01 * ones((length(option_times), length(swap_maturities)))
        res = DiffFusion.gaussian_hjm_model("EUR", ch, option_times, swap_maturities, implied_vols, yts, max_iter = 5)
        @test all(res.fit .> -2.1e-4)
        @test all(res.fit .<  2.6e-4)
        # display(res.model.chi)
        # display(res.model.sigma_T.sigma_f)
        # display(res.fit * 1e+4)
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
        delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])

        # flat implied vol surface
        implied_vols = 0.01 * ones((length(option_times), length(swap_maturities)))
        res = DiffFusion.gaussian_hjm_model("EUR", delta, chi, ch, option_times, swap_maturities, implied_vols, yts, max_iter = 5)
        # display(res)
        @test all(res.fit .> -0.1e-4)
        @test all(res.fit .<  0.1e-4)
        # display(res.model.chi)
        # display(res.model.sigma_T.sigma_f.times)
        # display(res.model.sigma_T.sigma_f.values)
        # display(res.fit * 1e+4)
    end

end