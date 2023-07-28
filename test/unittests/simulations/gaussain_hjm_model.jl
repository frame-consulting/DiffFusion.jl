using DiffFusion
using StatsBase
using Test

@testset "Gaussian HJM model simulation." begin

    include("../test_tolerances.jl")
    abs_tol = test_tolerances["simulations/gaussian_hjm_model.jl"]
    @info "Run simulation test with tolerance abs_tol=" * string(abs_tol) * "."

    ch = DiffFusion.correlation_holder("Std")
    DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", 0.8)
    DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", 0.8)
    DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", 0.5)
    #
    delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
    chi = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
    times =  [ 1., 2., 5., 10. ]
    values = [ 50. 60. 70. 80.;
               60. 70. 80. 90.;
               70. 80. 90. 90.] * 1.0e-4
    sigma_f = DiffFusion.backward_flat_volatility("EUR",times,values)
    hjm_model = DiffFusion.gaussian_hjm_model("Std_no_corr",delta,chi,sigma_f,ch,nothing)

    @testset "Simple simulation HJM Model (no correlation)." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(hjm_model, ch, times, n_paths, with_progress_bar = false)
        @test size(sim.X) == (4,1024,6)
        # martingale test for numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test one[1] == 1.0
        @test isapprox(one[2], 1.000109346026247 , atol=abs_tol)
        @test isapprox(one[3], 0.9999727336866814, atol=abs_tol)
        @test isapprox(one[4], 0.9982685831027912, atol=abs_tol)
        @test isapprox(one[5], 0.9975872474473677, atol=abs_tol)
        @test isapprox(one[6], 0.9968209737863186, atol=abs_tol)
        # martingale test for zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(hjm_model, t, t+dt)
                y = DiffFusion.func_y(hjm_model, t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                @test isapprox(one, 1.0, atol=9.0e-3)
            end
        end
    end

    @testset "Simple Sobol sequence simulation." begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        # HJM model simulation, no correlation
        sim = DiffFusion.simple_simulation(hjm_model, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim.X) == (4,1024,6)
        # martingale test for numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9999998466576736, atol=abs_tol)
        @test isapprox(one[3], 0.9999995313596035, atol=abs_tol)
        @test isapprox(one[4], 1.0000006581864604, atol=abs_tol)
        @test isapprox(one[5], 1.0000091701465808, atol=abs_tol)
        @test isapprox(one[6], 1.0000130679716686, atol=abs_tol)
    end

    @testset "Simple simulation HJM with correlation." begin
        hjm_model_w_corr = DiffFusion.gaussian_hjm_model("EUR",delta,chi,sigma_f,ch,nothing)
        times = 0.0:2.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(hjm_model_w_corr, ch, times, n_paths, with_progress_bar = false)
        @test size(sim.X) == (4,1024,6)
        # martingale test for numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test one[1] == 1.0
        @test isapprox(one[2], 1.0001057163643803, atol=abs_tol)
        @test isapprox(one[3], 0.9998565201394450, atol=abs_tol)
        @test isapprox(one[4], 0.9991138613456693, atol=abs_tol)
        @test isapprox(one[5], 0.9994502962701297, atol=abs_tol)
        @test isapprox(one[6], 0.9995824198604566, atol=abs_tol)
        # martingale test for zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(hjm_model, t, t+dt)
                y = DiffFusion.func_y(hjm_model, t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                @test isapprox(one, 1.0, atol=1.3e-2)
                # println(one)
            end
        end
        #
        # repeat exercise with Sobol sequence
        sim = DiffFusion.simple_simulation(hjm_model_w_corr, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim.X) == (4,1024,6)
        # martingale test for numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9999999271829669, atol=abs_tol)
        @test isapprox(one[3], 0.9999995250439770, atol=abs_tol)
        @test isapprox(one[4], 0.9999960388371499, atol=abs_tol)
        @test isapprox(one[5], 0.9999817760406665, atol=abs_tol)
        @test isapprox(one[6], 0.9999303006126795, atol=abs_tol)
        # martingale test for zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(hjm_model, t, t+dt)
                y = DiffFusion.func_y(hjm_model, t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                @test isapprox(one, 1.0, atol=1.0e-2)
                # println(one)
            end
        end
    end

end
