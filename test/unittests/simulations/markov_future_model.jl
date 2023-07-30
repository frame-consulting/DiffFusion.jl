
using DiffFusion
using StatsBase
using Test

@testset "Markov Future model simulation." begin

    ch = DiffFusion.correlation_holder("Std")
    DiffFusion.set_correlation!(ch, "NIK_f_1", "NIK_f_2", 0.8)
    DiffFusion.set_correlation!(ch, "NIK_f_2", "NIK_f_3", 0.8)
    DiffFusion.set_correlation!(ch, "NIK_f_1", "NIK_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "NIK_f_1", -0.40)
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "NIK_f_2", -0.40)
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "NIK_f_3", -0.40)
    #
    delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.] * 0.25 * 1.0e-2
    sigma_f = DiffFusion.backward_flat_volatility("", times, values)

    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ] * 1.0e-2
    sigma_fx = DiffFusion.backward_flat_volatility("EUR-USD",times,values)

    @testset "Simple simulation (no correlation)." begin
        model = DiffFusion.markov_future_model("NIK-no-corr",delta,chi,sigma_f,ch,nothing)
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sobol = DiffFusion.sobol_brownian_increments
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments=sobol)
        @test size(sim.X) == (3,1024,6)
        # martingale test for Future price
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                H = DiffFusion.H_hjm(model, t, t+dt)
                I = ones(3)
                y = DiffFusion.func_y(model.hjm_model, t)
                x = sim.X[1:3,:,k]
                one = mean(exp.(H'*(x .+ 0.5*y*(I - H))))
                # display(one - 1.0)
                @test isapprox(one, 1.0, atol=5.0e-3)
            end
        end
    end

    @testset "Simple simulation (full correlation)." begin
        model = DiffFusion.markov_future_model("NIK",delta,chi,sigma_f,ch,nothing)
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sobol = DiffFusion.sobol_brownian_increments
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments=sobol)
        @test size(sim.X) == (3,1024,6)
        # martingale test for Future price
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                H = DiffFusion.H_hjm(model, t, t+dt)
                I = ones(3)
                y = DiffFusion.func_y(model.hjm_model, t)
                x = sim.X[1:3,:,k]
                one = mean(exp.(H'*(x .+ 0.5*y*(I - H))))
                # display(one - 1.0)
                @test isapprox(one, 1.0, atol=4.9e-3)
            end
        end
    end

    @testset "Simple simulation (with quanto)." begin
        asset_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
        markv_model = DiffFusion.markov_future_model("NIK",delta,chi,sigma_f,ch,asset_model)
        model = DiffFusion.simple_model("Std", [markv_model, asset_model])
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sobol = DiffFusion.sobol_brownian_increments
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments=sobol)
        @test size(sim.X) == (4,1024,6)
        # martingale test for Future price
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                H = DiffFusion.H_hjm(markv_model, t, t+dt)
                I = ones(3)
                y = DiffFusion.func_y(markv_model.hjm_model, t)
                x = sim.X[1:3,:,k]
                fx = sim.X[4:4,:,k]
                one = mean(exp.(H'*(x .+ 0.5*y*(I - H)) + fx))
                # display(one - 1.0)
                @test isapprox(one, 1.0, atol=3.6e-3)
            end
        end
    end

end
