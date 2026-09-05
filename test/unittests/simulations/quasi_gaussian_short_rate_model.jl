using DiffFusion
using StatsBase
using Test

@testset "quasi-Gaussian short rate model simulation." begin

    @info "Run QuasiGaussianShortRateModel simulation."

    chi = DiffFusion.flat_parameter(0.03)
    sigma_f = DiffFusion.flat_volatility(0.01)
    volatility_function = DiffFusion.GaussianShortRateModelFunction()
    ch = DiffFusion.correlation_holder("Std")

    @testset "State-dependent simulation local volatility model" begin
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "Std",
            chi,
            sigma_f,
            nothing,
            volatility_function,
        )
        sim_times = 0.0:0.25:10.0
        n_paths = 2^10
        #
        @time sim0 = DiffFusion.state_dependent_simulation(
            model, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @time sim1 = DiffFusion.simple_simulation(
            model.gaussian_model, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim0.X) == (3, 1024, 41)
        @test size(sim1.X) == (2, 1024, 41)
        @test maximum(abs.(sim0.X[1:2,:,:] - sim1.X)) < 2.5e-16
    end

    @testset "CIR-like model simulation" begin
        chi = DiffFusion.flat_parameter(0.01)
        sigma_f = DiffFusion.flat_volatility(0.10)
        ts = DiffFusion.flat_forward(0.03)
        cir_volatility_function = DiffFusion.CirShortRateModelFunction(ts, 1.0e-6)
        model = DiffFusion.quasi_gaussian_short_rate_model(
            "CIR",
            chi,
            sigma_f,
            nothing,
            cir_volatility_function,
        )
        sim_times = 0.0:0.25:1.0  # std matches only for short times due to differing drifts
        n_paths = 2^13
        #
        @time sim0 = DiffFusion.state_dependent_simulation(
            model, ch, sim_times, n_paths, with_progress_bar = false, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        @test size(sim0.X) == (3, 8192, 5)
        #
        m_ = mean(sim0.X[1,:,:], dims = 1)
        s_ = std(sim0.X[1,:,:], dims = 1)
        #
        z0 = 0.03     # initial short rate
        chi = 0.01    # mean reversion speed
        theta = 0.03  # mean reversion level
        sigma = 0.10  # volatility
        m_cir = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        cir_moments = [
            DiffFusion.cir_moments(m_cir, z0, 0.0, t) for t in sim_times
        ]
        std_cir = [sqrt(m[2]) for m in cir_moments]
        #
        rel_deviation = abs.(vec(s_)[2:end] ./ std_cir[2:end] .- 1.0)
        @test maximum(rel_deviation) < 0.01
        #
        # m_s_s_ = hcat(m_', s_', std_cir)
        # println("Mean/std/std_CIR:")
        # display(m_s_s_)
    end

end