using DiffFusion
using LinearAlgebra
using StatsBase
using Test

@testset "Quasi-Gaussian model simulation." begin

    @info "Run Quasi-Gaussian simulation."

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
    sigma_f = DiffFusion.backward_flat_volatility("EUR", times, values)
    quanto_model = nothing

    gaussian_model = DiffFusion.gaussian_hjm_model("Std", delta, chi, sigma_f, ch, nothing)

    #
    slope_d_vals = [
        10. 10. 10. 10.;
        10. 10. 10. 10.;
        10. 10. 10. 10.
    ] * 1.0e-2 * (-1.0)
    #
    slope_u_vals = [
        15. 15. 15. 15.;
        15. 15. 15. 15.;
        15. 15. 15. 15.
    ] * 1.0e-2
    #
    sigma_min = 1.0e-4
    sigma_max = 500. * 1.0e-4
    #
    ou_model = DiffFusion.ornstein_uhlenbeck_model(
        "OU",
        DiffFusion.flat_parameter("Std", 0.10),  # chi
        DiffFusion.flat_volatility("Std", 0.20),  # sigma_x
    )


    @testset "State-dependent simulation Gaussian model" begin
        slope_d = DiffFusion.backward_flat_parameter("Std", times, zeros(3, 4))
        slope_u = DiffFusion.backward_flat_parameter("Std", times, zeros(3, 4))
        volatility_model = nothing
        volatility_function = nothing
        #
        m0 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        sim_times = 0.0:1.0:10.0
        n_paths = 2^10
        #
        @time sim0 = DiffFusion.state_dependent_simulation(
            m0, ch, sim_times, n_paths, with_progress_bar = false
        )
        @time sim1 = DiffFusion.simple_simulation(
            gaussian_model, ch, sim_times, n_paths, with_progress_bar = false
        )
        #
        @test isapprox(sim0.X[1:4,:,:], sim1.X, atol=7.0e-15)
        #
        for k in 2:length(sim_times)
            y = DiffFusion.func_y(gaussian_model, sim_times[k])
            y = reshape(y, (3, 3, 1)) .* ones(1, 1, n_paths)
            SX = DiffFusion.model_state(sim0.X[:,:,k], m0)
            y0 = DiffFusion.auxiliary_variable(m0, SX)
            @test isapprox(y0, y, atol=4.0e-16)
        end 
    end

    @testset "State-dependent simulation local volatility model" begin
        #
        slope_d = DiffFusion.backward_flat_parameter("Std", times, slope_d_vals)
        slope_u = DiffFusion.backward_flat_parameter("Std", times, slope_u_vals)
        volatility_model = nothing
        volatility_function = nothing
        #
        m0 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        sim_times = 0.0:0.25:10.0
        n_paths = 2^10
        #
        @time sim0 = DiffFusion.state_dependent_simulation(
            m0, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @time sim1 = DiffFusion.simple_simulation(
            gaussian_model, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        #
        @test size(sim0.X) == (13, 1024, 41)
        # martingale test for numeraire
        one0 = mean(exp.(-sim0.X[4,:,:]), dims=1)
        one1 = mean(exp.(-sim1.X[4,:,:]), dims=1)
        # display(one0)
        # display(one1)
        # display(maximum(abs.(one0 .- 1.0)))
        # display(maximum(abs.(one1 .- 1.0)))
        @test maximum(abs.(one0 .- 1.0)) < 6.0e-3
        @test maximum(abs.(one1 .- 1.0)) < 3.0e-3
        # martingale test for zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(0.0:10.0)
            # Gaussian model
            y1 = DiffFusion.func_y(gaussian_model, t)
            x1 = sim1.X[1:3,:,k]
            s1 = sim1.X[4:4,:,k]
            # quasi-Gaussian model
            SX = DiffFusion.model_state(sim0.X[:,:,k], m0)
            x0 = DiffFusion.state_variable(m0, SX)
            s0 = DiffFusion.integrated_state_variable(m0, SX)
            y0 = DiffFusion.auxiliary_variable(m0, SX)
            # display(size(y0))
            for dt in dt_
                G = DiffFusion.G_hjm(gaussian_model, t, t+dt)
                one1 = mean(exp.(-G'*x1 .- 0.5*G'*y1*G - s1))
                # display(one1)
                @test abs(one1 - 1.0) < 2.2e-2 
                #
                GyG = [ dot(G, @view(y0[:,:,p]), G) for p in 1:n_paths ]'
                one0 = mean(exp.(-G'*x0 - 0.5*GyG - s0))
                # display(abs(one0 - 1.0))
                @test abs(one0 - 1.0) < 3.6e-3
            end
        end
    end

    @testset "State-dependent simulation via hybrid model" begin
        #
        slope_d = DiffFusion.backward_flat_parameter("Std", times, slope_d_vals)
        slope_u = DiffFusion.backward_flat_parameter("Std", times, slope_u_vals)
        volatility_model = nothing
        volatility_function = nothing
        #
        m0 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        m1 = DiffFusion.diagonal_model("Std", [ m0 ])
        #
        sim_times = 0.0:1.0:10.0
        n_paths = 2^10
        #
        @time sim0 = DiffFusion.state_dependent_simulation(
            m0, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @time sim1 = DiffFusion.state_dependent_simulation(
            m1, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        #
        @test maximum(abs.(sim1.X - sim0.X)) < 1.2e-12
    end

    @testset "State-dependent simulation with stochastic volatility" begin
        #
        slope_d = DiffFusion.backward_flat_parameter("Std", times, slope_d_vals)
        slope_u = DiffFusion.backward_flat_parameter("Std", times, slope_u_vals)
        volatility_model = ou_model
        volatility_function = exp
        #
        m0 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )
        #
        m1 = DiffFusion.diagonal_model("Std", [ m0, ou_model ])
        # reset m0
        m0 = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            nothing, nothing,
        )
        #
        sim_times = 0.0:1.0:10.0
        n_paths = 2^10
        @time sim0 = DiffFusion.state_dependent_simulation(
            m0, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @time sim1 = DiffFusion.state_dependent_simulation(
            m1, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        #
        @test size(sim1.X) == (14, 1024, 11)
        # martingale test for numeraire
        one0 = mean(exp.(-sim0.X[4,:,:]), dims=1)
        one1 = mean(exp.(-sim1.X[4,:,:]), dims=1)
        # display(one0)
        # display(one1)
        # display(maximum(abs.(one0 .- 1.0)))
        # display(maximum(abs.(one1 .- 1.0)))
        @test maximum(abs.(one0 .- 1.0)) < 2.8e-3
        @test maximum(abs.(one1 .- 1.0)) < 3.1e-3
        # martingale test for zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(0.0:10.0)
            # local vol model
            SX = DiffFusion.model_state(sim0.X[:,:,k], m0)
            x0 = DiffFusion.state_variable(m0, SX)
            s0 = DiffFusion.integrated_state_variable(m0, SX)
            y0 = DiffFusion.auxiliary_variable(m0, SX)
            # stochastic vol model
            SX = DiffFusion.model_state(sim1.X[:,:,k], m1)
            x1 = DiffFusion.state_variable(m1.models[1], SX)
            s1 = DiffFusion.integrated_state_variable(m1.models[1], SX)
            y1 = DiffFusion.auxiliary_variable(m1.models[1], SX)
            # display(size(y0))
            for dt in dt_
                G = DiffFusion.G_hjm(gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y0[:,:,p]), G) for p in 1:n_paths ]'
                one0 = mean(exp.(-G'*x0 - 0.5.*GyG - s0))
                # display(abs(one0-1))
                @test abs(one0 - 1.0) < 1.7e-2
                G = DiffFusion.G_hjm(gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y1[:,:,p]), G) for p in 1:n_paths ]'
                one1 = mean(exp.(-G'*x1 - 0.5.*GyG - s1))
                # display(abs(one1-1))
                @test abs(one1 - 1.0) < 1.8e-2
            end
        end

    end

end